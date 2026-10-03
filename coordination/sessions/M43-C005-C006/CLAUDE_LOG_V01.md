# M43-C005-C006 — CLAUDE LOG V01 — Standard Card Pack Production Opening Presentation

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-064
Status: **AWAITING_AUDIT** (E1/E2 evidence only; no audit verdict claimed) · **owner visual review requested** (see §6)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V01.md
- Prior audits: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md (SB-M43-063 PASS), https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C002/CHATGPT_AUDIT_V04.md, https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C003/CHATGPT_AUDIT_V01.md
- `M43-C005-C002/FINAL_OWNER_ACCEPTANCE_V01.md`, `PACK_ASSET_MANIFEST_V01.json`, `M43-C005-C001/OWNER_VISUAL_DECISION_V02.md`
- `CLAUDE.md`, root `TASKS.md` (read only, **not edited**), `coordination/AUDIT_POLICY.md`
- `reveal_sequencer.gd`, `base_popup.gd`, `modal_stack.gd`, `card_pack_service.gd`, `collection_inventory.gd`, C005 preview harness (reference only)

Learnings applied: file existence ≠ evidence (render + direct property assertions); never fabricate art (byte-exact promotion, hash-gated against the manifest, canonical card art only); direct observability + sensitivity (every material assertion has a comparator sensitivity check or a source mutation that breaks it); headless timing ≠ visual evidence (frame order proven from bound-frame history, visuals from a rendering-driver run).

## Sync

- `main` was 3 behind `origin/main` (8feab75 → C005 audit + C006 prompt); `git merge --ff-only origin/main` clean.
- Owner/local work preserved, **not committed**: `M project.godot`, untracked `.mcp.json`, `addons/`, `*.import`, `*.uid`, etc.

## 1. Implementation

| File | Change |
|---|---|
| `assets/ui/final/rewards/pack_opening/standard/frame_01..09_*.png` | new: exact bytes of the 9 owner-accepted candidates (`cp`; `cmp` BYTE_IDENTICAL ×9; sha256 == manifest ×9) |
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | new shipping `StandardPackCeremony extends BasePopup` |
| `scripts/ui/ceremony/standard_pack_model.gd` | new fail-closed presentation-model validator |
| `scripts/collection/collection_card_catalog.gd` | new read-only id → {set, card, name, rarity, art} reader |
| `data/config/collection_card_catalog_v1.json` | new: 135 cards generated from the audited C003 manifest; every rarity == the `economy_rewards_v1.json` profile derivation (0 mismatches), 135 unique names/paths |
| `scripts/ui/ui_text.gd` | `PACK_*`, `RARITY_*` keys |
| `tests/m43_c005_c006_standard_pack_presentation.gd` | new focused suite (13 cases) |
| `tests/support/standard_pack_fixtures.gd` | deterministic committed fixtures (catalog only) |
| `tests/tools/standard_pack_snapshot.gd` | rendering-driver evidence tool for the shipping ceremony |
| `assets/ui/VISUAL_ASSET_INDEX.md` | new `rewards/pack_opening/standard (9)` section |
| `coordination/sessions/M43-C005-C006/STANDARD_PACK_PRODUCTION_MATRIX_V01.md`, `evidence/*.png` | matrix + 8 runtime PNGs |

Why a card catalog file: no shipping source held card names; the only canonical name source was the coordination-only C003 manifest. Without it, the validator could not reject a fabricated name/rarity/art. It is identity content only (no ownership, counts or grants) and is consumed read-only.

Design details (full table in the matrix):
- Model `{presentation_id, cards:[{card_id, art, name, rarity, is_new, copies_after}×3]}`; NEW ⇒ `copies_after == 1`, DUPLICATE ⇒ `≥ 2`, a card repeated inside one pack must count up by one and be NEW at most on its first row.
- One `RevealSequencer` per ceremony, key = `presentation_id`, started on `opened`. Pack beats are zero-duration steps on the `pack_frame` property after per-beat holds (01 rests 0.40 s, then 0.14 s per beat), then 3 face fades (0.20 s, first after a 0.35 s rest on frame 09), then the committed note. `finish()` therefore lands exactly frame 09 + all faces. Reduced: plan = frame 09 + faces + note, landed in one call.
- Continue is blocked until completion; tap on stage/cards fast-forwards; Back/Escape consumed (not dismissible); `closed` cancels the sequencer.
- Card images are bound as-is (one TextureRect per tile; no rarity frame overlay). NEW/DUPLICATE is a text badge; rarity is a text chip; count is `You now have N`.
- Frames 05/07/09 contain the accepted near-black ground (alpha ≈ 237–251, noted by the owner in the acceptance); the stage is drawn black so the beats read as one continuous animation.

