# M23-C001 V03 — Strict Audit Criteria

Cycle: `M23-C001 V03`
Milestone: `M23 — Batch Supply Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Auditor: ChatGPT
Prior audit: `coordination/sessions/M23-C001/CHATGPT_AUDIT_V02.md`
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

## 0. Verdict policy

V03 passes only if the authentic transaction remains usable after caller-visible transaction fields are maliciously mutated, while forged/foreign objects remain unable to mutate engine state.

All V01/V02 passing behavior must remain green. M24–M27 remain out of scope.

## 1. Governance

- Work only in `Sekiph82/Scrubbots` on `main`.
- Safe sync only; preserve owner-local work.
- Root `TASKS.md` is read-only for Claude.
- Push implementation first, `CLAUDE_LOG_V03.md` separately afterward.
- Zero image-generation credits.
- Do not modify protected routing/target/reservation/dispatcher/clearing systems.

## 2. Engine-owned transaction identity

The authoritative lookup for an open transaction must not depend on caller-mutable transaction fields such as `_token_id`, `_column`, `_front_batch_id`, or the detached front batch snapshot.

Required:

1. open authentic transaction A on column A and authentic transaction B on column B;
2. construct a fresh `BatchSelectionTransaction` whose visible fields copy A exactly;
3. forged commit returns false;
4. forged cancel returns false;
5. forged `has_open_transaction()` returns false;
6. forged attacks do not mutate any queue or consume A;
7. maliciously mutate A's visible `_token_id`, `_column`, `_front_batch_id`, and detached front data toward B or nonsense values;
8. A must still be recognized as the authentic engine-minted A transaction by engine-owned identity;
9. `commit(A)` must advance exactly A's original column/front once;
10. B must remain valid and independently commit exactly B's original column/front once;
11. no wrong-column removal, no extra advance, no token orphaning;
12. after A commits, second `commit(A)` and `cancel(A)` fail closed;
13. reset-stale and stale-front semantics remain fail-closed.

Preferred authority: exact RefCounted instance identity / `get_instance_id()` keyed engine-owned record. Public transaction fields may be debug snapshots only, not authority.

## 3. Preserve hardening already accepted

V03 must retain:

- malformed real `ColorBatch` rejection at load boundary;
- atomic queue + seed + palette candidate truth;
- reset restoration of all candidate metadata;
- strict real-LevelData validation;
- per-color 59×59 conservation;
- 3/4/5 FIFO columns;
- front-only selection;
- hidden preview secrecy;
- independent-column FIFO advance;
- deterministic generation and conservation;
- detached snapshots;
- Hazard Bot evidence;
- candidate-only generation with no M27 solvability claim.

## 4. Scope boundary

Do not implement or modify:

- Five-Slot Batch Engine;
- Batch Target Claim Engine;
- Auto Dispatch Scheduler;
- Solvability / Deadlock Engine;
- production supply UI/scene integration;
- M22 Railroad/routing policy.

## 5. Required validation

Run at minimum:

- `godot --version`
- full `tests/run_tests.gd`
- dedicated V03 transaction-identity evidence
- M23 V01 and V02 evidence scripts
- M22 V06/V05/V04/V03 evidence
- M21 real-art smoke
- M21 V10 reservation evidence
- representative M20 queue-free/lifecycle smoke
- `git diff --check`

Report exact check count, failure count and exit codes.

## 6. Required V03 log

`CLAUDE_LOG_V03.md` must include:

- safe-sync start SHA;
- implementation SHA;
- complete changed-file list;
- exact production identity mechanism;
- direct trace showing forged copy fails;
- direct trace showing field-mutated authentic A still commits A's original column;
- direct trace showing B remains independently valid;
- regression results;
- `root TASKS.md modified = NO`;
- `M24-M27 implementation = NO`;
- `image-generation credits spent = 0`;
- final `AWAITING_AUDIT`.

## 7. Closure

If V03 passes, ChatGPT may close all M23 tasks and advance the canonical tracker to M24. Otherwise M23 remains open.
