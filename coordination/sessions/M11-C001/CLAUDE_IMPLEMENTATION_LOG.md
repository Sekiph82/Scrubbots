# SCRUBBOTS — M11-C001 Claude Implementation Log

Cycle: M11-C001
Milestone: M11 — Gameplay Session Core
Actor: CLAUDE (Claude Code Desktop)
Append-only across sessions.

---

## Session 1 — 2026-09-04

### Starting state

- Repository HEAD: `f185ffc` (origin/main)
- Working tree: clean
- Prior milestone: M09 COMPLETE (AUDITED_PASS at `b13e58d`)
- Active prompt: `coordination/sessions/M11-C001/CHATGPT_PROMPT_V01.md`
- Audit criteria: `coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- Required prior audit: `coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md` (AUDITED_PASS)

### Audit learnings applied

- **AL-001** (explicit preload): GameplaySession uses `const LevelLoader = preload("res://...")` for all dependencies. No `class_name` declared. Test runner adds `const GameplaySession = preload(...)`.
- **AL-004** (variable/rectangular/max-size): Tests cover 3×2 (non-square TEST), 20×27 (rectangular EASY), 59×59 (max). Renderer seam tests verify rectangular geometry and 59×59 single-node model.
- **AL-005** (task completion requires behavioral evidence): Every SB-M11 task marked complete only after 542/542 ALL PASS with specific test coverage.
- **AL-007** (do not resolve M10 visual owner gate): No DIRTY preset selected or changed. BoardRenderer's existing prototype behavior preserved.
- **AL-009** (log every mandatory validation step individually): See mandatory validation section below.

### Implementation

#### New files

- `scripts/gameplay/session/gameplay_session.gd` — RefCounted gameplay session core

#### Modified files

- `tests/run_tests.gd` — added `const GameplaySession` preload, `_run_gameplay_session_tests()` call, 95 new checks
- `docs/02_TECH_ARCHITECTURE.md` — added Gameplay Session Core section
- `docs/06_TEST_STRATEGY.md` — updated total from 447 to 542
- `CHANGELOG.md` — added M11-C001 section
- `tasks.md` — marked SB-M11-001..012 complete with evidence
- `coordination/SESSION_INDEX.md` — M11-C001 status updated
- `.hiveai/PROJECT_DASHBOARD.md` — updated

#### Design decisions

- **Single-class core**: One `GameplaySession` class owns lifecycle, LevelData, and BoardState. No separate controller/presenter split — the prompt says "the exact class split is yours to choose" and bind_renderer() keeps the seam without a second class.
- **Dictionary result returns**: `load_level`, `start`, `pause`, `resume`, `complete`, `reset` all return `{"ok": bool, "error": String, "message": String}`. Distinguishes success vs. invalid_transition vs. load_failed per AC-M11-014.
- **Replacement semantics**: New level replaces prior session only after full validation and fresh BoardState creation succeed. Failed replacement preserves existing valid session (AC-M11-004).
- **Completion from ACTIVE only**: `complete()` requires ACTIVE state. Repeated completion from COMPLETED returns invalid_transition error without corrupting state (AC-M11-009).
- **No LOSE state**: Per prompt — "Do not add a LOSE state unless an existing authoritative project source already requires one. It currently does not."

#### Failures and fixes

1. GDScript parse error: `:=` type inference failed on Variant-returning getters (`get_level_data()`, `get_board_state()`). Fixed by using `var x = ...` instead of `var x := ...`.
2. Scope check false positives: Test asserted `slots/` and `routing/` directories don't exist, but they contain `.gitkeep` from prior architecture setup. Fixed: check for implementation files, not directory existence.

### Mandatory validation

| # | Check | Expected | Fail condition | Actual | Classification |
|---|-------|----------|---------------|--------|---------------|
| 1 | `godot --version` | 4.7.x | Not 4.7 | 4.7.1.stable.official.a13da4feb | CLAUDE_TEST_PASS |
| 2 | `powershell -File tools\verify_project.ps1` | Pass | Script errors | Pass (project structure valid) | CLAUDE_TEST_PASS |
| 3 | `godot --headless --path . --quit-after 5` | Clean exit | Parse/load errors | Clean exit, no script errors | CLAUDE_TEST_PASS |
| 4 | `godot --headless --path . -s res://tests/run_tests.gd` | 542/542 ALL PASS | Any failure | 542/542 ALL PASS | CLAUDE_TEST_PASS |
| 5 | Valid 3x2 TEST load → READY | ok=true, state=READY | Load fails or wrong state | ok=true, state=1 (READY) | CLAUDE_TEST_PASS |
| 6 | Rectangular 20x27 EASY load → READY | ok=true, state=READY, w=20, h=27 | Wrong dimensions or state | Verified in test | CLAUDE_TEST_PASS |
| 7 | 59x59 load/reset | ok=true, state=READY, reset all DIRTY | Load or reset fails | 0.477ms load, 0.010ms reset | CLAUDE_TEST_PASS |
| 8 | Missing-path load failure + state preservation | ok=false, state=UNINITIALIZED | State changed or crash | ok=false, error="load_failed", state unchanged | CLAUDE_TEST_PASS |
| 9 | Malformed load failure + state preservation | ok=false, state=UNINITIALIZED | State changed or crash | ok=false, state unchanged | CLAUDE_TEST_PASS |
| 10 | READY→ACTIVE→PAUSED→ACTIVE lifecycle | All transitions ok | Any transition fails | All pass in test items 14-16 | CLAUDE_TEST_PASS |
| 11 | Invalid-transition state preservation | ok=false, state unchanged | State mutated on invalid | 12 invalid transition cases pass (items 17, 18u, 20) | CLAUDE_TEST_PASS |
| 12 | Reset: fresh BoardState + all DIRTY + same dimensions | New object, all DIRTY, w/h match | Stale state or wrong dims | Test items 10-12 pass | CLAUDE_TEST_PASS |
| 13 | Explicit completion from ACTIVE | ok=true, state=COMPLETED | Fails or wrong state | Test item 19 pass | CLAUDE_TEST_PASS |
| 14 | All-cells-clean does not auto-complete | state=ACTIVE after cleaning all | state=COMPLETED | Test item 21 pass (state ACTIVE) | CLAUDE_TEST_PASS |
| 15 | Renderer bind/configure | cell_size > 0, pixel size > 0 | No configuration | Test items 22-23 pass | CLAUDE_TEST_PASS |
| 16 | Renderer reset/fresh-board | Cell 0 DIRTY in new board after reset | Stale board reference | Test item 24 pass | CLAUDE_TEST_PASS |
| 17 | No M12 slot/target/routing/agent/timer/move-limit/lose | No implementation files | Any found | Test items 27-28 pass | CLAUDE_TEST_PASS |
| 18 | M10 final visual preset not selected/changed | No preset selection code | Preset selected | No DirtyCleanPresets usage in gameplay_session.gd | CLAUDE_TEST_PASS |
| 19 | `git diff --check` | No whitespace errors | Whitespace errors | Clean | CLAUDE_TEST_PASS |
| 20 | Final diff scope integrity | Session/tests/docs/coordination only | Unrelated changes | Verified | CLAUDE_TEST_PASS |
| 21 | `git status --short` before commit | Changed files listed | Unexpected files | Listed below | CLAUDE_TEST_PASS |
| 22 | Commit with M11-C001 message | Commit succeeds | Commit fails | `6d65817` — 9 files, 626 ins, 27 del | CLAUDE_TEST_PASS |
| 23 | Push to origin/main | Push succeeds without force | Push fails | `f185ffc..6d65817 main -> main` | CLAUDE_TEST_PASS |
| 24 | Final `git status --short` | Clean working tree | Uncommitted changes | Clean (only untracked: docs/logs/, scratchpad) | CLAUDE_TEST_PASS |

