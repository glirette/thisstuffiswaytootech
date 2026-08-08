#!/usr/bin/env python3
"""Fetch the one reviewed public authority feed without following redirects."""

from __future__ import annotations

import argparse
import http.client
import ipaddress
import json
import os
import re
import socket
import ssl
import tempfile
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable

DESTINATION = "glirette/thisstuffiswaytootech"
FEED_PATH = "/api/public-knowledge/promotion-feed"
MAX_BYTES = 1_048_576
_HOST_LABEL = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")
_CONTROL = re.compile(r"[\x00-\x1f\x7f]")
_NON_GLOBAL_V4 = tuple(
    ipaddress.ip_network(cidr)
    for cidr in (
        "0.0.0.0/8",
        "10.0.0.0/8",
        "100.64.0.0/10",
        "127.0.0.0/8",
        "169.254.0.0/16",
        "172.16.0.0/12",
        "192.0.0.0/24",
        "192.0.2.0/24",
        "192.88.99.0/24",
        "192.168.0.0/16",
        "198.18.0.0/15",
        "198.51.100.0/24",
        "203.0.113.0/24",
        "224.0.0.0/4",
        "240.0.0.0/4",
    )
)


class FetchError(RuntimeError):
    """Raised when the public-feed boundary cannot be established safely."""


@dataclass(frozen=True)
class Endpoint:
    url: str
    hostname: str
    request_target: str


def _decoded_has_control(value: str) -> bool:
    decoded = value
    for _ in range(4):
        if _CONTROL.search(decoded):
            return True
        next_value = urllib.parse.unquote(decoded)
        if next_value == decoded:
            return False
        decoded = next_value
    return bool(_CONTROL.search(decoded))


def _validate_dns_hostname(hostname: str) -> str:
    if not hostname or hostname.endswith("."):
        raise FetchError("endpoint must use a canonical DNS hostname")
    try:
        hostname.encode("ascii")
    except UnicodeEncodeError as exc:
        raise FetchError("endpoint hostname must be ASCII") from exc
    normalized = hostname.lower()
    if len(normalized) > 253 or any(not _HOST_LABEL.fullmatch(label) for label in normalized.split(".")):
        raise FetchError("endpoint hostname is invalid")
    try:
        ipaddress.ip_address(normalized)
    except ValueError:
        return normalized
    raise FetchError("endpoint hostname must not be an IP literal")


def parse_reviewed_feed_url(raw_url: str) -> Endpoint:
    """Validate the one public worker feed contract before any connection."""

    if not isinstance(raw_url, str) or not raw_url or raw_url != raw_url.strip():
        raise FetchError("endpoint URL is empty or contains surrounding whitespace")
    if _decoded_has_control(raw_url):
        raise FetchError("endpoint URL contains a control character")
    try:
        parsed = urllib.parse.urlsplit(raw_url)
        port = parsed.port
    except ValueError as exc:
        raise FetchError("endpoint URL is invalid") from exc
    if parsed.scheme.lower() != "https":
        raise FetchError("endpoint must use HTTPS")
    if parsed.username is not None or parsed.password is not None:
        raise FetchError("endpoint must not contain user credentials")
    if parsed.fragment:
        raise FetchError("endpoint must not contain a fragment")
    if port not in (None, 443):
        raise FetchError("endpoint must use port 443")
    hostname = _validate_dns_hostname(parsed.hostname or "")
    if parsed.path != FEED_PATH:
        raise FetchError("endpoint path is not the reviewed promotion-feed path")
    try:
        parameters = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True, strict_parsing=True)
    except ValueError as exc:
        raise FetchError("endpoint query is invalid") from exc
    if parameters != [("destination", DESTINATION)]:
        raise FetchError("endpoint query must contain exactly the reviewed destination")
    return Endpoint(raw_url, hostname, f"{parsed.path}?{parsed.query}")


def _is_public_ipv4(address: ipaddress.IPv4Address) -> bool:
    return address.is_global and not any(address in network for network in _NON_GLOBAL_V4)


