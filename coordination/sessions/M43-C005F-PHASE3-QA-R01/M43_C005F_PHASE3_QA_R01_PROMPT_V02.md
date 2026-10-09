# M43-C005F-PHASE3-QA-R01 — Pack Route Sampling Deflake — CLAUDE REMEDIATION PROMPT V02

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-09

## Owner recovery status

The owner has confirmed they did **not** make manual local `project.godot` changes after the 2026-10-08 reconciliation and accepts the restored reconciled file as current. Owner record:
`coordination/sessions/M43-C005F-PHASE3/OWNER_DESKTOP_RECOVERY_ACCEPTANCE_V01.md`

Therefore **OWNER RECOVERY IS CLOSED**. Do not perform any recovery/reconstruction of the persistent Desktop `project.godot`. This task has exactly one remaining closure objective: deterministic pack-route test deflake.

## Objective

Fix ONLY the nondeterministic test observation in:

- `tests/m43_c005_c006_standard_pack_presentation.gd` case `v07`
- `tests/m43_c005_c007_premium_pack_presentation.gd` case `p12`

Current tests require a headless process frame to happen while each routing card has `0 < route < 1`. Under scheduler/load stalls, a process frame may skip the observable mid-route window even though production routing is correct.

This is a TEST-HYGIENE remediation.

**Do not change owner-approved Standard/Premium pack production behavior, art, timing, sequencing or routing.**

Read first:

- `coordination/sessions/M43-C005F-PHASE3/CHATGPT_INDEPENDENT_AUDIT_V01.md`
- `coordination/sessions/M43-C005F-PHASE3/M43_C005F_PHASE3_AUDIT_CRITERIA_V01.md`
- `tests/m43_c005_c006_standard_pack_presentation.gd`
- `tests/m43_c005_c007_premium_pack_presentation.gd`
- `scripts/ui/ceremony/standard_pack_ceremony.gd`
- `scripts/ui/ceremony/premium_pack_ceremony.gd`
- `scripts/ui/components/reveal_sequencer.gd`

Root `TASKS.md` is READ-ONLY for Claude.

---

# GATE 0 — OWNER DESKTOP SAFETY

The previous Phase 3 run accidentally executed a checkout against owner Desktop. That must never recur.

Before any implementation:

1. Use explicit absolute repo paths on EVERY git command.
2. Record:
   - persistent Desktop HEAD
   - origin/main
   - ahead/behind
   - tracked dirty files
   - untracked count
   - SHA-256 or exact file hash/stamp of persistent Desktop `project.godot`
3. Run:
   `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin`
4. Non-destructively fast-forward/reconcile Desktop to current origin/main while preserving every owner-local file.
5. If persistent Desktop cannot safely reach origin/main, STOP:
   `BLOCKED_OWNER_DESKTOP_SYNC`

### Hard prohibition

Never run any of these against the persistent Desktop checkout:

- `git checkout -- <file>`
- `git restore <file>`
- `git reset --hard`
- `git clean`
- destructive stash/pop
- force checkout/rebase/push

No shell command may rely on `cd <temp> && ... ; destructive-command` semantics.

---

# TEMP WORKTREE RULE

After Gate 0, create ONE disposable TEMP worktree from exact current `origin/main`.

Use absolute commands only, e.g.:

`git -C "<repo>" worktree add "<absolute-temp-path>" origin/main`

Then every TEMP command must be:

- `git -C "<absolute-temp-path>" ...`
- `godot --headless --path "<absolute-temp-path>" ...`

If worktree creation fails:
- STOP.
- Do not continue in Desktop.
- Do not suppress the error.
- Do not fall back to the current working directory.

Before any command that can modify/restore a file, print/verify the absolute target path.

---

# PRODUCTION FREEZE

These paths must remain BYTE-IDENTICAL to the starting origin/main:

- `scripts/ui/ceremony/standard_pack_ceremony.gd`
- `scripts/ui/ceremony/premium_pack_ceremony.gd`
- `scripts/ui/components/reveal_sequencer.gd`
- all pack art
- all pack manifests
- all pack timing constants
- all pack model/economy/receipt code

No production source edit is authorized.

Allowed implementation files:

- `tests/m43_c005_c006_standard_pack_presentation.gd`
- `tests/m43_c005_c007_premium_pack_presentation.gd`

A small TEST-ONLY helper under `tests/` is allowed only if both suites genuinely need the same deterministic observation utility.

No other source changes.

---

# DEFECT

Current Standard v07 and Premium p12 do this:

1. start real shipping routing;
2. once per `process_frame`, read `cv.route`;
3. require seeing at least one frame satisfying `0 < route < 1` for every card.

