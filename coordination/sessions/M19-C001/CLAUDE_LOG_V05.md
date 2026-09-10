# M19-C001 — CLAUDE_LOG_V05

Cycle: **M19-C001** · Prompt: `CHATGPT_PROMPT_V05.md` · Task: **M19-C001-V05**
Frozen remainder: **F-M19-STRICT-001.G, 003.G/.H/.I + 002 evidence** (004 CLOSED)
Actor: CLAUDE · Handoff: **AWAITING_AUDIT** (no self-audit verdict claimed)

## 0. H!veAI start ordering (hard gate)

**No V05 production or test edit existed before the successful IN_PROGRESS push.**
Sequence this cycle:
1. synced `origin/main` to **9c14e5ad31ed433e2692c5893a1230afc70d114d** (fast-forward,
   owner work preserved); canonical state matched the prompt (currentTaskId
   `M19-C001-V05`, workflowState `CHANGES_REQUIRED`, requiredActor `CLAUDE`,
   progress `278/719 = 38.66%`, lastCompletedTaskId `M15-C002-V03`) → no
   `HIVEAI_STATE_CONFLICT`;
2. updated `.hiveai/TASKS.md` → `IN_PROGRESS` + appended `hiveai-event/v1`
   (id `4a8f7c95-2e84-4933-9661-f9e95d3bbf9a`);
3. committed tracker/event only and pushed as **1566402** (`9c14e5a..1566402`);
4. verified remote `origin/main` HEAD == `1566402` (contains the start transition);
5. ONLY THEN edited `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` and tests.

This corrects the V02/V04 local-ordering nonconformance: local edit ordering
complied, not merely durable commit ordering.