def resolve_public_ipv4(
    hostname: str,
    resolver: Callable[..., Iterable[tuple]] = socket.getaddrinfo,
) -> list[str]:
    """Resolve once, reject any non-public answer, and return vetted IPv4 addresses."""

    try:
        answers = resolver(hostname, 443, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise FetchError("endpoint DNS resolution failed") from exc
    addresses: set[ipaddress.IPv4Address | ipaddress.IPv6Address] = set()
    for answer in answers:
        try:
            address = ipaddress.ip_address(answer[4][0].split("%", 1)[0])
        except (IndexError, ValueError) as exc:
            raise FetchError("endpoint DNS returned an invalid address") from exc
        addresses.add(address)
    if not addresses:
        raise FetchError("endpoint DNS returned no addresses")
    for address in addresses:
        if address.version == 4 and not _is_public_ipv4(address):
            raise FetchError("endpoint DNS resolved to a non-public IPv4 address")
        if address.version == 6 and not address.is_global:
            raise FetchError("endpoint DNS resolved to a non-public IPv6 address")
    ipv4 = sorted(
        (str(address) for address in addresses if address.version == 4 and _is_public_ipv4(address)),
        key=lambda value: int(ipaddress.ip_address(value)),
    )
    if not ipv4:
        raise FetchError("endpoint must provide a public IPv4 address")
    return ipv4


class PinnedHTTPSConnection(http.client.HTTPSConnection):
    """HTTPS connection which preserves TLS hostname checks while pinning the socket IP."""

    def __init__(self, hostname: str, address: str, timeout: float):
        super().__init__(hostname, port=443, timeout=timeout, context=ssl.create_default_context())
        self._pinned_address = address

    def connect(self) -> None:
        self.sock = socket.create_connection((self._pinned_address, self.port), self.timeout)
        self.sock = self._context.wrap_socket(self.sock, server_hostname=self.host)


def _read_limited(response: http.client.HTTPResponse, max_bytes: int) -> bytes:
    content_length = response.getheader("Content-Length")
    if content_length is not None:
        try:
            declared_length = int(content_length)
        except ValueError as exc:
            raise FetchError("endpoint returned an invalid content length") from exc
        if declared_length < 1 or declared_length > max_bytes:
            raise FetchError("endpoint response length is outside the allowed bound")

    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = response.read(min(65_536, max_bytes + 1 - total))
        if not chunk:
            break
        total += len(chunk)
        if total > max_bytes:
            raise FetchError("endpoint response exceeds the allowed size")
        chunks.append(chunk)
    if total == 0:
        raise FetchError("endpoint response is empty")
    return b"".join(chunks)


def request_from_pinned_address(
    endpoint: Endpoint,
    address: str,
    method: str,
    headers: dict[str, str],
    body: bytes | None,
    expected_statuses: set[int],
    max_bytes: int,
    timeout_seconds: float,
    connection_factory: Callable[[str, str, float], http.client.HTTPSConnection] = PinnedHTTPSConnection,
) -> bytes:
    connection = connection_factory(endpoint.hostname, address, timeout_seconds)
    try:
        request_headers = {
            "Accept": "application/json",
            "User-Agent": "public-authority-feed-fetch/1",
            **headers,
        }
        connection.request(method, endpoint.request_target, body=body, headers=request_headers)
        response = connection.getresponse()
        if response.status not in expected_statuses:
            raise FetchError(f"endpoint returned HTTP {response.status}")
        content_type = (response.getheader("Content-Type") or "").split(";", 1)[0].strip().lower()
        if content_type != "application/json" and not content_type.endswith("+json"):
            raise FetchError("endpoint response content type is not JSON")
        return _read_limited(response, max_bytes)
    finally:
        connection.close()


def fetch_feed(
    raw_url: str,
    output_path: Path,
    max_bytes: int = MAX_BYTES,
    timeout_seconds: float = 30,
    resolver: Callable[..., Iterable[tuple]] = socket.getaddrinfo,
    connection_factory: Callable[[str, str, float], http.client.HTTPSConnection] = PinnedHTTPSConnection,
) -> str:
    endpoint = parse_reviewed_feed_url(raw_url)
    addresses = resolve_public_ipv4(endpoint.hostname, resolver)
    last_transport_error: Exception | None = None
    for address in addresses:
        try:
            body = request_from_pinned_address(
                endpoint,
                address,
                "GET",
                {},
                None,
                {200},
                max_bytes,
                timeout_seconds,
                connection_factory,
            )
        except (OSError, ssl.SSLError, http.client.HTTPException) as exc:
            last_transport_error = exc
            continue
        try:
            json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise FetchError("endpoint response is not valid UTF-8 JSON") from exc
        output_path.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary_name = tempfile.mkstemp(prefix=f".{output_path.name}.", dir=output_path.parent)
        try:
            with os.fdopen(descriptor, "wb") as output:
                output.write(body)
            os.replace(temporary_name, output_path)
        finally:
            if os.path.exists(temporary_name):
                os.unlink(temporary_name)
        return address
    raise FetchError("endpoint could not be reached at a vetted public address") from last_transport_error


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Reviewed public feed URL.")
    parser.add_argument("--output", required=True, type=Path, help="Destination file for validated response bytes.")
    parser.add_argument("--max-bytes", type=int, default=MAX_BYTES)
    parser.add_argument("--timeout-seconds", type=float, default=30)
    args = parser.parse_args()
    if args.max_bytes < 1 or args.timeout_seconds <= 0:
        parser.error("max bytes and timeout must be positive")
    try:
        address = fetch_feed(args.url, args.output, args.max_bytes, args.timeout_seconds)
    except FetchError as exc:
        print(f"safe feed fetch failed: {exc}", file=os.sys.stderr)
        return 1
    print(f"safe feed fetch succeeded: bytes={args.output.stat().st_size} remote_ipv4={address}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
