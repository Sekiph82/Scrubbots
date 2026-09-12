# M21-C001 V03 — Final Path-Safety + Direct-Evidence Reconciliation

You are the implementer/test runner. ChatGPT is the independent auditor.

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Cycle: `M21-C001`
Evidence output: `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`

This is intentionally a small final correction/validation pass. Do not broaden it.

## 0. Safe sync and required reading

Safely synchronize the local repository with `origin/main` while preserving every pre-existing owner/local tracked or untracked change. Do not use `reset --hard`, `clean -fd`, force push, or restore owner work merely to get a clean tree.

Read in this order:

1. root `TASKS.md`;
2. `CLAUDE.md`;
3. `coordination/AUDIT_POLICY.md`;
4. `coordination/AUDIT_INDEX.md`;
5. `coordination/sessions/M21-C001/CHATGPT_AUDIT_V01.md`;
6. `coordination/sessions/M21-C001/CHATGPT_AUDIT_V02.md`;
7. `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V03.md`;
8. `coordination/sessions/M21-C001/OWNER_DIFFICULTY_V1_SCOPE_NOTE.md`;
9. the accepted M09 path-resolution implementation / AL-010..017, especially AL-013.

V02 audit decision is:

`CHANGES_REQUIRED / F-M21-STRICT-003 RESIDUAL / V03_FINAL_PATH-SAFETY_AND_DIRECT-EVIDENCE_RECONCILIATION_REQUIRED`

F-M21-STRICT-001, F-M21-STRICT-002 and F-M21-STRICT-004 are accepted CLOSED. Do not redesign them.

## 1. Mandatory tracker-only V03 start commit

Before editing implementation/tests/evidence, update **only** the root `TASKS.md` Project Status lifecycle fields to:

- Current Milestone: M21
- Current Sprint: M21-C001 V03 — final path-safety + direct-evidence reconciliation
- Current Task: M21-C001-V03
- Current Task Status: IN_PROGRESS
- Next Task/Action: execute `coordination/sessions/M21-C001/CHATGPT_PROMPT_V03.md` and satisfy `CHATGPT_AUDIT_CRITERIA_V03.md`, then hand back for independent final M21 audit.
- Required Actor: CLAUDE
- Progress unchanged: `304/719` main+ui and `304/943` overall
- `lastCompletedTaskId` remains `M20-C001-V11`
- note that V02 closed F-001/F-002/F-004, while the one remaining F-M21-STRICT-003 path-resolution residual plus explicit direct-evidence cells are V03 scope; no M21/UI task row is closed.

Commit `TASKS.md` alone and push that tracker-only start commit to `origin/main` before implementation. Record its full SHA in `CLAUDE_LOG_V03.md`.

Do not stage any implementation file or owner/local work in the tracker-only commit.

## 2. Hard scope protection

Do NOT:

- change the owner-approved Hazard Bot source PNG;
- change any M19/M20 production gameplay file;
- redesign Difficulty V1 or edit `difficulty_rules.gd` / `production_level_validator.gd`;
- implement Level Factory, PixelLab/Art Intelligence integration, CampaignBuilder, scoring, win/lose, progression, economy or save;
- start M22/M23/M24 UI/touch work;
- refactor unrelated importer/gameplay architecture;
- close `SB-M21-*` or `SB-UI-014..016` checkboxes.

Protected identities are hard locks:

- owner source blob: `b565743ba52699899007882b750b7c8e7cdd00f9`
- owner source SHA-256: `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`
- CompleteClearingLoop blob: `06391839523cbc27e88a4b3ef12b730012cd45fa`
- ScrubbotDispatcher blob: `eee10149e4f116af6706beec832042352bf3a6dd`

## 3. Close the single F-M21-STRICT-003 residual: one filesystem path identity

The V02 builder currently resolves path identity in two different ways:

