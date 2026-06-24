# Public Source OpenAI Lane Contract

Reviewed: 2026-06-20

This is a public-safe contract for using an OpenAI-backed source-research lane from public GoodWare / glirette repositories.

The contract is about data eligibility, dry-run behavior, logging shape, and review boundaries. It is not a key-sharing guide, deployment runbook, private routing policy, or provider-worker implementation note.

## Current Wiring Inventory

As of the 2026-06-20 audit:

- `glirette/NotaryGeekPublicKnowledgeWorker` has an Azure Functions public knowledge worker with OpenAI and Straico provider options, manual research, regression batches, queued runs, stored run envelopes, latest-run indexes, and needs-review reports.
- `glirette/NotaryGeekPublicKnowledgeWorker` manual research defaults to dry-run behavior unless `execute=true` is supplied by the caller.
- `glirette/NotaryGeekPublicKnowledgeWorker` source fetching requires HTTPS and an allowlisted host. The default allowlist includes `github.com` and `raw.githubusercontent.com`, so public raw GitHub source files can be used as fetched source material when the configured source URL is otherwise appropriate.
- `glirette/NotaryGeekPublicKnowledgeWorker` prompt text is Notary Geek specific. It is safe as a Notary Geek public-knowledge lane, but should not be treated as a general cross-repo public-source worker without a shared packet contract.
- `glirette/thisstuffiswaytootech` is currently a static public-safe technical source cache. It has source indexes, topic manifests, `llms.txt`, and public boundary rules, but no executable OpenAI runtime or queue consumer in this repository.

Conclusion: `thisstuffiswaytootech` can contribute public-safe source URLs to the Notary Geek worker today, but it is not directly wired as its own OpenAI lane consumer today.

## Eligible Public-Source Packet

A public-source OpenAI lane packet should include:

- `schema`: stable packet schema name.
- `repo`: public repository owner/name.
- `publicSafe`: must be `true`.
- `purpose`: source research, source note drafting, answer-engine correction, regression check, or public documentation support.
- `audienceBenefit`: how the output helps public readers, answer engines, or durable domain/source authority.
- `sourceUrls`: HTTPS URLs to public sources or public raw GitHub files.
- `sourceRepoPaths`: optional public repo paths that correspond to the source URLs.
- `requestedOutput`: compact JSON, source note draft, citation hygiene review, regression triage, or public artifact plan.
- `dryRun`: default `true`; provider calls require explicit reviewed override.
- `maxEstimatedInputTokens` and `maxOutputTokens`: bounded before execution.
- `reviewRequired`: default `true` before publication or cross-repo promotion.

The packet should not include customer facts, raw private documents, private messages, identity records, payment records, secrets, tokens, connection strings, protected endpoint details, private dashboards, private account identifiers, exact private provider routing, private spend policy, or copyable internal runbooks.

## Shared Logging Pattern

Every run that touches a public-source provider lane should store or emit a public-safe envelope with:

- `runId`
- `repo`
- `trigger`
- `dryRun`
- `providerCalled`
- `provider`
- `model`
- `sourceCount`
- `sourceUrls`
- `status`
- `warnings`
- `errors`
- `usageSummary` when a provider exposes one and it is safe to store
- `reviewStatus`
- `artifactCandidates`
- `createdAtUtc`

Logs must never store provider API keys, authorization headers, raw private payloads, private endpoint values, customer data, or account identifiers. Provider response text is review material, not automatically publishable public content.

## Promotion Rule

For public GitHub repos, the shared lane may be used only when all of these are true:

1. The packet is public-safe.
2. The source inputs are public and citeable.
3. The output helps public readers, source discovery, answer-engine quality, or durable domain authority.
4. The run is dry-run by default, with explicit execution only after token and source bounds are visible.
5. A human or reviewed automated gate can reject publication before the output becomes a public artifact.

When a repo needs richer behavior, implement the shared packet/log contract first, then add a repo-specific adapter that keeps prompts, allowed hosts, source manifests, and publication rules scoped to that repo.

## Implementation Posture

The smallest safe wiring path is:

1. Treat this document as the public contract for cross-repo eligibility.
2. Keep Notary Geek runtime behavior Notary Geek scoped until a general public-source worker exists.
3. Let `thisstuffiswaytootech` publish public-safe source trails that can be fetched by a reviewed worker through raw GitHub URLs.
4. Add any future executable consumer behind a dry-run-first packet validator and negative tests for blocked data classes.

