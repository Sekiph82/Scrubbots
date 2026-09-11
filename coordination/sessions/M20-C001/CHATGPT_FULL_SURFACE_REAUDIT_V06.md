# M20-C001 — Full-Surface Re-Audit Freeze V06

Status: **FINDING SET FROZEN / V06 CORRECTION AUTHORIZED**

Basis:
- `CHATGPT_AUDIT_V05.md`
- new runtime fact: a truly-freed Godot Object can compare `== null` while `typeof(...) == TYPE_OBJECT`;
- current V04 production blobs remain locked and unchanged through V05.

## Frozen finding set

No new top-level M20 finding IDs are created. V06 remains inside the existing F-M20-STRICT-001..007 set.

Open correction:
- **F-M20-STRICT-001.L** — optional renderer presence/liveness is encoded through `renderer != null`, so a truly-freed configured renderer aliases the intentional headless state and bypasses lifecycle coherence.

Accepted/regression-only:
- F-M20-STRICT-001 prior exact-category and mandatory-dispatcher liveness work;
- F-M20-STRICT-002 activation/post-dispatch barrier;
- F-M20-STRICT-003 authenticated arrival identity;
- F-M20-STRICT-004 exact cross-layer transaction / owner-map rollback;
- F-M20-STRICT-005 transactional reset;
- F-M20-STRICT-006 FIFO/current-arrival dedup + pair-narrow reset;
- F-M20-STRICT-007 direct integration/scale/state-desync coverage.

## Renderer state model frozen for V06

M20 must distinguish permanently between:

### HEADLESS
- renderer argument is actual Variant NIL at bind;
- no renderer dependency is configured;
- renderer is excluded from bundle coherence and repaint;
- clearing remains valid.

### CONFIGURED_RENDERER
- bind received a non-NIL Variant intended as renderer;
- it must be a live exact BoardRenderer at bind;
- successful bind persists private renderer-present metadata independent of later object equality;
- queued/freed/coherence-lost renderer makes the bundle incoherent;
- renderer death must never silently switch the loop into HEADLESS.

A truly-freed renderer before bind is non-NIL by `typeof` under the observed Godot 4.7 runtime fact and must therefore be rejected as an invalid explicit dependency.

## Required production shape

Use explicit private renderer-presence metadata, e.g. `_renderer_expected: bool`.

At bind:
- derive local presence from Variant type, not `renderer != null` equality;
- actual TYPE_NIL -> headless;
- non-NIL -> require live exact BoardRenderer;
- commit `_renderer_expected` only on successful bind.

At live coherence:
- if renderer was configured, require live renderer + exact board coherence;
- if headless, skip renderer checks;
- do not infer configured/headless state from current `_renderer == null` equality after bind.

At renderer helpers/presentation:
- use persisted configuration state where semantic distinction matters;
- never call a freed renderer;
- keep renderer presentation-only after dispatcher finalization;
- do not turn renderer death into BoardState/candidate/reservation rewrites.

Test-only direct harnesses that bypass production bind must set the private renderer-presence state consistently.

## Frozen attack matrix

V06 must cover:
- omitted renderer;
- explicit null renderer;
- scalar renderer input;
- arbitrary wrong Object;
- wrong-script live Node;
- queued exact renderer before bind;
- truly-freed exact renderer before bind;
- healthy exact renderer bind;
- renderer queued after bind;
- renderer truly freed after bind;
- dispatcher queued/freed regression;
- `is_coherent()` after renderer death;
- activation after renderer death;
- reset after renderer death;
- arrival attempt after renderer death before clear;
- headless successful clear;
- renderer successful clear/repaint;
- rollback renderer opacity;
- post-dispatch renderer-loss barrier;
- exact owner-map reservation preservation;
- pair-narrow reset foreign-board preservation;
- current-arrival dedup/FIFO/reset;
- 1x1 / AL-028 second-B / five-slot / 59x59 / rectangular / rapid-cycle regressions.

## Scope freeze

Authorized production:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` ONLY.

Read-only production:
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`;
- BoardState;
- BoardRenderer;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- routing/access;
- ScrubbotAgent.

If a broader production change is genuinely required, STOP `BLOCKED` and hand back to ChatGPT.

## Closure path

V06 is a production correction pass. Even if its source audit is clean, M20 remains open until an auditor-authored V07 validation-only pass proves the corrected production under runtime adversaries and sensitivity mutation.
