# ADR — Difficulty V1: Decouple Challenge from Board Size and Color Count

Status: **ACCEPTED / OWNER-LOCKED — 2026-09-12**

Supersedes the difficulty-class semantics of historical ADR-010 while preserving the variable-size engine and its 59x59 capability.

Owner decision:
`coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

## Context

Early SCRUBBOTS development needed deterministic production bands to prove that LevelData, BoardState, rendering and performance handled multiple board sizes. The project therefore used:

```text
EASY       20..29 per dimension
MEDIUM     30..39
HARD       40..49
VERY_HARD  50..59
```

and later paired those labels with distinct-color bands.

That framework was useful for engine validation but creates an undesirable product-design coupling:

- more pixels mostly increase work/session duration;
- more colors are only one source of puzzle complexity;
- accessibility, unlock topology, bottlenecks, routing and slot pressure can make compact boards difficult;
- an endless campaign needs same-class progression and recovery waves independent of board resolution.

## Decision

### 1. Production board envelope

Supported production dimensions remain 20..59 per dimension, rectangular boards allowed. This is capacity/content legality, not difficulty class.

### 2. Production palette envelope

ACTIVE cells use only C01..C16. Production artwork normally uses 3..12 distinct used canonical colors. Count does not assign class.

### 3. Difficulty measurement

Challenge Score V1 is based on:

- W Workload 10%
- C Color Complexity 15%
- A Accessibility Scarcity 20%
- U Unlock Depth 20%
- B Bottleneck Pressure 15%
- R Route Complexity 10%
- S Slot/Color Pressure 10%

Session Load and Frustration Risk are separate outputs.

### 4. Campaign class

Class comes from the exact repeating cadence:

`E,E,M,E,H,E,E,M,E,VH`

and the candidate must fit the calculated target Challenge window for that campaign position.

### 5. Long-term progression

Same-class target challenge grows with a saturating progression function rather than unbounded linear growth.

### 6. Generator architecture

Level Factory is evaluator-guided: generate → solve/analyze → accept/mutate/reject. CampaignBuilder sequences accepted candidates separately from generation.

## Consequences

### Positive

- compact hard puzzles become legal;
- larger relaxing artwork becomes legal when Session Load is acceptable;
- difficulty can grow across hundreds/thousands of levels without requiring ever-larger boards;
- campaign recovery rhythm is explicit;
- generator can optimize multiple dimensions instead of gaming one proxy;
- mobile readability and duration become dedicated QA dimensions.

### Costs

- legacy `DifficultyRules` and `ProductionLevelValidator` require controlled migration;
- Level Factory needs canonical simulation/solver infrastructure;
- score coefficients require calibration/versioning;
- production catalog needs derived metric metadata;
- old docs/tasks/audits must be interpreted historically rather than rewritten as if the old rule never existed.

## Compatibility

The current M21 owner-approved 20x20 Hazard Bot remains valid and may use legacy EASY validation during that already-open vertical-slice audit cycle.

Historical tests that prove 20..59 engine capability remain valuable. Tests that assert dimension/color bands are eternal class identity must be migrated, not blindly deleted.

## Alternatives rejected

### Board size only

Rejected because it mostly predicts workload/duration and cannot represent compact structural difficulty.

### Color count only

Rejected because distribution, accessibility, topology, routes and slot options materially change difficulty.

### One scalar only

Rejected because challenge, duration and frustration can diverge dramatically.

### Pure adaptive difficulty per player

Not authorized. V1 uses deterministic campaign progression. Any later individualized adaptation requires a separate owner/privacy/product decision.

### One-shot random generation

Rejected for production scale. Evaluator-guided bounded search provides reproducibility, target fit and explicit rejection evidence.

## Source hierarchy

Exact current values live in:

- `data/config/level_progression_v1.json`
- `data/config/difficulty_score_model_v1.json`
- `data/config/level_generator_acceptance_v1.json`

Detailed rationale/measurement contracts live in docs 09–11.
