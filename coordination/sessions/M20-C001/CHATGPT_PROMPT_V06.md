# M20-C001 — Optional Renderer Lifecycle Correction V06

Status: **ISSUED — SAME FROZEN M20 SET / PRODUCTION CORRECTION**

Canonical live tracker: repository-root `TASKS.md` only.

Read FIRST:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V05.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V06.md`;
- this prompt;
- `CHATGPT_AUDIT_CRITERIA_V06.md`.

Expected evidence log:
`coordination/sessions/M20-C001/CLAUDE_LOG_V06.md`

Do not begin M21.

## 0. Root TASKS lifecycle

Expected synced starting state:
- M20-C001 V05;
- `BLOCKED`;
- Required Actor `CHATGPT`;
- blocker is `V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT` for truly-freed optional renderer;
- progress 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06;
- SB-M20-001..014 all open.

`CHATGPT_AUDIT_V05.md` + this prompt authorize V06.

Before ANY V06 production/test edit:
1. sync `origin/main`, preserving owner work;
2. verify V05 audit + V06 freeze/prompt/criteria exist;
3. verify root tracker has not moved to another task;
4. update ONLY top Project Status lifecycle fields to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V06 — optional renderer lifecycle correction
   - Current Task: M20-C001-V06 — preserve explicit renderer presence across freed-object null aliasing
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: implement V06, validate, write CLAUDE_LOG_V06.md, hand off AWAITING_AUDIT to ChatGPT
   - progress unchanged
   - lastCompletedTaskId unchanged
5. commit + push tracker-only transition BEFORE any V06 production/test edit;
6. verify remote main contains it.

If tracker moved: `TRACKER_STATE_CONFLICT`.
If push fails: `GITHUB_TRACKING_NOT_SYNCED`.

Do not mark any SB-M20 row complete.

## 1. Preserve V04/V05 accepted behavior

Do NOT redesign:
- exact production-script dependency boundary;
- mandatory dispatcher live-node checks;
- post-dispatch reset/generation barrier;
- post-dispatch full M20 coherence barrier;
- pair-narrow board-safe dispatcher reset;
- exact reservation owner-map transaction proof;
- current-arrival dedup + distinct FIFO;
- deferred transactional reset;
- clear order BoardState -> candidate -> reservation -> dispatcher finalize -> renderer;
- renderer presentation-only, post-finalize;
- no M21/win/lose/scoring/session/slot policy.

`scrubbot_dispatcher.gd` is READ-ONLY in V06.

## 2. Fix F-M20-STRICT-001.L: optional renderer presence must not use Object equality

The runtime fact from V05 is authoritative:
- a truly-freed Object can compare `== null`;
- `typeof(freed) == TYPE_OBJECT` remains true.

Therefore `renderer != null` / `_renderer != null` MUST NOT be the semantic authority for whether a renderer was configured.

### Required design

Add private immutable bundle metadata, e.g.:

```gdscript
var _renderer_expected: bool = false
```

At bind entry/transaction derive a local `renderer_expected` from Variant type:
- `typeof(renderer) == TYPE_NIL` => intentional headless / no renderer;
- any non-NIL Variant => explicit dependency was supplied and must pass the exact renderer category/lifecycle gate.

Do not use equality with null to decide this.

On successful bind only:
- commit `_renderer = renderer`;
- commit `_renderer_expected = renderer_expected`.

Failed bind must leave the loop fully unbound and must not leave renderer-present metadata committed.

### Bind law

When `renderer_expected == false`:
- null/omitted renderer is accepted if all other bundle checks pass;
- renderer is not part of bundle coherence.

When `renderer_expected == true`:
- scalar, wrong Object, wrong script, queued renderer, truly-freed renderer all fail bind cleanly;
- no SCRIPT ERROR;
- no arrival signal connection;
- loop remains unbound.

A truly-freed renderer before bind MUST be rejected, not treated as headless.

## 3. Live coherence must use persisted renderer-presence metadata

Change `_probe` / `is_coherent()` so it never decides renderer participation from current Object equality.

Required:
- headless bundle -> no renderer check;
- configured healthy renderer -> live + bound-to-exact-board required;
- configured queued renderer -> false;
- configured truly-freed renderer -> false without SCRIPT ERROR;
- configured renderer wrong/coherence-lost -> false;
- renderer death can never silently switch the bundle to headless.

Recommended shape:
- pass explicit `renderer_expected` into bind-time probe;
- after successful bind, `is_coherent()` uses `_renderer_expected`.

Do not infer `_renderer_expected` from `_renderer` after bind.

## 4. Renderer helpers / transaction semantics

Audit and correct every renderer-specific branch in `complete_clearing_loop.gd` that currently uses renderer null equality as semantic presence.

At minimum inspect:
- bind gate;
- `_probe`;
- successful post-finalize repaint;
- `_renderer_pixel` / rollback presentation proof.

Rules:
- actual headless bundle remains valid;
- configured dead renderer is never called;
- preflight must fail before BoardState mutation when configured renderer is already dead/incoherent;
- renderer remains presentation-only and never becomes rollback authority for canonical gameplay truth;
- no false-clear frame on rollback;
- healthy renderer success still updates exactly the target cell to CLEARED/alpha-0;
- no renderer success still clears normally.

If a configured renderer dies after successful bind but before arrival, authenticated arrival must not clear the BoardState under a falsely-headless interpretation.

## 5. Update test-only harness truth

`_m20_harness_bind` bypasses production `bind()` for deliberate rollback fault injection.

If V06 adds private renderer-presence metadata, update this harness so:
- harness with a renderer sets presence true;
- harness without renderer sets presence false;
- production `bind()` remains the only production entry point;
- support subclasses remain production-rejected.

Do not create a public setter/exposure for renderer presence.

## 6. Make the V05 lifecycle smoke pass

`tests/m20_v05_lifecycle_smoke.gd` is now a permanent regression artifact.

Required post-fix results:
- truly-freed renderer before bind -> bind false / unbound / no SCRIPT ERROR;
- healthy renderer bind -> success;
- renderer destroyed after bind -> `is_coherent()` false;
- activation after renderer destruction -> stable failure, no dispatch/clear;
- reset after renderer destruction -> safe;
- dispatcher before/after-bind destroyed cases remain green.

Also keep V04 lifecycle smoke green.

## 7. Add direct null-vs-dead distinction tests

Directly prove all of these are distinct:

A. renderer omitted -> healthy headless bind succeeds.

B. explicit `null` renderer -> same legitimate headless semantics.

C. wrong scalar renderer -> rejected.

D. arbitrary RefCounted / wrong Node -> rejected.

E. queued exact renderer -> rejected.

F. truly-freed exact renderer -> rejected despite `renderer == null` being true at runtime.

G. healthy exact renderer -> accepted and renderer-present metadata remains true.

Do not expose private state through a new public getter merely for testing. Observe behavior through bind/coherence/repaint.

## 8. Preserve V05 validation matrix

Keep the fresh V05 auditor validation block enabled and green after correction:
- queued dispatcher/renderer lifecycle;
- post-dispatch reset barrier;
- post-dispatch renderer-coherence barrier;
- pair-narrow reset A-F with exact unrelated reservation identity;
- duplicate current arrival;
- distinct FIFO;
- reset candidate/reservation phases;
- identity-swap -> ROLLBACK_FAILED;
- unrelated candidate preservation;
- failed-preflight reset recovery;
- stale replay rejection;
- real 1x1;
- AL-028 second real B dispatch/clear;
- five unique owners/targets/exact reservation pairs;
- 59x59;
- rectangular;
- rapid >=25 cycles.

## 9. Sensitivity for THIS fix

After the corrected tests are green, perform at least one temporary production sensitivity mutation, then restore before final run.

Preferred mutation:
- make configured-renderer coherence once again depend on `_renderer != null` / equality instead of the persisted presence bit.

Expected:
- V05 truly-freed-renderer smoke fails on after-bind renderer destruction;
- at least one direct null-vs-dead V06 test fails for the intended reason.

Restore byte-for-byte before final validation and record pre/post production blob hashes.

Do not commit the mutation.

## 10. Production scope

Authorized production:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` ONLY.

