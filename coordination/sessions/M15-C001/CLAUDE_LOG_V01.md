# M15-C001 — CLAUDE_LOG_V01

Cycle: **M15-C001** — TargetSelector
Prompt: `coordination/sessions/M15-C001/CHATGPT_PROMPT_V01.md` (V01)
Handoff state: **AWAITING_AUDIT**
Actor: Claude (implement + test only; no self-audit; no tracker/tasks edits)

---

## 1. Sync & baseline

- Starting `origin/main` SHA: `b0ec470d048ef41ff68f84f414ef35fb4bb32f6d`
- Local `main` fast-forwarded to `origin/main` (`b6b2408..b0ec470`, ff-only, no
  merge commit). No destructive op used (no reset --hard / clean -fd / force).
- Owner working-tree change **preserved and not staged**: `project.godot`
  (pre-existing owner modification). Verified `origin/main` does not touch
  `project.godot`, so ff was safe (AL-026 / preserve-pre-existing-tracked-work).
- Godot: `4.7.1.stable.official.a13da4feb`.
- Baseline suite before any change: **1098 checks, 0 failures, ALL PASS**.

## 2. Files changed (exact)

New (M15):
- `scripts/gameplay/targeting/target_selector.gd` — TargetSelector.
- `tests/support/access_query_double.gd` — injectable access-query test double
  (observes queried indices; optional race side-effect).
- `tests/support/candidate_index_double.gd` — candidate-index double for
  stale/invalid raw-candidate injection.

Modified:
- `tests/run_tests.gd` — 3 preloads, 3 registrations, 3 test sections
  (`_run_target_selector_tests`, `_run_target_selector_simultaneous_tests`,
  `_run_target_selector_benchmark`) + 2 board-snapshot helpers.
- `docs/01_GAMEPLAY_SPEC.md` — current-law note: M15 enforces candidate-vs-
  reachable via injected access truth, fails closed.
- `docs/02_TECH_ARCHITECTURE.md` — seam status M15 implemented + new
  TargetSelector section.
- `docs/05_TECH_DECISIONS.md` — new **ADR-023** (select-and-reserve + injected
  access seam).

Not staged (owner/local): `project.godot`; untracked `_owner_inbox` refs,
`*.uid` (not tracked in this repo), `docs/logs/`, scratchpad. `.uid` files are
Godot editor cache and intentionally not committed (rule 21).

## 3. Dependency / API design (SB-M15-001, SB-M15-002)

`extends RefCounted`, explicit `preload()` (AL-001, ADR-009).

- `create() -> RefCounted`
- `bind(board, candidate_index, reservation_state) -> bool` — rejects any null
  dependency, stays unbound on failure.
- `is_bound() -> bool`
- `select_and_reserve(color_id, owner_id, access_query) -> int`

Narrow dependencies only:
1. `BoardState` — **final validation only** (`is_valid_index`,
   `get_cell_state`, `get_color_id`). No full-board scan, no array
   duplication, no mutation, no index-math re-derivation, no lifecycle
   ownership (SB-M15-002).
2. `ColorCandidateIndex` — raw ascending candidates via `get_candidates`
   (returns detached copy; never mutated).
3. `ReservationState` — atomic ownership via public `reserve()` /
   `get_reserved_indices()` / `get_target_for_owner()` only; internals never
   touched directly (crit 32).
4. `access_query` — per-call injected reachability truth.

## 4. Access-query seam & fail-closed (SB-M15-006)

- Duck-typed contract: `access_query.is_targetable(index) -> bool`.
- Selector **fails closed** (returns -1) when `access_query` is null OR lacks
  `is_targetable()`. No raw color candidate is ever assumed reachable
  (AL-028). See ADR-023.
- Selector computes no route geometry, runs no AStar, inspects no route
  points, invents no topology (SB-M15-009).

## 5. Deterministic strategy (SB-M15-003)

First targetable candidate in **ascending row-major candidate order**. Per
candidate, in order: valid index → ACTIVE → matching color → unreserved →
`access_query.is_targetable()` → atomic `ReservationState.reserve()`. On a lost
reserve (competing synchronous assignment), continue to the next candidate for
the still-unassigned owner. No random/distance/route-length scoring; no hidden
fallback.

## 6. Selection + reservation as one operation

`select_and_reserve()` chooses and reserves inside one synchronous call — no
`choose() … reserve()` gap (prompt §"Why…", ADR-023). Main-thread synchronous;
competing calls serialize, exactly one wins a contested target (final gate is
M14 `reserve()`).

## 7. Task-by-task evidence (SB-M15-001..012)

| Task | Evidence (test ids in `tests/run_tests.gd`) |
|------|---------------------------------------------|
| SB-M15-001 Create TargetSelector | M15-01 create/bind; file exists; suite loads/runs |
| SB-M15-002 Narrow BoardState access | M15-08/09/10 final-validation filters stale wrong-color/CLEARED/invalid; M15-22 no BoardState mutation |
| SB-M15-003 Deterministic strategy | M15-06 first ascending; M15-25 identical→identical; M15-30 rectangular row-major |
| SB-M15-004 Match color | M15-06 color match; M15-08 wrong-color skipped; M15-15 no-bucket color → -1 |
| SB-M15-005 Never target CLEARED | M15-09 CLEARED candidate skipped even when injected stale |
| SB-M15-006 Never invalid/blocked/unreachable | M15-10 invalid; M15-18/19/20 blocked via access query; M15-16 fail-closed |
| SB-M15-007 Respect reservations | M15-11 reserved skipped; M15-14 all reserved → -1; M15-13 owner already holds → -1; M15-12 reservation created |
| SB-M15-008 Return no-target cleanly | M15-03/04/05/13/14/15/16/19/20 all return -1, no dispatch/exception |
| SB-M15-009 No route generation | M15-24 no route/pathfinding method exposed; source has none |
| SB-M15-010 Determinism tests | M15-06/25/28/30 |
| SB-M15-011 Simultaneous assignment | M15-27 exactly one wins; M15-28 unique+ordered; M15-29 lost-reserve continues |
| SB-M15-012 3481-cell benchmark | M15-31/32/40 (see §10) |

