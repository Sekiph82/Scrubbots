# M19-C001 — ChatGPT Independent Audit V05

Decision: **SOURCE_CORRECTION_ACCEPTED / VALIDATION_ONLY_V06_REQUIRED**

Audited implementation commit:
`9cf1e7d75009ba50d02db35802aa5cf345f9752a`

H!veAI start-transition commit:
`1566402867a498ca52c618f9b3068fbb520232de`

H!veAI handoff commit:
`3697393cb0120757230a041e3817e52dcd0ff6c1`

Prompt:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V05.md`

Criteria:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V05.md`

Claude evidence:
`coordination/sessions/M19-C001/CLAUDE_LOG_V05.md`

Prior audit:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V04.md`

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb` and **3203 / 3203 ALL PASS**, zero final SCRIPT ERROR / Parse Error lines, and clean `git diff --check`.

Those runtime results are E1/E2. Godot is unavailable in the ChatGPT audit environment, so ChatGPT did not independently execute the suite.

ChatGPT independently inspected:
- exact V05 implementation commit and changed-file scope;
- current `scrubbot_dispatcher.gd` transaction ordering;
- V05 reservation-proof and reset-state doubles;
- V05 direct adversarial assertions;
- current final M15-C002 TargetSelector integration behavior;
- canonical H!veAI TASKS / EVENTS lifecycle;
- post-V05 dispatcher public/stateful surface.

This is E3 source/diff/adversarial-test evidence.

# H!veAI v3 audit — PASS

V05 corrected the prior local-ordering process nonconformance.

Canonical sequence:
1. sync/read canonical tracker;
2. `CHANGES_REQUIRED -> IN_PROGRESS` tracker/event;
3. start transition pushed and remote-verified at `1566402`;
4. only then V05 production/test edits;
5. implementation commit `9cf1e7d`;
6. handoff `IN_PROGRESS -> AWAITING_AUDIT` at `3697393`.

Claude explicitly records that **no V05 production or test edit existed before the successful IN_PROGRESS push**. Durable Git history agrees with the required start -> implementation -> handoff ordering.

Final V05 tracker correctly remained:
- task `M19-C001-V05`;
- workflow `AWAITING_AUDIT`;
- required actor `CHATGPT`;
- progress `278 / 719 = 38.66%`;
- last completed task `M15-C002-V03`;
- M19 root task rows still open.

# V05 correction audit

## F-M19-STRICT-001.G / 003.H — pending-owner baseline — ACCEPTED

Current dispatcher now performs:
1. `get_target_for_owner(owner_id)` into untyped Variant;
2. reset-generation check;
3. TYPE_INT check;
4. exact bundle-coherence check;
5. reset-generation check;
6. require exact `-1`;
7. only then enter selector.

This closes the V04 gap where a dependency could drift during the baseline callback and the selector would still be entered.

V05 direct tests distinguish:
- malformed baseline;
- non-`-1` baseline;
- reset during baseline;
- bundle drift during baseline;

and directly prove selector call count remains zero on those failure paths.

## F-M19-STRICT-003.G — canonical selector `-1` owner-side-effect query — ACCEPTED

The post-`-1` ownership callback is now bracketed as a full external boundary:
- callback result captured untyped;
- generation checked first;
- TYPE_INT required;
- bundle coherence rechecked;
- generation rechecked;
- only then canonical no-target truth is interpreted.

Direct cases cover reset, drift, malformed return, canonical no-side-effect `-1`, and secret reservation with narrow cleanup.

## F-M19-STRICT-003.I — generation precedence over agent-state probe verdict — ACCEPTED

Both helper seams now follow the required order.

### `_dispatcher_ownable`
- store helper verdict;
- check generation;
- RESETTING rollback wins;
- only then interpret false as AGENT_ASSIGN_FAILED.

### `_agent_assigned_ok`
- store helper verdict;
- check generation;
- RESETTING rollback wins;
- only then interpret false as AGENT_ASSIGN_FAILED.