- Godot: **4.7.1.stable.official.a13da4feb**.
- Pre-existing owner working-tree changes preserved and NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`.

## 1. Frozen correction (production, `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` only)

- **F-M19-STRICT-001.G / 003.H — pending-owner baseline bracketed.** Before the
  selector phase: capture `get_target_for_owner(owner_id)` untyped → generation
  check → TYPE_INT → exact `_bundle_coherent` → generation check → require value
  `== -1`. A baseline callback that resets → RESETTING; that drifts the bundle or
  returns non-int/non-`-1` → COHERENCE_FAILED; the selector is NEVER called on any
  of these paths.
- **F-M19-STRICT-003.G — canonical `-1` side-effect query bracketed.** After a
  selector `-1`: capture `get_target_for_owner(owner_id)` untyped → generation
  FIRST → TYPE_INT → `_bundle_coherent` → generation again → only then interpret.
  reset → RESETTING; drift/malformed → COHERENCE_FAILED; secret non-`-1` owner
  target → COHERENCE_FAILED; all with narrow `release_for_owner` cleanup and no
  route/factory/agent. Coherent actual `-1` → NO_REACHABLE_TARGET.
- **F-M19-STRICT-003.I — generation beats helper verdicts.** `_dispatcher_ownable`
  and `_agent_assigned_ok` now store the verdict, then check generation FIRST
  (RESETTING + rollback wins), and only then interpret a false verdict as
  AGENT_ASSIGN_FAILED. New `_dispose_fresh(agent)` disposes only a valid unparented
  ScrubbotAgent (our fresh product, even one whose get_state() lies) on the
  ownability-reset path, never a foreign parented/reused object.

All accepted V04 hardening preserved (bind `_in_bind` transaction + reset-during-bind,
selector Variant matrix + exact owner↔target proof before owner-id advance, route
validation generation checks, post-selection/routing/factory/assign/add coherence
generation checks, reset re-entry no-op + post-cancel instance revalidation, assign
actual-bool gate, add_child post-guards, invalid-cached-route no-fresh-route,
explicit-factory-invalidation no fallback, no retarget). M15/BoardState/
ColorCandidateIndex/ReservationState/routing/ScrubbotAgent production untouched.
M20 boundary locked.

## 2. Adversarial coverage added (`_run_m19_v05_tests`, direct counters)

New narrow doubles:
- `tests/support/m19_reservation_proof_double.gd` — full ReservationState-compatible
  double with per-call FORCE overrides + `on_owner_query`/`on_get_owner` hooks for
  malformed-return / reset / drift injection at exact ownership-callback ordinals.
- `tests/support/m19_reset_state_agent.gd` — ScrubbotAgent subclass whose
  overridable `get_state()` resets on a chosen call ordinal and can return an
  overriding state (drives the ownability and postcondition reset-precedence cases).
Reused `m19_selector_return_double` (now via `_v05_wire_proof`).

Direct cases (all asserted with counters / post-state):
- baseline: malformed → COHERENCE_FAILED + selector-calls 0 + owner-id not advanced;
  non-`-1` owner already assigned → COHERENCE_FAILED + selector-calls 0; reset →
  RESETTING + selector-calls 0; bundle drift → COHERENCE_FAILED + selector-calls 0.
- canonical `-1`: control → NO_REACHABLE_TARGET (owner id unchanged); reset during
  post-`-1` query → RESETTING; drift → COHERENCE_FAILED; malformed → COHERENCE_FAILED;
  secret owner reservation → COHERENCE_FAILED + narrow cleanup with unrelated (99,777)
  preserved.
- malformed positive proof: malformed `get_target_for_owner` and malformed `get_owner`
  → COHERENCE_FAILED, no routing (call_count 0), owner id not advanced, pending
  reservation cleaned, unrelated (99,777) preserved (post-state observed directly).
- generation precedence: reset from `_dispatcher_ownable` get_state (returns
  non-UNASSIGNED) → RESETTING (not AGENT_ASSIGN_FAILED), no active, reservation
  released, later dispatch recovers, owner ids monotonic; reset from
  `_agent_assigned_ok` get_state (verdict false) → RESETTING, add_child not reached
  (child count unchanged), no active, reservation released, later recovers.
- real M15-C002 V03 integration: real TargetSelector + real ReservationState + real
  ColorCandidateIndex; `access_query.is_targetable()` attempts
  `selector.bind(bundle B)` during selection → M15 final law keeps the selector on
  bundle A (`is_bound_to(A)` true), no foreign reservation orphaned in B, dispatcher
  commits exact ownership only in A (or leaves none), later coherent dispatch usable.

## 3. Sensitivity proofs (§7, temporary mutations recorded + restored)

Backed up the dispatcher, applied each mutation, ran the suite, then restored:
- **Mutation A** — interpret the `_dispatcher_ownable` verdict BEFORE the generation
  check: `003.I: reset in _dispatcher_ownable get_state -> RESETTING` FAILED
  (returned AGENT_ASSIGN_FAILED). Restored.
- **Mutation B** — remove the `_bundle_coherent` recheck after the pending-owner
  baseline callback: **3 failures** in the baseline-drift/observability class.
  Restored.
Both confirm the corrected orderings are genuinely load-bearing. After restore the
full suite is green again.

## 4. Validation results

- Full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
  → **Total checks: 3203 · Failures: 0 · RESULT: ALL PASS**
  (pre-V05 baseline 3163/0; +40 new V05 checks). M13–M18, M15-C002, M19 V01–V04
  regressions all green.
- Zero SCRIPT ERROR / Parse Error lines in the final run.
- `git diff --check`: clean (only benign LF→CRLF notices).
- Exit-time WARNINGs (CanvasItem RID / ObjectDB leaked / resources still in use)
  are benign process-shutdown artifacts (RefCounted test-double lambda-capture
  cycles freed at exit), not runtime SCRIPT/Parse errors — unchanged in character
  from prior M19 cycles.

## 5. Scope / governance

- Production changed: `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` only.
- Tests/support changed: `tests/run_tests.gd` + the two new M19 doubles above.
- Not touched: BoardState, ColorCandidateIndex, ReservationState, TargetSelector,
  routing, ScrubbotAgent core; root `tasks.md` checkboxes; `coordination/AUDIT_INDEX.md`;
  any `CHATGPT_*` artifact; legacy H!veAI trackers; `.hiveai/PROJECT.json`/`.hiveai/RULES.md`.
- No self-audit verdict; audit disposition is ChatGPT-owned.

## 6. Commits / events

- Start transition: **1566402** (`CHANGES_REQUIRED -> IN_PROGRESS`), pushed
  `9c14e5a..1566402` and verified on remote main BEFORE any production/test edit.
- Implementation + AWAITING_AUDIT handoff pushed after this log; see
  `.hiveai/EVENTS.jsonl` `IN_PROGRESS -> AWAITING_AUDIT` row
  (`a626a773-7b1c-44c8-96af-01b10ed35ba5`). Per the non-self-referential final-SHA
  rule no extra commit is made solely to embed this log's own commit SHA.

Handoff state: **AWAITING_AUDIT** (requiredActor CHATGPT).
