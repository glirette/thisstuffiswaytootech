# Mautic 7 Release Source Trail

Reviewed: 2026-06-26

## Purpose

Public-safe source trail for Mautic 7 release metadata, stable-versus-prerelease status, update documentation, and version-specific documentation caution.

Use this note to avoid stale Mautic 4/5/6 assumptions when planning Mautic 7 work. This is a finding aid, not a private deployment runbook.

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

- Identify that `7.1.2` is a stable Mautic release tag that was published after `7.1.0`.
- Identify that the `7.1.2` release notes describe it as a security release and advise backup and staging testing before updating.
- Identify that `7.2.0-rc` is marked as a prerelease/release candidate and that its release notes say not to use it in production.
- Re-check Mautic 7.1 docs and GitHub releases before relying on old Mautic 4/5/6 tutorials.
- Pay special attention to version drift around forms, APIs, campaigns, plugins, cron/update commands, and email behavior.

## Does Not Prove

- That any private Mautic installation is configured, healthy, backed up, or safe to update.
- That a private install is Composer-based, package-based, or UI-update capable.
- That a private database, plugin set, theme, campaign, email transport, or cron setup is compatible with a release.
- That a release candidate should be used in production.
- That any private organization should follow a particular update cadence.
- That this source trail replaces current official Mautic release notes or update documentation.
- That a private bug report or fix is automatically safe to publish upstream without removing customer facts, private URLs, credentials, and business-specific workflow details.

## Recheck Rule

Before citing Mautic 7 release or update facts:

1. Check the current official GitHub releases feed.
2. Distinguish stable release tags from prerelease tags.
3. Read the release notes for security advisories and upgrade cautions.
4. Check the current official update documentation before selecting update commands.
