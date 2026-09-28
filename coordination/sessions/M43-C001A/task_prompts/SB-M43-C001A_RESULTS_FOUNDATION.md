# M43-C001A — RESULTS FOUNDATION + VISUAL MASTER READINESS

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Tracked task scope

This cycle advances the unblocked foundation of M43-C001, primarily:

- SB-M43-001 Result model
- SB-M43-003 streak/reward presentation data contract (not final styling)
- SB-M43-004 committed first-clear/streak/Bot Part/Collection reward receipt binding
- SB-M43-005 Continue
- SB-M43-007 No double reward
- SB-M43-008 Rapid-tap protection
- SB-M43-012 Gift Meter milestone handoff data
- SB-M43-013 downstream ceremony handoff contract where authoritative truth already exists
- SB-M43-014 Continue advances exactly once

Also perform readiness analysis for:
- SB-M43-002 Completion UI
- SB-M43-009 canonical Victory/Results visual master
- SB-M43-010 ordered reward celebration
- SB-M43-006 / 011 Replay

Do **not** claim those gated visual/replay rows complete in this cycle unless an existing owner authority fully resolves them.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M55-C002/CHATGPT_AUDIT_V01.md`
4. `coordination/OWNER_PLAYER_EXPERIENCE_SURFACE_PROGRAM_V01.md`
5. `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md`
6. `coordination/OWNER_ECONOMY_REWARDS_V01.md`
7. `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`
8. `docs/15_PLAYER_EXPERIENCE_UI_ARCHITECTURE.md`
9. existing `scripts/ui/results_screen.gd`, `scripts/app/main.gd`, navigation/results tests
10. existing victory/reward assets under `assets/ui/final/popups/victory/**`, `assets/ui/final/rewards/**`, common reward frames
11. `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`

Do NOT edit root `TASKS.md`.

## Important current-state fact

A minimal M42 `ResultsScreen` already exists and routes WON/LOST/Home/Continue/Retry.

Do not throw it away blindly.

M43 must evolve it from a narrow terminal shell into a truthful player-facing Results system while preserving the existing navigation and authoritative economy/save boundaries.

## Core architecture rule

**Authoritative grants happen before presentation. Results presents committed truth; Results never grants the same reward a second time.**

The current gameplay terminal path already commits economy/save before navigation enters Results. Preserve that ordering.

Create a durable/read-only Results presentation model or receipt contract that lets Results show exactly what was committed for the terminal event.

The model must be derived from authoritative transaction/service outputs, not by recomputing rewards from UI guesses.

At minimum, when available from canonical services/transactions, expose:
- terminal status / level / attempt;
- first-clear vs replay/already-cleared truth;
- first-clear SB delta;
- Win Streak SB delta / resulting streak;
- Bot Parts delta;
- Gift Meter progress and any newly queued milestone;
- Collection/card/pack reward facts actually committed;
- robot/set/master/feature/world follow-up events only when authoritative committed truth exists;
- next-frontier availability.

Do not fabricate a reward/event merely because a future M43 surface is planned.

## Reward idempotency

Results must never call `RewardGrantService` to re-grant the terminal receipt.

Prove:
- duplicate terminal callback;
- repeated Results open/refresh;
- repeated Continue tap;
- stale Continue callback;
cannot duplicate SB, Bot Parts, cards, Gift Meter rewards, progression or route transitions.

## Continue

WON Continue:
- advances/launches the exact canonical current frontier;
- exactly one accepted transition/host launch;
- rapid taps after the first commit are rejected/no-op;
- Level 10 -> frontier 11 CONTENT_MISSING remains a clean unavailable Continue state for the current content pack.

LOST Retry remains M30 transaction-safe and must not be accidentally changed by this Results-foundation work.

## Replay — OWNER GATE

Do **not** invent Replay policy.

SB-M43-006 says "Replay if approved"; no current owner approval was found for a shipping Replay control in the Results surface.

In this cycle:
- inspect existing progression/reward semantics needed for a safe replay path;
- document the exact owner decision required;
- do not add a production Replay button or new replay economy rule.

## Visual-master gate

The repo already contains a substantial victory asset family:
- `assets/ui/final/popups/victory/victory_emblem.png`
- `reward_glow.png`
- `continue_button_frame.png`
- Scrubby victory pose
- nine additional robot victory poses
- reward bundle assets / popup reward frame

But `PLAYER_EXPERIENCE_ASSET_MANIFEST.json` still marks `victory_results` as `MASTER_REQUIRED`.

Therefore:

1. inventory all existing Results/Victory assets;
2. identify which can compose the final Results master;
3. identify genuinely missing component art, if any;
4. create a written **visual-master readiness/spec**, not a fake final approval;
5. do not overwrite/regenerate approved existing assets;
6. do not promote `victory_results` to MASTER_OWNER_APPROVED;
7. do not finalize production styling/animation sequence before owner visual approval.

A technical/wireframe-safe Results shell may bind the new live model for testing, but final visual polish must remain gated.

## Ordered celebration

Do not finalize the visual choreography yet.

You may define a deterministic, data-only reveal queue/order contract so authoritative rewards can later animate in a short sequence.

Presentation must never delay or own the grant transaction.

Reduced Effects compatibility must remain possible.

## Tests

Add focused production-path tests for:
- result receipt/model exactly matching committed terminal transaction facts;
- first clear vs already-cleared behavior;
- duplicate terminal/open/refresh no additional grants;
- rapid Continue taps -> one transition/one next host;
- Level 10 no-next-content Continue disabled/no mutation;
- Gift Meter milestone handoff truth if crossed;
- follow-up ceremony queue contains only authoritative committed events;
- LOST Retry regression unchanged;
- existing M42 navigation/results behavior preserved.

Run relevant:
- M30 completion/retry;
- M39 economy/rewards;
- M40 save;
- M42 navigation/results;
- M52 First 10;
- M55 relevant regression;
- root suite;
- `git diff --check`.

## Outputs

Create:
- `coordination/sessions/M43-C001A/RESULTS_FOUNDATION_MATRIX_V01.md`
- `coordination/sessions/M43-C001A/RESULTS_VISUAL_MASTER_READINESS_V01.md`
- `coordination/sessions/M43-C001A/CLAUDE_LOG_V01.md`

The readiness file must explicitly state:
- existing reusable assets;
- missing master/composition decisions;
- Replay owner decision required;
- what must be owner-approved before final Results visual implementation.

## Scope locks

Do not:
- implement M43-C002+;
- generate/overwrite visual assets;
- change First 10 level content/supply/difficulty;
- change Heart or 2x economy;
- invent replay rewards;
- edit TASKS.md.

## Handoff

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M43-C001A RESULTS FOUNDATION`

Do not edit TASKS.md.
