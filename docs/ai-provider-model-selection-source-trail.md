# AI Provider Model Selection Source Trail

Reviewed: 2026-06-16

This is a public-safe source trail for choosing AI provider and model documentation sources before making cost, capability, context-window, coding-quality, or routing claims.

Official provider documentation controls the claim. This note is only a reusable pointer and dated source cache.

## Operating Posture

AI model names, availability, context windows, prices, and coding/reasoning suitability change quickly. Treat any cached model-selection rule as stale unless it points back to current official provider documentation or a freshly captured authenticated model catalog.

For operational use, cache the public-safe facts that help a router pick the right model class:

- provider;
- model identifier or model family;
- official documentation URL;
- date checked;
- public capability labels;
- public context/pricing notes where officially documented;
- coding/reasoning suitability notes;
- whether the source was public docs or an authenticated model catalog;
- what must be re-checked before spend or deployment decisions.

Do not publish private account entitlements, API keys, organization IDs, customer data, private prompts, or private provider-routing tactics in this repository.

## Source Families

### OpenAI

Use OpenAI's official model and pricing documentation before relying on an OpenAI model name, cost tier, context window, tool support, or reasoning/coding capability.

Current source starting points:

- OpenAI model documentation: https://platform.openai.com/docs/models
- OpenAI API pricing: https://platform.openai.com/docs/pricing
- OpenAI API reference: https://platform.openai.com/docs/api-reference
- OpenAI developer docs: https://developers.openai.com/

This supports public-safe checks such as:

- whether a model is officially documented;
- whether OpenAI presents it as a flagship, reasoning, mini, nano, or other model class;
- whether pricing and context-window claims are public and current;
- whether a code-generation or code-review workflow should use a higher-reasoning model or a cheaper task model.

This does not prove:

- that a private account currently has access;
- that a social-media model rumor is real;
- that a private router should use one specific model without checking cost, quality, and task shape;
- that a cached model snapshot remains current.

### Anthropic

Use Anthropic's official Claude model and API documentation before relying on model identifiers, context windows, pricing, or capability claims.

Current source starting points:

- Claude model overview: https://docs.anthropic.com/en/docs/about-claude/models/overview
- Anthropic Messages API: https://docs.anthropic.com/en/api/messages
- Anthropic pricing: https://www.anthropic.com/pricing

This supports public-safe checks such as:

- which Claude model families are documented;
- which API surface creates messages;
- which public pricing page controls current cost claims;
- whether a review lane should use a higher-capability model family for hard code/security reviews.

This does not prove:

- that a private account currently has access;
- that a model is available through a reseller or aggregator;
- that a cached price or context claim remains current.

### Straico

Straico is an aggregator/middle-man surface. Use Straico's live model catalog when available before routing by model name through Straico.

Current source starting points:

- Straico API base observed from public/authenticated integration work: `https://api.straico.com/v2`
- Straico models endpoint shape to check with an API key: `GET https://api.straico.com/v2/models`
- Straico chat endpoint shape to check with an API key: `POST https://api.straico.com/v2/chat/completions`

The unauthenticated `GET /v2/models` endpoint returned HTTP 401 when checked on 2026-06-16, which is consistent with needing an API key before capturing an account-visible model catalog.

This supports public-safe checks such as:

- Straico model routing should be based on a fresh catalog snapshot rather than hardcoded assumptions;
- Straico-mediated multi-model review should preserve the underlying model perspectives when available;
- private routing can use cheap models for well-defined tasks and higher-capability models for hard code review, but the public source cache should not publish private spend strategy.

This does not prove:

- the current model list for a private Straico account;
- private account balances, prices, entitlements, or usage limits;
- that a model available directly from OpenAI or Anthropic is also available through Straico;
- that a cached authenticated catalog remains current.

### xAI / Grok

Use xAI's official REST API documentation before relying on Grok model identifiers, request shape, or pricing/catalog metadata.

Current source starting points:

- xAI API reference overview: https://docs.x.ai/docs/api-reference
- xAI models endpoint: https://docs.x.ai/developers/rest-api-reference/inference/models
- xAI chat completions endpoint: https://docs.x.ai/developers/rest-api-reference/inference/chat
- xAI Batch API: https://docs.x.ai/developers/advanced-api-usage/batch-api
- xAI pricing, including Batch API pricing: https://docs.x.ai/developers/pricing

The official REST surface is OpenAI-compatible at `https://api.x.ai/v1`. Use `GET /v1/models` for a fresh account-visible catalog and `POST /v1/chat/completions` for chat completions through reviewed private worker code.

The official Batch API docs describe a background-processing lane for large request volumes where immediate response is not required. The source trail supports treating xAI batch as a distinct async/bulk route from real-time chat completions, with lower pricing and separate operational monitoring. Use official pricing docs before making cost claims.

This supports public-safe checks such as:

- whether the xAI API surface is reachable with the expected base URL and authorization pattern;
- whether a fresh catalog lists the model id a private router wants to use;
- whether a provider adapter should treat xAI as a direct provider lane instead of an aggregator.
- whether a batch route is appropriate for high-volume, latency-insensitive work rather than real-time requests.

This does not prove:

- private account balance, entitlements, or usage limits;
- that a cached Grok model list remains current;
- that a specific Grok model is the right economic choice for a private work item;
- that Batch API pricing, rate limits, or completion timing remain unchanged after the checked date;
- that a private runner should spend on xAI without the private routing policy allowing it.

## Model Selection Rule For Consumers

Consumers should use this source trail as a starting point, then apply their own private routing rules:

- Well-defined mechanical tasks should prefer the lowest-cost model that passes quality checks.
- Hard code review, security/privacy review, unclear bugs, integration-contract review, and customer-impacting workflow changes should use more capable reasoning models or multiple independent model families.
- High-confidence routing requires both a current source trail and a recent task-quality observation.
- If the source trail is stale, refresh it before relying on cost, context, or model-availability claims.

## Public Boundary

This source trail is public-safe. It should not contain:

- API keys or secret names;
- private organization or account identifiers;
- private balances or spend ceilings;
- customer facts;
- private prompts;
- private provider-worker implementation details;
- exact internal routing rules that would expose business tactics.

Keep private routing decisions, queue policy, and provider-worker implementation in private repos. Keep public model/source facts here.
