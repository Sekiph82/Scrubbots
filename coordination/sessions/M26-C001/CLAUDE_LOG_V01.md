# M26-C001 V01 — CLAUDE IMPLEMENTATION LOG

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M26 — Auto Dispatch Scheduler`
Cycle: `M26-C001 V01`
Engine: Godot **4.7.2** (`4.7.2.stable.official.ed1daf0bf`), GDScript
Status: **AWAITING_AUDIT**

Start SHA (pre-work `origin/main`): `dc8e27f7f3347cc479dbfbc327a9a8bb5e67903b`
Implementation SHA: `1bd49497f3e67cedb63952397b1f48a68d12c228`
Log commit SHA: `(this commit)` (this file, separate final commit)

## 0. Governance / scope confirmation

- Repo/branch: `Sekiph82/Scrubbots` / `main`. Verified before work.
- Safe sync: fast-forwarded local `main` (was behind 9) to `origin/main`; no `reset --hard`/`clean`/force. Pre-existing owner-local work preserved (editor `.uid`/`.import`, `assets/…`, `project.godot` cosmetic reshuffle, `tests/_probe_tmp.gd`) — none staged or deleted.
- Root `TASKS.md` modified by Claude: **NO** (absent from implementation commit).
- M27 solvability/deadlock implemented: **NO**.
- Final M28 gameplay UI implemented: **NO**.
- Image-generation credits spent: **0** (no image tool invoked).
- Implementation commit(s) precede this separate `CLAUDE_LOG_V01.md` commit.

## 1. Authority topology (no duplicate authority introduced)

The production chain is exactly:

```
M23 supply -> M24 five-slot batch -> M26 scheduler -> M25 claim/reserve
  -> exact route -> RouteValidator -> ScrubbotDispatcher.dispatch_preclaimed
  -> ScrubbotAgent -> M20 CompleteClearingLoop authenticated clear
  -> authenticated_clear signal -> M25.finalize_clear -> M24 quota update
