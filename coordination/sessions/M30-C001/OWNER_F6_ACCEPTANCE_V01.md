# M30-C001 — Owner F6 Acceptance V01

Date: 2026-09-19  
Milestone: M30 — Win/Lose Rules  
Scene: `res://scenes/debug/m30_win_lose_playtest.tscn`

## Owner-observed runtime results

The owner manually executed the M30 F6 production playtest and accepted the following behavior:

1. AUTO-SOLVE completed the board and reached `WON`.
2. RETRY after WON restored the full level to `PLAYING`.
3. RETRY restored gameplay at `1x`.
4. DEADLOCK DEMO intentionally produced a partially uncleared board and reached `LOST`.
5. The visible deadlock state retained unresolved board cells / waiting work, as expected for a proven deadlock rather than a completed board.
6. RETRY from LOST restored the puzzle to the initial `PLAYING` state at `1x`.
7. Owner reported AUTO-SOLVE and RETRY functioning correctly and reported no concrete stale-state or terminal-latch regression.

The deadlock-demo result is accepted specifically because M30's contract is to latch LOST only on a real M27 DEADLOCK at quiescence; a LOST board is not expected to be visually cleared.

## Owner verdict

`OWNER_F6_PASS / M30 ACCEPTED`

No further M30 hardening loop is authorized without a concrete later runtime regression.
