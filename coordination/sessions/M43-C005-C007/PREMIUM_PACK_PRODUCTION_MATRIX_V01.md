# M43-C005-C007 — Premium Pack Production Matrix V01 (SB-M43-065)

Date: 2026-10-04 · Implementer: Claude · Status: AWAITING_AUDIT (no verdict claimed) · OWNER VISUAL PASS still required

## 1. Premium frames (asset gate)

All nine C002 owner-accepted Premium candidates were diagnosed from decoded pixels with the V03 validator
(`tools/validate_m43_c005_standard_frame_alpha_v03.py`) **before** promotion: all CLEAN. **No alpha remediation was
required**; every frame was promoted byte-for-byte by `tools/build_m43_c005_premium_frame_manifest_v01.py` (which
refuses to promote a dirty frame). Historical candidates under `assets/ui/candidates/m43_c005/pack_opening/premium/`
untouched (== C002 `PACK_ASSET_MANIFEST_V01`). Record: `PREMIUM_FRAME_MANIFEST_V01.json`.

| # | file (`assets/ui/final/rewards/pack_opening/premium/`) | sha256 (== candidate == C002) | bytes | largest dark comp. / dark wash / max bbox-side fill / max edge-cut run |
|---|---|---|---:|---|
| 01 | `frame_01_closed.png` | `29b87a206bae589ce4811641a40d352186a6bf01528cad9279b390c82031034c` | 972,600 | 9623 / 29 / 0.01 / 5 |
| 02 | `frame_02_charge.png` | `44b88fbbc9796edadd13229268978ce7a3c94b22bcebd3bb9906f4d6a2bfe571` | 1,532,592 | 9386 / 24 / 0.04 / 0 |
| 03 | `frame_03_pressure.png` | `cf79d5b85d6227f69b462261e350c8bb1e27d8ad9deab135f5201faf778d9af6` | 1,695,103 | 9386 / 24 / 0.03 / 0 |
| 04 | `frame_04_first_tear.png` | `2cbe8a7470e403a68768bb0aa7ada536d1c5e52dbc92ee77d36d0406a9f2493f` | 1,049,017 | 9623 / 29 / 0.01 / 5 |
| 05 | `frame_05_tear_widens.png` | `072dbc8f4accd17b4eb0c4a679cb47d0fe5bf1083f7576480c926712be8ab564` | 1,837,082 | 9386 / 21 / 0.03 / 0 |
| 06 | `frame_06_card_edge.png` | `242a6d8166082f7e13e7f920bbe7249b62ba5626c2ef682cb9b9f1860a0d1b62` | 2,020,416 | 9386 / 21 / 0.03 / 3 |
| 07 | `frame_07_one_card_rises.png` | `f47a7b6ecb8d02f444acf4dd75d25f0276f8a9f2459320a799edee94768d9dfa` | 2,020,972 | 9386 / 21 / 0.03 / 3 |
| 08 | `frame_08_cards_emerge.png` | `72d63957839455a442120a1cfa8c78e2c3e319c3627322d0fb10c5a883afb065` | 2,049,886 | 9386 / 118 / 0.03 / 3 |
| 09 | `frame_09_final_reveal.png` | `0de24ea3509518b8a358d733925cee30b8bc4087219dceecc39f20bec750977a` | 2,061,236 | 9386 / 117 / 0.03 / 3 |

Gates (validator limits): dark component ≤ 25,000 (largest here = robot visor), wash ≤ 8,000, side fill ≤ 0.55, edge-cut
run ≤ 64; border band transparent; 1024×1536 RGBA. Pack-art card-back counts 0/0/0/0/0/1/1/5/5 (C002 manifest).
Sensitivity (`evidence/v01/validator_sensitivity_premium_v01.json`): for every Premium frame an injected opaque black
rectangle and an injected semi-transparent dark rectangle FAIL; historical dirty Standard 05..09 FAIL; 9 clean pass.
Sheets (evidence only, labels outside the images): `evidence/v01/PREMIUM_V01_{checkerboard,white,gray,black}_01_09.png`
— checkerboard, gray and white inspected frame by frame: no box, wash or straight cut.

## 2. Architecture

| Path | Role |
|---|---|
| `scripts/ui/ceremony/premium_pack_ceremony.gd` | `PremiumPackCeremony extends StandardPackCeremony`; `create_premium(model, reduced) -> {ok, reason, popup}`; overrides only the frame family (`_frame_paths`), title/popup id and `_layout` (3 + 2 block; each card rises from its own frame-09 card back) |
| `scripts/ui/ceremony/premium_pack_model.gd` | fail-closed Premium model: `presentation_id`, `kind == "premium"`, exactly 5 cards in service order, canonical id/art/name/rarity, strict bool NEW, coherent `copies_after` (NEW = 1, DUP ≥ 2, repeats count up by one), **card 0 ∈ RARE/EPIC/LEGENDARY** |
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | one minimal hook: frame paths now come from an overridable `_frame_paths()` (returns the same nine Standard paths) — so the Premium subclass never loads Standard textures |
| `scripts/ui/ui_text.gd` | `PACK_PREMIUM_TITLE` |

