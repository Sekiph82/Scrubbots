# 04 — Roadmap

Status: **updated for Difficulty / Progression / Retention V1 — 2026-09-12**

Repository-root `TASKS.md` remains the canonical live task tracker. This document describes the architecture/dependency roadmap and the new cross-project Difficulty V1 program.

Owner decision:
`coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

Core specs:
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`

## 1. Completed gameplay foundation

The project already has the major low-level systems needed by the new model:

- variable-size LevelData / BoardState;
- exact pixel-art importer tooling;
- batched BoardRenderer with ACTIVE/CLEARED semantics;
- five-slot data system;
- color candidates;
- reservations;
- TargetSelector;
- production reachability/access truth;
- production routing;
- ScrubbotAgent;
- dispatcher;
- complete M20 clearing vertical slice.

This foundation is deliberately preserved. Difficulty V1 does not require rewriting gameplay truth.

## 2. Current milestone — M21 real-art vertical slice

M21 continues with the owner-approved 20x20 Hazard Bot.

M21 remains intentionally narrow:

```text
real owner-approved artwork
→ exact/canonical LevelData
→ BoardState
→ renderer
→ five slots
→ production target/access/routing
→ Scrubbots
→ ACTIVE→CLEARED
→ complete playable real-art vertical slice
```

The current legacy EASY dimension/color validator may be used as an M21 compatibility gate only. M21 is not evidence that future EASY content must be 20x20 or use five colors.

Do not destabilize M21 by mixing the entire Difficulty V1 runtime migration into its active implementation cycle.

## 3. Cross-project Difficulty V1 program — effective now

Design truth changes immediately:

- exact cadence: `E,E,M,E,H,E,E,M,E,VH`;
- later levels within the same class grow through a saturating progression curve;
- board size no longer defines difficulty;
- color count no longer defines difficulty;
- Challenge Score, Session Load and Frustration Risk are separate;
- retention/recovery/novelty become first-class campaign constraints;
- Level Factory becomes evaluator-guided rather than blind random generation.

Runtime/content validators migrate through audited milestones rather than through an unreviewed global rewrite.

## 4. Main-game milestone impact

### M21 — First Real-Art Vertical Slice

No scope expansion. Preserve the approved 20x20 engineering proof.

### M22–M24 — Production gameplay UI/touch

Add one presentation requirement: gameplay layout must remain readable across compact/standard/large logical boards because dimensions no longer map to class.

Do not make UI assumptions such as "Very Hard always has tiny 50..59 cells".

### M25 — Win/Lose Rules

Still owner-gated. Difficulty V1 must not invent timer/move-limit/failure mechanics.

When win/lose rules are chosen, solver/legal-move adapters must be updated without changing the Difficulty V1 separation of challenge/load/frustration.

### M30 — Level Catalog

Catalog must eventually store/resolve:

- stable level ID;
- campaign number/order;
- cadence slot/class;
- Challenge Score + model version;
- challenge vector;
- Session Load;
- Frustration Risk;
- novelty signature/version;
- source/provenance hashes;
- solver/generator versions.

Catalog validation must no longer classify difficulty from dimensions alone.

### M31 — Difficulty Intelligence V1

M31 is upgraded from a small matrix task into the main-game Difficulty V1 integration milestone.

Required implementation themes:

1. versioned progression config loader;
2. exact ten-level cadence calculation;
3. target score calculation;
4. versioned LevelMetrics schema;
5. W/C/A/U/B/R/S metric contracts;
6. Challenge Score calculation;
7. Session Load calculation;
8. provisional Frustration Risk contract;
9. dimension/color class-gate migration;
10. regression fixtures proving compact hard and larger easy cases;
11. M21 compatibility preserved;
12. legacy `DifficultyRules` migration without breaking generic LevelData/BoardState.

### M32 — Campaign Progression / Sequencing

M32 is no longer a blank progression design gate. The owner has selected the V1 cadence/curve.

Implementation themes:

- `level -> cadence slot/class`;
- `level -> TargetChallenge`;
- recovery validation;
- accepted-candidate selection;
- challenge-vector diversity;
- novelty/recent-similarity rules;
- Session Load / Frustration budgets;
- deterministic campaign-build provenance;
- replay/reordering without regenerating level data.

Unlock/replay UI rules that are unrelated to difficulty may remain owner-gated where necessary.

### M40 — Debug Tooling

Add display of:

- target vs actual Challenge Score;
- W/C/A/U/B/R/S;
- Session Load;
- Frustration Risk;
- cadence slot/class;
- progression/model versions;
- unlock/frontier diagnostics where available.

### M41/M42 — Performance / real devices

Performance matrices must sample board size independently from difficulty class.

Required representative cases include:

- compact high-challenge;
- standard low/medium/high challenge;
- large low-cognitive/high-load;
- exceptional 49..59 readability/load cases.

59x59 remains a capability stress ceiling, not the default Very Hard format.

### M47 — Production Content Scale-Up

