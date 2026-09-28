# SB-M43-C002-C001 — REUSABLE POPUP / MODAL / PAUSE FOUNDATION

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Build the reusable production popup/modal foundation and canonical Pause flow needed to unblock Gameplay V02 and the later acquisition surfaces.

This cycle covers M43-C002 foundation rows and integrates the real Gameplay Pause button.

Do NOT edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M28-C002-C002-R01/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`
4. `coordination/sessions/M43-C001B/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`
5. `coordination/OWNER_RESULTS_VISUAL_REPLAY_V01.md`
6. current M28 GameplayScreen / ProductionGameplayHost / input controller
7. M30 Retry / completion / attempt truth
8. M39 Economy / Heart / streak / booster / 2x truth
9. existing Home modal implementations, if reusable
10. `assets/ui/VISUAL_ASSET_INDEX.md`

## Existing visual authority

Do NOT generate new popup art in this cycle.

Use existing promoted assets where appropriate:

- `assets/ui/final/common/frames/popup_small_frame.png`
- `popup_medium_frame.png`
- `popup_large_frame.png`
- `popup_confirmation_frame.png`
- `popup_reward_frame.png`
- `popup_warning_frame.png`

Use the already owner-approved Results/Life/Help visual language as the family reference:
- cream + royal-blue framing;
- green/yellow primary Life/Help-family CTA where appropriate;
- live Godot labels, prices, timers and values;
- no baked dynamic text.

Do not restyle the accepted Results screen.

## A. Reusable BasePopup

Implement one reusable `BasePopup` / equivalent production component with:

- dim/scrim background;
- responsive frame;
- header region;
- content region;
- footer/action region;
- optional close affordance;
- canonical open/close lifecycle;
- safe-area aware portrait layout;
- no duplicate open callback or double close callback;
- live Godot text/data only.

It must support the existing promoted common popup frames rather than creating duplicated bespoke scene architecture.

## B. Modal stack authority

Implement one modal-stack authority used by gameplay and reusable elsewhere.

Requirements:

- exactly one TOP modal owns input;
- modal below the top cannot receive input;
- gameplay/Home/background controls behind any modal cannot receive input;
- opening a second modal preserves deterministic stack order;
- closing top modal restores the next modal or screen correctly;
- Back/Escape closes the top modal first;
- Back/Escape must never leak through and trigger an underlying action;
- focus loss/background/resume cannot duplicate callbacks or replay an already-completed action;
- repeated rapid open/close requests must be deterministic;
- modal authority is presentation/input state, not gameplay economy truth.

Do not create competing modal managers.

## C. Reusable confirm popup

Implement a generic confirm popup for destructive/costly actions.

It must support:
- title/body;
- primary/secondary CTA;
- optional warning treatment;
- pending action context object/token;
- exactly-once confirmation;
- cancellation without side effects.

## D. Reusable reward / confirmation popup

Implement a reusable confirmation/reward surface for a completed action.

It displays committed truth only.
It must not grant rewards itself.

## E. Canonical Pause popup

Wire the existing Gameplay V02 top-right Pause button to the canonical Pause popup.

Pause popup must show:
- current level context;
- Resume;
- Restart;
- Home.

### Resume
- closes Pause;
- resumes only the state that Pause itself suspended;
- no duplicate resume.

### Restart
Use M30/M39 truth.

If gameplay has begun:
- show confirmation;
- state the real Heart/streak consequence derived from existing authority;
- confirm through the real restart/retry path.

If gameplay has NOT begun:
- do not invent a Heart/streak loss;
- use the existing no-cost semantics.

Never hardcode consequences from UI assumptions.

### Home / exit
Distinguish:
- pre-first-action no-cost exit;
- post-action loss semantics.

Use existing runtime/attempt/economy truth.
Do not fabricate a new parallel "started" flag if an accepted authority already exists.

## F. Generic foundation states for later acquisition flows

Implement reusable states/components needed by M43-C003 without implementing the actual Life/Booster/2x products yet:

### Insufficient SB
- can route to Shop;
- preserves a detached pending-acquisition context so the caller can resume or cancel cleanly;
- does not spend/grant anything by itself.

### Network-required / error
Generic state for:
- rewarded ads;
- store;
- cloud;
- live-event surfaces.

### Busy/loading
- blocks duplicate taps;
- one unresolved external transaction at a time per modal action;
- dismiss/timeout/failure must restore a deterministic usable state.

### Success/failure feedback
Generic feedback only.
The popup displays caller-committed success/failure truth; it does not perform the purchase/reward/exchange.

## G. Gameplay input isolation

While Pause or any modal is open:

- board input blocked;
- Batch Supply front taps blocked;
- booster buttons blocked;
- Pause/2x/background controls blocked unless they belong to the top modal;
- moving agents / gameplay runtime follow the canonical pause semantics;
- no hidden click-through on close;
- temporary sixth-slot presentation remains intact.

This must directly satisfy the M28-C002 dependency for popup-open input suppression.

Do not yet implement:
- BoosterAcquire product logic;
- 2x Acquire product logic;
- Life purchase/reward paths;
- real ads/store SDK;
- M43-C004 Fail/Need-a-Hand;
- Shop destination itself.

## H. Responsive / accessibility

Validate at minimum:
- 1080×2160
- 1170×2532
- 1290×2796
- 1080×1920
- 1536×2048 tablet portrait

Use safe-area-aware modal placement.

Touch targets follow project minimums.

Text must remain live and fit without clipping.

## I. Tests

Add focused automated tests proving at minimum:

1. BasePopup open/close exactly once.
2. stack order with 2+ modals.
3. only top modal receives input.
4. gameplay behind modal receives zero board/supply/booster input.
5. Back/Escape closes top modal and does not leak.
6. rapid duplicate taps/open requests do not duplicate callbacks.
7. background/focus loss/resume does not duplicate callbacks.
8. generic confirm: confirm once / cancel no side effect.
9. reward/confirmation popup displays committed data only.
10. Pause opens from real Gameplay V02 Pause control.
11. Resume returns correctly.
12. Restart pre-first-action semantics.
13. Restart post-action confirmation/consequences use M30/M39 truth.
14. Home pre-first-action semantics.
15. Home post-action confirmation/consequences use accepted truth.
16. insufficient-SB route preserves pending context.
17. busy state blocks duplicate transaction action.
18. generic network/error can recover/retry/cancel deterministically.
19. popup stack survives +1 Slot six-shell state with no visual/state corruption.
20. no node/signal/timer accumulation across repeated modal cycles.

Run relevant:
- M28 C002/R01;
- M29 input;
- M30 retry/completion;
- M39/M40;
- M42 Home;
- M43-C001 Results;
- M52;
- M55;
- root suite;
- `git diff --check`.

Historical M21 corridor failures may remain only if identical and documented.

## J. Evidence / owner review

Create fresh screenshots for:

- Pause popup on Gameplay V02;
- Restart confirmation before first action;
- Restart confirmation after gameplay has begun;
- Home/exit confirmation before first action;
- Home/exit confirmation after gameplay has begun;
- stacked-modal example;
- generic confirm;
- generic reward/confirmation;
- insufficient-SB state;
- network/error state;
- busy/loading state;
- short phone;
- tablet.

Owner review should focus on:
- popup frame family;
- Pause hierarchy;
- scrim opacity;
- CTA hierarchy;
- text density/readability.

## Outputs

Create:

- `coordination/sessions/M43-C002-C001/POPUP_MODAL_MATRIX_V01.md`
- `coordination/sessions/M43-C002-C001/OWNER_POPUP_PAUSE_REVIEW_V01.md`
- `coordination/sessions/M43-C002-C001/CLAUDE_LOG_V01.md`
- evidence under `coordination/sessions/M43-C002-C001/evidence/`

## Scope locks

Do not:
- edit root `TASKS.md`;
- regenerate promoted popup frames;
- change gameplay routing;
- change Heart/economy/booster/2x prices;
- implement M43-C003 acquisition products;
- implement M43-C004 Fail/Need-a-Hand;
- change accepted Results visuals;
- change the approved Gameplay V02 static-shell visuals.

## Finish

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M43-C002-C001 POPUP MODAL PAUSE FOUNDATION`
