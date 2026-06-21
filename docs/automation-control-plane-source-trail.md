# Automation Control Plane Source Trail

Captured: 2026-06-21

## Public Sources

- Microsoft Learn: Azure DevOps REST API, Run Pipeline  
  https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline?view=azure-devops-rest-7.1
- Microsoft Learn: Azure DevOps CLI, `az pipelines`  
  https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest
- Temporal documentation  
  https://docs.temporal.io/
- Dagger documentation  
  https://docs.dagger.io/
- Kestra documentation  
  https://kestra.io/docs

## What These Sources Support

- Azure DevOps pipelines can be queued and inspected through official REST and CLI surfaces.
- A control layer can treat Azure DevOps as one backend instead of making every operator or agent depend directly on CLI behavior.
- Durable workflow/orchestration systems such as Temporal, Dagger, and Kestra are public candidates for workflow control-plane research.
- A resilient automation fabric should preserve run requests, run IDs, parameters, status, logs, artifacts, and retry decisions outside a single chat session.

## What These Sources Do Not Prove

- They do not prove that any private Azure DevOps organization, token, runner, pipeline, or service connection is configured correctly.
- They do not prove that Azure DevOps should be replaced.
- They do not reveal private runner names, private repository topology, secrets, queue payloads, customer data, or internal prompts.
- They do not prove that any one open-source orchestration engine is the right choice without a separate fit review.

## Public-Safe Posture

Use official Azure DevOps REST APIs as the stable public reference for run orchestration. Treat CLI commands as useful operator tools and fallback diagnostics, but avoid making the CLI itself the only automation contract.

For open-source alternatives, capture source trails first, then evaluate with a bounded matrix: local development fit, self-hosting burden, secrets model, artifact model, retry semantics, Windows/Linux ergonomics, and whether the system can run without an interactive desktop agent.

