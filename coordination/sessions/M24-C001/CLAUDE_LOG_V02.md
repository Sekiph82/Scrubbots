# M24-C001 V02 — Five-Slot Batch Engine Transaction Hardening — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Prior verdict: `CHANGES_REQUIRED` (`CHATGPT_AUDIT_V01.md`; findings F-M24-V01-STRICT-001/-002)
Handoff state: `AWAITING_AUDIT`

## 1. Commit identities

- **Safe-sync start `origin/main` SHA:** `97a8f44` (fast-forward `79e3754..97a8f44`;
  incoming commits were M24 V02 coordination/tracker only — none touched `project.godot`,
  `scripts/` or `tests/`). Owner-local `project.godot` + untracked `.import`/`.uid`
  sidecars preserved, left unstaged. No `reset --hard` / `clean -fd` / destructive restore
  / force push.
- **Implementation SHA (single focused commit, pushed first):**
  `808a06fd97ef1a7f271f675767cb9eb6697074b0`
  (`fix(M24-C001 V02): serialize whole mutation surface during placement`).
- **Final implementation SHA:** `808a06fd97ef1a7f271f675767cb9eb6697074b0`.
- **This log** is a separate final documentation commit pushed afterward.

## 2. Changed files

Production:
- `scripts/gameplay/slots/five_slot_batch_engine.gd` — global `_busy` mutation guard on
  the entire public mutation surface; `reset()` returns bool and never touches `_busy`
  while busy.
- `scripts/gameplay/slots/slot_batch_state.gd` — `set_state()` hardened to a type-checked,
  fail-closed setter restricted to EMPTY/ACTIVE/WAITING.

Tests:
- `tests/support/m24_callback_supply.gd` (new) — configurable adversarial M23 double
  (begin-callback / commit-callback / forced commit failure).
- `tests/m24_v02_transaction_hardening_evidence.gd` (new) — dedicated V02 evidence.
- `tests/run_tests.gd` — `_m24_v02_serialization()` root block (+18 checks).

Historical `slot_system.gd` / `slot_state.gd` direct-color behavior untouched. No M23
supply change. No protected M22/M21/M20 change. Root `TASKS.md` absent.

## 3. Mutation-serialization design (F-M24-V01-STRICT-001)

A single engine-owned boolean `_busy` is set for the WHOLE supply-placement transaction:
`select_front_batch()` sets `_busy = true`, calls `_select_front_batch_guarded()` (which
performs the M23 `begin_front_selection` AND `commit` — the two possible external-callback
boundaries), then sets `_busy = false`. Every public mutator now checks `_busy` first and
fails closed with zero state change when set:

- `select_front_batch` → returns `{ "error": "reentrant" }`;
- `commit_work` / `resolve_clear` / `rollback_work` / `set_claimable_work_available` →
  return `false`;
- `pause` / `resume` → return without mutating `_paused`;
- `reset` → returns `false` and does NOT clear/reopen `_busy` or touch any field.

`reset()` is now `-> bool` (ordinary reset returns `true`; busy reset returns `false`).
Because it no longer writes `_busy = false`, a reset requested from inside a placement
callback cannot reopen the transaction guard. There is no reachable state where M23 is
consumed while M24 is reset/empty, and the outer placement always uses the rightmost-empty
slot from stable serialized state.

## 4. Lifecycle hardening (V01 non-blocking observation)

`SlotBatchState.set_state(new_state)` now returns `bool`, rejects non-String and any value
other than `EMPTY`/`ACTIVE`/`WAITING`, and leaves state unchanged on rejection. Engine-owned
state can never become an out-of-domain string.

## 5. Direct adversarial evidence

`tests/m24_v02_transaction_hardening_evidence.gd` →
`M24 V02 transaction-hardening evidence: PASS` (exit 0). Mirrored in the root suite
(`_m24_v02_serialization`).

### Scenario A — begin() callback re-entry
```
  ok: A: nested reset() returned false (fail-closed)
  ok: A: nested select rejected reentrant
  ok: A: nested commit_work rejected while busy
  ok: A: nested set_claimable rejected while busy
  ok: A: pre-existing slot 0 untouched (ACTIVE, committed 0)
  ok: A: outer placement used correct rightmost-empty slot 4
  ok: A: exactly one new occupancy; no ghost/double insert
```

