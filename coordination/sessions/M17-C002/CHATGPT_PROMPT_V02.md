# M17-C002 — Strict Production Routing Correction / Validation V02

Status: **ISSUED**

Owner decision remains LOCKED:
- Organized/curved production movement language;
- deterministic Grid-aware planner backbone;
- Direct debug-only.

Read strict policy, M17 owner decision, V01 artifacts, and:
`coordination/sessions/M17-C002/CHATGPT_STRICT_REAUDIT_V02.md`.

Fix production correctness only. Do not change owner movement language and do not
implement M18/M19/M20 features.

## 1. Complete exterior reachability

Remove the correctness cap `MAX_ENTRIES=12` from production reachability.

Use all valid deterministic perimeter entries or an equivalent complete exterior
virtual-node approach.

Required adversarial scenario:
- >12 valid perimeter entries;
- the first 12 in deterministic nearest order are dead ends;
- a later entry is the ONLY connection to the target;
- production must succeed and retain the same target.

Keep deterministic ordering and 59×59 practicality.

## 2. Exact grid segment traversal

Replace production point sampling with exact/supercover cell traversal.

Canonical production rule:
- outside board is OPEN;
- CLEARED cell is OPEN;
- non-target ACTIVE is BLOCKED;
- assigned ACTIVE target can be entered only as the final target-center endpoint;
- a segment that crosses the interior of any blocked cell is rejected;
- exact corner crossing is conservative: include both touched neighbor cells
  needed to prevent diagonal corner-cutting between blockers.

Do NOT fix by decreasing sample spacing.

Required direct tests include:
- short-chord blocker case:
  `(0.5,0.5) -> (20.5,23.5)`, ACTIVE blocker at `(7,7)` => false;
- same geometry with that cell CLEARED => true if no other blocker;
- diagonal exact-corner between two ACTIVE blockers => false;
- axis-aligned cell-center route through CLEARED corridor => true;
- outside-to-perimeter entry;
- target final-center entry allowed;
- passing through target without ending at its center rejected.

## 3. Production route must self-validate

BFS expansion:
- every neighbor edge must satisfy segment access truth as well as topology cell
  classification.

Post-processing:
- preserve last-known-valid route;
- each shortcut/rounded candidate must be validated;
- final result must pass shared RouteValidator INSIDE compute_route before success
  is returned;
- if organized candidate invalid, fall back to a validated prior route;
- if no validated route remains, return explicit failure with original target.

Add a sensitivity double where cells are OPEN but one specific orthogonal segment
is blocked. BFS must not use that edge.

## 4. Full topology seam + board coherence

Before route work require:
- is_segment_traversable
- classify_cell
- cell_of_point
- exact board-coherence query for production stateful access.

ProductionAccessQuery adds read-only `is_bound_to(board)` with exact object
identity and no board-reference leak.

Tests:
- missing cell_of_point -> clean MISSING_ACCESS_QUERY;
- same-size ProductionAccessQuery(Board A) used with Board B -> fail closed;
- correct same-board access still routes.

## 5. Scale/regression

Adversarially exercise:
- 59×59;
- 53×59;
- >12-entry reachability;
- exact segment supercover;
- blocked interior;
- newly-opened-after-clear same target;
- deterministic repeated points;
- no BoardState/ReservationState mutation;
- no retarget;
- owner-selected conservative Organized/curved defaults preserved.

Update ADR-025/current-law docs to replace sampled production truth and capped
entry limitation.

Run full Godot 4.7.1 suite + `git diff --check`.

Governance untouched.

Write `coordination/sessions/M17-C002/CLAUDE_LOG_V02.md`, commit/push,
return `AWAITING_AUDIT`, stop.
