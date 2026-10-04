# M43-C005-C007 — CLAUDE LOG V01 — Premium Card Pack Shipping Presentation

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-065
Status: **AWAITING_AUDIT** (E1/E2 only; no verdict claimed) · OWNER VISUAL PASS required

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C007/CHATGPT_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C007/CHATGPT_AUDIT_CRITERIA_V01.md
- `M43-C005-C006/OWNER_VISUAL_ACCEPTANCE_V03.md` (SB-M43-064 CLOSED), `CHATGPT_AUDIT_V03.md`, `owner_review_harness/CHATGPT_AUDIT_V02.md`
- `M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`, `FINAL_OWNER_ACCEPTANCE_V01.md`, `CHATGPT_AUDIT_V04.md`, `PREMIUM_CONTACT_SHEET_V03.png`, the nine Premium candidates
- `CLAUDE.md`, root `TASKS.md` (read only, not edited), `coordination/README.md`, `coordination/AUDIT_POLICY.md`
- Standard ceremony/model/tests (accepted reference), `reveal_sequencer.gd`, `modal_stack.gd`, `card_pack_service.gd`, `collection_inventory.gd`, `collection_card_catalog.gd`, `economy_config.gd`, C001 Premium 3 + 2 fixture layout

Learnings applied: diagnose assets from decoded pixels before promotion (V03 lesson); never promote blindly; sensitivity
for every gate; time-based loop caps (no frame-count caps that can expire under fast headless frames); taps as real GUI events.

## Sync

`git fetch origin --prune` → 0 ahead / 6 behind; `git merge --ff-only origin/main` clean. Owner/local preserved, not
committed: `M project.godot`, `M scenes/app/main.tscn`, untracked owner files. The Godot editor (killed at its background
time limit in the previous session) had re-saved `tests/tools/owner_review/standard_pack_owner_review.tscn` with
machine-local uid/unique_id lines; that file is mine and the change was editor metadata only → restored to the committed
path-only version (`git checkout --` of that single file).

## 1. Changes

| File | Change |
|---|---|
| `assets/ui/final/rewards/pack_opening/premium/frame_01..09` | new, byte-identical promotion of the clean C002 candidates |
| `tools/build_m43_c005_premium_frame_manifest_v01.py` | new: validates every candidate from pixels, refuses dirty, promotes, writes manifest |
| `coordination/sessions/M43-C005-C007/PREMIUM_FRAME_MANIFEST_V01.json` | new |
| `scripts/ui/ceremony/premium_pack_model.gd` | new fail-closed Premium model (5 cards, card 0 Rare+, order kept) |
| `scripts/ui/ceremony/premium_pack_ceremony.gd` | new `PremiumPackCeremony extends StandardPackCeremony` (frames, title, 3 + 2 layout, per-back emergence) |
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | minimal shared hook: `_frame_paths()` (same nine Standard paths) replaces the inline const loop |
| `scripts/ui/ui_text.gd` | `PACK_PREMIUM_TITLE` |
| `tests/support/premium_pack_fixtures.gd` | new mixed / all_new / repeat (card 0 always Rare+) |
| `tests/m43_c005_c007_premium_pack_presentation.gd` | new focused suite (19 cases) |
| `tests/tools/premium_pack_snapshot.gd` | new rendering-driver evidence tool (adapted from the Standard tool) |
| `tests/tools/owner_review/premium_pack_owner_review.{tscn,gd}` | new review scene/controller |
| `tests/m43_c005_c007_premium_owner_review_harness.gd` | new harness smoke (11 cases) |
| `tests/m43_c005_c006_owner_review_harness.gd` | Standard harness: ceremony pin re-pinned after the hook (`380cec3e…` → `b95b9e10…`, LF-normalised), with comment |
| `tests/m43_c005_c006_standard_pack_presentation.gd` | Standard c01: obsolete C006 scope clause "no Premium frames promoted" removed (SB-M43-065 owns that family now); the Standard-family check stays |
| `assets/ui/VISUAL_ASSET_INDEX.md` | Premium section + note |
| `M43-C005-C007/PREMIUM_PACK_PRODUCTION_MATRIX_V01.md`, `OWNER_REVIEW_INSTRUCTIONS_V01.md`, this log, `evidence/v01/*` | evidence |

Standard behaviour: the only production change to the accepted Standard is the `_frame_paths()` indirection, which
returns exactly the previous nine paths. Standard frames, cadence, gates, 3-card layout and routing are untouched; proven
by the Standard suite 21/21, Standard harness 14/14 and the Standard validator 9/9 (§3).

Design choices: subclassing reuses the owner-accepted state machine (no second sequencing authority, no duplicated
gates). Premium model logic duplicates the Standard per-card checks (~30 lines) rather than refactoring the closed
Standard model. Emergence: card i rises from frame 09's card back i (C002 overlay geometry) — the first attempt reused the
Standard mid-pack mouth point, which made row-2 cards travel down through the pack body; fixed before evidence.

## 2. Five-card model / guarantee proof

