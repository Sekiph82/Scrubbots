# M43-C005-C007 — SB-M43-065 PREMIUM CARD PACK SHIPPING PRESENTATION V01

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-065**  
Expected Claude log: `coordination/sessions/M43-C005-C007/CLAUDE_LOG_V01.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. Goal

Implement the **shipping Premium Card Pack opening presentation** for exactly **5 committed draws**, using the owner-approved Premium 01→09 frame sequence and the same owner-approved interaction grammar now closed for Standard Pack.

Premium must preserve the real CardPackService invariant:

- Premium = exactly **5** draws;
- draw order is preserved;
- **slot/index 0 is the service's guaranteed Rare-or-better draw**;
- therefore card 0 must be RARE, EPIC or LEGENDARY;
- duplicates remain legal;
- the presentation does not reroll, grant, exchange, save or navigate.

This task is **presentation only**. SB-M43-066 will own pack-commit/atomic/reopen integration. Do not pull SB-M43-066 authority forward.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty files and unrelated untracked work.
5. Synchronize the Desktop checkout with latest `origin/main` **non-destructively**.
6. If sync cannot be completed safely without overwriting owner work, STOP and report the exact conflicting paths.
7. Only after Desktop + GitHub are synchronized may work begin.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read at minimum:

- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C006/OWNER_VISUAL_ACCEPTANCE_V03.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md`
- `coordination/sessions/M43-C005-C006/owner_review_harness/CHATGPT_AUDIT_V02.md`
- current Standard shipping ceremony/model/tests as the accepted interaction reference
- `scripts/ui/components/reveal_sequencer.gd`
- `scripts/ui/popup/modal_stack.gd`
- `scripts/collection/card_pack_service.gd`
- `scripts/collection/collection_inventory.gd`
- `scripts/collection/collection_card_catalog.gd`
- `scripts/economy/economy_config.gd`
- `coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`
- `coordination/sessions/M43-C005-C002/FINAL_OWNER_ACCEPTANCE_V01.md`
- `coordination/sessions/M43-C005-C002/CHATGPT_AUDIT_V04.md`
- all nine Premium candidate frames under:
  `assets/ui/candidates/m43_c005/pack_opening/premium/`
- the owner-approved Premium contact sheet:
  `coordination/sessions/M43-C005-C002/PREMIUM_CONTACT_SHEET_V03.png`
- C001 Premium visual-master fixture/layout, especially the accepted **5-card 3+2 layout**.

## 3. OWNER-LOCKED PREMIUM CEREMONY

The shipping Premium ceremony must read exactly:

**Premium Pack alone**  
→ deliberate **Tap 1**  
→ Premium opening frames **01→09**, one beat at a time  
→ final opening beat presents the five Premium card backs  
→ the **5 live committed cards emerge from the opened pack**  
→ pack disappears  
→ **5-card hold in a centered 3+2 layout**  
→ Collection icon upper-left + Cards Exchange icon upper-right  
→ wait for deliberate **Tap 2**  
→ NEW cards fly to Collection  
→ DUPLICATE cards fly to Cards Exchange  
→ complete once after all 5 arrivals.

Do not:
- show a nine-frame strip in shipping UI;
- auto-open;
- auto-route;
- add a Continue button;
- add reroll/open-again;
- reveal fewer/more than five cards;
- change card order;
- turn the Premium ceremony into a separate UI language from the accepted Standard ceremony.

The Premium gold pack identity is the visual distinction. Interaction grammar stays consistent with Standard.

## 4. FULL CADENCE — MATCH THE ACCEPTED STANDARD FEEL

FULL Premium mode must use all nine Premium beats in exact order:

`01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08 -> 09`

Use the **owner-accepted Standard V03 cadence** unless a hard technical reason prevents it:

- frame 01: **0.40 s**
- frames 02..08: **0.22 s each**
- frame 09: **0.30 s** before live cards begin emerging

No 01..08 beat may have an effective visible hold below **0.18 s**.

