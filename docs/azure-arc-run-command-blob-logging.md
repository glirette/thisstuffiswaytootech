# Azure Arc Run Command Blob Logging

Captured: 2026-06-14

Topic: `azure-arc-run-command-operations`

## Public-Safe Conclusion

Azure Arc Run Command is a useful administrative execution rail for Arc-enabled servers, but it should be treated as asynchronous infrastructure management, not as a real-time work loop.

For commands with meaningful output, use Azure Blob-backed output and error streams instead of relying on the small platform-visible command tail. Microsoft documents `outputBlobUri` and `errorBlobUri` support for Run Command, and the Azure CLI exposes matching `--output-blob-uri` and `--error-blob-uri` options.

For deployable support resources such as the Blob container used for logs, prefer ARM/Bicep artifacts and repeatable wrappers over portal clicks or one-off terminal commands. When an Azure CLI deployment can be long-running, use the CLI's nonblocking deployment option where appropriate and poll deployment/resource state separately.

## Source Observations

As observed on 2026-06-14, Microsoft Learn's Azure Arc Run Command documentation says:

- Run Command lets Azure direct the Connected Machine agent on an Arc-enabled server to run scripts without direct SSH or RDP.
- Arc Run Command is available through Azure CLI, PowerShell, and REST API.
- It works for Windows and Linux Arc-enabled servers.
- Linux Run Command names have a documented name-length limit.
- Script output and error streams can be sent to output and error AppendBlobs.
- Output/error blob SAS URIs need permissions that allow read, append, create, and write, unless an approved managed identity path is used.
- Run Command is built for administrative tasks such as software install/update, health checks, troubleshooting, firewall configuration, and security remediation.

As observed on 2026-06-14, Azure CLI help for `az connectedmachine run-command create` exposes:

- `--script` and script URI inputs;
- `--timeout-in-seconds`;
- `--output-blob-uri`;
- `--error-blob-uri`;
- managed identity options for output/error blobs.

As observed on 2026-06-14, Azure CLI help for `az deployment group create` exposes:

- `--no-wait` for nonblocking ARM deployment submission;
- `--what-if` and `--confirm-with-what-if` for deployment preview flows.

## Recommended Public-Safe Deployment Posture

Use a small replaceable logging resource group and storage account for Arc Run Command logs when the goal is durable command evidence.

A clean pattern is:

1. Define the storage account and container in Bicep.
2. Validate/build the template before deployment.
3. Submit deployment through Azure CLI, GitHub Actions, or another repeatable runner.
4. Use short-lived SAS URIs for stdout/stderr AppendBlob targets.
5. Run the Arc command with `--output-blob-uri` and `--error-blob-uri`.
6. Store only redacted blob URLs, deployment names, command names, and status evidence in public notes.
7. Keep full SAS URIs, secrets, account identifiers, private hostnames, customer facts, and production topology out of public notes.

## Supports

This source trail supports these public-safe claims:

- Arc Run Command can execute administrative scripts on Arc-enabled Windows or Linux servers without direct SSH/RDP.
- Arc Run Command output/error streams can be persisted to Blob storage instead of depending only on platform-visible output.
- Blob-backed command logging is a reasonable Azure-native answer to output truncation and durable evidence needs.
- ARM/Bicep plus a repeatable wrapper is a cleaner long-term pattern than hand-running one-off infrastructure commands.
- `az deployment group create --no-wait` is the right shape when the deployment should be submitted and then tracked separately.

## Does Not Prove

This source trail does not prove:

- that a private Arc-enabled server is connected, healthy, or authorized;
- that any specific private storage account or resource group exists;
- that a specific command succeeded;
- that a deployment should skip validation in production;
- that SAS URIs should be logged, shared, or stored;
- that Arc Run Command is the right lane for high-volume work dispatch.

## Drift Risks

Re-check before acting on:

- current Arc Run Command preview/GA status;
- CLI argument names and behavior for `az connectedmachine run-command create`;
- blob auth support and managed identity behavior;
- Azure deployment CLI flags and long-running operation behavior;
- Run Command limits, name length, timeout behavior, and output behavior;
- RBAC requirements for creating Run Command resources and generating user delegation SAS tokens.

## Official Sources

- Azure Arc-enabled servers Run Command: https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command
- Azure CLI `az connectedmachine run-command`: https://learn.microsoft.com/en-us/cli/azure/connectedmachine/run-command
- Azure CLI `az deployment group create`: https://learn.microsoft.com/en-us/cli/azure/deployment/group
- Azure Resource Manager Bicep overview: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview
