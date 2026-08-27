---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M09-C001
version: 3
createdAt: 2026-08-28T00:02:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
supersedes: CHATGPT_PROMPT_V02.md
triggerAudit: CHATGPT_AUDIT_V02.md
auditedImplementationHead: 61172cee24c3996729370cfbba4f54f3c2f9833d
taskRefs:
  - SB-M09-017
---

# SCRUBBOTS - M09-C001 Filesystem Identity Correction Prompt V03

## Objective

Close the single remaining finding from ChatGPT independent audit V02: equivalent filesystem paths must not bypass source-immutability or cross-artifact alias checks.

Do not redesign already-correct importer behavior. Keep this pass narrow.

## Mandatory GitHub sources

Read these before modifying anything:

1. Project manual:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Task ledger:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
5. Audit index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
6. Prior audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md
7. Independent audit V02 that triggered this pass:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md
8. Audit criteria V03:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V03.md
9. Existing Claude implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md
10. This active prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md
11. Current importer:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
12. Current importer tests:
    https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd

## Finding to close

`F-M09-005`: current path comparison normalizes `res://`, `user://`, separators, and Windows case, but does not fully normalize `.` / `..` or general relative-vs-absolute identity.

The locked guarantee is stronger than string normalization:

**No source path may ever resolve to a derived write destination, and no two derived artifacts may resolve to the same destination.**

This must hold even when equivalent filesystem targets are written using different syntax.

## Required implementation

1. Keep one path-identity helper used by all source/output/preview/metadata alias checks.
2. Resolve `res://` and `user://` consistently.
3. Resolve general relative filesystem paths against one explicit, documented base that matches how this CLI/importer actually opens those paths.
4. Simplify `.` and `..` path segments before comparison using Godot-supported path operations.
5. Normalize separators.
6. Preserve Windows case-insensitive comparison behavior.
7. Compare source against every destination using the normalized identity.
8. Compare every destination pair using the normalized identity.
9. If a path category cannot be safely converted to a comparable filesystem identity, fail closed with an actionable error instead of assuming it is distinct.
10. Do not introduce symlink-resolution claims unless they are actually implemented and testable. Document that symbolic-link identity is outside this correction if it cannot be reliably resolved in the current Godot runtime.

Do not weaken the existing `overwrite=true` rule. Overwrite may replace a distinct derived artifact only; it must never authorize source destruction or destination aliasing.

## Mandatory targeted tests

Add specific tests that prove the new normalization rather than repeating exact-string aliases.

At minimum include:

1. source TEST PNG referenced as canonical path, output expressed as an equivalent `./` path, rejected before writes;
2. source TEST PNG referenced through one syntax, output expressed using a `subdir/../` equivalent path, rejected before writes;
3. equivalent relative-vs-absolute source/output path rejection where supported by the test environment;
4. destination-to-destination alias using different `.` / `..` syntax, rejected before writes;
5. `overwrite=true` on an equivalent source alias is still rejected;
6. source bytes verified unchanged after each source-alias attempt;
7. a legitimate pair of distinct normalized paths still succeeds, proving the guard is not simply rejecting all relative paths.

Keep all existing V02 safety tests.

## Regression requirements

Do not regress:

- PNG-only gate;
- valid JPEG unsupported-format rejection;
- corrupt `.png` decode failure distinction;
- preview/metadata/Level JSON all-artifact preflight;
- identical artifact unchanged behavior;
- malformed reconstruction guards;
- exact RGBA8 round-trip;
- deterministic first-seen palette;
- row-major cells;
- TEST/production split;
- 20x27 rectangular coverage;
- 59x59 maximum coverage;
- Level Data V1 schema;
- no owner artwork.

Run the full test suite and report the actual new total. Do not assume 320.

## Task truth

This correction specifically revalidates `SB-M09-017`.

Do not mark or start:

- SB-M09-018 batch import;
- SB-M09-019 batch validation;
- SB-M09-020 duplicate level ID protection;
- any M08 item;
- any M10/M11 or later work.

## Logging

Append a new Session 3 entry to:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md

Record:

- starting commit;
- Audit V02 URL;
- `F-M09-005` and `AL-013`;
- exact path-normalization implementation;
- all targeted equivalent-path tests and actual results;
- full regression result;
- any failed approaches/debugging;
- git diff/status;
- correction commit and push evidence.

Claude must not create any audit or self-audit file.

## Mandatory final validation

Individually record:

1. `godot --version`
2. `powershell -File tools\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. targeted CLI/source-alias rejection using an equivalent dot-segment or relative path, with source byte preservation
6. targeted destination-to-destination equivalent-path rejection
7. a valid distinct-path CLI import still succeeds
8. deterministic rerun still reports unchanged behavior
9. raw reconstruction equality for at least 3x2 and 59x59 remains intact
10. `git diff --check`
11. inspect final diff for scope integrity
12. `git status --short` before commit
13. commit
14. push to `origin/main` without force
15. final `git status --short`

Use `CLAUDE_TEST_PASS`, `CLAUDE_TEST_FAIL`, `NOT_RUN`, or `BLOCKED` in the implementation log. Never assign an audit verdict.

## Handoff

When complete:

1. update https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
2. update https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
3. set `M09-C001` to `AWAITING_AUDIT` only if the correction and validation completed;
4. push safely;
5. stop.

Do not start M09-C002.

## Expected Claude final response

Keep it short:

- `Cycle: M09-C001`
- state;
- correction commit/push;
- implementation-log URL;
- full test total;
- targeted path-safety result summary;
- blockers if any;
- `READY FOR CHATGPT AUDIT` when appropriate.