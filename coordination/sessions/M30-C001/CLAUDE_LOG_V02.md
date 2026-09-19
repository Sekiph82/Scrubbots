# M30-C001 V02 — CLAUDE IMPLEMENTATION LOG (Narrow Remediation)

Milestone: `M30 — Win/Lose Rules`
Cycle: `M30-C001 V02` (narrow remediation of the three V01 audit findings)
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Implementation commit (pushed BEFORE this log): `f307bd29a4656ec1b815e91f43c293e7d8e75d4a`
Status handoff: `AWAITING_AUDIT`

Authority followed: `coordination/sessions/M30-C001/CHATGPT_AUDIT_V01.md`,
`coordination/sessions/M30-C001/CHATGPT_PROMPT_V02.md`,
`coordination/sessions/M30-C001/CHATGPT_AUDIT_CRITERIA_V02.md`,
`coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`.

V01 core M30 architecture (real M27 DEADLOCK authority, DEADLOCK-only LOST, exact-once terminal latch, event/dirty-gated proof, terminal input/scheduler stop, same deterministic supply reset, M26-first Retry gate) is ACCEPTED and was NOT rewritten. Only the three findings were fixed, in one continuous pass.

---

## 0. Git sync / owner-work preservation

- Repository `Sekiph82/Scrubbots`, branch `main` confirmed.
- `origin/main` was 4 commits ahead (coordination docs + ChatGPT tracker update). Fast-forwarded non-destructively (`git merge --ff-only`). No `reset --hard` / `clean` / force. Owner untracked assets and the owner working-tree `project.godot` change were preserved and NOT committed. Root `TASKS.md` was READ-only and NOT edited.

---

## 1. F-M30-V01-001 — complete cross-engine inconsistency detection

Code: `scripts/gameplay/completion/completion_evaluator.gd`
- New `transaction_cardinalities(scheduler, dispatcher, claim, reservations, slots)` returns the ordered five live counts: M26 assignments, M19 dispatcher agents, M25 claims, ReservationState reservations, M24 committed work.
- `has_fatal_inconsistency(...)` now returns true on `scheduler.is_fatal()` OR ANY cardinality drift across the five (previously only scheduler↔dispatcher).
- `evaluate()` classifies: all-equal → consistent (all-zero routes to WIN/deadlock proof; all-equal-positive → PLAYING `in_flight_work`); any drift → `ERROR` (`cross_engine_inconsistency`). Never LOST, never indefinite PLAYING.

Contract: owner decision §2 (cross-engine inconsistency fails closed as an error, not a LOSE). Evaluated only at the stable runtime state-sync tail (unchanged), never mid half-step.

Tests: `tests/m30_completion_authority.gd` `_test_cross_engine_consistency`:
- all five == N (N=1,2,5) → legitimate in-flight PLAYING;
- each single-axis drift (scheduler / dispatcher / claim / reservation / M24 committed) → ERROR and never LOST;
- each lone orphan-from-zero (e.g. sched=0,disp=0,claim=1) → ERROR (not indefinite PLAYING);
- all-zero → quiescent (not ERROR).
The existing healthy-in-flight LOSE test was updated to an all-five-equal shape.

## 2. F-M30-V01-002 — Retry restore preflight + required candidate rebuild

Code: `scripts/gameplay/completion/retry_coordinator.gd`
- New `_preflight(bundle)` runs BEFORE the first destructive `scheduler.reset()`: validates every required restore collaborator exists with its required method surface (`board`, `slots`, `supply`, `runtime`, `input`, `completion`, `clearing_loop`, `candidate_index`), that the candidate index is bound to the EXACT production board, that a SUPPLIED renderer is bound to that exact board, and that a SUPPLIED (non-empty) restore callback is valid. On any failure: return false, `scheduler.reset` called ZERO times, nothing mutated.
- After the clean gate + `board.restore_all_active()`, `_rebuild_candidate_coherent(ci, board)` REQUIRES `candidate_index.rebuild()==true`, the index still bound to the exact board, AND total candidate population == board ACTIVE count. Retry never returns true on rebuild/coherence failure. Runtime/input/completion resets run only after this postcondition passes.
- M26/M13 fail-closed semantics unchanged (only their contracts are required to hold).
- `production_gameplay_host.gd` retry bundle unchanged except it now supplies `clearing_loop` (used by §3) and the same renderer/board/ci it already owned.

Contract: owner decision §6 (preflight first, then teardown, never half-old/half-new, coherent candidate truth). Criteria V02 §2/§3.

Tests: `tests/m30_transaction_safe_retry.gd`:
- `_test_preflight_fails_before_teardown`: candidate index bound to wrong board / restore collaborator missing a required method / supplied renderer not bound to board / invalid supplied callback → each returns false with `scheduler.reset` call count == 0 and nothing mutated.
- `_test_rebuild_failure_never_returns_true`: a candidate-index double that passes preflight but whose `rebuild()` returns false → Retry returns false; the gate WAS reached (reset_calls==1); runtime/input/completion were NOT reset (no false fresh attempt).
- `_test_gate_success_restores`: real board + real ColorCandidateIndex → full ACTIVE restore, candidate index repopulated (total == cell count) and still bound, all collaborators restored, scheduler resumed.
- `_test_gate_fail_closed_atomicity` (retained): every M26 gate-failure mode fails closed with a real board left unrestored and no collaborator touched.

