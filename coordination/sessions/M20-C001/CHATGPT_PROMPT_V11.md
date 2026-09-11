# M20-C001 V11 — Final Direct-Assertion Reconciliation

You are Claude, validation/test runner only. ChatGPT owns independent audit verdicts, SB task closure, progress advancement, and M21 authorization.

Repository:
`https://github.com/Sekiph82/Scrubbots`

Canonical live tracker: repository-root `TASKS.md` ONLY.

## Read first

Read directly from GitHub/current `origin/main`:
- `TASKS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V10.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V11.md`
- `coordination/sessions/M20-C001/CHATGPT_PROMPT_V10.md`
- `coordination/sessions/M20-C001/CLAUDE_LOG_V10.md`

V10 verdict is **PRODUCTION_ACCEPTED / CHANGES_REQUIRED / V11_VALIDATION_ONLY**.

This is a narrow validation-only pass. Production is accepted and immutable. Do not broaden the work.

## 0. Mandatory GitHub/local synchronization and tracker start

Before any V11 test/log edit:
1. inspect local git status and preserve all owner/local work;
2. fetch `origin`;
3. safely reconcile local `main` with `origin/main`; do not reset/restore owner work for cleanliness;
4. verify the GitHub versions of the V10 audit and V11 criteria are present locally;
5. verify the current tracker is still `M20-C001-V10 / AWAITING_AUDIT / CHATGPT`, progress `290/719` main+ui and `290/943` overall, `lastCompletedTaskId M19-C001-V06`, all SB-M20-001..014 open;
6. change only the root `TASKS.md` Project Status lifecycle fields to:
   - Current Sprint: `M20-C001 V11 — final direct-assertion reconciliation`
   - Current Task: `M20-C001-V11`
   - Current Task Status: `IN_PROGRESS`
   - Required Actor: `CLAUDE`
   - Next Task/Action: execute the frozen V11 validation-only direct-assertion reconciliation, then hand back `AWAITING_AUDIT / CHATGPT`;
7. do not change progress, lastCompletedTaskId, or any SB-M20 checkbox;
8. commit and push this tracker-only transition before editing V11 tests;
9. verify the tracker-only commit exists on GitHub remote;
10. record the exact commit SHA in `CLAUDE_LOG_V11.md`.

No `.hiveai` live tracker may be recreated.

## 1. Production lock

Accepted production basis:
`e189ee8bd2b9be68b876cfdb18377622ed3ce832`

Required exact production blobs before and after:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `eee10149e4f116af6706beec832042352bf3a6dd`

Rules:
- NO committed `scripts/**` change.
- NO production sensitivity mutation is required in V11.
- Do not modify docs.
- Do not start M21.
- Do not add scoring/win/lose/session/economy behavior.
- Do not add slot queue/cooldown/consumption behavior.

If a V11 assertion exposes a production defect, STOP. Do not fix production. Set handoff BLOCKED and describe the defect in the Claude log.

## 2. Scope: close only the five V10 direct-evidence defects

Do not rewrite the whole M20 suite. Preserve all prior M19/M20 tests and the accepted V10 evidence. Add only the smallest V11 assertions/helpers needed.

Add one narrow entry such as `_run_m20_v11_direct_assertion_reconciliation_tests()` or amend the V10 group with clearly V11-labelled assertions. Prefer a new V11 group so audit traceability is explicit.

### G-V10-01 — arrival-drain inner activation must prove zero exact side effects

The V10 test captured `res_before2` but never used it, and its active-count assertion used `<=`, which can false-pass after outer A finalizes.

Use a fresh healthy two-target arrangement. While A is actively in the arrival drain hook:

Immediately before the inner `activate_slot()` capture:
- `peek_next_owner_id()`;
- dispatcher active count;
- exact reservation target->owner map;
- reservation count.

Call the inner `activate_slot()`.

Immediately after that inner call returns, still inside the hook, directly assert/store evidence that:
- result is exactly `REENTRANT`;
- next-owner id is EXACTLY unchanged;
- active count is EXACTLY unchanged;
- reservation target->owner map is EXACTLY unchanged;
- reservation count is EXACTLY unchanged.

Do not use `<=`, aggregate post-transaction state, or an unused baseline variable as a substitute.

Then separately prove:
- outer A transaction completes normally and clears exactly once;
- after drain completes, a later ordinary activation remains usable and clears B.

### G-V10-02 — missing reservation must preserve dispatcher assignment

In a fresh real assignment:
- remove only that assignment's reservation pair;
- invoke authenticated-arrival preflight;
- assert `PREFLIGHT_REJECTED`;
- assert cleared_count remains zero;
- assert target remains ACTIVE;
- DIRECTLY assert `dispatcher.has_owner(owner)` is still true after rejection;
- preserve unrelated sentinel truth if arranged.

### G-V10-03 — candidate rebind(null) exact preservation

In a fresh real assignment, rebind candidate index to null before arrival preflight.

