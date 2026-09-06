# M14-C001 — Claude Implementation Log V01

Cycle: **M14-C001** (Reservation State) — first implementation cycle of M14.
Prompt: `coordination/sessions/M14-C001/CHATGPT_PROMPT_V01.md`
Audit criteria: `coordination/sessions/M14-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Handoff state: **AWAITING_AUDIT**

## SHAs

- Starting `origin/main` SHA (synced to): `c01fbc6aee28453d875079be335fbee8c082baa9`
- Pre-implementation local HEAD: `fc66277` → fast-forwarded to `c01fbc6`.
- Implementation commit SHA: recorded in the GitHub push receipt for this cycle
  (non-self-referential final-SHA rule; this log holds pre-commit evidence).

## Safe sync

- `git fetch origin`; local was behind by 14, ahead by 0.
- Verified the 14 incoming commits do NOT touch `project.godot` (owner had an
  uncommitted trivial editor reformat/reorder of `project.godot`).
- `git merge --ff-only origin/main` → fast-forward `fc66277..c01fbc6`.
- No `reset --hard`, `clean -fd`, `restore`, `checkout --`, or force used.
- Owner work preserved: `project.godot` (M) and all untracked owner assets
  (`_owner_inbox/*.import`, `*.uid`, `docs/logs/`, scratchpad) untouched and
  NOT staged.

## Architecture decision (ADR-022)

Reservation is a **separate ephemeral assignment layer**, NOT a cell state.

- New module `scripts/gameplay/targeting/reservation_state.gd` (extends
  `RefCounted`, explicit-preload convention per AL-001 / ADR-009).
- `BoardState.CellState` remains exactly `{ ACTIVE = 0, CLEARED = 1 }` — no
  `RESERVED` added. This formally resolves deferred gate **SB-M02-017**: the
  reservation architecture is now designed, and the decision is that RESERVED
  does not belong in the physical cell lifecycle.
- Ownership token: deterministic integer `owner_id >= 0`, standing for one
  future dispatch/agent assignment — not a color/slot/cell id.
- Invariants enforced: one target ≤ one owner; one owner ≤ one target;
  synchronous check-and-set `reserve()` with no await/deferred gap.
- `resolve_arrival()` clears only the reservation, never the BoardState cell.
- ColorCandidateIndex (M13) stays reservation-agnostic; callers pass
  `get_reserved_indices()` as the exclusion set. TargetSelector (M15) will
  *consume* exclusions but not own them; dispatcher/agent (M18/M19) is the
  caller supplying owner tokens.
- ADR text: `docs/05_TECH_DECISIONS.md` → **ADR-022** (next available; latest
  prior was ADR-021).

## Changed files

Staged for this cycle:
- `scripts/gameplay/targeting/reservation_state.gd` (new — the M14 module)
- `tests/run_tests.gd` (M — +3 test functions, preload const, registration)
- `docs/05_TECH_DECISIONS.md` (M — ADR-022)
- `docs/02_TECH_ARCHITECTURE.md` (M — ReservationState section)
- `docs/01_GAMEPLAY_SPEC.md` (M — stale M10-QA-open wording → complete)
- `CLAUDE.md` (M — rule 34 stale M10-QA-open wording → complete)
- `coordination/sessions/M14-C001/CLAUDE_LOG_V01.md` (this log)

Explicitly NOT staged (owner/local/generated): `project.godot`, all `*.uid`,
all `*.import`, `_owner_inbox/*`, `docs/logs/`, scratchpad temp.

## Reservation module API

`create()`, `bind(board)`, `rebind(board)`, `is_bound()`,
`reserve(target,owner)->bool`, `is_reserved(target)->bool`,
`get_owner(target)->int` (-1 if none), `get_target_for_owner(owner)->int`
(-1 if none), `release(target,owner)->bool`, `release_for_owner(owner)->bool`,
`resolve_arrival(target,owner)->bool`, `reset()`,
`get_reserved_indices()->PackedInt32Array` (detached, ascending),
`get_reservation_count()->int`.

All reserve/lookup/release ops are O(1) average via two mirrored dictionaries
(`_target_to_owner`, `_owner_to_target`). No full-board scan on any normal
reservation query. `get_reserved_indices()` returns a fresh detached copy.

## Test commands + results

```
godot --version
  4.7.1.stable.official.a13da4feb

godot --headless --path . -s res://tests/run_tests.gd
  Total checks: 1098   (baseline before M14 was 1031; +67 M14 checks)
  Failures: 0
  RESULT: ALL PASS
  No SCRIPT ERROR / parse error / runtime error.

git diff --check
  exit 0 (only informational LF→CRLF warnings on files Git touches)
```

## M14 task-by-task evidence (test IDs in `tests/run_tests.gd`)

- **SB-M14-001 reservation ownership** — integer `owner_id>=0` token; invariants
  tested M14-04/08/09/10/11; invalid owner rejected M14-07.
- **SB-M14-002 RESERVED in CellState or separate?** — decided SEPARATE; proven
  M14-29 (`CellState.keys()==["ACTIVE","CLEARED"]`, no RESERVED).
- **SB-M14-003 ADR** — ADR-022 recorded.
- **SB-M14-004 reserve atomically** — synchronous check-and-set; M14-04 success,
  M14-28 contested-target race (exactly one of 50 owners wins).
- **SB-M14-005 prevent double reservation** — M14-08 (other owner), M14-09
  (same owner same target), M14-10 (owner second target).
- **SB-M14-006 release on dispatch failure** — M14-17 reserve→fail→release→
  reservable-again lifecycle; wrong-owner release M14-14; correct M14-15.
- **SB-M14-007 release on reset** — M14-18 reset clears all, keeps binding;
  M14-19 rebind clears old-board reservations.
- **SB-M14-008 resolve arrival** — M14-20 succeeds once, M14-21 wrong owner
  fails, M14-22 second resolution fails, M14-23 does NOT mutate BoardState cell.
- **SB-M14-009 concurrency tests** — M14-28 simultaneous-assignment race proves
  exactly one reservation succeeds; integration M14-26/27/28b prove M13
  exclusion seam and reservation-agnosticism.
- **SB-M02-017** — formally resolved by ADR-022 (RESERVED stays out of
  CellState); proven by M14-29.

Other criteria: detached/ascending indices M14-24/25; is_reserved/get_owner/
owner→target truth M14-12/13; independent owners M14-11.

## ColorCandidateIndex integration evidence

`_run_reservation_state_integration_tests()`:
- M14-26: reserved indices `[2,4]` excluded from color-7 candidates only via
  `idx.get_candidates(7, res.get_reserved_indices())`.
- M14-28b: without exclusions, ColorCandidateIndex still returns reserved cells
  → it owns no reservation state.
- M14-27: after `release(2,900)` the cell is visible again.
- M13 source (`color_candidate_index.gd`) was NOT modified.

## Performance evidence (59×59 = 3481 cells, all ACTIVE)

`_run_reservation_state_performance()` (representative run):
```
reserve x500:     0.883 ms total, 0.00177 ms/reserve
is_reserved x5000: 1.401 ms total, 0.000280 ms/query
release x500:     0.371 ms total, 0.00074 ms/release
```
O(1) dictionary ops; no per-call full-board scan. 500 reservations on a
3481-cell board stored and released with counts verified (M14-31).

## Scope confirmations

- M15 TargetSelector: NOT implemented.
- M16 routing / M17 prototype / M18 ScrubbotAgent / M19 Dispatcher / M20
  vertical slice: NOT implemented.
- No reachability, route topology, slot-mechanic, or renderer-visual changes.
- Palette, BG01, difficulty bands, 5 slots, BoardRenderer contract unchanged.
- Source content/artwork untouched.

## Governance-file confirmations (untouched by Claude)

- `tasks.md` — untouched.
- `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`,
  `.hiveai/PROGRESS_SNAPSHOT.md`, `.hiveai/PROJECT_DASHBOARD.md` — untouched.
- `coordination/SESSION_INDEX.md` — untouched.
- No self-audit; no `CHATGPT_AUDIT_VNN.md` created.

## Push result

Committed and pushed to `origin/main` safely (no force). See the cycle's
GitHub push receipt for the final commit SHA.

## Handoff

**AWAITING_AUDIT.**
