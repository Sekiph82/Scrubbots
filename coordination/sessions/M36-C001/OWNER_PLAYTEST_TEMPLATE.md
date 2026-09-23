# M36 Difficulty V1 — Owner Playtest Report Template (SB-M36-005)

Status: OWNER_REQUIRED / PLAYTEST_GATE. Machine proxies and the deterministic
calibration matrix are complete; human fairness calibration is not fabricated.

Owner fills one row per playtested level. Machine target/vector come from the
Difficulty V1 services; the owner records felt experience.

| level | class (cadence) | machine target D | felt too easy / fair / too hard | perceived main friction (A/U/B/R/S) | session felt long? | frustration notes |
|------:|-----------------|-----------------:|---------------------------------|-------------------------------------|--------------------|-------------------|
| 1     | EASY            |                  |                                 |                                     |                    |                   |
| 5     | HARD            |                  |                                 |                                     |                    |                   |
| 10    | VERY_HARD       |                  |                                 |                                     |                    |                   |
| 11    | EASY            |                  |                                 |                                     |                    |                   |

## Machine reference (deterministic, from `DifficultyProgressionV1`)

Run to regenerate exact target numbers:
```
godot --headless --path . -s res://tests/m36_difficulty_v1.gd
```
The `[target curve]` section prints target D for representative levels.

## Calibration questions the owner answers on-device

1. Does the cadence *feel* like relief → rise → tension → recovery → boss?
2. Is the level-10 boss meaningfully harder than surrounding relief?
3. Does a later-cycle EASY (e.g. 311) feel richer than an early EASY (11) while
   still reading as relief?
4. Are any "hard" levels actually just *long* (Session Load) rather than
   cognitively hard (Challenge)? Note them — that is a vector-mislabel, not a
   difficulty bug.
5. Any level that felt unfair/frustrating rather than hard? (Frustration Risk.)

## What Claude did NOT do
No human calibration PASS is claimed. No dynamic per-player difficulty. No
analytics SDK. The owner owns the calibration verdict.
