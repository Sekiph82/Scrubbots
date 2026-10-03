# M43-C005-C006 — Standard Pack Production Matrix V01 (SB-M43-064)

Date: 2026-10-04 · Implementer: Claude · Status: AWAITING_AUDIT (no verdict claimed)

## 1. Promoted Standard opening frames (byte-identical)

Source `assets/ui/candidates/m43_c005/pack_opening/standard/` → destination
`assets/ui/final/rewards/pack_opening/standard/`. Copy only (`cp`), confirmed with `cmp`;
authority = `coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`.

| # | File | Beat | sha256 (manifest = source = destination) | Bytes | Cards in art |
|---|---|---|---|---:|---:|
| 01 | `frame_01_closed.png` | closed | `ae31881ea692af695125d539832b48a5d76ef77672a22864dcc784c1d35eceea` | 691,154 | 0 |
| 02 | `frame_02_charge.png` | charge | `075e917c6e82a9bc555650df57b187d2eacc34b74e0fc504a1ff76c708f66b32` | 1,261,936 | 0 |
| 03 | `frame_03_pressure.png` | pressure | `086a7e7e6deb325c573e6fdd362c1f0d801b1acb3fb8f04786b74e4ad3cfc2a4` | 1,392,316 | 0 |
| 04 | `frame_04_first_tear.png` | small first tear | `81183737951d9d17ef7e50ca95f9e1f776d35d733af66eb1a79779db0295e160` | 745,974 | 0 |
| 05 | `frame_05_tear_widens.png` | tear widens | `0d47eeb9b4ac3f7483d64f5298bd06c8eb286a8c0df4968fba8c6f5c43674b63` | 1,596,068 | 0 |
| 06 | `frame_06_card_edge.png` | one card edge | `2d12e040123598072046d5b2b6049599d31334fddea444317a39adcd85eff189` | 1,786,185 | 1 |
| 07 | `frame_07_one_card_rises.png` | one card rises | `6b20fa33e72d09319cf1aea6adc0ebf8fa51feb7787ff072e9a0e6d7adf1c1ef` | 1,785,357 | 1 |
| 08 | `frame_08_cards_emerge.png` | three backs emerge | `a29d9ed9c7727887b7a76ae972ddfb61b18f673f6c30c63b1ec0cf42a70b05af` | 1,812,340 | 3 |
| 09 | `frame_09_final_reveal.png` | final three backs | `561753dc9ade575874685d4cc07b8bd8bbd4f2e984c28ee228a76248ef385402` | 1,844,098 | 3 |

Premium frames: not touched / not promoted. Card PNGs (135): not touched.

## 2. Shipping architecture

| Path | Role | Authority |
|---|---|---|
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | `StandardPackCeremony extends BasePopup`; built via `create(model, reduced) -> {ok, reason, popup}`; pushed on the app's `ModalStack` | presentation only |
| `scripts/ui/ceremony/standard_pack_model.gd` | `StandardPackModel.validate(model) -> {ok, reason, model}`; fail-closed contract | read-only validation |
| `scripts/collection/collection_card_catalog.gd` + `data/config/collection_card_catalog_v1.json` | canonical card identity id → {set, card, name, rarity, art}; generated from the audited C003 manifest; rarity cross-checked against `economy_rewards_v1.json` profiles (0 mismatches / 135) | read-only content |
| `scripts/ui/components/reveal_sequencer.gd` (SB-M43-063, unchanged) | the one sequencing authority | presentation only |
| `scripts/ui/ui_text.gd` | `PACK_*` and `RARITY_*` keys | copy |