## 8. Negative-test evidence (AL-011 isolation)

Each negative test isolates one failure mode: unbound (M15-03), null deps
(M15-02), null/methodless access_query (M15-16), invalid owner (M15-05),
invalid color (M15-04), owner-already-holds (M15-13), all-reserved (M15-14),
no-candidates (M15-15), wrong-color/CLEARED/invalid stale (M15-08/09/10),
all-blocked / enclosed AL-028 (M15-19/20). M15-16/21 confirm failed/invalid
calls create **no** reservation.

## 9. AL-018 direct-observability evidence

`AccessQueryDouble` records every queried index and count. Tests assert on the
actual query trace, not a proxy:
- M15-18: `was_queried(0/1/2)` true (blocked prefix consulted in order),
  `was_queried(3)` false (iteration stopped at the selected candidate).
- M15-08/09/10: `was_queried(1/2/99)` false — stale wrong-color/CLEARED/invalid
  candidates are rejected by BoardState final-validation **before** the access
  query, proving order and that access truth is not a proxy for validation.
- M15-20: `total_queries() >= 1` before the all-blocked give-up.
`CandidateIndexDouble` proves BoardState final-validation independently of the
real index.

## 10. Simultaneous-assignment evidence (SB-M15-011)

- M15-27: 19 owners race one reachable target → exactly 1 success, exactly 1
  reservation.
- M15-28: 3 candidates, 3 owners by call order → targets 0,1,2 (unique,
  ascending); 4th owner → -1.
- M15-29: side-effect on the first access query reserves target 0 for a
  competing owner (999) between targetable-check and reserve; selector's
  reserve on 0 loses, continues, and the unassigned owner takes target 1.
  Asserts `get_owner(0)==999`, `get_owner(1)==10`.

## 11. 59×59 / 3481-cell performance evidence (SB-M15-012)

Board 59×59 all color 0, all ACTIVE. CPU/selection timing only — **no FPS/GPU
claim** (AL-003).

```
candidate count for tested color: 3481
bounded-iteration select (100 blocked prefix): 101 access-query calls (chose index 100)
select_and_reserve x500 (first-candidate): ~2.1 ms total, ~0.0043 ms/select
access-query calls over sample: 500 (== 500 selects, one per call)
```

- M15-40: with a 100-blocked prefix, access queries == **101** (prefix+1),
  `< 3481` → iterates color candidates, **not** the whole board (crit 40).
- M15-32: 500 first-candidate selects → exactly 500 access queries (1/call) →
  no per-call full-board scan.

## 12. Rectangular coverage (AL-004)

M15-30 uses a 5×2 (w≠h) board; color-5 cells at row-major indices 1,7,9 select
in ascending order across rows. Additional rectangular boards used throughout
(3×1, 4×1, 2×1). 59×59 max-size benchmark present.

## 13. Non-mutation / no-leak (AL-020)

- M15-22: BoardState cell states identical before/after selection.
- M15-23: `ColorCandidateIndex.get_candidates()` identical before/after.
- Selector owns no mutable collection it returns (no state leak). It mutates
  only `ReservationState` via public `reserve()`.

## 14. Full regression (SB-M15-010 / AL-005 / AL-009)

`godot --headless --path . -s res://tests/run_tests.gd`
→ **Total checks: 1155, Failures: 0, RESULT: ALL PASS**
(baseline 1098 + 57 new M15 checks). `git diff --check`: clean (only CRLF
info warnings, no whitespace errors). Every prompt-mandated material check is
recorded individually above, not only the aggregate green total.

## 15. Locked-contract preservation

Unchanged: 59×59 max; ACTIVE/CLEARED only (no RESERVED); ReservationState
ADR-022; C01..C16 / C16 #000000 / BG01 #202533; five slots; raw candidate ≠
reachable target (AL-028); TargetSelector ≠ RoutingSystem; no one-Node-per-cell.

## 16. Explicit M16+ non-scope confirmation

Not implemented (out of M15 scope): RoutingSystem, AStar/pathfinding, route
geometry/points, collision radius/topology, Scrubbot movement, Dispatcher,
dispatch queue, robot spawning, cell clearing on arrival, M16–M20. M15-24 and
source review confirm the selector exposes no routing API.

## 17. Governance — untouched by Claude

Not created/modified by Claude this cycle: `tasks.md`, `.hiveai/ACTIVE_CYCLES.md`,
`.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md`,
`.hiveai/PROJECT_DASHBOARD.md`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, any `CHATGPT_AUDIT_*`. No self-audit performed.

## 18. Commit / push

- Commit: see push receipt below (this log recorded pre-commit; final SHA not
  self-referenced per the non-self-referential-final-SHA rule).
- Push: to `origin/main`, non-destructive.

Handoff: **AWAITING_AUDIT**. Stop.
