# PROJECT-WIDE DIFFICULTY V1 CHANGE INDEX

Status: **ACTIVE OWNER DESIGN TRUTH — 2026-09-12**

This index records what changed immediately and what remains controlled implementation/migration debt. It prevents future agents from confusing historical runtime compatibility with current owner design truth.

## A. Current owner truth

Primary decision:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

Detailed design:
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`

Machine configuration:
- `data/config/level_progression_v1.json`
- `data/config/difficulty_score_model_v1.json`
- `data/config/level_generator_acceptance_v1.json`

Project migration roadmap:
- `coordination/PROJECT_WIDE_DIFFICULTY_V1_MIGRATION_PLAN.md`

## B. Rules now superseded as design truth

The following historical interpretations are no longer authoritative:

1. `EASY=20..29`, `MEDIUM=30..39`, `HARD=40..49`, `VERY_HARD=50..59` as player-facing class legality.
2. `EASY=3..5 colors`, `MEDIUM=6..7`, `HARD=8..9`, `VERY_HARD=10..12` as player-facing class legality.
3. Bigger board automatically means harder class.
4. More colors automatically means harder class.
5. Difficulty can be represented by one scalar without separately controlling time/load and frustration.
6. Campaign progression may be a simple increasing staircase.
7. Level Factory may generate one candidate and label it according to dimensions.

## C. Rules that remain locked

- variable-size logical board;
- current supported production envelope 20..59 per dimension, rectangular allowed, max 59x59;
- LevelData row-major logical cells;
- C01..C16 only for ACTIVE production artwork;
- ACTIVE source color / alpha 255;
- CLEARED alpha 0 and BG01 visible behind;
- local palette used-only, ascending canonical C-ID;
- five visible slots;
- raw candidate != reachable target;
- ACTIVE blockers / CLEARED-open access law;
- TargetSelector WHAT vs RoutingSystem HOW split;
- one Scrubbot per dispatch, no target = no spawn;
- no color carrying / no return to slot;
- M20 authenticated clearing transaction;
- owner-original source preservation;
- main runtime isolated from Level Factory/publisher code.

## D. Difficulty V1 rules now locked

- cadence repeats exactly: `E,E,M,E,H,E,E,M,E,VH`;
- global progression uses saturating `P(k)=1-exp(-k/20)`;
- lane formulas and slot modifiers from `level_progression_v1.json`;
- Challenge V1 weights W/C/A/U/B/R/S from `difficulty_score_model_v1.json`;
- Challenge, Session Load and Frustration Risk are separate axes;
- recovery after slots 3,5,8,10 is explicit campaign QA;
- novelty and recent-similarity are sequencing constraints;
- same-class levels become harder across campaign age without destroying class separation;
- no forced label outside target tolerance merely to fill a campaign slot;
- no hidden individualized dynamic difficulty authorized;
- initial clear-rate bands are calibratable hypotheses, not eternal constants.

## E. Files already aligned with Difficulty V1

- `CLAUDE.md`
- `docs/00_PROJECT_BRIEF.md`
- `docs/01_GAMEPLAY_SPEC.md`
- `docs/03_LEVEL_DATA_SPEC.md`
- `docs/04_ROADMAP.md`
- `docs/08_PIXEL_ART_PALETTE_RULES.md`
- `data/palettes/scrubbots_palette_v2.json`
- configs/docs listed in section A.

Historical pre-Difficulty-V1 operating manual preserved at:
- `docs/migration/legacy-task-trackers/CLAUDE_PRE_DIFFICULTY_V1_2026-09-12.md`

## F. Deliberately NOT changed mid-M21

These are implementation/migration debt, not current design authority:

### F1. `scripts/data/difficulty_rules.gd`

Still implements the legacy class-specific dimension bands.

Reason it is not hot-edited now:
- M21-C001 V01 is already in progress against an audited prompt/criteria set;
- the owner-approved 20x20 Hazard Bot is compatible with the legacy EASY gate;
- changing core validation underneath an active critical vertical slice would mix two risk domains and contaminate audit evidence.

Required future action:
- migrate to separate ProductionBoardEnvelope and cadence/difficulty concepts under a dedicated strict audit cycle.

### F2. `scripts/data/production_level_validator.gd`

Still delegates class-specific dimension legality to legacy DifficultyRules.

Required future action:
- production legality becomes global 20..59 envelope + canonical palette/source legality;
- campaign class comes from progression/target-fit analysis, not dimensions.

### F3. importer production preflight

M09 importer still uses legacy DifficultyRules for production difficulty dimension checks and first-seen palette ordering.

M21 explicitly normalizes the approved asset to canonical palette order without changing logical colors. Future general production importer/Factory path must migrate cleanly.

### F4. root `TASKS.md` historical rules/task wording

The Project Status block remains the live lifecycle tracker and currently truthfully points to active M21 work.

Historical sections still contain old class=dimension/color wording. The 2026-09-12 owner decision explicitly supersedes those rules until a governance-safe full tracker migration preserves every existing unfinished task/history while rewriting the relevant design sections and LF/M31/M32/M47/M48 task wording.

Do not treat the stale historical rule text as permission to override the newer owner decision.

### F5. older audit/docs evidence

Historical audit files and prior milestone logs remain immutable evidence. They are not rewritten retroactively. Statements inside them describe the rules under which those milestones were validated at the time.

## G. M21 rule

M21 continues as scoped.

The 20x20 Hazard Bot remains:
- owner-approved;
- valid first real-art engineering vertical slice;
- usable with the legacy EASY compatibility validator during M21 only.

Do not expand M21 into the complete Difficulty V1 runtime migration.
Do not infer future EASY sizing/color policy from the M21 asset.

## H. Next controlled implementation packages

Recommended strict-audit packages after/around M21 without mixing evidence:

1. `DV1-00` governance-safe root TASKS migration.
2. `DV1-01` production envelope/palette legality runtime migration.
3. `DV1-02` deterministic progression service.
4. `DV1-03` LevelMetrics schema.
5. Factory pure simulation + solver.
6. seven metric analyzers.
7. Challenge/Session Load/Frustration engines.
8. novelty/similarity.
9. acceptance evaluator.
10. generator/mutation targeting.
11. CampaignBuilder.
12. internal calibration.
13. M30/M31/M32/M47/M48 integration.

Exact detailed workstreams are in `PROJECT_WIDE_DIFFICULTY_V1_MIGRATION_PLAN.md`.

## I. Precedence rule

For difficulty/progression/generation questions:

1. newest explicit owner instruction;
2. `OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`;
3. machine configs for exact V1 values;
4. docs 09–11;
5. updated subsystem docs;
6. active prompt/criteria for current implementation scope;
7. historical legacy rules only as compatibility/migration evidence.

If a future agent sees a contradiction, it must not silently choose the older dimension/color-band rule.
