# M43-C005-C006 — CLAUDE LOG V03 — Standard Frame Alpha Cleanup + 01→09 Cadence

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-064
Status: **AWAITING_AUDIT** (E1/E2 only; no verdict claimed) · fresh owner visual gate still required

## Inputs read

- V03 prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V03.md
- V03 criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_CRITERIA_V03.md
- V02 prompt / criteria / audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V02.md, `CLAUDE_LOG_V02.md`
- `coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`, `FINAL_OWNER_ACCEPTANCE_V01.md`, `CODEX_LOG_V03.md`, `tools/remediate_m43_c005_pack_assets_v04.py`, `tools/rebuild_m43_c005_card_emergence.py`
- `CLAUDE.md`, root `TASKS.md` (read only, **not edited**), `coordination/README.md`, `coordination/AUDIT_POLICY.md`
- current shipping frames, `standard_pack_ceremony.gd`, focused suite, evidence tool

Learnings applied: rendered pixels are the authority (validator never trusts manifest claims); "has some alpha" ≠ clean
(dark-component / wash / box / straight-cut checks); sensitivity for every gate (injected rectangles, historical files,
cadence/asset mutations); never redraw owner-approved art (alpha-only re-derivation; over-black look preserved).

## Sync (first action)

`git fetch origin` → local `main` == `origin/main` (c108ebc, which already contained the V03 prompt/criteria). Nothing to
merge. Owner/local work preserved, not committed: `M project.godot`, `M scenes/app/main.tscn` (editor re-save), untracked
`.mcp.json`, `addons/`, `*.import`, `*.uid`, owner art/evidence.

Governance note: the owner-review harness V01 was implemented and pushed in the **previous** pass (c9a4db3, merged in
c108ebc) before the V03 prompt reached me; V03 marks it paused. In this pass it was not run or modified. Its smoke test
pins the V02 ceremony sha256 (h03), so it will intentionally flag this V03 timing change until the harness is re-baselined
against the cleaned V03 state.

## 1. Diagnosis (rendered pixels, all nine)

- 01–04: clean (transparent outside the pack/sparkles; largest dark component = robot visor ≈10–11k px).
- 05 / 07 / 09: near-black matte rectangle 928×1440 at α ≈ 237–251 (largest dark component 300,769 px; bbox sides 100 % filled).
- 06 / 08: not clean either — C002 V04 had made only exterior-connected *dark* pixels transparent with a feather, leaving a
  semi-transparent dark wash (92,471 px) around the pack.
- No clean layered source exists for 05–09 (C002 bases were generated on a flattened black canvas).

## 2. Changes

| File | Change |
|---|---|
| `tools/clean_m43_c005_standard_frame_alpha_v03.py` | new deterministic cleanup (method in matrix §1) |
| `tools/validate_m43_c005_standard_frame_alpha_v03.py` | new rendered-pixel validator + `--sensitivity` mode |
| `tools/render_m43_c005_standard_frame_sheets_v03.py` | new 3×3 checkerboard/white/gray/black evidence sheets |
| `tools/build_m43_c005_standard_frame_manifest_v03.py` | new manifest builder (asserts historical == C002, candidate == final) |
| `assets/ui/candidates/m43_c005/pack_opening/standard_v03_alpha_clean/frame_01..09` | new V03 clean candidate family |
| `assets/ui/final/rewards/pack_opening/standard/frame_05..09` | promoted V03 bytes (01–04 unchanged, byte-identical) |
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | timing only: `FRAME_HOLD` 02–08 0.14 → 0.22 s, `MIN_FULL_HOLD = 0.18`, `FRAME09_HOLD_S = 0.30` (was 0.14) |
| `tests/m43_c005_c006_standard_pack_presentation.gd` | c01 → V03 hash authority (+ historical unchanged); v03 beat→file check uses V03 manifest; new v13 cadence, v14 rendered alpha (19 → 21 cases) |
| `tests/tools/standard_pack_snapshot.gd` | + one real capture per bound frame 01..09 after Tap 1 + `STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png` |
| `assets/ui/VISUAL_ASSET_INDEX.md` | 05–09 bytes/authority + V03 note |
| `STANDARD_FRAME_ALPHA_MATRIX_V03.md`, `STANDARD_FRAME_ALPHA_MANIFEST_V03.json`, `evidence/v03/*` | evidence |

Historical candidates under `assets/ui/candidates/m43_c005/pack_opening/standard/` untouched. Not changed: card truth,
destinations, routing, gates, lifecycle, Reduced semantics, model/catalog, sequencer, root `TASKS.md`. No SB-M43-065 work.

### Iterations (truthful record)

1. First mask (bright ≥150, 3 px feather) removed the box but turned the bright glow into solid opaque blobs (yellow burst,
   cyan side glow) → rejected on the checkerboard sheet.
2. Bright ≥200 + 40 px inward ramp → glow correct, but dark crimp lines near the mask edge went translucent (min α 32) →
   added the dark-detail guard (37k dark art px inside objects: 5 below α 250).
3. Card backs in 07–09 were translucent (uniform navy inside the ramp) → protected by their exact C002 placement silhouettes
   (0 card px below α 255).
