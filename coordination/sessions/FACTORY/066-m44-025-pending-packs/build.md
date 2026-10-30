STATUS: READY

# Build: Pending-pack inventory: pre-L20 packs kept, openable at L20

## Summary
Earned packs were already queued durably at grant time (`economy.pending_packs`). The gap was on the open side: a fresh profile below L20 could open them. The branch closes that gap with one gate in the shared open path and one silent guard in the presenter:
- `AppState.open_earned_pack(id)` returns `{ok:false, reason:"locked"}` while `feature_unlocked("card_packs")` is false. Nothing is committed and the entry stays queued.
- `PackPresenter.drain()` returns false before any UI while locked. It records no `last_error` and emits no `idle`, so nothing blocks the next drain.
- I added no new drain trigger. On Home arrival `_on_route_changed` already calls `request_home_ceremonies()`, and `_drain_home_ceremonies()` calls `packs.drain()` after the meta ceremonies. Committed actions, rewarded results, `pack_finished` and Collection OPEN PACKS also trigger a drain. Once the frontier reaches 20, the next Home arrival drains the queue FIFO through the existing C005 ceremony.
- There is no save/schema change. Grandfathered profiles are unchanged because the gate returns true for them. The gate fails open the same way the existing one does.

Files changed (worktree):
- `scripts/app/app_state.gd` (gate and doc comment)
- `scripts/ui/ceremony/pack_presenter.gd` (silent locked guard)
- `tests/m44_pending_packs_gate.gd` (new suite, 6 cases)
- `.github/workflows/android-family-first10.yml` (validate list now has 59 suites; exact 6/6 guard `M44-PENDING-PACKS verdict=...`; header comment)
- `TASKS.md` (SB-M44-025 ticked with evidence; queue row set to DONE)

Commits: `9f335a86` (code, test, CI) and `650c40b8` (TASKS.md).

AGENTS.md: no change. It does not describe the pending-pack or pack-ceremony flow (grep for pending_pack, PackPresenter and pack ceremony found nothing).

## Acceptance criteria
1. [x] queue_below_unlock: on a fresh profile walked to L1, L10 and L19, `economy.reward.grant` queued 4 packs. The FIFO ids were stable, and Collection, pack_receipts, RNG and pity snapshots were unchanged. Evidence: suite output `ok:` lines.
2. [x] no_open_below_unlock: at L19, `open_earned_pack(front)` returned `{ "ok": false, "reason": "locked" }`. `drain()` returned false, stack depth stayed 0, `last_error` was empty, no `idle` was emitted, the queue was unchanged and there were 0 receipts.
3. [x] persist: after reload into a fresh AppState on the same temp path, the entries were identical (ids, kinds, order). The profile was still new, the frontier was 19 and opening still returned locked.
4. [x] open_at_unlock: at L20, `card_packs` and `collection` are unlocked. The Collection `Packs` label read "Packs to open: 2 Standard · 2 Premium". The ceremony drain opened the 4 ids in FIFO order, each finished exactly once with no replay. The queue emptied, all receipts exist, Collection gained the 16 revealed cards, and a drain on the empty queue was a no-op.
5. [x] exactly_once: the repeat open replayed the same receipt with Collection and RNG unchanged. The ack removed the entry, a second drain was a no-op, and a reload showed an empty queue with the receipt kept.
6. [x] grandfather: an established L1 save has the gate true, and drain opened the ceremony immediately and acknowledged it normally.
   - Last line: `M44 PENDING PACKS GATE: PASS (6/6 cases, 0 fail)`, exit 0, no SCRIPT ERROR or Parse Error.
7. [x] Regressions LOCAL_PASS (each run with `$GODOT --headless --path $W -s res://tests/<suite>.gd`):
   - m43_master_c007_collection: PASS (17/17)
   - m43_master_c005_meta_ceremonies: PASS (32/32)
   - m44_unlock_gate: PASS (6/6)
   - m44_ftue: PASS (23/23)
   - m40_save_system: PASS
   - m43_c005f_phase2_r01_earned_pack_runtime: PASS (22/22)
   - m43_c005f_phase3_meta_rewards_acquisition: PASS (15/15)
   - m54_collection_set_master_exactly_once: PASS
   - The phase2_r01 and phase3 logs contain 3 and 1 `SCRIPT ERROR` lines respectively. These are their own documented `EXPECTED_FAULT_INJECTION` spy-plugin throws, announced by a banner line, and neither suite is in the CI validate list.
   - No fixture needed changing. None of these suites relies on sub-L20 auto-open: they use established (grandfathered) AppState or main boots without `boot_ftue_override`.
8. [x] `git diff --check HEAD~2 HEAD` is clean. The workflow YAML parses (`yaml.safe_load`). `tools/run_suites.read_workflow` reads 59 unique suites, ending in `m44_pending_packs_gate`, with guard `M44 PENDING PACKS GATE: PASS (6/6 cases, 0 fail)`.

## Validation
- New suite `m44_pending_packs_gate`: LOCAL_PASS 6/6.
- The 8 regression suites above: LOCAL_PASS.
- `python tools/run_suites.py` (all 59 suites, local, under load): 56/59.
  - Failed: m46_performance (frame p99 and retry timing budgets), m50_color_symbols (`300 rebinds in 3839.8 ms`, a timing budget) and m43_master_c007_collection (set-detail build 426/212 ms against a 150 ms budget).
  - Standalone rerun: c007 PASS 17/17. m50 and m46 failed again, on timing budgets only (`300 rebinds in 3231.7 ms`; frame p99 and retry budgets).
  - Neither m50 nor m46 touches the changed code. GitHub CI (validation_only) is the arbiter for timings and the 59-suite aggregate.
- `git diff --check`: clean.
- Not committed: Godot-regenerated `.import` and `.uid` files in the worktree, per instructions.
- `validate_logs/` is gitignored.

## Log
### Round 0
- Traced grant to queue to drain. The grant side already only enqueues.
- Added the `card_packs` gate in `AppState.open_earned_pack` and a silent locked guard at the top of `PackPresenter.drain()`.
- Confirmed the existing Home-arrival drain (`_on_route_changed` -> `request_home_ceremonies` -> `packs.drain()`), so I added no new trigger.
- Wrote the 6-case suite, wired it into CI validate (59 suites, exact guard), ran the regressions and the full local run, and updated TASKS.md.

CI: GitHub Actions run 41058336026 (job branch, validation_only) success; M44-PENDING-PACKS verdict=PASS (6/6).
