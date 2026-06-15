# Heffl API v2 Task Assignment And Linking

Captured: 2026-06-15

This is a public-safe source trail for Heffl task assignment and task-to-record linking fields. Official Heffl documentation controls the claim; this note is only a reusable pointer.

## Official Sources

- Documentation index: https://docs.heffl.com/llms.txt
- Create task: https://docs.heffl.com/api-v2-reference/objects/create-task.md
- List tasks: https://docs.heffl.com/api-v2-reference/objects/list-tasks.md
- List users: https://docs.heffl.com/api-v2-reference/reference-data/list-users.md

## Public-Safe Findings

- Heffl API v2 production server is documented as `https://api.heffl.com/api/v2`.
- Heffl API v2 `TaskInput` documents `assigneeIds` as an array of user IDs.
- Heffl API v2 task creation documents `entity` and `entityId` for linking a task to a project, lead, or deal.
- Heffl API v2 task listing documents filters for status, type, priority, assignees, tags, dates, and permissions-aware results.
- Heffl API v2 user listing returns team users and supports search and active membership filtering.

## What This Does Not Prove

- It does not prove any private account has a specific user, permission, task, lead, deal, or project.
- It does not prove a private API key can assign work to another user without live authorization checks.
- It does not reveal private endpoint URLs, keys, IDs, customer records, or implementation details.
- It does not replace re-checking the current official docs before changing production integrations.

