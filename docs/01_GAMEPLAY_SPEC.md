# 01 — Gameplay Specification

Status tags:

- `[LOCKED]` — owner-specified. Do not reinterpret or silently change.
- `[TO BE DESIGNED]` — intentionally unresolved.
- `[CALIBRATABLE]` — versioned tuning value that may change only through explicit model/version updates and evidence.

Canonical difficulty/progression owner decision:
`coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

## Board `[LOCKED — variable-size engine; Difficulty V1 owner update 2026-09-12]`

- Logical grid is **variable-size**: width and height come from level data.
- Cell count is always `width * height`, derived rather than hard-coded.
- Generic gameplay never assumes `width == height`.
- Current production-capable envelope is width/height **20..59**, rectangular boards allowed, maximum **59x59 = 3,481 cells**.
- These dimensions are an engine/content envelope, **not player-facing difficulty bands**.
- `TEST`/development fixtures may exist outside the production envelope and must never enter production content/catalog.
- Grid dimensions are logical/data units, independent of physical phone pixels or zoom.
- Each logical cell has at minimum: index, x, y, color id and lifecycle state.

### Board-size usage guidance `[LOCKED V1]`

- 20..23: compact / intro / engineering / short-session content;
- 24..40: preferred standard mobile-content sweet spot;
- 41..48: large-content range; Session Load review required;
- 49..59: exceptional/showcase/challenge-sized range; strict Session Load + phone readability evidence required.

A compact board may be VERY_HARD. A larger board may be EASY. Board size contributes to Workload and Session Load but does not assign the difficulty class.

The old table `EASY=20..29, MEDIUM=30..39, HARD=40..49, VERY_HARD=50..59` is retained only as historical/legacy validator behavior until controlled migration. It is superseded as design truth by the 2026-09-12 owner decision.

## Global production pixel-art palette `[LOCKED]`

Only C01..C16 from `data/palettes/scrubbots_palette_v2.json` are legal production logical artwork colors. C16 Pure Black is a normal logical artwork color.

Under Difficulty V1:

- production artwork normally uses **3..12 distinct canonical logical colors**;
- distinct color count no longer directly defines EASY/MEDIUM/HARD/VERY_HARD;
- color count + color-distribution entropy contribute to Challenge Score;
- local LevelData palette contains only actually used C01..C16 entries, ordered by ascending global C-ID;
- CLEARED alpha-0 transparency, BG01 and presentation grid/border colors are excluded.

The historical class-specific color bands `3–5 / 6–7 / 8–9 / 10–12` are superseded as class-legality gates.

## ACTIVE / CLEARED cell lifecycle `[LOCKED — ADR-019]`

Every logical artwork pixel begins **ACTIVE** and may become **CLEARED**.

**ACTIVE**:

- present on the board;
- exact original source palette color;
- opaque;
- raw color candidate;
- occupies/blocks access space except when it is the assigned final target.

**CLEARED**:

- no longer visually present;
- alpha 0;
- exposes the gameplay background through transparency;
- no longer a color candidate;
- becomes open/free access space.

Production background is **BG01 Midnight Slate `#202533`**. BG01 is not C01..C16, not a logical LevelData cell color and does not contribute to artwork color statistics.

No DIRTY/CLEAN/grime/reveal model exists. The visible artwork itself is removed.

## Color candidate vs reachable target `[LOCKED]`

A matching color is not enough to dispatch a Scrubbot.

A raw candidate must be valid, ACTIVE, matching-color and not excluded/reserved.

A final target must additionally be reachable/targetable under canonical access semantics:

- non-target ACTIVE cells block;
- CLEARED cells/open background are traversable;
- outside-board free space is open;
- the assigned ACTIVE target can be entered only as the final arrival endpoint.

A fully enclosed matching-color ACTIVE cell remains untargetable until previous clears create legal access.

`TargetSelector` decides WHAT target. `RoutingSystem` decides HOW to reach the already-assigned target. Never merge those responsibilities.

Production movement is the owner-selected deterministic grid-aware backbone with organized/curved validity-preserving post-process (ADR-025). Direct straight routing remains debug/baseline only.

## Display/readability `[LOCKED principle]`

Logical artwork pixels are not physical device pixels. `BoardRenderer` scales the logical image to the available gameplay area using crisp nearest filtering.

Therefore a 20x20 source may occupy a large region of the phone screen. Conversely, high logical dimensions reduce physical cell size and require mobile readability QA.

High-resolution support must never be interpreted as permission to make every HARD/VERY_HARD level large.

## Slots `[LOCKED]`

- Exactly **5** slots are active in the primary gameplay presentation.
- Each slot corresponds to a color/robot type.
- The player interacts with slots to dispatch Scrubbots.
- Future queue/cooldown/stack mechanics are not implied by Difficulty V1 and may not be invented merely to raise a score.

## Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot leaves only after a valid reachable matching target is assigned/reserved.
- It visually travels from slot origin to that target.
- On arrival the target becomes CLEARED, candidate/access truth updates and reservation resolves.
- The Scrubbot then disappears/finishes.
- It does not carry the pixel color.
- It does not return to its slot.

## Target selection vs routing `[LOCKED architecture]`

`TargetSelector` answers WHAT.
`RoutingSystem` answers HOW.

