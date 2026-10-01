# M42-C003 V02 asset constraint report

## Authority and source integrity

- Exact archive: `C:\Users\sekip\Desktop\Home_Main_Hero_Assets.zip`.
- Archive SHA-256: `f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458` (matches V02).
- All 63 PNG files and dimensions now match `OWNER_SOURCE_ASSET_MANIFEST_V02.md`.
- The exact-hash archive exposed one manifest typo: `bow_12.png` had `d05a4e...` but its digest in the pinned archive is `d05a4a...`. The one-character manifest correction is recorded in the diff and implementation log. The archive bytes were not changed.
- HOME-026 SHA-256 remains `fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18`.

## Deterministic measurement method

The committed preparation tool measures a dark visor envelope inside the central upper alpha bounds, fits one uniform scale per source family, and limits that scale so retained alpha and the registered root remain inside the 1158x1358 output. `HOME-026` visor envelope is approximately 723 px. Each candidate is registered to root/soles `(592, 1318)`. A deterministic descending 0.05-scale sweep then finds the largest family scale meeting its V02 blocking helper/keep-out zones. Detailed source and per-frame values are in `source_verification.json`, `normalization_measurements.json`, and `safe_scale_analysis.json`.

## Measured fit versus V02 requirements

| Runtime family | Source family | Largest canvas-contained fit scale | Visor width versus HOME-026 | Largest scale passing blocking zones | Visor width at that scale |
|---|---|---:|---:|---:|---:|
| Wave | Wave | 2.9737 | 70.3% | 2.67 | 63.2% |
| Bow | Bow | 2.6588 | 60.3% | 2.36 | 53.5% |
| Turn / Look | Full Turn | 3.2945 | 62.9% | 2.89 | 55.2% |
| Full Turn | Full Turn | 3.2945 | 62.9% | 3.29 | 62.8% |

The 85% flag in `safe_scale_analysis.json` is an implementation diagnostic used to call out substantial measured identity/scale loss; it is not an owner-authored tolerance. Even at the largest canvas-contained fit, all four source-family visor envelopes are 29.7–39.7% smaller than HOME-026. The V02 blocking zones force the first three runtime families still smaller. At the canvas-contained fit, K3 overlaps are 3,316 Wave pixels, 2,268 Bow pixels, 3,106 Turn/Look pixels, and 3,141 Full Turn pixels (alpha >128). Full Turn K3/K4 values are explicitly warnings per V02 and are reported frame-by-frame in `full_turn_helper_overlap.md`.

Using the V02-safe scales would remove about 37–47% of the HOME-026 visor width. Using the identity-fit scales violates K3 for Wave, Bow, and Turn/Look. Neither choice meets both the V02 scale/identity priority and its hard K-zone gates. Per-frame shrinking, moving the soles/root, cropping approved art, or repainting frames would violate the prompt. Therefore the prompt's permitted disposition is `BLOCKED_V02_ASSET_CONSTRAINT_CONFLICT`.

## Work stopped at the blocking gate

- Exact raw source bytes are staged under `assets/ui/generated/characters/home_animation/source_v02/`.
- 14/15/17/17 production candidate PNGs, mappings, measurements, contact sheets, and HOME-026 transition strips were generated deterministically for review. They remain generated candidates and are not runtime dependencies.
- No candidate was promoted to `assets/ui/final/`; HOME-026 and the existing HOME manifest were not changed.
- Runtime integration and runtime tests were not started because the mandatory source art cannot satisfy both fit and blocking safe zones. The complete aggregate suite, four viewport captures, Reduced Effects runtime capture, 20x lifecycle check, and 12 fps runtime videos were not run. No runtime evidence is claimed.
