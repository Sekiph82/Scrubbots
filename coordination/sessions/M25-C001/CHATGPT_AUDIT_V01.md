# M25-C001 V01 — ChatGPT Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M25 — Batch Target Claim Engine`
Cycle: `M25-C001 V01`
Auditor: ChatGPT
Implementation SHA: `65294d78037268508a5ced5d02f847919a2cfe3b`
Claude log commit: `7dd0061799c57f97b875a82b0170084a75fa41ad`
Criteria: `coordination/sessions/M25-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CHANGES_REQUIRED / FULL M25 WAS IMPLEMENTED, BUT STRICT CLOSURE IS NOT YET SAFE**

Claude did execute the complete continuous M25 package and attempted all `SB-M25-001..032` in one implementation commit. This is not a partial-work-package handoff.

The core architecture is directionally correct and substantial portions are accepted provisionally: same-color oldest-placement arbitration, capacity spill, TargetSelector delegation, BLUE 8/14/12 behavior, blocked-then-open timing, detached claim snapshots, and ordinary claim/finalize/reset happy paths.

However, strict audit found identity, compensation, trust-boundary and lifecycle defects that can break the one-claim <-> one-reservation <-> one-M24-work invariant under adversarial/stale state. M25 therefore remains open.

## Governance / diff integrity

Verified implementation range:

- start: `ebab53b8dfc30fd6dc0d1237868b30a7d957782a`
- implementation: `65294d78037268508a5ced5d02f847919a2cfe3b`

One focused implementation commit changed only the new M25 engine and M25 tests/support plus `tests/run_tests.gd`. Root `TASKS.md` was absent. M26/M27 production code was absent.

Verified implementation -> log range:

- `65294d78037268508a5ced5d02f847919a2cfe3b`
- `7dd0061799c57f97b875a82b0170084a75fa41ad`

That range adds only `CLAUDE_LOG_V01.md`.

Claude reports Godot 4.7.2 and root suite `5139 / 0`. Existing green tests do not close the findings below because the missing adversarial states are not exercised.

## F-M25-V01-STRICT-001 — stale claim / reservation-owner identity reuse across reset

Production `reset()` sets:

- `_next_owner = 0`
- `_next_claim = 1`

Therefore a post-reset claim may reuse the exact pre-reset public claim identity `M25C1` and owner id `0`.

This violates the master criterion that reset/session teardown must invalidate stale claim identities. A caller retaining a pre-reset `M25C1` can become indistinguishable from a newly-created post-reset `M25C1` and may rollback/finalize the new claim.

The owner-id allocator also assumes owner 0 is free. ReservationState is a shared session authority. If an unrelated live reservation already owns owner id 0, TargetSelector rejects the M25 attempt. Because M25 advances `_next_owner` only after success, the engine can retry the same colliding owner forever and incorrectly put a batch into WAITING despite valid targets.

Existing unrelated-owner tests use very large ids (e.g. 987654/555555) and do not test a collision with M25's next id.

Required correction:
- never recycle stale claim identities within a live engine/session lifecycle;
- never let a live unrelated ReservationState owner collide with a newly minted M25 owner;
- prove pre-reset stale ids cannot mutate post-reset claims;
- prove unrelated owner id 0/next-candidate does not stall valid M25 work.

## F-M25-V01-STRICT-002 — failed M24 commit does not restore lifecycle prestate

Accepted claim flow performs:

1. TargetSelector reserves a target.
2. M25 calls `set_claimable_work_available(slot, true)`, potentially changing WAITING -> ACTIVE.
3. M25 calls `commit_work(slot, claim_id)`.
4. On commit failure it releases the reservation and returns `commit_failed`.

The failure branch does not restore the prior lifecycle state.

Therefore a WAITING batch can become ACTIVE even though the logical claim transaction failed and no claim/committed work was published.

The master prompt/criteria explicitly require exact rollback of lifecycle state changed by the attempt.

Required correction:
- snapshot the selected batch lifecycle before claim acceptance;
- if post-reservation M24 commit fails, release the exact reservation and restore lifecycle prestate;
- direct test must begin from WAITING, make a target claimable, force `commit_work` failure, and prove WAITING + counters + reservation + ledger all return to exact pre-attempt truth.

## F-M25-V01-STRICT-003 — rollback/reset ignore canonical mutation failure and can erase bookkeeping after partial cleanup

`rollback_claim()` currently:
1. calls `M24.rollback_work(claim_id)`;
2. calls `ReservationState.release(target, owner)` but ignores its return;
3. erases the M25 ledger entry;
4. returns true.

If the exact reservation pair has drifted or cannot be released, M24 can already be mutated and the ledger still erased. That violates the required transactional rollback policy.

`reset()` similarly ignores return values from every `rollback_work` and `release`, then unconditionally clears the entire claim ledger.

This can hide an orphan M24 committed work identity or an unresolved reservation mismatch instead of failing closed.

Required correction:
- define and implement a transactional cleanup policy;
- preflight exact tuple coherence before destructive mutation, or provide verified compensation that restores exact pre-call state on failure;
- never erase a claim merely because one half of cleanup succeeded;
- reset must not silently clear ledger truth when cleanup of any live tuple fails;
- add adversarial reservation-drift and M24-work-drift tests;
- unrelated ReservationState ownership must remain untouched.

A narrow read-only M24 work-identity/coherence query is permitted only if genuinely necessary; any accepted-M24 seam change must be minimal and fully regressed.

## F-M25-V01-STRICT-004 — production targetability trust boundary is too wide

`claim_for_color()` accepts any `RefCounted` that merely exposes `is_targetable`.

The master criteria require the production claim path to consume a real/coherent `ProductionTargetAccess` or equivalently strict production adapter deriving targetability from ProductionRoutingSystem + RouteValidator for the same board.

The current generic method-compatible gate allows an arbitrary all-true object to become production reachability truth. In fact, `tests/support/m25_reentrant_access.gd` is exactly such an all-true RefCounted double and is passed through the production claim method.

This is useful for re-entry testing but demonstrates that the production dependency category was widened to facilitate a test, which the criteria explicitly prohibit.

Required correction:
- tighten production access validation to canonical ProductionTargetAccess or a narrowly-defined strict adapter with exact board coherence;
- reject a foreign-board ProductionTargetAccess;
- reject a generic method-compatible/all-true RefCounted in production claim calls;
- retain re-entry coverage without weakening the production trust boundary;
- if a minimal read-only coherence seam must be added to ProductionTargetAccess, document why and fully regress the protected M19/M22 paths.

## F-M25-V01-STRICT-005 — valid rebind can move the engine while live claims remain

`bind()` is not initialization-only. A second coherent bind can overwrite `_board`, `_batches`, `_selector`, and `_reservations` while `_claims` still contains live records from the original session bundle.

Subsequent rollback/finalize/reset would then operate old claim records against new authorities, risking reservation/work leaks.

Required correction:
- make M25 binding session-stable;
- simplest accepted policy: once bound, a second bind fails closed and preserves the original bundle;
- alternatively provide an explicit rebind only after verified claim cleanup, but do not move bundles with live claims;
- add direct live-claim rebind adversarial evidence.

## Accepted/provisionally green V01 behavior to preserve

V02 must not rewrite the milestone. Preserve:

- one session claim ledger;
- ReservationState as live reservation authority;
- TargetSelector bottom-most -> left-most WHAT policy;
- multiple same-color batches;
- oldest placement sequence first;
- capacity spill only after oldest reaches zero capacity;
- claim creation increments M24 committed once and does not decrement remaining;
- blocked future target not pre-owned;
- BLUE 8 / BLUE 14 / BLUE 12;
- opening-time reassignment;
- authenticated-clear finalization happy path;
- rectangular + 59x59 evidence;
- no M26 scheduler/spawn;
- no M27 solver.

## Closure decision

Do not close `SB-M25-001..032` yet.

Open one narrow `M25-C001 V02` remediation cycle covering all five findings together. This is a correction pass on the already-complete M25 implementation, not task-by-task implementation.
