# M23-C001 V03 — Transaction Identity Hardening

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Milestone: `M23 — Batch Supply Engine`
Handoff target: `AWAITING_AUDIT`

This is a narrow remediation cycle. Do not redesign M23. Close only the remaining transaction-authentication defect from `CHATGPT_AUDIT_V02.md`, preserve all V01/V02 passing behavior, and do not begin M24–M27.

## 1. Mandatory reading

Read in order:

1. `CLAUDE.md`
2. root `TASKS.md` — READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
5. `coordination/sessions/M23-C001/CHATGPT_AUDIT_V01.md`
6. `coordination/sessions/M23-C001/CHATGPT_AUDIT_V02.md`
7. `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
8. current M23 supply implementation/tests

## 2. Safe synchronization

Work only in `Sekiph82/Scrubbots` `main`.

At start:

- inspect remote/branch/upstream/status;
- fetch and safely fast-forward/synchronize;
- preserve all owner-local tracked/untracked work;
- never use `reset --hard`, `clean -fd`, destructive restore or force push.

If safe sync is impossible without destroying owner work, stop `BLOCKED`.

## 3. Remaining defect

V02 rejects a separate forged same-class transaction object, but authentic lookup still begins from `tx.get_token_id()`. Because GDScript underscore fields are caller-mutable, changing authentic A's `_token_id` can orphan A from its engine-owned record.

That fails the strict requirement that public-ish field mutation cannot redirect A and must not destroy A's ability to commit its original engine-owned transaction.

## 4. Required production correction

Make engine-owned object identity the authoritative transaction lookup.

Preferred model:

- when `begin_front_selection()` mints transaction object `tx`, capture its exact runtime identity, for example `tx.get_instance_id()`;
- store the authoritative record keyed by that engine-known identity, or otherwise locate records by exact object identity without trusting caller-mutated `_token_id`, `_column`, `_front_batch_id`, or detached front data;
- authoritative record contains original token/debug ID, original column, original front batch ID and object identity;
- `commit(tx)`, `cancel(tx)`, and `has_open_transaction(tx)` authenticate by exact engine-owned object identity;
- visible transaction fields are informational snapshots only;
- mutating those fields must not redirect, orphan, or change the authoritative record.

Do not expose a new forgeable caller-supplied nonce as authority.

## 5. Direct adversarial proof

Add a dedicated V03 evidence script and root-suite assertions that prove:

1. engine with at least two non-empty columns;
2. begin authentic A on column 0 and authentic B on column 1;
3. capture queue snapshot;
4. construct a fresh `BatchSelectionTransaction` with A's exact visible token/column/front/batch values;
5. forged commit/cancel/has-open all fail and queue remains unchanged;
6. mutate authentic A's `_token_id` to B's visible ID;
7. mutate authentic A's `_column` to B's column;
8. mutate authentic A's `_front_batch_id` to B's front ID;
9. mutate/replace A's detached front snapshot if technically possible;
10. `has_open_transaction(A)` is still true because engine identity is authoritative;
11. `commit(A)` succeeds and removes exactly original A front from original column 0;
12. column 1 remains byte-for-byte/logically unchanged after A commit;
13. authentic B remains open and `commit(B)` removes exactly original B front from column 1;
14. neither mutation nor forged object can remove wrong fronts;
15. second commit/cancel on consumed A fails closed;
16. stale-front and reset-stale tests remain green.

The test must explicitly prove **A itself commits after its fields were mutated**. Proving only that B survives is insufficient.

## 6. Preserve accepted V01/V02 behavior

Do not regress:

- malformed real ColorBatch rejection;
- no-partial-mutation candidate loads;
- exact queue+seed+palette reset;
- strict LevelData validation;
- 59×59 per-color conservation;
- 3/4/5 FIFO columns;
- preview secrecy/front-only selection;
- deterministic generation/conservation;
- Hazard Bot evidence;
- protected M22/M21/M20 behavior.

## 7. Forbidden scope

Do NOT implement:

- M24 Five-Slot Batch Engine;
- M25 Batch Target Claim Engine;
- M26 Auto Dispatch Scheduler;
- M27 Solvability / Deadlock Engine;
- production supply UI;
- unrelated refactors.

Do not modify root `TASKS.md`.

## 8. Validation

Run and report:

- `godot --version`
- `godot --headless --path . -s res://tests/run_tests.gd`
- dedicated V03 evidence script
- M23 V02 evidence
- M23 V01 evidence
- M22 V06, V05, V04, V03 evidence
- M21 real-art smoke
- M21 V10 reservation evidence
- M20 queue-free and lifecycle smoke
- `git diff --check`

## 9. Commit/handoff

1. Commit and push implementation/tests first.
2. Then create `coordination/sessions/M23-C001/CLAUDE_LOG_V03.md` in a separate commit.
3. Log exact start SHA, implementation SHA, changed files, adversarial traces, check counts/exits, and explicit scope statements.
4. Return only:

`AWAITING_AUDIT`

implementation SHA

direct GitHub URL to `CLAUDE_LOG_V03.md`
