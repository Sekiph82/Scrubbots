STATUS: READY

# Build: 175-ev02-ci-fix (flaky m43_c001a "economy/progression untouched" after Events V02)

## Summary
**Root cause:** `EventsV02Service.now()` raised the persisted high-water clock `_hw` on every read. Home's EVENTS badge refresh calls `events_v02.claimable_count()`, which goes through `list()` and then `now()`. So a pure read during a results flow changed the `events_v02.hw` field of the economy save whenever a wall-clock second ticked between the suite's two snapshots. That makes the failure intermittent (CI 44099810993 failed, 44105389461 passed on nearly the same code). Locally it reproduced on the sibling assertion "rollback: nothing shown, nothing granted". A temporary diagnostic print (not committed) showed the only differing section:

`events_v02 {"hw":1794927818,...} -> {"hw":1794927819,...}` (instances / receipts / tutorial_seen unchanged)

**Decision: (a), fix the game.** A read path must not write persisted state. This also removes the same latent flake from every other suite that compares full economy snapshots (about 19 suites erase only `speed.clock_high_water`).
- `now()` is read-only: `max(hw, clock)`.
- A new `_stamp()` records the high-water mark only on state changes: an applied receipt, a join, a claim.
- Anti-tamper still holds: after any committed change, a clock moved back cannot reopen a window or rewind rivals.
- The "economy untouched" check in m43_c001a is unchanged, and the suite still compares the full `events_v02` section.

**Files:** `scripts/economy/events_v02_service.gd` (now / _stamp + header comment), `tests/ev02_events_v02.gd` (e05: two new permanent assertions).

## Acceptance criteria
1. [x] **Reproduced locally and root cause found:** `m43_c001a_results_foundation` FAIL (11/11 cases, 1 fail) on `4be082a5`, with the diff probe output above.
2. [x] **Fixed in the right place, check not weakened:**
   - Game fix in `9c48fa0c`.
   - `tests/m43_c001a_results_foundation.gd` is untouched.
   - New `ev02_events_v02` e05 assertions: "list / view / counts at a later clock leave the save byte-identical" and "an applied receipt stamps the high-water mark".
3. [x] **Deterministic now:** `m43_c001a_results_foundation` PASS (11/11 cases, 0 fail) in 3 consecutive runs, plus a fourth in the full list.
4. [x] **Full CI list via `tools/run_suites.py` in 2 shards (98 suites, 49 + 49, built from `--list`):**
   - Shard 2: `aggregate=PASS (49/49)`, including the exact lines `EV02 events service evidence: PASS (10/10 cases, 0 fail)` and `EV02 events UI evidence: PASS (6/6 cases, 0 fail)`.
   - Shard 1: 48/49 PASS. `m43_c001a_results_foundation` PASS (11/11 cases, 0 fail).
   - The one shard-1 failure was `m46_performance`, on timing thresholds only (retry 57.5 ms vs 50.1; frame p99 21.2 ms vs 16.7). The two shards ran in parallel while 7 other Godot processes from other factory jobs were running.
   - Solo reruns of `m46_performance`: one more timing miss (FULL p99 16.84 vs 16.7), then `M46 performance evidence: PASS (22/22 cases, 0 fail)`.
   - The change touches no per-frame code. Effective 98/98.

## Validation
All LOCAL_PASS, Godot 4.7.2:
- `python tools/run_suites.py m43_c001a_results_foundation` x3: PASS
- `ev02_events_v02` PASS (10/10)
- `ev02_events_ui` PASS (6/6)
- `m43_c005f_phase6_unlock_feel` PASS (8/8)
- Full list in 2 shards as above.

`git diff --check` clean. Import churn (EOL-only `.import` files, `project.godot` rewrite) re-checked out; generated sidecars deleted by name. `git status --porcelain` empty.

## Log
### Round 0
- **Reproduced:** probed the differing snapshot section; only `events_v02.hw` moved.
- **Fixed:** made `now()` read-only and stamp on mutations.
- **Test:** added the permanent read-does-not-write test.
- **Commit:** one commit `9c48fa0c` on `factory/175-ev02-ci-fix`, not pushed. TASKS.md and the workflows untouched; no `git stash` or `git clean`.
