# M43-C005-C006 — Standard Frame Alpha + Cadence Matrix V03 (SB-M43-064)

Date: 2026-10-04 · Implementer: Claude · Status: AWAITING_AUDIT (no verdict claimed) · fresh owner visual gate still required

Machine record: `STANDARD_FRAME_ALPHA_MANIFEST_V03.json` (per-frame before/after hashes + full metrics).

## 1. Method (deterministic, pixel-preserving)

`tools/clean_m43_c005_standard_frame_alpha_v03.py` (params in the manifest):

- The accepted look of these frames is what they show **over black** (the generator flattened them onto a black canvas).
  Each pixel keeps that over-black colour `P = rgb·a`; only alpha is re-derived.
- **Solid objects stay opaque**: object mask = hole-filled closing of the bright region (max-channel ≥ 200, closing r=3), islands < 1500 px
  dropped, +3 px rim; alpha ramps in over 40 px so bright glow caught by the mask fades into light. Inside the mask, dark
  art details (max-channel < 120 and 20 below their 9×9 neighbourhood: outlines, crimp lines, visor) are always opaque.
  The card backs of 06–09 are opaque inside their **exact C002 placement silhouettes** (manifest `card_overlays` +
  the C002 `card_layer` function in `tools/rebuild_m43_c005_card_emergence.py`).
- **Everything else is light** (glow, rays, sparkles, matte): alpha = its own brightness `max(P)/255`, colour `P/alpha`,
  soft noise floor (0 below 6, full from 30), and faded to 0 over 48 px approaching the old flattened-canvas edge so no
  straight cut of light remains.
- No global dark threshold; nothing redrawn, moved, recoloured, added or removed; 1024×1536 RGBA kept.
- A frame the validator already finds clean is copied byte-for-byte (01–04).

Over-black difference vs historical (05–09): ≤ 10.84/255 everywhere except the 48 px edge-fade band (≤ 54.6/255, where the
straight cut was softened). Bright-art (≥150) centroid shift ≤ 0.332 px → registration preserved.

Validator `tools/validate_m43_c005_standard_frame_alpha_v03.py` (decoded pixels only): border band (24 px) fully transparent;
largest dark visible component (α ≥ 16, max-channel < 40) ≤ 25,000 px; dark semi-transparent wash ≤ 8,000 px; visible
region covers ≤ 55 % of any side of its own bbox; no run > 64 px of α ≥ 24 along any bbox side (straight cut).

## 2. Per-frame before / after

| # | action | sha256 before (historical C002) | sha256 after (V03 candidate = shipping) | bytes after |
|---|---|---|---|---:|
| 01 | unchanged (already clean) | `ae31881ea692af695125d539832b48a5d76ef77672a22864dcc784c1d35eceea` | `ae31881ea692af695125d539832b48a5d76ef77672a22864dcc784c1d35eceea` | 691,154 |
| 02 | unchanged (already clean) | `075e917c6e82a9bc555650df57b187d2eacc34b74e0fc504a1ff76c708f66b32` | `075e917c6e82a9bc555650df57b187d2eacc34b74e0fc504a1ff76c708f66b32` | 1,261,936 |
| 03 | unchanged (already clean) | `086a7e7e6deb325c573e6fdd362c1f0d801b1acb3fb8f04786b74e4ad3cfc2a4` | `086a7e7e6deb325c573e6fdd362c1f0d801b1acb3fb8f04786b74e4ad3cfc2a4` | 1,392,316 |
| 04 | unchanged (already clean) | `81183737951d9d17ef7e50ca95f9e1f776d35d733af66eb1a79779db0295e160` | `81183737951d9d17ef7e50ca95f9e1f776d35d733af66eb1a79779db0295e160` | 745,974 |
| 05 | alpha re-derived | `0d47eeb9b4ac3f7483d64f5298bd06c8eb286a8c0df4968fba8c6f5c43674b63` | `9071350f5f52e2c0d91c593878f8891d22bd419db6765d7ccea1111c604da442` | 1,733,853 |
| 06 | alpha re-derived | `2d12e040123598072046d5b2b6049599d31334fddea444317a39adcd85eff189` | `c24cae359ee45d90b3ae2cb6b722735466952441a1729933446695a98600f455` | 1,501,124 |
| 07 | alpha re-derived | `6b20fa33e72d09319cf1aea6adc0ebf8fa51feb7787ff072e9a0e6d7adf1c1ef` | `4376ebcaad8dbe67725d49d002455aa33525de48dd7a22a875c3f3cb406bfa8b` | 1,785,425 |
| 08 | alpha re-derived | `a29d9ed9c7727887b7a76ae972ddfb61b18f673f6c30c63b1ec0cf42a70b05af` | `70d5a3ca3863f11579db38f0fd57730af16e7360753e2f3e8e618f75489c97cd` | 1,527,623 |
| 09 | alpha re-derived | `561753dc9ade575874685d4cc07b8bd8bbd4f2e984c28ee228a76248ef385402` | `a6d9cb74eb10acc1aed6498dc0140e87fa26cad747462a87f592e78dab922b81` | 1,846,374 |

