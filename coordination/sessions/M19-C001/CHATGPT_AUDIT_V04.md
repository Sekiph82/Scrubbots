# M19-C001 — ChatGPT Independent Audit V04

Decision: **CHANGES_REQUIRED / SAME_FROZEN_SET / V05_REQUIRED**

Audited implementation commit:
`50aac5d976abe1ec5bb8e357bbd7871a70aee57e`

H!veAI start-transition commit:
`aa8ebb9a9af81ca62969fe498f2e989d61517acf`

H!veAI handoff commit:
`6ec52081c07b9c032afc2431714558fd19c033e8`

Prompt:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V04.md`

Criteria:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

Claude evidence:
`coordination/sessions/M19-C001/CLAUDE_LOG_V04.md`

Prior frozen remainder:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`

## Runtime / independence

Claude reports Godot 4.7.1 and **3163 / 3163 ALL PASS**, with zero final SCRIPT ERROR / Parse Error lines and clean `git diff --check`.

Those runtime results are E1/E2 because Godot is unavailable in the ChatGPT audit environment.

ChatGPT independently inspected:
- the exact V04 implementation diff and current dispatcher source;
- V04 selector/factory/reset/coherence doubles;
- the V04 direct test block;
- current M15-C002 final TargetSelector;
- M16-M18 collaborators;
- H!veAI GitHub-first v3 start/final state and events;
- the post-V04 transaction surface.

This is E3 source/diff/adversarial-test evidence.

## V04 corrections accepted and preserved

The following V04 changes are source-accepted and must not be regressed.

### F-M19-STRICT-001.D — bind transaction

Accepted:
- explicit `_in_bind` guard;
- nested bind from bind-time coherence seams is rejected;
- reset generation is captured before bind coherence;
- reset-during-bind prevents bundle commit;
- parent/factory liveness is revalidated before commit;
- ordinary already-bound bind remains false/preserve.

### F-M19-STRICT-001.E / 002.D — selector Variant + reservation proof

Accepted:
- raw selector return is captured untyped;
- only TYPE_INT is interpreted as selector result;
- negative int other than -1 is rejected;
- positive selected target requires exact owner->target and target->owner proof in the dispatcher's ReservationState;
- owner id does not advance until exact positive ownership proof passes;
- lying/malformed selector cases use narrow cleanup and do not route/spawn;
- unrelated other-owner reservation is preserved in the tested matrix.

### F-M19-STRICT-003.D — most callback-generation ordering

Accepted:
- reset generation is checked after initial/post-selection/post-routing/post-factory/post-assign/post-add coherence helpers;
- cached and fresh `_route_ok` / RouteValidator callback resets are checked before factory;
- reset during post-routing coherence blocks factory;
- reset during post-factory coherence blocks assign;
- reset during post-assign coherence blocks add-child.

### F-M19-STRICT-003.E — reset re-entry

Accepted:
- `reset()` is a stable no-op while `_resetting`;
- outer reset increments generation once;
- nested reset from `cancel()` does not recurse;
- agent validity is rechecked after cancel before parent/free access.

### F-M19-STRICT-002.E — assign return type

Accepted:
- assign result is captured untyped;
- only actual TYPE_BOOL true is accepted;
- legal non-bool override is directly demonstrated and rejected.

### F-M19-STRICT-001.F / 003.F — post-add source guards

Source-accepted:
- generation check immediately after add_child;
- post-add bundle coherence + generation recheck;
- final instance/expected-parent revalidation;
- detach/free/release on failure.

The headless engine limitation prevents a clean synchronous `_ready` self-free/reset adversary without locked-object engine errors. This remains a validation limitation, not by itself a new production defect.

### F-M19-STRICT-004

**CLOSED.** Preserve finite request validation.

# Remaining same-frozen-set defects / validation gaps

No new top-level M19 finding IDs are opened. The remainder stays under F-M19-STRICT-001..003.

## F-M19-STRICT-003.G — canonical `-1` owner-side-effect query is an unbracketed callback boundary

After a canonical selector return of `-1`, V04 does:

```gdscript
var owned_after = _reservations.get_target_for_owner(owner_id)
if typeof(owned_after) != TYPE_INT or owned_after != -1:
    ...
return NO_REACHABLE_TARGET
```

There is no immediate reset-generation check and no bundle-coherence check after this external ownership callback.

Therefore a compatible ReservationState can, inside `get_target_for_owner()`:
- call dispatcher.reset() and return -1; or
- drift/rebind itself and return -1.

The dispatcher can then report `NO_REACHABLE_TARGET` even though reset or dependency drift occurred during the callback.

Required:
- capture callback result;
- check reset generation immediately;
- validate TYPE_INT;
- re-check exact bundle coherence + generation;
- only then interpret `-1` as canonical no-target.

RESETTING must win if reset occurred. COHERENCE_FAILED must win if non-reset drift occurred.

Direct tests must prove no later route/factory/agent and no pending reservation.

## F-M19-STRICT-001.G / 003.H — pending-owner baseline is not fully bracketed for dependency drift

Before selector invocation V04 queries:

```gdscript
var pre_owned = _reservations.get_target_for_owner(owner_id)
```

It checks generation and TYPE_INT, but not bundle coherence after the callback before entering the selector phase.

