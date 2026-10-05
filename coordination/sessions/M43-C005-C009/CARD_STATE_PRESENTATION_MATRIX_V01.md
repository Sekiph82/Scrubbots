# M43-C005-C009 — CARD STATE PRESENTATION MATRIX V01

Canonical task: SB-M43-067 · Implementer evidence only (no verdict claimed) · Status: AWAITING_AUDIT, then OWNER VISUAL PASS

Suite: `tests/m43_c005_c009_card_state_celebration.gd` (case ids `kNN_*`). "N" = source mutation (`CLAUDE_LOG_V01.md` §4).
Evidence: `evidence/v01/*` from `tests/tools/card_state_snapshot.gd` (each capture layout-checked, 0 REJECTED).
Sources: **S** `scripts/ui/ceremony/standard_pack_ceremony.gd` (ceremony + shared `CardView`), **P**
`scripts/ui/ceremony/premium_pack_ceremony.gd` (unchanged; inherits), **T** `scripts/ui/ui_text.gd`.

## Governance

| Criterion | Evidence | Result |
|---|---|---|
| synced non-destructively; owner files preserved | log §Sync | done |
| root TASKS.md untouched; SB-M43-068 not started; no tracker | file list | done |

## Truth source

| Criterion | Source | Test | Result |
|---|---|---|---|
| committed `is_new` / `copies_after` only | S `CardView.count_text`, `extra_copies` | k01 (C008 receipt reopened after live Collection +4 copies → committed text), k24 | PASS · N03 |
| no live Collection query | S has no Collection / economy / transaction identifiers | k24 static | PASS · N03 |
| `extra_copies = copies_after - 1` | S `extra_copies` | k08 | PASS · N01 |
| repeated rows sequential | rows rendered in model order | k12 (fixture + real C008 receipt) | PASS |

## NEW presentation

| Criterion | Source | Test / evidence | Result |
|---|---|---|---|
| NEW explicit; FIRST COPY explicit | S badge + count line, T `PACK_CARD_FIRST_COPY` | k03, k11; S2, P2 | PASS · N02 |
| canonical `card_new_glow.png` (bytes unchanged, no new art) | S `NEW_GLOW` | k04 (path + sha256), k26 | PASS · N07 |
| FULL: one restrained celebration | S `celebration` step + `CardView.celebrate` (4% sine pop, glow swell 1.12 → rest) | k05 (peak scale 1.040, glow peak ≤ 1, once per NEW) | PASS · N09, N11 |
| settles before routing gate | step order: emerge → pack fade → celebration → hold → destinations | k05 (after settle + pack gone, dest hidden), k21 | PASS · N10 |
| no loop / spin / strobe / shake / confetti | S | k05 static | PASS |
| multiple NEW Premium readable | stagger 0.1 s, bounded overlap; glows under all cards | k16, k19; P4, P5 | PASS |
| at most once per CardView; relayout no retrigger | S `_celebrated` once-guard; layout never touches `celebrate` | k05, k20 (5 resizes + reads + Tap 2) | PASS · N04, N11 |

## Reduced Effects

| Criterion | Test / evidence | Result |
|---|---|---|
| NEW / FIRST COPY / counts retained | k06 (Standard + Premium); R2, R4 | PASS |
| no bounce / pulse / flash; static glow | k06 (scale never > 1.0, glow never > rest, no celebration step) | PASS · N05, N06 |
| two-tap semantics unchanged | k06 flow, C006 v12 / C007 Reduced cases | PASS |

## Duplicate presentation

| Criterion | Test / evidence | Result |
|---|---|---|
| DUPLICATE explicit; primary count EXTRAS xN | k07, k11; S4, P3 | PASS |
| copies 2 → x1, 3 → x2, N → x(N−1) | k08 (2/3/4/8/12/100) | PASS · N01 |
| NEW never EXTRAS x0 | k11 (all 9 fixtures) | PASS · N02 |
| optional owned total | not shown (EXTRAS xN only; layout kept clean) | n/a |
| readable at all target viewports | k13/k14 + 15 viewport captures | PASS |