One current pack-frame TextureRect only.

Reduced Effects:
- keeps Pack IDLE and Tap 1;
- may jump directly to Premium frame 09;
- still reveals the same 5 committed cards;
- still shows destinations;
- still requires Tap 2;
- still routes all five cards correctly;
- does not change model truth or completion semantics.

## 5. PREMIUM ASSET INTAKE + CLEAN BACKGROUND GATE

Premium candidate art is historically owner-approved, but Standard later exposed a real matte/background problem. Therefore Premium may not be promoted blindly.

### 5.1 Diagnose all nine before promotion

Run decoded-pixel alpha/matte validation on all nine Premium candidates.

Use/reuse the generic logic already proven in:
`tools/validate_m43_c005_standard_frame_alpha_v03.py`
where technically appropriate.

For every Premium frame verify:
- 1024×1536 RGBA;
- transparent outer canvas;
- no large black/dark rectangle;
- no dark semi-transparent rectangular wash;
- no straight alpha/matte cut;
- no box visible over checkerboard, white, 50% gray or black;
- pack/card/glow artwork remains intact.

### 5.2 Promotion rule

If a Premium frame is already clean:
- preserve it byte-for-byte.

If any Premium frame fails:
- do **alpha/background remediation only**;
- preserve owner-approved pack identity, geometry, foil, tear progression, card-back positions/counts, glow and registration;
- never use a naive global dark-pixel delete;
- use Premium manifest card-overlay geometry where needed;
- create a reproducible Premium cleanup tool and a clean candidate family;
- prove the dirty source fails and the remediated candidate passes.

Do not alter the historical Premium candidate files in place.

Promote validated Premium bytes into:

`assets/ui/final/rewards/pack_opening/premium/`

with the canonical nine filenames.

Final shipping Premium frames must have a manifest with SHA-256 and decoded-pixel metrics.

### 5.3 Required evidence sheets

Produce 3×3 Premium 01→09 sheets on:
- checkerboard;
- white;
- 50% gray;
- black.

These are evidence only.

Any visible rectangular matte/background is a FAIL.

## 6. PREMIUM PRESENTATION MODEL

Create a strict presentation model/validator appropriate to the current architecture.

The input represents **already committed presentation truth**, not a request to open a pack.

Required model truth:
- non-empty `presentation_id`;
- Premium kind;
- exactly **5** cards;
- cards remain in source/service order;
- each card id exists in canonical 135-card catalog;
- art path is the canonical card art;
- name is canonical;
- rarity is canonical;
- `is_new` is strict bool;
- `copies_after` is a valid positive integer coherent with NEW/DUPLICATE state;
- repeated-card ordering remains coherent;
- **card 0 rarity must be RARE / EPIC / LEGENDARY**.

Why card 0:
`CardPackService.open_premium()` commits the guaranteed Rare-or-better draw first, then appends the other four draws. This task must preserve that exact service order.

Do not fabricate a "guaranteed" card if the input is invalid. Invalid model = fail closed / no popup.

Do **not** add a new "GUARANTEED RARE+" badge unless an existing owner-approved shipping surface already defines it. The guarantee is represented by truthful rarity/order; no invented visual language is required.

## 7. CARD PRESENTATION — FIVE CARDS

After the pack disappears, present exactly five live card faces in the owner-approved Premium composition:

- centered **3 cards on the first row + 2 cards on the second row**;
- preserve committed draw order row-major: 0,1,2 then 3,4;
- no overlap;
- no clipping;
- all five remain readable on target portrait sizes;
- use canonical card art and existing rarity visual language;
- each card shows rarity;
- each card shows NEW or DUPLICATE in text, not color alone;
- duplicate cards show truthful `copies_after`;
- NEW cards show truthful first-owned count;
- no second decorative rarity frame over already-framed canonical card art if Standard architecture has already eliminated that duplication.

The guaranteed card 0's rarity must remain readable. Do not reorder it for aesthetics.

