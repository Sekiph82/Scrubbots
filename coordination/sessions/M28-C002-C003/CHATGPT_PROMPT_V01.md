# M28-C002-C003 — GAMEPLAY V02 POPUP-INCLUSIVE FINAL EVIDENCE / PLAYTEST

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Close the remaining Gameplay Composition V02 convergence delta by validating the **actual shipping Gameplay V02 together with the now-approved M43-C002 modal/Pause foundation and M43-C003 Life/Booster/2x acquisition surfaces**.

This is primarily a **validation / evidence / closure cycle**, not a redesign cycle.

Target open rows:

- SB-M28-C002-012 — zero-charge booster routes to canonical Booster Acquire;
- SB-M28-C002-013 — unentitled manual 2x routes to canonical 2x Acquire;
- SB-M28-C002-019 — fresh owner-review evidence including popup-open states;
- SB-M28-C002-020 — prepare complete final evidence for independent ChatGPT audit + owner visual/playtest acceptance.

Do **not** edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
4. `coordination/sessions/M28-C002-C002-R01/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`
5. `coordination/sessions/M28-C002-C002-R01/CHATGPT_AUDIT_V01.md`
6. `coordination/sessions/M43-C002-C001/CHATGPT_AUDIT_V01.md`
7. `coordination/sessions/M43-C002-C001/OWNER_POPUP_PAUSE_GATE_V01.md`
8. `coordination/sessions/M43-C003-C001/CHATGPT_AUDIT_V01.md`
9. `coordination/sessions/M43-C003-C001/OWNER_ACQUISITION_GATE_V01.md`
10. current `tests/m28_c002_c001_gameplay_v02.gd`
11. current `tests/m28_c002_c002_r01_visual.gd`
12. current `tests/m28_c002_c002_static_shell.gd`
13. `tests/tools/gameplay_v02_snapshot.gd`

## Owner-locked visual state

Do not reinterpret or redesign the already accepted Gameplay V02 static shell.

Preserve:

- approved background / Scrubby lower hierarchy;
- five permanent slot-to-bottom-rail connectors;
- five normal slots + temporary authoritative sixth slot;
- selected Batch Supply presentation and 3/4/5-column support;
- only supply-front interaction;
- Pause + 2x side-by-side top-right;
- no gameplay Settings button;
- no gameplay Heart HUD;
- no current gameplay ad banner;
- approved 2.4-cell mini Scrubbot / slot treatment;
- owner-approved bubble copy / static shell visuals.

Preserve M43 owner decisions:

- Pause/modal family approved as-is;
- Life uses current family frame / royal X;
- Selector/Tornado target picking remains in Booster Acquire popup;
- rewarded charge may be saved if immediate booster use is illegal;
- 2x 2×2 acquisition layout and extension copy approved;
- temporary Shop handoff copy approved;
- last-Heart Pause → Restart uses the Life gate.

## A. Validation-first rule

Start from current `origin/main`.

Do not change shipping code unless a real blocker is found against the exact criteria below.

If current implementation already satisfies a requirement:
- prove it;
- add/strengthen tests only where necessary;
- capture fresh evidence;
- do not churn accepted visuals.

If a real defect is found:
- make the smallest production fix;
- document why;
- rerun all affected regression suites.

## B. SB-M28-C002-012 — Booster Acquire routing

Prove from the real Gameplay V02 booster controls that:

1. exactly the four canonical boosters are shown;
2. with zero owned charge, tapping a booster does **not** silently fail and does **not** immediately debit SB;
3. instead, the canonical M43-C003 Booster Acquire popup opens on the shared ModalStack;
4. the popup corresponds to the tapped booster and displays live charge/price/legality;
5. Selector/Tornado use the owner-approved popup target picker;
6. owned charge behavior remains charge-first;
7. popup-open background gameplay input remains blocked;
8. closing/cancelling acquisition without commit changes no economy/gameplay truth;
9. successful SB/rewarded use still goes through the canonical solver-safe transaction authority.

At minimum validate +1 Slot and one target-requiring booster through the real visible control.

## C. SB-M28-C002-013 — 2x Acquire routing

Prove from the real Gameplay V02 2x control that:

1. unentitled 1x → 2x tap opens the canonical M43-C003 2x Acquire popup;
2. no silent free manual 2x is granted;
3. no SB is debited merely by opening the popup;
4. popup shows exactly the canonical products:
   - current level 200 SB
   - 15m 300 SB
   - 30m 500 SB
   - 60m 750 SB
5. successful purchase immediately allows/sets manual 2x;
6. active entitlement permits free 1x/2x switching with no recharge;
7. timed countdown is live and visible;
8. free M23 supply-exhausted auto-2x remains acquisition-independent;
9. popup-open gameplay input remains isolated.

## D. Final popup-inclusive evidence pack

Create a **fresh** final evidence directory:

`coordination/sessions/M28-C002-C003/evidence/`

At minimum include these 1080×2160 canonical screenshots from real Gameplay V02:

1. `final_fresh_level_1080x2160.png`
2. `final_active_cleaning_1080x2160.png`
3. `final_five_slots_occupied_1080x2160.png`
4. `final_sixth_slot_active_1080x2160.png`
5. `final_booster_acquire_open_1080x2160.png`
6. `final_selector_or_tornado_picker_open_1080x2160.png`
7. `final_pause_open_1080x2160.png`
8. `final_2x_acquire_open_1080x2160.png`
9. `final_timed_2x_active_1080x2160.png`

