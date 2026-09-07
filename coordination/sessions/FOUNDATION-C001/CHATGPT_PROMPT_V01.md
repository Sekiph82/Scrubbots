# FOUNDATION-C001 — BoardState Canonical CellState Validation V01

Status: **ISSUED — VALIDATION-FIRST FOUNDATION GATE**

This cycle resolves the repository-level:
`FOUNDATION-STRICT-001 — BoardState HIGH-RISK VALIDATION GAP`

It is NOT permission to redesign BoardState.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- scripts/gameplay/board/board_state.gd
- current BoardState tests in tests/run_tests.gd
- this prompt + V01 audit criteria

Expected Claude log:
`coordination/sessions/FOUNDATION-C001/CLAUDE_LOG_V01.md`

## Objective

Determine by direct Godot runtime evidence whether the current typed enum setter:

```gdscript
func set_cell_state(index: int, state: CellState) -> bool
```

actually rejects noncanonical integer enum values.

Canonical BoardState state domain is EXACTLY:
- ACTIVE = 0
- CLEARED = 1

No other stored state is legal.

## Phase A — validation test FIRST

Before modifying production BoardState, add sensitivity-safe direct tests on a
fresh canonical BoardState.

Choose a VALID cell index whose initial state is known.

Directly attempt:
- set_cell_state(valid_index, 2)
- set_cell_state(valid_index, -1)
- set_cell_state(valid_index, 255)

Also include at least:
- 3
- 99

For EVERY noncanonical integer, canonical expected behavior is:
- return false;
- no runtime fault;
- target cell state unchanged;
- all other cell states unchanged;
- ACTIVE/CLEARED counts unchanged.

These must be VALID-index tests. Do not hide state validation behind an invalid
index.

### Sensitivity requirement

Run the new test against the CURRENT production source before any fix.

Record in CLAUDE_LOG_V01:
- whether each invalid integer was accepted/rejected;
- returned value;
- observed cell state after call;
- whether any runtime/SCRIPT ERROR occurred.

If all noncanonical values already return false + no mutation + no runtime
fault, FOUNDATION-STRICT-001 is a validation-only gap. Do NOT modify production.

If ANY value:
- returns true;
- mutates the cell;
- produces an invalid stored state;
- or causes a runtime fault instead of stable false;

then FOUNDATION-STRICT-001 is confirmed as a concrete M02 BoardState defect and
you MUST apply the minimal fix in Phase B.

Do not skip the pre-fix evidence run.

## Phase B — minimal production fix ONLY if Phase A exposes defect

If required, harden set_cell_state() explicitly.

Canonical behavior:
- invalid index -> false/no mutation;
- valid index + ACTIVE -> true;
- valid index + CLEARED -> true;
- valid index + any other integer -> false/no mutation.

Preferred minimal guard:

```gdscript
if state != CellState.ACTIVE and state != CellState.CLEARED:
    return false
```

Place validation before writing _cell_states.

Do not:
- add RESERVED;
- change enum numeric values;
- change PackedByteArray storage;
- change get_cell_state semantics;
- redesign BoardState;
- modify M13/M14/M15/M16/M17/M18/M19 production code.

## Canonical-state regression

Directly prove after final implementation:
- fresh board all ACTIVE;
- ACTIVE -> CLEARED succeeds;
- CLEARED -> ACTIVE succeeds;
- repeated ACTIVE/ACTIVE or CLEARED/CLEARED remains stable;
- invalid index still false/no mutation;
- 2/-1/255/3/99 all false/no mutation;
- get_cell_state never exposes a noncanonical stored value after these calls;
- count_cells_by_state(ACTIVE) + count_cells_by_state(CLEARED) == cell count.

Use at least:
- a small rectangular board;
- a 59x59 board or existing canonical max-board fixture where practical.

## Downstream regression

Run the FULL root suite.

The following contracts must remain green:
- M10 renderer canonical ACTIVE/CLEARED assumptions;
- M11 reset/session state;
- M13 candidate index unknown-state hardening;
- M14 reservation state;
- M15 TargetSelector;
- M16/M17 routing/access;
- M18 agent lifecycle;
- M19 dispatcher tests already present in the root suite.

This cycle does not reopen those milestones.

## Task handling

Claude MUST NOT edit tasks.md.

If Phase A exposes a real defect, record in the log:
`PROMOTE FOUNDATION-STRICT-001 -> M02 defect affecting SB-M02-012`

ChatGPT owns any temporary reopen/final re-close decision after independent
audit.

If Phase A shows current code already rejects all noncanonical integers, record:
`VALIDATION_GAP_ONLY — NO PRODUCTION DEFECT OBSERVED`

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/STRICT_UPSTREAM_REPAIR_SEQUENCE_V01.md
- any CHATGPT_* file

Allowed:
- tests/run_tests.gd;
- a narrowly-scoped test support file only if truly needed;
- scripts/gameplay/board/board_state.gd ONLY if Phase A first exposes a real
  defect;
- matching CLAUDE_LOG_V01.md.

Run and record separately:
- godot --version;
- Phase-A pre-fix focused/root test command and result;
- final full root headless suite;
- git diff --check.

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
