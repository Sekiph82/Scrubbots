# M25-C003 — EXACT-SAFE TARGET PREFILTER + LAID-OUT 59x59 HARNESS — IMPLEMENTATION PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M25-034`
Status: READY FOR CLAUDE

Investigation:
`coordination/sessions/M25-C002/M25_59X59_TARGET_SELECTION_FINDINGS_V01.md`

Independent audit:
`coordination/sessions/M25-C002/CHATGPT_AUDIT_V01.md`

Blocking parent:
`SB-M29-010 — Gameplay Tempo Retune`

Do not edit root `TASKS.md`.

## Mission

Implement ONLY the accepted S0 + S1 stages from the audited investigation.

### S0
Correct the 59x59 performance harness so it uses real laid-out production slot geometry and proves every slot origin used for performance evidence is outside/below the board.

### S1
Reduce the real-layout WHAT-side candidate-scan cost without changing target truth:

1. materialize the existing exact-safe M52 reachability necessary condition as an O(1) per-revision touchability mask in `ProductionTargetAccess`;
2. allow `TargetSelector` to consult an OPTIONAL conservative prefilter capability **before** its expensive strict per-candidate body;
3. skip only candidates the authoritative access layer proves cannot possibly be targetable;
4. preserve exact bottom-most/left-most canonical winner and all transaction truth.

Do NOT implement S2 routing/Dijkstra optimization in this cycle.

Do NOT add the optional shipping inside-board-origin guard D2 in this cycle.

## Architecture lock

`TargetSelector` still owns WHAT.

`ProductionTargetAccess` / routing still own reachability/HOW.

TargetSelector must NOT:
- inspect rail geometry;
- inspect CLEARED connectivity itself;
- compute masks itself;
- import routing policy into target ordering;
- choose nearest/cheaper targets.

The selector may only consume an opaque, conservative necessary-condition answer from the same access-query abstraction it already trusts for `is_targetable()`.

## Preferred optional capability

Implement a narrow optional access capability with semantics equivalent to:

`prefilter_maybe_targetable(index) -> Variant`

Contract:

- returns `false`: candidate is mathematically guaranteed NOT targetable for the current access state; selector may skip it before strict per-candidate collaborator work;
- returns `true`: candidate MAY be targetable; selector must continue through the existing full strict path, including `is_targetable()`;
- returns `null` / unsupported / malformed: selector MUST use the existing full strict path with no filtering.

The exact method name may differ if a cleaner API is chosen.

This capability is only a necessary-condition accelerator. It is NEVER a success verdict.

A `true` prefilter result must never cause selection without the existing authoritative `is_targetable()` call.

## S1-A — materialized touch mask

Current `ProductionTargetAccess._could_reach(index)` computes the exact-safe necessary condition:

- perimeter cell => possible;
- interior cell 4-adjacent to perimeter-connected CLEARED mask => possible;
- otherwise impossible;
- inside-board origin => prefilter deliberately unsupported, use current interior/debug path.

Materialize this condition as a `PackedByteArray` (or equally compact O(1) structure) next to the existing reach mask.

Requirements:

- keyed by exact BoardState instance id + monotonic revision;
- shared across access instances for the same board/revision as appropriate;
- rebuild on revision change;
- never reuse across another board instance;
- restore/retry revision invalidates it;
- outside-origin lookup after build is O(1);
- inside-board origin returns unsupported/no-filter, preserving current behavior;
- invalid/malformed origin returns unsupported/no-filter or existing fail-closed path, never an unsafe false negative;
- no per-candidate temporary 4-element Vector2i array allocation after materialization.

The materialized mask must be differential-tested against the current necessary-condition semantics before/while refactoring.

## S1-B — selector early conservative filter

The current selector performs expensive strict work before `access_query.is_targetable()`.

Move only the **provably-impossible** rejection ahead of that strict body through the optional access capability.

Required loop semantics:

1. candidates remain in exact canonical bottom-most -> left-most -> index order;
2. for each candidate, ask optional conservative prefilter;
3. if strict bool `false`, skip it immediately;
4. if strict bool `true` or capability unavailable/malformed, execute the CURRENT strict body unchanged;
5. the first candidate whose existing authoritative `is_targetable()` path succeeds is still the winner;
6. reservation remains the same atomic last gate.

Do not remove or weaken:
- board validity/state/color validation for candidates that reach the strict path;
- reservation ownership checks;
- `_op_coherent` checks;
- malformed collaborator handling;
- re-entrancy guards;
- exact rollback;
- ownership proof.

### Capability safety

Do not trust arbitrary malformed filter data.

At minimum:
- access object remains a RefCounted authoritative query;
- optional capability return must be exactly TYPE_BOOL to be actionable;
- unsupported/missing/malformed => full old path;
- board/access coherence must still be preserved;
- any board revision/identity mismatch inside the canonical access must make the capability unsupported or rebuild against current truth.

Existing adversarial/double access objects that do not implement the capability must exercise the exact old selector loop.

## S0 — fix the 59x59 performance harness

The old M29-C002 s8 helper constructed fixture hosts unlaid on the headless root.

For dense/full-host performance evidence, use real layout like:

- a sized `SubViewport` (1080x2160 minimum reference);
- host as full-rect child;
- settle frames;
- build;
- relayout;
- settle frames;
- disable runtime auto processing;
- reset deterministic runtime clock before measured gameplay.

When +1 Slot grows to six:
- settle/re-layout as needed before measuring origins.

Hard assertion:
- every slot origin used for the 59x59 production-performance fixture is finite and exterior to the board;
- specifically, the normal gameplay contract should show it below the board bottom;
- do not accept an origin on/in the 0..W-1 × 0..H-1 logical board.

