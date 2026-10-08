# M43-C005F-PHASE2-R02 — Durable Earned-Pack Acknowledgement — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_REMEDIATION_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_AUDIT_CRITERIA_V01.md`
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `25a5094d5435c1d903bc1b3f43515d7f57162cf9` (`origin/main`)
- Final SHA: the commit that adds this log (implementation, tests and this log in one commit; parity is reported in the hand-off)

## 0. Owner-local sync truth

The owner-local checkout `C:/Users/sekip/Desktop/ScrubBots` is on `main` at `593f0f6d`, behind `origin/main`.

Its protected state was not touched:
- `project.godot`, `scenes/app/main.tscn` and the two owner-review `.tscn` files are modified;
- untracked: the pre-canonical `addons/` (including `godot_ai`), `.mcp.json`, art and `.uid`/`.import` files;
- `stash@{0}` ("pre-batch TASKS whitespace") and three Codex worktrees.

It still cannot fast-forward: Git refuses to overwrite those untracked addon copies and the dirty `project.godot` (known since Phase 1). Nothing was reset, cleaned, stashed or moved.

All work was done in a clean TEMP worktree at exact `origin/main` `25a5094d`. Root `TASKS.md` was not edited.

## 1. Blocker being fixed

R01 `AppState.acknowledge_earned_pack(id)` removed the queue entry first, then saved. It returned `ok:true` even when the save failed. So a failed save left the live economy without the entry while disk still had it. The presenter then emitted `pack_finished` and advanced the FIFO.

## 2. A — Transactional acknowledgement (`scripts/app/app_state.gd`)

```text
acknowledge_earned_pack(id)
  is_blocked                      -> {ok:false, reason:"app_blocked"}
  no committed receipt            -> {ok:false, reason:"not_committed"}
  not in pending queue            -> {ok:false, reason:"not_pending"}      (checked with has(); nothing mutated)
  pre = economy.snapshot()                                                 (exact pre-ack economy)
  pending_packs.remove(id)
  r = request_save()                                                       (canonical SaveService path)
  r.ok                            -> {ok:true, save:r}
  else economy.import_snapshot(pre)
                                  -> {ok:false, reason:"ack_save_failed", save:r, restored:<bool>}
```

- The snapshot covers the whole economy: queue, receipts, Collection, pack RNG, pity and wallet. Restoring it puts the same id/kind back at the same FIFO position, and every other section stays byte-identical.
- Nothing is redrawn. A replay after restore goes through `open_earned_pack` → the committed receipt (zero draw). The h01 test proves this.
- `open_earned_pack` and `commit_pack` are unchanged.

## 3. B — Presenter semantics (`scripts/ui/ceremony/pack_presenter.gd`, `scripts/app/main.gd`)

- `_on_completed` stores the durable ack result per id (`_ack_ok`).
  - On failure it records `last_error = "ack:ack_save_failed"`, sets a transient guard, and emits the new `pack_ack_failed(id, result)`.
- `_on_closed("complete")` emits `pack_finished(id)` **only if the ack succeeded**.
  - So a failed ack never reaches `main`'s `pack_finished → request_earned_packs()`, and there is no FIFO advance.
- Reopen-loop guard: `_ack_guard` is a presentation-local Dictionary in memory and is **not persisted**.
  - While the front id is guarded, `drain()` returns false with `last_error = "ack_retry_guarded"`.
  - Nothing reopens, and the packs queued behind it stay blocked, because FIFO order is preserved.
  - Under a persistent save failure, Home's `modal_changed`/drain calls therefore do not spin the ceremony again and again.
- Guard release:
  - `main._on_route_changed(→ HOME)` calls `packs.release_ack_guard()`, so the next Home entry retries the same receipt as a replay.
  - A restart builds a fresh presenter, so it starts unguarded.
- No new persisted flag or save field was added. The queue schema is unchanged.