Historical files under `assets/ui/candidates/m43_c005/pack_opening/standard/` unchanged (== `PACK_ASSET_MANIFEST_V01`).
V03 candidates under `assets/ui/candidates/m43_c005/pack_opening/standard_v03_alpha_clean/` are byte-identical to the
shipping files under `assets/ui/final/rewards/pack_opening/standard/` (`cmp` + manifest builder asserts).

| # | before: largest dark comp. / dark wash / max bbox-side fill / max edge-cut run / failures | after: same / border px | alpha bbox before → after | transparent px before → after | opaque px before → after | over-black max diff | bright-art centroid shift |
|---|---|---|---|---|---|---:|---:|
| 01 | 10197 / 0 / 0.03 / 12 / none | 10197 / 0 / 0.03 / 12 / 0 | [266,499,779,1256] → same | 1241762 → 1241762 | 1280 → 1280 | 0.00 | 0.000 px |
| 02 | 10654 / 0 / 0.01 / 4 / none | 10654 / 0 / 0.01 / 4 / 0 | [220,420,790,1258] → same | 1171455 → 1171455 | 0 → 0 | 0.00 | 0.000 px |
| 03 | 11319 / 0 / 0.02 / 6 / none | 11319 / 0 / 0.02 / 6 / 0 | [166,239,857,1227] → same | 1041316 → 1041316 | 0 → 0 | 0.00 | 0.000 px |
| 04 | 10197 / 0 / 0.03 / 12 / none | 10197 / 0 / 0.03 / 12 / 0 | [266,499,779,1256] → same | 1238704 → 1238704 | 35029 → 35029 | 0.00 | 0.000 px |
| 05 | 300769 / 25508 / 1.00 / 1440 / large_dark_component, dark_wash, rectangular_boundary, straight_edge_cut | 11851 / 0 / 0.06 / 0 / 0 | [48,48,975,1487] → [55,64,968,1377] | 236544 → 476688 | 0 → 370334 | 54.56 (band) / 10.84 | 0.332 px |
| 06 | 62015 / 92471 / 0.22 / 222 / large_dark_component, dark_wash, straight_edge_cut | 11851 / 0 / 0.06 / 1 / 0 | [48,48,975,1380] → [55,92,968,1317] | 479820 → 662752 | 31058 → 386966 | 54.56 (band) / 10.73 | 0.238 px |
| 07 | 300769 / 25508 / 1.00 / 1440 / large_dark_component, dark_wash, rectangular_boundary, straight_edge_cut | 11851 / 0 / 0.06 / 0 / 0 | [48,48,975,1487] → [55,63,968,1377] | 236544 → 476670 | 33690 → 376696 | 54.56 (band) / 10.84 | 0.226 px |
| 08 | 62015 / 92471 / 0.22 / 222 / large_dark_component, dark_wash, straight_edge_cut | 11851 / 0 / 0.06 / 1 / 0 | [48,48,975,1380] → [55,92,968,1317] | 479820 → 662752 | 86180 → 391135 | 54.56 (band) / 10.73 | 0.231 px |
| 09 | 300769 / 25508 / 1.00 / 1440 / large_dark_component, dark_wash, rectangular_boundary, straight_edge_cut | 11851 / 0 / 0.06 / 0 / 0 | [48,48,975,1487] → [55,63,968,1377] | 236544 → 476670 | 122015 → 350798 | 54.56 (band) / 10.84 | 0.193 px |