Also capture:

10. short phone 1080×1920 with a popup open;
11. tall phone 1290×2796;
12. tablet portrait 1536×2048 with a popup open;
13. temporary sixth-slot + popup/input-isolation state if it differs materially.

Use real app/runtime state. Do not fake a popup by composing images externally.

## E. Motion / playtest evidence

SB-M28-C002-019 calls for screenshots/video.

Produce the strongest reproducible motion evidence the current repository/tooling can safely create.

Preferred:
- a short gameplay capture showing fresh gameplay → supply tap / active cleaning → Pause open/close → zero-charge Booster Acquire open/close → 2x Acquire open → purchase or test entitlement → visible timed/current 2x.

If direct video capture is available locally without adding a new dependency, save it under the session evidence directory in a practical review format.

If direct video capture is not deterministic/available in the development environment:
- do **not** add a paid or heavy dependency;
- create a timestamped ordered frame sequence/contact sheet representing the same flow;
- state clearly in the review pack that final interactive motion remains an OWNER PLAYTEST gate.

Never claim video evidence exists if it does not.

## F. Final owner playtest checklist

Create:

`coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`

Keep it compact and actionable.

Owner should be able to answer PASS/FAIL for:

1. fresh Gameplay V02 composition;
2. active cleaning readability;
3. five occupied slots readability;
4. sixth-slot readability;
5. zero-charge booster tap opens correct Acquire popup;
6. Selector/Tornado target picker feels clear;
7. popup blocks accidental gameplay taps;
8. Pause opens/closes correctly and visual hierarchy is accepted;
9. unentitled 2x opens 2x Acquire;
10. 2x purchase/timed countdown presentation is clear;
11. popup stacking / Back behavior feels correct;
12. no visual jump/corruption when popup closes;
13. short-phone readability;
14. tablet readability;
15. overall Gameplay V02 shipping visual acceptance.

Do not self-mark owner acceptance.

## G. Automated proof

Add or extend focused tests only as necessary to prove the integration.

Required assertions include:

1. zero-charge +1 Slot visible tap → `booster_plus_one_slot` popup;
2. zero-charge Selector or Tornado visible tap → corresponding popup;
3. popup open causes no SB debit;
4. popup close/cancel causes no mutation;
5. background supply tap blocked while Booster Acquire is open;
6. background booster tap blocked while modal is open;
7. temporary sixth slot remains visually/state intact with popup open;
8. unentitled visible 2x tap → `speed_acquire` popup;
9. opening 2x popup causes no debit;
10. successful canonical 2x purchase debits exactly once;
11. entitled repeated 1x/2x switching costs 0 additional SB;
12. timed countdown updates from authoritative service;
13. Pause still opens from visible Pause control;
14. Pause / acquisition stack obeys top-modal input rules;
15. no click-through after close;
16. mouse/touch rapid tap protections remain valid;
17. five-slot / supply / BoardRenderer geometry remains unchanged by the integration;
18. no node/timer/signal accumulation after repeated popup cycles.

## H. Responsive matrix

Revalidate popup-inclusive states at minimum:

- 1080×2160
- 1170×2532
- 1290×2796
- 1080×2400
- 1440×3200
- 1080×1920 short portrait
- 1536×2048 tablet portrait

At least:
- base gameplay,
- Booster Acquire open,
- Pause open,
- 2x Acquire open,
- sixth-slot state

must fit safely with no clipping/critical overlap and compliant touch targets.

## I. Regression gate

Run:

- M28 C002 C001;
- M28 C002 C002 static shell;
- M28 C002 C002 R01;
- M28 gameplay layout smoke;
- M29 input;
- M30 retry/completion;
- M39 economy/boosters/2x;
- M40 save;
- M43-C002 modal/Pause;
- M43-C003 acquisition;
- M52 supply/2x;
- M55 Heart/timed-2x;
- root suite;
- `git diff --check`.

Historical M21 corridor findings may remain only if identical to the accepted baseline and unrelated.

## J. Required outputs

Create:

- `coordination/sessions/M28-C002-C003/GAMEPLAY_V02_FINAL_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C003/CLAUDE_LOG_V01.md`
- fresh evidence under `coordination/sessions/M28-C002-C003/evidence/`

The matrix must map:
- SB-M28-C002-012
- SB-M28-C002-013
- SB-M28-C002-019
- SB-M28-C002-020 prerequisites

to concrete implementation/test/evidence.

## Scope locks

Do not:

- edit root `TASKS.md`;
- redesign the accepted Gameplay V02 static shell;
- change owner-approved M43 popup visuals/UX choices;
- alter booster prices/rules;
- alter 2x prices/durations;
- change Heart rules;
- add an ad SDK;
- implement M43-C004 or later meta screens;
- generate new standalone art unless an actual missing blocker is proven and owner approval is required;
- modify routing/solver truth merely to make evidence easier.

## Finish

Commit and push all authorized work.

Return:

1. final commit SHA;
2. whether shipping production code changed, and why;
3. focused + regression test summary;
4. direct GitHub link to `CLAUDE_LOG_V01.md`;
5. direct GitHub link to `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`;
6. evidence directory link;
7. explicit note whether direct video was captured or owner interactive motion playtest remains required.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M28-C002-C003 GAMEPLAY V02 FINAL POPUP-INCLUSIVE GATE`