The dedicated `M19ResetStateAgent` makes the callback both reset the dispatcher and return a state that makes the helper verdict false. Therefore these tests are sensitivity-safe for the exact ordering defect.

Claude also records a temporary mutation reversing `_dispatcher_ownable` ordering; the intended test failed with AGENT_ASSIGN_FAILED rather than RESETTING, then production was restored. This is strong direct-observability evidence.

## F-M19-STRICT-002 evidence remainder — ACCEPTED

V05 directly exercises malformed positive ownership proof:
- malformed `get_target_for_owner` after a real pending reservation;
- malformed `get_owner` after a real pending reservation;
- no route;
- no active assignment;
- no owner-id advance;
- pending attempt reservation removed;
- unrelated reservation preserved.

## Real M15-C002 integration — ACCEPTED

V05 uses the current production TargetSelector, ReservationState and ColorCandidateIndex. During `access_query.is_targetable()`, the adversary attempts to bind the selector to a second bundle.

The final M15 transaction law keeps selection on the original bundle. V05 observes:
- selector remains exact-bound to original board/reservations;
- foreign ReservationState receives no orphan reservation;
- M19 commits only exact original-bundle ownership when successful;
- later coherent dispatch remains usable.

M15 production is unchanged.

# Full post-V05 source sweep

No material new M19 defect was found in the frozen dispatcher scope.

Accepted and preserved across V02-V05:
- initialization-only/coherent bundle bind;
- RefCounted collaborator category boundary;
- nested bind protection and reset-during-bind;
- finite request validation;
- serial dispatch re-entry protection;
- exact selector Variant + reservation proof;
- no raw-candidate-as-work shortcut;
- no retarget;
- cached-route vs invalid-cached-route distinction;
- RouteValidator enforcement;
- explicit factory invalidation fail-closed;
- foreign/reused factory-product protection;
- assign actual-bool gate;
- assign postconditions;
- generation precedence after callback-bearing routing/factory/agent phases;
- reset re-entry safety;
- completion source/owner/target/color identity;
- successful arrival does not yet clear/release/score;
- final add-child source guards, subject to the already-documented headless locked-object runtime limitation.

No M20 responsibility moved into M19.

# Strict-v2 stage decision

M19 is a critical/stateful orchestration system.

V05 changed production code. ChatGPT can provide E3 source/diff/test-design evidence but cannot independently run Godot here. Under `coordination/AUDIT_POLICY.md`, final closure therefore requires the auditor-authored adversarial validation stage.

V05 is NOT rejected. Its production correction is source-accepted.

Next cycle is **M19-C001 V06 VALIDATION-ONLY**.

V06 must:
- make zero committed production changes;
- independently exercise the highest-risk M19 transaction seams using auditor-selected adversaries;
- include load-bearing sensitivity checks with temporary mutations restored before final run;
- prove the V05 dispatcher production blob is unchanged;
- rerun the complete root suite on Godot 4.7.1.

If V06 passes, ChatGPT may final-close:
- SB-M19-001 through SB-M19-012.

Expected post-close progress:
- Main + UI: **290 / 719 = 40.33%**;
- Overall: **290 / 943 = 30.75%**.

Until V06 independently audits clean, progress remains:
- Main + UI: **278 / 719 = 38.66%**;
- Overall: **278 / 943 = 29.48%**.

## Frozen finding status after V05

- F-M19-STRICT-001 — **SOURCE_CORRECTION_ACCEPTED / pending V06 validation**
- F-M19-STRICT-002 — **SOURCE_CORRECTION_ACCEPTED / pending V06 validation**
- F-M19-STRICT-003 — **SOURCE_CORRECTION_ACCEPTED / pending V06 validation**
- F-M19-STRICT-004 — **CLOSED / regression-only**

## Verdict

**SOURCE_CORRECTION_ACCEPTED / VALIDATION_ONLY_V06_REQUIRED**

Do not start M20 yet.
