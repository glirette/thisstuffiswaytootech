# Azure Communication Services Virtual Visits And Microsoft Bookings

Captured: 2026-06-13

Topic: `azure-communication-services-virtual-appointments`

## Public-Safe Conclusion

For a stack that mainly uses Azure Communication Services Virtual Visits plus Microsoft Bookings, `Azure-Samples/communication-services-virtual-visits-js` is still the better Microsoft sample base to track.

The related `Azure-Samples/communication-services-web-calling-hero` repository is useful as a comparison point for generic ACS calling UX and newer package versions, but it does not own the Bookings-centered virtual appointment pattern in the same way.

The `Azure/communication-ui-library` repository is the lower-level UI library source. It is important for component behavior, package version drift, and CallComposite/MeetingComposite capabilities, but it is not itself a focused virtual appointment deployment.

## Recommended Public-Safe Deployment Posture

Use a separate GitHub repository for the appointment/session app. Keep the Microsoft sample as an upstream source and maintain a small deployable overlay instead of copying the hard video/session logic into a multisite web app.

A focused deployment repo should generally:

- track `Azure-Samples/communication-services-virtual-visits-js` as upstream;
- keep deployment-specific changes small, documented, and reviewable;
- prefer environment/configuration changes over code edits when the sample already supports them;
- expose only a thin route or handoff from a separate public site;
- avoid making the public site own ACS token, meeting, room, or Teams interop logic unless there is a deliberate replacement project;
- keep private tenant, domain, support, customer, and workflow details out of public notes.

One stable branch shape is:

- `upstream/main`: Microsoft sample source fetched from `Azure-Samples/communication-services-virtual-visits-js`.
- `main`: deployable branch with the smallest possible overlay.
- PRs from upstream refreshes into `main`, with build/test checks before deployment.

GitHub's fork-sync documentation supports the general upstream-sync pattern, but it does not decide the deployment architecture or prove that an automatic upstream merge is safe for a branded production appointment app.

## Source Observations

As observed on 2026-06-13, the Virtual Visits sample repository:

- describes Azure Communication Services Virtual Appointments as a hostable branded virtual consultation web app;
- documents `/book` and `/visit` routes;
- includes a Microsoft Bookings setup guide;
- uses `VV_MICROSOFT_BOOKINGS_URL` / `microsoftBookingsUrl` for the Bookings page;
- instructs configuring Microsoft Bookings with the hosted app URL suffixed with `/visit`;
- lets staff join through Teams while clients join through the branded ACS web app;
- is a separate React/Node app, not a Razor Pages or .NET multisite module;
- was observed at commit `f7d04bb4a357a7fb0c1950a5b260f84928791e9c`, dated 2026-01-09;
- advertised sample version `1.5.0` in client/server package files;
- required Node.js `20.17.0 and above` in its README;
- pinned `@azure/communication-react` to `1.26.0` in the client package.

As observed on 2026-06-13, the web calling hero repository:

- is a generic group calling sample for `@azure/communication-react`;
- includes a React front end and Node/Express server that mints ACS tokens;
- was observed at commit `e4db62d07572af6bb92b4c9da47f7921776e765f`, dated 2025-11-13;
- used newer ACS UI/package versions than the Virtual Visits sample, including `@azure/communication-react` `^1.31.0`;
- did not present itself as the Microsoft Bookings virtual appointment sample.

As observed on 2026-06-13, the Azure Communication UI Library repository:

- contains `@azure/communication-react`;
- was observed at commit `a36c0911cf7a6252f5b5b05a65a96000b65a0aba`, dated 2026-02-17;
- showed `@azure/communication-react` version `1.32.0-beta.1` in the package metadata;
- can hit Windows checkout path-length problems because some test snapshot filenames are long.

## Supports

This source trail supports the following public-safe claims:

- The Virtual Visits sample is the best Microsoft sample starting point when Microsoft Bookings is part of the appointment workflow.
- The web calling hero sample is better treated as a generic calling reference, not as a drop-in replacement for a Bookings-centered virtual appointment deployment.
- The ACS UI Library is the component and package source to watch for SDK/UI drift.
- A separate upstream-tracking deployment repo is a cleaner architecture than importing the sample's hard ACS/Teams/room logic into a separate multisite application.

## Does Not Prove

This source trail does not prove:

- which version any private deployment currently runs;
- that any private Azure App Service, Microsoft Bookings calendar, tenant, Teams policy, ACS resource, DNS route, or production workflow is configured a particular way;
- that upstream `main` is safe to auto-deploy without review;
- that a sample app is production-ready without security, privacy, branding, accessibility, telemetry, and operational review;
- that a public multisite app should contain ACS token, meeting, room, or Teams interop code.

## Drift Risks

Re-check before acting on:

- current upstream commits and release tags;
- package versions for `@azure/communication-react`, `@azure/communication-calling`, `@azure/communication-rooms`, and `@azure/communication-identity`;
- Microsoft Bookings behavior and Graph API permissions;
- Teams interoperability requirements;
- ACS browser support and token rules;
- Azure App Service runtime and Node.js requirements;
- sample telemetry/privacy notices.

## Official And Project Sources

- Azure Samples Virtual Visits repository: https://github.com/Azure-Samples/communication-services-virtual-visits-js
- Virtual Visits Microsoft Bookings guide: https://github.com/Azure-Samples/communication-services-virtual-visits-js/blob/main/docs/microsoft-bookings.md
- Azure Samples web calling hero repository: https://github.com/Azure-Samples/communication-services-web-calling-hero
- Azure Communication UI Library repository: https://github.com/Azure/communication-ui-library
- Azure Communication UI Library documentation: https://azure.github.io/communication-ui-library/
- Azure Communication Services Teams interoperability: https://learn.microsoft.com/en-us/azure/communication-services/concepts/teams-interop
- Azure Communication Services Rooms concept: https://learn.microsoft.com/en-us/azure/communication-services/concepts/rooms/room-concept
- Azure Communication Services access tokens quickstart: https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/identity/access-tokens
- Microsoft Graph Bookings API overview: https://learn.microsoft.com/en-us/graph/api/resources/booking-api-overview
- GitHub syncing a fork: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork
