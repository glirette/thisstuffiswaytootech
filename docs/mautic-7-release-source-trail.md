# Mautic 7 Release Source Trail

Reviewed: 2026-06-26

## Purpose

Public-safe source trail for Mautic 7 release posture, update targeting, and version-specific caution.

This posture is for Mautic only. It does not imply "latest version" policy for n8n, PHP, databases, operating systems, or other infrastructure.

Use this note to avoid stale Mautic 4/5/6 assumptions when planning Mautic 7 work. This is a finding aid, not a private deployment runbook.

Some deployments may intentionally use current stable Mautic for real low-blast-radius work rather than treating Mautic as testing-only. That production-use posture is separate from release-candidate adoption: RC builds still need an explicit testing/staging decision.

## Official Sources

- Mautic GitHub releases: https://github.com/mautic/mautic/releases
- Mautic 7.1.0 release: https://github.com/mautic/mautic/releases/tag/7.1.0
- Mautic 7.1.2 release: https://github.com/mautic/mautic/releases/tag/7.1.2
- Mautic 7.2.0 RC release: https://github.com/mautic/mautic/releases/tag/7.2.0-rc
- Mautic 7.1 update docs: https://docs.mautic.org/en/7.1/getting_started/how_to_update_mautic.html
- Mautic 7 CLI command docs: https://docs.mautic.org/en/7.0/configuration/command_line_interface.html

## Dated Public Observations

As of 2026-06-26, the Mautic GitHub releases feed showed:

- `7.1.0`: stable release, published 2026-04-24.
- `7.1.2`: stable release, published 2026-05-28.
- `7.2.0-rc`: pre-release, published 2026-06-02.

The `7.1.2` release notes identify the release as a security release and advise updating after backup and staging testing.

The `7.2.0-rc` release notes identify the release candidate as testing-only and not for production use.

## Supports

- Treat Mautic 7.1.x as the current Mautic production release line until a later stable Mautic tag supersedes it.
- Treat `7.1.2` as the production update target when comparing a `7.1.0` installation against public release tags.
- Treat `7.2.0-rc` as a testing/staging candidate only, not a production target.
- Distinguish "use current stable Mautic for low-blast-radius production work" from "run a release candidate in production."
- Re-check Mautic 7.1 docs and GitHub releases before relying on old Mautic 4/5/6 tutorials.
- Pay special attention to version drift around forms, APIs, campaigns, plugins, cron/update commands, and email behavior.
- Treat reproducible Mautic 7 bugs as likely upstream contribution candidates when the issue and fix are public-safe and not private-deployment-specific.
- Reproducible public-safe bugs in other open-source dependencies may also become upstream issues or PRs; Mautic is simply the more likely lane when operating a near-current Mautic 7 deployment.

## Does Not Prove

- That any private Mautic installation is configured, healthy, backed up, or safe to update.
- That a private install is Composer-based, package-based, or UI-update capable.
- That a private database, plugin set, theme, campaign, email transport, or cron setup is compatible with a release.
- That a release candidate should be used in production.
- That Mautic should become the source of truth for private business records.
- That this source trail replaces current official Mautic release notes or update documentation.
- That a private bug report is automatically safe to publish upstream without removing customer facts, private URLs, credentials, and business-specific workflow details.

## Recheck Rule

Before acting on a Mautic update or bug diagnosis:

1. Check the current official GitHub releases feed.
2. Prefer stable, non-prerelease tags for production.
3. Read the release notes for security advisories and upgrade cautions.
4. Check whether the installation is Composer-based before selecting update commands.
5. Back up and test in staging before production updates.
