# M17-C002 — Promote Owner-Selected Routing to Production (V01)

Status: **ISSUED**

Owner decision:
`coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md`

## Goal

Promote the owner-selected M17 routing direction from experimental prototype code into production routing code.

Locked owner choice:
- movement language = **Organized/curved**
- planner backbone = **Grid-aware deterministic**
- Direct = debug/baseline only, NOT production
- reduce overly aggressive diagonal shortcuts
- keep curves controlled/readable
- never sacrifice route validity for aesthetics

## Required work

1. Safely sync main and preserve all owner work.
2. Read the owner decision, M16 contract/ADR-024, M17 audit/comparison, and this prompt.
3. Create production routing implementation outside `prototypes/`.
4. Reuse the selected architecture:
   - deterministic grid-aware planner establishes valid reachability/path
   - organized/curved post-process improves movement language
   - every final segment must pass shared access truth / RouteValidator
5. Keep target identity fixed. Never retarget.
6. Keep Direct only in debug/prototype tooling.
7. Use conservative production defaults for shortcut/rounding so dense routes are less chaotic than the experimental Organized default.
8. Add tests proving:
   - production route derives from a valid grid route
   - blocked target -> no route
   - opened-after-clear -> same target routes
   - no BoardState/ReservationState mutation
   - deterministic repeated points
   - no invalid diagonal shortcut accepted
   - production defaults are more conservative than M17 experimental defaults
   - 59x59 and rectangular VH coverage
   - full Godot regression suite passes
9. Update current-law docs and add the next ADR recording the owner-selected production movement language.
10. Keep the M17 debug lab/prototypes available for diagnostics; do not delete comparison evidence.

## Out of scope

Do NOT implement:
- M18 ScrubbotAgent
- movement playback
- Dispatcher
- spawning
- arrival logic
- vertical slice
- crossing/congestion optimization system beyond conservative route-shape defaults

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- any CHATGPT audit file

## Output

Write:
`coordination/sessions/M17-C002/CLAUDE_LOG_V01.md`

Run:
- `godot --version`
- full headless test suite
- `git diff --check`

Commit/push safely, return `AWAITING_AUDIT`, then stop.
