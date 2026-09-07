# M16-C001 — Claude Implementation Log V02

Cycle: **M16-C001** — RoutingSystem contract/validator strict correction
Prompt: `coordination/sessions/M16-C001/CHATGPT_PROMPT_V02.md`
Audit criteria: `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Strict re-audit driving this work: `coordination/sessions/M16-C001/CHATGPT_STRICT_REAUDIT_V02.md`
Handoff state at end: **AWAITING_AUDIT**
Engine: Godot **v4.7.1.stable.official.a13da4feb**

Scope: fix ONLY the M16 contract/validator defects raised by the strict re-audit
(F-M16-STRICT-001/002/003 + the access-verdict-type dependency check). No M17
pathfinding, no movement-language change, no governance edits.

---

## 1. Starting point / safe sync

- Local `HEAD` before sync: `4b34337` (behind `origin/main` by 17, ahead by 0).
- Sync method: `git fetch origin main` then `git merge --ff-only origin/main`
  (fast-forward only — **no** `reset --hard`, `clean -fd`, restore/checkout, or
  force operation).
- Base `origin/main` SHA after fast-forward (base for this work):
  `61608ff010fd2b8c7b9ea42c2690ea3d88483bca`.
- Verified before merging that the 17 upstream commits touch **none** of the
  owner-modified files (`git diff --name-only HEAD origin/main` vs the working
  tree). Upstream touched only `.hiveai/*`, `coordination/*`, `docs/*`,
  `tasks.md`; the owner modifications (`project.godot`,
  `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`) and all untracked owner files
  (`*.import`, `*.uid`, `docs/logs/`, `assets/art/references/_owner_inbox/...`)
  survived the fast-forward untouched. See §7.

## 2. Exact changed files

Modified (M16 strict correction):
- `scripts/gameplay/routing/route_validator.gd`
- `tests/run_tests.gd`

New (TEST-only adversarial double):
- `tests/support/route_nonbool_access_double.gd`

New (this evidence log):
- `coordination/sessions/M16-C001/CLAUDE_LOG_V02.md`

Explicitly **not** staged (owner/local work, preserved): `project.godot`,
`scenes/debug/routing_prototype_lab.tscn`,
`scenes/debug/scrubbot_agent_debug.tscn`, every `*.uid`, `docs/logs/`,
`assets/art/references/_owner_inbox/*`, and the session scratchpad temp file.

## 3. Defect-by-defect implementation

### F-M16-STRICT-001 — non-finite request coordinates rejected

`RouteValidator` gains a reusable finite-Vector2 check
`is_finite_vector(v) -> bool` (`is_finite(v.x) and is_finite(v.y)`, Godot 4.7.1
global `is_finite()`, which is false for both NaN and ±INF).

`validate_request()` now rejects a non-finite `start_position` or
`target_position` with `INVALID_REQUEST` **before** any access/routing geometry
call (placed immediately after the null checks, ahead of `center_of_index()` /
`is_valid_index()` / `get_cell_position()`). So NaN/±INF can never reach routing
math (floor/distance/sorting) or an access query, and it fails closed/stable, not
as a runtime fault.

Tests (in `_run_route_validator_tests`):
- NaN start rejected;
- +INF start rejected;
- -INF start rejected;
- non-finite `target_position` rejected;
- a non-finite request routed through `validate_route()` returns
  `INVALID_REQUEST` and makes **zero** access calls (asserted via
  `RouteAccessQueryDouble.total_queries() == 0`).

### F-M16-STRICT-002 — non-finite intermediate route points structurally rejected

`validate_route()` now inspects **every** route point for finiteness before the
access-query loop. Any non-finite point (including an intermediate one) returns
`INVALID_ROUTE` and the access query is called **zero** times for that malformed
route (the loop is the only caller, and the finite guard precedes it).

Tests use `default_traversable = true` access doubles so that, absent the guard,
access would *approve* the route — proving `INVALID_ROUTE` + zero queries comes
from the structural finite check, not from access blocking:
- NaN intermediate point → `INVALID_ROUTE`, zero access calls;
- INF intermediate point → `INVALID_ROUTE`, zero access calls.
(Malformed **middle** points, not only endpoints, per the prompt.)

### F-M16-STRICT-003 — success/failure metadata coherence

- `validate_route()` now requires `result.failure_reason == NONE` for a claimed
  success; a success result carrying e.g. `failure_reason = NO_ROUTE` is rejected
  `INVALID_ROUTE`.
- New reusable structural validator
  `validate_failure_result(request, result) -> StringName`: returns `NONE` only
  for a coherent failure (success == false; non-NONE reason; zero points;
  requested target retained when a request is supplied), else `INVALID_ROUTE`.
  This does **not** widen `RouteResult`'s mutable internals — it is a read-only
  static check.

Tests:
- success + NO_ROUTE contradiction → `INVALID_ROUTE`;
- canonical failure (`NO_ROUTE`, target retained, empty points) → `NONE`;
- failure + NONE → `INVALID_ROUTE`;
- failure with route points → `INVALID_ROUTE`;
- failure with wrong target → `INVALID_ROUTE`;
- a success result rejected as a failure result → `INVALID_ROUTE`.

### Additional strict dependency check — access verdict must be an actual bool

The segment access loop now captures the verdict and rejects it when
`typeof(verdict) != TYPE_BOOL`, so a query returning int/string/null fails closed
`INVALID_ROUTE` rather than letting a truthy non-bool count as approval.

New TEST double `route_nonbool_access_double.gd` returns a configurable non-bool
`verdict_value` and counts calls. Tests iterate `[1, "yes", null]`:
- each fails closed to `INVALID_ROUTE`;
- `call_count >= 1` proves the verdict was actually consulted then rejected on
  type (not short-circuited before the query).
Normal `true`/`false` access semantics remain proven by the pre-existing
open-segment (valid) and blocked-segment (`INVALID_ROUTE`) tests.

## 4. Regression / preserved contract

Unchanged and still green:
- detached `RouteResult` point copy-in (`success_route`) and copy-out
  (`get_points()`);
- no retarget (failure retains the originally requested target);
- no `BoardState` / `ReservationState` mutation (validator is stateless static
  functions; no mutation added);
- board-local cell coordinates (no pixel/1080×2160 leakage);
- slot origins left/right/above/below (outside-board) preserved;
- swappable `RoutingSystem.compute_route(request, board, access_query)` contract
  (base + two fakes);
- 59×59 and 53×59 rectangular full-route coverage;
- **no** M17 path algorithm added (no AStar/BFS/DFS/curve/collision); base
  `RoutingSystem` still returns `NOT_IMPLEMENTED`.

## 5. Validation results

- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` →
  **Total checks: 1662, Failures: 0, RESULT: ALL PASS**. No `SCRIPT ERROR` /
  `Parse Error` lines. (The only `ERROR:` lines are pre-existing intentional
  negative-path importer tests loading deliberately corrupt/nonexistent images —
  unrelated to this change.)
- `git diff --check` → clean (exit 0; only benign LF→CRLF line-ending warnings on
  `route_validator.gd` and `run_tests.gd`; no whitespace errors).
- `git diff` inspected before commit.

Material strict checks asserted individually above (§3), not inferred from the
aggregate green total (AL-009). Each new test is a direct adversarial assertion
on the contract/validator, not a proxy.

## 6. Governance / non-scope confirmation

Not created or modified by Claude this cycle: `tasks.md`,
`.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`,
`.hiveai/PROGRESS_SNAPSHOT.md`, `.hiveai/PROJECT_DASHBOARD.md`,
`coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, and any
`CHATGPT_AUDIT_VNN.md`. No self-audit and no audit verdict assigned. Reopened
tasks (SB-M16-002/003/010/011) are left for ChatGPT to re-close after audit.

## 7. Owner / local-work preservation evidence

- `git merge --ff-only` used; no destructive command run.
- `project.godot` and both `scenes/debug/*.tscn` remained `M` (owner-modified)
  throughout and were **not** staged.
- All untracked owner artifacts (`*.import`, `*.uid`, `docs/logs/`, owner inbox
  art, scratchpad temp) remained untracked and untouched; none were committed.
- Only the two modified `.gd`/test files, the one new TEST double, and this log
  were staged.

## 8. Commit / push

See the commit carrying this cycle's V02 correction (`fix(M16-C001 V02) ...`).
Push performed to `origin/main` with a non-destructive `git push` (no force).
Handoff: **AWAITING_AUDIT**. Claude stops here and does not self-audit.
