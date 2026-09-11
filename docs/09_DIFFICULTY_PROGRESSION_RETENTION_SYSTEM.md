# 09 — Difficulty, Progression & Retention System V1

Status: **OWNER-LOCKED DESIGN V1 — 2026-09-12**
Owner decision: `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
Machine-readable progression config: `data/config/level_progression_v1.json`
Machine-readable score model: `data/config/difficulty_score_model_v1.json`

This document defines how SCRUBBOTS separates **difficulty**, **duration/load** and **frustration**, while preserving a fixed ten-level emotional rhythm and allowing the absolute difficulty of each class to rise over a long campaign.

## 1. Why the old model is retired

The historical model used board dimensions and distinct color count as hard class gates. That was useful as an early engine-validation framework, but it confuses three different things:

- visual/logical resolution;
- amount of work/time in a level;
- actual puzzle difficulty.

A large board can be easy. A compact board can be structurally difficult. The new system therefore keeps board size and color statistics as inputs, not class identity.

The variable-size engine and 59x59 capacity are preserved.

## 2. Fixed ten-level cadence

For `n >= 1`:

```text
slot(n)  = ((n - 1) mod 10) + 1
cycle(n) = floor((n - 1) / 10)
```

Locked cadence:

| Slot | Class | Emotional job | Micro modifier |
|---:|---|---|---:|
| 1 | EASY | fresh-cycle relief / flow | +0 |
| 2 | EASY | confidence / slight rise | +2 |
| 3 | MEDIUM | first tension peak | +0 |
| 4 | EASY | recovery | -1 |
| 5 | HARD | mini-boss | +0 |
| 6 | EASY | strongest recovery | -2 |
| 7 | EASY | playful novelty | +1 |
| 8 | MEDIUM | second tension peak | +2 |
| 9 | EASY | confidence before finale | -1 |
| 10 | VERY_HARD | cycle boss | +0 |

This repeats forever. Campaign age changes the target score inside each lane, not the cadence ordering.

## 3. Global progression curve

Completed-cycle index:

`k = floor((n - 1) / 10)`

Progression factor:

`P(k) = 1 - exp(-k / 20)`

Properties:

- `P(0) = 0`;
- it rises quickly enough to make level 311 meaningfully harder than level 11;
- it asymptotically approaches 1 so an endless campaign does not become impossible.

Lane formulas:

```text
EASY       = 20 + 14P
MEDIUM     = 40 + 13P
HARD       = 58 + 13P
VERY_HARD  = 76 + 12P
```

Final target:

`TargetChallenge(n) = LaneTarget(class(n), P(k)) + SlotModifier(slot(n))`

Representative values:

| Level | Class | Target |
|---:|---|---:|
| 1 | EASY | 20.00 |
| 10 | VERY_HARD | 76.00 |
| 11 | EASY | 20.68 |
| 111 | EASY | 25.92 |
| 310 | VERY_HARD | 85.32 |
| 311 | EASY | 31.03 |
| 312 | EASY | 33.03 |
| 1001 | EASY | 33.91 |
| 1010 | VERY_HARD | 87.92 |

The key behavior is visible at 310 → 311: absolute campaign difficulty has risen, but the player receives a dramatic recovery after the boss.

## 4. Challenge Score

Challenge Score is a 0..100 structural/cognitive estimate. It intentionally does not equal duration.

V1 normalized vector:

```text
W = Workload
C = Color Complexity
A = Accessibility Scarcity
U = Unlock Depth
B = Bottleneck Pressure
R = Route Complexity
S = Slot/Color Pressure
```

V1 score:

`D = 100 * (0.10W + 0.15C + 0.20A + 0.20U + 0.15B + 0.10R + 0.10S)`

All submetrics are clamped to `[0,1]` and must record their metric-model version.

### 4.1 W — Workload

Workload represents the amount of physical clearing work without allowing cell count to dominate difficulty.

Inputs may include:

- ACTIVE logical cell count;
- reference-solution dispatch count;
- normalized total route distance.

V1 principle: use a compressed transform such as logarithmic or square-root normalization rather than linear `cells / max_cells`.

Recommended first implementation:

```text
W_cells = clamp(
  (sqrt(active_cells) - sqrt(400)) /
  (sqrt(2400) - sqrt(400)),
  0, 1
)
```

Values above the reference range clamp rather than forcing every 59x59 board to be maximally difficult. Session Load handles the heavier time cost separately.

### 4.2 C — Color Complexity

Color complexity must reflect both how many colors exist and how they are distributed.

Let:

- `m` = number of distinct canonical colors actually used;
- `H` = normalized Shannon entropy of the color-frequency distribution.

Recommended V1:

```text
count_norm = clamp((m - 3) / 9, 0, 1)
C = 0.50 * count_norm + 0.50 * H
```

This means eight evenly distributed colors are more demanding than eight colors where one dominates almost the whole board.

### 4.3 A — Accessibility Scarcity

This is one of the most important SCRUBBOTS-specific metrics.

At each reference-solution state, measure:

```text
reachable_matching_targets / raw_matching_active_candidates
```

Accessibility scarcity is the inverse of that availability, averaged across the level with extra weight on early and mid-game states.

Recommended conceptual form:

```text
A_t = 1 - reachable_candidates_t / max(raw_candidates_t, 1)
A = weighted_mean(A_t)
```

The weighting function should emphasize the first 60% of progress because early restriction has stronger perceived difficulty and churn impact than a final forced cleanup.

### 4.4 U — Unlock Depth

Unlock Depth measures how many clearing layers are required before previously enclosed cells become targetable.

The analyzer assigns each logical cell an earliest reachability wave under canonical ACTIVE-blocker / CLEARED-open semantics.

Useful raw values:

- maximum unlock wave;
- mean unlock wave;
- 90th/95th percentile unlock wave;
- proportion of cells unavailable in the first wave.

Recommended V1 combination:

```text
U = 0.55 * normalized_p95_unlock_wave
  + 0.30 * normalized_mean_unlock_wave
  + 0.15 * initially_locked_fraction