That samples wall/scheduler frames rather than the deterministic presentation geometry.

Under load, a frame can jump from route 0 to route 1 between observations.

The test then fails even though:
- route log is correct;
- arrival order is correct;
- production route geometry/timing is unchanged.

---

# REQUIRED TEST DESIGN

Make the observation deterministic WITHOUT changing production.

Preferred solution:

Separate two truths that the old frame-sampled check mixed together:

### A. Deterministic route geometry

Before starting the real Tap-2 route, for every shipping CardView:

- record slot/start and canonical destination;
- set/probe a strictly intermediate route value in TEST CODE only, e.g. `route = 0.5`;
- assert the card:
  - is strictly between its slot/start and destination;
  - is closer to its own destination than at start;
  - remains visible at that mid-route point;
  - moves toward the destination selected by NEW/DUPLICATE truth;
- restore `route = 0.0` before real routing starts.

This uses the production CardView route setter/geometry deterministically but changes no shipping source.

Then:

### B. Real routing lifecycle

Perform the real Tap 2 and assert the existing production facts:

- correct route log;
- one route per card;
- NEW -> Collection;
- DUPLICATE -> Cards Exchange;
- serialized one-card-in-flight semantics;
- exact arrival order;
- completion once;
- final destination/close behavior.

If you find a cleaner deterministic TEST-ONLY technique using existing sequencer state, use it, but it must not depend on catching a scheduler frame inside a finite timing window.

### Forbidden "fixes"

Do NOT:
- lengthen `ROUTE_S`;
- change Tween duration/easing;
- add sleeps/delays to production;
- add production debug hooks;
- add test-only branches in shipping ceremony code;
- loosen/remove destination or arrival assertions;
- replace the route test with only end-state assertions;
- retry the flaky assertion until it happens to pass.

The new test must still prove visible intermediate travel semantics, just deterministically.

---

# SENSITIVITY

Add a small deterministic sensitivity assertion so the test would fail if:

- intermediate route geometry stayed at the slot;
- intermediate route geometry jumped directly to destination;
- a card targeted the wrong destination.

Do not merely set `mid_seen = true` by construction.

---

# REQUIRED VALIDATION

First import only inside TEMP:

`godot --headless --path "<TEMP>" --import`

If import modifies `project.godot`, restore it ONLY inside TEMP using an absolute `git -C "<TEMP>" ...` command.

## 10x stability gate

Run Standard suite TEN consecutive times:

`godot --headless --path "<TEMP>" -s res://tests/m43_c005_c006_standard_pack_presentation.gd`

Required: **10/10 PASS**.

Run Premium suite TEN consecutive times:

`godot --headless --path "<TEMP>" -s res://tests/m43_c005_c007_premium_pack_presentation.gd`

Required: **10/10 PASS**.

No retry substitution:
- if run #4 fails, the result is not 10/10 even if runs #11-#20 later pass.
- fix the test and restart the 10-run sequence from 1.

Record every run exit code.

## Phase 3 closure regression

After 10/10 + 10/10, rerun the full required Phase 3 regression battery from:
`coordination/sessions/M43-C005F-PHASE3/M43_C005F_PHASE3_CLAUDE_LOG_V01.md`

At minimum it must include all suites named by the Phase 3 audit criteria, plus:
- Phase 3 focused 15/15
- earned-pack R01/R02 22/22
- Phase 1 / Phase 2 feel
- Standard pack
- Premium pack
- root `tests/run_tests.gd`
- headless boot/import
- `git diff --check`

For Phase 3 strict closure, the final required battery must have no unexplained failing suite.

---

# HASH / SCOPE PROOF

Record SHA-256 before and after for:

- StandardPackCeremony source
- PremiumPackCeremony source
- RevealSequencer source

They must be identical.

Also prove the git diff contains no:
- `scripts/ui/ceremony/**`
- `scripts/ui/components/reveal_sequencer.gd`
- assets
- economy/save
- Remote Content/R2
- TASKS.md

Only authorized test files + QA log may change.

---

# PUBLICATION

Write log:

`coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_CLAUDE_LOG_V01.md`

Push normally to `main`.

After push:

1. fetch origin using explicit `git -C` on persistent Desktop;
2. fast-forward persistent Desktop to final origin/main non-destructively;
3. do not touch/restore owner `project.godot`;
4. verify its pre-task hash/stamp is unchanged;
5. report Desktop HEAD == origin/main and ahead/behind 0/0.

If the persistent Desktop project.godot changes during this task, STOP and report:
`OWNER_DESKTOP_MUTATION_DETECTED`.

End:

`AWAITING_GPT_M43_C005F_PHASE3_QA_R01_REAUDIT`