4. Glow was still chopped by a straight line at the old canvas edge (α up to 44 along 126–195 px) → added a 48 px edge fade
   and a `straight_edge_cut` validator check (which fails that first-pass output). Final bytes = iteration 4.

## 3. Validation

| # | Command | Expected / failure condition | Actual |
|---|---|---|---|
| A1 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/candidates/m43_c005/pack_opening/standard` | 01–04 CLEAN, 05–09 DIRTY | as expected (05/07/09: dark comp + wash + box + cut; 06/08: dark comp + wash + cut) |
| A2 | `python tools/clean_m43_c005_standard_frame_alpha_v03.py <historical> <v03 candidate> evidence/v03/cleanup_metrics_v03.json` | 9/9 clean after | **9/9 clean**; 01–04 copied byte-for-byte |
| A3 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/final/rewards/pack_opening/standard` | 9 CLEAN, rc 0 | **9/9 CLEAN** |
| A4 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py --sensitivity <v03> <historical> evidence/v03/validator_sensitivity_v03.json` | 33 expectations | **SENSITIVITY PASS 33/33** |
| A5 | `python tools/render_m43_c005_standard_frame_sheets_v03.py …` (V03 + historical) | 8 sheets | written |
| A6 | `python tools/build_m43_c005_standard_frame_manifest_v03.py` | provenance asserts hold | written; historical == C002 sha, candidate == final per frame |
| T1 | `godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd` (×2) | 21/21 | **PASS 21/21 both runs**, 0 script errors |
| T2 | focused-suite mutations (temporary, restored, `diff -q`/`cmp` RESTORED) | each fails | CM1 frame 03 hold 0.10 s → 2 FAIL (measured hold 0.111 s); CM2 skip 05 → 3 FAIL (history `[1,2,3,4,6,7,8,9]`); CM3 repeat 04 → 3 FAIL (`[1,2,3,4,5,4,7,8,9]`); AM1 historical dirty 07 restored to shipping → 4 FAIL (c01, v03 beat sha, v14 matte). **All detected** (run against the first-pass V03 bytes; the checks are independent of the iteration-4 alpha changes) |
| T3 | `godot --path . -s res://tests/tools/standard_pack_snapshot.gd -- coordination/sessions/M43-C005-C006/evidence/v03` (rendering driver) | 0 REJECTED; runtime frames exactly 01..09 | **0 REJECTED**; runtime bound textures `01=frame_01_closed.png … 09=frame_09_final_reveal.png`; mixed flow frames `[1..9]`, routes `[[0,collection],[1,exchange],[2,collection]]`, closed `complete`; Reduced `[9]`, same routes |
| T4 | `-s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | PASS | **12/12** |
| T5 | M43 `c001a`, `c001b`, `c001r_c001`, `c002_c001`, `c003_c001`, `c004_c001`, `c005_c001` | PASS | **11/11, 11/11, 40/40, 23/23, 34/34, 40/40, 17/17** |
| T6 | root `-s res://tests/run_tests.gd` | ALL PASS | **5,323 checks, ALL PASS**, 0 script errors |
| T7 | `git diff --check` | clean | **clean** |

T1/T3–T7 were run on the final (iteration-4) bytes after promotion + `--import`. An earlier full run on the first-pass
bytes was also green; it is superseded.

### FULL cadence (T1, sequencer `step_started` bind instants)

| beat | run 1 hold | run 2 hold |
|---|---|---|
| 01 | 0.409 s | 0.400 s |
| 02 | 0.222 s | 0.206 s |
| 03 | 0.206 s | 0.220 s |
| 04 | 0.222 s | 0.219 s |
| 05 | 0.223 s | 0.222 s |
| 06 | 0.222 s | 0.219 s |
| 07 | 0.220 s | 0.219 s |
| 08 | 0.218 s | 0.219 s |
| 09 | bound once (then 0.30 s before cards) | same |

## 4. Manual compositing inspection

Checkerboard and 50 % gray sheets (`STANDARD_V03_CLEAN_*`) inspected frame by frame; white and black also viewed:
01–04 identical to before; 05/07/09 no rectangle — glow reads as translucent light, burst soft, pack/torn flaps/shards solid,
bottom crimp outline solid; 06/08 no wash, card edge/backs solid; 07/09 card backs fully opaque; no straight edge or halo on
any background. Full-resolution crops (pack bottom, torn top, card fan) checked during iteration. Black sheet matches the
historical look. Residual (not a defect): 06/08 glow is a little tighter than 05/07/09 because C002 V04 had already
removed their dim outer glow — restoring it would mean inventing art.

## 5. Blockers / assumptions

- None blocking.
- Alpha re-derivation is a judgement-based object/light separation (documented parameters); intentional dark art inside
  objects is preserved by the detail guard and card silhouettes; the owner should still judge the live result.
- The owner-review harness needs re-baselining (h03 hash pin) before it is used against V03 — out of scope here.
- SB-M43-064 stays open for a fresh OWNER VISUAL PASS on the V03 production state.

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C006_V03_ALPHA_AND_CADENCE_AUDIT`