Directly assert after rejection:
- `PREFLIGHT_REJECTED`;
- exact `target -> owner` reservation remains;
- exact `owner -> target` reservation remains;
- dispatcher assignment remains pending;
- cleared_count remains zero;
- target BoardState remains expected ACTIVE.

### G-V10-04 — externally-CLEARED exact preservation

In a fresh real assignment, externally set target to CLEARED before arrival preflight.

Directly assert:
- `PREFLIGHT_REJECTED`;
- M20 cleared_count remains zero;
- exact `target -> owner` reservation remains;
- exact `owner -> target` reservation remains;
- dispatcher assignment remains pending.

Do not describe the externally-written CLEARED cell as an M20 clear.

### G-V10-05 — reservation rollback must prove reverse identity for every owner

Use current pair + at least one unrelated pair.

Before the fault snapshot DETACHED:
- full target->owner map/count;
- `get_target_for_owner(current_owner)`;
- `get_target_for_owner(unrelated_owner)` for every unrelated arranged owner;
- BoardState;
- dispatcher active/current-owner identity.

Run reservation mutate-before-false.

If result is `RESERVATION_ROLLBACK`, directly compare every snapshot including the unrelated owner->target reverse mapping.

Do NOT substitute a redundant `get_owner(unrelated_target)` check for `get_target_for_owner(unrelated_owner)`.

## 3. No reinvention of already accepted evidence

Keep enabled and do not unnecessarily rewrite:
- V10 G01 actual second post-reset gameplay operation;
- V10 nested activation-preflight exact owner token test;
- renderer-foreign / renderer-queued matrix rows;
- V10 lifecycle smoke including truly-freed renderer and failed-preflight cleanup;
- five-slot pair removal and scale-row direct target CLEARED checks;
- candidate rollback detached prestate comparison;
- all V01-V10 M20 regressions and M19 regressions.

## 4. V11 log requirements

Create:
`coordination/sessions/M20-C001/CLAUDE_LOG_V11.md`

The log must contain a compact evidence table G-V10-01..06. For every row include:
- exact test/helper name;
- exact executable assertion(s);
- expected failure condition;
- actual runtime result;
- evidence source: root-suite or frame smoke.

G-V10-06 is traceability: the table must not claim anything the source does not directly assert.

Record:
- V11 tracker-start commit SHA;
- exact final validation commit SHA if known without self-referential fabrication;
- Godot version;
- exact full-suite total/pass/fail;
- each lifecycle smoke result individually;
- exact changed files;
- final production blobs;
- `git diff e189ee8 -- scripts/` result;
- `git diff --check` result;
- blockers/unverified claims if any.

## 5. Final validation

After all V11 test edits:
1. verify both production blobs exactly;
2. run `godot --version`;
3. run full root suite;
4. run separately:
   - `tests/m20_queue_free_smoke.gd`
   - `tests/m20_v04_lifecycle_smoke.gd`
   - `tests/m20_v05_lifecycle_smoke.gd`
   - `tests/m20_v07_lifecycle_smoke.gd`
   - `tests/m20_v08_lifecycle_smoke.gd`
   - `tests/m20_v09_lifecycle_smoke.gd`
   - `tests/m20_v10_lifecycle_smoke.gd`
   - any V11 smoke only if you actually create one;
5. inspect final outputs for literal `SCRIPT ERROR` and `Parse Error`;
6. run `git diff --check`;
7. record exact changed files;
8. verify `git diff e189ee8 -- scripts/` is empty;
9. commit/push V11 validation + log + tracker handoff;
10. verify remote `main` contains the final commit and log.

Expected V11 changed files should be only:
- `TASKS.md` lifecycle fields;
- `tests/run_tests.gd`;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V11.md`.

Do not modify V10 historical evidence files. Do not modify production. Do not modify docs.

## 6. Handoff

On clean validation:
- leave SB-M20-001..014 open;
- leave progress `290/719` main+ui and `290/943` overall;
- leave `lastCompletedTaskId M19-C001-V06`;
- set root tracker to:
  - `Current Sprint: M20-C001 V11 — final direct-assertion reconciliation`
  - `Current Task: M20-C001-V11`
  - `Current Task Status: AWAITING_AUDIT`
  - `Required Actor: CHATGPT`
  - Next Task/Action: independent V11 audit against `CLAUDE_LOG_V11.md` and `CHATGPT_AUDIT_CRITERIA_V11.md`;
- commit/push/verify;
- do not start M21.

## 7. Mandatory user-facing final response: GitHub log link

After the final push, verify this exact GitHub URL resolves:

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M20-C001/CLAUDE_LOG_V11.md`

Your final response to the user must be only these two lines:

`AWAITING_AUDIT`
`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M20-C001/CLAUDE_LOG_V11.md`

Do not return a local filesystem path as the log. Do not paste the whole log into chat. The GitHub blob link is the handoff artifact.