# M53-C001 — CLAUDE LOG V01 — First 10 Level QA + Difficulty V1

Date: 2026-09-27
Actor: Claude (implementer). No audit verdict is claimed here.
Prompt: `coordination/sessions/M53-C001/task_prompts/SB-M53-C001_FIRST10_LEVEL_QA_DIFFICULTY.md`
Criteria: `coordination/sessions/M53-C001/audit_criteria/SB-M53-C001_FIRST10_LEVEL_QA_DIFFICULTY.md`
Base: `origin/main` `ad532e1` (fast-forwarded from local `9485472`; no conflicts).
Root `TASKS.md`: read only, not edited.

## Result in one line

The canonical analyzer works and all ten levels pass every static M53 QA gate. **None of the ten fits its owner-locked Challenge target.** Actual D is 45–54 for every level, so all ten are reported as **TUNING_REQUIRED**. The in-cycle recovery guards also fail (L8→L9 is inverted), and L10 is not the cycle maximum. No level was relabeled and no content was changed to make a number fit.

## Git / owner-work preservation

- Repo `Sekiph82/Scrubbots`, branch `main`. Fast-forwarded to `origin/main` `ad532e1` (M53 prompt/criteria commit).
- Owner/local work left untouched and uncommitted:
  - modified `project.godot` (removes the `[audio]` bus-layout block and moves `config/features`);
  - the untracked `.import`/`.uid` files, `_owner_inbox` art, top-level `assets/art/levels/source/level_0xx_*.png` duplicates, and generated UI candidates.
- The commit contains only the M53 files listed under "Changed files".

## What was built

### 1. Analyzer seam — `scripts/difficulty/level_difficulty_analyzer_v1.gd` (`m53-level-difficulty-analyzer/v1`)

Offline QA tooling only. No shipping script or scene references it (asserted by test).

It has two stages:

- **`measure()`** (expensive, raw facts only). It replays a reference path of ordered legal column placements through the real **`ProofKernel`**, which drives the M23 supply, M24 slots, M25 claims, `TargetSelector`, and production routing/access. It records:
  - every exact-slot claim's production route, recomputed from the claim's own slot origin on the claim-time board and validated by `RouteValidator`;
  - every quiescent decision state, sampled with `ProductionTargetAccess.is_targetable`: raw and reachable candidates for each front batch and each occupied slot;
  - the colour-agnostic reachability peel (earliest wave per cell), using the same production access truth;
  - colour stats and a colour-layer topology signature.
- **`score()`** (pure). It normalizes raw measurements with the locked component weights/formulas from `difficulty_score_model_v1.json` (via `ChallengeScoreModelV1`) plus versioned Stage-A anchors. It produces `[W,C,A,U,B,R,S]`, D, target/delta/window, Session Load, provisional Frustration, and the dominant profile.

### 2. Kernel seam — `scripts/gameplay/solver/proof_kernel.gd`

- Added `var observer = null` plus two guarded calls, `on_claim` and `on_wave`. They default to null, so gameplay and solver paths are unobserved and their transitions are unchanged.
- No second routing law exists. Every route and reachability fact comes from `ProductionRoutingSystem` / `ProductionTargetAccess` / `RouteValidator`.

### 3. Versioned config — `data/config/level_difficulty_analysis_v1.json`

- `STAGE_A_PROVISIONAL`. Every anchor was chosen from production-envelope geometry or canonical runtime constants **before** any level was analyzed:
  - unlock reference wave 29 = the 59×59 maximum peel;
  - actions reference 3481;
  - decisions reference 117 = ceil(3481/30);
  - route-time reference 48400 s;
  - route length 2 diagonals, detour ref 3, turns ref 8;
  - A early weight 2.0.
- It also records the operational definition of every metric.
- `difficulty_score_model_v1.json` and `level_progression_v1.json` are **not modified**.

### 4. Tool — `tools/analyze_m53_first10.gd`

- `--only=<id>`: measures one level and writes `evidence/raw/<id>_raw_v1.json`. Levels ran as 10 parallel processes.
- No argument: runs a deterministic merge over the committed raw files. It runs the static QA gates, scoring, sensitivity, recovery and novelty checks, then writes both evidence JSONs and the matrix.

