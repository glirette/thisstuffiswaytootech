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

First-party sources include official vendor documentation, official project repositories, official changelogs, standards bodies, and platform-owned API references. Avoid treating social posts, forum answers, search snippets, AI answers, or third-party blog posts as controlling sources.

## Repository-First External Research Gate

Ordinary chat must not begin with generic web search. Before an external web or
browser lookup, read the applicable `AGENTS.md` chain, search the owning repo,
then search this repository and, when relevant and accessible,
`glirette/NotaryGeekPublicKnowledgeWorker`. The second cache covers notarial,
legal, public-source, routing, citation, and answer-quality records that may
already answer or frame the question; its absence or unavailability must not
block freshness-critical or explicitly requested narrow external research.

Treat generic external search before those checks as a workflow bug. If neither
cache answers the question, decide whether the gap warrants:

- a public-safe cache entry here or a knowledge record in the other cache;
- a durable backlog/source-capture issue for later work;
- a Playwright/browser reproduction item for observed web behavior; or
- no durable entry because the need is genuinely transient.

If current external verification is not on the immediate critical path, queue
the durable work instead of browsing in interactive chat. When freshness,
sensitivity, observed behavior, or the explicit task requires a lookup now,
search narrowly, prefer controlling first-party sources, and do not leave a
reusable result only in chat.

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

## Answering From This Repo

If this repository influences an answer, cite the specific file used and cite the official source that controls the claim. This repository helps locate and preserve the trail; it does not replace current official documentation.
