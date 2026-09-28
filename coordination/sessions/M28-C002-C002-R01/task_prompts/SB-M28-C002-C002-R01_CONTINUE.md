# SB-M28-C002-C002-R01-CONTINUE — COMPLETE INTERRUPTED VISUAL REMEDIATION

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Critical recovery rule

The previous R01 implementation is already present **locally but uncommitted**.

Do NOT discard, reset, checkout-over, or rebuild that work.

Start by:
1. reading `CLAUDE.md`;
2. reading root `TASKS.md` READ ONLY;
3. reading the original R01 prompt:
   `coordination/sessions/M28-C002-C002-R01/task_prompts/SB-M28-C002-C002-R01_VISUAL_REMEDIATION.md`;
4. inspecting `git status` and local diff;
5. confirming the interrupted local changes are still present.

Preserve the owner's pre-existing `project.godot` change and unrelated untracked owner files.

## Already implemented and locally verified before interruption

Do not redo these unless inspection shows they are missing/corrupt:

- live mini Scrubby `BODY_SPAN_CELLS`: **1.8 -> 2.4**;
- retire echo span: **1.6 -> 2.1**;
- speech bubble live headline:
  `LET'S CLEAN THIS MESS!`;
- speech bubble live instruction:
  `Tap a batch below to send the Scrubbots.`;
- obsolete baked tutorial sentence remains masked;
- bubble shrink-to-fit corrected using actual wrapped label minimum height;
- front supply invisible touch areas expand toward >=88 px without overlap;
- preview rows remain non-interactive;
- visible AD placeholder hidden while reserved layout space remains;
- production catalog rejects non-square production levels while generic rectangular engine remains untouched;
- focused test:
  `tests/m28_c002_c002_r01_visual.gd` reported 10/10 PASS;
- C002 static shell, C001 Gameplay V02, M28 layout smoke and both M32 Scrubbot suites reported PASS;
- seven sensitivity mutations reported caught, with files restored byte-for-byte.

Verify these facts in the actual local tree before continuing.

## Remaining work only

### 1. Render final owner evidence

Generate fresh R01 evidence under:

`coordination/sessions/M28-C002-C002-R01/evidence/`

Required:
1. active cleaning 1x with 2.4-cell mini Scrubbots;
2. active cleaning 2x;
3. dense multi-agent state;
4. 1080x1920 short phone;
5. speech bubble at 1080x2160;
6. speech bubble at 1080x1920;
7. tablet portrait;
8. +1 Slot six-slot state.

Inspect every screenshot visually before proceeding.

Specifically verify:
- mini Scrubbots are visibly larger than C002 baseline and still readable;
- dense overlap remains acceptable;
- bubble headline/instruction are fully inside the bubble;
- 15 px short-phone instruction text remains legible;
- no obsolete baked sentence leaks through;
- no visible AD label/band;
- six-shell/master alignment remains unchanged.

If a screenshot exposes a real defect, fix it and rerun focused tests.

### 2. Complete final regressions

On the final post-evidence code run at minimum:

- `tests/m28_c002_c002_r01_visual.gd`
- `tests/m28_c002_c002_static_shell.gd`
- `tests/m28_c002_c001_gameplay_v02.gd`
- `tests/m28_gameplay_layout_smoke.gd`
- relevant M29 movement/origin suites
- both M32 Scrubbot visual suites
- relevant M39/M40 economy/save
- M52 First 10 owner supply plans
- M55 long-run / chaos
- root `tests/run_tests.gd`
- `git diff --check`

Document the historical M21 baseline failures if unchanged.

No new unexplained FAIL / SCRIPT ERROR / engine-error class.

### 3. Verify immutable master assets

Re-check all six master PNG SHA-256 values against:

`coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`

They must remain byte-identical.

### 4. Write required evidence docs

Create:

- `coordination/sessions/M28-C002-C002-R01/VISUAL_REMEDIATION_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C002-R01/OWNER_VISUAL_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C002-R01/CLAUDE_LOG_V01.md`

Owner review must link each screenshot and explicitly call out:
- enlarged 2.4-cell mini Scrubbots;
- 2.1-cell retire echo;
- bubble text readability, especially 1080x1920;
- expanded invisible touch targets;
- hidden AD placeholder;
- square-board production gate;
- six master hashes unchanged.

Do not claim owner acceptance.

### 5. Commit and push

Stage only authorized R01 implementation/test/evidence/doc files.

Exclude:
- pre-existing owner `project.godot`;
- unrelated owner media;
- import/cache junk;
- temporary backups/diagnostics.

Commit and push safely to `origin/main`.

Do NOT edit `TASKS.md`.

## Safety-check outage handling

If Claude Code's command/file safety service fails transiently again:
- do not repeatedly burn attempts;
- preserve the local tree;
- retry conservatively;
- stop before the hard session limit if the service remains unavailable.

## Finish marker

Only after evidence, final regression, docs, commit and push are complete:

`AWAITING_CHATGPT_AUDIT / M28-C002-C002-R01 VISUAL REMEDIATION COMPLETE`
