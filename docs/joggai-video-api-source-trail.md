# JoggAI Video API And SmartVideo Source Trail

Captured: 2026-08-29
Reviewed: 2026-09-12

## Purpose

This public-safe note distinguishes JoggAI's SmartVideo Codex plugin from its server API and records the official sources that should be re-checked before implementation.

## Two different integration surfaces

### SmartVideo Codex plugin

JoggAI documents SmartVideo as a Codex plugin for interactive video authoring. The installation and troubleshooting pages describe a local plugin/runtime workflow and JoggAI OAuth authentication. That makes it useful as an editor-facing authoring tool, but the public documentation does not make a local Codex session a durable production worker.

Official sources:

- [JoggAI Codex overview](https://docs.jogg.ai/codex)
- [Install SmartVideo](https://docs.jogg.ai/codex/install)
- [Create a video with SmartVideo](https://docs.jogg.ai/codex/create-video)
- [SmartVideo troubleshooting](https://docs.jogg.ai/codex/troubleshooting)

### JoggAI API v2

JoggAI's API documentation describes server-to-server calls authenticated with the `x-api-key` header. The official account test is `GET https://api.jogg.ai/v2/user/whoami`; remaining quota has a separate read-only endpoint.

Official sources:

- [Getting Started](https://docs.jogg.ai/api-reference/v2/QuickStart/GettingStarted)
- [Get User Info](https://docs.jogg.ai/api-reference/v2/User/GetUserInfo)
- [Get Remaining Quota](https://docs.jogg.ai/api-reference/v2/User/GetRemainingQuota)
- [API documentation index](https://docs.jogg.ai/llms.txt)

The API and the SmartVideo plugin therefore have separate authentication and execution boundaries. An implementation may use either or both, but one should not be presented as technically required by the other without newer controlling documentation.

## Webhook contract

JoggAI's webhook documentation says:

- requests include `X-Webhook-Signature`;
- the signature is a hexadecimal HMAC-SHA256 digest over the raw request body using the webhook secret;
- comparisons should be constant-time;
- the handler should return a `2xx` response within five seconds;
- non-`2xx` responses are retried;
- duplicate delivery is possible, so consumers should be idempotent;
- payloads may include `event_id`, `event`, `timestamp`, and provider-specific data such as a video ID, status, result URL, or error.

Official sources:

- [Webhook Integration Guide](https://docs.jogg.ai/api-reference/v2/API%20Documentation/WebhookIntegration)
- [Add Webhook Endpoint](https://docs.jogg.ai/api-reference/v2/Webhook/AddWebhookEndpoint)
- [List Webhook Events](https://docs.jogg.ai/api-reference/v2/Webhook/ListWebhookEvents)

The webhook secret is returned when an endpoint is registered. Public documentation examples are not credentials and should never be reused as secrets.

## Azure Queue Storage transport constraint

Microsoft's .NET Queue Storage API reference says the encoded queue message can be at most 64 KiB. When a queue client uses Base64 message encoding, the Base64 representation of the complete envelope—not only the provider's raw body—must fit that ceiling.

Official source:

- [Azure Queue Storage `SendMessageAsync`](https://learn.microsoft.com/en-us/dotnet/api/azure.storage.queues.queueclient.sendmessageasync?view=azure-dotnet)

A webhook receiver that places the full body inside a JSON envelope should therefore enforce a smaller raw-body limit or use an owned Blob-pointer pattern. The exact limit is an implementation decision based on envelope and encoding overhead; Microsoft does not prescribe a particular webhook-body limit.

## Asynchronous and cost-aware posture

JoggAI documents video creation as an asynchronous API workflow with later status/result retrieval or webhook delivery. The error documentation lists business codes for invalid keys, insufficient credit, missing permission, parameter errors, and system errors. The rate-limit page documents a POST limit that should be re-checked before automation.

Official sources:

- [Create Talking Avatar Videos](https://docs.jogg.ai/api-reference/v2/API%20Documentation/CreateAvatarVideos)
- [Check Video Result And Status](https://docs.jogg.ai/api-reference/v2/API%20Documentation/GetResult)
- [Error Handling](https://docs.jogg.ai/api-reference/v2/QuickStart/ErrorHandling)
- [Rate Limits](https://docs.jogg.ai/api-reference/v2/QuickStart/RateLimits)
- [Pricing](https://docs.jogg.ai/api-reference/v2/QuickStart/Pricing)

A conservative implementation should persist the provider task/video ID, distinguish read-only checks from paid POSTs, and reconcile an unknown submission outcome before retrying. This last sentence is an implementation inference from asynchronous, metered API behavior; it is not quoted as a JoggAI guarantee.

## What these sources support

- The documented difference between local SmartVideo authoring and JoggAI API v2.
- The `x-api-key` server authentication pattern and read-only account probe endpoint.
- The documented raw-body HMAC-SHA256 webhook verification contract.
- The five-second acknowledgement, retry, and idempotency posture documented for webhooks.
- The 64 KiB encoded-message ceiling documented for Azure Queue Storage.
- The need to check current pricing, rate limits, error codes, and result/status endpoints before enabling automated video generation.

## What these sources do not prove

- That any private account has API access, credits, a working key, or a particular plan.
- That a private webhook, host, queue, storage account, or deployment is configured correctly.
- That a particular raw webhook-body limit is universally correct; it depends on the queue envelope and encoding.
- That the SmartVideo plugin is installed or authenticated on a particular machine.
- That a specific video workflow is economical, legally appropriate, brand-safe, or production-ready.
- That dated pricing, limits, events, payload fields, or plugin behavior remain unchanged; re-check current official documentation.
- Any private infrastructure name, credential, endpoint, account identifier, or operational runbook.
