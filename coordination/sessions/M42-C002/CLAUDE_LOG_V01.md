# M42-C002 — CLAUDE LOG V01 — Home Scrubby Hero Scale + Placement Lock

Date: 2026-09-30
Task: `SB-M42-034`
Prompt: `coordination/sessions/M42-C002/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M42-C002/CHATGPT_AUDIT_CRITERIA_V01.md`
Owner authority: `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V01.md`
Engine: Godot 4.7.2.stable.official.ed1daf0bf
Status: `AWAITING_CHATGPT_AUDIT` (+ OWNER visual gate)

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`, upstream `origin/main`.
- Local was behind 4 at `1cd735a`; fast-forwarded to `35f0a7e` (incoming: `TASKS.md` + M39/M42 coordination docs only).
- Pre-existing local owner work preserved and NOT committed: `project.godot` drift, untracked assets / `.import` / `.uid` files, `tests/_m55_diag_tmp.gd`.
- Root `TASKS.md` not edited.

## Production change (one constant)

`scripts/ui/home/home_screen.gd:99`

```
- const SCRUBBY_SCALE := 1.24
+ const SCRUBBY_SCALE := 1.612
```

(+ comment naming the M42-C002 owner lock.) Nothing else in production changed:

- world transform, `data/config/home_worlds_v1.json` (940x1672 HOME-121, feet anchor (470,1240), safe box (305,620,330,620)), background, HUD/Play/Gift/BottomNav/shortcut layout, helper-bot panel avoidance — unchanged;
- existing `get_scrubby_canonical()` already scales about the visible soles (k = k_v04 x SCRUBBY_SCALE; origin chosen so visible centre X = 470 and soles line y 1318 of the texture = 1240), so the soles stay on the platform contact with no new code;
- no per-viewport branch, lookup table or scale-down; 1.612 everywhere;
- **HeroFocusShade unchanged**: `Rect2(260,600,420,690)` still contains the enlarged torso centre (470, 935.2); widening it would reach the helper-bot rects (V06 rule), so no adjustment was needed;
- same HOME-026 texture (sha256 `fc30b992…` = manifest pin), still the separate runtime `Art_scrubby` under `Background/Layer_characters`, MOUSE_FILTER_IGNORE; no face/brush overlays, no animation component.

## Placement analysis — why the canonical anchor is kept

Canonical 1.612 visible rect: canvas (204.0, 622.8, 532.0, 624.7) (1.24 was (265.4, 670.9, 409.2, 480.5)).

- Baked sign (230,405,480,140; bottom 545): clear (hero top 622.8).
- Helper bots: in the bot rows (canvas y 1010..1260) the hero's opaque span is 443.5 canvas px, the gap between the two bot rects is 440 px (250..690) — **no horizontal re-anchor can clear both**, and vertical moves would break the soles/platform contact. Pixel-level: right bot rect gets 0 hero pixels; in the left bot rect only the brush bristles enter its right strip (canvas x 204..250, over the bucket/water spray — not the bot body). Placement kept canonical (feet (470,1240)); reported for owner question 4.
- Functional UI: 0 opaque hero pixels inside every functional control at every viewport (below). At 1080x2160 the hero's **rectangular bbox corners** intersect COLLECTION and DAILY hit rects over transparent texels only (pixel clearance 116.3 / 54.2 px). Panels could not move to clear the bbox (they already sit at the 26 px edge margin; `PANEL_TOP` is fixed to clear the Gift Meter), and the scale may not shrink — disclosed, not hidden.

## Four-viewport geometry (zero insets; full table `evidence/measurement_report.md`)

| Viewport | World scale / offset | Old 1.24 visible (screen) | New 1.612 visible (screen) | Soles | Platform contact | Error |
|---|---|---|---|---|---|---|
| 1080x2160 | 1.23544 / (-40.66, -74.65) | (287.2, 870.8, 505.5, 593.7) | (211.4, 694.8, 657.2, 771.8) | (540.00, 1457.29) | (540.00, 1457.29) | 0.0001 px |
| 1080x1920 | 1.04725 / (47.79, -53.53) | (325.7, 747.9, 428.5, 503.2) | (261.5, 598.7, 557.1, 654.2) | (540.00, 1245.05) | (540.00, 1245.06) | 0.0002 px |
| 1290x2796 | 1.56459 / (-90.36, 0.00) | (324.9, 1197.3, 640.2, 751.8) | (228.8, 974.5, 832.3, 977.4) | (645.00, 1940.10) | (645.00, 1940.10) | 0.0001 px |
| 1536x2048 | 1.14269 / (230.94, -56.79) | (534.2, 817.7, 467.6, 549.1) | (464.1, 654.9, 607.9, 713.8) | (768.00, 1360.15) | (768.00, 1360.15) | 0.0001 px |

On-screen visible height ratio new/old = 1.3000 at all four. Hero fully inside the visible Home world clip at all four.

## Collision matrix (opaque hero px inside rect / bbox)

| Control | 1080x2160 | 1080x1920 | 1290x2796 | 1536x2048 |
|---|---|---|---|---|
| TopCurrencyHUD | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| GiftMeter | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| PlayButton | 0 / clear (92.7 px) | 0 / clear (90.3) | 0 / clear | 0 / clear (90.5) |
| BottomNav | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| SHOP | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| COLLECTION | 0 / **bbox corner** (116.3 px) | 0 / clear (110.3) | 0 / clear | 0 / clear |
| TASKS | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| DAILY | 0 / **bbox corner** (54.2 px) | 0 / clear (26.6) | 0 / clear | 0 / clear |
| Baked sign | 0 / clear | 0 / clear | 0 / clear | 0 / clear |
| Left helper bot | 7945 tex px, brush strip only | same | same | same |
| Right helper bot | 0 | 0 | 0 | 0 |
| Panel over a bot | none | none | none | none |

(parenthesised = smallest pixel clearance from any opaque hero pixel to the rect.) Real pointer events at every viewport: every functional control (Play, 4 panels, Settings, Home nav, both HUD `+`) is the topmost hit at its centre; Play / DAILY / Settings fire; disabled SHOP/COLLECTION/TASKS stay inert (V04 design, same at 1.24); economy snapshot unchanged.

## Tests

New `tests/m42_c002_scrubby_scale.gd` (7 cases, 107 checks): `exact_scale`, `soles_registration`, `ui_collision_matrix` (pixel-level via the HOME-026 alpha), `sign_helper`, `responsive_relayout` (one live Home resized through all four sizes and back: same hero node + texture object, 1 hero / 1 shade, identical rects on return, `resized` connections / timers / tweens constant), `ui_truth` (pushed pointer events), `identity_scope`.

Legacy assertions that pinned the superseded 1.24 geometry were updated to the owner lock (no other change):

- `tests/m42_home_v04.gd`: bristles-below-soles bound now 16 texels x k (was a fixed 7 px, 7.5 px at 1.612); bot bbox check → bounded intrusion (<= 47 canvas px each side); panel-vs-Scrubby check now pixel-level (a panel must never cover an opaque hero pixel) instead of bbox.
- `tests/m42_home_v05.gd`, `tests/m42_home_v06.gd`: scale 1.612; bot bbox check → bounded intrusion.
- `tests/m42_home_v07_safe_area.gd`: constant pin 1.612.

First regression run: `m42_home_v04` 3 FAIL + `m42_home_v05` 1 FAIL — all the 1.24-era bbox assertions above; fixed as listed, then the full batch was rerun from scratch on the final files.

## Evidence (`coordination/sessions/M42-C002/evidence/`)

Rendered by new `tests/tools/m42_c002_scale_evidence.gd` (real Home scene, current background, same representative state as `tests/tools/home_snapshot.gd`):

- `home_scrubby_1612_1080x2160.png`, `home_scrubby_1612_1080x1920.png`, `home_scrubby_1612_1290x2796.png`, `home_scrubby_1612_1536x2048.png`;
- `home_scrubby_before_124_vs_after_1612_1080x2160.png` (left 1.24, right 1.612) + `home_scrubby_124_before_1080x2160.png`;
- `measurement_report.md`.

The "before" frame places the same hero node at the 1.24 canonical geometry; it is **pixel-identical** (PIL difference bbox `None`) to `home_snapshot.gd` rendered at the pre-change production code, and the 1080x2160 after frame is pixel-identical to `home_snapshot.gd` on the new code.

## Regression (all exit 0, 0 FAIL)

| Suite | Result |
|---|---|
| `m42_c002_scrubby_scale` | m42_c002_scrubby_scale: 7/7 cases, 0 failures |
| `m42_home` | M42 home evidence: PASS |
| `m42_home_v04` | m42_home_v04: 18/18 cases, 0 failures |
| `m42_home_v05` | m42_home_v05: 13/13 cases, 0 failures |
| `m42_home_v06` | m42_home_v06: 13/13 cases, 0 failures |
| `m42_home_v07_safe_area` | m42_home_v07_safe_area: 9/9 cases, 0 failures |
| `m42_home_composition` | m42_home_composition: 9/9 cases, 0 failures |
| `m42_navigation` | M42 navigation evidence: PASS |
| `m42_opening` | M42 opening evidence: PASS |
| `m42_assets` | M42 assets evidence: PASS |
| `m40_save_system` | M40 save system evidence: PASS |
| `m40_v02_safety` | M40 V02 safety evidence: PASS |
| `m40_v03_canonical` | M40 V03 canonical evidence: PASS |
| `m40_v04_bootstrap` | M40 V04 bootstrap evidence: PASS |
| `m43_c001a_results_foundation` | M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail) |
| `m43_c001b_won_results_visual` | M43-C001B WON results visual evidence: PASS (11/11 cases, 0 fail) |
| `m43_c002_c001_popup_modal_pause` | M43-C002-C001 popup / modal / Pause foundation evidence: PASS (23/23 cases, 0 fail) |
| `m43_c003_c001_acquisition` | M43-C003-C001 acquisition evidence: PASS (34/34 cases, 0 fail) |
| `m28_c002_c003_r01_remediation` | M28-C002-C003-R01 five-finding remediation: PASS (24/24 cases, 0 fail) |
| `m28_c002_c003_final_gate` | M28-C002-C003 final popup-inclusive gate: PASS (22/22 cases, 0 fail) |
| `run_tests` | RESULT: ALL PASS |

Root `tests/run_tests.gd`: 5323 checks, 0 failures, `RESULT: ALL PASS`. Full list: `evidence/regression_summary.txt`.

`git diff --check` clean.

## Owner gate

Not self-closed. Owner questions: (1) +30% enlargement, (2) platform planting, (3) four-viewport composition, (4) UI / helper-bot relationship — notably the brush over the left helper's bucket and the waving hand near DAILY (26.6 px at 1080x1920). SB-M42-035 animation not started.

## Handoff

`AWAITING_CHATGPT_AUDIT / M42-C002 HOME SCRUBBY SCALE LOCK V01`
