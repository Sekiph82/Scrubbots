# M19-C001 — ChatGPT Independent Audit V03

Decision: **CHANGES_REQUIRED / UPSTREAM_M15_GATE + M19_REMAINDER_FROZEN**

Audited implementation commit:
`c30b802595983cf1b76865ca7c70ecaa895d62e3`

H!veAI start-transition commit:
`3e0b2a48947713e9670efeed08bf72efe1bc97b6`

Prompt:
`coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md`

Criteria:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

Claude evidence:
`coordination/sessions/M19-C001/CLAUDE_LOG_V03.md`

Prior audit:
`coordination/sessions/M19-C001/CHATGPT_AUDIT_V02.md`

## Runtime / independence

Claude reports Godot 4.7.1 and **2892 / 2892 ALL PASS**, with zero SCRIPT ERROR / Parse Error lines and clean `git diff --check`.

Those runtime results are E1/E2 because Godot is unavailable in the ChatGPT audit environment.

ChatGPT independently inspected the exact V03 implementation commit, production dispatcher, V03 test/support doubles, current M15-M18 dependencies, H!veAI v3 start/final transitions, and the complete V03 attack surface described below. This is E3 source/diff/adversarial-test evidence.

## H!veAI v3 lifecycle — PASS with one human-text drift to repair next cycle

The canonical machine state and Current/Active handoff are correct:
- CHANGES_REQUIRED -> IN_PROGRESS was separately pushed before implementation;
- final state is AWAITING_AUDIT;
- requiredActor is CHATGPT;
- progress remains 278/719 = 38.66%;
- lastCompletedTaskId remains FOUNDATION-C001-V01;
- matching start/final `hiveai-event/v1` rows exist;
- Claude did not claim COMPLETE / READY_FOR_NEXT_TASK.

Minor tracker-text drift: the `Milestones` paragraph still says M19 V02 is awaiting Claude implementation. The machine block and Current/Active sections are authoritative and correct, so this is not the production blocker, but the next canonical tracker update must remove the stale sentence so `.hiveai/TASKS.md` is internally coherent.

## V03 corrections accepted

The following V03 work is source-accepted and must be preserved:

### F-M19-STRICT-001.A/B
- select_access now requires `is_targetable` + `is_coherent_with`;
- missing/non-bool/false coherence fails bind;
- selector/reservation/routing/routing-access/select-access collaborators are narrowed to RefCounted + narrow API;
- method-compatible Node collaborators are rejected;
- agent_parent remains the intentional Node lifecycle dependency.

### F-M19-STRICT-002.A/B/C
- null cached route is distinguished from a present invalid cache;
- present invalid cache returns ROUTE_FAILED with no fresh routing fallback;
- explicit factory invalidation no longer silently falls back to default;
- assign postconditions validate valid/unparented/MOVING/exact owner/color/target.

### F-M19-STRICT-003.A/B partial closure
- `_in_dispatch` is armed before the first live coherence callback;
- reset generation is captured before that callback;
- reset during initial coherence is detected;
- reset after set_origin is detected before selection;
- reset after consume_route is detected before fresh routing;
- recursive dispatch from initial coherence seams is rejected.

### F-M19-STRICT-004
**CLOSED.** Preserve finite request validation regression.

## Remaining M19 strict-v2 findings

No new top-level M19 finding IDs are created. Remaining defects stay under F-M19-STRICT-001..003.

### F-M19-STRICT-003.D — generation is still not checked after every callback boundary

The V03 source still calls external/overridable code without an immediate reset-generation check in several later phases.

Most importantly, the post-phase calls to `_bundle_coherent()` occur after:
- selection;
- routing;
- factory;
- assign.

`_bundle_coherent()` itself invokes injected collaborator methods. If one of those callbacks calls `reset()`, generation changes, but the dispatcher currently tests only the returned coherence boolean and may begin the next external phase before noticing reset.

Examples:
- reset during post-selection coherence can allow routing to start;
- reset during post-routing coherence can allow factory execution;
- reset during post-factory coherence can allow `agent.assign()`;
- reset during post-assign coherence can allow `add_child()`.

The same class exists inside `_route_ok()`: `RouteValidator.validate_route()` calls injected routing-access methods. A routing-access callback can call reset during route validation, but generation is not checked immediately after `_route_ok()`.

Required after M15 gate closes:
- generation check immediately after every `_bundle_coherent()` call;
- generation check immediately after every `_route_ok()` / RouteValidator access pass;
- generation checks after any overridable agent-state helper that can execute subclass code;
- RESETTING must win over later route/factory/assign/attach side effects.

### F-M19-STRICT-003.E — reset itself is not re-entry guarded

`reset()` sets `_resetting = true` but does not return early when already resetting.

An accepted ScrubbotAgent subclass can override `cancel()`. If `cancel()` synchronously calls dispatcher.reset(), the nested reset can iterate the same `_active` entries again, call cancel again, and recurse/double-touch lifecycle state.

Required:
- repeated/reentrant reset while `_resetting` is true is a stable no-op;
- direct cancel-callback -> reset adversarial test;
- after `agent.cancel()` revalidate instance before parent/remove/free calls;
- no double free, no recursive reset storm, no orphan reservation, later dispatch recovers.

