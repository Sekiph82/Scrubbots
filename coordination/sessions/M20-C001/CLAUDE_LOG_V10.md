# CLAUDE_LOG_V10 — M20-C001 Final Closure-Only Exact-Evidence Reconciliation

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V10.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V10.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V10.md`
- V09 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V09.md`
- Actor: CLAUDE (validation only — no committed `scripts/**` change).
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- V10 tracker start transition (IN_PROGRESS): `e3764aa` (verified on remote).
- Accepted V07 implementation commit: `e189ee8`.

## OUTCOME
Clean. Entire V10 closure-only reconciliation set executed; production immutable;
no defect exposed. Per prompt §9, no production sensitivity mutations are required
in V10 (S1–S6 remain fully proven in CLAUDE_LOG_V09.md) and none were run. Return
`AWAITING_AUDIT`.

## 0. Tracker start
Synced ff (`a7ac79d..9b37678`), owner work preserved. Verified V09 audit + V10
freeze/prompt/criteria; tracker at V09/AWAITING_AUDIT/CHATGPT. Set V10/IN_PROGRESS/
CLAUDE and pushed the tracker-only transition `e3764aa` BEFORE any V10 test/smoke
edit; verified on remote. NO V10 validation edit existed before the successful push.

## 1. Production lock
Pre- and post-validation blobs (matched the locked expected values):
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `eee10149e4f116af6706beec832042352bf3a6dd`.
`git diff e189ee8 -- scripts/` is EMPTY. No `scripts/**` committed.

## 2–7. V10 reconciliation groups
`_run_m20_v10_closure_reconciliation_tests()` in `tests/run_tests.gd` with groups
`_v10_g01_claim_reset_usability`, `_v10_g02_activation_serialization`,
`_v10_g03_failed_preflight_matrix`, `_v10_g04_ledger_identity`,
`_v10_g05_rollback_prestate`, plus the frame smoke `tests/m20_v10_lifecycle_smoke.gd`.
All prior M19/M20 regressions remain enabled.

- G-V09-01 claim/reset ACTUAL usability: diagnostic before first bind; first loop
  clears A; snapshot BoardState + exact reservation map/count; owner reset with no
  active work leaves both snapshots unchanged; second different loop still cannot
  bind; the ORIGINAL first loop then performs a SECOND real activation/dispatch/
  arrival and clears B (cleared_count 1→2); second loop cleared_count stays 0; B is
  directly asserted CLEARED. Actual second gameplay operation used, not is_coherent.
- G-V09-02 activation serialization: 2A nested activation from the outer preflight
  coherence callback → nested REENTRANT, outer succeeds, active/reservation count 1,
  `peek_next_owner_id() == before + 1` (nested consumed no token). 2B activation
  during arrival drain (`_draining` true via candidate sync hook) → inner REENTRANT,
  owner id unchanged (no token), no extra active agent, A completes normally, a
  later ordinary activation clears B.
- G-V09-03 exact failed-preflight matrix: missing reservation; candidate
  rebind(foreign); candidate rebind(null); externally CLEARED; renderer foreign
  after dispatch/before arrival; renderer queued after dispatch/before arrival —
  each asserts PREFLIGHT_REJECTED/no clear, cleared_count unchanged, BoardState
  expected state, reservation BOTH directions when the pair should remain,
  dispatcher assignment pending, raw target candidate present when BoardState ACTIVE
  and candidate healthy, and an unrelated sentinel unchanged. Frame smoke adds the
  truly-freed renderer before arrival (same preservation incl. raw candidate +
  owner→target) and the failed-preflight cleanup proof.
- G-V09-04 exact ledger identity: five-slot — after the first arrival
  `get_owner(target)==-1` and `get_target_for_owner(owner)==-1`, the other four
  exact BOTH directions, then all five finalize with active/reservation counts 0.
  Scale rows Easy/Medium/Hard/Very-Hard/59×59/rectangular — expected target index
  recorded, real sequence run, success asserted, `get_cell_state(expected)==CLEARED`
  asserted directly, total CLEARED delta exactly +1.
- G-V09-05 detached rollback prestate: candidate mutate-before-false with T +
  same-color U + different-color V + an unrelated reservation — detached prestate
  (full BoardState, target/same-color bucket, different-color bucket, exact
  reservation map/count, active count, dispatcher owner identity) captured and, on
  CANDIDATE_ROLLBACK, every field compared exactly. Reservation mutate-before-false
  with the current pair + an unrelated pair — detached exact target→owner map/count,
  owner→target reverse identity for both owners, BoardState, dispatcher active/owner
  captured and, on RESERVATION_ROLLBACK, every field compared exactly.

