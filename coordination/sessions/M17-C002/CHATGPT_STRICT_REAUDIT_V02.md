# M17-C002 — Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

This strict re-audit focuses on the production promotion of the owner-selected
Organized/curved movement language.

The owner decision itself remains valid:
- Organized/curved movement language;
- deterministic grid-aware planner backbone;
- Direct debug-only.

The defects are in production reachability/access correctness, not owner taste.

## F-M17-STRICT-001 — MAX_ENTRIES=12 can create false NO_ROUTE

Production BFS uses a nearest-first perimeter bridge capped at 12 entries.

That cap was acceptable as an experimental M17-C001 limitation, but it was later
promoted into production. A board can have 12 nearer perimeter entries that all
lead to dead ends while a 13th valid entry reaches the assigned target.

The target is reachable, but production can return NO_ROUTE.

Required:
- remove correctness-affecting entry cap;
- model all valid deterministic perimeter entries or an equivalent complete
  exterior virtual-node solution;
- keep cost bounded by production board maximum through algorithmic design, not
  by dropping valid reachability;
- adversarial test where the first 12 usable entries are dead ends and a later
  entry is the only route.

## F-M17-STRICT-002 — sampled segment access can miss a blocked cell

`ProductionAccessQuery` uses SAMPLE_STEP=0.1 point sampling. Sampling is not an
exact grid-intersection test.

A sufficiently short chord through an ACTIVE cell can fall entirely between two
samples, allowing a diagonal/curved segment to cross blocked gameplay truth.

Concrete adversarial geometry to test:
- from `Vector2(0.5, 0.5)`
- to `Vector2(20.5, 23.5)`
- cell `(7,7)` ACTIVE/non-target

The segment intersects only a short portion of that cell and must be rejected.

Required:
- replace sampling as production truth with deterministic exact/supercover grid
  traversal;
- enumerate every cell a segment crosses;
- conservative exact-corner handling must prevent diagonal corner cutting
  between blockers;
- outside-board remains open;
- assigned ACTIVE target may be entered only as the final target-center endpoint;
- do not merely reduce SAMPLE_STEP.

## F-M17-STRICT-003 — ProductionRoutingSystem returns success without final shared validation

Current production code post-processes and returns `success_route` directly.

Required:
- every raw BFS edge must honor segment access truth, not only cell class;
- retain a last-known-valid route through post-processing;
- final success must pass shared RouteValidator internally before returning;
- invalid shortcut/rounding must fall back to a validated prior route or fail
  explicitly;
- ProductionRoutingSystem must never return success for a route the shared
  validator would reject.

## F-M17-STRICT-004 — topology dependency contract incomplete

Production code checks for `is_segment_traversable` and `classify_cell`, then
calls `cell_of_point` without checking that method.

Required:
- validate the full narrow topology seam before use;
- missing method returns stable MISSING_ACCESS_QUERY/fail-closed, no runtime fault.

## F-M17-STRICT-005 — access-query BoardState coherence is not enforced

ProductionRoutingSystem accepts `board` and a stateful ProductionAccessQuery
that internally owns another board reference.

Same-size Board A / Board B mismatch can make request validation use one state
while access truth reads another.

Required:
- ProductionAccessQuery exposes read-only exact `is_bound_to(board)`;
- ProductionRoutingSystem verifies coherence before route work;
- same-size different-board mismatch fails closed;
- no mutable board reference leak.

## Strict task state

Reopen:
- SB-M17-002
- SB-M17-003
- SB-M17-015
- SB-M17-016

Other M17 tasks, including the OWNER movement-language decision, remain accepted.

Next:
`coordination/sessions/M17-C002/CHATGPT_PROMPT_V02.md`
