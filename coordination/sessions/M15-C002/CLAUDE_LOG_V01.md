# M15-C002 — CLAUDE_LOG_V01

Cycle: **M15-C002** · Prompt: `CHATGPT_PROMPT_V01.md` · Task: **M15-C002-V01**
Finding set (frozen): **F-M15-STRICT-004**, **F-M15-STRICT-005**
Actor: CLAUDE · Handoff: **AWAITING_AUDIT** (no self-audit verdict claimed)

## 1. Environment / sync

- Godot: **4.7.1.stable.official.a13da4feb** (`godot --version`).
- Synced starting `origin/main` SHA: **42e2caf221c034d582db71ff9dd2e77b7bd6ae23**
  (fast-forward from local `c30b802`, +6 upstream commits, 0 local ahead;
  incoming files did not touch any locally-modified file, so the ff preserved
  owner work).
- Pre-existing owner working-tree changes preserved and NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`, plus untracked `.uid`/`.import`/
  owner-inbox assets. None were restored, reset, or committed.

## 2. H!veAI start transition (pushed before production edits)

- `.hiveai/TASKS.md`: `CHANGES_REQUIRED -> IN_PROGRESS`, requiredActor `CLAUDE`,
  progress unchanged `278/719 = 38.66%`, stale current-state text reconciled
  (no lingering M19/V02/V03 "awaiting implementation" claim in the current
  block).
- `.hiveai/EVENTS.jsonl`: appended one `hiveai-event/v1` WORKFLOW_CHANGED row
  (`CHANGES_REQUIRED -> IN_PROGRESS`, id `272ec55e-1729-4e01-af6b-3f71445f9d23`).
- Start-transition commit **2df67b2** pushed to `origin/main`
  (`42e2caf..2df67b2`) before any `target_selector.gd` edit.
- Canonical state on sync matched the prompt exactly (currentTaskId
  `M15-C002-V01`, workflowState `CHANGES_REQUIRED`, requiredActor `CLAUDE`,
  progress `38.66%`), so no `HIVEAI_STATE_CONFLICT`.

## 3. Pre-fix sensitivity evidence (prompt §10 / criteria 8–12)

A temporary probe (`tests/m15_c002_prefix_probe.gd`, since deleted; permanent
coverage now lives in `tests/run_tests.gd`) ran the four frozen adversarial
classes against the **pre-fix** `target_selector.gd`:

| # | Class | Pre-fix outcome |
|---|-------|-----------------|
| 1 | scalar `access_query` (int 5) | **SCRIPT ERROR** — `Invalid call. Nonexistent function 'has_method' in base 'int'` at `target_selector.gd:131`; no fail-closed |
| 2 | non-bool `is_targetable` (int 1) | **accepted as reachable** — returned target 0, `reservations=1` |
| 3 | `selector.bind` re-entry from targetability callback | reserved in **foreign bundle B** — `B.reservations=1` |
| 4 | `ReservationState.rebind(boardB)` from targetability callback | reserved in **drifted bundle** — `drifted-rs.reservations=1` |

Verdict: **M15-C002 DEFECT CONFIRMED** on all four classes (fault, non-bool
acceptance, and reservation across a drifted/foreign bundle).

Post-fix, the same four classes each fail closed: (1) `-1` no fault; (2) `-1`
no reservation; (3) continues safely on A, `B.reservations=0`; (4) `-1`,
`drifted-rs.reservations=0`.

## 4. Frozen minimal correction (production)

Only `scripts/gameplay/targeting/target_selector.gd` changed.

**F-M15-STRICT-004 — dependency & Variant-return fail-closed boundary**
- `bind()` now requires `board is BoardState` (category, not method-name
  compatibility — Node/scalar/non-BoardState RefCounted rejected), and
  `candidate_index`/`reservation_state` to be `RefCounted` exposing the full
  required API (reservation API now includes `release` + `get_owner`).
- Coherence gate requires `is_bound_to(board)` to return an **actual TYPE_BOOL
  true** via `_bool_true()`; non-bool true-ish values do not pass.
- `access_query` boundary: `access_query is RefCounted` short-circuits before
  any `has_method()` call, so a scalar/String/Vector2/Array/Dictionary never
  reaches `has_method` and a method-compatible Node is rejected on category.
- Every dynamic collaborator return is type-validated before typed use:
  `get_target_for_owner` → TYPE_INT; `get_reserved_indices` →
  PackedInt32Array; `get_candidates` → Array; each candidate entry → TYPE_INT
  before any BoardState call; `is_reserved` → TYPE_BOOL; `reserve` → TYPE_BOOL
  (only actual `true` is success); `get_owner` → TYPE_INT for ownership proof.
  Any malformed return yields stable `-1` / no mutation / no runtime fault.
- Targetability verdict accepted only on actual `true` (`_bool_true`).

**F-M15-STRICT-005 — selection-operation snapshot / rebind safety**
- Added a monotonic `_bind_generation` (incremented per successful bind) and an
  `_in_selection` guard.
- `select_and_reserve()` captures an immutable snapshot `(board, candidate
  index, reservation state, bind generation)` at entry and runs the operation
  through `_select_core` under `_in_selection = true`.
- `bind()` during an active selection returns `false` without touching the
  active binding — a re-entrant bind cannot move the selector to another bundle.
- `_op_coherent()` re-verifies after every external collaborator boundary
  (owner query, reserved snapshot, candidate query, `is_reserved`,
  `is_targetable`, `reserve`, post-reserve ownership queries) that the bind
  generation is unchanged, the selector still holds exactly the snapshot deps,
  and both deps still return bool-true `is_bound_to` for the snapshot board.
  Drift before reserve → `-1`, no reservation.
- Post-reserve: proves exact atomic ownership (`get_owner(idx) == owner_id` and
  `get_target_for_owner(owner_id) == idx`, both ints) before returning. On
  drift/failed proof, `_rollback_own()` releases only this operation's exact
  `(idx, owner_id)` entry (never an unrelated/competing reservation) and returns
  `-1`.
- Preserved contention law (same-owner side effect → `-1`, external reservation
  kept, no later candidates queried; different-owner contention → continue) and
  all §9 architecture invariants (no routing, no board/candidate mutation, no
  full-board scan, `is_bound_to(board, reservation_state)` identity seam).

## 5. Adversarial coverage added (validation-first)

`tests/run_tests.gd` → `_run_target_selector_strict_v03_tests()` (registered
after the strict-v2 block). New narrow M15 doubles:
- `tests/support/m15_reservation_double.gd` — full-API RefCounted reservation
  double with forced malformed returns + reserve-lie / drift hooks.
- `tests/support/m15_variant_access.gd` — configurable non-bool `is_targetable`.
- `tests/support/m15_node_access.gd` — method-compatible Node access.
- `tests/support/candidate_index_double.gd` — additive `candidates_force` knob
  for the malformed-container case.

Coverage includes: bind category rejection; access_query scalar/String/
Vector2/Array/Dictionary/Node/plain-RefCounted rejection; non-bool targetability
verdicts (null/int/float/String/Vector2/Object/Array/Dictionary) fail closed;
malformed `get_target_for_owner`/`get_reserved_indices`/`get_candidates`/
`is_reserved`/`reserve`/`get_owner`; non-int candidate entries skipped;
post-reserve ownership proof (stored-nothing / other-target / other-owner /
malformed get_owner); drift-during-reserve rollback; bind re-entry blocked;
ReservationState rebind mid-select fails closed.

## 6. Validation results

- Full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
  → **Total checks: 2941 · Failures: 0 · RESULT: ALL PASS**
  (baseline pre-change was 2892/0; +49 new strict-v2 2nd-stage checks).
- Zero SCRIPT/Parse errors.
- `git diff --check`: clean (only benign LF→CRLF notices).
- Pre-existing renderer-test resource-leak WARNINGs are unchanged and unrelated.

## 7. Scope / governance

- Production changed: `scripts/gameplay/targeting/target_selector.gd` only.
- Tests/support changed: `tests/run_tests.gd`,
  `tests/support/candidate_index_double.gd`, and the three new M15 doubles.
- Not touched: BoardState, ColorCandidateIndex, ReservationState, M19
  dispatcher production; root `tasks.md` checkboxes; `coordination/AUDIT_INDEX.md`;
  any `CHATGPT_*` artifact; legacy H!veAI trackers; `PROJECT.json`/`RULES.md`.
- No self-audit verdict is recorded here; audit disposition is ChatGPT-owned.

## 8. Commits / events

- Start transition: **2df67b2** (`hiveai: CHANGES_REQUIRED -> IN_PROGRESS`),
  pushed `42e2caf..2df67b2`.
- Implementation + AWAITING_AUDIT handoff: recorded at push (see EVENTS.jsonl
  `IN_PROGRESS -> AWAITING_AUDIT` row and the final commit SHA in the pushed
  history; per the non-self-referential final-SHA rule no extra commit is made
  solely to embed this log's own commit SHA).

Handoff state: **AWAITING_AUDIT** (requiredActor CHATGPT).