### Reference paths

- **Primary (declared in config before analysis): the canonical oracle `SolvabilitySolver` trace** (doc 09 §13), replayed step-exact.
  - L1: re-solved from the historical generator seed-1 supply. Hash `1618197986` equals the M52 evidence.
  - L2–10: the M52 owner-plan verification traces, after checking that each hash re-computes and that each plan and LevelData is byte-bound to the M52 acceptance.
- **Sensitivity:** the owner intended click path for L2–10, analyzed fully and reported alongside.

## Results (actual analyzed values)

| L | Class | Target | D (solver path) | Window | D (owner path) | Session Load | M53 verdict |
|---:|---|---:|---:|---|---:|---:|---|
| 1 | EASY | 20 | 46.03 | OUT (>±5) | n/a | 9.9 | TUNING_REQUIRED |
| 2 | EASY | 22 | 45.04 | OUT | 38.60 | 24.4 | TUNING_REQUIRED |
| 3 | MEDIUM | 40 | 54.27 | OUT | 44.47 | 35.3 | TUNING_REQUIRED |
| 4 | EASY | 19 | 49.49 | OUT | 37.09 | 24.9 | TUNING_REQUIRED |
| 5 | HARD | 58 | 53.19 | ±3.5–5 (−4.81) | 39.07 | 26.7 | TUNING_REQUIRED |
| 6 | EASY | 18 | 50.91 | OUT | 38.75 | 25.0 | TUNING_REQUIRED |
| 7 | EASY | 21 | 50.96 | OUT | 39.47 | 25.0 | TUNING_REQUIRED |
| 8 | MEDIUM | 42 | 47.37 | OUT (+5.37) | 37.67 | 24.9 | TUNING_REQUIRED |
| 9 | EASY | 19 | 50.78 | OUT | 41.00 | 24.7 | TUNING_REQUIRED |
| 10 | VERY_HARD | 76 | 51.50 | OUT | 40.77 | 25.1 | TUNING_REQUIRED |

The full vectors, supporting raw values, sensitivity and novelty are in `FIRST10_M53_MATRIX_V01.md` and `evidence/first10_difficulty_v1.json`.

### Recovery cadence (actual D, never target D)

- L3→L4: drop 4.78. Design minimum is 15; target drop is 21. **FAIL.**
- L5→L6: drop 2.28. Design minimum is 20. **FAIL.**
- L8→L9: drop −3.41. **Inverted. FAIL.**
- L10 boss: D 51.50, ranked 3rd of 10. **Not the cycle maximum.**
- On the owner path the guards also fail: 44.47→37.09, 39.07→38.75, 37.67→41.00 (inverted).
- The 10→next-1 guard needs Level 11, which is CONTENT_MISSING, so it was not evaluated.

### Why D does not separate the classes

This is a diagnostic, not a remedy.

- **Fixed geometric floor.**
  - All ten boards are fully ACTIVE rectangles, so the colour-agnostic peel equals distance-to-edge. It matched geometry for every cell of every level (`geometricMismatchCells` = 0).
  - For every 32×32 level, U = 0.410 and W = 0.414 are therefore identical. Together they contribute about 12.3 D points.
  - Early accessibility scarcity is dominated by the perimeter/area ratio, giving A = 0.61–0.78.
  - So every level starts near 25–28 D before colour, bottleneck, route or slot pressure is counted. The EASY targets of 18–22 cannot be reached by any 32×32 full-rectangle artwork under these V1 definitions.
- **Similar owner plans.** The supply plans are structurally alike: 30-robot same-colour batches in round-robin. On the owner path, B is 0.03–0.08 for every level.
- **Colour is the only real separator.** C rises from 0.37 to 0.78 (L10), but C carries 15% weight and cannot make up a 24-point VERY_HARD gap.
- **Policy dependence.** The oracle trace drains column 1 first, then column 2. This exhausts columns and inflates B (forced states, low-choice fraction around 0.7) and S compared with the owner path. The solver path therefore scores about 5–14 D higher. Both paths put every level outside the window, so the verdict does not depend on this choice.
- **Anchor sensitivity.** Rescaling each provisional anchor by ×0.5 or ×2, one at a time, moves D by about 3–9 points.
  - L5 and L8 can enter ±3.5 under a single rescaled anchor. They are still reported TUNING_REQUIRED at the declared anchors.
  - No variant brings any EASY level near its target.

