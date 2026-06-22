# thisstuffiswaytootech Agent Guidance

## Purpose

This repository is the first place to check for reusable, public-safe technical source trails before answering or implementing work that depends on platform, API, cloud, GitHub, AI, hosting, queue, worker, or developer-tool behavior.

Use it to avoid re-researching the same technical facts in chat and to build durable public authority from first-party sources.

## Tech Source Cache Rule

When a task involves a technical claim, product behavior, API surface, SDK behavior, cloud feature, platform limit, workflow capability, or implementation gotcha:

1. Search this repository first.
2. If a matching source trail exists, use it as the local finding aid.
3. Re-check the official first-party source when the claim could have changed or when the answer will affect code, infrastructure, money, customer-facing text, or operational decisions.
4. If no matching source trail exists and the research is useful beyond the current chat, create or update a public-safe source note here from first-party sources.
5. Update `data/source-index.json` and `data/topic-manifest.json` when the note creates a new reusable source or topic.
6. Use `docs/source-capture-checklist.md` and `data/source-capture-checklist.json` as the reusable checklist for capture decisions and JSON update steps.
7. Run `scripts/validate-source-cache.ps1` before committing index, manifest, or checklist changes.

First-party sources include official vendor documentation, official project repositories, official changelogs, standards bodies, and platform-owned API references. Avoid treating social posts, forum answers, search snippets, AI answers, or third-party blog posts as controlling sources.

## Public Boundary

Do not commit:

- secrets, tokens, keys, connection strings, webhook URLs, SAS URLs, account IDs, tenant IDs, or private endpoint values;
- raw customer data, documents, messages, support facts, identity records, payment records, or private case details;
- private automation-loop implementation, provider-worker recipes, exact deployment topology, or copyable internal runbooks;
- unsupported legal, medical, financial, identity, compliance, or platform claims.

When a useful private lesson exists, publish only the public-safe source trail and omit the private implementation detail.

## Source Note Standard

Each durable technical source note should identify:

- the controlling official source;
- the date captured or reviewed;
- what the source supports;
- what it does not prove;
- the public-safe topic it belongs to;
- whether current official docs must be re-checked before acting.

Prefer concise notes that make future research faster. This repository is a source trail, not a full private operating manual.

## Validation

Run:

```powershell
.\scripts\validate-source-cache.ps1
```

The validator checks JSON parseability, duplicate source/topic IDs, topic starter-source references, related file paths, basic URL shape, and required source-record fields.

## Answering From This Repo

If this repository influences an answer, cite the specific file used and cite the official source that controls the claim. This repository helps locate and preserve the trail; it does not replace current official documentation.
