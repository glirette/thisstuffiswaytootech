# xAI Voice Agent API Source Trail

Captured: 2026-07-07
Reviewed: 2026-08-01

## Purpose

Public-safe source trail for xAI Voice Agent API research. This note preserves official xAI documentation links so future agents can re-check the current API surface before making implementation, cost, telephony, or customer-facing decisions.

## Controlling Official Sources

- xAI Voice Agent API docs: https://docs.x.ai/developers/model-capabilities/audio/voice-agent
- xAI Voice Agent API model and pricing docs: https://docs.x.ai/developers/models/voice-agent-api
- xAI Ephemeral Tokens docs: https://docs.x.ai/developers/model-capabilities/audio/ephemeral-tokens
- xAI SIP Phone Calls docs: https://docs.x.ai/developers/model-capabilities/audio/voice-agent/sip
- xAI Grok Voice Think Fast 2.0 announcement: https://x.ai/news/grok-voice-think-fast-2
- xAI Voice inference API reference: https://docs.x.ai/developers/rest-api-reference/inference/voice
- xAI llms.txt docs index: https://docs.x.ai/llms.txt

## What The Sources Support

- xAI publishes official Voice Agent API documentation for realtime voice agents.
- The Voice Agent API docs describe WebSocket authentication and point to tester apps for WebSocket, WebRTC, and Twilio telephony examples.
- The model/pricing page lists audio and text-event pricing for the Voice Agent API.
- The ephemeral token docs are the official pointer for browser or mobile client sessions where a long-lived API key must not be exposed.
- The SIP docs are the official pointer for phone-call integration, including SIP provider and Twilio-oriented setup.
- xAI announced `grok-voice-think-fast-2.0` on 2026-07-29 at `$0.08` per audio minute and states that `grok-voice-latest` will move from `grok-voice-think-fast-1.0` to 2.0 on 2026-08-05.
- xAI reports shorter sentences, one-question turns, less filler, faster first audio, and substantially better noisy and telephony-compressed transcription for 2.0. These are vendor claims that require workload-specific validation.
- As reviewed on 2026-08-01, the current Voice inference API reference documents `grok-voice-latest` as the default realtime model and explicitly lists both `grok-voice-think-fast-2.0` and `grok-voice-think-fast-1.0`.
- The docs navigation includes tool and retrieval surfaces such as function calling, web search, X search, collections search, and remote MCP tools, but each tool surface must be re-checked in the current docs before use.

## What The Sources Do Not Prove

- They do not prove any private xAI account has API access, beta access, sufficient limits, or billing enabled.
- They do not prove the no-code Voice Agent Builder console is available in a given account or exposes any specific dashboard option.
- They do not prove whether a saved Voice Agent Builder agent is pinned to 1.0, pinned to 2.0, or follows `grok-voice-latest`; inspect the saved agent or account API before relying on the August 5 alias migration.
- xAI's benchmark and A/B-test claims do not prove that an existing prompt, transfer policy, caller filter, tool, or telephony workflow will improve without regression.
- They do not prove production suitability for legal-adjacent, notary, identity, payment, customer-service, or phone-routing workflows.
- They do not authorize connecting live customer calls, phone numbers, callbacks, sends, CRM writes, payment actions, identity decisions, or private customer data to xAI.
- They do not replace current xAI docs, console checks, or account-specific testing.

## Public-Safe Implementation Posture

Use these sources as a starting point for a browser-only prototype or source-verified planning note. Before operational use, re-check current xAI docs and the target account console, then keep secrets in an approved secret store and customer/private data out of prompts, logs, public repos, and source notes.

For the 2.0 migration, first determine whether each saved agent follows `grok-voice-latest` or a pinned model. Test the existing prompt unchanged on synthetic and controlled calls before editing prompt wording. If validation cannot finish before 2026-08-05, pin 1.0 temporarily rather than accepting an unobserved live alias change. A later move to 2.0 should record the tested model identifier, scenarios, date, and rollback choice.