What the owner decides next is outside this task. The options include retuning content or supply plans, versioning Stage-B calibration, or re-deciding class tokens. Nothing was remediated silently.

### Session Load

- `PROVISIONAL_STAGE_A`, using the documented envelope anchors.
- L1 = 9.9; L2 and L4–10 = 24.4–26.7; L3 (38×38) = 35.3.
- Estimated attempt duration is a proxy of 237–976 s, based on the kernel's wait-for-quiescence timing at 1×. It is not a human time.
- No owner per-slot Session Load budget exists, so "outside slot budget" cannot be evaluated. Session Load drops at L3 → L4 (35.3 → 24.9) but stays about flat at L5 → L6 (26.7 → 25.0) and L8 → L9 (24.9 → 24.7).

### Frustration Risk

- `PROVISIONAL_STAGE_A` for every level. **No scalar is claimed.**
- Only the choice-opacity proxy is supported: 0.5·B + 0.5·(non-productive legal choice fraction), range 0.22–0.56.
- `retryRisk`, `sessionOverrun` and `lateFailure` are marked UNSUPPORTED: there is no trustworthy human policy, no owner budget, and no failing-simulation population.
- Solver success is **not** used as a clear probability.

### Novelty / profile

- Dominant profile: BALANCED for L1–4 and L6–8; COLOR for L5, L9 and L10.
- Nearest-prior combined similarity is 0.53–0.89. Nine 32×32 boards with similar palettes make most levels miss their slot novelty targets. This is informational.
- Art category is marked `NOT_DEFINED`; no canonical taxonomy exists.

## Static M53 QA — 10/10 levels PASS all gates

Gates checked for each level:

- **Board and palette:** dimensions/envelope; owner-locked class token (LevelData, metadata, catalog and cadence all agree); canonical C01..C16 ascending palette; used colours 3..12 and all used; exact cell count; no invalid IDs.
- **Source art and rendering:** exact source reconstruction (byte-equal RGBA8); no interpolation (source w×h equals the board, all alpha 255); headless `BoardRenderer` check (ACTIVE pixels equal the exact palette colour at alpha 255, CLEARED alpha 0, NEAREST filter).
- **Solving and routing:**
  - canonical solvability (step-exact trace replay; owner path also SOLVED);
  - routing/access sanity: 0 peel-unreachable cells, 0 `RouteValidator` failures across all claims (claims = cells), 0 analyzer-vs-kernel productivity mismatches, peel equals geometry.
- **Performance sanity (headless tooling):**
  - kernel placement is at most 30 s and a single route is at most 1 s;
  - measured single-route maximum was 12–156 ms and kernel-placement maximum 0.8–5.7 s, measured under 10-process parallel contention;
  - runtime frame performance is proven by the R01 suite.
- **Catalog and provenance:**
  - preview exact, and catalog/metadata paths correct;
  - unique stable ID and catalog order;
  - source/metadata provenance: path, SHA-256, git blob SHA-1 and per-C-ID counts all match; LevelData bytes equal the M52-accepted hash.
- **Supply:**
  - L2–10: owner supply-plan provenance — plan SHA equals the M52 evidence, owner-input markdown SHA matches, catalog path matches;
  - L1: historical generator path — no plan, seed-1 supply, trace hash equals M52.

## Tests run (all on Godot 4.7.2.stable.official.ed1daf0bf, headless)

