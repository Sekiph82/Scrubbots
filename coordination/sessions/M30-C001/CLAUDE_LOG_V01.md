# M30-C001 V01 — CLAUDE IMPLEMENTATION LOG

Milestone: `M30 — Win/Lose Rules`
Tasks: `SB-M30-001..008`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Implementation commit (pushed BEFORE this log): `5e1b82ba2f9e8729e5137a6d4e643e304ae5ddeb`
Status handoff: `AWAITING_AUDIT`

Owner authority followed: `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`,
master prompt `coordination/sessions/M30-C001/CHATGPT_MASTER_PROMPT_V01.md`,
audit criteria `coordination/sessions/M30-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`,
and the four M30 work packages. Root `TASKS.md` was READ only and NOT edited.

---

## 0. Git synchronization / owner-work preservation

- Confirmed repository `Sekiph82/Scrubbots`, branch `main`.
- Start state: local diverged from `origin/main` (local +4 owner `assets(codex)` commits, origin +12). Safely synchronized with a non-destructive `git merge origin/main` (merge commit `38de068`) — no `reset --hard`, no `clean -fd`, no force. The 4 pre-existing owner asset commits and all untracked owner `*.import` / `_owner_inbox` assets were preserved.
- Owner-modified `project.godot` (pre-existing working-tree change) was NOT staged or committed. Root `TASKS.md` was NOT modified.
- The implementation commit stages ONLY M30 files (see §7).

---

## 1. Scope compliance (audit §A governance)

- Root `TASKS.md` unchanged by Claude. ✔
- No M31 effects, no Economy rewards (no Scrub Bucks / Hearts / Win Streak / Bot Parts / ads / IAP / M39 entitlements), no final branded result-screen art, no new solver, no rewrite of accepted M23–M29 authority. ✔
- Zero AI image-generation credits used. ✔
- Implementation commit precedes this separate log commit. ✔

---

## 2. Task → evidence map

### SB-M30-001 — Owner-locked WIN truth
Code: `scripts/gameplay/completion/completion_evaluator.gd` — `is_won()` / `evaluate()` latch WON only when `BoardState.count_cells_by_state(ACTIVE)==0` AND full quiescence: `scheduler.live_assignment_count()==0`, `dispatcher.get_active_count()==0`, `claim.live_claim_count()==0`, `reservations.get_reservation_count()==0`, `slots.live_work_count()==0`. Board reaching zero while a final robot still travels is not quiescent → no early WIN.
Tests: `tests/m30_completion_authority.gd` (`_test_win_truth`: cleared+quiescent→WON; cleared board + live in-flight robot→NOT won; each authority independently blocks WON). `tests/m30_manual_playtest_smoke.gd` (real host solved Hazard → WON exactly once, board ACTIVE==0).

### SB-M30-002 — Owner-locked LOSE truth via real M27
Code: `completion_evaluator.gd` calls the REAL `DeadlockClassifier` (`get_classifier()` defaults to `DeadlockClassifier.new()`); only `DEADLOCK` at quiescence → LOST. WAITING/STALLED/PROGRESSABLE/UNKNOWN_BOUND and any in-flight assignment are never LOST. Cross-engine inconsistency / M26 fatal → fail-closed `ERROR` (not LOSE).
Tests: `m30_completion_authority.gd` (`_test_lose_mapping_no_duplication`: PROGRESSABLE/STALLED/UNKNOWN_BOUND→PLAYING, DEADLOCK→LOST, in-flight→PLAYING with classifier never consulted; `_test_real_classifier_deadlock`: real M27 proves an empty-supply/non-empty-board DEADLOCK→LOST, and a matching-supply STALLED→PLAYING). `m30_manual_playtest_smoke.gd` (real stack deadlock fixture → LOST exactly once via real classifier).

### SB-M30-003 — One terminal authority + exact-once latch
Code: `scripts/gameplay/completion/completion_controller.gd` — states PLAYING/WON/LOST/ERROR; `on_tick()` latches exactly once and emits exactly one `terminal_reached`; a latched result never re-emits and never flips; `reset_attempt()` arms a fresh latch for the next attempt.
Tests: `m30_completion_authority.gd` (`_test_exact_once_latch`: one event, later ticks/events emit no duplicate, LOST stays LOST, fresh attempt latches again exactly once). `m30_manual_playtest_smoke.gd` (WON event count == 1; a fresh replay after Retry latches exactly one new event; LOST event count == 1).

