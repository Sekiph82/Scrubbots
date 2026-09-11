# M20-C001 — ChatGPT Independent Audit V03

Decision: **CHANGES_REQUIRED / SAME_FROZEN_SET / V04_REQUIRED**

Audited implementation commit:
`28da9701c3185188b4563aaccb73feaf6032c576`

Tracker start-transition commit:
`c6c684327199817dd1ce7958e91cc27c39648393`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V03.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V03.md`

Prior audit:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_V02.md`

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb`, root suite **3533 / 3533 ALL PASS**, the dedicated M20 queue-free smoke PASS, and clean `git diff --check`.

These runtime results are E1/E2. ChatGPT cannot independently execute Godot in the audit environment, so they are not E3 runtime proof.

ChatGPT independently inspected:
- root `TASKS.md` live state;
- V03 prompt / criteria / log;
- exact start -> implementation Git ordering;
- implementation commit and changed-file scope;
- current `complete_clearing_loop.gd`;
- current exact `ReservationState`, `SlotSystem`, `ScrubbotDispatcher`, `BoardRenderer` contracts;
- V03 test harness and adversarial support changes;
- the complete post-correction M20 public/stateful surface.

This is E3 source/diff/test-design evidence.

## Root TASKS lifecycle — PASS

Remote history is correctly ordered:
1. V03 prompt/criteria existed on main;
2. tracker-only start transition `c6c6843` moved V03 to `IN_PROGRESS / CLAUDE`;
3. that start commit is the direct parent of implementation commit `28da9701`;
4. implementation commit returns root `TASKS.md` to `AWAITING_AUDIT / CHATGPT`;
5. progress remains 290/719 main+ui and 290/943 overall;
6. lastCompletedTaskId remains M19-C001-V06;
7. no SB-M20 row was closed by Claude.

No V03 start-order process defect was found.

## V03 corrections accepted

### F-M20-STRICT-001 trust-boundary narrowing — ACCEPTED PART

Production M20 now requires exact script identity for:
- BoardState;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- ScrubbotDispatcher;
- optional BoardRenderer.

Candidate/reservation subclasses can no longer enter production `bind()`. The test-only harness preserves rollback sensitivity without reopening production polymorphism.

This closes the V02 subclass-spoof route itself.

### F-M20-STRICT-004 exact reservation state — ACCEPTED

V03 replaces count-only proof with a detached target->owner snapshot and exact map comparison.

After `resolve_arrival`, production now proves the reservation map equals pre-state minus the exact current target. Rollback verifies the complete pre-state owner map before reporting an ordinary rollback outcome.

The prior U->V same-count substitution can therefore no longer masquerade as successful rollback. In the adversarial harness it correctly escalates to `ROLLBACK_FAILED`.

### F-M20-STRICT-006 current-arrival dedup — ACCEPTED PART

V03 publishes private current owner+agent identity while one arrival transaction executes and rejects duplicates of the current or already-queued identity. Distinct arrivals remain FIFO.

No mutable public queue/current identity was introduced.

## Evidence nonconformance: V03 pre-fix sensitivity

V03 prompt §3 explicitly required the three pre-fix sensitivity attacks to be executed against the V02 source before narrowing.

The V03 log mostly gives source-derived statements such as “would have been reported” and post-fix executable proof. It does not provide the requested concrete V02 runtime observations for all three attacks.

This is an evidence/process miss, not by itself a new gameplay finding. The underlying V02 weaknesses were already independently source-proven and V03 source corrections are inspectable. V04 must not repeat this: its pre-fix sensitivity cases must record actual V03-baseline observations before correction.

# Post-V03 full attack-surface sweep

Strict-v2 requires the post-correction audit to re-run the whole stateful surface conceptually. That sweep found three remaining material gaps plus one documentation drift. They stay inside the already-frozen top-level F-M20-STRICT-001..007 set.

## F-M20-STRICT-001.K — exact script is not sufficient Node lifecycle validation

**Status: OPEN / V04 REQUIRED**

`ScrubbotDispatcher` is a `Node`; `BoardRenderer` is a `TextureRect`/Node.

Current helper:

```gdscript
static func _is_exact_script(obj, script) -> bool:
    return obj != null and typeof(obj) == TYPE_OBJECT and obj.get_script() == script
