# M20-C001 — ChatGPT Independent Whole-Sprint Audit V08

Decision: **PRODUCTION_ACCEPTED / VALIDATION_EVIDENCE_INCOMPLETE / V09_FINAL_EVIDENCE_ONLY_REQUIRED**

Audited validation commit:
`e13ffdc39772c1f26d7b03738951b67513639444`

Start-transition commit:
`b243c10bc66cbd016550d589c124ccd0ef88071c`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V08.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V08.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V08.md`

Canonical live tracker: repository-root `TASKS.md` only.

## Executive result

No material M20 production defect was found in the V08 whole-sprint source/state sweep.

The accepted V07 production remains locked:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` blob `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` blob `eee10149e4f116af6706beec832042352bf3a6dd`.

Independent GitHub comparison from V07 implementation commit `e189ee8` through V08 validation commit `e13ffdc` contains no `scripts/**` change. Current GitHub blobs independently equal the locked values.

Claude reports Godot 4.7.1, full suite **3937 / 3937 ALL PASS**, queue-free + V04/V05/V07/V08 lifecycle smokes PASS, and all six sensitivity mutations failing their named protection for the intended reason before exact restoration. Those runtime results remain E1/E2 because ChatGPT cannot execute Godot here.

V08 is nevertheless NOT final-closeable. Under the owner-locked sprint-wide audit policy, direct-test criteria must be reconciled one-to-one with the actual assertions. Several V08 tests are green while not actually asserting every field/property claimed by the V08 freeze/log/criteria. These are validation-evidence defects, not production defects.

## Governance / lifecycle

PASS:
- V08 tracker-only start transition exists and precedes V08 validation edits;
- V08 validation commit is a child of that start transition;
- no committed `scripts/**` change exists;
- no SB-M20 task was closed by Claude;
- root tracker is `M20-C001-V08 / AWAITING_AUDIT / CHATGPT`;
- progress remains 290/719 main+ui and 290/943 overall;
- no `.hiveai` live tracker was revived.

## Pass A — whole-sprint implementation/state sweep

### Production architecture

SOURCE ACCEPTED / unchanged:
- CompleteClearingLoop remains the sole M20 cross-module clearing orchestrator;
- single live M20 transaction owner per dispatcher is enforced by the V07 WeakRef claim;
- `agent_parent` explicit/default presence uses Variant TYPE rather than `!= null`;
- renderer explicit/default presence uses `_renderer_expected`;
- activation reset/coherence post-dispatch barrier remains;
- arrival transaction order remains BoardState -> candidate -> reservation -> dispatcher finalize -> renderer;
- exact reservation owner-map proof remains;
- current-arrival dedup + distinct FIFO remain;
- pair-narrow, board-safe dispatcher reset remains;
- ProductionAccessQuery still reads BoardState live;
- no M21+, win/lose/scoring/session-complete/slot queue/cooldown/consumption behavior was introduced.

### Sibling-failure search

Checked after the V05/V07 null-alias findings:
- optional renderer default-vs-dead: protected by `_renderer_expected`;
- optional `agent_parent` default-vs-dead: protected by TYPE_NIL presence capture;
- explicit factory default-vs-invalidated: protected by `_explicit_factory`;
- dispatcher/renderer Node liveness before dereference: preserved;
- reset cleanup siblings: pair-narrow exact pair remains;
- exact-set/map siblings: arrival/rollback still use exact owner-map proof;
- duplicate transaction-owner sibling: single M20 consumer claim remains.

No new production correction is frozen.

### Interaction sweep

Re-reviewed:
- claim + reset + owner GC;
- reset + M19 callback;
- reset + dependency drift;
- parent/renderer lifecycle death + configured/default semantics;
- failed arrival preflight + pair-narrow cleanup;
- rollback + unrelated candidate/reservation truth;
- duplicate current arrival + distinct FIFO;
- stale completion + owner monotonicity;
- max/rectangular scale + synchronized clearing;
- presentation loss + canonical gameplay state.

No material source defect found.

## Pass B — criteria-to-evidence reconciliation