### SB-M30-004 — Dirty/event-driven evaluation (no per-frame proof)
Code: `completion_controller.gd` — `notify_event()` only sets `_dirty`; `on_tick()` runs cheap WIN/ERROR checks every call but runs the M27 proof only while `_dirty`; a completed non-terminal proof clears `_dirty`. `production_gameplay_host.gd` marks dirty on `authenticated_clear` and accepted placement, and evaluates in the runtime state-sync tail.
Tests: `m30_completion_authority.gd` (`_test_event_driven_gate`: first quiescent tick runs the proof once; 50 idle ticks with no event never re-run it; one event re-arms exactly one proof).

### SB-M30-005 — Production Win/Lose integration + terminal blocking
Code: `production_gameplay_host.gd` binds the authority over the exact live engines and, on `terminal_reached`, sets a distinct terminal stop on the runtime, terminal-stops input, and `scheduler.pause()` (blocks new M26 assignments). `production_runtime_controller.gd` adds `_terminal_stopped` (distinct from user pause / system suspension; freezes cadence + travel). `production_input_controller.gd` rejects post-terminal front activations with a deterministic `"terminal"` error before any M23 consumption / M24 mutation. No legitimate in-flight work is discarded — the latch only fires at quiescence.
Tests: `m30_manual_playtest_smoke.gd` (post-terminal activate_front → `terminal` error; input + runtime terminal-stopped; terminal stop is NOT a user pause; rejected activation mutated no M23 supply). `tests/m29_input_gate_evidence.gd` + full M29 suite still green (preserved M29 input/pause/focus/speed semantics).

### SB-M30-006 — Minimal owner-testable terminal seam (no branded art)
Code: `completion_controller.terminal_reached(status, detail)` is the stable terminal event; `scripts/debug/m30_win_lose_playtest.*` shows a native `RESULT` label (PLAYING/WON/LOST/ERROR). No branded result-screen art, no Economy consumption.

### SB-M30-007 — Transaction-safe same-puzzle Retry
Code: `scripts/gameplay/completion/retry_coordinator.gd` — the M26 `scheduler.reset()` is the FIRST destructive gate; `_scheduler_reset_clean()` requires `reset()==true` AND not `is_reset_pending()` AND `last_reset_succeeded()` AND not `is_fatal()`. On any failure/defer/pend/fatal it returns false with ZERO other reset (no M23/M24/board/speed/terminal touched). On a clean teardown it restores one coherent fresh attempt: `slots.reset()`, `supply.reset()` (deterministic → exact same initial candidate), `board.restore_all_active()`, `candidate_index.rebuild()`, `renderer.refresh_all()`, `runtime.reset_runtime()` (1x + clears terminal stop), `input.set_terminal_stopped(false)`, `scheduler.resume()`, `completion.reset_attempt()`. Reuses the same bound engine instances so stale pre-retry callbacks reach no new BoardState instance; M26/M25 monotonic ids are never recycled. `ProductionGameplayHost.retry()` delegates here; `reset_session()` is a back-compat alias.
Tests: `m30_transaction_safe_retry.gd` (each gate-failure mode `reset()==false` / pending / prior-failed / fatal → retry fails closed with every restore-side engine untouched and scheduler not resumed; clean gate → full restore; stale pre-retry authenticated-clear with a real captured pre-retry owner id creates no assignment, clears no new board cell, advances no clear count, emits no second terminal). `m30_manual_playtest_smoke.gd` (Retry after WON and after LOST restores the EXACT initial `debug_snapshot()` supply, full ACTIVE board, empty slots, zero claims/reservations/agents/assignments/committed work, 1x, PLAYING, input enabled; the restored attempt replays to a fresh WON).

### SB-M30-008 — Manual playtest + closure
Code/scene: `scenes/debug/m30_win_lose_playtest.tscn` + `scripts/debug/m30_win_lose_playtest.gd` — real M28 screen + real M23–M29 stack (`ProductionGameplayHost`) + real M30 authority on the real 20×20 Hazard Bot with the deterministic seed-1/3-col/preview-3 candidate. Minimal native result label + `AUTO-SOLVE` / `DEADLOCK DEMO` / `RETRY` controls. The deadlock demo uses the QA-only `qa_supply_drop_last` drain-tail seam to make the same real stack a proven end-of-supply DEADLOCK the real M27 classifier latches as LOST.
Evidence: `m30_manual_playtest_smoke.gd` drives this exact host path headless and proves all owner outcomes (see §3 F6 checklist).

---

## 3. Owner F6 manual instructions

Open Godot 4.7.2, run `res://scenes/debug/m30_win_lose_playtest.tscn` (F6):

