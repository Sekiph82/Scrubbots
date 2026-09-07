# M16-C001 — Claude Implementation Log V03

Cycle: **M16-C001** — RoutingSystem contract/validator strict boundary hardening
Prompt: `coordination/sessions/M16-C001/CHATGPT_PROMPT_V03.md`
Audit criteria: `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
Audit driving this work: `coordination/sessions/M16-C001/CHATGPT_AUDIT_V02.md`
Handoff state at end: **AWAITING_AUDIT**
Engine: Godot **v4.7.1.stable.official.a13da4feb**

Scope: fix ONLY **F-M16-STRICT-004** (malformed non-null request/board dependency
boundary, AL-040). Every accepted V02 correction preserved. No M17 pathfinding,
no movement-language change, no governance edits.

---

## 1. Starting point / safe sync

- Local `HEAD` before sync: `d12f558` (M16 V02), behind `origin/main` by 9,
  ahead by 0.
- Sync method: `git fetch origin main` then `git merge --ff-only origin/main`
  (fast-forward only — **no** `reset --hard`, `clean -fd`, restore/checkout, or
  force).
- Base `origin/main` SHA after fast-forward (base for this work):
  `c783af00f3d97366bbfdf4a16fce053b3e67f990`.
- Verified the 9 upstream commits touch **none** of the owner-modified files
  (`git diff --name-only HEAD origin/main` disjoint from the working tree). They
  touched only `.hiveai/*`, `coordination/*` (incl. the M16 V02 audit + V03
  prompt/criteria). Owner modifications (`project.godot`,
  `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`) and all untracked owner files
  survived untouched. See §6.

## 2. Exact changed files

Modified:
- `scripts/gameplay/routing/route_validator.gd`
- `tests/run_tests.gd`

New (TEST-only adversarial double):
- `tests/support/partial_board_double.gd`

New (this evidence log):
- `coordination/sessions/M16-C001/CLAUDE_LOG_V03.md`

Explicitly **not** staged (owner/local work, preserved): `project.godot`,
both `scenes/debug/*.tscn`, every `*.uid`, `docs/logs/`,
`assets/art/references/_owner_inbox/*`, scratchpad temp.

## 3. F-M16-STRICT-004 implementation

AL-040: **non-null is not enough** at a duck-typed/stateful dependency boundary.
V02's numeric guards assumed `request` exposed its fields and `board` exposed its
methods; a non-null malformed object could raise a runtime fault instead of a
stable fail-closed outcome.

### Request boundary
`validate_request()` now first checks `request is RouteRequest`. This is false for
`null` AND for arbitrary junk objects and **never throws** (Godot 4.7.1 `is`
against a preloaded script const). It runs BEFORE any request field
(`start_position` / `target_position` / `target_index` / `board_width` /
`board_height`) is read → malformed request → stable `INVALID_REQUEST`.

### Board boundary
New reusable guard `_board_has_api(board)` requires the narrow M16 BoardState
method surface via `has_method` (which never throws):
`get_width`, `get_height`, `is_valid_index`, `get_cell_state`,
`get_cell_position`. Called BEFORE any board method → a non-null malformed board,
or one exposing only SOME of the surface, fails closed to `INVALID_REQUEST`
before the first missing-method call. The board is only queried, never
stored/exposed.

### validate_route inheritance
`validate_route()` calls `validate_request()` as its first statement, so junk
request/board yield `INVALID_REQUEST` before the endpoint checks and before the
access loop → **zero access calls** for malformed dependencies.

### validate_failure_result boundary
- `result` is guarded by `result is RouteResult` (false for null/junk, no throw)
  before any `.success` / `.failure_reason` / `.point_count()` deref.
- Request handling: `null` request keeps its documented semantics (no target
  comparison); a non-null request that is NOT a real RouteRequest is malformed
  and fails closed to `INVALID_ROUTE` — its `target_index` is never
  dereferenced; a real RouteRequest still must retain the requested target.

No RouteResult/RouteRequest mutable internals were newly exposed; guards are
read-only static checks.

## 4. Adversarial tests (in `_run_route_validator_tests`)

1. RefCounted junk request → `validate_request` → `INVALID_REQUEST`.
2. RefCounted junk board → `validate_request` → `INVALID_REQUEST`.
3. `PartialBoardDouble` (only get_width/get_height) → `validate_request` →
   `INVALID_REQUEST` (before missing-method call).
4. junk request through `validate_route` → `INVALID_REQUEST`, `total_queries()==0`.
5. junk board through `validate_route` → `INVALID_REQUEST`, `total_queries()==0`.
6. partial board through `validate_route` → `INVALID_REQUEST`, zero access calls.
7. malformed non-null request → `validate_failure_result` → `INVALID_ROUTE`
   (no runtime error).
8. null request → `validate_failure_result` on a canonical failure → `NONE`
   (documented semantics retained).

Access doubles use `default_traversable = true`, so a leaked access call would
approve the route — asserting `INVALID_REQUEST` + zero queries proves the guard
precedes and replaces access, not that access happened to block.

New TEST double: `tests/support/partial_board_double.gd`.

## 5. Preserved V02 + regression evidence

- V02 finite-coordinate guards (NaN/±INF start & target) — retained, green.
- V02 finite-middle-point guards (NaN/INF intermediate, zero access calls) —
  retained, green.
- V02 success/failure metadata coherence + `validate_failure_result` canonical
  cases (success+non-NONE, failure+NONE, failure+points, failure+wrong-target) —
  retained, green.
- V02 non-bool access verdict rejection (int/string/null fail closed) — retained,
  green.
- Normal bool access semantics (open valid / blocked INVALID_ROUTE) — green.
- Detached points (copy-in/copy-out), no retarget, no BoardState/ReservationState
  mutation, swappable RoutingSystem contract, board-local coordinates — unchanged.
- 59×59 and 53×59 full-route coverage — green.
- **No** M17 path algorithm added; base RoutingSystem still `NOT_IMPLEMENTED`.

## 6. Validation results

- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` →
  **Total checks: 1673, Failures: 0, RESULT: ALL PASS**. No `SCRIPT ERROR` /
  `Parse Error`. (Only `ERROR:` lines are pre-existing intentional negative-path
  importer tests loading deliberately corrupt/nonexistent images — unrelated.)
- `git diff --check` → clean (exit 0; only benign LF→CRLF warnings on
  `route_validator.gd` and `run_tests.gd`; no whitespace errors).
- `git diff` inspected before commit.

Material boundary checks asserted individually (§4), not inferred from the
aggregate green total (AL-009).

## 7. Governance / owner-preservation

Not created or modified this cycle: `tasks.md`, `.hiveai/*`,
`coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, the strict
sequence controller, and any `CHATGPT_AUDIT*` file. No self-audit, no verdict.
Reopened tasks (SB-M16-002/003/010/011) left for ChatGPT to re-close after audit.

Owner preservation: `git merge --ff-only`, no destructive command;
`project.godot` + both `scenes/debug/*.tscn` stayed `M` and were **not** staged;
all untracked owner artifacts untouched. Only the two modified `.gd`/test files,
the one new TEST double, and this log were staged.

## 8. Commit / push

See the commit carrying this cycle's V03 boundary hardening (`fix(M16-C001 V03)
...`). Push to `origin/main` non-destructive (`git push`, no force). Handoff:
**AWAITING_AUDIT**. Claude stops here and does not self-audit.
