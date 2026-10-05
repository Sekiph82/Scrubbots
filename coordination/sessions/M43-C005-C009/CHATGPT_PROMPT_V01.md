# M43-C005-C009 — SB-M43-067 FIRST-NEW-CARD CELEBRATION + DUPLICATE COUNT V01

Status: **READY FOR CLAUDE**  
Date: 2026-10-05  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-067**  
Expected Claude log: `coordination/sessions/M43-C005-C009/CLAUDE_LOG_V01.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. Goal

Implement the player-facing card-state treatment required by:

> **SB-M43-067 — Implement first-new-card celebration and clear duplicate-count presentation.**

Use the already-committed C008 receipt/model truth.

This is **presentation only**.

The two owner-accepted pack ceremonies remain authoritative for:
- opening art;
- timing/cadence;
- pack emergence;
- card layouts;
- destinations;
- two-tap interaction;
- routing;
- Reduced Effects;
- completion.

C009 enhances the card-state presentation inside those accepted surfaces. It must not redraw pack art or change economic truth.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading/modifying implementation:

1. Work from exactly:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty files and unrelated untracked work.
5. Synchronize Desktop with latest `origin/main` **non-destructively**.
6. If unsafe, STOP and report exact conflicting paths.
7. Only then begin.

No destructive reset/clean/force/owner-file overwrite.

## 2. READ FIRST

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- C006 final Standard technical + owner acceptance;
- C007 Premium technical + owner acceptance;
- C008 `CHATGPT_AUDIT_V02.md`;
- current Standard/Premium ceremony/model code;
- current owner-review harnesses;
- current `UiText`;
- `assets/ui/final/collection/states/card_new_glow.png`;
- canonical 135-card catalog;
- Cards Exchange protected-first-copy semantics (M39 / M43 Collection state);
- existing focused tests/evidence tooling.

Before implementation, document the current card-state presentation:
- NEW/DUPLICATE badge;
- current `copies_after` text;
- Standard 3-card hold;
- Premium 3+2 hold;
- routing destinations.

## 3. TRUTH SOURCE — HARD LOCK

Card state comes only from the committed presentation row:

- `is_new`
- `copies_after`

Do not query live Collection to decide whether a card is NEW/DUPLICATE for presentation.

Why:
- C008 already committed the truth;
- reopening/replaying a receipt must show the original committed result;
- live Collection may have changed later.

### Derived duplicate count

Define:

`extra_copies = copies_after - 1`

because the first copy is protected and only copies above 1 are duplicates/extras.

Required truth:
- NEW row => `is_new == true`, `copies_after == 1`, `extra_copies == 0`.
- DUPLICATE row => `is_new == false`, `copies_after >= 2`, `extra_copies >= 1`.

For repeated same-card rows within one pack:
- first-ever row may be NEW / first copy;
- next row may be DUPLICATE / EXTRAS x1;
- next row may be DUPLICATE / EXTRAS x2;
- preserve service/receipt order.

Do not derive duplicate count from final Collection state.

## 4. FIRST-NEW-CARD CELEBRATION — OWNER PRODUCT CONTRACT

Every committed row with `is_new == true` is a **first ownership** and gets a clearly positive, restrained one-shot visual treatment.

Use existing canonical:
`res://assets/ui/final/collection/states/card_new_glow.png`

if it is technically suitable after inspection.

Do not generate replacement art unless the existing asset is unusable and you stop for approval.

### FULL effects

For each NEW card:

1. The normal card emerges exactly as in the accepted pack ceremony.
2. As the card reaches/settles into its hold slot, show a **single NEW-card celebration**:
   - existing new-card glow behind the card;
   - one restrained native scale/pop or glow pulse;
   - clear `NEW` state remains readable;
   - `FIRST COPY` text is visible.
3. The celebration must finish/settle into a readable hold state before Tap 2 routing.
4. No looping, spinning, screen flash, camera shake, confetti storm or strobe.
5. Multiple NEW cards in one Premium pack must not become visual soup.
   - They may celebrate in deterministic model order with short staggering,
   - or use bounded overlapping pulses,
   - but all five-card content must remain readable.

This is native Godot presentation work only.

**Do not use GameFeelFlow or Saltmire Spark in SB-M43-067.** Their canonical plugin-integration tasks are the future C005F program.

### REDUCED EFFECTS

For NEW cards:
- no scale bounce/pulse animation;
- no flashing;
- static/subtle NEW glow is allowed;
- `NEW` + `FIRST COPY` must remain explicit and readable;
- truth must match FULL.