The following is the COMPLETE known V08 evidence-gap set. The audit did not stop at the first gap.

### G-V08-01 — owner-claim lifecycle test ordering/directness

`_v08_owner_claim()` connects the benign diagnostic listener only AFTER the first M20 loop has already claimed the dispatcher. Therefore it does not directly prove the specific criterion that a pre-existing benign diagnostic listener does not block the first M20 claim.

Additional direct observations still needed in the same fresh arrangement:
- second rejected loop explicitly remains unbound and has zero clear attribution;
- owning loop remains usable after its own reset while still holding the claim;
- after actual owner GC, the old M20 transaction callback is gone and a fresh loop adds exactly one M20 transaction callback;
- claim/reset-only operations preserve a detached BoardState snapshot.

The V08 frame smoke correctly proves the WeakRef owner can actually be GC'd and a fresh loop can bind; the missing pieces above are observability gaps only.

### G-V08-02 — activation “per-case snapshot” helper does not assert the claimed snapshot

V08 freeze required each invalid/no-work activation to preserve:
- BoardState;
- dispatcher active count + next owner id;
- exact reservation owner map/count;
- all five slots' palette/availability/activity fields.

Current `_v08_snap()` captures `cells`, `active`, `next_owner`, and a `reserved` map. `_v08_snap_unchanged()` compares only cells, active count, and next owner. The captured reservation map is never compared. Slot fields are not in the snapshot. The unavailable-slot case checks only one slot's palette/availability after the call and does not prove all five slot activity/palette/availability tuples.

This is a direct-observability false-positive risk: capturing a value without asserting it is not evidence.

V09 must use a real detached snapshot helper and compare every claimed field per ordinary invalid/no-work case.

Fresh V08 also lacks direct final-gate arrangements for:
- activation while arrival drain is active -> REENTRANT;
- reset during activation preflight -> RESETTING;
- post-dispatch M20 coherence loss -> COHERENCE_FAILED;
- no-target and enclosed-target with the same exact per-case state snapshot proof.

Nested activation and reset-inside-M19-dispatch are directly present and accepted.

### G-V08-03 — arrival-preflight matrix still has exact-invariant holes

Fresh V08 forged identity cases directly assert outcome + BoardState and aggregate dispatcher/cleared_count, but do not directly assert the exact reservation remains held for EACH wrong owner/target/color/source/unknown-owner injection and do not snapshot unrelated truth per case.

The fresh V08 desync block also omits a dedicated missing-reservation case even though the final freeze/criteria require it.

Other fresh cases require stronger direct observation:
- same-board `T -> O2`: assert the replacement exists immediately after failed M20 preflight, before reset, then again after reset;
- foreign ReservationState: assert foreign replacement exists immediately after failed preflight, BoardState/cleared_count/current dispatcher assignment are unchanged, then prove survival after reset;
- candidate foreign-board and `rebind(null)`: assert exact reservation + dispatcher assignment remain held and cleared_count remains unchanged before cleanup;
- externally-CLEARED target: assert M20 did not finalize dispatcher or release reservation;
- renderer foreign-board after a REAL pending assignment before arrival needs a direct arrival-preflight arrangement; V08 currently proves foreign renderer blocks activation before dispatch, which is a different boundary;
- duplicate queued owner+agent should be directly isolated, not inferred from the current-arrival/FIFO arrangement.

### G-V08-04 — final SB-M20 ledger contains proxy/one-direction assertions

Fresh V08 ledger is valuable, but several rows do not yet meet the exact closure criterion:

- SB-M20-001 checks `ReservationState.get_owner(target) == -1` but not the inverse `get_target_for_owner(owner) == -1`.
- SB-M20-002 checks only `NO_REACHABLE_TARGET`; it does not directly assert zero dispatcher active, zero reservation and no BoardState clear for both no-target and enclosed-target arrangements.
- SB-M20-006 verifies selected target indices but does not directly prove unrelated other-color candidate truth remains intact.
- SB-M20-007 initial “exact pairs” checks only target -> owner, not owner -> target. After first arrival it checks remaining dispatcher owners but not the four exact bidirectional reservation pairs. After all five it checks cleared_count but not final active/reservation zero.
- AL-028 V08 ledger does not explicitly prove B is unreachable before A clears, and does not directly assert B's exact reservation exists before B arrival.
- slot immutability on success is checked only for slot 0, not as a five-slot before/after tuple.
- multi-in-flight reset checks active/reservation count but should also prove BoardState/candidate truth was not mutated by reset.

