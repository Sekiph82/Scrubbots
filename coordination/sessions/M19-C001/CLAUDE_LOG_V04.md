# M19-C001 — CLAUDE_LOG_V04

Cycle: **M19-C001** · Prompt: `CHATGPT_PROMPT_V04.md` · Task: **M19-C001-V04**
Frozen remainder: **F-M19-STRICT-001.D/.E/.F, 002.D/.E, 003.D/.E/.F** (004 CLOSED/regression)
Actor: CLAUDE · Handoff: **AWAITING_AUDIT** (no self-audit verdict claimed)

## 1. Environment / sync

- Godot: **4.7.1.stable.official.a13da4feb**.
- Synced starting `origin/main` SHA: **2f12e9c4a2baef3a0116cfb615f05fc483c64ff1**
  (fast-forward; incoming M15 final audit + M19 V04 prompt/criteria did not touch
  any locally-modified file).
- Canonical state on sync matched the prompt (currentTaskId `M19-C001-V04`,
  workflowState `CHANGES_REQUIRED`, requiredActor `CLAUDE`, progress
  `278/719 = 38.66%`, lastCompletedTaskId `M15-C002-V03`) → no `HIVEAI_STATE_CONFLICT`.
- Pre-existing owner working-tree changes preserved and NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`.

## 2. H!veAI start ordering

Start transition pushed as a tracker-only commit **BEFORE the implementation
commit**: `.hiveai/TASKS.md` `CHANGES_REQUIRED → IN_PROGRESS` + `.hiveai/EVENTS.jsonl`
WORKFLOW_CHANGED row (id `31636f1f-07fe-4fcc-8313-bad729586152`), committed and
pushed as **aa8ebb9** (`2f12e9c..aa8ebb9`).

Disclosure (honest): in this session some dispatcher edits were authored locally
before the IN_PROGRESS push, but no implementation was committed or pushed before
the tracker-only IN_PROGRESS commit — the durable GitHub ordering is
start → implementation → handoff.

## 3. Frozen minimal correction (production, `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` only)

- **F-M19-STRICT-001.D — bind is a guarded transaction.** Added `_in_bind`.
  `bind()` returns false while already `_bound` (ordinary preserve) and while
  `_in_bind` (nested bind from a bind-time coherence callback). Validation +
  commit moved to `_bind_txn()` inside the guard; the reset generation is captured
  before the first `_bundle_coherent()` callback, and after the callbacks the bind
  fails closed if the generation moved (reset during bind → stay UNBOUND) and
  revalidates `agent_parent` liveness + explicit-factory validity before commit.
- **F-M19-STRICT-001.E / 002.D — selector Variant + exact reservation proof.**
  The pending owner id is proven unassigned (TYPE_INT `-1`) before selection; the
  selector return is captured UNTYPED and required TYPE_INT; canonical `-1` gives
  `NO_REACHABLE_TARGET` only when no owner reservation side effect exists (else
  `COHERENCE_FAILED` + exact `release_for_owner` cleanup); a negative int other
  than `-1` fails `COHERENCE_FAILED`; a positive target is accepted only after
  proving `get_target_for_owner(owner)==target` AND `get_owner(target)==owner`
  (both TYPE_INT) in the dispatcher's OWN ReservationState, with a
  generation + coherence check after EACH ownership-proof callback. The owner id
  advances only after that exact proof; failed proof cleans only this pending
  owner's reservation and never routes/creates a factory/agent.
- **F-M19-STRICT-003.D — generation wins after every callback boundary.** After
  every `_bundle_coherent()` (initial, post-selection, post-owner-proof×2,
  post-routing, post-factory, post-assign, post-add) and every `_route_ok()`
  (cached + fresh, which run RouteValidator routing-access callbacks), and after
  the overridable `_dispatcher_ownable()` / `_agent_assigned_ok()` state probes,
  the reset generation is tested FIRST — RESETTING wins over COHERENCE_FAILED and
  no later phase begins after a reset injected in the previous boundary.
- **F-M19-STRICT-003.E — reset re-entry safe.** `reset()` returns immediately when
  already `_resetting` (nested reset from a cancel() override is a no-op); the
  generation advances exactly once per outer reset, each committed agent is
  cancelled once, and `is_instance_valid(agent)` is re-checked after `agent.cancel()`
  before any get_parent/remove_child/free.
- **F-M19-STRICT-002.E — assign return actual bool.** `agent.assign(...)` return is
  captured untyped; only `typeof(result) == TYPE_BOOL and result == true` proceeds,
  otherwise `AGENT_ASSIGN_FAILED` with exact release + fresh-agent free.
- **F-M19-STRICT-001.F / 003.F — final add-child transaction.** After
  `add_child(agent)`: generation check → RESETTING (detach+free+release); exact
  bundle coherence check with generation re-check; incoherence-without-reset →
  COHERENCE_FAILED (detach+free+release); agent instance + expected-parent identity
  revalidated before signal connect and `_active` commit (new `_detach_free` helper).

All accepted V02/V03 hardening preserved (mandatory select-access coherence,
RefCounted categories, init-only ordinary bind, missing-vs-invalid cached route,
explicit-factory invalidation, factory-product ownership protection, assign
postconditions, set_origin/consume_route reset checks, completion identity, finite
request validation, no retarget, monotonic owner ids, M20 boundary locked).

## 4. Adversarial coverage added (validation-first, direct counters)

`tests/run_tests.gd` → `_run_m19_v04_tests()` (registered after
`_run_m19_strict_v3_tests`). New narrow M19 doubles:
- `tests/support/m19_selector_return_double.gd` — configurable Variant return +
  optional side-effect reservation in the real ReservationState.
- `tests/support/m19_reset_cancel_agent.gd` — cancel() → nested dispatcher.reset()
  (re-entry) with an external cancel counter.
- `tests/support/m19_nonbool_assign_agent.gd` — untyped assign() returning a non-bool.
- `tests/support/m19_coherence_reset_access.gd` — injects reset() from a chosen
  post-boundary bundle-coherence callback ordinal.
- `tests/support/m19_probe_agent.gd` — counts assign() calls (external Array).
- `tests/support/route_access_query_double.gd` — added `on_query` hook (fires in
  is_segment_traversable, not is_bound_to) for RouteValidator-access reset injection.

Direct coverage: bind nested-bind rejection + bundle-A identity win + reset-during-bind
(each of the 4 bind-time coherence seams); selector Variant matrix (null/float/String/
Vector2/RefCounted/bool/Array/Dictionary/negative/−1/−1-with-secret-reservation/
positive-no-reservation/owner→other-target/target→other-owner/exact-accepted) with
owner-id-not-advanced + no-route + no-active + exact cleanup + unrelated preserved;
generation-after-boundary resets at post-selection, cached-route validator access,
fresh-route validator access, post-routing (factory count 0), post-factory (assign
count 0), post-assign (add_child count 0), each proving the forbidden next phase did
not run; reset re-entry via cancel→reset (cancel count 1, no storm, monotonic ids,
recovery); assign bool-false and non-bool both → AGENT_ASSIGN_FAILED with release +
no child/active; prior committed assignment survives a later failed pending dispatch.

### Documented headless limitations (source-verified guards, not runtime-reproducible)

- **add_child _ready / child_entered_tree boundary (F-M19-STRICT-001.F/003.F):** in a
  `-s` SceneTree this callback is delivered DEFERRED, and injecting reset/free from it
  frees a locked (mid-callback) object → engine "locked object" errors. So the
  synchronous add-child adversary is not reproducible here without emitting engine
  errors (same limitation the V02 add-child test documents). The dispatcher's
  post-add generation + coherence + instance/parent revalidation guards are present
  and covered by source inspection; the error-free synchronous consequence (a
  committed assignment surviving a later failed dispatch) is asserted directly.
- **self-freeing cancel() (F-M19-STRICT-003.E "if reproducible"):** freeing the agent
  from inside its own cancel() is a Godot locked-free; not cleanly reproducible. The
  dispatcher's post-cancel `is_instance_valid(agent)` revalidation is source-verified;
  the re-entrant nested-reset case is exercised directly and error-free.

## 5. Validation results

- Full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
  → **Total checks: 3163 · Failures: 0 · RESULT: ALL PASS**
  (pre-V04 baseline 3024/0; +139 new V04 checks). All M13–M18 + M19 V02/V03 +
  M15-C002 regressions remain green with the dispatcher rewrite.
- Zero SCRIPT ERROR / Parse Error lines in the final run.
- `git diff --check`: clean (only benign LF→CRLF notices).
- Exit-time WARNINGs ("CanvasItem RID leaked", "ObjectDB instances leaked",
  "resources still in use at exit") are benign process-shutdown artifacts —
  RefCounted test doubles held in lambda-capture cycles, freed at exit — not runtime
  SCRIPT/Parse errors. The count rose vs earlier target-selector-only cycles because
  V04 adds Node/double-heavy dispatcher tests; the same artifact class pre-exists in
  the suite.
- Failed attempts corrected during development: an undeclared `_in_bind` (added to
  dispatcher state); coherence-reset ordinals were off by one because `bind()`
  consumes one `is_coherent_with` call (fixed by resetting the double's
  `coherence_calls` to 0 after wiring); the add-child `_ready`/self-free adversaries
  produced engine locked-free errors and were replaced with source-verified notes +
  error-free synchronous assertions.

## 6. Scope / governance

- Production changed: `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` only.
- Tests/support changed: `tests/run_tests.gd`,
  `tests/support/route_access_query_double.gd`, and the five new M19 doubles above.
- Not touched: BoardState, ColorCandidateIndex, ReservationState, TargetSelector,
  routing, ScrubbotAgent core production; root `tasks.md` checkboxes;
  `coordination/AUDIT_INDEX.md`; any `CHATGPT_*` artifact; legacy H!veAI trackers;
  `.hiveai/PROJECT.json`/`.hiveai/RULES.md`.
- M20 boundary preserved: no BoardState CLEARED on arrival, no arrival reservation
  resolution, no scoring, no slot progression, no auto follow-up dispatch.
- No self-audit verdict; audit disposition is ChatGPT-owned.

## 7. Commits / events

- Start transition: **aa8ebb9** (`CHANGES_REQUIRED -> IN_PROGRESS`), pushed
  `2f12e9c..aa8ebb9` before the implementation commit.
- Implementation + AWAITING_AUDIT handoff pushed after this log; see
  `.hiveai/EVENTS.jsonl` `IN_PROGRESS -> AWAITING_AUDIT` row
  (`6c407cb6-9062-4329-a40c-1fb9e6ea4e99`). Per the non-self-referential final-SHA
  rule no extra commit is made solely to embed this log's own commit SHA.

Handoff state: **AWAITING_AUDIT** (requiredActor CHATGPT).
