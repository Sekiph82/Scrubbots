---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M07-C001
version: 4
createdAt: 2026-08-27T16:03:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M07
taskRefs:
  - SB-M07-001
  - SB-M07-002
  - SB-M07-003
  - SB-M07-004
  - SB-M07-005
  - SB-M07-006
  - SB-M07-007
  - SB-M07-008
  - SB-M07-009
  - SB-M07-010
  - SB-M07-011
  - SB-M07-012
  - SB-M07-013
  - SB-M07-014
  - SB-M07-015
  - SB-M07-016
  - SB-M07-017
supersedes: CHATGPT_PROMPT_V03.md
triggerAudit: CHATGPT_AUDIT_V01.md
---

# SCRUBBOTS - M07-C001 Correction Prompt V04

## Objective

Correct the two findings from ChatGPT independent audit V01, record the complete required validation sequence in the existing Claude implementation log, and return the same cycle to `AWAITING_AUDIT`.

Do not expand scope beyond these corrections.

## Mandatory GitHub sources

Read these before modifying anything:

1. Project operating manual:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical task ledger:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Coordination protocol:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. Session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. Audit policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
7. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. Independent audit that triggered this correction:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md
9. Existing append-only Claude implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md
10. This active correction prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md

Historical scope/criteria may be consulted when useful:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md

The old criterion requiring a Claude self-audit is superseded by the owner's corrected workflow. Claude does not create audit or self-audit files.

## Prior audit findings that must drive this pass

### F-M07-001 - Unsupported metadata

Audit V01 found that:

`assets/art/references/inventory.json`

contains:

`"originalFilename": "akilta-wordmark-a1.svg"`

for `akilta_wordmark`, while the audited GitHub evidence establishes only the repository file:

https://github.com/Sekiph82/Scrubbots/blob/main/assets/brand/akilta-wordmark.svg

Required correction:

- set `akilta_wordmark.originalFilename` to `null`;
- do not infer or invent replacement source metadata;
- preserve all other inventory truth unless fresh repository evidence requires a correction.

Apply audit learning `AL-008` from:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

### F-M07-002 - Missing validation traceability

Audit V01 found that the previous implementation log did not explicitly record all prompt-required validation commands.

Required correction:

Run the complete validation sequence below on the corrected repository state and append every command/result individually to the existing `CLAUDE_IMPLEMENTATION_LOG.md`.

Apply audit learning `AL-009`.

## Implementation scope

1. Safely synchronize the local repository with `origin/main` without destroying local owner work.
2. Continue the existing local phase log:
   `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M07_LOG.md`
3. Append a new Claude session entry to the existing GitHub implementation log. Do not rewrite previous entries.
4. In that new log entry explicitly state how `F-M07-001`, `F-M07-002`, `AL-008`, and `AL-009` changed this pass.
5. Change only the unsupported Akilta `originalFilename` metadata to `null`, unless another file must change strictly for coordination/log synchronization.
6. Preserve the current M07 task truth:
   - SB-M07-001..007 remain complete;
   - SB-M07-008..014 remain open and `AWAITING OWNER ASSET`;
   - SB-M07-015..017 remain complete.
7. Preserve M10 as an owner-controlled design gate.
8. Do not add artwork, placeholders, importer work, gameplay work, M08 work, or unrelated refactors.

## Mandatory validation sequence

Run and record every item separately in `CLAUDE_IMPLEMENTATION_LOG.md` with command/check, expected outcome, explicit failure condition, actual result, and Claude test result.

1. `godot --version`
   - Expected: installed Godot 4.7.x project-compatible version.
   - Fail if unavailable or materially inconsistent with the project baseline.

2. `powershell -File tools\verify_project.ps1`
   - Expected: exit 0 / project verification succeeds.
   - Fail on any reported verification failure or non-zero exit.

3. `godot --headless --path . --quit-after 5`
   - Expected: clean startup/parse smoke without fatal project errors.
   - Fail on fatal parse/runtime/startup errors or non-zero failure attributable to the project.

4. `godot --headless --path . -s res://tests/run_tests.gd`
   - Expected: full regression suite passes.
   - Record the actual pass/total count. Do not assume 227/227 without running it.
   - Fail on any regression failure or non-zero exit.

5. Independently parse/check `assets/art/references/inventory.json` with an available built-in/local runtime.
   Verify all of the following:
   - JSON parses successfully;
   - exactly 9 asset entries;
   - asset IDs are unique;
   - exactly 7 entries have `availabilityStatus == "MISSING"`;
   - all MISSING entries have `repositoryPath == null`;
   - all MISSING entries have `width == null`, `height == null`, and `candidateDifficulty == null`;
   - `akilta_wordmark.sourceClass == "PROJECT_BRANDING"`;
   - `akilta_wordmark.repositoryPath == "assets/brand/akilta-wordmark.svg"`;
   - `akilta_wordmark.originalFilename == null`;
   - Colony Flow remains text-only external inspiration, not a copied asset.

6. `git diff --check`
   - Expected: clean.
   - Fail on whitespace/error output.

7. Final `git status --short`
   - Record the exact output before commit and again after commit/push as appropriate.
   - Ensure the local Desktop phase log, `.godot/`, secrets, build artifacts, arbitrary images, or unrelated files are not committed.

Claude-run checks are implementation evidence only. Use implementation-log result labels such as `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL`; do not assign audit verdicts.

## Logging and Git requirements

Append only to:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md

The new entry must include:

- actual starting commit;
- prior audit URL;
- F-M07-001 and F-M07-002;
- AL-008 and AL-009;
- exact file change;
- every validation command above and exact result;
- any failure/fix history;
- final commit URL and push result;
- remaining owner-asset blockers.

Commit/push safely to `origin/main`. Never force-push.

Do not create or modify:

- `CHATGPT_AUDIT_VNN.md` files;
- `CLAUDE_SELF_AUDIT_VNN.md` files;
- historical prompt files.

The historical `CLAUDE_SELF_AUDIT_V01.md` remains untouched as old evidence from the superseded workflow.

## Coordination handoff

Before ending:

1. update https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
2. update https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
3. set `M07-C001` to `AWAITING_AUDIT` if the correction and required checks are complete;
4. set `BLOCKED` only if there is a real blocker;
5. stop and wait for ChatGPT independent audit V02.

Do not mark `AUDITED_PASS`.

Do not start M08.

## Expected Claude final response

Keep the chat response short. Include only:

- `Cycle: M07-C001`
- cycle state;
- correction commit + push status;
- implementation log URL;
- short Claude-run validation summary;
- blockers, if any;
- `READY FOR CHATGPT AUDIT` when appropriate.
