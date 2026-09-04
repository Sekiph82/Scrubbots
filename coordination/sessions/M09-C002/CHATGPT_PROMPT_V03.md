---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M09-C002
version: 3
createdAt: 2026-09-04T08:54:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
supersedes: CHATGPT_PROMPT_V02.md
triggerAudit: CHATGPT_AUDIT_V02.md
auditedImplementationHead: a95ca5bff646e9e8f2a1382303be2df14d847ace
taskRefs:
  - SB-M09-018
  - SB-M09-019
  - SB-M09-020
---

# SCRUBBOTS - M09-C002 Destination-Type Preflight Correction V03

## Objective

Close only `F-M09B-006` from ChatGPT independent audit V02.

The V02 catalog-root, catalog-health, bidirectional ownership, optional-schema-type, destination-parent, deterministic-reporting, duplicate-ID, path-identity, and M09-C001 importer corrections are accepted baseline behavior for this pass. Preserve them.

Do not start another milestone.

## Mandatory GitHub sources

Read before changing code:

1. Independent audit V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md
2. Active audit criteria V03:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md
3. This active prompt:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md
4. Previous audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md
5. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
6. Current implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md
7. Current batch importer:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_batch_importer.gd
8. Audited single importer:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
9. Current tests:
   https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd
10. Canonical task truth:
    https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
11. Session index:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
12. H!veAI dashboard:
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

## Audit learnings to apply

At minimum read, apply, and log:

- `AL-009`
- `AL-010`
- `AL-011`
- `AL-012`
- `AL-013`
- `AL-014`
- `AL-015`
- `AL-016`
- `AL-017`

## Locked scope

This is a narrow M09-C002 correction only.

Do not start M08, M10, M11, gameplay, slots, routing, agents, progression, saves, mobile export, runtime LevelCatalog work, or owner-art ingestion.

Do not redesign the M09-C001 importer or the M09-C002 batch architecture.

## Required implementation

Extend the existing read-only batch destination preflight so it validates both:

1. the destination parent exists and is a directory, as V02 already does;
2. the final resolved destination path itself is **not an existing directory**.

Apply this to every requested final destination role:

- Level JSON output;
- preview PNG;
- metadata sidecar.

Use the existing case-preserved real-filesystem resolver:

`LevelImporter._resolve_path()`

Do not introduce a second path-resolution algorithm.

### Required behavior

- If the resolved final destination is an existing directory, add an actionable item-level preflight error naming the role/path.
- The failure must occur before the commit loop starts.
- Validation-only mode must remain read-only and must not create/remove/rename anything.
- A later item whose destination is a directory must prevent an earlier otherwise-valid item from writing.
- Existing regular files must continue to follow the audited overwrite/unchanged semantics. Do not reject a normal existing file merely because it exists.
- Preserve catalog ownership and all V02 fail-closed behavior.
- Preserve the bounded non-transactional statement for genuinely post-preflight OS failures.
- Do not claim that this check proves arbitrary filesystem writability, ACL/permission stability, disk capacity, or symlink identity.

## Required targeted tests

Add tests that isolate the destination-object-type failure itself.

At minimum:

1. Later item output path is an existing directory whose parent is valid:
   - batch fails;
   - earlier valid item remains unwritten;
   - failure message identifies output destination type.
2. Preview path is an existing directory:
   - batch fails before any final write.
3. Metadata path is an existing directory:
   - batch fails before any final write.
4. Validation-only run with a directory destination:
   - fails;
   - creates no file/directory and removes nothing.
5. Same directory-target case with `overwrite=true`:
   - still fails; overwrite cannot turn a directory into a file target.
6. Existing regular Level JSON file:
   - unchanged/overwrite semantics remain exactly as before.
7. Existing regular preview/metadata artifacts:
   - existing audited unchanged/overwrite behavior remains green.
8. Full previous M09-C002 and M09-C001 regression suite remains green.

Negative tests must not rely on a missing parent, invalid catalog root, duplicate ID, malformed manifest, or other earlier error. Construct valid surrounding state so the destination's own directory type is the reason for failure.

## Mandatory real CLI checks

Run and log individually:

1. `godot --version`
2. `powershell -File tools\\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. full `tests/run_tests.gd`
5. real CLI later-item output-is-directory rejection, proving earlier item was not written
6. real CLI preview-is-directory rejection
7. real CLI metadata-is-directory rejection
8. real CLI validation-only directory-target rejection with no mutation
9. real CLI directory-target rejection with `overwrite=true`
10. real CLI existing-regular-file same-entry re-import / unchanged behavior still works
11. re-run at least the critical V02 catalog-root/catalog-health/path-ownership negative cases or explicitly execute the existing full suite that covers them, with named evidence
12. confirm no owner SCRUBBOTS artwork was fabricated/ingested
13. `git diff --check`
14. inspect final diff for scope integrity and accidental binary/cache/temp files
15. `git status --short` before commit
16. commit with a precise M09-C002 V03 correction message
17. push to `origin/main` without force
18. final `git status --short`

Record expected outcome, explicit fail condition, actual result, and classification for every mandatory step.

## Documentation and task truth

Update durable documentation only where actual behavior changed.

Update `tasks.md` evidence for SB-M09-018/019/020 only after the corrected behavior and full validation are complete.

Do not mark any other milestone complete.

## Logging and handoff

Append to:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md

Update:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md

https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

Claude implements, tests, and logs only. Claude must not create audit or self-audit files.

When complete, set M09-C002 to `AWAITING_AUDIT`, push safely, and stop.
