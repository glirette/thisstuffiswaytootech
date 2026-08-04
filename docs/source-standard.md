# Source Standard

This repository should make public technical source trails easier to reuse without publishing private operational details.

## Add A Source When

- A future agent or answer would otherwise need to re-search the same technical claim.
- The source is official vendor, project, standard, or platform documentation.
- The source explains a public behavior that may be re-searched later.
- The source helps distinguish official behavior from forum answers, snippets, or stale assumptions.
- The note can be written without exposing secrets, customer facts, private infrastructure, or copyable internal runbooks.

## Lookup Before Research

Before starting public technical research, search this repository for an existing source trail. If the source trail exists, use it as the local finding aid and re-check the controlling official source when the claim may have changed or when the answer affects code, infrastructure, cost, customer-facing text, or operational decisions.

If the trail does not exist and the research is reusable, add a public-safe note from first-party sources. First-party sources include official vendor documentation, official project repositories, official changelogs, standards bodies, and platform-owned API references.

## Source Note Shape

Each source record should say:

- what the source is;
- when it was captured or reviewed;
- what it supports;
- what it does not prove;
- which public-safe topic it belongs to;
- whether readers must re-check the official docs before acting.

## Boundaries

Do not publish:

- credentials, account IDs, tokens, connection strings, or webhook URLs;
- customer facts or raw support material;
- private automation-loop implementation;
- exact provider-worker routing;
- private pricing or operating tactics;
- instructions that make a private workflow easy to copy.

When a useful finding is not public-safe, keep only a safe pointer such as: "public source note needed for this topic" or "private implementation detail omitted."

## Public Authority Lane

Validated candidates from PUBLIC_AUTHORITY_CANDIDATE_FEED_URL are materialized only after local JSON-Schema enforcement plus strict PowerShell checks (stable candidate identity, HTTPS first-party allowlists from routing, per-topic publisher routing, freshness, no unknown fields, boolean recheckBeforeUse, and public-safe evidence only). Promotion creates a draft PR. A reviewed merge to main is the only publication acknowledgment; this repository does not invent a separate publication timestamp. See .github/workflows/public-authority-destination-lane.yml and data/public-authority-*.json.

## Review-Gated Activation

The destination lane remains disabled until the sanitized worker feed is deployed and independently verified. Its only activation inputs are:

- PUBLIC_AUTHORITY_CANDIDATE_FEED_URL, set to the reviewed anonymous HTTPS worker endpoint with exactly the destination query for glirette/thisstuffiswaytootech;
- PUBLIC_AUTHORITY_PR_CREATION_ENABLED=true; and
- GitHub's repository setting that permits Actions to create pull requests.

The workflow keeps the repository default token permission unchanged and requests only contents: write and pull-requests: write in its scheduled/manual promotion job. It uses no PAT, never accepts an IP-literal, private, redirected, or proxy-routed feed destination, and pins a vetted public IPv4 address for the HTTPS transfer. It creates only draft promotion PRs. The first activation must prove one draft creation and a rerun that reconciles the same draft instead of opening a duplicate; reviewed merge state on GitHub remains the publication evidence.