## 8. Failed-preflight cleanup frame proof (`tests/m20_v10_lifecycle_smoke.gd`)
Held one real assignment via an intentional wrong-owner preflight failure; confirmed
it stayed pending; reserved an unrelated sentinel; called the authorized loop reset;
awaited frames; proved the held agent is no longer valid, the dispatcher has no
orphan child, the original reservation pair is gone BOTH directions, and the
unrelated sentinel reservation and cell remain intact.

## 9. Final validation
- Final blobs: loop `06391839523cbc27e88a4b3ef12b730012cd45fa`, dispatcher
  `eee10149e4f116af6706beec832042352bf3a6dd` (match locked V07 values).
- `git diff e189ee8 -- scripts/` EMPTY.
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- Full root suite → `Total checks: 4262 / Failures: 0 / RESULT: ALL PASS`, exit 0.
- Smokes (each run separately) PASS: `tests/m20_queue_free_smoke.gd`,
  `tests/m20_v04_lifecycle_smoke.gd`, `tests/m20_v05_lifecycle_smoke.gd`,
  `tests/m20_v07_lifecycle_smoke.gd`, `tests/m20_v08_lifecycle_smoke.gd`,
  `tests/m20_v09_lifecycle_smoke.gd`, `tests/m20_v10_lifecycle_smoke.gd`.
- Zero final M20 `SCRIPT ERROR` / `Parse Error` (only the pre-existing importer
  negative-path file-test ERROR lines appear).
- `git diff --check` clean (benign LF→CRLF advisories only).
- Changed files: `tests/run_tests.gd`, `tests/m20_v10_lifecycle_smoke.gd` (new),
  `TASKS.md`, `coordination/sessions/M20-C001/CLAUDE_LOG_V10.md`. No `scripts/**`,
  no docs, no test-support change.

## 10. G-V09 evidence table

| Row | Test / smoke name | Exact assertions | Actual result | Evidence source |
|---|---|---|---|---|
| G-V09-01 | `_v10_g01_claim_reset_usability` (+ v09/v10 smokes for GC) | first clears A; owner reset preserves BoardState + reservation map/count; second loop cannot bind; ORIGINAL loop second activation clears B; cleared_count 1→2; second loop 0; B CLEARED | PASS | synchronous root-suite (GC release: frame smoke) |
| G-V09-02 | `_v10_g02_activation_serialization` | 2A nested REENTRANT, outer succeeds, active/res 1, next-owner==before+1; 2B inner REENTRANT during drain, no token/agent, A completes, later activation usable | PASS | synchronous root-suite |
| G-V09-03 | `_v10_g03_failed_preflight_matrix` + `tests/m20_v10_lifecycle_smoke.gd` | missing/candidate-foreign/candidate-null/CLEARED/renderer-foreign/renderer-queued: rejected, no clear, reservation both directions + assignment + raw candidate held where required, sentinel intact; truly-freed renderer + failed-preflight cleanup | PASS | root-suite + frame-smoke |
| G-V09-04 | `_v10_g04_ledger_identity` | five-slot first arrival both directions -1, four exact both directions, all finalize (active/res 0); scale rows expected-target CLEARED + delta +1 | PASS | synchronous root-suite |
| G-V09-05 | `_v10_g05_rollback_prestate` | candidate mutate-before-false: full detached prestate (board/buckets/map/count/active/owner) compared exactly on CANDIDATE_ROLLBACK; reservation mutate-before-false: exact map/count + reverse identity + board + dispatcher compared on RESERVATION_ROLLBACK | PASS | synchronous root-suite |
| G-V09-06 | this table + CLAUDE_LOG_V10.md | exact test/smoke + assertion names + result + sync-vs-frame source; no aggregate substitution | PASS | log |

## 11. Handoff
Did NOT close any SB-M20 checkbox or mark COMPLETE/READY_FOR_NEXT_TASK. Progress
unchanged (290/719; 290/943; lastCompletedTaskId M19-C001-V06). Tracker set to
M20-C001-V10 / AWAITING_AUDIT / CHATGPT. Validation tests/smoke/log/tracker committed
and pushed; remote verified; production blobs remain the exact locked V07 values.

Return: `AWAITING_AUDIT`.