| Suite | Result |
|---|---|
| `tests/m53_first10_difficulty.gd` (new) | exit 0, 315 ok, **PASS**, 0 SCRIPT ERROR |
| `tests/m52_owner_supply_plans.gd` | exit 0, 255 ok, 0 FAIL, **PASS**, 0 SCRIPT ERROR |
| `tests/m52_r01_parallel_runtime.gd` | exit 0, 79 ok, PASS |
| `tests/m52_r02_early_slot_release.gd` | exit 0, 65 ok, PASS |
| `tests/m27_generation_retry.gd`, `m27_hazard_bot_solve.gd`, `m27_scale_59.gd` | exit 0, PASS |
| `tests/m29_hazard_bot_runtime_smoke.gd`, `m29_realtime_movement_smoke.gd` | exit 0, PASS |
| `tests/m30_completion_authority.gd`, `m30_transaction_safe_retry.gd`, `m30_manual_playtest_smoke.gd` | exit 0, PASS |
| `tests/m36_difficulty_v1.gd`, `m36_v02_migration.gd`, `m37_level_progression.gd` | exit 0, PASS |
| root `tests/run_tests.gd` | exit 0, **5323 checks, RESULT: ALL PASS**, 0 SCRIPT ERROR, 9 engine `ERROR:` lines. These are the same count and the same intentional adversarial loads as the R02 baseline (corrupt/nonexistent image fixtures and resources-in-use at exit). |
| `git diff --check` | clean |

What the M53 suite asserts:

- config, analyzer and model versions, and that the locked coefficients are unchanged;
- targets for L1–10 and window classification (±3.5 / ±5 edges);
- full evidence schema;
- the D and Session Load formulas re-derived with the literal weights (tolerance 1e-9); W..S finite and in [0,1];
- every committed raw record re-scores to the committed evidence;
- a **fresh Level 1 measurement run twice** is byte-identical to itself and to the committed raw (timing excluded);
- the observed kernel equals a plain `SolvabilitySolver.replay`, step for step;
- observer defaults to null;
- exact normalized entropy;
- no shipping dependency;
- **no content mutation** (SHA-256 of all sources, LevelData, metadata, previews, plans and the catalog before and after);
- content bound to the M52 bytes;
- all static gates re-run PASS and match the committed gate list;
- recovery guards computed from actual D; recovery failures are never PASS; boss relationship;
- Frustration is provisional with UNSUPPORTED components.

## Protected First 10 behavior

- Owner supply plans are unchanged (hash-bound to M52).
- Level 1 is unchanged: LevelData hash `ae725a9c…`, generator seed-1 path, trace hash `1618197986`.
- R01 and R02 pass.
- `m52_owner_supply_plans` re-run: runtime 9/9 WON for L2–10 through production input, and frontier 11 → CONTENT_MISSING.

## Limitations (explicit)

- Every anchor is Stage-A provisional, and no human data exists.
- The decision-state metrics (A/B/S) depend on the reference policy; both the oracle and owner paths are reported.
- Unlock Depth is colour-agnostic per doc 09 §4.4. On full-rectangle art it is purely geometric.
- Timing values are headless tooling numbers, not device performance.

## Changed files

- `scripts/gameplay/solver/proof_kernel.gd` (null-default observer seam)
- `scripts/difficulty/level_difficulty_analyzer_v1.gd` (new)
- `data/config/level_difficulty_analysis_v1.json` (new)
- `tools/analyze_m53_first10.gd` (new)
- `tests/m53_first10_difficulty.gd` (new)
- `coordination/sessions/M53-C001/evidence/raw/*_raw_v1.json` (10, new)
- `coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json` (new)
- `coordination/sessions/M53-C001/evidence/first10_level_qa_v1.json` (new)
- `coordination/sessions/M53-C001/FIRST10_M53_MATRIX_V01.md` (new, generated)
- `coordination/sessions/M53-C001/CLAUDE_LOG_V01.md` (this file)

## Reproduce

```bash
godot --headless --path . -s res://tools/analyze_m53_first10.gd -- --only=<level_id>
godot --headless --path . -s res://tools/analyze_m53_first10.gd
godot --headless --path . -s res://tests/m53_first10_difficulty.gd
```

The first command runs once per level; the second merges the evidence; the third runs the M53 suite.

`AWAITING_CHATGPT_AUDIT / M53-C001 FIRST 10 LEVEL QA + DIFFICULTY V1`