- `_canon()` explicitly bases bare-relative paths at `res://`;
- `_preflight_destination()` calls `ProjectSettings.globalize_path(raw_path)` directly and therefore does not use the same explicit bare-relative base.

Correct this with the smallest coherent implementation.

Create/reuse **one physical path resolver** with the accepted M09 semantics:

1. normalize separators;
2. `res://` / `user://` -> `ProjectSettings.globalize_path(...)`;
3. bare relative -> explicitly prefix/base at `res://` before globalization;
4. absolute path -> preserve as absolute;
5. simplify `.` / `..` lexically;
6. preserve physical path case for I/O;
7. apply Windows lowercasing only in a separate comparison-identity helper if needed.

Then ensure the builder's:

- source/destination alias checks;
- destination/destination alias checks;
- destination parent/object preflight;
- existing-file planning/comparison;
- final writes

are demonstrably consistent with that same resolved physical identity. Do not allow alias checks to reason about one path while preflight/write acts on another.

You may use the resolved absolute path internally for planning/writes while preserving the caller's logical path strings in metadata/errors, or another equally coherent minimal design. Do not silently alter the public artifact naming contract.

Do **not** rewrite the audited generic M09 importer to solve this M21-local problem.

## 4. Required direct path-safety tests against ProductionArtLevelBuilder

Add direct tests against the **new M21 builder**, not merely historical LevelImporter tests.

### 4.1 Legitimate bare-relative behavior

Create a controlled existing temporary directory inside the project and prove:

- bare-relative output succeeds at exactly the equivalent `res://...` physical location;
- bare-relative preview succeeds at its equivalent `res://...` location;
- bare-relative metadata succeeds at its equivalent `res://...` location;
- deterministic rerun remains `UNCHANGED`.

The test must fail if `_preflight_destination()` again interprets a bare relative path outside the explicit project base.

### 4.2 Equivalent aliases

Directly prove:

- bare-relative source-equivalent output is rejected and source bytes remain unchanged;
- bare-relative destination vs equivalent `res://...` destination aliases are rejected;
- where practical, bare-relative vs equivalent absolute destination aliases are rejected;
- dot-segment equivalent aliases remain rejected;
- `overwrite=true` never bypasses source alias protection.

### 4.3 Complete later-artifact failure matrix

Directly prove on the builder:

- existing-different output + `overwrite=false` -> reject before preview/metadata mutation;
- existing-different preview + `overwrite=false` -> reject before output/metadata mutation;
- existing-different metadata + `overwrite=false` -> reject before output/preview mutation;
- directory at output -> reject for both overwrite false/true;
- directory at preview -> reject for both overwrite false/true before output mutation;
- directory at metadata -> reject for both overwrite false/true before output/preview mutation;
- non-directory parent -> reject before any final write;
- bare-relative later preview/metadata missing parent -> reject before earlier output mutation.

Arrange at least one later-artifact test so removing the all-destination preflight would actually create a partial write. Assert the prior final artifacts are absent or byte-identical afterward.

Clean up only V03 temporary test artifacts. Never clean owner/local files.

## 5. Final direct real-art evidence reconciliation

Add a fresh V03 real-art arrangement using committed M21 LevelData and the real production collaborators. Do not use M20 fault seams/doubles for the authoritative path.

Before the blocked activation, directly assert:

- all 400 cells ACTIVE;
- C01 candidates = 30;
- C03 candidates = 5;
- C08 candidates = 298;
- C11 candidates = 11;
- C16 candidates = 56.

Preserve the V02 exact-zero-side-effect blocked non-C08 proof: snapshot all cell states, all five buckets, reservation truth/count, dispatcher truth and M20 clear count; real activation must return exactly `NO_REACHABLE_TARGET`; every snapshot property must remain exact.

Then on fresh real success state:

1. activate the C08 slot through real CompleteClearingLoop;
2. prove target is C08 + ACTIVE;
3. prove exact reservation target<->owner identity before arrival;
4. prove dispatcher owns the assignment before arrival;
5. prove the real ScrubbotAgent is MOVING;
6. drive authenticated arrival;
7. prove loop cleared_count increments by exactly one;
8. prove exact target becomes CLEARED;
9. prove candidate bucket no longer contains target;
10. prove reservation target->owner and owner->target truth are released;
11. prove dispatcher no longer owns that owner and active assignment count is cleaned up;
12. prove renderer alpha for that target is 0.

Continue real clears until at least one color that was blocked in the initial snapshot becomes genuinely reachable and clears through the real production path. No forced target, no fake candidate, no M20 fault seam.

These are direct reconciliation assertions, not permission to change gameplay production code.

## 6. Mandatory regression / reproducibility commands

Run and record exact results for:

1. `godot --version`;
2. full root suite: `godot --headless --path . -s res://tests/run_tests.gd`;
3. dedicated fresh `tests/m21_real_art_smoke.gd`;
4. all currently required M20 queue-free and V04/V05/V07/V08/V09/V10 lifecycle smokes;
5. headless boot/parse of `scenes/debug/m21_real_art_vertical_slice.tscn`;
6. `tools/build_m21_level.gd` canonical rerun, proving level/preview/metadata unchanged;
7. `tools/build_m21_reference_composite.gd` twice, proving second run unchanged;
8. final owner source Git blob + SHA-256 recheck;
9. final CompleteClearingLoop + ScrubbotDispatcher blob recheck;
10. literal scan of required outputs for `SCRIPT ERROR` and `Parse Error`;
11. `git diff --check`.

Keep V01 and V02 M21 tests enabled. Keep all prior M19/M20 tests enabled.

Headless elapsed time may be recorded as diagnostic only. Do not infer or claim mobile FPS/GPU performance.

## 7. Sensitivity statement required in CLAUDE_LOG_V03.md

Explain why the new tests are load-bearing:

- a legitimate bare-relative build would fail if preflight lost the `res://` base again;
- equivalent-path alias tests would fail if identity/preflight resolution diverged;
- preview/metadata conflict tests would expose any earlier artifact mutation;
- metadata-directory tests would expose missing final-object-type preflight;
- fresh candidate-count assertions come from real committed LevelData state;
- first-arrival cleanup checks use the actual returned target/owner identity rather than only end-of-level aggregate zeros.

## 8. V03 evidence log and handoff

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`

It must contain:

- synchronized starting GitHub commit;
- preserved owner/local work relevant to safe sync;
- tracker-only V03 start commit full SHA;
- exact implementation/handoff commit scope;
- exact changed files;
- F-M21-STRICT-003 residual closure table;
- direct path-safety matrix;
- V03 real-art direct-evidence matrix;
- every required command and actual result;
- failures encountered and how they were corrected;
- sensitivity/load-bearing explanation;
- final source SHA/blob and M20 blob rechecks;
- explicit statement that Claude closed no M21/UI task checkbox and authored no audit verdict.

At the end update only prompt-authorized root `TASKS.md` lifecycle fields to:

- Current Milestone: M21
- Current Sprint: M21-C001 V03 — final path-safety + direct-evidence reconciliation
- Current Task: M21-C001-V03
- Current Task Status: AWAITING_AUDIT
- Next Task/Action: independent V03 final M21 audit against `CLAUDE_LOG_V03.md` and `CHATGPT_AUDIT_CRITERIA_V03.md`
- Required Actor: CHATGPT
- Progress unchanged `304/719` and `304/943`
- `lastCompletedTaskId` remains `M20-C001-V11`

Push all authorized work safely to `origin/main`, never force push.

Then respond with exactly two lines:

`AWAITING_AUDIT`

and the direct GitHub blob URL for:

`coordination/sessions/M21-C001/CLAUDE_LOG_V03.md`

If this V03 reveals a genuinely new M19/M20 production defect, stop `BLOCKED`, record exact evidence, and do not patch the closed subsystem opportunistically.
