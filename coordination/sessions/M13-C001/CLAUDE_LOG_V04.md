# CLAUDE_LOG_V04 — M13-C001 Strict Dependency Closure V04

Cycle: M13-C001
Prompt: coordination/sessions/M13-C001/CHATGPT_PROMPT_V04.md
Criteria: coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V04.md
Handoff state: AWAITING_AUDIT

## Scope

Same frozen finding set. Closes the reopened F-M13-STRICT-001 gaps and
preserves the V03 -002/-003 corrections, all in
`scripts/gameplay/targeting/color_candidate_index.gd`. No M14+ behavior.
`scripts/gameplay/board/board_state.gd` unchanged (FOUNDATION-STRICT-001
separate). Governance untouched.

## Sync

- `git fetch origin`, safe `git merge --ff-only origin/main`. No ahead commits.
- Pre-existing tracked owner modifications preserved, NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`.
- No destructive sync ops.

## Production fixes (F-M13-STRICT-001)

1. **bind(null) stale-escape (§1).** `bind()` now `_neutralize()`s on the null
   path too, so null is no longer the single bind failure that preserves stale
   state. Every bind failure (null / non-RefCounted / missing API / malformed
   build) is one consistent fail-closed policy. Fresh `bind(null)` stays safe
   (neutralize is idempotent).
2. **RefCounted-only dependency lifecycle (§2).** `_has_board_api()` now
   requires `board is RefCounted` (was `is Object`) plus the full narrow API.
   Real BoardState and the M13 spies/doubles are RefCounted; a method-compatible
   Node is rejected, so no externally-freed Node dependency can enter M13.
3. **sync_cell live-drift neutralization (§4).** `sync_cell()` distinguishes a
   HEALTHY out-of-range index (plain `false`, cache intact) from a MALFORMED
   live return (non-bool `is_valid_index`, non-int `get_cell_state`, non-int or
   negative `get_color_id` on ACTIVE **or** CLEARED) which now `_neutralize()`s.
   Previously non-int state/color returned `false` without neutralizing.
4. Zero `get_cell_count` documented as intentional/harmless (empty board binds
   with no candidates); negative/non-int count still fails closed. The
   transactional `_scan` already covered the §3 build adversaries (negative
   count, non-bool/false `is_valid_index`, non-int/unknown state, non-int/
   negative color) — verified by new tests, no further production change needed
   there.

## Tests

- Extended `tests/support/m13_malformed_board_double.gd` with per-index
  adversary knobs (`count_negative`, `invalid_index_false_at`,
  `invalid_index_nonbool_at`, `state_nonint_at`, `cleared_at`, `color_nonint_at`,
  `color_neg_at`) so a malformed value can be placed AFTER earlier valid ACTIVE
  indices (transactional proof).
- New `tests/support/m13_board_node_double.gd`: method-compatible Node for the
  RefCounted-only lifecycle test.
- `_run_m13_v04_strict_validation()` (M13V4-001/002/003/004): bind(null)
  fail-closed sequence + recovery + fresh-safe; RefCounted-only lifecycle (real
  board / spy / canonical double accepted; plain RefCounted / bare Node /
  method-compatible Node rejected); complete transactional build adversaries
  with no partial commit; sync_cell live-drift (healthy-invalid stays intact,
  malformed neutralizes) + recovery.
- V03 (M13V3-*) and V02/V01 (T1-T23) regressions retained green, including the
  -002 unknown-state and -003 exclusion coverage and the real ReservationState
  `PackedInt32Array` consumer.

## Commands run (Godot 4.7.1)

- `godot --version` -> `4.7.1.stable.official.a13da4feb`
- `godot --headless --path . -s res://tests/run_tests.gd`
  -> `Total checks: 2264  Failures: 0  RESULT: ALL PASS`
- `git diff --check` -> exit 0 (only informational LF->CRLF warnings)

## Governance

Not modified: `tasks.md`, `.hiveai/*`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, the strict repair queue/sequence files, any
`CHATGPT_*` file, `scripts/gameplay/board/board_state.gd`. No self-audit.

## Handoff

AWAITING_AUDIT.