1. Press **AUTO-SOLVE** and watch the board clear. When the last cell clears, the top **RESULT** reads **WON** (exactly once).
2. Tap any supply front tile after WON → nothing happens (terminal blocks input; a rejected activation consumes no supply).
3. Press **RETRY** → the full original artwork and full supply are restored, speed returns to 1x, **RESULT** = **PLAYING**. The attempt is fully playable again (AUTO-SOLVE reaches WON once more).
4. Press **DEADLOCK DEMO** → the same real stack rebuilds with a residual-deficient supply and auto-drains; when the residual supply is exhausted the real M27 classifier proves DEADLOCK and **RESULT** reads **LOST** (exactly once).
5. Press **RETRY** → same board + same initial supply restored at 1x, PLAYING, playable.

Manual taps on supply front tiles work exactly as in the M29 scene; AUTO-SOLVE is only a convenience that rides the real runtime cadence through the real input gate.

---

## 4. Validation run (this machine, Godot 4.7.2.stable)

- Root suite `godot --headless --path . -s res://tests/run_tests.gd` → **RESULT: ALL PASS**, exit 0.
- `tests/m30_completion_authority.gd` → PASS.
- `tests/m30_manual_playtest_smoke.gd` → PASS (real host WON/LOST/blocking/Retry end-to-end).
- `tests/m30_transaction_safe_retry.gd` → PASS (gate fail-closed atomicity + stale-callback safety).
- Regression floor (audit §M) standalone suites re-run: M20 (queue_free + v04..v10 lifecycle), M21 (real-art, v05, v06 tall, v07 corridor, v10 reservation), M22 (railroad/responsive/connector/final/demo), M23 v01/v02/v03, M24 (blue/refill/slot/handoff/v02), M25 (blue/claim/rollback/scale/v02/v03), M26 (hazard/scale-59), M27 (generation-retry/hazard-solve/scale-59), M28 layout, M29 (exact-origin/runtime/input-gate/presentation/realtime/slot-sync/speed) → all exit 0.
- `git diff --check` on tracked M30 edits → clean (only benign LF→CRLF notices).

### Known pre-existing failures (NOT M30, NOT regressions)
`tests/m21_v08_corridor_validation.gd` (checks C/043, C/047) and `tests/m21_v09_direct_evidence_reconciliation.gd` (check B) fail on exterior-route corridor geometry. Verified pre-existing on `origin/main`: with all M30 tracked edits stashed, both fail identically. They are outside M30 scope (routing geometry, unrelated to Win/Lose/Retry) and were not introduced or touched by this milestone. Left as-is per scope discipline (no unrelated fixes in M30).

---

## 5. Preserved accepted behavior (audit §A / §F)

- M23 deterministic candidate, M24 five-slot transactions, M25 claim/rollback/finalize, M26 one-assignment-per-step + transaction-safe/generation-safe reset, M27 classifier semantics, M28 layout, M29 input/pause/focus/speed and live slot sync — all unchanged and green. M30 additions are additive (a new read-only authority + narrow terminal gates + a hardened retry gate); no accepted authority was rewritten or weakened. The M26 reset gate was NOT weakened to ease the retry-failure test (failure is injected at the gate boundary via a scheduler double).

---

## 6. Boundaries honored

- No timer / move-limit / paid-retry / energy / ads / IAP / failure manipulation.
- No Economy currency, Hearts, Win Streak, Bot Parts, or M39 entitlements — only a stable terminal event is exposed for later systems.
- No final branded result-screen art. No M31. Zero AI image generation.

---

## 7. Files in the implementation commit (`5e1b82b`)

New:
- `scripts/gameplay/completion/completion_evaluator.gd` (+ `.uid`)
- `scripts/gameplay/completion/completion_controller.gd` (+ `.uid`)
- `scripts/gameplay/completion/retry_coordinator.gd` (+ `.uid`)
- `scripts/debug/m30_win_lose_playtest.gd` (+ `.uid`)
- `scenes/debug/m30_win_lose_playtest.tscn`
- `tests/m30_completion_authority.gd` (+ `.uid`)
- `tests/m30_manual_playtest_smoke.gd` (+ `.uid`)
- `tests/m30_transaction_safe_retry.gd` (+ `.uid`)

Modified:
- `scripts/gameplay/board/board_state.gd` — `restore_all_active()` seam.
- `scripts/gameplay/runtime/production_runtime_controller.gd` — distinct terminal stop.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — completion wiring, hardened `retry()`, QA deadlock seam, accessors.
- `scripts/ui/production_input_controller.gd` — post-terminal input gate.

Not touched: root `TASKS.md`, `project.godot` (owner working-tree change), all owner assets.

---

Handoff: `AWAITING_AUDIT`.
