# Public publication policy

This policy governs content in both public source repositories. Keep the copies
aligned when changing the shared rule. Agent entry points, contribution guides,
source standards and machine-readable discovery files must follow it.

## Publish supported public knowledge

Keep confirmed, source-backed corrections public. Accurate criticism of a named
provider, trainer or organization belongs here when the exact proposition has
public sources, attribution, checked dates and appropriate evidence limits.
Preserve findings and distinguish facts, attributed claims and editorial
inferences. An unresolved transaction question does not withdraw an independently
supported correction to a public representation.

Public authorship, public source URLs, public repository references relevant to
the source or contribution, and hashes of public artifacts are useful provenance.
Document reusable behavior of the code actually published in this repository.

## Exclude internal context

Do not publish internal-only repository names, URLs or paths; private commit,
branch, issue or pull-request identifiers; internal workflow or chat identifiers;
private prompts, operational instructions, deployment topology, account details,
billing or provider tactics, private pricing strategy or business playbooks.
Calling these details provenance, non-fetchable or non-authoritative does not make
them public-safe. Omit them from prose, JSON, indexes, generated exports, examples,
tests, commit messages and public issue or PR discussions.

Keep unsent correspondence, complaint-production state, internal follow-up plans
and unpublished investigation leads private. Public evidence limits and questions
needed to understand a published correction can remain, without disclosing the
internal work that prompted them.

Do not publish credentials, protected endpoints, customer or identity records,
payment data, private messages or unredacted evidence. A private input may guide
research; a public artifact must stand on its own public source trail.

## Prepare public projections

Export the public findings, cited sources and necessary evidence limits. Remove
internal metadata before creating a public blob or branch. A full internal ledger
is not automatically an acceptable public export. Preserve claim IDs and record
content unless the task separately authorizes a substantive correction.

When a projection changes, update its public commit pin, payload hash and every
discovery reference together. Record the verification actually performed; do not
carry an older readback, deployment or ingestion assertion onto changed bytes.
Private custody and source-revision records remain outside public artifacts.

## Check the proposed publication

Read the full diff, including JSON values, links, generated companions and public
PR text. Run `python3 tools/check_publication_boundary.py`, parse changed JSON and
run `git diff --check`. The checker detects unexpected publisher-owned repository
references and selected internal metadata fields; it cannot recognize every bare
private name or decide whether a claim is supported. Human source and privacy
review remains necessary.

The checker recognizes only the two public source repositories as publisher-owned
references. Add another only after verifying that it is public and relevant;
never put a private-name denylist into a public file.

Prepare a reviewable PR within the task's authority. Merge, deployment and live
workflow activation require task authorization; a completed check does not supply
it. If another document permits internal metadata as public provenance, follow
this policy and correct that conflicting guidance.
