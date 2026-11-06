# Round 1 review: 111-comeback-catchup-track

Tests (local, headless): m43_master_c011_c014 PASS 29/29; m43_c001a_results_foundation PASS 11/11; m39_v02_atomicity PASS. git diff --check clean. project.godot restored.

Checks
- Values 50/75/100 SB + 1 Bot Part: existing currencies only, config v2, documented as Claude proposal (OWNER_ECONOMY §9.3). No new currency, no timer/energy/paid retry.
- Grant path: only ReturnService.on_first_clear_win, called from _meta_terminal inside the branch where FirstClearTransaction succeeded (replay/loss/retry/purchase never reach it). tx catchup:<track window>:<step> via RewardGrantService; claim_catchup treats already_applied as ok, so relaunch/import does not regrant. Wins capped; claimed set prevents repeats.
- Expiry/rollback: expires at started+7d or when now < high-water; on_first_clear_win returns [] when expired. No stacking: a new window only opens a track if none exists or the current is expired/complete.
- Host change: runs after the first-clear commit, inside the existing _economy_terminal_done latch (duplicate/fast-tap terminal cannot rerun); no change to win/lose evaluation, timing, routing.
- Receipt: catchup_sb/bot_parts added to reconciliation; default arg keeps other callers valid.
- Migration: v1 had empty steps, so no old-shape catchup state ever existed; the new "started" validation cannot reject real older saves.
- UI: native Controls, static pips, no economy mutation from UI.
- Tests assert real properties (tx applied, wallet, reconciliation, expiry, no stacking, relaunch).

Non-blocking
- grant_failed leaves the step claimable on a later win; acceptable.

Must-fix: none.

VERDICT: PASS
