# M17-C002 — ChatGPT Full Attack-Surface Re-Audit V03

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This audit supersedes the not-yet-executed M17-C002 V02 correction prompt as the
canonical correction basis.

Reason:
the locked audit policy now requires a full subsystem attack-surface sweep and a
frozen finding set BEFORE a critical correction prompt becomes READY.

Owner decision remains LOCKED and is NOT under re-evaluation:
- Organized/curved movement language;
- deterministic grid-aware backbone;
- Direct debug-only;
- validity never traded for aesthetics.

## Sweep scope

ChatGPT inspected:
- ProductionAccessQuery;
- ProductionRoutingSystem;
- shared M16 RouteRequest/RouteResult/RouteValidator contract;
- M17 production tests;
- prototype/production separation;
- immediate M19 reachability consumer (ProductionTargetAccess);
- public mutable production routing configuration.

Godot is unavailable in the ChatGPT audit environment. Existing runtime evidence
remains E1/E2; findings are based on current source/contract/test E3 inspection.

## Frozen findings

### F-M17-STRICT-001 — correctness-affecting MAX_ENTRIES cap

Existing finding retained.

The nearest-first exterior bridge stops after 12 queued entries. A later
perimeter entry can be the only route to the target.

Required:
- complete deterministic exterior reachability;
- no correctness-affecting entry cap;
- direct >12-entry later-only-route test.

### F-M17-STRICT-002 — sampled segment truth can miss blockers

Existing finding retained.

Fixed-step SAMPLE_STEP=0.1 point sampling is not exact cell-intersection truth.
A short chord through an ACTIVE cell can fall between samples.

Required:
- deterministic exact/supercover grid traversal;
- short-chord blocker test;
- conservative exact-corner handling;
- do not "fix" by decreasing SAMPLE_STEP.

### F-M17-STRICT-003 — production success is not self-validated

Existing finding retained and expanded.

ProductionRoutingSystem returns success after post-processing without requiring
the final RouteResult to pass the shared RouteValidator inside compute_route.

Raw BFS open-cell expansion also does not require every neighbour edge to satisfy
segment access truth.

Required:
- every used BFS edge honors segment access;
- retain last validated route through post-processing;
- internally validate final success;
- invalid shaping falls back to a validated prior route or fails explicitly.

### F-M17-STRICT-004 — topology dependency contract is incomplete

Existing finding retained and expanded.

ProductionRoutingSystem checks only some required methods, then uses
cell_of_point without checking it.

Additionally, method existence alone does not prove return-value contract:
- classify_cell must return a canonical CellClass integer;
- cell_of_point must return Vector2i;
- is_segment_traversable must return an actual bool.

Required:
- safe object/type guard before has_method;
- validate the complete narrow seam;
- validate every returned topology/access verdict before trusting it;
- malformed scalar/object/partial/wrong-return doubles fail closed.

### F-M17-STRICT-005 — access BoardState coherence is not enforced

Existing finding retained.

Request validation may use Board A while ProductionAccessQuery internally reads
Board B with identical dimensions.

Required:
- read-only exact is_bound_to(board);
- ProductionRoutingSystem re-checks coherence before route work;
- same-size different-board mismatch fails closed;
- no mutable board reference leak.

### F-M17-STRICT-006 — ProductionRoutingSystem request/access public boundaries can fault before shared validation

New full-surface finding.

Current compute_route() does:
- null-check request;
- then immediately reads request.target_index;
- later calls access_query.has_method(...) after only a null check.

A scalar or malformed non-null request/access Variant can fault before the
hardened M16 validator can reject it.

Required:
- require real RouteRequest before any request field read;
- require object-shaped access before has_method;
- stable failure with target -1 for malformed request;
- stable MISSING_ACCESS_QUERY for malformed access when a valid request exists;
- direct null/scalar/junk/partial tests.

### F-M17-STRICT-007 — ProductionAccessQuery itself is not fail-closed

New full-surface finding.

ProductionAccessQuery._init(board) stores any supplied value. Public methods then
assume a real BoardState.

Also:
- cell_of_point() does floor() on arbitrary finite/non-finite Vector2 values;
- is_segment_traversable() does not reject NaN/INF endpoints;
- invalid target indices can be treated as "no matching target" rather than a
  failed target-specific query.

Required:
- constructor/bound state recognizes only exact BoardState;
- is_bound_to(board) exact identity;
- unbound/malformed instance fails closed rather than throwing;
- non-finite segment endpoints return false;
- cell_of_point(non-finite) returns a documented outside/sentinel cell safely;
- invalid target index returns false for target-specific segment access;
- classify_cell on invalid/unbound state returns safe BLOCKED semantics.

### F-M17-STRICT-008 — direct outside-to-perimeter-target reachability false negative

New full-surface correctness defect.

Exterior entry seeding accepts only cells classified OPEN. The assigned ACTIVE
target is classified TARGET, not OPEN.

Therefore a target on the board perimeter can be directly reachable from an
outside slot while all non-target perimeter cells are blocked, yet the BFS seeds
no entry and returns NO_ROUTE.

Concrete adversarial case:
- small board;
- target ACTIVE on left perimeter;
- slot origin directly outside that target center;
- every other board/perimeter cell ACTIVE/non-target;
- ProductionAccessQuery correctly allows the final outside -> target-center
  segment;
- ProductionRoutingSystem must succeed for the same target.

Required:
- explicitly support direct final arrival to a perimeter target, or equivalent
  complete exterior virtual-node logic;
- do not require target cell to be OPEN as an ordinary transit entry;
- preserve target-only-as-final semantics.

### F-M17-STRICT-009 — non-finite shaping configuration can poison route math

New mutation/configuration finding.

ProductionRoutingSystem exposes mutable tuning:
- max_shortcut_span
- corner_radius
- corner_samples
- enable_rounding

The typed integer/bool fields are structurally constrained, but corner_radius is
a float and can be NaN/INF/negative.

A NaN radius can flow into cut/bezier/access math and may fault or generate
non-finite candidate points before final validation.

Required:
- define fail-safe deterministic behavior for non-finite/negative corner_radius;
- do not allow invalid tuning to produce non-finite route math;
- route validity must remain protected by last-known-valid fallback;
- direct NaN/+INF/-INF/negative radius tests;
- zero/negative corner_samples and max_shortcut_span remain safe and deterministic.

## Accepted / not reopened

No new issue found with:
- owner movement-language selection itself;
- Direct remaining debug-only;
- prototype/production separation;
- no target selection/reservation ownership in routing;
- no BoardState/ReservationState mutation intent;
- target identity/no-retarget intent;
- board-local coordinate system;
- deterministic neighbour ordering;
- 59x59 / rectangular board limits as required test domains.

## Frozen M17 finding set

The complete pre-correction set is now frozen to:
- F-M17-STRICT-001
- F-M17-STRICT-002
- F-M17-STRICT-003
- F-M17-STRICT-004
- F-M17-STRICT-005
- F-M17-STRICT-006
- F-M17-STRICT-007
- F-M17-STRICT-008
- F-M17-STRICT-009

The older CHATGPT_PROMPT_V02.md is **SUPERSEDED** and must not be executed.

Next:
`coordination/sessions/M17-C002/CHATGPT_PROMPT_V03.md`