## 8. DESTINATIONS + SECOND TAP

Use the same owner-accepted destination semantics as Standard:

- Collection upper-left;
- Cards Exchange upper-right;
- both visible before Tap 2;
- destination labels/icons reuse canonical existing art/text;
- icons do not cover cards.

Before Tap 2:
- all 5 cards remain stationary at their hold positions;
- no routing starts automatically.

After Tap 2:
- every NEW card routes only to Collection;
- every DUPLICATE routes only to Cards Exchange;
- all 5 routes occur exactly once;
- use restrained staggering/serialization so five simultaneous cards do not become visual soup;
- arrival order must be deterministic;
- no card disappears instantaneously without visible travel;
- complete only after all 5 arrivals.

## 9. AUTHORITY BOUNDARY — HARD

The Premium ceremony/model must not:
- call `open_premium()`;
- call `open_standard()`;
- draw RNG;
- mutate CollectionInventory;
- call `add_card()`;
- call CardsExchange;
- grant rewards;
- save;
- navigate;
- change pack counts;
- consume currency;
- claim set/master rewards.

Presentation only.

A test may instantiate real `CardPackService` to verify the **5 draw + guaranteed first Rare-or-better invariant**, but shipping Premium presentation code must never own that authority.

SB-M43-066 remains the future integration/atomicity task.

## 10. STANDARD PACK NON-REGRESSION

SB-M43-064 is now owner-accepted and CLOSED.

Treat the accepted Standard ceremony as protected.

If you introduce any shared helper/refactor:
- Standard visual/runtime semantics must remain unchanged;
- Standard V03 frame bytes remain unchanged;
- Standard 01→09 cadence remains unchanged;
- Standard two-tap gates remain unchanged;
- Standard 3-card layout/routing remains unchanged;
- existing Standard focused suite and owner-review harness smoke must still pass.

Prefer sharing clean presentation primitives, but do not destabilize Standard merely to remove small duplication.

If a shared refactor becomes necessary, keep it minimal and prove behavior parity.

## 11. LIFECYCLE / INPUT / IDEMPOTENT PRESENTATION

Premium must follow existing ModalStack/BasePopup conventions:

- Back/Escape cannot abandon a half-resolved presentation;
- extra taps during OPENING/ROUTING are ignored/refused;
- close/route-clear/free cancels active sequencing/tweens;
- no late completion after cancellation/free;
- a single popup instance cannot reopen/replay itself after completion;
- completion emits exactly once after five arrivals;
- re-entry with a new committed presentation model is clean.

This task is presentation idempotency only. Transaction/grant idempotency belongs to SB-M43-066.

## 12. TESTS

Create a focused suite, e.g.:

`tests/m43_c005_c007_premium_pack_presentation.gd`

It must cover at minimum:

1. Premium final frame manifest/hashes;
2. all 9 shipping Premium frames pass alpha/matte checks;
3. exact five-card model required;
4. invalid 0/1/2/3/4/6 card counts rejected;
5. unknown id rejected;
6. art/name/rarity mismatch rejected;
7. invalid copies/new state rejected;
8. service-order guarantee: card 0 must be Rare-or-better;
9. a model with card 0 COMMON is rejected even if another card is Rare+;
10. duplicates are allowed;
11. real CardPackService test proves `PREMIUM_DRAWS == 5` and first returned draw is Rare-or-better;
12. Pack IDLE waits indefinitely;
13. no auto-start;
14. Tap 1 starts exactly one FULL run;
15. exact frame history 01..09;
16. 01..08 effective holds >=0.18 s;
17. one pack frame at a time;
18. no live card face before final opening beat;
19. exactly five cards emerge;
20. pack disappears;
21. 3+2 hold layout, order preserved;
22. destination icons upper-left/right and clear of cards;
23. Tap 2 required;
24. mixed NEW/DUPLICATE routing across all five;
25. repeated duplicates deterministic;
26. all-new route case;
27. no state/economy/save/RNG mutation by ceremony;
28. completion once after 5 arrivals;
29. lifecycle/back/cancel/free/re-entry;
30. Reduced Effects same truth/two gates;
31. Standard Pack regression remains PASS.

