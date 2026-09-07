# M14-C001 — Claude Implementation Log V02

Cycle: **M14-C001** (Reservation State) — V02 frozen full-surface correction.
Prompt: `coordination/sessions/M14-C001/CHATGPT_PROMPT_V02.md`
Audit criteria: `coordination/sessions/M14-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Basis: `coordination/sessions/M14-C001/CHATGPT_FULL_SURFACE_REAUDIT_V03.md`
Handoff state: **AWAITING_AUDIT**

Scope executed: fix ONLY `F-M14-STRICT-001` and `F-M14-STRICT-002`.
BoardState NOT modified. No M15+ behaviour added.

## SHAs

- Starting `origin/main` SHA (synced to): `1a5ba5c3f1ba1e6ec095b9830a0a2675f8488c90`
- Pre-implementation local HEAD: `a92891c` → fast-forwarded to `1a5ba5c`.
- Implementation commit SHA: recorded in the GitHub push receipt for this cycle
  (non-self-referential final-SHA rule; this log holds pre-commit evidence).

## Safe sync (GitHub-only logging override, M12-C001)

- `git fetch origin`; local was behind by 12, ahead by 0.
- Verified the 12 incoming commits do NOT touch the owner's pre-existing
  uncommitted files (`project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`) via
  `git diff --name-only HEAD origin/main | grep -E ...` → no overlap.
- `git merge --ff-only origin/main` → fast-forward `a92891c..1a5ba5c`.
- No `reset --hard`, `clean -fd`, `restore`, `checkout --`, or force used.
- Owner work preserved and NOT staged: pre-existing `M` on `project.godot` and
  the two debug scenes; all untracked owner assets (`_owner_inbox/*.import`,
  `*.uid`, `docs/logs/`, `assets/brand/akilta-wordmark.svg.import`, scratchpad).

## Findings fixed

### F-M14-STRICT-001 — BoardState dependency contract now fail-closed

`scripts/gameplay/targeting/reservation_state.gd`:

- New internal `_is_canonical_board(board)`: rejects on lifecycle category
  first (`board is RefCounted`), so every scalar/non-object Variant
  (int/String/Vector2/Dictionary/Array) and a method-compatible **Node** are
  rejected BEFORE any `has_method` call (AL-040). Then requires the complete
  narrow API `get_cell_count` / `is_valid_index` / `get_cell_state`; a partial
  RefCounted is rejected.
- New internal `_try_bind(board)` takes a one-shot **bind-time domain
  snapshot**: reads `get_cell_count()` once, requires `TYPE_INT`, requires
  `0 <= count <= MAX_CELL_COUNT` (3481 = 59×59). Stores it as immutable
  `_cell_count`. Oversized/malformed counts fail with **no per-cell traversal**.
- `reserve()` hardened to live-truth fail-closed:
  - `owner_id < 0` → false;
  - target outside stored `[0, _cell_count)` → false **before** any per-index
    board call (guarantees `is_valid_index`/`get_cell_state` are never called
    for an out-of-domain target);
  - `is_valid_index` must return `TYPE_BOOL true`; in-domain `false` or a
    non-bool → false;
  - `get_cell_state` must return `TYPE_INT` equal to `ACTIVE`; `CLEARED`,
    unknown ints (2/-1/255/99), and non-int returns → false;
  - every dependency-validation failure preserves existing reservation
    ownership maps (M14 owns live assignment metadata; a dependency fault must
    not erase live reservations — unlike M13's derived cache).

### F-M14-STRICT-002 — ordinary bind is now UNBOUND-only

- `bind(board)` returns `false` immediately when already bound, making zero
  destructive changes: board identity, bound status, both ownership maps,
  reservation count and reserved-index snapshot are all preserved. It no longer
  reaches dependency validation while bound (so a scalar re-bind never calls
  `has_method`).
- `rebind(board)` remains the explicit destructive board-replacement API:
  clears board + reservations + `_cell_count` first, then `_try_bind()`. Valid
  board installs new domain; same-board rebind may clear; null/malformed rebind
  leaves a safe cleared+unbound state recoverable by a later valid bind/rebind.
- `reset()` unchanged (clears reservations, keeps binding/domain).

Owner-visible line delta on production script: +81/−19 hunk (see diff stat).
BoardState untouched. No RESERVED cell state introduced.

## Tests added (`tests/run_tests.gd` + new doubles)

New counting/partial/Node doubles under `tests/support/`:
- `m14_counting_board_double.gd` — RefCounted, full narrow API, configurable
  `cell_count` (any Variant), `valid_mode` (normal/false/nonbool),
  `state_overrides`, and per-index counters (`per_index_calls()`).
- `m14_partial_board_double.gd` — RefCounted with `get_cell_count` only.
- (reused) `m13_board_node_double.gd` — method-compatible Node.

New `_run_reservation_state_strict_tests()` covers prompt §1–§8:
- §1 dependency category rejection (int/String/Vector2/Dictionary/Array/plain
  RefCounted/partial/Node-without-API/method-compatible Node) + bind-time count
  snapshot (String/-1/3482/1e6/very-large → fail; 0 and 3481 → allowed);
  oversize rejection proven with `per_index_calls() == 0`.
- §2 repeated-bind matrix (same A / different B / null / int / partial /
  compat Node) after two live reservations — every re-bind returns false and
  leaves board identity, count, both mappings, and sorted indices unchanged.
- §3 destructive rebind: valid B, same board, null, malformed — with recovery.
- §4 reserve live-return contract with the counting double: out-of-domain
  targets make zero per-index calls; `is_valid_index` false/non-bool → false;
  `get_cell_state` CLEARED/2/-1/255/99/float/String/Object → false; ownership
  preserved on every failure.
- §5 mirrored-map invariants across reserve/release/release_for_owner/
  resolve_arrival/reset (incl. sibling-preservation and no BoardState mutation).
- §6 query/encapsulation regression (negative/large IDs; detached
  PackedInt32Array snapshot; no `get_board` getter).
- §7 M13 ColorCandidateIndex exclusion regression (PackedInt32Array excluded
  set; release_for_owner restores visibility on next snapshot).
- §8 real 59×59 (3481) bind/reserve/release + structural no-scan evidence
  (one reserve = exactly 2 board reads; query/release = 0 board reads).

## Commands / results (recorded separately)

- `godot --version` → `4.7.1.stable.official.a13da4feb`
- Full root headless suite: `godot --headless -s tests/run_tests.gd`
  - Baseline before changes: **2313 checks, 0 failures, ALL PASS**.
  - After changes: **2506 checks, 0 failures, ALL PASS** (+193 M14 strict).
- `git diff --check` → clean (only informational LF→CRLF warnings on the two
  touched text files; no whitespace/conflict errors).

## Governance compliance

- Did NOT modify: `tasks.md`, `.hiveai/*`, `coordination/SESSION_INDEX.md`,
  `coordination/AUDIT_INDEX.md`, the strict repair-queue/sequence files, any
  `CHATGPT_*` file, or `scripts/gameplay/board/board_state.gd`.
- Did NOT create audit/self-audit files or assign any verdict.
- Staged only this cycle's task files (production script, test file, two new
  test doubles, this log). Owner pre-existing tracked changes left unstaged and
  intact per the Preserve-pre-existing-tracked-local-work lock.
- `FOUNDATION-STRICT-001` remains separate and unresolved in this M14 cycle.

## Handoff

State: **AWAITING_AUDIT**. Stopping. ChatGPT owns the independent audit and all
SESSION_INDEX / H!veAI / dashboard updates.