Routes operate in board-local cell units, not physical screen pixels. Routing never retargets after failure and never silently calls TargetSelector.

Production implementation:

- `scripts/gameplay/routing/production_access_query.gd`
- `scripts/gameplay/routing/production_routing_system.gd`

## Difficulty / progression / retention `[LOCKED V1 — owner decision 2026-09-12]`

Difficulty is measured, not inferred solely from board dimensions.

### Fixed ten-level cadence

Every ten-level block repeats exactly:

```text
1  EASY
2  EASY
3  MEDIUM
4  EASY
5  HARD
6  EASY
7  EASY
8  MEDIUM
9  EASY
10 VERY_HARD
```

This cadence repeats indefinitely.

### Global progression

For level `n >= 1`:

```text
slot  = ((n - 1) mod 10) + 1
k     = floor((n - 1) / 10)
P(k)  = 1 - exp(-k / 20)
```

Lane targets:

```text
EASY       = 20 + 14P
MEDIUM     = 40 + 13P
HARD       = 58 + 13P
VERY_HARD  = 76 + 12P
```

Slot modifiers:

```text
1:+0, 2:+2, 3:+0, 4:-1, 5:+0,
6:-2, 7:+1, 8:+2, 9:-1, 10:+0
```

Thus a level-311 EASY is meaningfully harder than level-11 EASY while remaining a recovery/flow lane relative to local peaks.

Examples:

- Level 11 EASY ≈ 20.68
- Level 111 EASY ≈ 25.92
- Level 311 EASY ≈ 31.03
- Level 310 VERY_HARD ≈ 85.32

Machine config: `data/config/level_progression_v1.json`.

### Challenge Score

Each candidate receives a 0..100 structural Challenge Score:

```text
D = 100 * (
    0.10 W workload
  + 0.15 C color complexity
  + 0.20 A accessibility scarcity
  + 0.20 U unlock depth
  + 0.15 B bottleneck pressure
  + 0.10 R route complexity
  + 0.10 S slot/color pressure
)
```

All components are normalized/versioned. Full measurement contracts:
`docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`.

### Session Load

Session Load is separate from Challenge Score. It estimates attempt burden from actions, cumulative route time and decision count.

A level may be:

- long but easy;
- short but very hard;
- moderate challenge but too exhausting.

Board size contributes much more strongly to Session Load than to Challenge Score.

### Frustration Risk

Frustration Risk separately estimates retry burden, session overrun, late failure and opaque/brittle choice pressure.

A VERY_HARD level is not good merely because few players can beat it. Fairness and recovery remain first-class goals.

### Initial class tuning targets `[CALIBRATABLE]`

| Class | First-attempt completion target |
|---|---:|
| EASY | 85..95% |
| MEDIUM | 70..85% |
| HARD | 55..70% |
| VERY_HARD | 40..60% |

These are V1 tuning hypotheses, not eternal constants.

### Recovery rhythm `[LOCKED intent]`

- slot 4 recovers from slot 3;
- slot 6 strongly recovers from slot 5;
- slot 9 recovers from slot 8;
- next-cycle slot 1 strongly recovers from slot 10.

Campaign QA checks actual measured score/load/risk, not labels alone.

### Retention `[LOCKED design principle]`

Player retention should come from fair mastery, recovery, novelty, variety and satisfying flow, not endless difficulty escalation.

Campaign sequencing must consider:

- novelty target;
- recent-level similarity;
- challenge-vector diversity;
- Session Load caps;
- Frustration Risk caps;
- avoidance of repeated long/high-friction levels;
- boss/recovery contrast.

No hidden per-player dynamic difficulty is authorized by V1.

## Level Factory relationship `[LOCKED architecture]`

The Level Factory uses evaluator-guided generation:

```text
target envelope
→ candidate generation
→ legality validation
→ canonical solver/simulation
→ metric extraction
→ accept / mutate / reject
→ accepted candidate pool
→ CampaignBuilder sequencing
```

The Factory does not force class by choosing a board-size band.

Generator creates candidates; evaluator measures; QA accepts/rejects; CampaignBuilder orders accepted candidates. Campaign reordering does not mutate level data.

Full architecture: `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`.

Calibration/QA: `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`.

## M21 compatibility note

The owner-approved 20x20 Hazard Bot remains the first real-art vertical-slice asset. During M21 it may pass through the legacy EASY dimension/color validator strictly as a compatibility gate.

M21 must not be used as evidence that all future EASY levels must be 20x20 or five-color.

## Win / lose condition `[TO BE DESIGNED]`

The general concept is to clear the board, but exact win/lose conditions such as timer, move limits, stuck-state handling or partial-clear thresholds remain owner-gated until the relevant milestone.

Difficulty V1 does not silently invent a fail mechanic.

## Consecutive win-streak reward mapping `[LOCKED]`

| Consecutive wins | Reward |
|---|---:|
| 1 | 1 |
| 2 | 5 |
| 3 | 10 |
| 4 | 25 |
| 5 or more | 100 |

This maps consecutive-win count to reward. Do not reinterpret `1,5,10,25` as thresholds.

Economy around this reward remains `[TO BE DESIGNED]`.

## Detailed economy / shop / monetization `[TO BE DESIGNED]`

Not authorized here. Difficulty/retention design does not authorize ads, energy systems, paid retries, dynamic monetization walls or failure manipulation.