## 2. Validation (Godot 4.7.2.stable; `--import` rc=0 first)

| # | Command | Expected / failure condition | Actual |
|---|---|---|---|
| V1 | `godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd` | 13/13 cases, 0 fail | **PASS 13/13, 0 fail** |
| V2 | Source mutations (temporary, restored, `diff -q` RESTORED) | each must fail V1 | M1 swap frames 03/04 → 2 FAIL (c01, c02); M2 rarity not canon-checked → 1; M3 count check loosened → ledger incomplete; M4 art not checked → 2; M5 Reduced plays chain → 1; M6 Continue not gated → 2; M7 wrong card asset → 1. **All 7 detected** |
| V3 | `godot --path . -s res://tests/tools/standard_pack_snapshot.gd -- coordination/sessions/M43-C005-C006/evidence` (rendering driver) | every shot fits safe area + `text_fits`, strip beats exactly `1..9, final`, 0 REJECTED | **8 SNAPSHOT, 0 REJECTED**; strip `["1".."9","final"]`; shots visually inspected (1080×1920, 1080×2160 repeat, 1536×2048, strip) |
| V4 | `-s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | PASS | **PASS 12/12** |
| V5 | M43 `c001a` / `c001b` / `c001r_c001` / `c002_c001` / `c003_c001` / `c004_c001` / `c005_c001` | PASS each | **11/11, 11/11, 40/40, 23/23, 34/34, 40/40, 17/17** |
| V6 | M39/M54 Collection + economy: `m39a_economy_core`, `m39d_daily_collection`, `m39e_full_matrix`, `m39_v02_atomicity`, `m39_v03_full_surface`, `m54_collection_set_master_exactly_once` | PASS each | **all PASS**, 0 script errors |
| V7 | Root `-s res://tests/run_tests.gd` | ALL PASS | **Total checks 5323, RESULT: ALL PASS** |
| V8 | `git diff --check` | clean | **clean** |

Warnings: no `SCRIPT ERROR` anywhere. The focused suite's exit lines (`39 ObjectDB leaked / 19 resources in use`) are, per `--verbose`, the economy-service RefCounted graph of the one `AppState` built in c10 — the same pre-existing pattern every AppState-using suite shows; no ceremony/catalog/model object is listed.

Failures found and fixed during the cycle:
1. Parse error: `FRAMES` collides with BasePopup's `FRAMES` const → renamed `PACK_FRAMES`.
2. Frame history logged frame 01 twice (`from` + `to` of the first step) → the log records changes only.
3. Test-side orphan popup in c03 (valid `create()` never pushed) leaked ~50 CanvasItems at exit → freed.
4. c02's frame-file check first compared against the ceremony's own list (circular; mutation M1 slipped through it) → now checks beat N against the manifest's Nth name + sha256; M1 re-run caught by c02 as well.
5. The committed note was visible before the faces → it now fades in with the reveal.

False-positive risks handled: comparators each have a positive sensitivity check (real `open_standard()` changes economy + RNG; changed rarity label changes final info; injected `open_standard`/`add_card` flagged; bad models give the exact reason code); tween counts are relative to a baseline.

## 3. Scope boundaries

Not touched: Premium frames/ceremony (SB-M43-065), transaction/commit wiring (SB-M43-066 — no caller opens this ceremony yet), first-new-card celebration (SB-M43-067), `CardPackService`/`CollectionInventory`/economy/save code, the 135 card PNGs, the preview harness, GameFeelFlow/Saltmire Spark, root `TASKS.md`.

## 4. Known notes

- `VISUAL_ASSET_INDEX.md` collection-card byte sizes still list pre-C003 values and the top audit summary counts are stale (pre-existing; not recomputed here).
- The ceremony takes `reduced` from its caller; binding it to `AppState` Reduced Effects happens with the SB-M43-066 wiring.

## 5. Commit / push

See handoff response for the final SHA.

## 6. Owner visual gate

No owner-accepted pack-opening **composition** exists (C001 pack candidate rejected; C002 accepted frame assets only). The shipping composition (black stage above the 3-card row, badge placement, timing) is new → **owner visual review requested**, not self-approved. Evidence: `coordination/sessions/M43-C005-C006/evidence/`.

`AWAITING_GPT_M43_C005_C006_STANDARD_PACK_PRESENTATION_AUDIT`
