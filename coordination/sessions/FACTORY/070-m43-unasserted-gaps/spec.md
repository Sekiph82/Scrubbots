# M43 unasserted gaps (SB-M43-134, 143, R12-003, 165, 166)

> Feature: Close the test-evidence gaps that factory 065 found. Add real assertions against existing behavior in the existing M43 master suites. Fix a behavior only if a small, in-design bug turns up. Tick only the items whose full text is now proven.

Mostly tests-only. Assertions go into existing cases of `tests/m43_master_c010_meta.gd` and `tests/m43_master_c011_c014.gd`, so the case ledgers (12/12, 28/28) and the CI exact-summary guards stay the same. No new art, no UI economy mutation, no new currency.

## Acceptance criteria
1. 134: in the c010 suite, the EVENTS badge (`HomeBadges.compute` plus the Home `NavBadge_events`) is 0 while an event is active with nothing claimable, 1 once a milestone becomes claimable, and back to 0 after the claim.
2. 143: c02 asserts on the real comeback popup that the Gift / Tasks / Events lines appear with the real counts when that state is ready, are absent when it is not, and that opening the summary grants nothing.
3. R12-003: c04 asserts the expiry boundary (claimable at window_ts + expire_s - 1, expired at window_ts + expire_s, and no win or claim counts after it). For uninstall/reinstall it asserts what can be proven locally: a fresh profile with no save opens no window, offers no Catch-Up and shows no summary. A restored copy of the old snapshot keeps the claimed steps claimed, so nothing is granted twice.
4. 165: a04 asserts that the network-error popup gives a working retry control (fail, then usable again, then recover) for every surface: store, rewarded_ad, cloud and live_event. The item stays open: no live Shop IAP, ad provider (M57) or cloud provider (SB-M43-153) calls it yet, and Ranks is not live. Queue row -> OWNER.
5. 166: a04 asserts the no-tasks-ready state (task buttons and ScrubBox blocked, plus TASK_NONE for an unavailable order) and the no-duplicates state (Cards Exchange `Empty` = CARDS_EMPTY, exchange-all blocked, and the Empty label gone once a duplicate exists) on the real popups. Gifts (a04) and events (m05) are already asserted. No-rankings is out of scope while Ranks is not live, so the item stays open. Queue row -> OWNER.
6. The touched suites and the regressions pass headless on Godot 4.7.2. TASKS.md lines for the 5 items and queue rows 64/65/69/70/71 are updated with the line endings preserved.
