# M43-C005-C006 — STANDARD PACK OWNER REVIEW HARNESS V01

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-064**  
Purpose: **manual OWNER VISUAL REVIEW only**  
Expected Claude log: `coordination/sessions/M43-C005-C006/owner_review_harness/CLAUDE_LOG_V01.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of project lifecycle/progress state.

## 0. Goal

Create a tiny **Godot owner-review harness** that lets the owner inspect the already technically-audited V02 Standard Pack ceremony live, by opening one scene in Godot and pressing **F6**.

This harness is not a shipping feature and must not change the shipping ceremony.

The owner must be able to experience the real production sequence manually:

**Standard Pack alone -> click/tap -> real 01→09 opening -> cards emerge -> pack disappears -> three-card hold + destinations -> second click/tap -> NEW routes to Collection / DUPLICATE routes to Cards Exchange -> completion.**

The harness exists only so the owner can judge animation timing, transitions, composition and feel before giving OWNER VISUAL PASS.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, addons, dirty files and unrelated untracked work.
5. Synchronize the Desktop checkout with latest `origin/main` **non-destructively**.
6. If sync cannot be completed safely without overwriting owner work, STOP and report the exact conflicting paths.
7. Only after Desktop + GitHub are synchronized may work begin.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V02.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_CRITERIA_V02.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V02.md`
- `coordination/sessions/M43-C005-C006/CLAUDE_LOG_V02.md`
- `scripts/ui/ceremony/standard_pack_ceremony.gd`
- `scripts/ui/ceremony/standard_pack_model.gd`
- `scripts/ui/popup/modal_stack.gd`
- `tests/support/standard_pack_fixtures.gd`

## 3. HARD SCOPE LOCK

This pass is **OWNER REVIEW TOOLING ONLY**.

Do not modify:
- `scripts/ui/ceremony/standard_pack_ceremony.gd`;
- `scripts/ui/ceremony/standard_pack_model.gd`;
- `scripts/ui/components/reveal_sequencer.gd`;
- any canonical Standard Pack frame;
- any Collection card art/catalog;
- economy/reward/Collection/Card Exchange authority;
- root `TASKS.md`;
- SB-M43-065 or any Premium Pack work.

The already audited V02 shipping implementation must remain byte-identical.

If you discover that the harness cannot work without modifying production ceremony code, STOP and report the blocker. Do not silently alter shipping code.

## 4. REVIEW SCENE

Create a dedicated review-only scene under:

`tests/tools/owner_review/standard_pack_owner_review.tscn`

with a small controller under:

`tests/tools/owner_review/standard_pack_owner_review.gd`

The scene must:

1. launch directly with **F6**;
2. instantiate the real production `StandardPackCeremony` class;
3. mount it through the real `ModalStack`;
4. use the real V02 Standard Pack opening frames, timings, cards, badges and destination icons;
5. use deterministic precommitted test fixtures only;
6. default to the mixed fixture:
   - NEW
   - DUPLICATE
   - NEW
7. start in the real `IDLE` state with the pack waiting;
8. require the owner's actual mouse/touch click for Tap 1;
9. require the owner's actual second click for Tap 2;
10. never simulate or auto-send either tap.

The visual ceremony itself must be the shipping ceremony, not a copied/reimplemented animation.

## 5. REVIEW EXPERIENCE

### Default F6 flow

When the owner opens `standard_pack_owner_review.tscn` and presses F6:

- no setup menu should cover the ceremony;
- no debug overlay should cover the ceremony;
- the owner sees the actual pack-only shipping state;
- owner click 1 starts the actual opening;
- owner click 2 starts the actual routing;
- after completion, the harness may show a small review-only completion message or simply wait on a blank/review background.

### Replay controls

Provide keyboard-only review controls that do not alter the shipping ceremony:

- **R** = restart the current FULL-effects review from pack IDLE;
- **E** = toggle FULL / Reduced Effects and restart from pack IDLE;
- **1** = mixed fixture (NEW / DUPLICATE / NEW) and restart;
- **2** = all NEW fixture and restart;
- **3** = repeated-duplicate fixture and restart.