## 5. DUPLICATE COUNT PRESENTATION — OWNER PRODUCT CONTRACT

Current `You now have N` is not sufficient as the primary duplicate-count communication.

For DUPLICATE rows, the hold state must explicitly say:

**EXTRAS xN**

where:
`N = copies_after - 1`.

Examples:
- `copies_after = 2` -> **EXTRAS x1**
- `copies_after = 3` -> **EXTRAS x2**
- `copies_after = 8` -> **EXTRAS x7**

The existing DUPLICATE badge remains.

### Optional total-owned secondary truth

If layout remains clean, you may additionally show:
- `OWNED x{copies_after}`

but **EXTRAS xN is the primary duplicate-count line** and cannot be replaced by total-owned wording.

For NEW rows:
- do not show `EXTRAS x0`;
- show **FIRST COPY**.

This aligns with protected-first-copy / Cards Exchange semantics and makes the exchangeable-extra quantity understandable.

## 6. LAYOUT

### Standard

Preserve:
- exact accepted 3-card row geometry;
- destination icons;
- pack staging;
- card order.

New glow/count labels must not:
- overlap neighboring cards;
- collide with rarity/name;
- collide with destination icons;
- clip at supported viewports.

### Premium

Preserve:
- exact accepted centered 3+2 geometry;
- row-major order 0,1,2 / 3,4;
- Premium card 0 guarantee truth.

The extra count/state presentation must fit all 5 cards without shrinking canonical card art into unreadability.

If necessary:
- tighten vertical label spacing modestly;
- use concise text;
- do not change the accepted 3+2 composition.

## 7. SEQUENCING / TAP GATES

Preserve:

Pack alone  
→ Tap 1  
→ accepted 01→09  
→ cards emerge  
→ NEW-card celebration(s) settle  
→ pack gone / readable hold  
→ destinations visible  
→ wait for Tap 2  
→ routing  
→ completion.

Important:
- no auto Tap 2;
- NEW celebration cannot route cards;
- count labels cannot alter route;
- extra taps during celebration/opening remain ignored/refused;
- destinations may appear only when the final hold is ready.

If you add a celebration timing step, use the existing presentation sequencing architecture. Do not introduce a second grant/transaction state machine.

## 8. IDEMPOTENCY / REOPEN

A presentation instance:
- celebrates each NEW card at most once;
- does not retrigger celebration from resize/relayout;
- does not retrigger from model getter/read;
- does not retrigger from destination appearance;
- does not retrigger from Tap 2.

Recreating a new ceremony from the same committed receipt may replay the **visual** celebration, because it is presentation only, but must never mutate Collection, rewards, RNG, receipt ledger or save.

No celebration event is authoritative.

## 9. ACCESSIBILITY / TEXT

Add canonical UiText keys as needed.

Required semantic text:
- `NEW`
- `FIRST COPY`
- `DUPLICATE`
- `EXTRAS xN`

Do not rely on color/glow alone.

Text must be readable on all target portrait viewports.

Do not invent rarity/ownership semantics.

## 10. SHARED IMPLEMENTATION

Standard is the base ceremony and Premium subclasses it.

Prefer a single shared card-state presentation implementation so Standard/Premium cannot drift.

A good seam is the existing shared `CardView`, provided the change remains readable and testable.

Do not duplicate NEW/DUPLICATE logic into two separate ceremony implementations.

Do not modify C008 receipt truth to make the UI easier.

## 11. OWNER-ACCEPTED SURFACES / ASSET LOCK

Do not modify:
- 9 Standard opening frame PNGs;
- 9 Premium opening frame PNGs;
- canonical 135 card PNGs;
- pack destination icons;
- C008 receipt schema/transaction semantics.

If `card_new_glow.png` is used:
- use the existing canonical file;
- do not alter its bytes in this task.

No new Collection/set/master ceremony yet. SB-M43-068 / 069 remain future tasks.

## 12. FOCUSED TESTS

Create:
`tests/m43_c005_c009_card_state_celebration.gd`

Cover at minimum:

1. NEW card derives from committed `is_new=true`, not live Collection.
2. NEW card requires `copies_after=1` through existing model truth.
3. NEW hold text = NEW + FIRST COPY.
4. NEW shows canonical `card_new_glow.png`.
5. NEW FULL gets one bounded celebration.
6. NEW Reduced gets no bounce/flash but remains explicit.
7. DUPLICATE hold text includes DUPLICATE.
8. copies_after 2 => EXTRAS x1.
9. copies_after 3 => EXTRAS x2.
10. copies_after N => EXTRAS x(N-1).
11. no NEW row shows EXTRAS x0.
12. repeated same-card rows within one pack show sequential FIRST COPY / EXTRAS x1 / EXTRAS x2 truth.
13. Standard mixed NEW/DUPLICATE layout remains valid.
14. Premium mixed 5-card layout remains valid.
15. all-new Standard.
16. all-new Premium.
17. all-duplicate Standard.
18. all-duplicate Premium.
19. celebration order deterministic.
20. celebration cannot retrigger on relayout/resize.
21. Tap 2 still blocked until AWAIT_ROUTE.
22. routing destinations unchanged.
23. reopening same C008 model does not mutate authority.
24. no Collection query is used to recompute card-state truth.
25. no pack/transaction/save calls added to CardView/ceremony presentation path.
26. Standard/Premium opening frame hashes unchanged.

### Sensitivity

Deliberately prove detection of:
- extras off-by-one (`copies_after` instead of `copies_after-1`);
- NEW incorrectly showing EXTRAS x0;
- DUPLICATE x2 displayed for copies_after 2;
- live-Collection recomputation injected;
- celebration retrigger on resize;
- Reduced Effects bounce/pulse;
- wrong new-glow asset;
- routing/destination changed;
- pack frame changed.

## 13. RUNTIME EVIDENCE

Update/create evidence tool(s) using real shipping ceremonies and committed models.

Required captures:

### Standard mixed
- NEW card during celebration;
- final hold showing FIRST COPY;
- duplicate showing EXTRAS x1 or higher;
- destinations visible.

### Standard repeated-card truth
Use a model where the same card rows visibly demonstrate:
- FIRST COPY;
- EXTRAS x1;
- EXTRAS x2,
if compatible with the Standard three-row validator/truth fixture.

### Premium mixed
- at least two NEW cards + duplicates;
- clean 3+2 hold;
- duplicate count readable.

### Premium duplicate-heavy
- multiple duplicate cards with different extras counts.

### Reduced Effects
- Standard mixed;
- Premium mixed;
- explicit state/count truth with no bounce/flash.

Required target viewports:
- 1080×1920
- 1080×2160
- 1170×2532
- 1290×2796
- 1536×2048

No clipping/overlap.

## 14. OWNER REVIEW HARNESS

Reuse the existing:
- Standard owner-review harness;
- Premium owner-review harness.

Update their pinned production hashes/tests if the shared ceremony source changes.

Fixtures must make this task easy to inspect live.

Required review modes:
- mixed NEW/DUPLICATE;
- all NEW;
- repeated/duplicate-heavy.

Existing keys R / E / 1 / 2 / 3 may be retained.

Create:
`coordination/sessions/M43-C005-C009/OWNER_REVIEW_INSTRUCTIONS_V01.md`

Tell owner exactly:
- which Standard scene to F6;
- which Premium scene to F6;
- what keys to press;
- what to visually judge:
  - NEW glow/pop;
  - FIRST COPY;
  - DUPLICATE;
  - EXTRAS xN correctness/clarity;
  - Premium 3+2 readability;
  - Reduced Effects restraint.

## 15. REGRESSION

Run at minimum:
- new C009 focused suite;
- C006 Standard focused suite;
- C007 Premium focused suite;
- both owner-review harness smokes;
- C008 pack commit suite;
- M39 Collection/CardPack/Exchange suites;
- M54 set/master exactly-once;
- relevant M43 ModalStack/BasePopup/RevealSequencer suites;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained errors.

## 16. EVIDENCE / LOG

Create:
- `coordination/sessions/M43-C005-C009/CARD_STATE_PRESENTATION_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C009/OWNER_REVIEW_INSTRUCTIONS_V01.md`
- `coordination/sessions/M43-C005-C009/CLAUDE_LOG_V01.md`
- evidence under `coordination/sessions/M43-C005-C009/evidence/v01/`.

Do not create another roadmap/tracker.

Do not edit root `TASKS.md`.

## 17. HANDOFF

Return:
- final SHA;
- exact production files changed;
- NEW celebration implementation;
- duplicate-count formula and examples;
- Reduced Effects behavior;
- sensitivity results;
- focused/regression/root results;
- evidence URLs;
- owner-review scene paths;
- blockers.

SB-M43-067 remains open until:
1. independent ChatGPT technical audit PASS; and
2. explicit OWNER VISUAL PASS.

Do not start SB-M43-068.

Finish exactly:

`AWAITING_GPT_M43_C005_C009_V01_CARD_STATE_AUDIT`