Production scale-up becomes Factory-driven accepted-pool production:

```text
request campaign envelopes
→ generate many candidates
→ reject invalid/unsolved/bad-fit output
→ accepted candidate pools
→ human/owner review where required
→ CampaignBuilder
→ production handoff
```

Success is measured in **accepted campaign-fit levels**, not raw generated count.

### M48 — Level QA

Every level must validate:

- legal data/palette;
- canonical solvability;
- target Challenge fit;
- challenge vector;
- Session Load;
- Frustration Risk;
- novelty/similarity;
- mobile readability;
- performance;
- campaign recovery rules;
- provenance/model versions.

### M49/M50 — Regression / chaos

Add Difficulty V1 property/regression tests and long-campaign sequencing tests. Include levels 1/10/11, 111, 300/310/311 and 1000/1001/1010 in progression regression.

### M51 — Analytics

Analytics remains owner-gated.

Difficulty V1 must work without an external analytics SDK. If analytics is later approved, aggregate player results may calibrate V2+ but no hidden individualized dynamic difficulty is authorized by V1.

## 5. Level Factory roadmap impact

### LF00 — isolation/bootstrap

Unchanged. Factory remains a separate Godot project.

### LF01 — deterministic config/seeds

Update assumptions:

- dimensions selected from global production envelope, not class band;
- request contains target score/load/risk/novelty envelope;
- progression/score model versions recorded.

### LF02 — candidate generator

Generation becomes multi-objective and evaluator-guided. ART_FIRST, PUZZLE_FIRST and HYBRID modes remain.

### LF03 — solver/simulation

This is now a critical dependency for Difficulty V1, not optional research.

Provide canonical pure simulation, solvability verdicts, search diagnostics and reproducibility.

### LF04 — difficulty intelligence

Implement full V1:

- W/C/A/U/B/R/S;
- scalar Challenge;
- challenge vector/profile;
- Session Load;
- provisional Frustration Risk;
- novelty signature;
- model provenance.

### LF05 — Factory QA

Replace historical class-by-dimension/color checks with new production legality + target-fit gates.

Keep 20..59 engine envelope and C01..C16 palette. Use 3..12 global used-color envelope under V1.

### LF06 — human editor

Expose target challenge, measured vector, load/risk, frontier/unlock diagnostics, novelty/similarity and exact rejection reasons.

### LF07 — mutation / targeting

Mutation jointly targets score/load/risk/novelty. Never silently mutate owner-original art.

### LF08 — batch production

Request **accepted counts**, maintain rejection statistics and resumable jobs. Produce candidate pools broad enough for CampaignBuilder variety.

### LF09 — advanced research

Evolutionary/telemetry-calibrated methods remain experimental until the deterministic V1 pipeline is proven.

### LF10 — CampaignBuilder

The progression design gate is now resolved at the design level.

CampaignBuilder implements exact cadence + progression target + retention constraints after solver/metrics dependencies exist.

## 6. Recommended implementation dependency chain

```text
CURRENT M21 vertical slice
        │
        ├───────────── design/config V1 already locked now
        │
        ▼
Versioned progression + metric schemas
        ↓
Pure canonical Factory simulation adapter
        ↓
Oracle solver + diagnostics
        ↓
Difficulty analyzers W/C/A/U/B/R/S
        ↓
Session Load + provisional Frustration
        ↓
Candidate acceptance evaluator
        ↓
Constraint/hybrid generator
        ↓
Safe mutation targeting
        ↓
Novelty/signature engine
        ↓
Accepted candidate pools
        ↓
CampaignBuilder
        ↓
Internal calibration/playtest
        ↓
M30/M47/M48 production integration
        ↓
Optional future telemetry calibration (owner gate)
```

The design/config work does **not** need to wait for M21. Runtime migration and solver implementation remain independently auditable work packages.

## 7. Content-production principle

Do not generate a huge library under the obsolete dimension=difficulty model while Difficulty V1 infrastructure is unfinished.

It is acceptable to create art experiments and engineering fixtures, but scaled production content should pass the new evaluator/QA pipeline.

## 8. Retention north star

The campaign should feel like a sequence of controlled waves:

```text
flow
→ confidence
→ tension
→ recovery
→ mini-boss
→ strong recovery
→ novelty
→ tension
→ confidence
→ boss
→ relief
```

Later campaign cycles become more sophisticated, not simply larger and longer.

## 9. Source-of-truth hierarchy for Difficulty V1

For difficulty/progression/retention questions, use:

1. explicit latest owner decision;
2. `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`;
3. `data/config/level_progression_v1.json` and `data/config/difficulty_score_model_v1.json`;
4. docs 09–11;
5. updated gameplay/project docs;
6. legacy dimension-band text only as migration history/compatibility evidence.

Where root `TASKS.md` or `CLAUDE.md` still contains the historical class=dimension/color wording, the explicit 2026-09-12 owner decision supersedes that wording until the controlled tracker/manual migration lands.