```

Normalization references must be versioned and updated from accepted-candidate/playtest distributions, never silently changed.

### 4.5 B — Bottleneck Pressure

Bottleneck Pressure asks how often the player has very few valid productive choices.

At each simulated decision state record:

- number of legal productive slot actions;
- number of reachable target alternatives;
- whether the state is forced;
- length of consecutive forced-action streaks.

Recommended V1:

```text
low_choice_fraction = fraction(states with <= 2 productive actions)
forced_fraction     = fraction(states with exactly 1 productive action)
forced_streak_norm  = normalized longest forced streak

B = 0.35 * low_choice_fraction
  + 0.40 * forced_fraction
  + 0.25 * forced_streak_norm
```

A bottleneck is not automatically bad. It becomes bad when combined with long Session Load or high failure/retry pressure.

### 4.6 R — Route Complexity

Route Complexity describes the navigation burden produced by the canonical routing/access model.

Inputs:

- average route length normalized to board diagonal;
- detour ratio: actual route length / straight-line distance;
- turn count per route;
- route-length variance;
- share of targets requiring long exterior traversal.

Recommended V1:

```text
R = 0.45 * avg_route_length_norm
  + 0.35 * avg_detour_norm
  + 0.20 * avg_turn_norm
```

The analyzer consumes production routing results. It must not implement a second incompatible routing law.

### 4.7 S — Slot / Color Pressure

S measures how restrictive the five-slot interaction becomes over the reference solution.

Potential inputs:

- proportion of states where one or more visible slots have no productive work;
- productive-slot count distribution;
- imbalance of remaining work across slot colors;
- color-switch / slot-choice volatility;
- longest period where only one slot color can progress.

V1 must use only mechanics already canonical in the main game. Queue/cooldown/stack mechanics must not be invented merely to increase this metric.

Recommended first implementation:

```text
S = 0.40 * no_work_slot_fraction
  + 0.35 * single_productive_slot_fraction
  + 0.25 * color_demand_imbalance
