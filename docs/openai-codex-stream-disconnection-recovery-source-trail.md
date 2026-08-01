# OpenAI Codex Stream-Disconnection Recovery Source Trail

Captured: 2026-08-01

Topic: `ai-api-docs`

## Purpose

Public-safe source trail for diagnosing the Codex error `stream disconnected before completion: Transport error: network error: error decoding response body` and designing bounded recovery around non-interactive Codex runs.

This note distinguishes what the public Codex source establishes from what the retained error message cannot prove. It also records general recovery principles without publishing any private automation implementation, infrastructure, credentials, prompts, or logs.

## Controlling Official Sources

- OpenAI Codex release `0.146.0`: https://github.com/openai/codex/releases/tag/rust-v0.146.0
- Codex stream-error definition at the released commit: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/protocol/src/error.rs#L87-L92
- Shared HTTP transport error mapping: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/http-client/src/transport.rs#L80-L85
- Streaming response-body path: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/http-client/src/transport.rs#L137-L160
- Transport error representation: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/http-client/src/error.rs#L8-L23
- SSE completion and error handling: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/codex-api/src/sse/responses.rs#L499-L527
- Codex stream-retry handling: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/core/src/responses_retry.rs#L20-L73
- Codex stream-retry defaults: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/model-provider-info/src/lib.rs#L26-L31
- Codex non-interactive mode documentation: https://learn.chatgpt.com/docs/non-interactive-mode.md
- Codex configuration reference: https://learn.chatgpt.com/docs/config-file/config-reference.md

Corroborating public issue reports, which are not maintainer-confirmed root-cause findings:

- Exact error report: https://github.com/openai/codex/issues/29087
- Related connectivity report: https://github.com/openai/codex/issues/36059

## Observed Failure Boundary

The public Codex source defines this error class as a streaming failure after the HTTP handshake succeeds but before the stream emits the terminal `response.completed` event. Streaming response-body read errors pass through the shared HTTP transport, where non-timeout `reqwest::Error` values are converted to `TransportError::Network(err.to_string())`.

For the exact message in this note, the strongest supported root-cause statement is:

> Codex lost or could not decode the streaming HTTP response body after the connection was established and before the terminal completion event arrived.

At the cited revision, the transport layer retains a formatted error string rather than the typed `reqwest` error and its source chain. The message therefore does not identify whether the initiating fault occurred at the backend, an intermediary, HTTP framing, decompression, the local network, or another hop.

This exact error is also distinct from malformed model-event JSON in the SSE parser. The cited parser handles JSON deserialization failures on a separate path.

## What The Sources Support

- A terminal completion event is the positive signal that a streamed turn completed.
- A response-body stream can fail after some output or tool work has already occurred.
- Codex has native retry handling for retryable stream failures. At the cited release, the default stream retry budget is five reconnection attempts.
- `codex exec --json` provides machine-readable JSON Lines events, including `turn.completed`, `turn.failed`, and `error` events.
- `codex exec --ephemeral` avoids persisting session rollout files, and automation should grant only the sandbox permissions it needs.
- A separate outer recovery layer can be useful after Codex exhausts its own retry path, but that layer must account for the native retries already performed.

## What The Sources Do Not Prove

- They do not identify the precise server, proxy, protocol, decompression, operating-system, or network component that initiated a particular disconnect.
- They do not prove that task content, context size, a repository, or malformed JSON caused this exact response-body error.
- Public issue reports do not establish a widespread outage, regression, maintainer-confirmed root cause, or release timeline for a fix.
- A successful retry does not prove that repeating every prior side effect is safe.
- The general recovery posture below does not prove that any private wrapper, execution environment, repository, or deployment is implemented or configured correctly.

## Public-Safe Recovery Posture

Treat an outer retry as recovery for one narrowly classified terminal failure, not as a general rerun button.

1. Before the first send, record the expected workspace identity, revision, mutation scope, and ownership of the logical task.
2. Run Codex with machine-readable output, an isolated or least-privilege workspace, and no credentials that are unnecessary for the subprocess.
3. Qualify recovery only when the process failed, no terminal completion event exists, the terminal error matches the intended transport fingerprint, and the output parsed cleanly. Fail closed on malformed, missing, or ambiguous records.
4. Before retrying, verify that workspace identity and ownership have not changed, no conflicting operation is active, and every partial change remains inside the declared mutation scope.
5. Preserve safe partial work. Tell the recovery attempt to inspect and reconcile the existing diff rather than starting over or duplicating edits.
6. Permit only a small fixed outer retry budget. Remember that one outer attempt may already contain multiple native Codex stream reconnections.
7. Do not blindly retry actions that can create external side effects. Require application-specific idempotency or a fresh ownership check before allowing them.
8. Keep prompts and raw streams temporary. Retain only sanitized diagnostics such as timestamps, attempt counts, sizes, hashes, and allowed changed paths.
9. Exercise the classifier with exact-match, near-miss, malformed-output, changed-workspace, and partial-work cases before depending on it unattended.

On successful runs, the additional work is limited to local preflight, parsing, and reconciliation checks. A second model attempt occurs only after the narrowly classified failure.

## Recheck Rule

Re-check the current Codex release, source, configuration reference, and issue status before changing retry policy or relying on an error string. Event names, transports, retry defaults, and diagnostic fidelity can change between releases.
