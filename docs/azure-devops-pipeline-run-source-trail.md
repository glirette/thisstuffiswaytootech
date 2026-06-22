# Azure DevOps Pipeline Run Source Trail

Captured: 2026-06-21

## Public Sources

- Microsoft Learn: Azure DevOps REST API, Run Pipeline  
  https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline?view=azure-devops-rest-7.1
- Microsoft Learn: Azure DevOps CLI, `az pipelines`  
  https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest

## What These Sources Support

- Azure DevOps pipelines can be queued and inspected through official REST and CLI surfaces.
- The REST API documents the public request shape for queueing a pipeline run.
- The Azure DevOps CLI documentation is a public reference for available pipeline commands.

## What These Sources Do Not Prove

- They do not prove that any private Azure DevOps organization, token, runner, pipeline, or service connection is configured correctly.
- They do not describe any private automation design, repository topology, queue payload, customer data, or deployment procedure.
- They do not prove that a private pipeline run was requested, succeeded, failed, retried, or deployed anything.

## Public-Safe Posture

Use official Microsoft documentation when citing Azure DevOps pipeline run capabilities. Keep private runbooks, automation architecture, queue records, runner details, credentials, and deployment procedures out of this public cache.

