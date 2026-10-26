# Difficulty Frustration Risk inputs proposal V1 (SB-M36-011)

Status: PROPOSAL, recommendation pre-approved. This document changes nothing in `data/config/`, `data/levels/`, the catalog or any script. On 2026-10-26 the owner pre-approved the factory's own findings ("kendi bulduklarını ben okeyliyorum şimdiden.", orchestrator chat). The recommendation in section 7 is therefore approved, and its implementation is filed as SB-M36-015. The owner's ratings are not used as a criterion.

Inputs (every number below is copied from these files or computed directly from them):

- docs/09 section 6 (Session Load) and section 7 (Frustration Risk); docs/10 section 7 (reference policies) and section 22 step G; docs/11 sections 5-8.
- `data/config/difficulty_score_model_v1.json` and `data/config/difficulty_score_model_v2.json` (`frustrationRisk`, `sessionLoad`).
- `data/config/level_difficulty_analysis_v1.json` and `data/config/level_difficulty_analysis_v2.json` (`operationalDefinitions`, `policies`).
- `scripts/difficulty/level_difficulty_analyzer_v2.gd` (`run_policy`, `choose`, `frustration`).
- `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json` (v2 run of the 10 shipped levels, report `docs/DIFFICULTY_MODEL_V2_CALIBRATION.md`).
- `scripts/gameplay/completion/completion_evaluator.gd` (LOST only on a proven DEADLOCK), `coordination/OWNER_ECONOMY_REWARDS_V01.md` section 6 (Hearts).
- CLAUDE.md 11.3 (versioned coefficients), 11.4 (Challenge, Session Load and Frustration are separate axes), 11.5 (no hidden individualized dynamic difficulty), 15 (no timer, no move limits).

## 1. The definition today

docs/09 section 7 and both score models (v1 and v2, identical block) define:

```text
retry_risk       = 1 - simulated_human_policy_clear_rate
session_overrun  = normalized amount above slot load budget
late_failure     = fraction of failed simulations that fail after >70% progress
choice_opacity   = combination of bottleneck + misleading/low-information choice states

F = 100 * (0.35 retry_risk + 0.30 session_overrun + 0.20 late_failure + 0.15 choice_opacity)
```

Both models set `provisionalUntilHumanPolicyAndPlaytestCalibration: true`. Session Load (`100*(0.50 actionsNorm + 0.30 routeTimeNorm + 0.20 decisionCountNorm)`, anchors 3481 actions / 48400 route seconds / 117 decisions) is a separate axis and is already measured.

docs/11 section 7 gives only relative frustration ceilings (slots 4/6/9 very low, 1/2/7 low, 3/8 medium-low, 5 medium, 10 medium-high, never unbounded). docs/11 section 8 gives only relative attempt-duration rules (recovery shorter than the preceding peak, no consecutive long attempts, boss not a marathon by default).

## 2. Which inputs exist and which are missing

| Input | Weight | Status in the v2 analyzer | What is missing |
|---|---:|---|---|
| choice_opacity | 0.15 | SUPPORTED_PROXY: `0.5*B + 0.5*nonProductiveLegalFraction` over the six-policy ensemble | nothing for a provisional value |
| retry_risk | 0.35 | UNSUPPORTED: "no trustworthy simulated-human policy; policy/solver completion is not a human clear rate" | a stochastic human-like policy population and its clear rate |
| session_overrun | 0.30 | UNSUPPORTED: "no owner per-slot Session Load budget" | a per-slot Session Load budget and an overrun normalization |
| late_failure | 0.20 | DIAGNOSTIC_ONLY: one STRESS run, `stressLateFailure` true/false | a population of failed attempts (one adversarial run is not a fraction) |

So 85% of the weight has no input, and the analyzer correctly reports `scalar: null`. The task also names inputs that docs/09 does not weight. They are useful diagnostics, but none of them enters F:

| Diagnostic | Exists today | Proposed source |
|---|---|---|
| fail/retry probability | no | human-policy LOST rate (= retry_risk) |
| dead-end placements (non-productive slot fill) | STRESS only (`stressDeadPlacements`) | per attempt in the human-policy runs |
| no-target waits (every occupied slot has 0 reachable targets, bots wait) | no | per decision state in the human-policy runs (`occupied[].reachable`) |
| near-miss (LOST at >= 90% progress) | no | human-policy LOST runs |
| Hearts consumed per clear | no | derived from the clear rate (section 4.5), no economy change |
| session length in seconds | PROXY seconds in Session Load | human-policy think time + bot travel time, labelled PROXY |