Sensitivity must deliberately prove detection of at least:
- card0 COMMON;
- wrong destination;
- auto-start;
- auto-route;
- skipped Premium frame;
- hold below 0.18 s;
- stale pack left visible;
- a dirty dark rectangular Premium frame.

## 13. REAL RUNTIME EVIDENCE

Create a Premium runtime evidence driver analogous to the Standard evidence tool.

Required captures:
- Premium pack IDLE;
- actual runtime frame 01;
- 02;
- 03;
- 04;
- 05;
- 06;
- 07;
- 08;
- 09;
- five live cards emerging;
- pack-free five-card hold;
- destinations visible;
- mixed pre-route state;
- NEW card moving toward Collection;
- DUPLICATE card moving toward Cards Exchange;
- final completion;
- Reduced Effects key states.

Create an evidence-only:
`PREMIUM_RUNTIME_01_09_V01_CONTACT_SHEET.png`

Also capture the five-card destination hold at:
- 1080×1920
- 1080×2160
- 1170×2532
- 1290×2796
- 1536×2048

No clipping/overlap.

## 14. OWNER REVIEW HARNESS — INCLUDE NOW

To avoid another tooling-only cycle, also create a review-only scene:

`tests/tools/owner_review/premium_pack_owner_review.tscn`  
`tests/tools/owner_review/premium_pack_owner_review.gd`

It must:
- instantiate the real shipping Premium ceremony through real ModalStack;
- default to a deterministic mixed 5-card fixture with card 0 Rare+;
- require the owner's actual click for Tap 1;
- require the owner's actual click for Tap 2;
- never auto-tap;
- never duplicate animation logic.

Review-only keys:
- **R** replay;
- **E** FULL/Reduced;
- **1** mixed NEW/DUPLICATE fixture;
- **2** all NEW fixture;
- **3** repeated-duplicate fixture.

All fixtures must retain card 0 Rare-or-better.

Add concise:
`coordination/sessions/M43-C005-C007/OWNER_REVIEW_INSTRUCTIONS_V01.md`

This harness is evidence/review tooling only and must not become startup/main scene.

## 15. VALIDATION / REGRESSION

Run at minimum:

- new Premium focused suite;
- Premium owner-review harness smoke;
- V03 Premium alpha/matte validator;
- existing Standard presentation suite;
- existing Standard owner-review harness smoke;
- RevealSequencer suite;
- relevant M39 CardPack/Collection suites;
- relevant M43 modal/popup/ceremony suites;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained runtime/script error.

## 16. EVIDENCE / COORDINATION FILES

Create:
- `coordination/sessions/M43-C005-C007/PREMIUM_PACK_PRODUCTION_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C007/PREMIUM_FRAME_MANIFEST_V01.json`
- `coordination/sessions/M43-C005-C007/OWNER_REVIEW_INSTRUCTIONS_V01.md`
- `coordination/sessions/M43-C005-C007/CLAUDE_LOG_V01.md`
- evidence under:
  `coordination/sessions/M43-C005-C007/evidence/v01/`

Do not create a second roadmap/tracker.

Do not edit root `TASKS.md`.

## 17. HANDOFF

Return:
- final SHA;
- Premium final frame hashes;
- whether any Premium alpha remediation was required;
- exact five-card model/guarantee proof;
- measured FULL 01..08 hold times;
- focused/sensitivity/regression/root results;
- runtime evidence URLs;
- owner review scene path;
- blockers.

Leave SB-M43-065 open for independent ChatGPT technical audit + OWNER VISUAL PASS.

Do not start SB-M43-066.

Finish exactly:

`AWAITING_GPT_M43_C005_C007_V01_PREMIUM_PACK_AUDIT`
