# OpenCode and OpenRouter source trail

Reviewed: September 13, 2026.
Topics: AI API documentation; model selection sources.
Recheck current first-party documentation before code, routing, privacy, or spending decisions.

## Controlling sources

- [OpenCode providers — OpenRouter](https://opencode.ai/docs/providers/#openrouter):
  documents connecting an OpenRouter API key, discovering models, and configuring
  model-specific provider options.
- [OpenRouter provider routing](https://openrouter.ai/docs/guides/routing/provider-selection):
  documents endpoint restrictions, fallback behavior, data-collection filtering,
  and zero-data-retention routing.
- [OpenRouter data collection](https://openrouter.ai/docs/guides/privacy/data-collection):
  explains router and downstream-provider data handling.

## What this supports

OpenCode has a documented OpenRouter integration. Its configuration can carry
model-specific routing preferences. OpenRouter documents `only` and
`allow_fallbacks` for endpoint selection, `data_collection` for data-policy
filtering, and `zdr` as a separate retention constraint.

## What it does not prove

Documentation does not establish that a particular installed runtime transmits
each option, that an account is eligible for a model, or that a selected endpoint
will accept a request. Catalog presence is not successful inference or proof of
tool support. A model vendor's name does not by itself identify the billing
service or the downstream inference endpoint.

Routing/privacy options do not redact inputs. Do not infer a universal privacy
guarantee from a single setting. Verify the current policies and actual
integration behavior for the intended use.

This note contains no private account, deployment, credential, or operating
configuration and recommends no particular model or spending policy.