What "failure" means is already fixed by the game: `CompletionEvaluator` reports LOST only when the M27 DeadlockClassifier proves DEADLOCK at quiescence (no legal future sequence can make progress). There is no timer and no move limit (CLAUDE.md 15). In the analyzer, a run that ends with `no_legal_placement` while ACTIVE cells remain is that state: `ProofKernel.quiesce` has already dispatched every possible clear, and no placement is legal. Once a state is DEADLOCK no further cell clears, so the progress at the end of the run equals the progress at the LOST verdict. Non-completion already occurs under reasonable play: in `playtest_v2.json` only 4 of 6 non-adversarial primary policies complete Level 1 (`primaryPoliciesCompleted` 4/6).

## 3. Options

- **A. Real player telemetry.** Not available before release. Using it per player would also be the hidden individualized DDA that CLAUDE.md 11.5 forbids. It stays as the later calibration source (docs/11 section 5: retry/abandonment correlation), not as an input now.
- **B. Solver-only trap density.** At sampled states, count the placements that lead to a proven DEADLOCK. This is deterministic but has no human model, so it measures brittleness, not a clear rate. It is also expensive, because it needs one DeadlockClassifier solve per legal front per state.
- **C. Simulated-human policy population (recommended).** This is the "human-like stochastic ensemble" of docs/10 section 7: a bounded-rational dispatch policy with fixed, versioned mistake parameters, replayed through the real ProofKernel over many deterministic seeds. It records the distribution, not one number. It reuses `run_policy` and `_decision_state` unchanged and produces retry_risk, late_failure and every diagnostic above. It is paired with a versioned per-slot Session Load budget for session_overrun.

## 4. Recommended approach: bounded-rational human policy (HUMAN_BR) + Session Load budget

### 4.1 Policy

At each decision the policy sees the same decision state the v2 ensemble uses (`_decision_state`). Every legal front has `color`, `robots`, `raw` (ACTIVE cells of that colour) and `reachable` (targets reachable from the placement slot). The steps are:

1. **Perception.** For each front, with probability `mu` the player misjudges an enclosed colour: the perceived count is `raw` (the colour is visible on the board) instead of `reachable`. Otherwise the perceived count is `reachable`. This is the "misleading choice" docs/09 names: a colour that is present but not yet targetable.
2. **Utility.** `u = min(perceived, robots) / robots`, the same expression ACCESS uses, in 0..1.
3. **Choice.** With probability `epsilon` (slip) the player picks a uniformly random legal front. Otherwise the player samples from a softmax over `u / tau`. A lower `tau` is more rational.
4. **Latency.** Think time per decision is `t0 + t1 * log2(1 + legalFronts)` seconds (Hick-Hyman). The game has no timer, so latency never changes the outcome. It only feeds the session-length diagnostic.

There is no lookahead and no undo. The policy only places fronts, exactly as a player does. Dispatch, targeting and routing stay in the real ProofKernel/TargetSelector/RoutingSystem path (CLAUDE.md 9 and 10 unchanged).

