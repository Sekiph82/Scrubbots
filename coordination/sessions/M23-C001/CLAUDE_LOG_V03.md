# M23-C001 V03 — Transaction Identity Hardening — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Prior verdict: `CHANGES_REQUIRED` (`CHATGPT_AUDIT_V02.md`, finding `F-M23-V02-STRICT-001`)
Handoff state: `AWAITING_AUDIT`

## 1. Commit identities

- **Safe-sync start `origin/main` SHA:** `1613357` (fast-forward `027b116..1613357`;
  incoming commits were coordination/tracker only — none touched `project.godot`,
  `scripts/` or `tests/`). Owner-local `project.godot` + untracked `.import`/`.uid`
  sidecars preserved, left unstaged. No `reset --hard` / `clean -fd` / destructive
  restore / force push.
- **Implementation SHA (pushed first):** `bc7f03844630377f350e2f13676ca2b8b7328ce7`
  (`fix(M23-C001 V03): engine-owned transaction identity authority`).
- **This log** is a separate evidence commit pushed after the implementation SHA.

## 2. Changed files (implementation commit bc7f038)

- `scripts/gameplay/supply/batch_supply_engine.gd` — transaction authority reworked to
  engine-owned runtime instance identity.
- `tests/run_tests.gd` — new `_run_m23_v03_identity_tests()`; V02 F-001 mutation
  assertions updated to corrected identity semantics.
- `tests/m23_v02_hardening_evidence.gd` — V02 F-001 mutation trace updated to corrected
  semantics (mutated A now commits its original column).
- `tests/m23_v03_transaction_identity_evidence.gd` — new dedicated V03 evidence script.

No generator change. No routing/target/reservation/dispatcher/agent/clearing/SlotSystem
change. Root `TASKS.md` absent.

## 3. Exact production identity mechanism

`begin_front_selection()` mints the `BatchSelectionTransaction` and stores the
authoritative record **keyed by `tx.get_instance_id()`** — the Godot runtime instance
id, which is engine-assigned, immutable, and not a field the caller can mutate or forge:

```gdscript
_open_tokens[tx.get_instance_id()] = {"token_id": tid, "column": column,
    "front_id": front.get_batch_id(), "object": tx}
```

`_authentic_record(tx)` locates the record solely by `tx.get_instance_id()`; it never
reads `_token_id`, `_column`, `_front_batch_id`, or the detached front. `commit()`,
`cancel()`, `has_open_transaction()` all authenticate through it and act only on
engine-owned record data (`rec["column"]`, `rec["front_id"]`). The submitted object's
visible fields are informational snapshots only. A forged fresh object has a distinct
instance id and is absent from the map (fail-closed); an authentic object stays keyed by
its immutable instance id no matter how its visible fields are mutated. Open objects are
held alive by `rec["object"]`, so their instance id cannot be recycled while open. No new
caller-supplied nonce is introduced.

## 4. Direct adversarial trace — dedicated V03 evidence

`godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd`
→ `M23 V03 transaction identity evidence: PASS` (exit 0):

```
V03 A: token=1 column=0 front=A0 iid=-9223372008786491951
V03 B: token=2 column=1 front=B0 iid=-9223372008752937521
V03 forged: token=1 column=0 front=A0 iid=-9223372008736160306 (distinct iid)
  ok: forged copy commit -> false
  ok: forged copy cancel -> false
  ok: forged copy has_open_transaction -> false
  ok: queue unchanged after forged attacks
V03 A after mutation: token=2 column=1 front=B0 iid=-9223372008786491951 (iid immutable)
  ok: field-mutated A still authentic by engine identity
  ok: field-mutated A commits
  ok: A removed ORIGINAL column-0 front A0 (now A1), not B's front
  ok: column 1 byte-for-byte unchanged by mutated-A commit
  ok: B still open after A commit
  ok: authentic B commits
  ok: B removed original column-1 front B0 exactly once
  ok: column 0 unchanged by B commit
  ok: second commit(A) fails closed
  ok: cancel(A) after commit fails closed
  ok: second commit(B) fails closed
  ok: first same-column commit succeeds
  ok: stale-front token fails closed
  ok: pre-reset token fails closed after reset
  ok: reset restored original column-0 front
```

Key proof: A's instance id (`iid=-9223372008786491951`) is identical before and after its
visible `_token_id`/`_column`/`_front_batch_id`/`_front_batch` are mutated toward B; A
still commits and removes only its ORIGINAL column-0 front A0. The forged copy carries A's
exact visible fields but a distinct iid and cannot mutate any state. B independently
commits only its own column-1 front. No wrong-column removal, no orphaning, no extra
advance. Mirrored as `_run_m23_v03_identity_tests()` in the root suite.

## 5. Preserved V01/V02 accepted behavior

Malformed real `ColorBatch` rejection, no-partial-mutation candidate loads, atomic
queue+seed+palette candidate truth and reset restoration, strict `LevelData` validation,
59×59 per-color conservation, 3/4/5 FIFO columns, front-only selection, hidden preview
secrecy, independent-column FIFO advance, deterministic generation/conservation, detached
snapshots, Hazard Bot evidence, candidate-only (no M27 solvability claim) — all retained
and green.

## 6. Validation commands / results / exits

Run from `C:\Users\sekip\Desktop\ScrubBots`.

| # | Command | Result | Exit |
|---|---------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4941, Failures: 0, RESULT: ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd` | `M23 V03 transaction identity evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m23_v02_hardening_evidence.gd` | PASS | 0 |
| 5 | `godot --headless --path . -s res://tests/m23_v01_batch_supply_evidence.gd` | PASS | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 8 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 9 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 10 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | PASS (full 400-cell clear) | 0 |
| 11 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 13 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 14 | `git diff --check` | clean (only informational LF→CRLF notices) | 0 |

Root-suite check count moved 4921 → 4941 (+20 V03 identity assertions; V02 F-001
mutation assertions rewritten in place).

## 7. Statements

- `root TASKS.md modified = NO` (absent from the implementation diff).
- `M24-M27 implementation = NO` (no five-slot batch engine, target claim, auto
  dispatch, or solvability/deadlock logic).
- `image-generation credits spent = 0`.
- No protected system (TargetSelector / ReservationState / Railroad V1 routing /
  Dispatcher / ScrubbotAgent / CompleteClearingLoop / SlotSystem) modified; all
  M22/M21/M20 regressions green.
- No solver/deadlock claim added.
- No audit verdict authored. `AWAITING_AUDIT`.