### F-M19-STRICT-001.D — fresh bind is still re-entrant during coherence validation

`bind()` is UNBOUND-only, but `_bound` is not set until after `_bundle_coherent()`.

A coherence callback during an outer fresh bind can call dispatcher.bind() again. The nested bind still sees `_bound == false` and can itself validate/commit before the outer bind resumes and overwrites the bundle.

Required:
- explicit bind-in-progress guard;
- nested bind from every coherence seam returns false;
- outer bind commits at most once;
- reset during bind invalidates the outer bind and leaves dispatcher unbound;
- revalidate agent_parent / explicit factory validity after coherence callbacks before commit;
- later clean bind recovers.

### F-M19-STRICT-001.E / F-M19-STRICT-002.D — selector return and reservation ownership are trusted

Current dispatch still effectively assumes `select_and_reserve()` returns a canonical int and that any nonnegative value means the target was really reserved by this dispatcher owner.

The dispatcher accepts a RefCounted selector by narrow API, so a compatible dependency can return malformed data or a positive target without creating the promised reservation.

Required after the upstream M15 gate:
- do not assign the raw selector result directly into a typed int before validating the Variant;
- require TYPE_INT;
- non-int return fails closed without runtime fault;
- before owner-id commit/routing, prove exact reservation truth in the dispatcher ReservationState:
  - owner -> selected target;
  - selected target -> same owner;
- positive target without exact reservation => COHERENCE_FAILED (or another existing stable dependency/coherence failure), no route/factory/agent;
- owner id must not be committed before ownership proof;
- verify rollback actually removed any pending reservation owned by this attempt.

### F-M19-STRICT-002.E — assign return itself should be actual bool

V03 validates postconditions after a truthy assign result, but the call result itself is not explicitly type-checked.

Because accepted agents may be subclasses, the external return contract should require actual TYPE_BOOL true before trusting success. If Godot override typing already prevents a non-bool return, record direct runtime evidence; otherwise reject non-bool fail-closed.

### F-M19-STRICT-001.F / F-M19-STRICT-003.F — add-child boundary lacks final coherence check

After `_agent_parent.add_child(agent)`, V03 checks reset generation but does not re-check bundle coherence before `_active` commit.

A synchronous `_ready` / tree callback can drift a collaborator without calling reset. The dispatcher can then commit an active assignment against an incoherent bundle.

Required:
- after add_child lifecycle callback, check generation and exact bundle coherence before signal connection / `_active` commit;
- drift => detach/free dispatcher-owned agent, release pending reservation, COHERENCE_FAILED;
- direct `_ready`-drift subclass if reproducible.

## Upstream blocker discovered: M15 TargetSelector

M19 cannot independently guarantee selector atomicity while current TargetSelector has an unclosed dynamic access/dependency boundary.

Current M15 source still:
- calls `_has_methods()` on arbitrary non-null Variants without a category/type guard;
- calls `access_query.has_method()` after null-only checking;
- trusts `candidate_index.is_bound_to()` / `reservation_state.is_bound_to()` truthiness;
- assigns `get_reserved_indices()` directly to PackedInt32Array;
- assigns `get_candidates()` directly to Array;
- iterates candidate entries without first requiring integer type;
- trusts `access_query.is_targetable()` truthiness;
- trusts reservation return values;
- does not protect one `select_and_reserve()` operation against selector/dependency rebind during an injected access callback.

A particularly important lifecycle sequence is:
1. selection starts on board/reservation A;
2. `access_query.is_targetable()` callback rebinds selector or ReservationState;
3. selection continues after the callback;
4. reserve may happen against the new dependency bundle;
5. M19 sees selector incoherence and rolls back through its original ReservationState;
6. the foreign reservation can be orphaned.

This is M15-owned selection atomicity, not routing/dispatcher policy.

Therefore M19 final closure is **BLOCKED on M15-C002**.

## V03 criterion disposition

The aggregate 2892/2892 run does not prove absent adversarial classes.

In particular V03 criterion 45 (`selector/bundle drift during callback detected where supported`) is not directly satisfied by a real TargetSelector rebind/ReservationState-rebind adversary. Existing V03 drift tests mutate access/routing coherence flags rather than the selector operation's own bound dependency identities.

## Frozen status

- F-M19-STRICT-001 — OPEN
- F-M19-STRICT-002 — OPEN
- F-M19-STRICT-003 — OPEN
- F-M19-STRICT-004 — CLOSED / regression-only

M19 tasks remain open:
- SB-M19-001..012

Progress remains unchanged:
- Main + UI: 278/719 = 38.66%
- Overall: 278/943 = 29.48%

## Verdict

**CHANGES_REQUIRED / UPSTREAM_M15_GATE + M19_REMAINDER_FROZEN**

Next executable cycle:
`M15-C002 V01`.

Do not issue/execute M19 V04 until M15-C002 independently closes. After that, ChatGPT will issue M19 V04 using this audit as the frozen M19 remainder basis.