Degenerate check: with `tau -> 0` (argmax, ties to the lowest column), `epsilon = 0` and `mu = 0`, HUMAN_BR must choose exactly what the v2 ACCESS policy chooses. (ACCESS's secondary key, `reachable`, is applied as the tie-break before the column tie-break.)

### 4.2 Parameters (versioned, uncalibrated priors)

A fixed population of three profiles. These are priors to be fitted later against internal playtests (docs/11 section 5), and they are labelled `PRIOR_UNCALIBRATED` in the config:

| Profile | Weight | tau | epsilon | mu | t0 s | t1 s |
|---|---:|---:|---:|---:|---:|---:|
| NOVICE | 0.30 | 0.30 | 0.10 | 0.40 | 1.5 | 0.8 |
| CASUAL | 0.50 | 0.15 | 0.05 | 0.20 | 1.0 | 0.6 |
| SKILLED | 0.20 | 0.05 | 0.01 | 0.05 | 0.6 | 0.4 |

Changing any value means a new config version (CLAUDE.md 11.3). The profiles are an offline analysis population. They are never assigned to a real player, never read save or telemetry data, and never ship in the runtime. CampaignBuilder and acceptance use the result the same way for every player, so this is not DDA (CLAUDE.md 11.5).

### 4.3 Determinism and seeds

- RNG: one Godot `RandomNumberGenerator` (PCG32) per attempt, seeded with `hash("%s|%s|%d|%s" % [levelId, profile, runIndex, policyConfigVersion])`. The RNG is consumed in a fixed order: per front the perception draw, then the slip draw, then the softmax draw.
- Runs: `runsPerProfile = 32` (`runIndex` 0..31), 96 attempts per level.
- Each attempt records a placement-column hash. The same level, profile, seed and config must give a byte-identical JSON, and the test suite checks this.

### 4.4 Session Load budget (session_overrun)

These are proposed per-slot budgets in Session Load units, labelled `PROXY` until playtest calibration. They follow the docs/11 section 7 ceiling order and the docs/09 board-size guidance. Measured Session Load is about 0.0245 per cell on the shipped 32x32..38x38 boards (32x32 = 25.0, 38x38 = 35.6), so each budget is also given as a square-board equivalent:

| Slots | docs/11 ceiling | Budget | About |
|---|---|---:|---|
| 4, 6, 9 | very low | 22 | 30x30 |
| 1, 2, 7 | low | 26 | 32x32 |
| 3, 8 | medium-low | 36 | 38x38 |
| 5 | medium | 40 | 40x40 |
| 10 | medium-high, never unbounded | 48 | 44x44 (inside the 41..48 load-gated band) |

`session_overrun = clamp((SessionLoad - budget) / budget, 0, 1)`: 0 at or under budget, 1 at twice the budget. The budget does not grow with campaign age in this version, and any growth needs a new config version. The relative docs/09 section 10 rule (Session Load drops at slots 4, 6, 9 and next-cycle 1) remains a CampaignBuilder check (SB-M36-014), not part of F.

Applied to the shipped 10 (v2 Session Load): L4 25.04, L6 25.21 and L9 25.07 overrun the very-low budget by 0.138, 0.146 and 0.139, which is about 4 F points each. Every other level is within budget (L1 7.5/26, L2 24.52/26, L3 35.64/36, L5 26.60/40, L7 25.17/26, L8 25.11/36, L10 25.12/48). This is consistent with SB-M36-010: the 32x32 recovery levels are not shorter than their peaks.

### 4.5 Outputs

Per level, per profile and population-weighted:

- `clearRate`: WON / (WON + LOST). Runs that hit the 2000-decision bound are INCONCLUSIVE: they are counted, reported and excluded, never counted as LOST. It is reported with a Wilson 95% interval.
- `retryRisk = 1 - weighted clearRate`.
- `lateFailure`: LOST runs with final progress > 0.70, divided by LOST runs. It is 0 when there are no LOST runs, and the count is reported next to it.
- `nearMiss`: LOST runs with progress >= 0.90 / LOST runs (diagnostic).
- `deadPlacementsPerAttempt`: chosen front not productive (diagnostic).
- `noTargetWaitFraction`: decision states where every occupied slot has 0 reachable targets (diagnostic).
- `expectedAttemptsPerClear = 1 / clearRate`, `heartsPerClear = 1/clearRate - 1` (each LOST costs 1 Heart), and `pOutOfHeartsBeforeClear = (1 - clearRate)^5` (5 Hearts maximum). These are diagnostics only, with no economy change.
- `attemptSecondsProxy`: think time plus bot travel time at the canonical 6 cells/s, median over attempts, labelled PROXY.
- `sessionOverrun`, plus the existing `choiceOpacity`.
- `F` and status: F is computed only when all four inputs are present, with weights read from `difficulty_score_model_v2.json` (unchanged), and its status is `PROVISIONAL_SIMULATED_HUMAN`. If any input is missing, F stays `null`.

### 4.6 Where it lives (no change to existing versions)

- New config `data/config/frustration_analysis_v1.json` (schema `scrubbots-frustration-analysis/v1`): profiles, seeds, runs, budgets, overrun rule, thresholds 0.70/0.90, status labels.
- New analyzer `scripts/difficulty/frustration_analyzer_v1.gd`. It reuses `LevelDifficultyAnalyzerV2.run_policy`/`_decision_state` through a policy callable or a new policy name. It is offline QA only, and no shipping script references it.
- `tools/difficulty_playtest.gd` gains `--frustration` (opt-in, off by default, so existing runs stay byte-stable) and `--runs N`.
- `difficulty_score_model_v1.json`, `difficulty_score_model_v2.json`, `level_difficulty_analysis_v1.json`, `level_difficulty_analysis_v2.json` and `level_progression_v1.json` stay byte-identical. The F weights are only read.

### 4.7 Runtime cost on the 10 shipped levels

Measured basis: the v2 run measured 7 policy runs per level in 1469.8 s summed `measureMs` for 10 levels. That is about 210 s per policy across the 10 levels, or 21 s per run on a standard level (L1 20x20: 1.6 s per run). The cost is dominated by `_decision_state` reachability per legal front, which HUMAN_BR also needs.

- 96 attempts per level, each about 210 s summed over the 10 levels, is about 20,200 s, or **about 5.6 h single-process**. Failed attempts end early, so this is an upper estimate.
- `--runs 8` (24 attempts per level) takes about 1.4 h. That is the smoke size for a tool change, not for acceptance.
- Precision at 32 runs per profile: the worst-case 95% half-width is about 0.17 per profile and about 0.11 for the weighted population (weights 0.30/0.50/0.20). Through the 0.35 weight that is about +/-3.7 F points on retry_risk.
- The job records the real wall time. An offline background run of this length is acceptable for a QA tool. Parallel workers and prefix caching are not proposed now; add them when the run becomes a per-candidate Level Factory gate.

## 5. Acceptance tests (new suite `tests/m36_frustration_v1.gd`)

1. Determinism: the same level, profile and seed run twice give an identical placement hash. A full 1-level run twice gives byte-identical JSON. Different seeds diverge on at least one fixture.
2. Degenerate equivalence: with `tau -> 0`, `epsilon = 0` and `mu = 0`, HUMAN_BR chooses exactly the v2 ACCESS column sequence on 3 corpus fixtures and L1.
3. Skill monotonicity: clearRate SKILLED >= CASUAL >= NOVICE on each fixture tested (ties allowed).
4. Discrimination, declared before measuring: retryRisk(compact_hard_20) >= retryRisk(flow_stripes3_20) and retryRisk(bottleneck_high_24) >= retryRisk(bottleneck_low_24) on the M53-C002 corpus (`tests/fixtures/difficulty_calibration`). If a declared pair fails, it is reported honestly as a finding and not tuned away.
5. Aggregator units on crafted run lists: late_failure uses strictly > 0.70; INCONCLUSIVE runs are excluded from clearRate and counted; lateFailure is 0 with a count of 0 when there are no LOST runs; near-miss uses >= 0.90.
6. session_overrun: 0 at or under budget, 1 at 2x budget and above, linear in between, budget looked up by slot.
7. F is finite and in 0..100. The weights equal the values in `difficulty_score_model_v2.json` (0.35/0.30/0.20/0.15). F is `null` when any input is missing.
8. Provenance: the five existing configs listed in 4.6 are byte-identical to `main` (sha256). The output carries the config version, seeds and analyzer version.
9. Boundary: no script under `scripts/` outside `scripts/difficulty/`, and no scene, preloads the frustration analyzer, and it never reads `user://`.
10. Full 10-level run (`--frustration`) is recorded with wall time in the job evidence, with per-level F, the three inputs and the diagnostics. Existing suites stay green: `m36_difficulty_v2`, `m36_difficulty_v1`, `m53_first10_difficulty`, `m53_c002_difficulty_calibration`.

## 6. What this does not do

It does not calibrate the human model. The profiles are priors until internal playtests exist (docs/11 sections 3-5), and F stays labelled provisional. It does not add a timer, move limit, Heart rule or any gameplay change. It does not change the F weights or any existing model version, and it does not use F to adapt anything per player.

## 7. Recommendation (approved by the owner pre-approval of 2026-10-26)

Build option C as specified in section 4: the HUMAN_BR population (3 profiles x 32 seeds, through the real ProofKernel), the per-slot Session Load budget 22/26/36/40/48 with `session_overrun = clamp((SL - budget)/budget, 0, 1)`, a new `frustration_analysis_v1.json` and analyzer, and the tests in section 5. This produces all four docs/09 inputs without telemetry and without changing any existing version, so the F scalar can be reported as `PROVISIONAL_SIMULATED_HUMAN`. Filed as SB-M36-015.
