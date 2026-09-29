# M28-C002-C004 — CLAUDE LOG V02 (same-colour base remediation)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V02.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V02.md` · Matrix: `REMEDIATION_MATRIX_V02.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- `main`, fast-forwarded 6 commits (`--ff-only`) from V01 `f85e698` to the ChatGPT audit/prompt commits; no conflict.
- Root `TASKS.md` read only, **not edited**. Local `project.godot` drift and untracked owner files preserved, not committed.

## Change

Only the owner-rejected point: the occupied `ColorBatchTile` lower base body/fill is now exactly the same canonical Palette v3 batch colour as the top face (`base bg_color == face bg_color == palette colour`). The old fixed `BASE_COLOR` / `BASE_EDGE` constants are removed; the 3 px bottom edge is `colour.darkened(0.32)` (same rule as the face rim; a depth edge, not the body). Height, shadow, highlight, count centring / sizing, ACTIVE / WAITING, preview, EMPTY, slot geometry and supply input were not touched.

Files: `scripts/ui/color_batch_tile.gd` (6 lines), `tests/m28_c002_c004_tile_visual.gd` (+ case `c17`), evidence, this log and `REMEDIATION_MATRIX_V02.md`.

## Tests

- **Focused C004: PASS, 17/17** (c01–c16 unchanged + new `c17_base_body_equals_face_colour`). Mutation check: reverting to the white base fails 5 `c17` assertions.
- **Full regression** (Godot 4.7.2 headless, 8-way, 115 suites, `_m55_diag_tmp` excluded): **112 exit 0, 3 non-zero:**
  - `m21_v08_corridor_validation`, `m21_v09_direct_evidence_reconciliation`: the documented pre-existing baseline (unchanged for three cycles).
  - `m52_owner_supply_plans`: exit 124 = my 900 s runner timeout under 8-way CPU load (it is a ~10-minute solver suite; it does not touch tile presentation). **Rerun alone: PASS.** Reported as a load timeout, not hidden.
- Root `run_tests.gd`: `Total checks: 5323`, all pass. M28 (C001/C002/C003/R01 suites), M29 (input, presentation identity, slot display sync), M39 (+1 Slot, V03/V04 integration), M43 (C002 popup/modal), M52 (R01, R02), M55 (long session PASS) all PASS.
- `SCRIPT ERROR` only in the known `m20_v04/v05/v07/v08` baseline. `git diff --check`: clean (CRLF advisories only).

## Evidence (`evidence/v02/`)

- `c004_tile_gallery_palette_states_sizes.png`: all 16 Palette v3 colours, face + base same colour; light (C03, C06, C12, C13, C15) and dark (C08, C14, C16) examples; normal / ACTIVE / WAITING / EMPTY / supply front / supply preview; 48–120 px sizes with a 3-digit count.
- `c004_5slot_5col_phone_1080x2160.png` (5-slot + 5×3 supply), `c004_6slot_4col_phone_1080x2160.png` (6-slot + 4-col supply), `c004_5slot_3col_phone_1080x2160.png`, `c004_5slot_5col_narrow_720x1600.png`.
- `c004_5slot_5col_phone_closeup_slot{0_7,1_42,2_120}.png` (1/2/3-digit close-ups, face-centre overlay).
- `measurements.txt`: layout delta 0.00 px, rendered-ink delta identical to V01.
- V01 evidence (`evidence/*.png`) is kept as the before state.

## Owner recheck required

Only the corrected base colour: does the lower base now read as the same batch colour as the face (the thin darker bottom edge is intentional depth). On very dark faces (C16 black) the base and its edge are near-black, which follows from "exactly the batch colour".

## Reproduce

```bash
godot --headless --path . -s res://tests/m28_c002_c004_tile_visual.gd
godot --path . -s res://tests/tools/m28_c004_tile_evidence.gd -- <out_dir>
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C004 SAME-COLOR BASE REMEDIATION V02`
