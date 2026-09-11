# M20-C001 — ChatGPT Independent Audit V06

Decision: **SOURCE_CORRECTION_ACCEPTED / WHOLE_SPRINT_V07_CORRECTION_REQUIRED**

Audited implementation commit:
`b4e960aaad8662ae4192a7ba57530940ff8767f9`

V06 start-transition commit:
`77b09bd3cc5be9b1d9f517404a99b599574b746b`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V06.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V06.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V06.md`

Current canonical tracker: repository-root `TASKS.md` only.

Policy applied to this audit:
`coordination/AUDIT_POLICY.md`, including owner-directed commit
`45ab64623e26478009c3fdbf5a43b51a7101f4a8` which requires sprint-wide two-pass auditing, task ledger, sibling search, interaction sweep and criteria-to-evidence reconciliation before another prompt may be issued.

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full suite **3655 / 3655 PASS**, V05 lifecycle smoke PASS, V04 lifecycle smoke PASS and queue-free smoke PASS. Those runtime results remain E1/E2 because ChatGPT cannot independently execute Godot here.

ChatGPT independently inspected the current M20/M19 production sources, V01-V06 prompts/audits/criteria, M20 tests, M19 arrival/reset seams, BoardState, ColorCandidateIndex, ReservationState, SlotSystem, ProductionAccessQuery, ProductionTargetAccess, BoardRenderer, root TASKS state and the V06 commit chain. This is E3 source/diff/test-structure evidence.

# Pass A — whole-sprint implementation/state sweep

## V06 correction accepted: F-M20-STRICT-001.L

The V05-exposed optional-renderer null-alias defect is source-corrected.

Accepted properties:
- renderer presence is persisted independently of `_renderer == null`;
- actual `TYPE_NIL` is the intentional headless case;
- a non-NIL renderer argument remains an explicit dependency;
- a truly-freed renderer therefore still goes through the live exact-node gate;
- successful bind commits `_renderer_expected`; failed bind does not;
- post-bind renderer death cannot silently downgrade a configured bundle to headless;
- repaint remains after authoritative dispatcher finalization;
- no other V06 production file changed.

Accepted V06 clearing-loop blob:
`514838fa6d965ffa1f5663b9c4c5385c12f63114`

Preserved dispatcher blob before the V07 corrections below:
`1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`

## Whole-sprint finding F-M20-STRICT-001.M — duplicate clearing-loop authority is not excluded

This is an auditor completeness miss that should have been caught earlier under duplicate ownership/contention. It is not presented as a newly-created V06 bug.

Current `CompleteClearingLoop.bind()` proves bundle coherence and dispatcher active-count zero, then connects its own `assignment_arrived` callback. Nothing claims exclusive M20 transaction authority for that dispatcher.

Therefore two different `CompleteClearingLoop` instances can bind the same healthy dispatcher/bundle while active count is zero. Both become signal consumers and both expose activation/reset/counter APIs over the same canonical state.

Canonical BoardState is usually protected by synchronous preflight/finalization ordering, but orchestration ownership is split: callback order can decide which loop increments `cleared_count` and which records `PREFLIGHT_REJECTED`; either loop can reset assignments created through the other. A valid public bind must not create two competing M20 transaction owners for the same dispatcher.

Frozen correction:
- add one narrow dispatcher-owned M20 arrival-consumer claim;
- claim must not depend on signal connection count, so unrelated diagnostic observers are not treated as transaction owners;
- `CompleteClearingLoop.bind()` must acquire that claim before committing the arrival bridge;
- second live clearing-loop bind to the same dispatcher must fail cleanly with no second M20 arrival connection and no mutation of the first bundle;
- failed claim/connect must leave the new loop unbound;
- original loop must remain coherent and usable;
- use weak/non-owning identity or an equally safe design so the claim does not create a hidden strong ownership cycle;
- do not add a general gameplay singleton/global.

## Whole-sprint finding F-M20-STRICT-001.N — explicit M19 agent_parent can suffer the same freed-Object/null-alias fallback

This sibling finding is allowed after the prior freeze because the decisive Godot runtime fact was first exposed by V05: a truly-freed Object can compare `== null` while remaining `TYPE_OBJECT`.

`ScrubbotDispatcher.bind(..., agent_parent: Node = null, ...)` currently distinguishes default parent from explicit parent with `agent_parent != null` and commits:

`_agent_parent = agent_parent if agent_parent != null else self`

A truly-freed explicit Node can therefore alias to the omitted/default case and silently fall back to `self`, exactly the configuration-loss class prohibited by AL-066.

Frozen correction:
- distinguish omitted/actual-null parent from explicit non-NIL parent by Variant/configuration truth, not `!= null` equality;
- a truly-freed explicit Node must fail bind, not select the default parent;
- queued explicit parent remains rejected;
- wrong/scalar explicit parent fails cleanly if the parameter is made untyped to preserve Variant truth;
- omitted/actual-null still means intentional dispatcher-self parent;
- healthy explicit parent still works;
- post-bind parent liveness before attach remains unchanged;
- do not redesign agent ownership/factory semantics.

Sibling optional-lifecycle surfaces checked after this finding:
- M20 optional renderer: corrected by V06;
- M19 explicit agent factory: already persists `_explicit_factory` and fails closed after invalidation;
- M19 `_agent_parent`: defect above;
- BoardState/ColorCandidateIndex/ReservationState/SlotSystem: RefCounted canonical dependencies, no externally-freed Node default substitution;
- BoardRenderer board ref: RefCounted BoardState, not the freed-Node presence class.

No additional material sibling of this root class was found in the active M20 dependency surface.

# Pass B — evidence/test/policy sweep

## Audit specification defect in V06 criterion 204

V06 criterion 204 required the temporary equality/null mutation to make “at least one V06 direct null-vs-dead test” fail. The V06 direct root-runner block intentionally puts the truly-freed case in the separate frame-aware V05 lifecycle smoke; A/B/C/D/E/G in the root runner do not include a truly-freed object.

Claude recorded the required failure in the frame-aware smoke, but not a root-runner V06 direct case. This is primarily an **AUDIT SPECIFICATION DEFECT authored by ChatGPT**, not a new production failure. V07 removes the artificial distinction and requires named frame-aware/direct evidence for the same invariant.

## V06 criteria/direct-observability gaps collected in one batch

The following are evidence gaps, not source-proven V06 defects:

1. explicit renderer Variant matrix is incomplete in direct tests: int exists, but float/String/Vector2 and other representative non-object Variants are not directly covered;
2. failed renderer bind -> same loop clean retry is not directly demonstrated, so failed-bind presence metadata needs direct recovery evidence;
3. successful renderer bind followed by refused second bind must directly prove the original renderer-presence contract is preserved;
4. configured renderer rebound/configured to a foreign board after bind lacks a fresh direct M20 test;
5. configured renderer lost after dispatch but before authenticated arrival lacks a fresh direct arrival-preflight arrangement;
6. healthy renderer clear does not freshly assert an unrelated renderer pixel is unchanged;
7. candidate index rebind/unbind before arrival was required by V01 but lacks a direct M20 arrival-preflight arrangement;
8. reservation wrong-owner/replacement before arrival needs a direct loop-level preflight arrangement;
9. wrong owner/target/color/source should be injected through the M20 arrival boundary itself on a real pending assignment, rather than relying only on dispatcher query checks;
10. M20 activation must directly exercise NaN/+INF/-INF across position/speed at its own public boundary;
11. the final whole-sprint gate must freshly re-cover every SB-M20-001..014 row, not infer closure from aggregate V01-V06 green totals.

## Documentation drift collected in the same batch

Two current non-historical texts are stale:
- the M20 header comment in `tests/run_tests.gd` still describes the old renderer-before-dispatcher-finalize order;
- `docs/02_TECH_ARCHITECTURE.md` says simultaneous Scrubbots are “bounded by slot count”, but M20 deliberately does not introduce per-slot busy/cooldown/consumption policy and `activate_slot()` does not mutate slot availability/activity. The doc must not claim a hard five-agent cap that current gameplay does not enforce.

Historical prompts/audits are evidence and must not be rewritten merely to update old transaction language.

# Sprint task coverage ledger

Status here is provisional audit coverage, not root-task closure.

| Task | Production owner / state | Direct evidence inspected | Status before V07 |
| --- | --- | --- | --- |
| SB-M20-001 Wire complete sequence | CompleteClearingLoop + M19 bridge; BoardState/candidate/reservation/dispatcher/renderer | V01/V02 transaction tests, V05 integration | GAP: exclusive loop authority + final fresh whole-sprint proof |
| SB-M20-002 No target means no bot | activate_slot -> M19 selector/routing | no-target + enclosed regressions | PROVEN, regression-lock |
| SB-M20-003 No return | dispatcher finalize -> queue_free | frame-aware queue-free smoke | PROVEN, regression-lock |
| SB-M20-004 One-cell | real 1x1 | V05.7 true 1x1 | PROVEN, regression-lock |
| SB-M20-005 One-color | candidate depletion/exhaustion | V01 scenario matrix | PROVEN, regression-lock |
| SB-M20-006 Multi-color | slot color -> selector/dispatch | V01 scenario matrix | PROVEN, regression-lock |
| SB-M20-007 Five-slot | 5 slot activations, owners/targets/reservations | V05.7 exact five-pair evidence | PROVEN, regression-lock |
| SB-M20-008 Easy | production-size synthetic integration | V01 dimension matrix | PROVEN, regression-lock |
| SB-M20-009 Medium | production-size synthetic integration | V01 dimension matrix | PROVEN, regression-lock |
| SB-M20-010 Hard | production-size synthetic integration | V01 dimension matrix | PROVEN, regression-lock |
| SB-M20-011 Very Hard | production-size synthetic integration | V01 dimension matrix | PROVEN, regression-lock |
| SB-M20-012 59x59 | max board clear/single-cell path | V03/V05 max tests | PROVEN, regression-lock |
| SB-M20-013 Rectangular | 53x59 integration | V01/V05 rectangular tests | PROVEN, regression-lock |
| SB-M20-014 State-desynchronization | exact bundle/preflight/reset/rollback | V02-V05 adversaries | GAP: collected pre-arrival drift/forgery + optional lifecycle + multi-loop ownership matrix |

# Interaction sweep

Checked before freezing V07:
- reset + callback: V02/V04/V05 coverage retained;
- reset + reservation-board drift: pair-narrow reset retained;
- lifecycle death + optional dependency: renderer corrected; agent_parent sibling defect frozen;
- rollback + unrelated reservation/candidate state: exact owner-map and unrelated candidate tests retained;
- duplicate/re-entry + current/queued arrival identity: V03/V05 coverage retained;
- completion + stale owner/target/color/source: existing M19 identity checks retained; loop-level direct evidence added to V07;
- scale + state synchronization: 59x59/rectangular/single-cell sync retained;
- presentation failure + canonical gameplay state: renderer remains post-finalize presentation; renderer-loss preflight tests added to V07;
- duplicate orchestrator ownership: defect F-M20-STRICT-001.M frozen.

No additional material source defect was found after this second interaction review.

# V06 criteria reconciliation disposition

V06 production correction is **source accepted**. V06 is not final-closure eligible because:
- criterion 204 was authored inconsistently with the direct/smoke split;
- several direct-observability rows above remain gaps under the owner-strengthened policy;
- F-M20-STRICT-001.M requires production correction;
- F-M20-STRICT-001.N requires upstream production correction.

All SB-M20-001..014 remain open. Progress remains `290/719 = 40.33%` main+ui and `290/943 = 30.75%` overall.

# Next cycle

Issue one batched **M20-C001 V07** correction/evidence pass containing the ENTIRE frozen set above.

Because V07 will modify production, a clean V07 must be followed by one auditor-authored **V08 validation-only whole-sprint gate** before final M20 closure. V08 must not discover avoidable known-surface omissions; its job is to adversarially validate the frozen V07 result with production immutable.
