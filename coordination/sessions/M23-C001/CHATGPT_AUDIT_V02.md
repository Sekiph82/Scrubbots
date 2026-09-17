# M23-C001 V02 — ChatGPT Strict Audit

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Auditor: ChatGPT
V02 implementation SHA: `e849290fb604317b5839c01af99e6bb55ca177b8`
V02 evidence/log SHA: `702a9f24a4d601a18eab64516fedd964a7ac8897`
Verdict: **CHANGES_REQUIRED**

## Executive result

V02 closes four of the five V01 findings cleanly and substantially hardens the Batch Supply Engine. The implementation diff is narrow, root `TASKS.md` is absent, no M24–M27 code is introduced, and protected M22/M21/M20 systems remain untouched.

However, F-M23-V01-STRICT-001 is only partially closed. Forged *separate* transaction objects are now rejected by exact object comparison, but transaction authentication still begins by reading the caller-mutable `_token_id` from the submitted object. Mutating the authentic transaction object's `_token_id` therefore makes the legitimate transaction unable to authenticate its own engine-owned open record. The V02 strict criteria explicitly required that field mutation not redirect A **and that original A can still commit afterward unless deliberately cancelled**.

M24 must not start until this final transaction-identity boundary is corrected.

## Verified closed findings

### F-M23-V01-STRICT-002 — CLOSED

`_build_columns()` revalidates each `ColorBatch` at the load trust boundary: non-empty unique String ID, integer non-negative color ID, positive integer quota, and palette bounds when known. Invalid real `ColorBatch` objects fail before engine state is committed. Prior candidate state is preserved.

### F-M23-V01-STRICT-003 — CLOSED

`load_candidate()` atomically commits queue + seed + palette metadata and snapshots them as initial candidate truth. `reset()` restores columns, seed and palette and clears open transactions. Direct V02 evidence mutates seed/palette, advances the queue, resets, and proves restoration.

### F-M23-V01-STRICT-004 — CLOSED

Generator source validation now requires real `LevelData`, positive dimensions, non-empty packed palette, packed cells, exact `cells.size() == get_cell_count()`, and in-range cell IDs. Null, foreign object, empty palette, out-of-range cell, mismatched cell count and zero-dimension fixtures fail closed.

### F-M23-V01-STRICT-005 — CLOSED

59×59 evidence now directly compares generated quota to source count independently for colors 0, 1 and 2. Same-seed determinism is retained.

## F-M23-V02-STRICT-001 — Authentic transaction can be orphaned by caller-visible field mutation

**Severity: BLOCKING**

V02 correctly stores the exact minted transaction object in `_open_tokens[tid]["object"]`, and a freshly constructed same-class object with A's live token ID cannot commit/cancel A.

But `_authentic_record(tx)` still performs this lookup sequence:

1. read `tid = tx.get_token_id()` from the caller-visible transaction object;
2. lookup `_open_tokens[tid]`;
3. compare `rec["object"] == tx`.

`BatchSelectionTransaction` fields are conventionally private only; GDScript callers can mutate `_token_id`. The V02 evidence does exactly that:

- A is authentic under token ID 1;
- B is authentic under token ID 2;
- test changes `A._token_id = B.get_token_id()`;
- redirect-to-B correctly fails because B's record stores object B;
- but A's own engine-owned record remains under ID 1 while A now reports ID 2;
- the test never restores A's field and never proves A can still commit.

This violates `CHATGPT_AUDIT_CRITERIA_V02.md` §2.6–§2.7:

- changing fields on A cannot redirect it to B or another column;
- original A can still commit after failed forge attempts unless deliberately cancelled.

The current test proves only that B remains usable. That is not equivalent.

### Required correction

Authentication must not depend on caller-mutable transaction fields for locating the authoritative open record.

Use an engine-owned identity map keyed by an immutable runtime property, for example `tx.get_instance_id()` / exact RefCounted instance identity, with token ID/column/front ID stored solely as engine-owned record data. The submitted object's token/column/front fields may be treated as display/debug snapshots but must not be authoritative for locating or mutating engine state.

Required direct sequence:

1. open authentic A and B;
2. forge a fresh same-class object carrying A's visible fields — commit/cancel false, zero mutation;
3. mutate A's `_token_id`, `_column`, `_front_batch_id`, and/or detached batch snapshot toward B;
4. A must still authenticate as A by engine-owned object identity;
5. A commit must advance only A's original column/front exactly once;
6. B must remain independently valid and commit only B;
7. no wrong-column removal, no token orphaning, no extra advance;
8. stale-front/double-commit/reset-stale behavior remains fail-closed.

## Scope discipline

V03 is transaction-authentication hardening only. Preserve all V01/V02 passing behavior. Do not redesign generator partitioning, supply UI, slot lifecycle, target claims, auto dispatch or solvability/deadlock logic.

## Closure state

- `SB-M23-001..SB-M23-030`: remain open pending V03.
- M23-C001 V02: **CHANGES_REQUIRED**.
- Next cycle: **M23-C001 V03**.
- M24: must not start.