READ-ONLY production:
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`;
- BoardState;
- BoardRenderer;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- routing/access;
- ScrubbotAgent.

Allowed tests:
- `tests/run_tests.gd`;
- `tests/m20_v05_lifecycle_smoke.gd`;
- existing M20 smokes/support;
- narrow new M20 V06 support/test file if genuinely useful.

Allowed docs:
- M20 architecture clarification;
- `CLAUDE_LOG_V06.md`;
- root TASKS lifecycle fields.

If any broader production change is required, STOP `BLOCKED`.

Claude MUST NOT edit CHATGPT_* artifacts, AUDIT_INDEX, or SB-M20 completion rows.

## 11. Full validation

Record individually:
- `godot --version`;
- V05 lifecycle smoke after fix;
- V04 lifecycle smoke;
- queue-free smoke;
- direct headless/null/wrong/dead/healthy renderer cases;
- V06 sensitivity mutation failure and restoration;
- full root `tests/run_tests.gd` exact total;
- zero final M20 SCRIPT ERROR / Parse Error;
- `git diff --check`;
- exact changed files;
- final production blob hash;
- root TASKS before/start/final;
- any failed attempts/fixes.

## 12. Final handoff

On successful V06 correction/testing:
- root TASKS current sprint/task -> M20-C001 V06 / M20-C001-V06;
- status -> AWAITING_AUDIT;
- Required Actor -> CHATGPT;
- progress remains 290/719 main+ui and 290/943 overall;
- lastCompletedTaskId remains M19-C001-V06;
- no SB-M20 checkbox `[x]`;
- push correction + tests + log + tracker handoff;
- verify remote main.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

A clean V06 source audit is NOT final M20 closure because production changes in V06. ChatGPT will issue an auditor-authored V07 validation-only gate.

Return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Broader-scope blocker:
`BLOCKED`

Then stop.
