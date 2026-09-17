# M23-C001 V02 — Batch Supply Engine Hardening

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Milestone: `M23 — Batch Supply Engine`
Handoff target: `AWAITING_AUDIT`

This is a narrow correction cycle for the V01 Batch Supply Engine. Do not redesign M23 and do not start M24-M27.

## 1. Mandatory reading

Read in order:

1. `CLAUDE.md`
2. root `TASKS.md` — READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
5. `coordination/sessions/M23-C001/CHATGPT_PROMPT_V01.md`
6. `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
7. `coordination/sessions/M23-C001/CLAUDE_LOG_V01.md`
8. `coordination/sessions/M23-C001/CHATGPT_AUDIT_V01.md`
9. `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## 2. Safe Git start

Confirm correct repo/branch/upstream and inspect `git status --short`.

Safely sync with `origin/main`. Preserve all owner-local tracked/untracked work. No `reset --hard`, `clean -fd`, destructive restore or force push.

Do not modify root `TASKS.md`.

## 3. Fix F-M23-V01-STRICT-001 — forged transaction objects

The V01 transaction boundary trusts a caller-supplied numeric token ID too much.

Harden it so only the exact `BatchSelectionTransaction` instance minted by `begin_front_selection()` can commit/cancel its engine-owned open transaction.

Requirements:

- a newly constructed same-class object carrying a real live token ID must fail;
- a forged object must not cancel the legitimate transaction either;
- field mutation on one token must not redirect it to another token/column;
- ordinary original transaction still works after failed forge attempts;
- stale/double/reset behavior remains fail-closed;
- `has_open_transaction()` must also require authentic ownership.

Use exact RefCounted identity / immutable instance identity or an equivalent unforgeable engine-owned proof. Do not solve this with a second globally guessable integer/string only.

## 4. Fix F-M23-V01-STRICT-002 — malformed ColorBatch load boundary

`load_columns()` must not trust `is ColorBatch` alone.

Before accepting candidate state, revalidate every batch value:

- non-empty String ID;
- unique ID;
- integer color ID >= 0;
- positive integer robot_count;
- palette range when palette size is known.

Directly test a real `ColorBatch` object whose underscore fields were deliberately corrupted or which was directly instantiated and populated with invalid state. The load must fail and preserve the prior engine candidate exactly.

## 5. Fix F-M23-V01-STRICT-003 — reset queue + seed + palette metadata

Make seed and palette size part of the committed candidate's initial truth, not loose mutable reporting fields.

Preferred direction: an atomic candidate configuration/load seam that establishes queue + seed + palette metadata together and snapshots them together.

`reset()` must restore:

- exact original queue/order;
- exact original seed;
- exact original palette size;
- no pre-reset transaction remains valid.

Remove or narrow public metadata mutators if they are unnecessary. If they remain public, prove reset restores original committed values after mutation.

Update generator integration accordingly without changing its deterministic candidate semantics.

## 6. Fix F-M23-V01-STRICT-004 — strict LevelData validation

Generator/source-total APIs must fail closed for foreign or malformed input.

Use the real LevelData category or an equally strict production-safe contract.

Validate at least:

- source is the expected LevelData domain value;
- dimensions are positive/coherent;
- palette exists and is non-empty;
- `cells` has the correct packed-int representation;
- `cells.size() == level.get_cell_count()`;
- each palette ID is within range.

Foreign RefCounted/object input and malformed LevelData must not produce a candidate or uncaught runtime script error.

## 7. Fix F-M23-V01-STRICT-005 — direct 59x59 per-color evidence

Extend tests so the 59x59 source totals are compared directly against generated totals for every source color.

Keep deterministic same-seed and performance sanity assertions.

## 8. Preserve all V01 passing behavior

Do not regress:

- exactly 3/4/5 independent FIFO columns;
- front-only selection;
- 3/4 preview support, V1 depth 3;
- hidden future content secrecy;
- independent-column advance;
- deterministic seeded generation;
- positive integer partitions;
- exact per-color quota conservation;
- unique batch IDs;
- detached snapshots;
- Hazard Bot real-level evidence;
- protected M22/M21/M20 systems.

Do not add solver/deadlock claims.

## 9. Scope prohibitions

Do not implement or modify production logic for:

- M24 Five-Slot Batch Engine;
- M25 Batch Target Claim Engine;
- M26 Auto Dispatch Scheduler;
- M27 Solvability / Deadlock Engine;
- production UI scenes;
- TargetSelector/ReservationState/Railroad/Dispatcher/CompleteClearingLoop except read-only regression use.

Zero image-generation credits.

## 10. Tests

Add direct adversarial tests matching every V02 audit criterion, especially a forged **real same-class** `BatchSelectionTransaction` with another live transaction ID.

Run the complete root suite and the required M23/M22/M21/M20 evidence commands from V02 criteria. Run `git diff --check`.

Do not delete historical regression tests.

## 11. Git handoff

Before commit:

- inspect `git diff` / `git status`;
- confirm root `TASKS.md` absent;
- confirm changed files are narrowly M23 supply/tests/evidence.

Push the implementation commit first.

Then create and push separately:

`coordination/sessions/M23-C001/CLAUDE_LOG_V02.md`

The log must map every prior audit finding `F-M23-V01-STRICT-001..005` to exact code and direct test evidence.

Return only:

`AWAITING_AUDIT`

plus implementation SHA and the direct GitHub URL to `CLAUDE_LOG_V02.md`.
