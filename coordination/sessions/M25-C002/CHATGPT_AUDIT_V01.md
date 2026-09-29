# M25-C002 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited investigation: `972619694fda3a48fd078a5c00be5006c89af16e`
Prompt: `coordination/sessions/M25-C002/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M25-C002/CHATGPT_AUDIT_CRITERIA_V01.md`
Task: `SB-M25-033`

## Verdict

**INVESTIGATION_AUDITED_PASS / IMPLEMENTATION_PROMPT_REQUIRED**

The investigation is accepted.

The original M29 multi-second 59x59 target-selection stall is reproduced and correctly attributed to an UNLAID test-harness geometry fault, not to normal production slot geometry.

However, real laid-out 59x59 gameplay still exposes two genuine synchronous costs:

1. an O(candidates) WHAT-side canonical scan;
2. a potentially expensive single winning Railroad Dijkstra late in the level.

The immediate implementation step is limited to S0 + S1:
- fix the performance harness so 59x59 evidence uses real laid-out slot origins;
- materialize the existing exact-safe reachability necessary condition into an O(1) touch mask;
- allow the production selector path to skip candidates that the canonical access layer proves cannot possibly be targetable, while preserving exact canonical order and all adversarial fallback behavior.

Routing acceleration S2 is NOT authorized yet. It will be considered only after S0+S1 is independently audited and remeasured.

## A. Production mutation

**PASS.**

Commit `9726196...` changes only:

- investigation findings;
- Claude log;
- evidence reports;
- `tests/tools/m25_c002_selection_probe.gd`.

No production gameplay file is changed.

Root `TASKS.md` is not changed by Claude.

## B. Reproduction quality

**PASS.**

The investigation reproduces both:

- the original UNLAID M29 fixture;
- a real 1080x2160 laid-out ProductionGameplayHost.

The evidence demonstrates:

### UNLAID

Representative slot origins land inside the 59x59 board, including:
- approximately `(40,0)`;
- `(49,0)`;
- `(58,0)`.

For inside-board origins, `ProductionTargetAccess._could_reach()` intentionally bypasses the M52 Railroad prefilter and uses the interior/debug planner.

Representative worst lane:
- 590 candidates;
- 590 targetability calls;
- 590 `compute_route` calls;
- 0 successes;
- ~2.38 s selection.

This explains the multi-second M29 performance evidence.

### LAID OUT

With real gameplay layout:
- slot origins are below the board, approximately y=72.8 for the 59-high board;
- full 59x59 run clears all 3481 cells and reaches WON;
- 5177 lanes;
- max one `compute_route` per lane;
- 0 failed route probes.

The instrumented and uninstrumented target/dispatch sequences are reported identical.

This is strong evidence that the multi-second spike was a harness geometry artifact.

## C. Per-lane attribution

**PASS.**

Required attribution is present:

- candidate counts;
- targetability calls;
- prefilter rejects;
- route calls;
- successes/failures;
- winner rank;
- origin;
- revision;
- selection timing;
- route timing.

Representative real-layout expensive lane:
- 565 candidates;
- 562 targetability calls;
- 561 cheap prefilter rejects;
- 1 winning route;
- winner rank 561;
- ~26 ms instrumented selection.

Full-level:
- targetability calls p50 28 / p90 295 / max 571;
- route calls max 1/lane;
- 0 failed routes.

## D. Existing M52 prefilter understanding

**PASS.**

The report correctly identifies the current necessary-condition logic:

- outside/rail start: perimeter candidate or candidate adjacent to perimeter-connected CLEARED region;
- inside-board origin: prefilter intentionally bypassed.

It correctly explains why the original M29 fixture exploded:
- the harness produced inside-board origins;
- therefore every candidate reached route computation.

It also correctly separates the remaining real-layout cost:
- the current prefilter avoids failed routes;
- it does NOT prevent TargetSelector from walking the canonical candidate list and executing strict checks on candidates that will later be rejected cheaply.

## E. Truth preservation / architecture

**PASS for proposal stage, with one implementation constraint.**

The recommended touch-mask concept can preserve WHAT/HOW separation if implemented as follows:

- topology/reachability necessary-condition state remains owned by `ProductionTargetAccess`;
- TargetSelector receives only an opaque canonical necessary-condition result/filter;
- TargetSelector never computes rail/frontier/path topology itself;
- the filtered candidate sequence must be an order-preserving subsequence of the exact canonical bottom-most/left-most sequence;
- every removed candidate must be mathematically proven to return `is_targetable == false` for the same board/origin state;
- non-canonical access objects and adversarial doubles MUST retain today's full strict loop.

The future implementation must not generalize this into a trusted arbitrary filter supplied by any duck-typed access object.

Use a canonical-production gate with exact board identity/revision validation and fail back to the existing unfiltered selector path on any uncertainty.

## F. Option comparison

**PASS.**

The investigation meaningfully evaluates:

- A: exact-safe materialized necessary-condition/touch mask;
- B: targetability cache;
- C: bounded deterministic continuation;
- D: origin-geometry harness/diagnostic;
- E: exact-equivalent route acceleration.

The cache option is correctly rejected for the measured workload because there are effectively no reusable failed-route verdicts on real layout.

Continuation is correctly classified as heavier because synchronous selector transaction semantics, revision changes and reservation changes make cursor continuation non-trivial.

## G. Recommendation

**PASS with staged authorization.**

Accepted now:

### S0
- 59x59 performance harnesses must be laid out in a real viewport geometry;
- assert every production slot origin used by the performance fixture is outside the board.

No shipping inside-board-origin guard is authorized in this cycle.

### S1
- materialize existing exact-safe necessary condition as an O(1) per-revision touch mask in `ProductionTargetAccess`;
- production-only prefilter handshake so canonical impossible candidates can be skipped before the expensive strict selector body;
- exact fallback to current behavior for non-canonical access objects or any identity/revision mismatch.

Not yet authorized:

### S2
- Railroad/Dijkstra route acceleration.

Reason: S2 changes deeper HOW implementation and should be justified using clean post-S1 measurements, not the contaminated UNLAID evidence.

## H. Future acceptance metrics

**PASS.**

The implementation cycle must use machine-independent hard checks:

- real laid-out origin outside the board;
- max one winning `compute_route` per lane for outside-origin production geometry;
- exact filtered/unfiltered winner identity;
- exact ReservationState result;
- exact dispatch sequence;
- O(1) touch lookup;
- strict-loop iterations bounded by canonical touchable candidates.

Timing remains evidence, not the sole correctness gate.

## I. M29 disposition

The M29 tempo retune remains functionally accepted.

Owner feel-playtest remains deferred through the S0+S1 optimization cycle.

After S1:
- re-run the laid-out 59x59 full-level performance evidence;
- if remaining frame spikes are dominated by winning-route Dijkstra, ChatGPT will decide whether S2 must block M29 closure or becomes a separate routing-performance follow-up.

## Final

**INVESTIGATION_AUDITED_PASS / IMPLEMENTATION_PROMPT_REQUIRED**
