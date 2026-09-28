# SB-M43-C001B-R01 — COMPLETE INTERRUPTED WON RESULTS VISUAL BINDING

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Why this remediation exists

The previous M43-C001B attempt was interrupted by repeated Claude Code safety-check service failures before any commit/push.

Nothing from that local implementation exists on GitHub yet.

The owner wants this task **finished before moving to Gameplay Screen V02**.

## Critical instruction: recover local work first

Before changing anything:

1. inspect the current local working tree;
2. preserve the existing owner/local `project.godot` modification and unrelated untracked owner files;
3. identify the uncommitted M43-C001B changes from the interrupted attempt;
4. **continue those changes in place** if they are present and coherent;
5. do not discard/rebuild them merely because GitHub main still points to the pre-C001B state;
6. if some interrupted edits are missing locally, reconstruct only the missing parts from the requirements below.

Do NOT edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_RESULTS_VISUAL_REPLAY_V01.md`
4. original prompt:
   `coordination/sessions/M43-C001B/task_prompts/SB-M43-C001B_WON_RESULTS_VISUAL_BINDING.md`
5. audit criteria:
   `coordination/sessions/M43-C001B/audit_criteria/SB-M43-C001B_WON_RESULTS_VISUAL_BINDING.md`
6. C001A foundation/audit/readiness docs
7. `tests/m55_long_session.gd` owner-plan driving patterns
8. owner First 10 solution/click-plan evidence

## Owner locks remain unchanged

- NO Replay in V1 Results.
- WON Results: Scrubby above/overlapping the popup frame.
- Small Victory emblem in the header.
- Green/yellow Life/Help-family Continue CTA.
- LOST gets no Victory art and remains technical fallback until M43-C004.
- No reward/economy truth change.
- No asset overwrite/regeneration.

## Already-completed local work reported by the interrupted run

Treat this as recovery guidance, not automatic PASS. Verify it in the actual local tree.

Reported locally implemented:

- WON Results native Life/Help-family style:
  - warm cream panel;
  - thick royal-blue border;
  - Scrubby victory pose overlapping top;
  - small Victory emblem in header;
  - green Continue CTA;
  - Home secondary.
- Reward rows bound only to committed receipt, in locked order.
- Short sequential reveal.
- Reduced Effects path shows rows immediately.
- LOST/ERROR technical fallback has no Victory art.
- no Replay action/button/route;
- app root passes Reduced Effects into Results model;
- C001A helper adapted to the row layout.
- focused `tests/m43_c001b_won_results_visual.gd`: reported 49 checks / 11 cases PASS.
- C001A, M42 navigation and M42 Home reportedly still PASS.

Verify every item rather than trusting the summary.

## The known blocker to fix first

The evidence snapshot harness used a naive "first available column" driver.

That deadlocked / lost on some levels, so four requested visual screenshots were invalid:
- the two WON Level 3 evidence views;
- Level 10 no-next-content;
- Reduced Effects WON evidence.

### Required remediation

Replace the naive driver in `tests/tools/results_snapshot.gd` (or the actual current harness path) with the existing **owner-approved level click-plan driver** used by the stable First 10 validation / `m55_long_session.gd`.

Do NOT:
- invent a solver;
- recalculate difficulty;
- generate a new batch/color solution.

Use the existing owner-provided solution/click sequences exactly as current validation truth.

Then regenerate every required screenshot from scratch.

Delete/replace the bad local evidence images so no FAILED screenshot remains in the final evidence set.

## Required final visual evidence

Capture and personally inspect all of these before handoff:

1. 1080×1920 WON Results with a valid WON and representative rewards.
2. 1080×2160 WON Results with a valid WON.
3. Level 10 WON -> Level 11 CONTENT_MISSING / no-next-content state.
4. Reduced Effects WON / static immediate-reward state.
5. LOST technical fallback with **no Victory art**.
6. One additional responsive portrait evidence view if needed to prove no clipping.

Every WON screenshot must come from a genuinely WON production-path state.

Evidence filenames/captions must make the state unambiguous.

## Visual self-review before commit

Inspect the rendered WON screenshots, not just geometry values.

Check:
- Scrubby visibly overlaps the top of the frame;
- Victory emblem is small and readable, not dominant;
- frame reads as Life/Help family;
- reward hierarchy is readable;
- reward icons do not overwhelm live numbers;
- green/yellow Continue is primary;
- Home is secondary;
- no Replay affordance;
- no clipping on narrow/tall portrait;
- no accidental Victory decoration on LOST;
- no placeholder/debug text.

If the screenshots expose a layout defect, fix it before the full regression run.

Do not create/overwrite source art to fix composition.

## Required tests

First rerun focused:
- `tests/m43_c001b_won_results_visual.gd`
- `tests/m43_c001a_results_foundation.gd`
- relevant M42 navigation/Home tests

Then full regression on the **final post-screenshot-fix code**:

- relevant M30 completion/retry
- M39 economy/rewards/Heart/2x
- M40 save
- M42 navigation/Home
- M43-C001A
- M52 R01/R02 + owner supply plans
- M54 applicable
- M55 core / long-session / Heart 900 / 2x anti-rollback
- root `tests/run_tests.gd`
- `git diff --check`

Important:
- distinguish intentional test fixture `ERROR:` from new runtime failures;
- 0 `FAIL:`;
- 0 `SCRIPT ERROR`;
- no new engine-error class.

If a full-regression failure exposes a real issue, fix it and rerun the affected suite + final regression relevant set.

## Required sensitivity

Retain or recreate meaningful sensitivity proof for the C001B-specific guards:
- no Replay;
- LOST no Victory art;
- Continue exactly once;
- reward rows tied to committed receipt;
- responsive fit / no leaking transient nodes.

Do not weaken tests to get PASS.

## Required GitHub evidence

Before commit, create:

- `coordination/sessions/M43-C001B/RESULTS_VISUAL_BINDING_MATRIX_V01.md`
- `coordination/sessions/M43-C001B/OWNER_VISUAL_REVIEW_V01.md`
- `coordination/sessions/M43-C001B/CLAUDE_LOG_V01.md`

Also commit the correct evidence screenshots under the C001B session evidence directory.

### OWNER_VISUAL_REVIEW_V01 must contain

- direct repository paths to each correct screenshot;
- exact state shown;
- viewport;
- what the owner should visually inspect;
- only genuinely unresolved visual-only issues.

Do not claim owner acceptance.

Do not mark `victory_results` MASTER_OWNER_APPROVED.

## Git discipline

Review the final diff carefully.

Exclude:
- owner/local `project.godot` change if it was pre-existing and unrelated;
- unrelated untracked owner files;
- import/cache junk;
- temporary diagnostics;
- wrong/failed evidence snapshots.

Commit only the completed C001B implementation/evidence.

Push to `origin/main`.

## Finish marker

Only after:
- correct WON evidence exists;
- focused tests pass;
- full final regression passes;
- matrix/review/log are written;
- commit and push succeed;

finish with:

`AWAITING_CHATGPT_AUDIT / M43-C001B-R01 WON RESULTS COMPLETE`

If the external safety-check service fails again, do not repeatedly burn the session. Preserve local work, report exact remaining steps, and stop before the hard limit.
