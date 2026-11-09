# Review round 1 - 134-ranks-weekly (SB-M43-131..133)

Tests (Godot 4.7.2 headless, worktree, exit 0 each): m43_ranks_weekly 7/7, m43_personal_ranks 8/8, m56_analytics_taxonomy 27/27, m40_save_system PASS. git diff --check clean.

## Checks
- Rule: all-time = progression.current_level() (frontier); weekly = +1 per committed first-clear WON. Hook is in _meta_terminal(true), reached only when FirstClearTransaction.commit returned ok (record_win rejects replays/stale/duplicates, and _economy_terminal_done latches), so no double count on fast taps; the count is saved at the terminal save boundary, so relaunch cannot recount. Booster question: a win achieved with a booster counts once; the booster adds nothing beyond the win itself, purchases/SB/hearts add nothing. This is consistent with "nothing bought counts" (the level completion is what counts, not the purchase). No change needed.
- Monday UTC: week_start = ts - posmod(ts-4d, 7d), correct (epoch Thursday). Rollback: win before stored week is not counted and never rewrites the stored week; tab shows 0 while behind, count returns afterwards.
- Save: `ranks` section absent = fresh (old saves 0); present = strict (version, int/integral float, Monday-aligned week, week/count coupling); bad section fails whole economy import with rollback.
- No fake players; "You"/"Sen"; offline note honest. Unlock L40 untouched (personal_ranks passes). Analytics band is int, table is enum-like string. CI guard and docs updated per diff.
- Layout: autowrap off on right-side labels, expand-fill on name labels; TR strings are short enough, no truncation concern seen in code.

## Notes (non-blocking)
- TR has no RANKS_YOU_WEEKLY_ONE key (Turkish has no plural form after a number; tn falls back to the base key). Fine.
- The worktree shows .import churn after --import; not committed, ignore.
- m60 gate 005 re-run is deferred until job 132 merges, as builder noted.

## Must-fix
None.

VERDICT: PASS
