# M21-C001 Owner Scope Note — Difficulty V1

Status: **OWNER-LOCKED SCOPE GUARD — 2026-09-12**

The owner has approved a new project-wide Difficulty / Progression / Retention V1 design while M21-C001 V01 is active.

Canonical new design:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`

## M21 V01 scope remains unchanged

Do **not** expand M21-C001 V01 into the full Difficulty V1 runtime migration.

M21 still exists to prove this exact first real-art vertical slice:

```text
owner-approved 20x20 Hazard Bot source
→ canonical source validation / LevelData artifact
→ BoardState / BoardRenderer
→ five slots
→ production candidate/target/access/routing
→ Scrubbot dispatch/movement
→ authenticated ACTIVE→CLEARED transaction
→ full 400-cell completion
```

The approved 20x20 source remains valid.

The existing legacy `DifficultyRules` / `ProductionLevelValidator` may be used as the **M21 compatibility gate only**, because this approved asset already fits the legacy EASY constraints.

M21 must still satisfy its existing `CHATGPT_PROMPT_V01.md` and `CHATGPT_AUDIT_CRITERIA_V01.md`, including canonical C-ID local palette normalization and exact cell-color preservation.

## Specifically forbidden as M21 drive-by work

Do not, merely because the new owner decision now exists:

- redesign `scripts/data/difficulty_rules.gd` inside M21;
- redesign `scripts/data/production_level_validator.gd` inside M21;
- implement the new mathematical Difficulty Score engine inside M21;
- implement CampaignBuilder inside M21;
- implement the Level Factory solver/generator inside M21;
- rewrite root TASKS difficulty/LF roadmap sections inside the M21 implementation commit beyond lifecycle changes explicitly authorized by the active prompt;
- change the approved Hazard Bot dimensions/colors to demonstrate the new model.

Those are separate strict-audit migration packages described in:
`coordination/PROJECT_WIDE_DIFFICULTY_V1_MIGRATION_PLAN.md`.

## Interpretation rule

The new Difficulty V1 decision is current **design truth**, while legacy M21 validation behavior is temporary compatibility implementation truth.

Therefore:

- do not create new assertions claiming `20x20 => EASY` as a future design law;
- do not create new assertions claiming `5 colors => EASY` as a future design law;
- it is acceptable to assert that the approved M21 asset passes the currently installed legacy compatibility validator;
- record this distinction truthfully in `CLAUDE_LOG_V01.md` if the new owner decision is present when M21 executes.

M21 remains independently auditable and must not absorb unrelated Difficulty V1 implementation risk.
