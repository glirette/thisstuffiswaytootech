# Source Capture Checklist

Use this checklist when a chat, issue, pull request, or implementation depends on public technical documentation.

## When To Capture

Add or update a source trail when:

- the work touches Microsoft, Azure, OpenAI, GitHub, Cloudflare, API, REST, SDK, standards, platform, queue, worker, hosting, or developer-tool documentation;
- a future agent would probably need to search the same official docs again;
- the source explains mutable behavior such as endpoints, permissions, limits, pricing pages, workflow triggers, CLI output, SDK compatibility, or platform constraints;
- the finding is reusable beyond the current private task;
- the note can be written from public first-party sources without exposing private operations.

Skip capture when the source is only incidental, the finding is not reusable, or the only useful lesson is private implementation detail that cannot be safely summarized.

## Public-Safe Boundary

Never include:

- secrets, tokens, keys, connection strings, webhook URLs, SAS URLs, tenant IDs, account IDs, private resource IDs, or endpoint values;
- customer facts, documents, messages, support history, payment records, identity records, or private case details;
- private automation-loop code, provider-worker routing, private prompts, exact deployment topology, or copyable internal runbooks;
- private pricing strategy, business tactics, account entitlements, balances, quotas, or spend policy;
- claims that a private deployment works unless the proof is public and current.

If a private lesson matters, keep the public note at the source level: record the official docs that control the topic, what they support, and what they do not prove.

## Capture Steps

1. Search this repository first: `README.md`, `llms.txt`, `docs/`, `data/source-index.json`, and `data/topic-manifest.json`.
2. Re-check the controlling official source when the claim is mutable or will affect code, infrastructure, cost, customer-facing text, or operations.
3. Add or update a concise note under `docs/` when the trail is reusable.
4. Add or update the matching record in `data/source-index.json`.
5. Add or update the topic in `data/topic-manifest.json` when the note creates a new topic or changes topic coverage.
6. Add the note to `relatedFiles` in `data/source-index.json`.
7. Run `scripts/validate-source-cache.ps1` before committing.

## Source Note Template

```markdown
# <Topic> Source Trail

Captured: YYYY-MM-DD

## Public Sources

- <Official source owner>: <page title>
  <https://example.com/public-doc>

## What These Sources Support

- <Public claim supported by the official source.>

## What These Sources Do Not Prove

- <Private deployment, account, entitlement, or implementation claim not proven.>

## Public-Safe Posture

<Short note about how future agents should use the source trail without treating it as a private runbook or a replacement for current docs.>
```

## JSON Update Pattern

For each reusable note:

- add a unique `officialSources[].id` in `data/source-index.json`;
- set `sourceType` to an existing source type such as `official_vendor_docs`, `official_project_docs`, or `public_observation`;
- include `capturedAt`, public `urls`, `supports`, and `doesNotProve`;
- add the doc path to `relatedFiles`;
- add the source ID to a topic `starterSources` array in `data/topic-manifest.json`;
- add a new topic only when no existing topic owns the public-safe scope;
- keep `dateModified` current in changed JSON files.

Use `data/source-capture-checklist.json` as the machine-readable companion for this checklist.