These keys are harness controls only. They must not be added to shipping ceremony code.

Do not add visible controls over the shipping ceremony while it is running.

## 6. OWNER INSTRUCTIONS

Create:

`coordination/sessions/M43-C005-C006/owner_review_harness/OWNER_REVIEW_INSTRUCTIONS_V01.md`

Keep it extremely simple and Windows/Godot-specific.

It must say exactly how the owner reviews:

1. Open Godot project:
   `C:\Users\sekip\Desktop\ScrubBots\project.godot`
2. In FileSystem, open:
   `res://tests/tools/owner_review/standard_pack_owner_review.tscn`
3. Press **F6 — Run Current Scene**.
4. Review pack-only state.
5. Click once and watch the full opening.
6. Wait for three-card hold/destination state.
7. Click again and watch NEW/DUPLICATE routing.
8. Press **R** to replay.
9. Press **E** to compare Reduced Effects.
10. Press **1 / 2 / 3** to inspect mixed / all-new / repeated-duplicate routing.

Also state clearly:
- F5 is not required.
- This scene does not mutate save/economy/Collection.
- This is the exact shipping V02 ceremony wrapped in review-only tooling.
- OWNER VISUAL PASS should be given only after judging the live motion.

## 7. HARNESS SAFETY

The harness must not:
- call `open_standard()` or `open_premium()`;
- grant cards/rewards;
- mutate Collection;
- mutate Card Exchange;
- save;
- navigate campaign progression;
- change project startup/main scene;
- modify `project.godot`;
- add production-only input paths;
- duplicate frame-by-frame opening logic.

The harness may only:
- create deterministic committed fixture models;
- instantiate/destroy the shipping ceremony;
- choose FULL/Reduced mode;
- choose among review fixtures;
- restart the review scene/ceremony.

## 8. VALIDATION

Add a focused review-harness smoke test, for example:

`tests/m43_c005_c006_owner_review_harness.gd`

It must prove at minimum:

1. the review scene loads;
2. it instantiates the real `StandardPackCeremony`;
3. production ceremony/model/sequencer hashes are unchanged from the pre-harness baseline;
4. default fixture is mixed NEW/DUPLICATE/NEW;
5. after launch the ceremony remains IDLE without input;
6. no harness auto-tap exists;
7. R restarts to IDLE;
8. E toggles Reduced Effects and restarts;
9. 1/2/3 select the documented fixtures;
10. harness contains no pack/grant/inventory/exchange/save authority;
11. harness contains no duplicate PACK_FRAMES/opening timing/state-machine implementation;
12. root `TASKS.md` and `project.godot` are untouched by Claude.

Run:
- the new owner-review-harness smoke test;
- `tests/m43_c005_c006_standard_pack_presentation.gd`;
- `tests/m43_c005_c005_reward_reveal_sequencer.gd`;
- `git diff --check`.

Do not rerun the entire root suite unless the harness touches something outside the authorized review-only paths. If it does, that is already a scope problem and should be explained.

## 9. MANUAL GODOT CHECK

Claude must manually open/run the new review scene in Godot and verify:

- F6 launches it;
- initial pack waits indefinitely;
- mouse click starts opening;
- second mouse click starts routing;
- R replay works;
- E Reduced Effects toggle works;
- fixture keys 1/2/3 work;
- no debug overlay obscures the shipping ceremony;
- no runtime/script error appears.

This is implementation evidence only, not owner approval.

## 10. LOG / HANDOFF

Create:

`coordination/sessions/M43-C005-C006/owner_review_harness/CLAUDE_LOG_V01.md`

Record:
- Desktop/GitHub sync;
- exact files added;
- proof production V02 files are unchanged;
- focused test commands/results;
- manual F6 check;
- blockers.

Commit and push only authorized review-harness files.

Do not edit root `TASKS.md`.

Finish exactly:

`AWAITING_GPT_M43_C005_C006_OWNER_REVIEW_HARNESS_AUDIT`
