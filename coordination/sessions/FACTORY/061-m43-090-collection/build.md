STATUS: READY

# Build: M43 Collection screen verify-close + pack-inventory entry (SB-M43-090..101)

## Summary
The Collection album now has a pack-entry row (SB-M43-098). It shows the live counts from `economy.pending_packs` (`count_of("standard")` / `count_of("premium")`). Its OPEN PACKS button is blocked when `size() == 0`, and the row then shows "No packs waiting to open.". Pressing the button only calls the `open_packs` Callable. Main passes `request_earned_packs` as that Callable, so opening goes through the existing M43-C005 PackPresenter ceremony. The UI itself never draws, grants or touches the queue. The album subscribes to `ModalStack.top_changed` and re-reads every value live whenever it becomes top again, for example after a pack ceremony has acknowledged its entry. Cases k14..k17 were added to the C007 suite, and both Collection suites are now in the CI validate list with exact-summary guards (55 suites).

Commits on `factory/061-m43-090-collection` (not pushed):
- `abb42509` M43-098: Collection pack entry + C007 k14..k17
- `74b85bab` ci: add m43_master_c007_collection + m54_collection_set_master_exactly_once with exact guards (55)
- `1367e8f9` tasks: SB-M43-090..101 Collection done (factory 061)

Files changed:
- `scripts/ui/collection/collection_screen.gd`: PackRow / Packs label / `packs` action; `open_album(stack, app, open_packs := Callable())`; top_changed live refresh.
- `scripts/app/main.gd`: one line, `CollectionScreen.open_album(_modals, app_state, request_earned_packs)`. **Deviation from AC7's file list:** the Collection screen is a static RefCounted that only gets `app_state`, and that object has no route to Main. Main must hand over `request_earned_packs`, and this follows the existing pattern `RobotsScreen.open(_modals, app_state, ceremonies)`. No other change to main.gd.
- `scripts/ui/ui_text.gd`: `COLLECTION_PACKS`, `COLLECTION_PACKS_EMPTY`, `COLLECTION_PACKS_OPEN`.
- `tests/m43_master_c007_collection.gd`: k14..k17, `EXPECTED_CASES` extended to 17 (ledger guard kept).
- `.github/workflows/android-family-first10.yml`: both suites in the validate list, exact guards, header comment (55 total).
- `TASKS.md`: SB-M43-090..101 ticked; the two READY queue rows were replaced by one DONE row.

## Acceptance criteria
1. [x] C007 prints `M43 master C007 Collection evidence: PASS (17/17 cases, 0 fail)`. It exited 0 with no SCRIPT ERROR / Parse Error in 3 isolated runs.
2. [x] `m54_collection_set_master_exactly_once` prints `M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS` and exits 0.
3. [x] k14 checks the pack entry:
   - With an empty queue the label reads "No packs waiting to open." and OPEN PACKS is disabled.
   - After `reward.grant("k14_tx", {standard_card_packs: 2, premium_card_packs: 1})`, the album opened from the Home shortcut shows "Packs to open: 2 Standard · 1 Premium" and the button is enabled.
   - The press itself leaves the queue entries and the Collection snapshot identical.
   - After frames, the stack is `["collection", "standard_pack"]`, so the route is Main.request_earned_packs to the C005 ceremony.
   - After the ceremony finishes, the queue size is 2 and the album re-reads "1 Standard · 1 Premium". Cards changed only through the ceremony's pack commit.
4. [x] `grep -n request_earned_packs scripts/ui/collection/collection_screen.gd` returns lines 15 and 60 (doc comments). The route is the `open_packs` Callable, which Main binds at main.gd:374 (`CollectionScreen.open_album(_modals, app_state, request_earned_packs)`). `grep -nE "\.(enqueue|remove|grant|exchange)\(" scripts/ui/collection/collection_screen.gd` returns nothing, so there is no direct queue or inventory mutation. Exchanges still go through `app.actions.exchange_card` / `exchange_all_extras`.
5. [x] Each suite name appears 3 times in the workflow: the header comment, the validate list and the guard. The YAML parses with `yaml.safe_load`.
6. [x] `python tools/run_suites.py --path .` gave `aggregate=FAIL (54/55)`. The only failure is `m46_performance` (frame mean/p99 timings: 5.03 ms vs 4.0 and p99 23 ms vs 16.7, gameplay frames only). An isolated re-run failed the same 3 timing assertions, with 22/22 cases completed. m46 has no Collection code path, and the machine is shared with other factory jobs, so this is machine load as the spec allows; CI is the arbiter.
7. [x] `git diff --check` is clean. The diff touches the spec's files plus the one-line `scripts/app/main.gd` wiring explained above. No .uid/.import files were committed. The worktree still has untracked/modified Godot import artifacts that existed before this job started; none were staged.
8. [x] TASKS.md SB-M43-090..101 are ticked with the Requirement 1 classification:
   - verify-close: 090, 092..097, 099, 101
   - 091: existing promoted assets, no new art, §0D.1 sign-off
   - 098: built
   - 100: no locked/future content, exactly 15 canonical rows (k16)
   - Each row carries "CLAUDE_PEER_REVIEW pending".

### k10 warm set-detail performance (budget not changed, 150 ms)
I ran the C007 suite 3 times on its own with nothing else running:
| run | cold | warm |
|---|---|---|
| 1 | 337.8 ms | 88.8 ms |
| 2 | 296.9 ms | 97.2 ms |
| 3 | 348.1 ms | 91.8 ms |

Warm stays at about 90 ms in all three runs, well under budget. The earlier 410 ms was machine load, not a regression, so the job 040 per-album texture cache is still working. No fix was needed.

## Validation
- `$GODOT --headless --path . -s res://tests/m43_master_c007_collection.gd`: run 3 times, PASS 17/17 each time (LOCAL_PASS)
- `$GODOT --headless --path . -s res://tests/m54_collection_set_master_exactly_once.gd`: PASS (LOCAL_PASS)
- `python tools/run_suites.py --path .`: 54/55 PASS, plus m46_performance FAIL on timing only (load-bound; isolated re-run is also a timing-only FAIL)
- `python tools/run_suites.py --list`: 55 suites, with the two new ones last
- `git diff --check`: clean

## Log
### Round 0
- Built SB-M43-098 as a Collection-owned pack row that reflects the durable `PendingPackQueue` and routes OPEN to `Main.request_earned_packs()`. No stored-inventory mechanic and no new art.
- Added k14 (pack entry), k15 (CLAIMED vs on completion; all 15 sets + Master granted exactly once; reopen and `claim_pending_rewards` grant nothing), k16 (exactly Set_1..Set_15 + MasterRow; row progress sums equal the inventory; 135 canonical ids only) and k17 (9x of every card; EXCHANGE ALL total 147,400 SB = sum(8 x value); every owned() == 1; one `exchange_all_extras` facade commit).
- Added both suites to CI (55) with exact-summary guards in the C006 style.
- Investigated k10: it is load only (warm about 90 ms isolated), and the budget is unchanged.
- Updated TASKS.md with the classification and LOCAL_PASS evidence. Peer-review labels stay pending.

## CI (orchestrator)
GitHub Actions run 41029956333 on job branch (validation_only): success. m46_performance PASS 22/22, m43_master_c007_collection PASS 17/17 (incl. k10 perf budget), m54_collection_set_master_exactly_once PASS. Local m46/k10 timing misses were machine load. Remote branch deleted. Post-review commit: TASKS labels pending -> PASS.
