# M43-C005-C006 — STANDARD CARD PACK PRODUCTION OPENING PRESENTATION

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-064**  
Root `TASKS.md`: **READ ONLY — ChatGPT owns it.**

## 0. Goal

Implement the **shipping Standard Card Pack opening presentation** for exactly **3 already-committed card results**.

This task is **SB-M43-064 only**.

It must use:
- the owner-approved Standard 9-frame opening sequence;
- the reusable production `RevealSequencer` from SB-M43-063;
- the new canonical 135 Collection card assets from C003;
- the existing BasePopup/ModalStack visual/lifecycle family.

Do **not** implement Premium Pack (SB-M43-065), transaction/commit wiring (SB-M43-066), first-new-card celebration (SB-M43-067), later ceremonies, or plugin feel work.

## 1. Sync and read first

Work from:
`C:\Users\sekip\Desktop\ScrubBots`

Sync `main` with `origin/main` non-destructively and preserve owner-local `project.godot`, addons and unrelated untracked work.

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M43-C005-C002/FINAL_OWNER_ACCEPTANCE_V01.md`
- `coordination/sessions/M43-C005-C002/CHATGPT_AUDIT_V04.md`
- `coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`
- `coordination/sessions/M43-C005-C003/CHATGPT_AUDIT_V01.md`
- `scripts/ui/components/reveal_sequencer.gd`
- `scripts/ui/popup/base_popup.gd`
- `scripts/ui/popup/modal_stack.gd`
- `scripts/collection/card_pack_service.gd`
- current C005 preview harness as **reference only**, never shipping authority.

## 2. Freeze and promote the owner-approved Standard opening art

The exact accepted Standard candidate frames are:

`assets/ui/candidates/m43_c005/pack_opening/standard/frame_01_closed.png`  
through  
`assets/ui/candidates/m43_c005/pack_opening/standard/frame_09_final_reveal.png`

The owner gave final visual approval in `FINAL_OWNER_ACCEPTANCE_V01.md`.

Promote the exact accepted bytes, without redraw/re-encode/edit, into a canonical shipping family such as:

`assets/ui/final/rewards/pack_opening/standard/frame_01_closed.png`  
...  
`assets/ui/final/rewards/pack_opening/standard/frame_09_final_reveal.png`

Use the exact hashes recorded in `PACK_ASSET_MANIFEST_V01.json` as the acceptance authority. Source and promoted destination must hash identically for all 9 frames.

Do not touch Premium frames in this task.

## 3. Product truth

Standard Pack = exactly **3 cards**.

The approved opening art sequence is:

1. closed;
2. charge;
3. pressure;
4. small first tear;
5. tear widens;
6. one card edge;
7. one card rises;
8. three card backs emerge;
9. final three card backs.

The pack animation itself shows **card backs only**.

Only after the opening sequence completes may the live committed card faces be presented.

There is:
- no reroll;
- no randomization inside the UI;
- no `OPEN AGAIN`;
- no grant/claim call from the presentation;
- no mutation of Collection inventory;
- no fabricated rarity or NEW/DUPLICATE state.

## 4. Committed presentation-model contract

Create a production presentation model/validator for a Standard opening. It must require a stable presentation id/key and **exactly 3 committed result rows**.

Each result must carry enough read-only truth to present:
- canonical card id;
- canonical card art path or deterministic canonical mapping;
- card name;
- rarity;
- whether this copy was NEW at the committed transaction;
- copies owned after commit for duplicate presentation.

Reject/fail closed if:
- card count != 3;
- any card id/art is invalid or missing;
- rarity is outside canonical values;
- duplicate state lacks a valid post-commit count;
- presentation id is empty.

This model is **presentation input only**. It must not call `CardPackService.open_standard()` or derive NEW/DUPLICATE by mutating/peeking and then opening.

SB-M43-066 will later create/wire the authoritative committed transaction result. In this task, use deterministic committed fixtures in tests.

## 5. Shipping StandardPack ceremony surface

Implement a real shipping class/controller under an appropriate `scripts/ui/ceremony/` or equivalent production path.

Use the existing `BasePopup` / `ModalStack` family.

Required presentation:
- title: Standard Pack;
- owner-approved 9-frame pack opening;
- after frame 09, exactly 3 canonical **new C003 full card images** appear;
- preserve the card's own canonical frame/name/rarity artwork rather than drawing a second fake card frame over it;
- add clear non-color-only UI state for **NEW** vs **DUPLICATE**;
- duplicates show the post-commit owned count;
- rarity must remain legible/accessibly stated even though it is visible in the card art;
- one final Continue action only;
- no reroll/open-again CTA;
- Back/Escape cannot bypass into a half-presented authoritative action.

## 6. Sequencing

Drive the opening with the shared `RevealSequencer`.

A practical implementation may use the sequencer's ordered timing plus `step_started` to switch the pack frame while using the sequencer for the timed beat. Do not create a second generic sequencing authority.

Requirements:
- deterministic order 01→09;
- no frame identity drift or runtime-generated pack art;
- then reveal the 3 committed card faces in deterministic order;
- final state contains all 3 cards fully readable;
- presentation completion fires once;
- reopening the **same presentation id** cannot produce a second independent one-shot run inside the same ceremony instance;
- cancel/free/route clear leaves no tween/timer/signal accumulation.

### Reduced Effects

Reduced Effects must:
- avoid the animated 01→09 motion chain;
- land quickly/immediately on the accepted final pack state;
- show all 3 committed card faces without flip/bounce/glow motion;
- preserve exactly the same card ids, names, rarities, NEW/DUPLICATE state and counts.

## 7. Canonical card assets

Use the accepted individual cards under:

`assets/ui/final/collection/cards/set_01..set_15/card_01..card_09.png`

Do not use old 3×3 source sheets, old cropped legacy cards, generated review contact sheets, or placeholder cards.

Do not modify any of the 135 canonical card PNGs.

## 8. No authority mutation in SB-M43-064

Hard prohibition for this task:
- no `open_standard()`;
- no `open_premium()`;
- no RewardGrantService calls;
- no CollectionInventory mutation;
- no set/master claim;
- no save;
- no progression/navigation authority;
- no ad/IAP;
- no fifth booster/economy changes.

The Standard ceremony consumes a **precommitted model** only.

## 9. Tests

Add a focused SB-M43-064 suite proving at minimum:

1. all 9 promoted Standard frame hashes equal the accepted source hashes;
2. exact frame order 01→09;
3. exactly 3 committed cards required;
4. exactly 3 card faces shown at final state;
5. all final card textures come from the new canonical 135-card tree;
6. rarity text/state matches model truth;
7. NEW vs DUPLICATE is explicit and duplicates show correct post-commit count;
8. no reroll/open-again action exists;
9. Reduced Effects final truth equals FULL final truth;
10. fast-forward/finalize cannot alter model/economy/save state;
11. cancel/free/reopen lifecycle leaves no presentation leaks;
12. source/static guard proves no pack opening/grant/collection mutation authority exists in the ceremony;
13. sensitivity mutations for wrong card count, wrong rarity, wrong asset path and wrong frame order are caught.

## 10. Visual evidence

Produce real Godot runtime evidence using the shipping Standard ceremony, not the old preview-only candidate builder.

Capture at least:
- 1080×1920;
- 1080×2160;
- 1290×2796;
- 1536×2048;
- one Reduced Effects final-state shot;
- one contact sheet or ordered evidence strip showing opening beats 01→09 plus final 3-card face reveal.

The actual cards must be readable enough to verify their identity/state. No clipped frame/effects/text.

If the shipping composition materially differs from the owner-approved C001 visual master, stop for owner visual review rather than self-approving.

## 11. Regression

Run:
- new SB-M43-064 focused suite;
- SB-M43-063 sequencer suite;
- current M43 Results / popup / acquisition / fail / ceremony-preview suites;
- relevant M39 Collection/CardPack tests;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained new errors/warnings.

## 12. Evidence / log

Create:
- `coordination/sessions/M43-C005-C006/STANDARD_PACK_PRODUCTION_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C006/CLAUDE_LOG_V01.md`
- runtime evidence under `coordination/sessions/M43-C005-C006/evidence/`.

Do not edit root `TASKS.md`.

## 13. Publish / return

Commit and push authorized changes to `origin/main`.

Return:
- final SHA;
- shipping Standard ceremony class path;
- promoted 9-frame final paths/hash proof;
- focused + regression results;
- runtime evidence/matrix/log URLs;
- whether owner visual review is needed;
- blockers, if any.

Finish exactly:

`AWAITING_GPT_M43_C005_C006_STANDARD_PACK_PRESENTATION_AUDIT`
