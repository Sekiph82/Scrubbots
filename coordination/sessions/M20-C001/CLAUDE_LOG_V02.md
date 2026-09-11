# CLAUDE_LOG_V02 — M20-C001 Strict-v2 Transaction Correction

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V02.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
- Frozen surface: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
- V01 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V01.md`
- Actor: CLAUDE (implement + test only). Handoff: AWAITING_AUDIT.
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Starting `origin/main`: `91bedaa` (V02 prompt + criteria issued)
- Tracker start transition (IN_PROGRESS): `72fd0dd`
- Result: full headless suite **3501 / 3501 PASS**, exit 0 (V01 baseline 3386;
  **+115 V02 checks**). Dedicated deferred-free smoke passes separately.

Claude did NOT modify any `CHATGPT_*` artifact, audit verdict, SB-M20 checkbox,
`.hiveai/*`, `coordination/SESSION_INDEX.md`, or unrelated production. Pre-existing
owner working-tree changes preserved and left unstaged.

## 0. Tracking / start-order (§0)
1. Synced `origin/main` fast-forward (`3071197..91bedaa`), owner work preserved.
2. Verified `CHATGPT_AUDIT_V01.md` + V02 prompt/criteria present on synced main.
3. Verified root `TASKS.md` still at M20-C001 V01 / AWAITING_AUDIT / CHATGPT.
4. Set Project Status to M20 / M20-C001 V02 / IN_PROGRESS / CLAUDE.
5. Committed + pushed the tracker-only transition (`72fd0dd`) BEFORE any V02 edit.
6. Verified remote `origin/main` carried IN_PROGRESS.

## Files changed (excluding auto `.uid`)
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — rewritten for the V02
  transaction engine (bind transaction, serialized activation, lossless serial
  arrival queue, transactional reset, corrected order, pre-state snapshot,
  postcondition verification, verified rollback + ROLLBACK_FAILED).
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — minimal reset() hardening:
  cancelled agents are `queue_free()`d (were `free()`d). Required because the V02
  transactional reset can be driven from inside an arrival/completion signal
  stack, where a synchronous `free()` of the still-emitting agent is a
  locked-object error that aborted `reset()` mid-cleanup. `_active`/reservations
  are still cleared synchronously; only node destruction defers. No M19
  authentication/finalization identity changed.
- `tests/run_tests.gd` — 8 new V02 sections + preloads.
- `tests/support/m20_candidate_seam.gd` — NEW adversarial candidate subclass.
- `tests/support/m20_reservation_seam.gd` — NEW adversarial reservation subclass.
- `tests/m20_queue_free_smoke.gd` — NEW dedicated deferred-destruction smoke.
- `docs/02_TECH_ARCHITECTURE.md` — corrected M20 order (renderer after finalize).
- `TASKS.md` — Project Status lifecycle only (IN_PROGRESS → AWAITING_AUDIT).
- `coordination/sessions/M20-C001/CLAUDE_LOG_V02.md` — this log.

## Pre-fix V01 sensitivity (§18)
The V01 implementation had no bind transaction guard, no activation guard, no
serial arrival queue, no loop reset generation, no pre-state snapshot,
best-effort (`_restore_candidate`) rollback with no verification, and committed
the renderer BETWEEN reservation resolve and dispatcher finalize. The following
V02 tests exercise mechanisms V01 did not have, so they are recorded as V01
**coverage gaps** now closed (not as pre-existing green):
- nested bind from a coherence callback (V01 bind was not a guarded transaction);
- reset injected during activation preflight / inside a candidate/reservation
  callback (V01 had no generation/deferred reset — a synchronous
  `dispatcher.reset()` mid-arrival hit the locked-object abort now fixed);
- candidate/reservation mutate-before-false and true-without-postcondition (V01
  rollback tests were friendly false-without-mutation only, and V01 verified no
  postcondition);
- true 1×1 BoardState (V01 used 20×20 with one ACTIVE cell);
- distinct nested arrival while a transaction commits (V01 had no serial queue);
- actual deferred-free after a real frame (V01 could not await under the root
  runner — added as a dedicated smoke script).

## Evidence mapped to frozen findings

### F-M20-STRICT-001 — bind transaction (§2)
`bind()` arms `_in_bind` before the first coherence callback; validation runs a
coherence probe TWICE (drift detection) and the `assignment_arrived` signal is
connected ONLY after all validation + `active_count==0`. Board/Slot/Dispatcher/
Renderer are narrowed to EXACT production script identity (`get_script()==…`);
only candidate/reservation accept subclasses (rollback seams). Tests
`_run_m20_v02_bind_transaction_tests`: nested bind from candidate `is_bound_to`
callback → false with exactly ONE signal connection (no ghost); callback-induced
same-size foreign-board drift → bind false, loop unbound, zero connections;
non-exact board script rejected. Plus V01 bind-contract tests still green.

### F-M20-STRICT-002 — activation transaction (§3)
`activate_slot()` rejects REENTRANT while `_in_activation`/`_draining`, RESETTING
while a reset is pending or injected during preflight, and re-checks
generation+coherence after the preflight callbacks before dispatch. Tests
`_run_m20_v02_activation_serialization_tests`: nested activation from the
coherence callback → REENTRANT, zero extra agent/reservation; reset injected in
the coherence callback → RESETTING, no dispatch, owner id NOT advanced, nothing
reserved; later ordinary activation recovers. Slots unchanged (V01 activation
tests still green).

### F-M20-STRICT-003 — arrival identity + failed-preflight recovery (§15)
M19 identity bridge preserved (exactly-once emission unchanged). Test in
`_run_m20_v02_direct_observability_tests`: an authenticated arrival that fails M20
preflight (reservation desynced) → PREFLIGHT_REJECTED, held not half-cleared,
BoardState unchanged, dispatcher still holds it; `loop.reset()` then removes the
stranded assignment + any reservation without changing BoardState; stale replay
after reset cannot clear; later normal activation works.

### F-M20-STRICT-004 — corrected order + postconditions + rollback (§6–§11)
Order is now BoardState → candidate → reservation → dispatcher finalize → optional
renderer (renderer never between resolution and finalization). Each step captures
a detached pre-state snapshot (`_snapshot`) and verifies its postcondition;
`_run_m20_v02_transaction_order_tests` asserts every one (board CLEARED + color
unchanged, raw candidate membership gone, reservation owner/target −1 and count
−1, dispatcher owner absent + active −1, renderer alpha 0 AFTER finalize).
Mutation-sensitive rollback in `_run_m20_v02_mutation_rollback_tests` (all with a
bound renderer): candidate mutate-false, candidate true-noop, candidate
neutralize-false, reservation mutate-false, reservation true-noop — each yields
the verified `CANDIDATE_ROLLBACK` / `RESERVATION_ROLLBACK` outcome, restores the
exact pre-arrival tuple (board ACTIVE, raw candidate membership present, exact
reservation pair, dispatcher arrival still pending, cleared_count 0) and leaves
the renderer pixel source/opaque (no transparent false-clear). Rollback is
verified (`_verify_pre_arrival`); an unrestorable tuple would surface the explicit
`ROLLBACK_FAILED`. Candidate neutralize rollback uses the exceptional
`rebuild()`/`rebind(_board)` recovery only on rollback; the healthy path stays
single-cell.

### F-M20-STRICT-005 — full AL-028 second activation (§13)
`_run_m20_v02_reachability_second_activation_tests` on the real production stack:
B unreachable before A clears; first `activate_slot` clears gate A; A CLEARED,
absent from candidates, OPEN to ProductionAccessQuery; a SECOND real
`activate_slot` selects/reserves B (`target_index == B`, B reserved); B driven to
arrival clears with a synchronized final tuple. Not a bare `is_targetable` probe.

### F-M20-STRICT-006 — arrival serialization + reset (§4/§5)
Private `_arrival_queue` drained by a single `_draining` processor; a distinct
authenticated arrival injected during the first transaction (via a candidate
sync-callback driving a second agent to arrival) is queued and drained after —
`_run_m20_v02_serial_arrival_tests` proves both A and B clear (no lost arrival).
Duplicate same assignment is deduped by owner+agent. Reset during arrival
(`_run_m20_v02_reset_during_arrival_tests`): reset injected in the candidate sync
callback and in the reservation resolve callback each yields `RESET_ABORTED` with
BoardState preserved (target still ACTIVE, not cleared), the in-flight assignment
+ reservation removed, nothing cleared, loop coherent afterward — the heavy
`dispatcher.reset()` is deferred to a safe point and never runs mid-mutated tuple.

### F-M20-STRICT-007 — direct-observability completion (§14)
`_run_m20_v02_direct_observability_tests`: real 1×1 BoardState (width/height/
cell_count == 1) dispatched/arrived/cleared, second activation no work; five-slot
identity proof (five success results, five unique owner ids, five distinct
targets, five exact reservation pairs, active_count == 5; first arrival preserves
the other four in-flight; then all resolve). Renderer-present candidate and
reservation rollback keep the source pixel opaque (covered in the rollback
section). Deferred destruction proven by the dedicated smoke script (below).

## Validation (§18, run individually)
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` → `Total checks: 3501 /
  Failures: 0 / RESULT: ALL PASS`, exit 0.
- `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` →
  `M20 queue_free smoke: PASS — deferred destruction verified: agent freed after
  one frame, no orphan child`, exit 0.
- `git diff --check` → clean (only benign LF→CRLF advisories on pre-existing
  owner-modified files; no whitespace errors introduced).
- Normal successful clear remains one board write + one single-cell candidate
  sync + O(1) reservation resolve + O(1) dispatcher finalize + one renderer cell
  repaint; full candidate rebuild/rebind occurs only on exceptional rollback.
- 59×59 + rectangular + rapid sequential coverage (V01 scenario matrix) still
  green; every M19 V01–V06 test still green (the reset queue_free change altered
  no count/identity assertion).
- TASKS lifecycle: before V02 = V01/AWAITING_AUDIT/CHATGPT; start = V02/
  IN_PROGRESS/CLAUDE (`72fd0dd`); after = V02/AWAITING_AUDIT/CHATGPT.

## Governance / handoff (§17/§19)
Modified only authorized surfaces (M20 loop, minimal M19 reset seam, tests,
support doubles, smoke, M20 doc note, log, TASKS lifecycle). Did NOT mark
COMPLETE/READY_FOR_NEXT_TASK or any SB-M20 checkbox. Progress unchanged
(290/719 = 40.33% main+ui; 290/943 = 30.75% overall; lastCompletedTaskId
M19-C001-V06). Tracker set to AWAITING_AUDIT / CHATGPT. Implementation + tests +
smoke + doc + log + tracker handoff committed and pushed; remote verified.

Return: `AWAITING_AUDIT`.