All corner alphas after = 0. Largest remaining dark component (≈10–12k px) is the robot visor inside the pack.

## 3. Validator sensitivity (`evidence/v03/validator_sensitivity_v03.json`)

33/33 as expected: 9 clean frames pass; for every frame an inserted **opaque black rectangle** and an inserted
**semi-transparent dark rectangle** fail; historical 05/06/07/08/09 fail (05/07/09: large dark component + dark wash +
rectangular boundary + straight cut; 06/08: large dark component + dark wash + straight cut). The first-pass V03 output
(before the edge fade) also failed the straight-cut check (05/06/09 runs of 126–195 px) — that is why the fade was added.

## 4. Compositing QA (evidence only)

`evidence/v03/STANDARD_V03_CLEAN_{checkerboard,white,gray,black}_01_09.png` — 3×3, labels outside the images.
`evidence/v03/STANDARD_HISTORICAL_BEFORE_{…}_01_09.png` — same sheets for the historical bytes (matte visible on white/gray/checker).
Checkerboard and gray inspected frame by frame (see log §4).

## 5. FULL cadence

`scripts/ui/ceremony/standard_pack_ceremony.gd`: `FRAME_HOLD = [0, 0.40, 0.22 ×7]` (frame 01 rests 0.40 s; 02–08 0.22 s each),
`MIN_FULL_HOLD = 0.18`, `FRAME09_HOLD_S = 0.30` before the cards rise. One `PackFrame` TextureRect; no strip; Reduced unchanged
(frame 09 only, both taps). No other ceremony change.

Measured (focused suite v13, bind instants from the sequencer's `step_started`; two runs):

| beat | run 1 bind / hold | run 2 bind / hold |
|---|---|---|
| 01 | 0.000 / 0.409 s | 0.000 / 0.400 s |
| 02 | 0.409 / 0.222 s | 0.400 / 0.206 s |
| 03 | 0.630 / 0.206 s | 0.606 / 0.220 s |
| 04 | 0.836 / 0.222 s | 0.826 / 0.219 s |
| 05 | 1.058 / 0.223 s | 1.046 / 0.222 s |
| 06 | 1.281 / 0.222 s | 1.268 / 0.219 s |
| 07 | 1.502 / 0.220 s | 1.487 / 0.219 s |
| 08 | 1.722 / 0.218 s | 1.706 / 0.219 s |
| 09 | 1.940 s (bound once) | 1.925 s (bound once) |

Frame history `[1,2,3,4,5,6,7,8,9]`; min hold 0.206 s ≥ 0.18 s.

Runtime evidence (rendering driver, real Tap 1): `evidence/v03/F01..F09_runtime_frame_*.png` (one capture per bound frame) and
`evidence/v03/STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png`; bound textures printed in order `01=frame_01_closed.png … 09=frame_09_final_reveal.png`.

## 6. Test matrix (focused suite, 21 cases)

| Prompt §12 | Case(s) | Mutation caught |
|---|---|---|
| 1 V03 promoted bytes | c01 (shipping == V03 candidate == V03 manifest; historical == C002; 01–04 unchanged) | AM1 dirty 07 restored |
| 2 historical matte fails | Python validator sensitivity; v14 (historical 05 rejected) | — |
| 3 compositing QA | sheets + manual inspection (log §4) | — |
| 4 no dark matte | Python validator on finals (9/9 CLEAN); v14 rendered check | AM1 |
| 5 registration | manifest centroid shift ≤ 0.332 px; alpha bbox inside old canvas | — |
| 6 exact order | v03, v13 | CM2 skip 05, CM3 repeat 04 |
| 7 holds ≥ 0.18 s | v13 measured + configured | CM1 short 03 |
| 8 no skip/repeat | v13 | CM2, CM3 |
| 9 one frame node | v03, v13 | — |
| 10 V02 flow | v01–v12 unchanged and passing | V02 mutations (V02 log) |
| 11 Reduced | v12 (frame 09 only, both gates) | — |
| 12 no authority | v09, c12 | — |
| 13 lifecycle | v11 | — |