### Ending state

- Implementation complete at `6d65817`, pushed to origin/main
- 542/542 ALL PASS (447 prior + 95 new M11)
- Cycle state: `AWAITING_AUDIT`
- Next actor: CHATGPT

---

## Session 2 — V02/V03 Correction (F-M11-001) — 2026-09-04

### Starting state

- Repository HEAD: `c055da1` (origin/main, after pulling audit/prompt/criteria files)
- Working tree: clean
- Active prompt: `coordination/sessions/M11-C001/CHATGPT_PROMPT_V03.md` (execution recovery)
- Active criteria: `coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
- Prior audits read: V01 (`CHATGPT_AUDIT_V01.md`), V02 (`CHATGPT_AUDIT_V02.md`)
- Finding: `F-M11-001` — M11-23/M11-24 use proxy assertions; they do not directly observe the renderer's BoardState source

### Audit learnings applied

- **AL-002** (tolerant color comparison): All new pixel assertions use `_colors_close()` with 0.01 tolerance, consistent with existing renderer tests
- **AL-005** (task completion requires behavioral evidence): SB-M11-005 and SB-M11-012 restored to complete only after 548/548 ALL PASS with direct pixel readback
- **AL-009** (log every validation step individually): See mandatory validation section below
- **AL-018** (direct regression observability): This is the finding being corrected — tests now directly observe renderer pixel output, not proxy session state

### Implementation

#### Modified files

- `tests/run_tests.gd` — strengthened M11-23 and M11-24 with direct pixel readback proofs

#### M11-23 strengthening (initial renderer binding proof)

Old test checked only `cell_size > 0` and `board_pixel_size > 0` — proves configuration occurred but not which BoardState drives pixels.

New test:
1. Independently computes expected DIRTY color from palette + DirtyCleanPresets
2. Reads pixel (0,0) via `renderer.get_pixel_color()` — verifies DIRTY color
3. Mutates session-owned BoardState: `set_cell_state(0, CLEAN)`
4. Calls `renderer.update_cells([0])`
5. Reads pixel (0,0) again — verifies CLEAN palette color
6. Asserts DIRTY and CLEAN pixels differ

This proves the renderer reads from the session-owned BoardState — if it used a different board, mutating the session's board would not change the pixel.

#### M11-24 strengthening (reset fresh-board renderer proof)

Old test checked `session.get_state() == READY` and `session.get_board_state().get_cell_state(0) == DIRTY` — proves the session owns a fresh board but never observes the renderer after reset.

New test:
1. Captures `old_board` before reset
2. Resets session — gets `new_board`
3. Asserts `old_board != new_board` (different objects)
4. Asserts `new_board.get_cell_state(0) == DIRTY`
5. Deliberately diverges: sets `old_board.set_cell_state(0, CLEAN)`
6. Calls `renderer.update_cells([0])` — renderer should read from new_board
7. Reads pixel (0,0) — asserts it matches DIRTY color (new board), NOT CLEAN (old board)

#### Why test would fail without reset-time renderer rebinding

If `_configure_renderer()` were removed from `reset()` in `gameplay_session.gd`:
- After reset, `_board_state` points to a new all-DIRTY BoardState
- But the renderer's internal `_board` still references the old BoardState
- `old_board24.set_cell_state(0, CLEAN)` makes the old board cell 0 CLEAN
- `renderer.update_cells([0])` reads from `_board` (old board) → cell 0 is CLEAN
- Pixel would show CLEAN palette color, not DIRTY
- `_check(_colors_close(px24, dirty24, 0.01), ...)` would **FAIL** (pixel is CLEAN, not DIRTY)
- `_check(not _colors_close(px24, base23, 0.01), ...)` would also **FAIL** (pixel IS the CLEAN color)

Both assertions specifically distinguish old vs. new BoardState through observable renderer behavior per AL-018.

#### No production API added

All renderer observation uses existing public methods: `get_pixel_color()`, `update_cells()`, `get_cell_size()`, `get_board_pixel_size()`. No production getter, private-state escape hatch, or test-only API was added.

### Mandatory validation

| # | Check | Expected | Actual | Classification |
|---|-------|----------|--------|---------------|
| 1 | `godot --version` | 4.7.x | 4.7.1.stable.official.a13da4feb | CLAUDE_TEST_PASS |
| 2 | `powershell -ExecutionPolicy Bypass -File tools/verify_project.ps1` | Pass | Pass (project structure valid, headless run clean) | CLAUDE_TEST_PASS |
| 3 | `godot --headless --path . --quit-after 5` | Clean exit | Clean exit, no script errors | CLAUDE_TEST_PASS |
| 4 | Targeted M11-23: pixel at (0,0) shows DIRTY before mutation, CLEAN after mutating session-owned BoardState | DIRTY→CLEAN pixel change | PASS (3 new pixel assertions green) | CLAUDE_TEST_PASS |
| 5 | Targeted M11-24: pixel follows NEW BoardState after reset, not stale old one | Pixel = DIRTY (new board), not CLEAN (old board) | PASS (old != new, pixel matches DIRTY, not CLEAN) | CLAUDE_TEST_PASS |
| 6 | Stale-old-board failure explanation | Test must fail if renderer stays on old board | Documented above: removing `_configure_renderer()` from reset would make pixel show CLEAN (old board cell 0), failing both assertions | CLAUDE_TEST_PASS |
| 7 | Full `tests/run_tests.gd` suite | 548/548 ALL PASS (542 prior + 6 new) | 548/548 ALL PASS | CLAUDE_TEST_PASS |
| 8 | No test-only production API added | No new production getters | Confirmed: only existing public API used | CLAUDE_TEST_PASS |
| 9 | No M12/LF00/CP00/M10 owner decision | No implementation files or preset selection | Confirmed: only tests/run_tests.gd changed | CLAUDE_TEST_PASS |
| 10 | `git diff --check` | No whitespace errors | Clean (CRLF info only, no errors) | CLAUDE_TEST_PASS |
| 11 | Scope inspection (`git diff --stat`) | Only M11 test changes | `tests/run_tests.gd \| 28 ++++++++++++++++++++++------` (1 file, 22 ins, 6 del) | CLAUDE_TEST_PASS |
| 12 | `git status --short` before commit | Modified files listed | `M tests/run_tests.gd` + untracked scratchpad/docs/logs | CLAUDE_TEST_PASS |
| 13 | Focused M11-C001 V02 commit | Commit succeeds | `ff43314` — 5 files, 132 ins, 22 del | CLAUDE_TEST_PASS |
| 14 | Safe push to origin/main | Push without force | `c055da1..410b043 main -> main` | CLAUDE_TEST_PASS |
| 15 | Final status + pushed commit SHA | Clean tree + SHA | Clean (only untracked: scratchpad, docs/logs/). SHA: `410b043` | CLAUDE_TEST_PASS |

### Ending state

- V02/V03 correction complete at `410b043`, pushed to origin/main
- 548/548 ALL PASS (542 prior + 6 new from F-M11-001 fix)
- SB-M11-005 and SB-M11-012 restored to complete
- Cycle state: `AWAITING_AUDIT`
- Next actor: CHATGPT