- `PremiumPackModel.CARD_COUNT == 5 == economy premium_pack_draws == CardPackService.PREMIUM_DRAWS` (p03).
- Card 0 must be RARE/EPIC/LEGENDARY: a model with card 0 COMMON and EPIC/LEGENDARY later is rejected
  `card_0_not_rare_or_better` (p05); the validated model keeps draw order (p05) and the ceremony source contains no `sort`.
- Real service (p06, test-only inventory + reward stub, seeded RNG): 200 `open_premium()` calls → always 5 draws, the
  first always Rare+, later draws include COMMONs, and every service result (with NEW/copies derived from the
  pre-open counts) is a valid Premium presentation model. The ceremony never calls the service (p18 guard, p14 RNG state).

## 3. Validation

| # | Command | Expected | Actual |
|---|---|---|---|
| V1 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/candidates/m43_c005/pack_opening/premium` | diagnose all 9 | **9/9 CLEAN** (no remediation) |
| V2 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py --sensitivity <premium candidates> <standard historical> evidence/v01/validator_sensitivity_premium_v01.json` | all expectations | **SENSITIVITY PASS** |
| V3 | `python tools/build_m43_c005_premium_frame_manifest_v01.py` | promote + manifest | 9 promoted byte-identical |
| V4 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/final/rewards/pack_opening/premium` | 9 CLEAN | **9/9** |
| V5 | `godot --headless --path . -s res://tests/m43_c005_c007_premium_pack_presentation.gd` | 19/19 | **PASS 19/19** (×4 runs) |
| V6 | Premium mutations (temporary; `cmp` RESTORED) | each fails | PM1 card-0 guarantee removed → p05; PM2 wrong destination → 4 FAIL; PM3 auto-start → 4 FAIL; PM4 auto-route → p09 + ledger; PM5 Premium frame 05 skipped → p08; PM6 frame 03 hold 0.12 s → p08; PM7 stale pack → p09; PM8 dirty frame 09 → p01/p02/p08. **All 8 detected** |
| V7 | `godot --path . -s res://tests/tools/premium_pack_snapshot.gd -- coordination/sessions/M43-C005-C007/evidence/v01` | 0 REJECTED | **0 REJECTED**; runtime frames `01..09 = frame_01_closed … frame_09_final_reveal` |
| V8 | `-s res://tests/m43_c005_c007_premium_owner_review_harness.gd` | 11/11 | **PASS 11/11** |
| V9 | `-s res://tests/m43_c005_c006_standard_pack_presentation.gd` | 21/21 | **PASS 21/21** (after the scope-clause update) |
| V10 | `-s res://tests/m43_c005_c006_owner_review_harness.gd` | 14/14 | **PASS 14/14** (after re-pin) |
| V11 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/final/rewards/pack_opening/standard` | 9 CLEAN | **9/9** |
| V12 | `-s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | 12/12 | **PASS** |
| V13 | M43 `c001b`, `c002_c001`, `c003_c001`, `c004_c001`, `c005_c001` | PASS | **11/11, 23/23, 34/34, 40/40, 17/17** |
| V14 | M39/M54 `m39a_economy_core`, `m39d_daily_collection`, `m39e_full_matrix`, `m39_v02_atomicity`, `m39_v03_full_surface`, `m54_collection_set_master_exactly_once` | PASS | **all PASS** |
| V15 | root `-s res://tests/run_tests.gd` | ALL PASS | **5,323, ALL PASS**, 0 script errors |
| V16 | `git diff --check` | clean | **clean** |

No `SCRIPT ERROR` in any final run. Exit-time "resources still in use" lines are the AppState economy graph (p14), as in
every AppState-using suite.

Measured FULL holds (p08, `step_started` bind instants), four runs: 01 = 0.384–0.399 s; 02..08 = 0.204–0.236 s
(e.g. last run 0.399 / 0.204 / 0.220 / 0.221 / 0.221 / 0.222 / 0.219 / 0.220 s). Min 0.204 s ≥ 0.18 s.

Failures found and fixed: (1) emergence origin (see §1); (2) p12 lambda reassigned a captured local (GDScript copies
captures) → append; (3) p12 flaked once because a 900-frame loop cap (~1.3 s at fast headless frames) expired before the
2.25 s serialized routing finished → all loop caps in the new suite are time-based (20 s); (4) the Standard c01 scope
clause and harness pin, as listed.

## 4. Visual self-check (not approval)

Inspected Premium sheets (checkerboard/gray/white), runtime 01..09 sheet, `03_opening_late_cards_emerging`,
`06_mixed_pre_route` (1080×1920), `V_destinations_1536x2048`, the timeline: gold pack identity intact, nine distinct beats,
no matte; cards rise from the five backs; 3 + 2 block readable, centred, no overlap, card 0 (Prism Bot EPIC) top-left;
destinations clear; serialized routing reads as five separate flights.

## 5. Scope / blockers

- Not started: SB-M43-066 (commit/atomic/reopen), plugin work. Root `TASKS.md` untouched. No tracker created.
- Blockers: none. SB-M43-065 left open for ChatGPT technical audit + OWNER VISUAL PASS
  (`res://tests/tools/owner_review/premium_pack_owner_review.tscn`).

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C007_V01_PREMIUM_PACK_AUDIT`