```

## 5. Challenge vector matters as much as scalar score

Two levels with `D = 45` must not necessarily feel alike.

Each accepted level stores its seven-dimensional challenge vector:

`[W,C,A,U,B,R,S]`

Campaign sequencing uses vector diversity so consecutive levels do not become repetitive even when scalar score fits perfectly.

Example profiles:

- FLOW: low B/U, medium R, low cognitive friction;
- COLOR: high C/S, moderate A;
- FORTRESS: high U/B;
- ROUTE: high R/A;
- MARATHON: high W but low B/U;
- BALANCED: no dominant axis.

These are analysis/sequencing profiles, not new gameplay mechanics.

## 6. Session Load

Session Load answers: "How much time/effort does one attempt consume?"

It is separate from challenge.

V1 inputs:

- `actions_norm`: normalized number of dispatch/clear actions;
- `route_time_norm`: reference-solution cumulative travel time using canonical bot speed;
- `decision_count_norm`: number of player decision opportunities;
- optional animation/FX overhead proxy when production effects exist.

Recommended V1:

`SessionLoad = 100 * (0.50 actions_norm + 0.30 route_time_norm + 0.20 decision_count_norm)`

The analyzer also reports an estimated attempt-duration proxy in seconds. This is not claimed as real human time until calibrated by playtests.

### Board-size guidance

Board dimensions affect Session Load strongly because every logical cell ultimately requires clearing.

Production envelope remains 20..59 per dimension, but campaign use should prefer:

- standard: 24..40;
- large: 41..48 only when load fits the intended slot;
- 49..59 only for deliberate exceptional content with mobile readability/load evidence.

## 7. Frustration Risk

Frustration Risk is not synonymous with challenge.

A difficult level can be satisfying when short and legible. A moderate level can be frustrating when attempts are long, choices are opaque and failure arrives late.

V1 components:

```text
retry_risk       = 1 - simulated_human_policy_clear_rate
session_overrun  = normalized amount above slot load budget
late_failure     = fraction of failed simulations that fail after >70% progress
choice_opacity   = combination of bottleneck + misleading/low-information choice states
```

Recommended V1:

`F = 100 * (0.35 retry_risk + 0.30 session_overrun + 0.20 late_failure + 0.15 choice_opacity)`

Until a human-policy simulator is trustworthy, Frustration Risk must be labeled provisional and internal playtest evidence outranks the proxy.

## 8. Initial class tuning targets

These are V1 calibration targets, not timeless laws.

| Class | First-attempt clear-rate target | General intent |
|---|---:|---|
| EASY | 85..95% | flow / recovery / confidence |
| MEDIUM | 70..85% | noticeable thought/tension |
| HARD | 55..70% | mini-boss pressure |
| VERY_HARD | 40..60% | cycle boss, demanding but fair |

Any production tuning change must version the model and retain old provenance.

## 9. Acceptance windows

Initial Challenge target tolerance:

- default: `TargetChallenge ± 3.5`;
- campaign builder may prefer ±2 when a sufficiently large accepted pool exists;
- a level outside ±5 must not be force-labeled merely to fill a slot.

Class label is derived from the campaign slot and accepted target fit, not from dimensions.

Additional acceptance requirements:

- legal data/palette/source;
- solvable or explicitly solver-authoritative PASS;
- Session Load within the slot budget;
- Frustration Risk below the slot budget;
- similarity and novelty rules pass;
- mobile readability passes;
- no unresolved QA blocker.

## 10. Recovery constraints

The campaign validator must directly check score/load drops after peaks.

Minimum V1 design intentions:

- 3 → 4: clearly lower challenge;
- 5 → 6: strong recovery;
- 8 → 9: clearly lower challenge;
- 10 → next 1: largest recovery in the cycle.

Suggested initial scalar guards:

```text
T(4)  <= T(3)  - 15
T(6)  <= T(5)  - 20
T(9)  <= T(8)  - 15
T(11) <= T(10) - 35
```

The formulas naturally satisfy these in early and mature campaign regions, but CampaignBuilder must test actual accepted level scores rather than trust formulas alone.

Session Load should normally drop with challenge at slots 4, 6, 9 and next-cycle 1 unless a deliberately long-but-relaxing showcase passes playtest.

## 11. Novelty and anti-boredom

Increasing challenge forever does not retain players. Novelty must be an independent sequencing signal.

Every candidate records a novelty signature including, where available:

- silhouette/art category;
- dimensions/aspect ratio;
- canonical palette subset and distribution;
- challenge vector;
- topology/unlock-wave signature;
- route signature;
- dominant profile;
- source/generator family.

CampaignBuilder compares a candidate to a recent window, initially 20 levels.

Reject or penalize:

- near-duplicate artwork/topology;
- same dominant challenge profile too often;
- same dimensions/aspect ratio for long runs;
- same dominant palette family repeatedly;
- consecutive long/high-load levels;
- repeated boss structure with only cosmetic changes.

### Suggested novelty targets by cadence slot

| Slot | Novelty target | Rationale |
|---:|---:|---|
| 1 | 0.55 | fresh cycle |
| 2 | 0.35 | reinforce flow |
| 3 | 0.45 | tension, not overload |
| 4 | 0.60 | recovery can feel fresh |
| 5 | 0.30 | hard level should be readable |
| 6 | 0.65 | strong recovery + delight |
| 7 | 0.75 | best novelty playground |
| 8 | 0.45 | second tension |
| 9 | 0.50 | confidence / refresh |
| 10 | 0.35 | boss should test mastery, not surprise with noise |

These values are tunable configuration, not hardcoded engine constants.

## 12. Generation must target a vector, not only a scalar

For each campaign request the Factory receives:

```text
level_number
class
TargetChallenge
ChallengeTolerance
SessionLoadBudget
FrustrationBudget
NoveltyTarget
preferred/avoided challenge profiles
recent-level signatures
seed policy
art mode
```

The generator/evaluator loop aims for this complete target envelope.

A candidate with a perfect scalar score but excessive Session Load or near-duplicate vector is rejected.

## 13. Simulation policies

The solver layer should separate provable solvability from human-likeness.

Required policy families:

1. **Oracle solver**: seeks a valid completion; used for solvability and structural metrics.
2. **Greedy-valid policy**: always takes an immediately productive option using a deterministic simple heuristic.
3. **Human-like stochastic policies**: bounded randomness and imperfect choice, used only as prediction proxies.
4. **Stress/adversarial policies**: explore poor but legal decisions to find dead ends and late-failure traps.

No human-like simulator result may override a proven oracle unsolvable result.

## 14. Calibration stages

### Stage A — pre-player

- exact solver metrics;
- deterministic generated fixtures;
- internal developer playtest;
- coefficient sanity checks;
- score monotonicity/property tests.

### Stage B — structured internal playtest

Record manually/local-only:

- completion/failure;
- attempt count;
- attempt duration;
- completion progress at failure;
- perceived difficulty 1..7;
- perceived fairness 1..7;
- boredom/engagement 1..7.

Fit provisional coefficients without requiring external telemetry.

### Stage C — production calibration, only after owner analytics approval

Potential aggregated signals:

- first-attempt clear rate;
- attempts-to-clear distribution;
- abandonment/churn after level;
- attempt duration;
- retry latency;
- help/booster use if such mechanics exist later.

External analytics collection remains a separate owner decision.

## 15. Model versioning

Every analyzed production level records at least:

```text
scoreModelVersion
progressionModelVersion
solverVersion
generatorVersion
challengeScore
challengeVector
sessionLoad
frustrationRisk
noveltySignature
analysisSeed/config provenance
```

If weights change, do not silently reinterpret old numbers. Re-analysis produces a new versioned result.

## 16. M21 compatibility

M21 is a vertical-slice proof, not campaign balancing.

The approved 20x20 Hazard Bot may pass through the legacy EASY dimension/color validator during M21. Its purpose is to prove real art → LevelData → BoardState → routing/dispatch/clearing/rendering.

No inference should be made that future EASY levels must be 20x20 or use five colors.

## 17. Definition of success

The new system succeeds when:

- cadence always matches E,E,M,E,H,E,E,M,E,VH;
- level 311 EASY is measurably more demanding than level 11 EASY;
- recovery levels remain genuine relief relative to local peaks;
- board size does not dictate class;
- accepted levels fit challenge, load and frustration envelopes separately;
- campaign variety is measurable rather than aesthetic guesswork;
- generator output is reproducible and auditable;
- coefficient changes are versioned;
- real playtest data can calibrate the system later without redesigning the architecture.