```

- TargetSelector remains the sole WHAT authority (called only inside M25, never by M26/preclaimed dispatch).
- ReservationState remains the sole reservation authority; M26 never creates a second reservation.
- ProductionTargetAccess/ProductionRoutingSystem/RouteValidator remain route/reachability truth.
- ScrubbotDispatcher remains the sole agent spawn/assign authority.
- CompleteClearingLoop remains the sole authenticated clear authority.
- M26 (`AutoDispatchScheduler`) owns ONLY orchestration/pacing/fairness/wake and the claim→preclaimed-assignment mapping.

## 2. Changed files

Production:
- `scripts/gameplay/dispatch/auto_dispatch_scheduler.gd` (NEW) — M26 Auto Dispatch Scheduler.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — added `dispatch_preclaimed(...)` (exact preclaimed-target path; no TargetSelector, no second reservation, no reservation release on failure, monotonic owner-id collision safety). Legacy `dispatch()`/`reset()`/M20 arrival API untouched.
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — added `authenticated_clear` post-commit signal (emitted once per CLEARED transaction), `bind_arrival_only(...)` seam (batch scheduler consumes arrivals without a fake direct-color SlotSystem), `activate_slot` disabled in arrival-only mode. Legacy `bind()`/`activate_slot()` and all M20 tests untouched.

Tests / evidence:
- `tests/run_tests.gd` — added M26 unit section (preclaimed boundary, no-ghost adversarial, pacing/capacity, fairness incl. BLUE 8/14/12 spill + round-robin, WAITING/wake, pause/resume/reset, BLUE-15 autonomy) + `_run_m26_scheduler_tests()` wired into the master run.
- `tests/support/m26_origin_provider.gd` (NEW) — deterministic slot-origin provider double.
- `tests/m26_hazard_bot_integration.gd` (NEW) — real Hazard Bot end-to-end integration evidence.
- `tests/m26_scale_59_sanity.gd` (NEW) — 59x59 high-density sanity/allocation evidence.

## 3. HARD NO-GHOST invariant

`dispatch_preclaimed` + scheduler `_attempt_color` enforce, per attempt:
1. successful M25 claim/reservation (else no robot),
2. exact route to the SAME claimed target (RouteRequest for the claimed target only),
3. RouteValidator-clean route (else `M25.rollback_claim`, no robot),
4. exact preclaimed dispatcher assignment (proves ReservationState owner↔target both ways, target/color/board validity),
5. only then exactly one ScrubbotAgent.

Failure semantics proven by tests: no target / claim failure / null route / generic route-like object / route-target mismatch / wrong slot origin / reset-injected / already-active owner ⇒ ZERO new agent, and `M25.rollback_claim` restores committed/reservation with remaining quota untouched. A failed claim is NEVER retargeted (dispatcher builds a request only for the claimed target; the scheduler never reselects).

## 4. Quota finalization bridge

`CompleteClearingLoop._run_transaction` emits `authenticated_clear(owner,target,color,agent)` exactly once, only on the committed CLEARED path (after BoardState→candidate→reservation→dispatcher-finalize→renderer), never on preflight-reject/rollback/reset. The scheduler maps the owner id to its exact live claim and calls `M25.finalize_clear(claim_id)` once (which does M24 committed-1 AND remaining-1). Duplicate/stale/unknown notifications hit no live assignment ⇒ no double decrement. M24 `remaining` never moves on claim/route/spawn.

## 5. Pacing / fairness / WAITING

- Pacing: `step()` accepts at most one assignment per call (returns on first success); never a synchronous batch burst.
- Fairness: deterministic round-robin across eligible colors ordered by oldest occupied placement sequence (never Dictionary iteration order); same-color oldest/spill ordering delegated entirely to M25.
- WAITING: a color whose oldest capacity batch yields no claimable target is marked WAITING and skipped until an authoritative wake (successful placement `notify_placed()`, authenticated clear, or `resume()`), so repeated idle steps cause zero reservation churn.

## 6. Reset / teardown ordering

`AutoDispatchScheduler.reset()` (serialized, idempotent): (1) roll back every live scheduler claim through `M25.rollback_claim` while ReservationState pairs still exist; (2) `CompleteClearingLoop.reset()` → `ScrubbotDispatcher.reset()` cancels/frees agents (finds pairs already released ⇒ no double release, zero orphan agents); (3) clear scheduler ledger. Cancelled work never decrements `remaining`; unrelated reservations survive; identities never recycled.

## 7. Test commands + results

Literal commands:
```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd
git diff --check
```

Results (this machine, Godot 4.7.2):
- `tests/run_tests.gd`: **5193 checks / 0 failures** (RESULT: ALL PASS). Includes the new M26 section.
- `tests/m26_hazard_bot_integration.gd`: **PASS** — `steps=77 clears=128 board_cleared=128 max_inflight=76 waited=true woke=true`; wake proven (128 clears > 76 initially-reachable edge ⇒ interior corridors opened); no ghost, no duplicate target, exact conservation, reset zero.
- `tests/m26_scale_59_sanity.gd`: **PASS** — `board=59x59 cells=3481 peak_inflight=30 claim_ms≈396 drain_ms≈3`; committed≤remaining every step, no duplicate target, bookkeeping bounded by slots+in-flight, quota conserved to zero, reset idempotent.
- Regression floor re-run, all exit 0:
  - M23: `m23_v01_batch_supply_evidence`, `m23_v02_hardening_evidence`, `m23_v03_transaction_identity_evidence`.
  - M24: `m24_blue_fixture_evidence`, `m24_five_full_refill_evidence`, `m24_slot_state_evidence`, `m24_supply_handoff_evidence`, `m24_v02_transaction_hardening_evidence`.
  - M25: `m25_blue_arbitration_evidence`, `m25_claim_model_evidence`, `m25_rollback_finalize_reset_evidence`, `m25_scale_evidence`, `m25_v02_strict_remediation_evidence`, `m25_v03_exact_work_binding_evidence`.
  - M22: `m22_v03_connector_evidence`, `m22_v06_real_demo_state_evidence` (V07 interior-turn covered in `run_tests.gd`).
  - M21: `m21_real_art_smoke`, `m21_v10_final_reservation_evidence`.
  - M20: `m20_queue_free_smoke`, `m20_v07_lifecycle_smoke`, `m20_v10_lifecycle_smoke`.
- `git diff --check`: clean (no whitespace/conflict errors).

## 8. Hazard Bot / 59x59 evidence traces

- Hazard Bot (`m21_level_001_hazard_bot.json`, 20x20): real BoardState/renderer + M23 fixture (per-color counts ≤ level totals: two colour-2 batches for same-color multi-batch) → M24 placement (5 slots) → M25 → real routing/RouteValidator → `dispatch_preclaimed` → ScrubbotAgent → CompleteClearingLoop. Slot origins from real laid-out `ColorSelectionPanel` SlotCell top-center anchors via `BoardPresentation.global_to_board_local()` (finite below-board starts; slot anchor → BOTTOM connector → Railroad V1 → V07 interior turns preserved). Trace: `HB_RUN steps=77 clears=128 board_cleared=128 max_inflight=76 any_waiting=true woke=true`.
- 59x59 (`3481` cells) density sanity: 30 concurrent in-flight peak, `committed<=remaining` invariant every step, no duplicate reservation, no per-tick O(board) scan (scheduler iterates 5 slots; bookkeeping bounded by slots + in-flight), quota conserved to zero, reset idempotent. Trace: `SCALE59 ... peak_inflight=30 claim_ms≈396 drain_ms≈3 loop_cleared=30 slot_empty=true`.

## 9. SB-M26-001..030 task → implementation + evidence

| Task | Implementation | Evidence |
|---|---|---|
| SB-M26-001 | `AutoDispatchScheduler` (RefCounted, gameplay-domain, no UI) | `_run_m26_scheduler_tests` bind |
| SB-M26-002 | `step()`/`run_until_idle()` auto-attempt occupied batches (no taps) | pacing/BLUE15 |
| SB-M26-003 | `notify_placed()` wake after placement | waiting/wake |
| SB-M26-004 | no claimable target ⇒ no spawn | no-ghost |
| SB-M26-005 | no successful claim/reservation ⇒ no spawn | no-ghost / preclaim |
| SB-M26-006 | no RouteValidator-clean route ⇒ no spawn | preclaim null/junk route |
| SB-M26-007 | order claim→route→validate→spawn | preclaim + `_attempt_color` |
| SB-M26-008 | no retarget; failed assignment rolled back | no-ghost (wrong origin), preclaim |
| SB-M26-009 | spawn from exact SlotCell anchor; connector/Railroad V1 preserved | Hazard Bot integration |
| SB-M26-010 | exactly one Scrubbot per accepted transaction | preclaim / pacing |
| SB-M26-011 | paced sequential dispatch, no one-frame burst | pacing (one/step) |
| SB-M26-012 | safe concurrency across slots | fairness / 59x59 peak |
| SB-M26-013 | deterministic color round-robin, no starvation | fairness round-robin |
| SB-M26-014 | same-color oldest-first delegated to M25 | fairness BLUE 8/14/12 |
| SB-M26-015 | BLUE 15 completes exactly 15 authenticated clears | BLUE15 autonomy |
| SB-M26-016 | committed/in-flight capacity bound | pacing/fairness/59x59 |
| SB-M26-017 | quota decremented only on authenticated clear | BLUE15 / bridge |
| SB-M26-018 | no claimable work ⇒ WAITING, no busy-loop/churn | waiting/wake, no-ghost |
| SB-M26-019 | wake on reachability change | waiting/wake, Hazard Bot |
| SB-M26-020 | one blue opens ⇒ one claim on M25-selected oldest | waiting/wake |
| SB-M26-021 | capacity spill to next same-color batch | fairness BLUE 8/14/12 |
| SB-M26-022 | auto-finish batch, slot → EMPTY | BLUE15 completion |
| SB-M26-023 | freeing slot doesn't reorder others / mutate supply | BLUE15 + M24 semantics |
| SB-M26-024 | pause blocks new dispatch, preserves state | pause/resume/reset |
| SB-M26-025 | resume without duplicate claim/spawn | pause/resume/reset |
| SB-M26-026 | reset releases claims/reservations, no orphan nodes | reset + Hazard Bot reset |
| SB-M26-027 | rapid input can't double-spawn/over-commit/dup target | no-ghost, 59x59, reentrancy guards |
| SB-M26-028 | multiple duplicate-color + different-color batches | fairness |
| SB-M26-029 | 59x59 high-density perf/allocation sanity | `m26_scale_59_sanity` |
| SB-M26-030 | Hazard Bot auto-dispatch integration smoke | `m26_hazard_bot_integration` |
