# Publication-boundary checker repair

Checked October 30, 2026. Scope: the standalone checker, its synthetic regression
tests, and this evidence note. The [publication policy](publication-policy.md),
public repository allowlist, destination rules, and technical source records are
unchanged.

## Original failure

At retained source `d39f8e5eb2d541a7f58d8ff65aaa8fdf19f050ad`, the original
eight tests passed and the whole-tree checker reported 51 UTF-8 files and zero
findings. However, valid JSON could conceal an unexpected publisher-owned
repository reference through ordinary JSON escaping. The raw-text rule did not
inspect decoded keys or string values. Uppercase `.JSON` also skipped JSON checks.

The repaired regression suite run against that original checker produced **12
expected subtest failures, zero errors**. All fixture names are synthetic.

| Synthetic control | Original checker | Repaired checker |
| --- | --- | --- |
| Slash-escaped reference in a JSON value | Missed | Rejected |
| Unicode-escaped slash in a JSON value | Missed | Rejected |
| Unicode-escaped slash in a JSON key | Missed | Rejected |
| Five further escaped key/value, nested, scalar and array controls | Missed | Rejected |
| Uppercase extension: escaped reference, selected metadata, production field, malformed JSON | Four misses | Four rejections |
| Five decoded public-reference/third-party controls and valid uppercase JSON | Allowed | Allowed |

The three new regression methods contain 18 rejection/allowance controls. The
original eight tests retain BOM acceptance, plain/percent-encoded references,
nested metadata, production fields, malformed JSON, supported criticism and
essential evidence limits.

## Repair and validation

The narrow checker/test repair applies the same reference expression, unchanged
allowlist and two-pass percent decoding to raw text and decoded JSON keys/string
values. It visits nested objects and arrays, accepts a leading UTF-8 BOM, treats
the JSON extension case-insensitively, and emits at most one reference finding
per file. Selected metadata findings remain separate.

The repaired checker blob is `f371576bec362f63cab822207d36ad6b48e4fabb`;
the regression-test blob is `d3e326e20280b08cdeb147ed5814225029cd5366`.

| Local check | Result |
| --- | --- |
| `python3 tools/test_publication_boundary.py` | 11 tests passed |
| `python3 tools/check_publication_boundary.py` | 52 UTF-8 files; zero findings, including this note |
| `python3 scripts/test-fetch-public-authority-feed.py` | All 6 offline contract tests passed; injected DNS/HTTP fakes |
| Tracked JSON parsing | All 21 parsed, with UTF-8 BOM support |
| Local inline Markdown file links | 12 targets exist; fragments and remote availability not checked |
| Source-index/topic integrity | 25 unique source IDs; all 26 starter-source references resolve |
| Destination negative fixture | Still differs from this consumer's declared destination |
| `git diff --check` | Passed |
| PowerShell validator/materializer contract suite | Not run: `pwsh` is unavailable |

Only the two Python files and this note change from the retained source. The 49
other tracked files retain their original bytes and modes. The PowerShell suite
still requires execution in an environment with PowerShell; the Python contract
results do not substitute for it. No provider or live feed was executed; no
workflow was dispatched and no deployment performed.

## Limits

This is a heuristic for selected patterns, not comprehensive privacy validation,
a secrets scan, or adjudication of source accuracy. It can miss bare names,
unselected correspondence-state language, unsupported encodings or references
encoded more than twice. JSON-specific traversal applies only to JSON-suffixed
files, and non-UTF-8 files are skipped. Duplicate JSON members overwritten during
parsing can hide escaped content from the decoded traversal. The retained raw
scan can flag a partial name when Unicode escapes occur inside an allowlisted
repository name. These misses and false positives also occur in the original
checker. Pattern matches can require human interpretation, including benign
examples of an unlisted owned reference.
Human review of the complete public diff and publication text remains necessary.
Passing checks do not establish deployment, anonymous availability or release
approval.
