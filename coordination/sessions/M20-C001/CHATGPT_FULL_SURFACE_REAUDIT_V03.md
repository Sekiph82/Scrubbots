# M20-C001 — Full-Surface Residual Re-Audit V03

Status: **CHANGES_REQUIRED / RESIDUAL SET FROZEN**

Basis:
- `CHATGPT_FULL_SURFACE_REAUDIT_V01.md`
- `CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
- `CHATGPT_AUDIT_V01.md`
- `CHATGPT_AUDIT_V02.md`
- implementation commit `949798faccc61e6de7bf8150be4b51538a2cac44`

Canonical live tracker: repository-root `TASKS.md` only.

V03 does NOT reopen the accepted M20 architecture. It freezes only the residual
attack surface found after V02.

## Accepted architecture to preserve

- `CompleteClearingLoop` remains a separate RefCounted M20 orchestrator.
- BoardState owns physical ACTIVE/CLEARED truth.
- ColorCandidateIndex owns derived ACTIVE candidate truth.
- ReservationState owns ephemeral owner<->target truth.
- ScrubbotDispatcher owns assignment/agent identity.
- ProductionAccessQuery reads BoardState live.
- Renderer is post-commit presentation only.
- Correct order remains BoardState -> candidate -> reservation -> dispatcher -> renderer.
- Serialized activation, arrival FIFO and deferred transactional reset remain.
- M19 arrival authentication remains exact owner/target/color/source-agent.
- No M21+, win/lose/scoring/session policy.

## Residual A — canonical dependency category must not be widened for tests

V02 accepts ColorCandidateIndex and ReservationState subclasses only to inject
faults. That makes every overridden state/coherence method a production trust
boundary.

A repeated `_probe()` is not a proof against an adversarial stateful override. A
subclass can rebind to the requested board just long enough to return true and
leave itself bound to another board before returning. It can repeat that behavior
on every probe.

### Frozen correction

M20 bind must require exact production script identity for ALL six canonical
collaborators:
- BoardState;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- ScrubbotDispatcher;
- optional BoardRenderer.

No production dependency type may remain subclass-open only for test injection.

Fault/sensitivity testing must not weaken the production trust category. Use
restored temporary sensitivity mutations and/or a test-only M20 harness; no final
upstream production mutation may remain.

## Residual B — exact reservation-set proof

V02 already captures detached `get_reserved_indices()` but ignores it in both
healthy resolve verification and rollback verification.

Frozen V03 requirements:
- snapshot the detached sorted reserved-index set;
- snapshot owner mapping for every preexisting reserved index;
- verify successful resolve produces exactly `pre_reserved - current_target`;
- verify every unrelated target keeps its exact owner;
- verify no new reservation appears;
- verify rollback restores exactly the full pre-reserved set and owner mapping;
- count-only equality is insufficient.

This is bounded by live reservations, not a BoardState full scan.

## Residual C — candidate unrelated-state proof after category narrowing

Under exact ColorCandidateIndex, canonical `sync_cell(target)` is audited to
mutate only target membership in the target color bucket. Preserve this
compositional contract rather than keeping arbitrary subclass mutation power.

Permanent tests must directly include at least:
- two same-color ACTIVE candidates;
- clear/rollback one target;
- unrelated same-color candidate remains present;
- another-color bucket remains unchanged.

Normal production clear must remain single-cell sync; do not snapshot/full-scan
all board candidates merely to defend against a subclass category that V03 removes.

## Residual D — current-arrival duplicate identity

The V02 queue dedupes only entries still in `_arrival_queue`. The current tuple is
popped before `_run_transaction()`, so it is not represented during processing.

Frozen V03 requirements:
- retain an internal current-arrival identity/token while one tuple is processed;
- `_enqueue_arrival()` rejects a duplicate of either the current tuple or any
  queued tuple;
- distinct second assignments still queue FIFO and complete losslessly;
- clear current identity on every transaction exit;
- reset clears queued/current stale bookkeeping safely;
- expose no mutable queue/current identity publicly.

## Residual E — sensitivity must prove V02 bugs before fixing

Before V03 production correction, against the V02 implementation:

1. Candidate coherence spoof:
   - accepted candidate subclass makes every `is_bound_to(board)` return true but
     leaves itself bound to a foreign same-size board;
   - demonstrate V02 double-probe can be fooled OR record the exact source-level
     sensitivity if Godot prevents the chosen override shape.

2. Reservation identity swap under mutate-false:
   - prestate contains current pair plus unrelated U->ownerU;
   - failing callback removes current pair, moves ownerU from U to different V,
     preserves total count, returns false;
   - demonstrate V02 rollback can report ordinary rollback success while U/V
     identity is wrong.

3. Candidate unrelated removal under mutate-false:
   - prestate has target plus another same-color candidate;
   - callback removes target and unrelated candidate then false;
   - demonstrate V02 target-only rollback/verification can accept the unrelated
     loss if reproducible.

These are sensitivity checks. Temporary support/test mutations must be restored
before final V03 state.

## Residual F — previously accepted direct-observability remains locked

Do not regress:
- true 1x1;
- second real B dispatch after A clear;
- five-slot unique owner/target/reservation identity;
- frame-after-queue_free smoke;
- failed-preflight reset recovery;
- reset during candidate/reservation phase;
- nested distinct arrival FIFO;
- renderer rollback no false-clear;
- 59x59, rectangular, rapid sequential clearing;
- all M19 V01-V06 regressions.

## Final V03 scope

Production changes should normally be limited to:
`scripts/gameplay/clearing/complete_clearing_loop.gd`

No upstream M13/M14/M19 behavior change is expected.

If the V03 exact-category correction proves an upstream production defect rather
than an M20 integration defect, stop `BLOCKED` and return to ChatGPT instead of
silently widening scope.

## Closure disposition

V03 is a production correction to a critical/stateful subsystem. A clean V03 is
normally followed by an auditor-authored validation-only V04 before
`SB-M20-001..014` close, unless ChatGPT obtains equivalent independent runtime
E3 evidence.