Inherited unchanged from the accepted Standard: IDLE → Tap 1 → OPENING (one `PackFrame`, 01..09, holds 0.40 / 0.22×7 /
0.30 s) → AWAIT_ROUTE (destinations, "Tap to collect your cards") → Tap 2 → ROUTING (serialized, one card in flight,
NEW → Collection, DUPLICATE → Cards Exchange) → COMPLETE once → `close("complete")`; Back consumed; Reduced = frame 09 +
short fades, both taps. No new UI language; no "GUARANTEED" badge (guarantee shown by card 0's real rarity, never reordered).

Hold geometry (`_layout`): card width = Standard (≤ 300 px), rows centred as one block between destinations and hint,
row gap 28 px, row 1 = cards 0,1,2, row 2 = cards 3,4. Emergence origin of card i = frame 09 card back i
(C002 `card_overlays`: x 278/395/512/629/746, y = top + 133).

Authority: presentation only — static guard over both Premium sources forbids pack opening, RNG, Collection /
Cards Exchange / reward / save / navigation identifiers and `sort`.

## 3. Requirement → test matrix (`tests/m43_c005_c007_premium_pack_presentation.gd`, 19 cases)

| Prompt §12 | Case | Direct assertion | Mutation caught |
|---|---|---|---|
| 1 manifest/hashes | p01 | shipping == manifest == candidate == C002; clean; counts 0/0/0/0/0/1/1/5/5; exactly 9 files | PM8 |
| 2 alpha/matte | p02 | rendered check 9/9; injected dark rectangle + historical dirty rejected | PM8 |
| 3–4 five cards | p03 | 0/1/2/3/4/6 → `card_count`; 5 == config == `PREMIUM_DRAWS` | — |
| 5–7 identity/state | p04 | unknown id, art, name, rarity, state, copies, kind, empty id, repeat order → exact reasons; duplicates allowed | — |
| 8–9 guarantee/order | p05 | card 0 COMMON rejected although cards 1/2 EPIC/LEGENDARY; RARE/EPIC/LEGENDARY card 0 accepted; order kept | PM1 |
| 10 duplicates | p04, p13 | repeat fixture valid & routed | — |
| 11 real service | p06 | `PREMIUM_DRAWS == 5`; 200 seeded `open_premium()` (test-only inventory) → 5 draws, first always Rare+, later draws include COMMONs; every service result maps to a valid model; checker sensitivity | — |
| 12–13 idle/no auto | p07 | 150 frames: IDLE, nothing bound, no tween; Premium frame 01; no card/destination/button | PM3 |
| 14–18 Tap 1 / cadence | p08 | one run; history 01..09; holds ≥ 0.18 s; Nth bound bytes == manifest Nth; one frame node; no face before 09 | PM5, PM6 |
| 19–21 emerge/hold | p09 | 5 cards emerge on 09; pack-free hold; pack gone; centred 3 + 2, order 0,1,2/3,4, no overlap, safe area | PM7 |
| 22 destinations | p10 | upper-left / upper-right, visible before Tap 2, clear of all five cards | — |
| 23 Tap 2 | p11 | 150 frames stationary, no route; tap → ROUTING; extra refused | PM4 |
| 24 mixed routing | p12 | routes `[[0,c],[1,e],[2,c],[3,e],[4,c]]`; each observed travelling to its own destination; max 1 in flight; arrivals `[0..4]` | PM2 |
| 25–26 repeat / all NEW | p13 | repeat deterministic across runs; all NEW → Collection ×5 | PM2 |
| 27 no mutation | p14 | model, economy/Collection/exchange snapshot, pack RNG, save bytes unchanged; real `open_premium()` detected | — |
| 28 completion | p15 | `[completed(id, 5 arrivals), closed("complete")]`, freed | — |
| 29 lifecycle | p16 | Back/Escape at 4 phases; 12 clears/closes: no late completion/tween/node; no replay; clean re-entry | — |
| 30 Reduced | p17 | no auto-open; frame `[9]`; same card truth/slots/destinations as FULL; waits for Tap 2; completes once | — |
| — static guard | p18 | Premium sources free of authority / RNG / sort; injection flagged | — |
| — card text | p19 | name / rarity / NEW-DUP / count / canonical art for all 5 in 3 fixtures; no overlay frame | — |
| 31 Standard regression | separate suites | Standard 21/21, Standard harness 14/14 | — |

## 4. Runtime evidence (`evidence/v01/`, rendering driver `tests/tools/premium_pack_snapshot.gd`)

Real flows, real taps via `SubViewport.push_input`; both gates observed (tool waits 20 frames at IDLE / AWAIT_ROUTE and
rejects auto-advance); per-shot checks: safe area, label widths, destinations clear of cards, 5 cards non-overlapping
3 + 2 in draw order, pack never visible with destinations. **0 REJECTED.**

`01_pack_idle`, `F01..F09_runtime_frame_0N` + `PREMIUM_RUNTIME_01_09_V01_CONTACT_SHEET.png`, `02_opening_mid`,
`03_opening_late_cards_emerging`, `04_five_card_hold`, `05_destinations_visible` (repeat), `06_mixed_pre_route`,
`07_new_card_to_collection`, `08_duplicate_card_to_exchange`, `09_complete`, `10_repeat_duplicate_to_exchange`,
`11_all_new_destinations`, `12_all_new_to_collection`, `R1..R5_reduced_*`, `V_destinations_{1080x1920,1080x2160,
1170x2532,1290x2796,1536x2048}`, `PREMIUM_V01_evidence_timeline_EVIDENCE_ONLY.png`.

Flow log: mixed `frames [1..9]`, routes `[[0,collection],[1,exchange],[2,collection],[3,exchange],[4,collection]]`,
arrivals `[0..4]`, closed `complete`, 2 taps; Reduced `frames [9]`, same routes, 2 taps.

## 5. Owner review

`res://tests/tools/owner_review/premium_pack_owner_review.tscn` (+ `.gd`), F6, real Premium ceremony on a real ModalStack,
default mixed fixture (card 0 EPIC), keys R / E / 1 / 2 / 3 (all fixtures keep card 0 Rare+), never taps; smoke
`tests/m43_c005_c007_premium_owner_review_harness.gd` 11/11. Instructions: `OWNER_REVIEW_INSTRUCTIONS_V01.md`.