```

Problems:
1. `get_script()` is called before proving an Object/Node instance is still valid;
2. a previously-freed dispatcher/renderer can therefore reach a method call on an invalid instance instead of cleanly returning false;
3. a Node already queued for deletion remains `is_instance_valid()==true`, so exact-script/category checks can accept a dependency whose lifetime is already ending;
4. live `_probe()` calls `disp.is_bound_to(...)` without any dispatcher liveness gate;
5. renderer `_probe()` checks `is_instance_valid()` but not `is_queued_for_deletion()`;
6. after bind, `is_coherent()` / `activate_slot()` can therefore fault or temporarily accept dying Node dependencies rather than fail closed.

Required law: Node collaborators must be live (`is_instance_valid` and not queued for deletion) before any method/property call. RefCounted exact collaborators remain lifecycle-stable while referenced.

Bind-time freed/queued dispatcher and renderer, plus post-bind queue/free, need direct tests with zero SCRIPT ERROR.

### Documentation drift under F-M20-STRICT-001.K

The bind doc comment still says candidate/reservation “accept subclasses (for controlled rollback testing)” even though V03 correctly rejects them. This is stale current-law prose and must be corrected in V04.

## F-M20-STRICT-002.K — dispatcher.dispatch is not bracketed by the M20 activation transaction

**Status: OPEN / V04 REQUIRED**

Current `_activate_core()` performs final pre-dispatch generation/coherence checks and then directly returns:

```gdscript
return _dispatcher.dispatch(palette_id, start_position, speed)
```

But `ScrubbotDispatcher.dispatch()` is itself callback-rich: selection/access/routing/factory/agent seams can synchronously run arbitrary game code.

Adversary:
1. M20 activation passes its preflight;
2. inside an M19 dispatch callback, call `loop.reset()` only;
3. M20 records `_reset_requested` + advances its own generation, but defers heavy dispatcher reset because `_in_activation` is true;
4. M19's own generation has not changed, so M19 can complete and return SUCCESS;
5. M20 currently returns that SUCCESS;
6. only after `_in_activation` is cleared does `_drain_pending_reset()` cancel the assignment.

The caller can therefore receive a stale success result for an assignment that M20 immediately reset.

A second variant is M20-only coherence drift during the dispatch boundary, e.g. queue-free the optional renderer from an M19 callback. M19 does not know the renderer and can succeed, while M20 currently has no post-dispatch coherence barrier before returning.

Required order:
1. capture dispatcher result;
2. M20 reset/generation check;
3. if reset moved -> return RESETTING and let the deferred reset clean safely;
4. re-check complete M20 live coherence;
5. if M20 coherence was lost -> request deterministic reset/cleanup and return COHERENCE_FAILED (never expose the stale success);
6. only otherwise return the captured dispatcher result.

A consumed monotonic owner id is acceptable if reset occurred after M19 already allocated it; it must never be rewound or reused.

## F-M20-STRICT-006.K — reset can mutate foreign/replaced reservation ownership

**Status: OPEN / MINIMAL M19 RESET HARDENING REQUIRED**

M20 `reset()` eventually calls `ScrubbotDispatcher.reset()` even if ReservationState drifted after bind.

Current M19 reset loops active owner IDs and calls:

```gdscript
_reservations.release_for_owner(owner_id)
```

Because dispatcher stores the ReservationState object identity, the same object can be destructively `rebind()`ed after dispatch to another board, or reset/repopulated with a different target for the same owner token.

Concrete attack:
1. dispatch owner O to target T on board A;
2. rebind the shared exact ReservationState to same-size board B;
3. reserve a B target for numeric owner O;
4. call `loop.reset()`;
5. current dispatcher reset calls `release_for_owner(O)` and deletes the foreign B reservation.

Same-board replacement is also unsafe: if O now owns V instead of the dispatcher's immutable T, owner-keyed cleanup can delete V.

Required narrow cleanup law in dispatcher reset:
- never `release_for_owner` merely because an active dispatcher entry has the same owner token;
- release reservation only when ReservationState is still truthfully bound to the dispatcher's original board AND the exact immutable entry target<->owner pair is still present;
- use exact `release(entry_target, owner)` after that proof;
- if reservation coherence/pair proof fails, skip reservation mutation but still disconnect/cancel/free the dispatcher's own agent and clear its own `_active` bookkeeping;
- normal coherent reset must still release the exact reservation;
- foreign/replacement reservations must survive.

This is a minimal upstream M19 reset hardening discovered at the M20 boundary. Do not alter M19 selection/routing/identity semantics.

## F-M20-STRICT-001.K / 006.K — invalid dispatcher during reset

If the dispatcher Node is already invalid, M20 reset must not call methods on it. If it is merely queued for deletion but still valid, cleanup may use it while valid, but the bundle must remain fail-closed for future activation/coherence.

V04 must define and test deterministic local cleanup without claiming impossible recovery from an externally-destroyed dependency.

# Attack-surface classes checked

Checked conceptually against current V03:
- bind null/scalar/wrong-category boundaries;
- exact category and same-bundle identity;
- Node freed/queued lifecycle;
- dependency drift after bind;
- slot invalid/range/nonfinite activation inputs;
- activation re-entry;
- reset before/during activation;
- downstream callback reset/coherence drift during dispatch;
- arrival owner/target/color/agent authentication;
- duplicate current/queued arrival;
- exact reservation snapshot and rollback;
- partial failure after BoardState/candidate/reservation mutation;
- reset during arrival;
- stale queue/current state;
- reservation rebind/reset/replacement before recovery reset;
- renderer optional/present/lost lifecycle;
- 1x1, rectangular, 59x59 and rapid cycles;
- one/five assignment ownership;
- queue_free destruction smoke;
- scope boundaries (no win/lose/scoring/session/M21 logic).

No additional material defect was found in:
- exact owner-map postcondition/rollback logic;
- current-arrival owner+agent dedup;
- BoardState->candidate->reservation->dispatcher->renderer ordering;
- renderer-after-finalize law;
- real 1x1 and AL-028 second-activation path;
- five-assignment identity behavior;
- successful-clear candidate/reservation integration.

# Frozen V04 finding set

No new top-level finding IDs are created.

- F-M20-STRICT-001.K — Node liveness + queued-deletion trust boundary, plus stale exact-category source prose.
- F-M20-STRICT-002.K — post-dispatch M20 generation/coherence barrier; no stale SUCCESS after reset/drift inside M19 dispatch.
- F-M20-STRICT-006.K — reset must not release foreign/replaced ReservationState ownership; invalid dispatcher reset must not fault.

All other V03 correction areas are accepted and become regression locks.

## V03 verdict

**CHANGES_REQUIRED / SAME_FROZEN_SET / V04_REQUIRED**

V04 is a correction pass, not validation-only. Because V04 will touch production, a clean V04 source audit will still require a subsequent auditor-authored validation-only V05 before final M20 task closure.

Do not start M21.