Model contract: `{presentation_id, cards:[{card_id, art, name, rarity, is_new, copies_after} ×3]}`.
Rejected (reason codes): `card_count`, `presentation_id_empty`, `card_N_unknown_id`, `card_N_art`
(not the canonical art or missing), `card_N_name`, `card_N_rarity` (outside COMMON/RARE/EPIC/LEGENDARY
or not the card's canonical rarity), `card_N_state` (non-bool NEW / non-int count), `card_N_copies`
(NEW must be 1 after commit, DUPLICATE ≥ 2), `card_N_repeat_order` (a card repeated in one pack must
count up by one and only its first row may be NEW).

Composition (top → bottom): `STANDARD PACK` title pill · black `PackStage` (frames 05/07/09 carry the
accepted near-black ground) with the 9 frames · `Cards` row of 3 canonical card images (no extra frame),
each with a NEW/DUPLICATE text badge on its top edge, live name, rarity chip (text + colour), and
`You now have N` · `Already added to your collection.` · one `CONTINUE`.

Timing (FULL): frame 01 → hold 0.40 s → 02..09 every 0.14 s → hold 0.35 s → 3 face fades × 0.20 s →
note fade 0.20 s (≈ 2.5 s). Each pack beat is a zero-duration `pack_frame` step; faces are faded tiles.
REDUCED: frame 09 + faces + note landed in one call (no tween, no 01..08 chain).

Input: Continue blocked until the sequencer completes; tap on stage/cards = `finish()` (fast-forward,
presentation only); Back/Escape consumed by ModalStack, ceremony not dismissible → nothing happens;
close/clear cancels the sequencer (no late completion).

## 3. Requirement → test matrix (`tests/m43_c005_c006_standard_pack_presentation.gd`)

| Prompt §9 | Case | Direct assertion | Source mutation that the case catches |
|---|---|---|---|
| 1 hashes | c01 | 9 destination sha256 == source == manifest; exactly 9 files; no premium dir | M1 (swap 03/04) |
| 2 order 01→09 | c02 | `frame_history() == [1..9]`; beat N binds manifest's Nth file name + sha256; 13 ordered sequencer steps; no face alpha > 0 before frame 09 | M1 |
| 3 exactly 3 | c03 | 0/1/2/4/5 cards → `card_count`, popup null; 3 == configured `standard_pack_draws` | M3 (count check loosened) |
| 4 three faces | c04 | final: frame 09, 3 tiles alpha 1 + visible + textured, note visible, Continue live | — |
| 5 canonical tree | c05 | catalog: 135 unique canonical paths, rarity == CollectionInventory catalog; face textures == canonical art in model order; one TextureRect per tile (no second frame) | M7 (wrong card asset) |
| 6 rarity | c06 | rarity chip text == model rarity == canonical; live name == model name | M2 (rarity not canon-checked) |
| 7 NEW/DUP | c07 | badges + `You now have N` for mixed and repeated-card packs; text differs (not colour-only) | — |
| 8 no reroll | c08 | action ids == `["continue"]`; no reroll/again/buy text; Back + ui_cancel consumed, no action; blocked Continue cannot fire; Continue closes exactly once after completion | M6 (Continue not gated) |
| 9 Reduced parity | c09 | Reduced info == FULL final info; frame history `[9]`, no tween, completed once at open | M5 (Reduced plays chain) |
| 10 no mutation | c10 | caller + validated model unchanged; economy/Collection snapshot + pack RNG state unchanged; save bytes unchanged after tap/finish/start/continue; sensitivity: real `open_standard()` detected | — |
| 11 lifecycle | c11 | 30 clear/finish/close cycles: no tween/node/connection growth; cancelled runs never complete; same id refused; freed mid-run host leaves no tween | — |
| 12 static guard | c12 | ceremony/model/catalog code free of open_*/add_card/grant/claim/RewardGrant/CardPackService/CollectionInventory/economy/AppState/save/navigation/RNG identifiers; injection flagged | — |
| 13 sensitivity | c13 | 11 bad models rejected with exact reason codes (count, rarity ×2, art ×2, name, id, copies ×2, state, empty id) + repeat-NEW; frame-order checker flags swapped/missing beats; final-info comparator sees a changed rarity label | M4 (art not checked) |

## 4. Runtime evidence (`evidence/`, rendering driver, `tests/tools/standard_pack_snapshot.gd`)

| File | Content |
|---|---|
| `standard_pack_1080x1920.png`, `_1080x2160`, `_1170x2532`, `_1290x2796`, `_1536x2048` | final state, mixed pack (Mud Blob COMMON NEW · Greasy Pan RARE DUPLICATE 2 · Scrubbot Prime LEGENDARY NEW) |
| `standard_pack_reduced_effects_1080x2160.png` | Reduced Effects final state |
| `standard_pack_repeat_1080x2160.png` | same card twice (Mighty Mop NEW 1 → DUPLICATE 2) + Sludge Beast EPIC DUPLICATE 5 |
| `standard_pack_opening_strip_1080x2160.png` | real run captured each time a beat bound: 01..09 + final faces (tool rejects anything but exactly `1..9, final`) |

All shots: frame inside the safe area, `text_fits()` true, 0 REJECTED.

## 5. Owner visual gate

There is **no owner-accepted pack-opening composition master**: the C001 pack candidate was rejected
(`OWNER_VISUAL_DECISION_V02.md`) and C002 accepted the frame assets only. This shipping composition
(stage above the 3-card row, black stage, badge placement, timing) is therefore new and is presented
for **owner visual review**; it is not self-approved.
