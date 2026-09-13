# OpenAI Codex Follow-Goals Source Trail

Captured: 2026-09-13

Topic: `ai-api-docs`

## Purpose

Public-safe cache of the official OpenAI source located while answering whether a user must repeatedly tell Codex to continue long-running work.

The search used the query `Codex app goals continue task automatically site:developers.openai.com`. The useful official result redirected to the ChatGPT Learn page below. Irrelevant search results and snippets are not treated as sources.

## Controlling Official Source

- OpenAI, [Follow a goal](https://learn.chatgpt.com/use-cases/follow-goals)

## Follow-Up Search Result Supplied From Another Chat

- OpenAI, [Model guidance](https://developers.openai.com/api/docs/guides/latest-model)

The separate chat reported that this page recommends making precedence among user instructions, skills, and files such as `AGENTS.md` explicit and auditing conflicting instructions. That chat's result is cached here as supplied; this task did not repeat or independently re-open the search. Re-check the page before relying on that summarized claim for implementation.

## What The Source Supports

- `/goal` gives Codex a durable objective for long-running work.
- OpenAI describes `/goal` for tasks that need Codex to keep working across turns toward a verifiable stopping condition.
- The documented examples emphasize long-running coding, migrations, refactors, experiments, and other work with clear success criteria and validation loops.

## What The Source Does Not Prove

- It does not say that `/goal` is mandatory for sustained work.
- It does not say that `/goal` replaces or overrides repository-specific `AGENTS.md` instructions, durable issues, branches, pull requests, queues, or other established operating rules.
- It does not authorize Codex to exceed the user's task scope, perform gated external actions, or ignore approval boundaries.
- It does not establish that every Codex surface, account, version, or deployment exposes identical goal behavior.
- The supplied Model guidance summary does not, by itself, establish that a particular global instruction or skill exception has been installed, loaded, or given the intended precedence.

## Recheck Rule

Re-check the official page before relying on current `/goal` syntax, availability, or behavior. Use this note as a finding aid and avoid repeating a general OpenAI documentation search when the cached source already answers the source-location question.
