# GitHub Actions Workflow Dispatch And Azure CLI Automation Output

Captured: 2026-06-15

Topic: `github-actions-and-cli-automation`

## Public-Safe Conclusion

When building GitHub Actions control-plane workflows, remember that manually dispatched workflows are controlled by GitHub's default-branch workflow discovery behavior. A new `workflow_dispatch` workflow may not be manually runnable from the GitHub API or CLI until the workflow file exists on the repository's default branch.

When using Azure CLI from automation scripts, do not assume every successful command produces clean JSON. Some commands produce status text, warnings, progress, or empty output. Use Azure CLI global output controls, suppress nonessential warnings when appropriate, and separate JSON-returning commands from commands that should only be checked for exit code.

## Source Observations

As observed on 2026-06-15, GitHub's official Actions documentation for `workflow_dispatch` includes a default-branch requirement for that event. This matters when a pull request adds a brand-new manually dispatched workflow: the branch may contain the workflow file, but the manual-dispatch endpoint may still fail until the file is present on the default branch.

As observed on 2026-06-15, Microsoft Learn documents Azure CLI global parameters including output format controls and `--only-show-errors`. This matters for scripts that parse Azure CLI output as JSON. A command wrapper should distinguish between:

- commands expected to return JSON, where stdout should be parsed only after exit code success;
- commands expected to perform an action, where success should be based on exit code and not on parsing status/progress text as JSON;
- commands where warning noise should be suppressed with official CLI flags when appropriate.

## Recommended Public-Safe Automation Posture

For GitHub Actions:

1. Treat new `workflow_dispatch` files as not fully manually dispatchable until they land on the default branch.
2. Test the workflow logic locally or through existing workflows before merge when possible.
3. After merge, run a validation-only workflow dispatch before enabling mutating or spending behavior.

For Azure CLI wrappers:

1. Use explicit output format expectations.
2. Parse JSON only from commands that are intended to return JSON.
3. Use exit-code-only wrappers for upload, download, create, and other action/status commands.
4. Use `--only-show-errors` when warnings would otherwise pollute automation output.
5. Keep credentials, SAS URLs, account IDs, tenant IDs, and private endpoints out of public notes.

## Supports

This source trail supports these public-safe claims:

- A new GitHub Actions manual-dispatch workflow may need to exist on the default branch before it can be dispatched through standard workflow-dispatch paths.
- Azure CLI automation should not blindly pipe every successful command into a JSON parser.
- `--only-show-errors` is an official Azure CLI global option that can reduce warning noise in automation.
- Robust CLI wrappers should separate JSON parsing from exit-code checking.

## Does Not Prove

This source trail does not prove:

- that a private workflow, runner, token, or repository is configured correctly;
- that any specific private workflow run succeeded or failed;
- that warnings should always be hidden;
- that CLI output formats or workflow-dispatch behavior will never change;
- that a new workflow should be merged without review just to make it dispatchable.

## Drift Risks

Re-check before acting on:

- GitHub Actions `workflow_dispatch` default-branch behavior;
- GitHub CLI workflow dispatch behavior;
- Azure CLI global parameters and output behavior;
- Azure CLI preview command warning behavior;
- any command-specific output format or status message behavior.

## Official Sources

- GitHub Actions `workflow_dispatch` event documentation: https://docs.github.com/en/actions/reference/events-that-trigger-workflows#workflow_dispatch
- GitHub CLI workflow run documentation: https://cli.github.com/manual/gh_workflow_run
- Azure CLI reference index and global parameters: https://learn.microsoft.com/en-us/cli/azure/reference-index
- Azure CLI output formats: https://learn.microsoft.com/en-us/cli/azure/format-output-azure-cli