## 4. C — Deterministic fault-injection evidence

Three cases were added to the existing focused suite `tests/m43_c005f_phase2_r01_earned_pack_runtime.gd`. It now has 22 cases: the R01 q01–q06 and g01–g13, plus h01–h03. All three new cases inject the failure via `SaveService.set_fault_injector(func(stage): return stage == "temp_write")`, so the canonical save returns `{ok:false, reason:"temp_write_failed"}`.

| Case | Scenario | Assertions (all ok) |
|---|---|---|
| h01 | AppState unit: 2 pending Standard; first committed; ack under fault | Outer `ok:false`, `reason:"ack_save_failed"`, `restored:true`, save reason `temp_write_failed`. Same id back at FIFO front, size 2. Collection / pack RNG / pity / receipts / queue sections **and** the full economy snapshot are byte-identical to pre-ack. After clearing the fault: reopen → `replay:true`, identical model, zero draw. Ack → ok, removed exactly once; second ack → `not_pending`. |
| h02 | REAL app (`main.tscn`, 1080×2160 SubViewport): 2 pending Standard; boot → pack 1 auto-opens; fault on the app's SaveService; shipping ceremony finished by taps | `pack_ack_failed == [id1]`, `pack_finished` empty. Entry restored at front, size 2, receipts / Collection / RNG / pity unchanged. After 30 frames of Home drains: no pack in the ModalStack, `presented_log` size 1 (pack 2 not started, pack 1 not reopened), `is_ack_guarded(id1)`. Clear fault + `release_ack_guard()` (what Home entry does) + drain: the same id1 reopens with `[id1,"standard",true]`, zero draw / pity advance. Finish → `pack_finished == [id1]`, removed exactly once. FIFO then opens pack 2 `[id2,"standard",false]`. Finish → queue empty, `pack_finished == [id1,id2]`. |
| h03 | Restart after failed ack: 1 pending Premium committed; ack fails | Entry kept. Relaunch (new AppState on the same save path = last good save): same pending front id, identical committed receipt. Boot the real app: the same 5 cards reopen with `replay:true`. Finish → Collection identical (no reroll), queue empty (durably acknowledged). |

Suite output: `M43-C005F-PHASE2-R01 earned pack runtime: PASS (22/22 cases, 0 fail)`.

The 3 `SCRIPT ERROR ... 'explode' in base 'Nil'` lines are the pre-existing g09 deliberate throwing-plugin fault injection. The suite announces them with `EXPECTED_FAULT_INJECTION`.

## 5. D — R01 preserved

R02 has no change to:
- `PendingPackQueue` or the queue schema;
- reward handlers (enqueue only, no silent draw);
- Gift / Daily / Rewarded triggers;
- `PackCommitTransaction`, CardPackService, pity or the Premium guarantee;
- the 3/5 card truth;
- the F005 feedback adapter;
- the F003/F004 Results ceremonies;
- the ModalStack z band.

All R01 q*/g* cases still pass in the same run.

## 6. Regression battery (clean worktree, after `--import`)