### Scenario B — commit() callback re-entry
```
  ok: B: nested reset() from commit callback fail-closed
  ok: B: nested select from commit callback rejected
  ok: B: nested commit_work from commit callback rejected
  ok: B: nested set_claimable from commit callback rejected
  ok: B: pre-existing slot 0 untouched
  ok: B: outer placement completed correctly after commit callback
```

### Scenario C — failed/stale M23 commit (F-M24-V01-STRICT-002)
```
  ok: C: select reports supply_commit_failed
  ok: C: all five slots exact-prestate (no ghost, no placement)
  ok: C: placement sequence did not advance
  ok: C: live-work ledger unchanged
  ok: C: rightmost-empty truth intact (slot 4 still empty)
  ok: C: engine still functional; next placement fills slot 4
```
The double's `commit(tx)` returns false deterministically without mutating M24. This is a
pure M24-side commit-failure proof (the tightly scoped double controls M23), so M24
exact-prestate is asserted; no claim about M23 byte-equality is made.

### Lifecycle hardening
```
  ok: L: valid WAITING accepted
  ok: L: valid ACTIVE accepted
  ok: L: invalid state rejected, unchanged
  ok: L: empty state rejected
  ok: L: non-string state rejected
  ok: L: EMPTY accepted
```

## 6. Finding closure mapping

| Finding | Production code | Direct test evidence | Result |
|---------|-----------------|----------------------|--------|
| F-M24-V01-STRICT-001 (global mutation serialization; reset must not reopen guard) | `five_slot_batch_engine.gd` `_busy` checks on all mutators; `reset()->bool` never clears `_busy` while busy | evidence Scenario A + B; run_tests `_m24_v02_serialization` A/B | CLOSED |
| F-M24-V01-STRICT-002 (failed/stale M23 commit exact prestate) | existing `supply_commit_failed` branch (post-commit placement infallible) | evidence Scenario C; run_tests `_m24_v02_serialization` C | CLOSED |
| V01 non-blocking (arbitrary `set_state`) | `slot_batch_state.gd` validated `set_state()->bool` | evidence lifecycle; run_tests V02 L | CLOSED |

## 7. Preserved V01 behavior (SB-M24-001..030)

Five initially EMPTY slots, rightmost-empty placement, no player slot choice, no
shift/compaction, full-five atomic rejection, same-color independence, BLUE 8/14/12, stable
batch IDs, counter invariants/capacity, live-work accounting (duplicate/unknown/double
fail closed), resolve decrements remaining+committed, rollback decrements committed only,
true completion frees only the completed slot, WAITING/ACTIVE, detached snapshots,
pause/resume, ordinary reset + pre-reset work invalidation, five-full→complete→refill,
deterministic replay — all retained and green (dedicated V01 evidence scripts + root
suite).

## 8. Validation commands / results / exits

Run from `C:\Users\sekip\Desktop\ScrubBots`.

| # | Command | Result | Exit |
|---|---------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 5090, Failures: 0, RESULT: ALL PASS** | 0 |
| 3 | `... res://tests/m24_v02_transaction_hardening_evidence.gd` | PASS | 0 |
| 4 | `... res://tests/m24_slot_state_evidence.gd` | PASS | 0 |
| 5 | `... res://tests/m24_supply_handoff_evidence.gd` | PASS | 0 |
| 6 | `... res://tests/m24_blue_fixture_evidence.gd` | PASS | 0 |
| 7 | `... res://tests/m24_five_full_refill_evidence.gd` | PASS | 0 |
| 8 | `... res://tests/m23_v03_transaction_identity_evidence.gd` | PASS | 0 |
| 9 | `... res://tests/m23_v02_hardening_evidence.gd` | PASS | 0 |
| 10 | `... res://tests/m23_v01_batch_supply_evidence.gd` | PASS | 0 |
| 11 | `... res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 12 | `... res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 13 | `... res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 14 | `... res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 15 | `... res://tests/m21_real_art_smoke.gd` | PASS | 0 |
| 16 | `... res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 17 | `... res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 18 | `... res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 19 | `git diff --check` | clean (only informational LF→CRLF notices) | 0 |

Root-suite check count moved 5072 → 5090 (+18 V02 serialization/lifecycle assertions).

## 9. Statements

- `root TASKS.md modified = NO`.
- `M25-M27 implementation = NO` (no target arbitration/claim, ReservationState change,
  dispatch/routing/spawn, or solvability/deadlock).
- `image-generation credits spent = 0`.
- No protected system modified; historical direct-color SlotSystem untouched; all
  M23/M22/M21/M20 regressions green.
- No audit verdict authored. `AWAITING_AUDIT`.
