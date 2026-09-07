# CLAUDE_LOG_V03 — M13-C001 Frozen Full-Surface Color Candidate Closure V03

Cycle: M13-C001
Prompt: coordination/sessions/M13-C001/CHATGPT_PROMPT_V03.md
Criteria: coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V03.md
Handoff state: AWAITING_AUDIT

## Scope

Fixed ONLY the three frozen findings in
`scripts/gameplay/targeting/color_candidate_index.gd`:

- **F-M13-STRICT-001** — malformed non-null dependency could reach bound state
  before the first missing/mistyped board method faulted.
- **F-M13-STRICT-002** — unknown/noncanonical cell state was silently treated as
  CLEARED.
- **F-M13-STRICT-003** — excluded/reserved Variant seam accepted unsupported
  containers/entries (float/String could coerce-match an integer index).

No M13+ behavior added. `scripts/gameplay/board/board_state.gd` unchanged
(FOUNDATION-STRICT-001 left separate, per prompt). Governance untouched.

## Sync

- `git fetch origin`, safe `git merge --ff-only origin/main`. No ahead commits.
- Pre-existing tracked owner modifications preserved, NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`.
- No destructive sync ops.

## Fixes

### 1. Dependency boundary + transactional build (F-M13-STRICT-001)

- `_has_board_api(board)`: `board is Object` and `has_method()` for the narrow
  M13 surface (`get_cell_count`, `is_valid_index`, `get_cell_state`,
  `get_color_id`) — duck-typed, so a compatible spy/double still binds, but a
  non-Object Variant (int/String/Vector2) or a partial-API object is rejected
  before any method call.
- `_scan(board)`: builds buckets into a LOCAL Dictionary; validates
  `get_cell_count` is a non-negative int, each index valid, each state exactly
  ACTIVE/CLEARED, each ACTIVE color id an int `>= 0`. Returns `null` on any
  malformed value. `bind()`/`rebuild()` commit `_board`/`_buckets`/`_bound`
  only after `_scan` succeeds — no partial buckets, no fault on bad return
  types.
- `_neutralize()`: resets to safe unbound/empty. Called on every fail-closed
  path so a malformed bind after valid state (and failed rebind/rebuild) leaves
  no stale/malformed usable binding. A later valid bind/rebind recovers.
- `rebind()` = `_neutralize()` then `bind()` (explicit destructive fresh-board
  path); null/malformed -> false + safe unbound.

### 2. Unknown cell state (F-M13-STRICT-002)

- `sync_cell()`: ACTIVE -> add, CLEARED -> remove, any other state ->
  `_neutralize()` + `false`. Chosen documented policy: invalidate/unbind the
  cache on unknown state so no stale/unknown membership is asserted as canonical
  truth — never silently treated as CLEARED. State/color return types are
  type-checked first.
- Build/rebuild reject unknown state via `_scan` returning `null` (no partial
  commit); restoring canonical truth + valid rebuild/rebind recovers.

### 3. Excluded/reserved Variant seam (F-M13-STRICT-003)

- `_is_supported_exclusion()`: only Array, PackedInt32Array, Dictionary. `null`
  is the intentional no-exclusion contract (documented + tested). Any other
  container -> `get_candidates` `[]`, `has_candidates` `false`,
  `count_candidates` `0`, no fault, cache unchanged.
- `_to_int_set()`: only TYPE_INT entries exclude (Dictionary: integer KEYS,
  values ignored). Float `2.0` and String `"2"` never exclude integer index 2;
  bool/Vector2/RefCounted/nested Array/Dictionary entries are ignored; duplicate
  and out-of-range ints are harmless.
- All three query APIs share the same normalization; malformed query input never
  mutates the cache.

## Tests added

- New double: `tests/support/m13_malformed_board_double.gd` — full narrow M13
  API with configurable malformed returns (wrong count/state/color type,
  unknown state at an index).
- `_run_m13_v03_strict_validation()` in `tests/run_tests.gd` (M13V3-001/002/003)
  covers criteria 1-57, 77-78: dependency-boundary rejection (int/String/
  Vector2/RefCounted/partial/wrong-return), valid-double bind, malformed-after-
  valid neutralize + recovery, rebind A->B/null/malformed/recovery, unknown
  state via sync/initial-build/rebuild + recovery, exclusion container boundary,
  exclusion entry boundary (incl. `2.0`/`"2"` non-coercion), shared query
  semantics, and the real ReservationState `PackedInt32Array` consumer path.
- Existing M13 (T1-T23) and M13-V02 regressions retained green (criteria 58-76,
  79-82).

## Commands run (Godot 4.7.1)

- `godot --version` -> `4.7.1.stable.official.a13da4feb`
- `godot --headless --path . -s res://tests/run_tests.gd`
  -> `Total checks: 2203  Failures: 0  RESULT: ALL PASS`
- `git diff --check` -> exit 0 (only informational LF->CRLF warnings)

## Governance

Not modified: `tasks.md`, `.hiveai/*`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, the strict repair queue/sequence files, any
`CHATGPT_*` file, `scripts/gameplay/board/board_state.gd`. No self-audit.

## Handoff

AWAITING_AUDIT.