## Layout / accepted surfaces

| Criterion | Test / evidence | Result |
|---|---|---|
| Standard 3-card + Premium 3+2 geometry preserved | k13/k14 `_geometry_preserved` (independent C006/C007 formula) at 5 viewports | PASS |
| card order / destinations unchanged | k22, C006 v07/v08, C007 suites | PASS · N08 |
| 9 + 9 frame bytes, destination icons, glow bytes unchanged | k26 (manifests + pinned sha256) | PASS · N12 |
| 135 card assets unchanged | no `assets/` path in the commit | done |
| no overlap / clipping | k13–k18 `_layout_problem`, evidence tool (every capture incl. mid-celebration) | PASS |

## Sequencing

| Criterion | Test | Result |
|---|---|---|
| IDLE / Tap 1 / 01→09 / emergence unchanged | C006 (21/21), C007 (19/19) incl. cadence cases | PASS |
| celebration after settle; readable hold; destinations at the right stage | k05, k21 | PASS · N10 |
| Tap 2 required, no auto-route, routing + completion unchanged | k21 (taps during celebration refused), k22, k20 | PASS |

## Authority / idempotency

| Criterion | Test | Result |
|---|---|---|
| no draw / Collection / Exchange / RNG / save / receipt mutation | k23 (4 full presentations of real C008 receipts: economy + RNG + ledger + save bytes unchanged), k24/k25 | PASS |
| reopen replays only the visual | k23 (same celebration count per new instance) | PASS |

## Shared architecture

| Criterion | Evidence | Result |
|---|---|---|
| one card-state path for Standard + Premium | `CardView` + base ceremony; P unchanged | PASS |
| no C008 schema change; no GameFeelFlow / Saltmire | diff; k24 static (`GameFeelFlow`, `GFF`, `Saltmire`, `Spark`) | PASS |

## Runtime evidence (`evidence/v01/`)

| Required | File(s) |
|---|---|
| Standard NEW celebration | `S1_std_mixed_new_celebration_1080x1920.png`, `S5_std_all_new_celebration_1080x1920.png` |
| Standard FIRST COPY hold + duplicate EXTRAS + destinations | `S2_std_mixed_hold_first_copy_extras_destinations_1080x1920.png`, `S4_std_all_duplicate_extras_1080x1920.png` |
| Standard repeated FIRST COPY / x1 / x2 | `S3_std_repeat_first_copy_x1_x2_1080x1920.png` |
| Premium mixed 3+2 (≥2 NEW + duplicates) | `P1_prem_mixed_new_celebration_1080x1920.png`, `P2_prem_mixed_hold_3plus2_1080x1920.png` |
| Premium duplicate-heavy | `P3_prem_duplicate_heavy_extras_1080x1920.png`, `P6_prem_repeat_first_copy_x1_x4_1080x1920.png` |
| Premium multi-NEW overlap | `P4_prem_all_new_celebration_overlap_1080x1920.png`, `P5_prem_all_new_hold_1080x1920.png` |
| Reduced Standard / Premium | `R1`–`R4` |
| 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048 | `V_std_mixed_hold_*`, `V_prem_mixed_hold_*`, `V_prem_duplicate_heavy_hold_*` |
| overview | `CARD_STATE_V01_EVIDENCE_SHEET.png` |

## Owner review harness

| Criterion | Evidence | Result |
|---|---|---|
| Standard / Premium F6 harness use current shipping code | harness smokes h02/h03 (Standard pin re-pinned to the C009 ceremony) | PASS |
| mixed / all-new / duplicate-heavy fixtures; R, E keys | Standard 1–5, Premium 1–4; harness smokes | PASS |
| instructions | `OWNER_REVIEW_INSTRUCTIONS_V01.md` | done |
