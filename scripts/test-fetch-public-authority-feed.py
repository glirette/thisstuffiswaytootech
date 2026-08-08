#!/usr/bin/env python3
"""Contract tests for the public feed's redirect, DNS, and output boundary."""

from __future__ import annotations

import importlib.util
import io
import socket
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_PATH = Path(__file__).with_name("fetch-public-authority-feed.py")
SPEC = importlib.util.spec_from_file_location("public_authority_fetch", SCRIPT_PATH)
assert SPEC and SPEC.loader
FETCH = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = FETCH
SPEC.loader.exec_module(FETCH)

VALID_URL = (
    "https://public-worker.example/api/public-knowledge/promotion-feed"
    "?destination=glirette%2Fthisstuffiswaytootech"
)


def dns_answer(address: str, family: int = socket.AF_INET) -> tuple:
    return (family, socket.SOCK_STREAM, 6, "", (address, 443))


class FakeResponse:
    def __init__(self, status: int, body: bytes, content_type: str = "application/json"):
        self.status = status
        self._body = io.BytesIO(body)
        self._content_type = content_type

    def getheader(self, name: str) -> str | None:
        if name.lower() == "content-type":
            return self._content_type
        if name.lower() == "content-length":
            return str(len(self._body.getvalue()))
        return None

    def read(self, size: int = -1) -> bytes:
        return self._body.read(size)


class FakeConnection:
    def __init__(self, hostname: str, address: str, timeout: float, response: FakeResponse):
        self.hostname = hostname
        self.address = address
        self.timeout = timeout
        self.response = response
        self.requests: list[tuple] = []
        self.closed = False

    def request(self, method: str, target: str, body: bytes | None = None, headers: dict[str, str] | None = None) -> None:
        self.requests.append((method, target, body, headers or {}))

    def getresponse(self) -> FakeResponse:
        return self.response

    def close(self) -> None:
        self.closed = True


class PublicAuthorityFetchContractTests(unittest.TestCase):
    def test_valid_url_is_parsed_without_loosening_the_query_contract(self) -> None:
        endpoint = FETCH.parse_reviewed_feed_url(VALID_URL)
        self.assertEqual(endpoint.hostname, "public-worker.example")
        self.assertEqual(
            endpoint.request_target,
            "/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech",
        )

    def test_unsafe_url_shapes_fail_before_dns(self) -> None:
        invalid_urls = (
            "http://public-worker.example/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech",
            "file:///tmp/feed.json",
            "https://user:password@public-worker.example/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech",
            "https://public-worker.example:444/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech",
            "https://127.0.0.1/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech",
            "https://public-worker.example/api/public-knowledge/promotion-feed?destination=wrong",
            "https://public-worker.example/api/public-knowledge/promotion-feed?destination=glirette%2Fthisstuffiswaytootech&extra=value",
            VALID_URL + "#fragment",
            VALID_URL + "%250a",
        )
        for value in invalid_urls:
            with self.subTest(value=value):
                with self.assertRaises(FETCH.FetchError):
                    FETCH.parse_reviewed_feed_url(value)

    def test_dns_rejects_private_mixed_and_ipv6_only_answers(self) -> None:
        private = lambda *args, **kwargs: [dns_answer("127.0.0.1")]
        mixed = lambda *args, **kwargs: [dns_answer("8.8.8.8"), dns_answer("10.0.0.1")]
        ipv6_only = lambda *args, **kwargs: [dns_answer("2606:4700:4700::1111", socket.AF_INET6)]
        for resolver in (private, mixed, ipv6_only):
            with self.subTest(resolver=resolver):
                with self.assertRaises(FETCH.FetchError):
                    FETCH.resolve_public_ipv4("public-worker.example", resolver)

    def test_fetch_pins_the_public_ipv4_and_writes_only_valid_json(self) -> None:
        created: list[FakeConnection] = []

        def factory(hostname: str, address: str, timeout: float) -> FakeConnection:
            connection = FakeConnection(hostname, address, timeout, FakeResponse(200, b'{"candidates":[]}'))
            created.append(connection)
            return connection

        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "feed.json"
            address = FETCH.fetch_feed(
                VALID_URL,
                output,
                resolver=lambda *args, **kwargs: [dns_answer("8.8.8.8")],
                connection_factory=factory,
            )
            self.assertEqual(address, "8.8.8.8")
            self.assertEqual(output.read_bytes(), b'{"candidates":[]}')
        self.assertEqual(len(created), 1)
        self.assertEqual(created[0].address, "8.8.8.8")
        self.assertEqual(created[0].requests[0][0], "GET")
        self.assertEqual(created[0].requests[0][1], FETCH.FEED_PATH + "?destination=glirette%2Fthisstuffiswaytootech")

    def test_redirect_is_rejected_without_contacting_a_location(self) -> None:
        created: list[FakeConnection] = []

        def factory(hostname: str, address: str, timeout: float) -> FakeConnection:
            connection = FakeConnection(hostname, address, timeout, FakeResponse(302, b""))
            created.append(connection)
            return connection

        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "feed.json"
            with self.assertRaises(FETCH.FetchError):
                FETCH.fetch_feed(
                    VALID_URL,
                    output,
                    resolver=lambda *args, **kwargs: [dns_answer("8.8.8.8")],
                    connection_factory=factory,
                )
            self.assertFalse(output.exists())
        self.assertEqual(len(created), 1)
        self.assertEqual(len(created[0].requests), 1)

    def test_oversized_non_json_and_missing_content_type_bodies_are_never_accepted(self) -> None:
        rejected = (
            (b"x" * 128, "application/json"),
            (b"not-json", "application/json"),
            (b'{"candidates":[]}', ""),
            (b'{"candidates":[]}', "text/plain"),
        )
        for body, content_type in rejected:
            with self.subTest(body=body[:8], content_type=content_type):
                def factory(
                    hostname: str,
                    address: str,
                    timeout: float,
                    body: bytes = body,
                    content_type: str = content_type,
                ) -> FakeConnection:
                    return FakeConnection(hostname, address, timeout, FakeResponse(200, body, content_type))

                with tempfile.TemporaryDirectory() as temporary:
                    output = Path(temporary) / "feed.json"
                    with self.assertRaises(FETCH.FetchError):
                        FETCH.fetch_feed(
                            VALID_URL,
                            output,
                            max_bytes=64,
                            resolver=lambda *args, **kwargs: [dns_answer("8.8.8.8")],
                            connection_factory=factory,
                        )
                    self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