| Suite | Exit | Result |
|---|---|---|
| `m43_c005f_phase2_r01_earned_pack_runtime` (R01 + R02 h01-h03) | 0 | PASS (22/22 cases, 0 fail) |
| `m43_c005f_phase1_foundation` | 0 | PASS (23/23 cases, 0 fail) (serr 1 expected) |
| `m43_c005f_phase2_results_pack_feel` | 0 | PASS (22/22 cases, 0 fail) (serr 6 expected) |
| `m43_master_c005f_feel` | 0 | PASS (10/10 cases, 0 fail) |
| `m43_c001a_results_foundation` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c001b_won_results_visual` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c001r_c001_results_momentum` | 0 | PASS (40/40 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 1 | FAIL (21/21 cases, 1 fail) — v07 mid-route sample missed once under battery load; rerun 3/3 PASS (21/21, 0 fail). R02 touches no ceremony code. |
| `m43_c005_c007_premium_pack_presentation` | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c006_owner_review_harness` | 0 | PASS (14/14 cases, 0 fail) |
| `m43_c005_c007_premium_owner_review_harness` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c005_c008_pack_commit_transaction` | 0 | PASS (27/27 cases, 0 fail) |
| `m43_c005_c009_card_state_celebration` | 0 | PASS (25/25 cases, 0 fail) |
| `m43_master_c005_meta_ceremonies` | 0 | PASS (32/32 cases, 0 fail) |
| `m43_master_c005r_gift_micro_progress` | 0 | PASS (8/8 cases, 0 fail) |
| `m43_master_c007_collection` | 0 | PASS (13/13 cases, 0 fail) |
| `m43_master_c007r_pity` | 0 | PASS (9/9 cases, 0 fail) |
| `m54_collection_set_master_exactly_once` | 0 | PASS |
| `m43_master_c009_daily` | 0 | PASS (12/12 cases, 0 fail) |
| `m43_master_c010_meta` | 0 | PASS (12/12 cases, 0 fail) |
| `m43_master_c011_c014` | 0 | PASS (28/28 cases, 0 fail) |
| `m39_v02_atomicity` | 0 | PASS |
| `m39_v03_full_surface` | 0 | PASS |
| `m39_v04_integration` | 0 | PASS |
| `m39a_economy_core` | 0 | PASS |
| `m39d_daily_collection` | 0 | PASS |
| `m39e_full_matrix` | 0 | PASS |
| `m40_save_system` | 0 | PASS |
| `m40_v02_safety` | 0 | PASS |
| `m40_v03_canonical` | 0 | PASS |
| `m40_v04_bootstrap` | 0 | PASS |
| `m41_settings` | 0 | PASS |
| `m42_home` | 0 | PASS |
| `m42_navigation` | 0 | PASS |
| `m43_c002_c001_popup_modal_pause` | 0 | PASS (23/23 cases, 0 fail) |
| `m43_c003_c001_acquisition` | 0 | PASS (34/34 cases, 0 fail) |
| `m43_c004_c001_fail_need_a_hand` | 0 | PASS (40/40 cases, 0 fail) |
| `m30_completion_authority` | 0 | PASS |
| `m30_manual_playtest_smoke` | 0 | PASS |
| `m43_r15_owner_remediation` | 0 | PASS (18/18 cases, 0 fail) |
| `m43_r15_001_r01_sequential_unlock` | 0 | PASS (14/14 cases, 0 fail) |
| `m55_economy_release_regression` | 0 | PASS |
| `m43_master_c006_shop` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_master_c008_robots` | 0 | PASS (10/10 cases, 0 fail) |
| `run_tests (root tests/run_tests.gd)` | 0 | RESULT: ALL PASS |
| headless boot (`--quit-after 120`) | 0 | clean; only the engine exit notice `29 resources still in use at exit` (same as R01 baseline) |
| `git diff --check` | 0 | clean |

`SCRIPT ERROR` counts in feel suites are their pre-existing documented expected fault injections (unchanged from R01).

## 7. Forbidden-path proof

The changed files are exactly:

```text
scripts/app/app_state.gd
scripts/app/main.gd
scripts/ui/ceremony/pack_presenter.gd
tests/m43_c005f_phase2_r01_earned_pack_runtime.gd
coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_CLAUDE_LOG_V01.md
```

The following are untouched:
- `TASKS.md`;
- `scripts/content_runtime/**` and `data/config/remote_content_runtime_v1.json`;
- `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/**`;
- `level_factory/**`, the VOID code and the R2/publisher code.

No endpoint, URL, credential or secret was added. No GameFeelFlow/Spark access was added outside the canonical FeedbackAdapter.

## 8. Status

AWAITING_GPT_M43_C005F_PHASE2_R02_REAUDIT