## 3. F-M30-V01-003 — M20 attempt-scoped observation reset

Code: `scripts/gameplay/clearing/complete_clearing_loop.gd`
- New `reset_attempt_observation()` zeros ONLY `_cleared_count` and `_last_outcome` (→ `Outcome.NONE`). Historical `reset()` (in-flight cancellation, preserves cumulative history) is UNCHANGED.
- `retry_coordinator.gd` calls it ONLY after the M26 teardown gate succeeds (and after board restore), before the candidate-rebuild postcondition. `production_gameplay_host.gd` supplies `clearing_loop` in the validated restore bundle.

Contract: owner decision §5 (fresh attempt) without altering the accepted M20 reset contract. Criteria V02 §4.

Tests: `tests/m30_manual_playtest_smoke.gd`:
- after a full 400-cell Hazard attempt: M20 `cleared_count == 400`, `last_outcome == CLEARED`;
- after successful Retry: `cleared_count == 0`, `last_outcome == NONE`;
- after replay: `cleared_count == 400` (new attempt only, not cumulative 800).
Gate-failure "observation unchanged" is covered in `m30_transaction_safe_retry.gd` (the clearing-loop collaborator is not touched on any fail-closed path).

---

## 4. End-to-end fresh attempt (criteria V02 §5)

`m30_manual_playtest_smoke.gd` drives the real host (real M28 screen + real M23–M29 stack + real M30 authority) and, after a real played Hazard attempt + successful Retry, asserts: full board ACTIVE, exact same initial M23 `debug_snapshot()`, five slots EMPTY, M24 committed 0, M25 claims 0, reservations 0, scheduler assignments 0, dispatcher agents 0, M20 cleared_count 0, M20 last_outcome NONE, candidate index bound+repopulated (verified via the RetryCoordinator postcondition), speed 1x, runtime/input terminal stop false, completion PLAYING; and the replay produces a current-attempt-only clear count. Proven for both the WON path and the LOST deadlock-fixture path.

---

## 5. Validation run (this machine, Godot 4.7.2.stable)

- Root suite `res://tests/run_tests.gd` → **RESULT: ALL PASS**, Failures: 0, exit 0.
- V02 regression floor (standalone), all exit 0: `m30_completion_authority`, `m30_manual_playtest_smoke`, `m30_transaction_safe_retry`, `m29_realtime_movement_smoke`, `m29_slot_display_sync_evidence`, `m29_exact_slot_origin_evidence`, `m29_hazard_bot_runtime_smoke`, `m29_input_gate_evidence`, `m29_speed_authority_evidence`, `m27_hazard_bot_solve`, `m27_scale_59`, `m27_generation_retry`, `m26_hazard_bot_integration`, `m26_scale_59_sanity`, `m25_v03_exact_work_binding_evidence`, `m24_v02_transaction_hardening_evidence`, `m23_v03_transaction_identity_evidence`, `m22_railroad_responsive_smoke`, `m20_queue_free_smoke`, `m20_v04_lifecycle_smoke`, `m20_v10_lifecycle_smoke` → 22/22 PASS.
- Real-play cross-engine guard: the new five-way consistency check runs every state-sync tick during the real WON and real LOST runs in `m30_manual_playtest_smoke` and never false-latched ERROR — confirming the five cardinalities stay equal in healthy in-flight play.
- `git diff --check` on tracked edits → clean (only benign LF→CRLF notices).

### Pre-existing unrelated failures (documented, not modified)
`tests/m21_v08_corridor_validation.gd` and `tests/m21_v09_direct_evidence_reconciliation.gd` fail on exterior-route corridor geometry, reproduced on the pre-M30 baseline (audit V01 §"Accepted regression evidence"). Outside this remediation's scope; not touched.

---

## 6. Boundaries honored

- V01 accepted behavior preserved (real M27 classifier, DEADLOCK-only LOST, no WAITING/STALLED/UNKNOWN loss, exact-once terminal latch, event-gated proof, terminal input/scheduler/runtime stop, same-puzzle supply reset, M23–M29 accepted gameplay, current owner playtest scene behavior).
- No M31. No Economy. Zero AI image generation. Root `TASKS.md` read-only for Claude.

---

## 7. Files in the implementation commit (`f307bd2`)

Modified:
- `scripts/gameplay/completion/completion_evaluator.gd` — full five-way cross-engine guard (F1).
- `scripts/gameplay/completion/retry_coordinator.gd` — preflight + required candidate rebuild postcondition + clearing-loop observation reset wiring (F2/F3).
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — `reset_attempt_observation()` seam (F3).
- `scripts/gameplay/runtime/production_gameplay_host.gd` — supply `clearing_loop` in the validated retry bundle.
- `tests/m30_completion_authority.gd` — cross-engine drift/healthy-positive tests.
- `tests/m30_transaction_safe_retry.gd` — preflight-before-teardown + rebuild-failure + gate-success coherence.
- `tests/m30_manual_playtest_smoke.gd` — M20 observation reset + replay-only count.

Not touched: root `TASKS.md`, `project.godot` (owner working-tree change), all owner assets.

---

Handoff: `AWAITING_AUDIT`.
