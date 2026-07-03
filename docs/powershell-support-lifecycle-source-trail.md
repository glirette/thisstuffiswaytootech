# PowerShell Support Lifecycle Source Trail

Captured: 2026-07-03

Topic: `serverless-workers-and-functions`

## Public-Safe Conclusion

For new automation, runner, and scripting decisions that depend on PowerShell support windows, use Microsoft's official PowerShell support lifecycle page as the controlling source.

As observed on 2026-07-03, Microsoft Learn listed PowerShell 7.6.3 as the current Long Term Servicing release, PowerShell 7.4.17 as the previous LTS release, PowerShell 7.4 support through 10-Nov-2026, and PowerShell 7.6 LTS support through 14-Nov-2028.

## Source Observations

Microsoft's PowerShell support lifecycle page distinguishes stable releases from Long Term Servicing releases. It says an LTS release of PowerShell is aligned to an LTS release of .NET, and that updates to an LTS release focus on critical security updates and servicing fixes.

The same page includes a support table for PowerShell releases. At capture time, the page showed:

- current LTS: PowerShell 7.6.3;
- previous LTS: PowerShell 7.4.17;
- PowerShell 7.4 LTS support end: 10-Nov-2026;
- PowerShell 7.6 LTS support end: 14-Nov-2028.

## Recommended Public-Safe Automation Posture

1. Prefer current PowerShell LTS for new cross-platform automation unless a host platform has a narrower supported runtime list.
2. Treat Windows PowerShell 5.1 compatibility as an explicit requirement, not an accidental default.
3. Re-check host-specific runtime support before changing Azure Functions, GitHub Actions, Azure DevOps, container, or Linux service runtime targets.
4. Avoid treating a local shell version as proof that a hosted runtime supports the same PowerShell version.

## Supports

This source trail supports these public-safe claims:

- Microsoft's official docs identify PowerShell release support windows.
- PowerShell 7.6.3 was the current LTS version on the captured date.
- PowerShell 7.4.17 was still supported on the captured date, with support listed through 10-Nov-2026.
- PowerShell 7.6 LTS support was listed through 14-Nov-2028.
- Automation that depends on support windows should re-check the official lifecycle page before making operational decisions.

## Does Not Prove

This source trail does not prove:

- that a private host has PowerShell installed;
- that a private Azure Function, runner, pipeline, container, or workstation supports a specific PowerShell runtime;
- that a private script is compatible with PowerShell 7 or Windows PowerShell 5.1;
- that upgrading any private runtime is safe without tests;
- that hosted platform runtime support is identical to the general PowerShell support lifecycle.

## Drift Risks

Re-check before acting on:

- current PowerShell LTS version;
- PowerShell release support dates;
- Azure Functions PowerShell worker support;
- GitHub Actions runner images and shell versions;
- Azure DevOps hosted or self-hosted runner PowerShell installation details;
- operating-system-specific installation guidance.

## Official Sources

- Microsoft Learn PowerShell support lifecycle: https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle
