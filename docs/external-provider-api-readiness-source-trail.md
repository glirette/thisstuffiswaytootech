# External Provider API Readiness Source Trail

Reviewed: 2026-07-06

## Purpose

Public-safe source trail for checking external provider API readiness before wiring private automation. This note is a finding aid for official documentation, not a credential setup guide, private runbook, or proof that any private account is configured.

## Official Sources

- n8n API authentication: https://docs.n8n.io/connect/n8n-api/authentication/
- n8n API reference: https://docs.n8n.io/connect/n8n-api/user/
- Mautic developer documentation: https://developer.mautic.org/
- Mautic REST API authentication: https://devdocs.mautic.org/en/7.1/rest_api/authentication.html
- Mautic REST API users: https://devdocs.mautic.org/en/7.1/rest_api/users.html
- DHL Express MyDHL API: https://developer.dhl.com/api-reference/dhl-express-mydhl-api
- FedEx Authorization API: https://developer.fedex.com/api/en-us/catalog/authorization/docs.html
- Smarty MCP documentation: https://www.smarty.com/docs/mcp

## Public-Safe Findings

- n8n documents API-key authentication for its public API and uses the `X-N8N-API-KEY` header.
- Mautic's current developer documentation routes to versioned 7.x documentation; use the current versioned REST API authentication and user endpoints before assuming older Mautic behavior.
- DHL Express publishes MyDHL API documentation from its developer portal. Re-check the current environment/base URL and activation status before treating early authorization failures as implementation defects.
- FedEx publishes a separate Authorization API reference for obtaining OAuth tokens before calling other FedEx APIs.
- Smarty publishes MCP documentation with `Auth-Id` and `Auth-Token` headers and a public health endpoint.

## Supports

- Build read-only API readiness probes that confirm DNS, endpoint reachability, and authentication posture before deeper integration work.
- Keep provider credentials in environment variables, Azure app settings, or Key Vault rather than source code.
- Separate missing configuration, credential/authorization failure, provider validation errors, and network/DNS failures in probe output.
- Reuse official-source links for Mautic, n8n, DHL, FedEx, and Smarty rather than relying on old snippets or forum posts.

## Does Not Prove

- That any private Mautic, n8n, DHL, FedEx, or Smarty account has working credentials, required entitlements, enabled products, or production access.
- That any private endpoint, tenant, workspace, subscription, API key, OAuth client, or account setting is configured correctly.
- That a read-only readiness probe is enough to prove shipment, address validation, workflow execution, billing, CRM sync, or customer-intake behavior.
- That provider documentation will keep the same URL, request shape, rate limit, error code, or activation timing.
- That this source trail should contain private URLs, credentials, customer payloads, provider-worker routing, or copyable internal runbooks.

## Recheck Rule

Before changing code or operational settings:

1. Re-open the current official documentation for the provider and API surface being touched.
2. Confirm whether the call is read-only, token-only, validation-only, or mutating.
3. Confirm the correct environment, base URL, authentication headers, and activation or entitlement requirements.
4. Keep secrets and private account identifiers out of Git, chat, screenshots, and public source notes.
