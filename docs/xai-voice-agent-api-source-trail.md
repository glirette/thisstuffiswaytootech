# xAI Voice Agent API Source Trail

Captured: 2026-07-07

## Purpose

Public-safe source trail for xAI Voice Agent API research. This note preserves official xAI documentation links so future agents can re-check the current API surface before making implementation, cost, telephony, or customer-facing decisions.

## Controlling Official Sources

- xAI Voice Agent API docs: https://docs.x.ai/developers/model-capabilities/audio/voice-agent
- xAI Voice Agent API model and pricing docs: https://docs.x.ai/developers/models/voice-agent-api
- xAI Ephemeral Tokens docs: https://docs.x.ai/developers/model-capabilities/audio/ephemeral-tokens
- xAI SIP Phone Calls docs: https://docs.x.ai/developers/model-capabilities/audio/voice-agent/sip
- xAI llms.txt docs index: https://docs.x.ai/llms.txt

## What The Sources Support

- xAI publishes official Voice Agent API documentation for realtime voice agents.
- The Voice Agent API docs describe WebSocket authentication and point to tester apps for WebSocket, WebRTC, and Twilio telephony examples.
- The model/pricing page lists audio and text-event pricing for the Voice Agent API.
- The ephemeral token docs are the official pointer for browser or mobile client sessions where a long-lived API key must not be exposed.
- The SIP docs are the official pointer for phone-call integration, including SIP provider and Twilio-oriented setup.
- The docs navigation includes tool and retrieval surfaces such as function calling, web search, X search, collections search, and remote MCP tools, but each tool surface must be re-checked in the current docs before use.

## What The Sources Do Not Prove

- They do not prove any private xAI account has API access, beta access, sufficient limits, or billing enabled.
- They do not prove the no-code Voice Agent Builder console is available in a given account or exposes any specific dashboard option.
- They do not prove production suitability for legal-adjacent, notary, identity, payment, customer-service, or phone-routing workflows.
- They do not authorize connecting live customer calls, phone numbers, callbacks, sends, CRM writes, payment actions, identity decisions, or private customer data to xAI.
- They do not replace current xAI docs, console checks, or account-specific testing.

## Public-Safe Implementation Posture

Use these sources as a starting point for a browser-only prototype or source-verified planning note. Before operational use, re-check current xAI docs and the target account console, then keep secrets in an approved secret store and customer/private data out of prompts, logs, public repos, and source notes.