SB-M20-003 frame destruction is directly established by the separately executed `tests/m20_queue_free_smoke.gd` and is accepted.

### G-V08-05 — fresh rollback/reset block does not cover its full final freeze

Fresh `_v08_rollback()` directly covers candidate mutate-before-false, reservation mutate-before-false, candidate true-without-postcondition, owner-map identity swap, reset during candidate/reservation, duplicate-current + distinct FIFO, healthy pair-narrow + unrelated reservation, foreign-board replacement, and post-dispatch generation barrier.

But the final V08 freeze/criteria also require fresh/direct coverage of:
- reservation true-without-postcondition;
- unrelated same-color candidate loss preservation/fatal detection;
- unrelated different-color candidate preservation;
- exact prestate verification after mutate-before-false, not outcome-only;
- missing-current-pair cleanup must not fabricate/delete unrelated reservation;
- same-board owner replacement preservation under reset.

Prior V02-V07 regression blocks contain adjacent/direct tests and remain enabled, so this is not evidence that production is broken. The final validation-only policy, however, requires the final auditor-authored gate itself to carry the complete high-risk matrix.

### G-V08-06 — log mapping precision

`CLAUDE_LOG_V08.md` is organized by behavior groups but does not explicitly map the final evidence back to G-V07-01..08 as V08 criterion 293 requests. This is procedural, not production.

V09 must include an explicit gap-closure table mapping every frozen V09 group/criterion to named test assertions and sensitivity where applicable.

## Accepted V08 evidence

The following V08 evidence is accepted and need not be redesigned:
- production immutability independently confirmed;
- WeakRef owner GC/no-strong-cycle frame smoke;
- truly-freed explicit parent before bind and destroyed-before-dispatch smoke;
- truly-freed renderer before arrival no-clear behavior;
- V08 doc correction to `docs/02_TECH_ARCHITECTURE.md` reflects M12-M20 current truth and M10 QA completion;
- all six sensitivity mutations are reported with named intended failures and exact restoration;
- `m20_queue_free_smoke.gd` directly proves finalized agent is actually destroyed after SceneTree frames with no dispatcher orphan;
- V04/V05/V07/V08 lifecycle regression scripts remain separate and were reported green.

## Reusable audit learnings from V08

### AL-067 — captured-but-unasserted state is not evidence

If a snapshot helper stores a field but the test never compares it after the operation, the field is not validated. A green test can silently coexist with mutation of the unasserted field.

Required future check: snapshot helpers used for fail-closed/no-mutation claims must compare every canonical field named by the criterion.

### AL-068 — negative-test setup order is part of the property

A test that installs a supposed non-blocking observer only after the protected claim has already succeeded cannot prove the observer was non-blocking at claim time.

Required future check: arrange the challenged condition before the boundary whose behavior it claims to test.

### AL-069 — exact bidirectional ownership needs bidirectional assertions

For owner<->target state, target->owner alone is not an exact-pair proof. Final ledger tests must prove both directions and preserve both directions for unrelated/in-flight pairs.

## Task disposition

No SB-M20 task closes in V08. This is NOT because a production defect was found. It is because final critical-sprint closure requires direct auditor-authored evidence and the V08 tests do not yet satisfy every exact criterion.

Production remains source-accepted. The next pass must be evidence-only and production-immutable.

## Frozen next action

Issue one comprehensive `M20-C001 V09` final evidence-only validation pass containing ALL G-V08-01..06 together. No production correction is authorized.

If V09 closes these evidence gaps with the exact production blobs unchanged and no new production defect exposed, ChatGPT may issue `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` and close SB-M20-001..014.
