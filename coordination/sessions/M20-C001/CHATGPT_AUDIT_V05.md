# M20-C001 — ChatGPT Independent Audit V05

Decision: **VALIDATION_EXPOSED_PRODUCTION_DEFECT / V06_CORRECTION_REQUIRED**

Validation commit:
`d50a4546e425c2327347748e6a92d7356b4ec5e2`

Tracker start-transition commit:
`c79825a26fa5f4fef888a889a1bc55d99577b624`

Accepted V04 production blobs remain unchanged:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `f00c34021da85e596df58f08857acde8846dd8a4`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V05.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V05.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V05.md`

Prior audit:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_V04.md`

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb`, fresh root suite **3640 / 3640 ALL PASS**, queue-free smoke PASS, V04 lifecycle smoke PASS, and the new V05 lifecycle smoke FAIL exactly on the truly-freed optional-renderer assertions.

Those runtime observations are E1/E2. ChatGPT cannot independently run Godot here. ChatGPT independently inspected the exact V05 validation commit, production blob immutability, the V05 lifecycle smoke, current V04 production source, root TASKS lifecycle, and the surrounding optional-renderer attack surface.

## Validation governance — PASS

V05 correctly behaved as a validation-only gate:
- root TASKS start transition was pushed before validation edits;
- no committed `scripts/**` change exists in V05;
- accepted V04 production blobs remain byte-for-byte unchanged;
- Claude stopped with `V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT` instead of silently fixing production;
- root TASKS is `BLOCKED / CHATGPT`;
- progress remains 290/719 main+ui and 290/943 overall;
- no SB-M20 row is closed.

This is the required behavior when an auditor-authored validation gate discovers a real production defect.

## New runtime fact

Godot 4.7 runtime evidence establishes the following combination for a truly-freed Object reference:
- `is_instance_valid(freed) == false`;
- `freed == null` is true;
- `freed != null` is false;
- `typeof(freed) == TYPE_OBJECT` remains true.

This runtime fact was not available during the V04 source-only audit and therefore qualifies under the frozen-sweep policy as a legitimate new finding rather than correction whack-a-mole.

## Finding F-M20-STRICT-001.L — optional renderer presence is encoded with `!= null`

**OPEN / MATERIAL**

V04 correctly added live-node checks, but optional renderer presence is still decided by value equality:

```gdscript
if renderer != null:
    ... liveness / exact-script check ...
```

and live coherence likewise uses:

```gdscript
if renderer != null:
    ... renderer coherence ...
```

A truly-freed renderer compares equal to null, so these branches are skipped. The dead configured dependency is silently reinterpreted as the intentional headless/no-renderer mode.

Fresh V05 frame-aware evidence directly shows:
- truly-freed renderer passed to bind -> V04 bind returns true instead of rejecting it;
- renderer healthy at bind then destroyed across frames -> V04 `is_coherent()` stays true;
- activation still succeeds after the configured renderer has died;
- dispatcher equivalent cases correctly fail closed because dispatcher is mandatory and checked unconditionally.

This violates the V04/V05 lifecycle contract and AL-066-style configured-dependency semantics: an invalidated explicit dependency must not silently become the default/absent mode.

## Correct semantic distinction

M20 has two legitimate renderer states:

1. **Headless / no renderer configured**
   - caller supplies actual null / omits the optional argument;
   - renderer is not part of bundle coherence;
   - clear transaction remains valid without presentation.

2. **Renderer configured**
   - caller supplied an Object renderer at bind;
   - that fact must remain immutable bundle metadata;
   - queued/freed/wrong/coherence-lost renderer makes the bundle incoherent;
   - it must never degrade to headless merely because Godot's freed-object equality says `== null`.

The robust fix is to capture explicit renderer presence at bind independently of `Object == null` equality. `typeof(renderer) != TYPE_NIL` is capable of distinguishing the observed truly-freed Object from an actual null at the incoming Variant boundary. Persist a private boolean such as `_renderer_expected` / `_renderer_configured` after successful bind and use that boolean for live coherence and renderer-dependent transaction helpers.

## Before-bind truly-freed renderer is fixable

V05 log suggested this case might be unsatisfiable. It is not unsatisfiable under the observed runtime semantics because the same evidence says `typeof(freed) == TYPE_OBJECT` while true null is `TYPE_NIL`.

Therefore V06 should preserve the stronger contract:
- actual null -> intentional headless accepted;
- truly-freed renderer Object -> explicit supplied dependency, rejected fail-closed;
- queued live renderer -> rejected fail-closed;
- healthy exact renderer -> accepted.

Do not relax the criterion to treat a truly-freed supplied renderer as headless.

## Full residual attack-surface sweep

The new runtime fact was swept across the M20 renderer surface.

### Bind
- actual null / omitted renderer must remain accepted;
- scalar/wrong-object/wrong-script rejected;
- queued exact renderer rejected;
- truly-freed exact renderer rejected without SCRIPT ERROR;
- successful renderer bind persists renderer-presence metadata.

### Live coherence / activation
- headless bundle remains coherent without renderer;
- configured healthy renderer remains coherent;
- configured queued renderer -> incoherent;
- configured truly-freed renderer -> incoherent;
- activation against dead configured renderer fails closed before dispatch;
- dead configured renderer cannot be reclassified as headless.

### Arrival / transaction
- renderer remains presentation-only and post-finalize;
- no renderer remains valid;
- healthy renderer successful clear still repaints target alpha 0;
- a dead configured renderer before arrival preflight makes arrival reject rather than clearing under a falsely-headless interpretation;
- rollback opacity/source-pixel checks remain intact for a live renderer.

### Reset
- reset remains safe when configured renderer has died;
- reset does not mutate BoardState/candidate/reservation merely to compensate for renderer death;
- local queue/current bookkeeping remains deterministic.

### Test-only harness
- any direct test harness that bypasses `bind()` must set the private renderer-presence metadata consistently when it injects a renderer, otherwise renderer-related fault tests can become false positives.

No additional material M20 defect was found in the V05 source/test sweep.

## V04 correction status after V05

- F-M20-STRICT-001.K Node liveness — accepted except new `.L` optional-presence alias defect;
- F-M20-STRICT-002.K post-dispatch barrier — fresh V05 validation PASS;
- F-M20-STRICT-006.K pair-narrow reset — fresh V05 validation PASS;
- V03 exact owner-map rollback — fresh validation preserved;
- current-arrival dedup/FIFO/reset — fresh validation preserved;
- direct gameplay 1x1, AL-028 second-B, five-slot identity, 59x59, rectangular, rapid-cycle tests — fresh validation PASS.

The three V05 temporary sensitivity mutations were correctly NOT run after a production defect was exposed. The prompt required STOP on a discovered production defect.

## Next cycle

Issue **M20-C001 V06 production correction** with production scope limited to:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` only.

Do not modify `scrubbot_dispatcher.gd` in V06.

V06 must close F-M20-STRICT-001.L, make the V05 lifecycle smoke pass, preserve all accepted V04 behavior, and run the complete regression set.

Because V06 changes production, a clean V06 source audit will still require a final **V07 validation-only** pass before M20 task closure.

## Verdict

**VALIDATION_EXPOSED_PRODUCTION_DEFECT / V06_CORRECTION_REQUIRED**

Do not close SB-M20-001..014. Do not begin M21.