Keep an explicit UNLAID regression fixture only if useful to prove the old artifact, but do not use it as production performance evidence.

## Differential correctness proof

This cycle must compare FAST-PREFILTER vs BASELINE-UNFILTERED behavior.

Preferred baseline seam:
- wrap the real `ProductionTargetAccess` in a test-only access adapter that exposes the same `is_targetable()` semantics but intentionally does NOT expose the optional prefilter capability.

This makes the same current `TargetSelector` execute:
- optimized canonical path with prefilter;
- legacy full strict loop without prefilter.

Compare them on identical detached/replayed states.

Required identity proofs:

1. exact selected target index;
2. exact reservation result;
3. exact target/color dispatch sequence;
4. exact clear identity/order where deterministic clock is normalized;
5. exact final board and completion truth.

## Required test matrix

### 1. Touch-mask equivalence

For many board states/revisions, including:
- 20x20;
- 32x32;
- rectangular board;
- 59x59;
- early/mid/late cleared states;
- retry/restore;
- perimeter targets;
- interior sealed targets;
- open-corridor targets;

prove for every valid index on an outside origin:

`materialized_touch[index] == old necessary-condition result`

No false negative allowed.

Inside-board origin:
- capability is unsupported;
- selector falls back to old full loop.

### 2. Selector filtered/unfiltered equivalence

At minimum:
- first 10 production levels;
- 20/32/38/59 representative boards;
- duplicate-color/reservation cases;
- WAITING/no-target case;
- six-slot case;
- multiple board revisions.

For every selection transaction:
- same winner;
- same no-target result;
- same reservation state;
- same owner/target relation.

### 3. Full 59x59 laid-out host

Run the six-stripe full level to WON with:
- canonical prefilter enabled;
- baseline wrapper disabling the prefilter.

Require:
- 3481/3481 clears;
- exact dispatch target/color sequence identity;
- exact final board;
- zero duplicate claim/clear;
- zero residue;
- max `compute_route` <= 1 per outside-origin lane;
- 0 failed route probes;
- every slot origin exterior/below-board.

### 4. Strict/adversarial fallback

Run all relevant M15/M19/M25 strict suites.

Add focused tests proving:
- missing optional capability -> old full path;
- malformed capability return -> old full path;
- capability `true` still invokes full authoritative `is_targetable`;
- capability `false` only skips that candidate;
- noncanonical/adversarial doubles are not silently granted success.

### 5. Revision invalidation

Prove:
- clear increments revision -> new mask;
- Retry/restore invalidates/rebuilds;
- different BoardState with same dimensions never reuses old mask;
- same revision lanes may share mask safely.

## Hard performance/work bounds

These are blocking and machine-independent:

1. outside-origin real-layout production lane: `compute_route <= 1`;
2. failed route probes = 0 on the full 59x59 laid-out reproduction;
3. strict selector-body iterations per lane <= number of touchable matching candidates + 1 accounting for the winner;
4. impossible candidates do NOT execute the expensive strict reservation/coherence body;
5. touch-mask candidate check is O(1) after the revision mask is built;
6. one-lane-per-frame scheduler rule remains unchanged;
7. no new cache grows unbounded across revisions/boards.

## Timing evidence

Timing is evidence, not the sole correctness gate.

On the clean laid-out 59x59 full-level reproduction report:

- target-selection total;
- access_compute_route;
- route_dijkstra;
- selector scan excluding winning route;
- frame p50/p90/p99/max;
- new 1x and 2x where practical.

Target for S1:
- selector scan excluding winning route p99 <= 3 ms.

If machine noise misses this target while hard work-count bounds pass, report exact numbers; do not fake or weaken correctness.

Crucially, remeasure the remaining winning-route Dijkstra hotspot.

Do NOT optimize it in this cycle.

## M29 evidence correction

Regenerate/update the M29 59x59 performance evidence so it no longer reports UNLAID geometry as production performance.

Preserve historical V01 evidence files if needed for audit history; create clearly versioned corrected evidence rather than silently rewriting historical claims without note.

The M29 tempo constants/behavior are not being changed.

## Regression gate

Run at minimum:

- new M25-C003 focused suite;
- M15 strict;
- M19 strict;
- M25 all current claim suites;
- M26 scheduler;
- M29 exact slot origin;
- M29-C002 tempo retune with corrected laid-out s8;
- M30;
- M39;
- M52;
- M55 long session;
- routing/railroad suites;
- root suite;
- `git diff --check`.

Known historical unrelated baselines may remain only if exact signatures match.

## Scope locks

Do NOT:
- edit root `TASKS.md`;
- change gameplay speed constants;
- change target priority;
- change route geometry;
- change railway-first rule;
- implement route/Dijkstra optimization;
- implement incremental continuation;
- add shipping inside-board-origin guard;
- change economy;
- change level content.

## Required outputs

Create:

- `coordination/sessions/M25-C003/CLAUDE_LOG_V01.md`
- `coordination/sessions/M25-C003/IMPLEMENTATION_MATRIX_V01.md`
- `coordination/sessions/M25-C003/evidence/` with work-count + timing reports.

Commit/push to `main`.

Return:
1. final SHA;
2. exact optional prefilter API;
3. touch-mask ownership/invalidation;
4. full differential correctness results;
5. 59x59 laid-out work counts;
6. before/after timing;
7. remaining Dijkstra/frame hotspot numbers;
8. regression results.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M25-C003 EXACT-SAFE TARGET PREFILTER V01`