A compatible ReservationState callback can rebind/drift while returning `-1`. Current downstream checks eventually fail in many normal paths, but the selector external phase has already been entered after a known-unchecked dependency boundary.

The transaction law is stronger: after every callback-bearing ownership boundary that precedes the next consequential phase, prove generation + exact bundle coherence before starting that phase.

Required:
- after the pending-owner baseline query: generation -> TYPE_INT -> bundle coherence -> generation;
- selector must not be called if the baseline callback drifted the bundle.

Direct counter evidence must prove selector call count stays zero after baseline drift/reset.

## F-M19-STRICT-003.I — agent-state probe verdict is interpreted before reset generation

V04 intended the law:
**after every overridable agent-state probe, RESETTING wins before interpreting the probe verdict.**

Current source violates that ordering twice.

### `_dispatcher_ownable(agent)`

Current order:

```gdscript
if not _dispatcher_ownable(agent):
    ... return AGENT_ASSIGN_FAILED
if _reset_since(my_gen):
    ... return RESETTING
```

`_dispatcher_ownable()` calls subclass-overridable `get_state()`.

A test subclass can call `dispatcher.reset()` from `get_state()` and return a non-UNASSIGNED state. The helper returns false and the dispatcher returns AGENT_ASSIGN_FAILED before observing the reset generation.

Required order:
1. store `_dispatcher_ownable()` result;
2. check generation;
3. RESETTING rollback if changed;
4. only then interpret ownability result.

### `_agent_assigned_ok(...)`

Current order has the same flaw:

```gdscript
if not _agent_assigned_ok(...):
    ... return AGENT_ASSIGN_FAILED
if _reset_since(my_gen):
    ... return RESETTING
```

`_agent_assigned_ok()` calls subclass-overridable `get_state()`.

If the state callback triggers reset and simultaneously causes the helper verdict to be false, AGENT_ASSIGN_FAILED incorrectly wins over RESETTING.

Required order:
1. store postcondition verdict;
2. check generation;
3. RESETTING rollback if changed;
4. only then interpret postcondition verdict.

Direct sensitivity-safe subclasses must trigger reset from `get_state()` and return a state that makes each helper false. Expected result is RESETTING, with no later phase.

## F-M19-STRICT-001.H / 002.F — V04 did not directly exercise the required real M15-C002 integration adversary

V04 criteria 63-68 required a real final TargetSelector integration where targetability attempts to rebind the selector/dependency bundle during selection.

The V04 additions exercise the final TargetSelector on ordinary successful dispatch and preserve the whole M15 suite, but the new M19 V04 block does not directly reproduce the M15-C002 rebind adversary inside an M19 dispatch.

This is an evidence gap, not a newly identified TargetSelector defect.

V05 must directly integrate:
- current real TargetSelector from M15-C002 V03;
- targetability callback attempting selector.bind/rebind or ReservationState/candidate drift;
- no foreign reservation;
- no split-brain routing;
- clean failure/recovery according to the final M15 transaction law.

M15 production remains READ-ONLY.

## Additional direct-observability gaps to close in the same V05 pass

Because V05 is already required, close these adjacent V04 criteria without opening new finding IDs:
- malformed pending-owner baseline return type directly tested;
- malformed positive `get_target_for_owner` ownership-proof result directly tested;
- malformed positive `get_owner` ownership-proof result directly tested;
- reset/drift inside the canonical `-1` owner-side-effect query;
- reset/drift inside the pre-selector pending-owner baseline;
- post-failure reservation count and unrelated-reservation preservation observed directly.

# H!veAI v3 process audit — NONCONFORMANCE

Durable GitHub commit order is correct:
- `aa8ebb9` start tracker/event;
- `50aac5d` implementation;
- `6ec5208` AWAITING_AUDIT handoff.

However V04 prompt and criterion 6 explicitly required the IN_PROGRESS transition to be pushed **before ANY V04 production/test edit**.

Claude's own log discloses:
> some dispatcher edits were authored locally before the IN_PROGRESS push

Therefore V04 criterion 6 is **NOT satisfied**.

This is the same process class previously exposed in M15-C002 V02. It does not invalidate the source corrections already accepted, but it prevents V04 from being a clean strict closure.

V05 must not repeat it:
- sync/read tracker;
- update IN_PROGRESS + event;
- commit + push;
- only AFTER the successful push may any V05 production or test file be edited.

Claude log must state whether local edit ordering complied, not merely durable commit ordering.

# V04 task/progress disposition

Do NOT close:
- SB-M19-001..012

Progress remains:
- Main + UI: **278 / 719 = 38.66%**
- Overall: **278 / 943 = 29.48%**

Frozen status:
- F-M19-STRICT-001 — OPEN remainder
- F-M19-STRICT-002 — OPEN remainder/evidence
- F-M19-STRICT-003 — OPEN remainder
- F-M19-STRICT-004 — CLOSED / regression-only

## Verdict

**CHANGES_REQUIRED / SAME_FROZEN_SET / V05_REQUIRED**

Next executable cycle:
`M19-C001 V05`.

Because V05 will contain production corrections, a clean V05 should normally be followed by a narrow auditor-authored **validation-only V06** before final-closing SB-M19-001..012, since ChatGPT cannot independently execute Godot.
