# SCRUBBOTS — MASTER TASK PLAN

Permanent master execution roadmap for the SCRUBBOTS project. This file is
authoritative alongside `CLAUDE.md`. Read both at the start of every
session. Update this file after every numbered implementation prompt.

Canonical local project: `C:\Users\sekip\Desktop\ScrubBots`
Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Primary branch: `main`

Verified at time of writing (end of Phase M06):
- HEAD commit at phase start: `89c7d43` ("feat: enforce Scrubbots
  difficulty board ranges") — see `docs/05_TECH_DECISIONS.md` and
  CHANGELOG for the Phase M06 commit that follows it.
- Working tree: clean, `main` up to date with `origin/main`
- Godot: `4.7.1.stable.official.a13da4feb` (installed, `godot --version` confirmed)
- Headless test suite (`tests/run_tests.gd`): **227/227 checks PASS**, exit
  code 0 (73 Prompt 02 + 58 Phase M03 + 96 Phase M06)
- Official production difficulty bands (Easy/Medium/Hard/Very_Hard,
  20..59, max 59×59 = 3,481 cells) implemented and enforced via
  `DifficultyRules` + `ProductionLevelValidator`, kept separate from the
  generic dimension-agnostic `LevelValidator`/`BoardState` core.
- `BoardRenderer` implemented (single Image/ImageTexture, zero per-cell
  Nodes at any board size — ADR-011) with a DIRTY/CLEAN visual prototype
  (`DirtyCleanPresets` A/B/C). **Final DIRTY visual style is an open design
  gate — not approved** (see M10).

## Status tags

```text
[x]  = completed AND validated (evidence exists: ran, passed, inspected)
[ ]  = incomplete / not validated
```

A task is never `[x]` merely because code exists somewhere. It must have
been run/validated. Additional tags used throughout:

```text
[LOCKED]            — owner-specified rule, do not silently change
[DESIGN GATE]       — unresolved, owner must decide, do not invent
[TECH DECISION]     — architecture choice, see docs/05_TECH_DECISIONS.md
[PERFORMANCE]       — has a performance-sanity dimension
[CONTENT]           — real art/level content work
[VISUAL REFERENCE]  — depends on owner-supplied visual assets
[QA]                — verification/testing work
[DEFERRED]          — intentionally postponed, not blocked
```

---

## GLOBAL DEFINITION OF DONE

A milestone is complete only when **all** relevant conditions below are
satisfied. If a required validation could not run, the milestone is **not**
complete — record why instead of marking `[x]`.

- Implementation exists.
- Code parses in the actual installed Godot version (currently 4.7.1-stable).
- Headless tests pass where applicable.
- Invalid input is tested, not just the happy path.
- Regression tests (everything previously passing) remain passing.
- No fatal Godot errors in headless/editor output.
- Warnings are understood or fixed, not ignored.
- Relevant performance sanity tests are executed and results recorded.
- The 59×59 (3,481-cell) maximum production workload is considered wherever
  cost scales with board size.
- Documentation reflects the actual implementation, not an aspirational one.
- `tasks.md` is updated to reflect true status.
- `git diff` is reviewed before commit.
- No cache/build junk (`.godot/`, import cache, build output) is committed.
- A focused, understandable commit exists.
- Push to `origin/main` succeeds when possible (never force-pushed).
- The current phase's Desktop log (see "PHASE LOG WORKFLOW" below) is
  updated to reflect the work.

---

## PERMANENT CLAUDE SESSION WORKFLOW

Every future numbered implementation prompt must:

1. Read `CLAUDE.md`.
2. Read `tasks.md` (this file).
3. Read relevant `docs/` files for the system being touched.
4. Inspect `git status` / branch / remote.
5. Confirm which milestone is actually current (don't assume from memory).
6. Preserve owner files and artwork — never delete/regenerate without cause.
7. Work only on the requested scope — no drive-by rewrites.
8. Reuse existing systems (`LevelData`, `BoardState`, etc.) where appropriate
   — do not rebuild working systems for stylistic reasons.
9. Run current regression tests before major modification when practical.
10. Implement the requested milestone.
11. Add/update tests.
12. Run headless validation (`godot --headless --path . -s res://tests/run_tests.gd`).
13. Fix regressions.
14. Run relevant performance sanity tests.
15. Update `docs/`.
16. Update `tasks.md`.
17. Review `git diff`.
18. Commit (focused, descriptive message).
19. Push safely (`git push origin main`, never force).
20. Never force-push.
21. Update the current phase's Desktop log (see "PHASE LOG WORKFLOW" below)
    — **never committed** to this repository.

---

## PHASE LOG WORKFLOW (supersedes the old per-prompt handoff-log convention)

**One development phase = one continuous Desktop log file**, not one log
per prompt. A "phase" is a milestone-level unit of work (e.g. `M03`, `M04`)
that may span multiple Claude prompts/sessions.

- Naming: `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` (e.g.
  `SCRUBBOTS_PHASE_M03_LOG.md`). `MXX` matches the `tasks.md` milestone ID
  the work belongs to.
- **Create the log file at the START of the phase's first prompt**, before
  any inspection or code changes — not at the end.
- If the log file already exists for the current phase, **read it and keep
  updating the same file** — never create a second log for the same phase
  (no `_RETRY`, no `_B`, no `PROMPT_03B` variants). Every prompt working on
  the same phase reuses the same file.
- Update it after every meaningful checkpoint: environment/repo inspection,
  baseline tests, architecture decisions, each implementation step,
  fixtures added, test-suite changes, each significant failure/debugging
  discovery, final tests, before commit, after commit, after push. The log
  must let another agent resume work correctly even if the session stops
  unexpectedly mid-phase.
- Keep the chronological journal/history in the log even after issues are
  fixed — do not erase past failures once resolved.
- When the phase is genuinely complete, set `PHASE STATUS: COMPLETE` and
  fill in the Final Phase Summary section — without deleting the earlier
  chronological content.
- Only start a **new** log file when moving to a genuinely new phase (e.g.
  `M03` complete, `M04` begins).
- The phase log is **never committed** to the Scrubbots Git repository — it
  lives only on the Desktop.

Prompts 01 and 02 predate this convention and used one-log-per-prompt
(`SCRUBBOTS_PROMPT_01_LOG.md`, `SCRUBBOTS_PROMPT_02_LOG.md`) — those are
historical and not retroactively merged. `SCRUBBOTS_MASTER_TASKS_LOG.md`
(the master-plan prompt) also predates this convention. Starting with
Phase M03, use the phase-log format above.

---

## LOCKED GAME RULES

These rules override older documentation where a conflict exists. They are
not open for silent reinterpretation.

### 8.1 — Mobile-first `[LOCKED]`

SCRUBBOTS is mobile-first. Primary orientation: **portrait**. Current
provisional virtual design resolution: **1080×1920** (see ADR-002 in
`docs/05_TECH_DECISIONS.md`). Gameplay code must remain independent of
physical phone resolution — this is a display setting, not gameplay logic.

### 8.2 — Variable-size logical board `[LOCKED]`

The board engine remains **variable-size**. It must never become a fixed
40×40, 50×50, 1600-cell, 2500-cell, or 3481-cell engine. Board dimensions
come from level data. Generic code uses `width`, `height`, `width * height`
— never a hard-coded cell count. See ADR-008.

### 8.3 — Official difficulty / board size bands `[LOCKED]`

Official SCRUBBOTS production rules, established in this planning prompt
(supersedes the Prompt 02-era "40×40 standard / 50×50 Very Hard" framing,
which under-specified the actual required range):

| Difficulty | Width range | Height range | Min cells | Max cells |
|---|---|---|---|---|
| EASY | 20–29 | 20–29 | 20×20 = 400 | 29×29 = 841 |
| MEDIUM | 30–39 | 30–39 | 30×30 = 900 | 39×39 = 1521 |
| HARD | 40–49 | 40–49 | 40×40 = 1600 | 49×49 = 2401 |
| VERY_HARD | 50–59 | 50–59 | 50×50 = 2500 | 59×59 = **3481** |

Examples of valid boards: Easy `20×27`, Medium `34×39`, Hard `48×41`,
Very Hard `53×59`.

**Current required production maximum: 59×59 = 3,481 logical cells.**

### 8.4 — Rectangular boards `[LOCKED]`

Boards do **not** have to be square. Width and height are validated
independently against the same difficulty band. Never assume
`width == height` in generic systems.

Valid: Easy `20×27`, Medium `34×39`, Hard `48×41`, Very Hard `53×59`.
Invalid: Easy `20×30`, Medium `39×40`, Hard `49×50`, Very Hard `49×59` —
each has one dimension outside its band.

### 8.5 — Current maximum required workload `[LOCKED]`

`59×59 = 3,481` cells. All systems whose cost scales with board size must
eventually be tested against this workload: LevelData validation,
BoardState, BoardRenderer, cell eligibility, target selection,
routing-related board queries, cleaning updates, save/load of level state
if used, and production content validation.

### 8.6 — Test/dev fixtures vs. production levels `[LOCKED TECHNICAL RULE]`

The existing `test_3x2.json` fixture (6 cells) is valuable because it
proves the board engine is genuinely generic — it is **not** a production
level and must never be treated as one. Production levels obey the
Easy/Medium/Hard/Very-Hard ranges in 8.3. Development fixtures may use a
`TEST` difficulty/context. `TEST` must never become a production difficulty
exposed to players, and the future production `LevelCatalog` must reject
accidental `TEST` fixtures (see M03, M30).

### 8.7 — Logical pixels `[LOCKED]`

One logical artwork square = one logical pixel = one board cell. Logical
cells are game data, never physical display pixels, and are never
represented as thousands of heavyweight Godot Nodes (see ADR-004, ADR-008).

### 8.8 — Five slots `[LOCKED]`

Primary gameplay presentation: **5 slots**. Player-visible gameplay uses
five slots. Internal code may stay configurable where sensible, but the
production game currently requires exactly five visible active slots.

### 8.9 — Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot does not leave if there is no valid cleaning job.
- A Scrubbot has a valid target *before* being dispatched.
- It visually moves from slot to target.
- On arrival it cleans/reveals the target logical pixel.
- It then disappears/finishes.
- It does not collect or carry pixel color.
- It does not return to the slot; no return route is needed.

Scrubbot movement across the picture is one of the most important pieces
of the game's visual identity.

### 8.10 — TargetSelector vs. RoutingSystem `[LOCKED ARCHITECTURE]`

`TargetSelector` answers **WHAT** valid cell should be assigned.
`RoutingSystem` answers **HOW** the Scrubbot travels there visually. Never
combine them. `BoardRenderer` never chooses targets. `ScrubbotAgent` never
searches the board and picks its own arbitrary target. The routing
implementation must remain replaceable (see ADR-005).

### 8.11 — Win streak `[LOCKED]`

```text
1 consecutive win   -> 1
2 consecutive wins  -> 5
3 consecutive wins  -> 10
4 consecutive wins  -> 25
5+ consecutive wins -> 100
```

Never reinterpret `1, 5, 10, 25` as win-count thresholds.

### ADR-009 — Explicit preload() convention `[LOCKED UNTIL EXPLICITLY REVISITED]`

Prompt 02 found bare `class_name` cross-script references unreliable in a
headless environment with no prior editor-built global class cache. The
working solution: `const LevelData = preload("res://scripts/data/level_data.gd")`
instead of relying on global class-name resolution. Future scripts in the
data/gameplay/test core should follow this convention unless a future task
deliberately revisits ADR-009 and proves an alternative equally reliable
via headless tests. Do not casually convert back to bare `class_name` for
stylistic reasons.

---

## VISUAL REFERENCE SYSTEM

SCRUBBOTS has (per the owner) prior artwork and visual concepts. The
project must use them rather than defaulting to generic programmer art —
but **only artwork that physically exists in this project or is supplied
during a task counts as available**. A visual discussed in a prior chat is
not automatically a local file.

**Verified at time of writing**: `assets/art/{characters,levels,ui,effects}/`
are all empty except `.gitkeep` placeholders — no SCRUBBOTS artwork
currently exists inside this repository. Several unrelated images exist on
the user's Desktop (`ChatGPT Image Aug 16...png`, `formulation reply/request
screen.png`, several `WhatsApp Image...jpeg` files) but none are named or
otherwise indicated as SCRUBBOTS assets, and none have been copied into the
project or treated as such — per rule 9.5, nothing is assumed or fabricated
from ambiguous evidence. **All visual reference categories below are
`STATUS = AWAITING OWNER ASSET`.**

### 9.1 — Visual reference priority `[LOCKED]`

**Priority 1 — Owner-approved original SCRUBBOTS artwork.** Canonical
visual reference: character concepts, gameplay concepts, five-slot layouts,
pixel-art level artwork, themed level artwork (e.g. an underwater SCRUBBOTS
scene, if/when supplied), original UI ideas, effects concepts, screen
compositions. If original approved artwork conflicts with a generic
placeholder, the original artwork wins.

**Priority 2 — Owner-supplied SCRUBBOTS reference images.** May guide
composition, proportions, pixel-art density, UI positioning, Scrubbot size,
slot size, board presentation, visual hierarchy.

**Priority 3 — External game references.** Inspiration/reference only —
movement density, clarity, pacing, spatial readability, touch ergonomics,
pixel construction methodology. Must never be copied.

### 9.2 — Colony Flow reference limit `[LOCKED]`

May be referenced only for the broad feeling of many tiny agents moving
across a play area. SCRUBBOTS intentionally differs:

```text
Correct SCRUBBOTS flow:
  slot -> Scrubbot leaves -> travels to valid pixel -> cleans pixel -> disappears

NOT:
  travel to resource -> collect resource -> carry resource back -> return home
```

Never copy Colony Flow's characters, art, levels, UI, icons, compositions,
exact animations, routing visuals, or source code.

### 9.3 — Pixel art reference rule `[LOCKED]`

Previously supplied game screenshots may be used only as reference for
*pixel construction method*, where explicitly approved — never for
characters, compositions, object placement, level art, or exact palettes.
The goal is understanding how a readable image is built from a limited
logical grid. SCRUBBOTS level artwork remains original.

### 9.4 — Existing SCRUBBOTS level art `[LOCKED]`

Existing original SCRUBBOTS level artwork (e.g. a previously-created
underwater theme piece) is intended to become real playable content once
the owner supplies the actual files. Never regenerate such pieces from
memory and present the result as "the original."

### 9.5 — Reference file availability `[LOCKED]`

Claude only has access to artwork physically present in the project or
supplied during the current task. If an expected visual does not exist
locally: `STATUS = AWAITING OWNER ASSET`. Do not fabricate it, do not mark
its audit complete, do not claim a pixel-accurate comparison was performed
against something that doesn't exist locally.

### 9.6 — Recommended future visual directory structure

Not implemented in this planning task — recorded here for the asset-audit
milestone (M07) to use later:

```text
assets/
└── art/
    ├── references/
    │   ├── gameplay/
    │   ├── ui/
    │   ├── scrubbots/
    │   ├── pixel_method/
    │   └── external_inspiration/
    ├── characters/
    │   └── scrubbots/
    ├── levels/
    │   ├── source/
    │   │   ├── easy/
    │   │   ├── medium/
    │   │   ├── hard/
    │   │   └── very_hard/
    │   └── previews/
    ├── ui/
    └── effects/
```

---

## DESIGN GATES

Unresolved. Do not silently invent final decisions for these:

Exact slot refill/replacement behavior; how a player activates a slot;
whether slots hold quantities; hidden/upcoming slot queue; exact number of
colors by difficulty; palette-size rules; exact target-selection heuristic;
exact route geometry; route crossing rules; route collision behavior; exact
dirty/clean visual presentation; exact win condition; exact lose condition;
timer; move limits; lives; blockers; boosters; hints; progression
structure; currency meaning; economy; shop; monetization; ads; IAP; energy
system; analytics; achievements; leaderboard; social features; cloud save;
tutorial wording; audio direction.

**Not design gates** (these are locked, see 8.3): Easy 20–29×20–29, Medium
30–39×30–39, Hard 40–49×40–49, Very Hard 50–59×50–59.

---

## MASTER MILESTONES

### M00 — Foundation & Environment

Verified complete via repo inspection + this session's re-run of
`tools/verify_project.ps1` and `godot --version`.

- [x] SB-M00-001 Canonical project directory created.
- [x] SB-M00-002 Git repository connected (`origin` = canonical remote).
- [x] SB-M00-003 `main` branch configured and tracked.
- [x] SB-M00-004 Godot project created (`project.godot` valid).
- [x] SB-M00-005 Directory architecture created.
- [x] SB-M00-006 `.gitignore` created.
- [x] SB-M00-007 `CLAUDE.md` created.
- [x] SB-M00-008 Initial documentation created (`docs/00`–`06`).
- [x] SB-M00-009 Bootstrap scene created (`scenes/app/main.tscn`).
- [x] SB-M00-010 Verification helpers created (`tools/*.ps1`).
- [x] SB-M00-011 Godot 4.7.1-stable installed (winget, `GodotEngine.GodotEngine`).
- [x] SB-M00-012 Godot CLI path verified (`godot --version` → `4.7.1.stable.official.a13da4feb`).
- [x] SB-M00-013 Headless bootstrap test succeeds (`--headless --path . --quit`, no errors).
- [x] SB-M00-014 Main scene parses (confirmed via headless boot).
- [x] SB-M00-015 Existing GDScript parses (confirmed via headless test run).
- [x] SB-M00-016 Bootstrap committed/pushed (`58caeab`, on `origin/main`).

### M01 — Variable-Size Level Data Core

Complete from Prompt 02. Re-verified this session (files exist, test suite
passes).

- [x] SB-M01-001 Level Data V1 implemented (`scripts/data/level_data.gd`).
- [x] SB-M01-002 Width stored in level data.
- [x] SB-M01-003 Height stored in level data.
- [x] SB-M01-004 Cell count derived (`get_cell_count() = width * height`, never stored).
- [x] SB-M01-005 Palette stored separately (array of hex strings, id = index).
- [x] SB-M01-006 Cell palette IDs compact (`PackedInt32Array`, not per-cell strings).
- [x] SB-M01-007 JSON loader implemented (`level_loader.gd`).
- [x] SB-M01-008 Validator implemented (`level_validator.gd`).
- [x] SB-M01-009 Malformed JSON handled (tested, rejected cleanly).
- [x] SB-M01-010 Unsupported version rejected (tested).
- [x] SB-M01-011 Invalid dimensions rejected (width/height ≤ 0, tested).
- [x] SB-M01-012 Wrong cell count rejected (tested).
- [x] SB-M01-013 Invalid palette ID rejected (tested).
- [x] SB-M01-014 Generic dimension support proven (3×2 fixture).
- [x] SB-M01-015 40×40 loads (1,600 cells, tested).
- [x] SB-M01-016 50×50 loads (2,500 cells, tested).
- [x] SB-M01-017 3×2 loads as generic test fixture (tested).
- [x] SB-M01-018 Explicit preload convention documented (ADR-009).

### M02 — BoardState Core

Complete from Prompt 02, re-verified.

- [x] SB-M02-001 BoardState exists (`scripts/gameplay/board/board_state.gd`).
- [x] SB-M02-002 Runtime state separate from LevelData (BoardState built via `from_level_data`, never mutates source).
- [x] SB-M02-003 Source color data copied safely (`_color_ids = level.cells.duplicate()`).
- [x] SB-M02-004 DIRTY state implemented.
- [x] SB-M02-005 CLEAN state implemented.
- [x] SB-M02-006 Coordinate validation exists (`is_valid_coordinate`).
- [x] SB-M02-007 Index validation exists (`is_valid_index`).
- [x] SB-M02-008 Coordinate→index exists (`get_cell_index`).
- [x] SB-M02-009 Index→coordinate exists (`get_cell_position`).
- [x] SB-M02-010 Cell color lookup exists (`get_color_id`).
- [x] SB-M02-011 Cell state lookup exists (`get_cell_state`).
- [x] SB-M02-012 State mutation exists (`set_cell_state`).
- [x] SB-M02-013 State counting exists (`count_cells_by_state`).
- [x] SB-M02-014 Instance independence tested (two BoardStates from same LevelData don't share state).
- [x] SB-M02-015 LevelData immutability behavior tested.
- [x] SB-M02-016 No one-Node-per-cell architecture exists (flat `PackedInt32Array`/`PackedByteArray`).
- [ ] SB-M02-017 Add RESERVED only when reservation architecture is designed (see M14).

### M03 — Official Difficulty Bands + 59×59 Envelope

**This is the next required architecture correction.** Prompt 02 only knew
about 40×40 and 50×50; the official band system (8.3) is broader and must
now be reflected in docs and enforced in code.

**Documentation**
- [x] SB-M03-001 Search docs for old claim that 40×40 is "standard."
- [x] SB-M03-002 Search docs for claim 50×50 is the Very Hard requirement without a range.
- [x] SB-M03-003 Search for `2500` used as a maximum (none found; only an example error message and a factual 50×50 cell-count statement remain).
- [x] SB-M03-004 Update `CLAUDE.md`.
- [x] SB-M03-005 Update project brief.
- [x] SB-M03-006 Update gameplay specification.
- [x] SB-M03-007 Update technical architecture.
- [x] SB-M03-008 Update Level Data spec.
- [x] SB-M03-009 Update roadmap.
- [x] SB-M03-010 Update test strategy.
- [x] SB-M03-011 Add/amend ADR for official difficulty dimension bands (ADR-010).

**Production difficulty representation**
- [x] SB-M03-012 Define canonical production difficulty IDs (`DifficultyRules`, `scripts/data/difficulty_rules.gd`).
- [x] SB-M03-013 EASY = dimensions 20..29.
- [x] SB-M03-014 MEDIUM = dimensions 30..39.
- [x] SB-M03-015 HARD = dimensions 40..49.
- [x] SB-M03-016 VERY_HARD = dimensions 50..59.
- [x] SB-M03-017 Keep TEST/dev fixture concept separate (`DifficultyRules.TEST_DIFFICULTY`).
- [x] SB-M03-018 Production catalog must never expose TEST (enforced at the validator layer — `ProductionLevelValidator` rejects TEST outright, tested; no `LevelCatalog` exists yet, that's M30).

**Validation**
- [x] SB-M03-019 Add production difficulty/dimension validation (`ProductionLevelValidator`).
- [x] SB-M03-020 Accept Easy rectangular boards (tested: 20×27).
- [x] SB-M03-021 Accept Medium rectangular boards (tested: 34×39).
- [x] SB-M03-022 Accept Hard rectangular boards (tested: 48×41).
- [x] SB-M03-023 Accept Very Hard rectangular boards (tested: 53×59).
- [x] SB-M03-024 Reject cross-band Easy dimensions (tested: 20×30 upper, 19×20 lower).
- [x] SB-M03-025 Reject cross-band Medium dimensions (tested: 39×40 upper, 29×30 lower).
- [x] SB-M03-026 Reject cross-band Hard dimensions (tested: 49×50 upper, 39×40 lower).
- [x] SB-M03-027 Reject cross-band Very Hard dimensions (tested: 49×59 upper, 49×50 lower).
- [x] SB-M03-028 Produce explicit errors, e.g.:
  ```text
  Level level_123: difficulty VERY_HARD requires width and height in
  range 50..59. Received width=49 height=59.
  ```
  (actual implemented format matches this shape, e.g. `Level easy_bad_upper:
  difficulty EASY requires width and height in range 20..29; received
  width=20 height=30`.)

### M04 — Expanded Board Fixtures & Test Matrix

Do not replace existing Prompt 02 fixtures — add to them.

- [x] SB-M04-001 3×2 generic non-square fixture exists.

**Easy** — all tested via in-memory `LevelData` against `ProductionLevelValidator` (see M03).
- [x] SB-M04-002 20×20. — [x] SB-M04-003 29×29. — [x] SB-M04-004 20×27.

**Medium**
- [x] SB-M04-005 30×30. — [x] SB-M04-006 39×39. — [x] SB-M04-007 34×39.

**Hard**
- [x] SB-M04-008 40×40 generic fixture exists.
- [x] SB-M04-009 49×49. — [x] SB-M04-010 48×41.

**Very Hard**
- [x] SB-M04-011 50×50 generic fixture exists.
- [x] SB-M04-012 59×59 (real fixture `test_59x59.json` + in-memory production check). — [x] SB-M04-013 53×59.

**Boundary rejection** — upper AND lower boundary tested for all four (prompt required at minimum the upper cases; lower cases added too).
- [x] SB-M04-014 Easy 20×30 fails production validation (also: 19×20 lower bound).
- [x] SB-M04-015 Medium 39×40 fails (also: 29×30 lower bound).
- [x] SB-M04-016 Hard 49×50 fails (also: 39×40 lower bound).
- [x] SB-M04-017 Very Hard 49×59 fails (also: 49×50 lower bound).

**Maximum workload**
- [x] SB-M04-018 59×59 loads successfully (`test_59x59.json`, full JSON pipeline).
- [x] SB-M04-019 `cell_count == 3481`.
- [x] SB-M04-020 Coordinate/index tests pass at 59×59 (4 corners + center).
- [x] SB-M04-021 State mutation tests pass at 59×59 (single-cell isolation: 1 CLEAN / 3480 DIRTY).
- [x] SB-M04-022 Performance sanity benchmark runs at 3,481 cells (kept alongside the existing 50×50 benchmark, not replacing it).
- [x] SB-M04-023 Record results without an arbitrary strict timing threshold (see `SCRUBBOTS_PHASE_M03_LOG.md` for actual measured numbers).

### M05 — Test Harness Maturity

`tests/run_tests.gd` already provides a usable native Godot headless
runner — mark actual existing capabilities complete.

- [x] SB-M05-001 Headless test script exists.
- [x] SB-M05-002 Test process returns failure exit code (verified: exit 0 on pass).
- [x] SB-M05-003 Current tests print PASS/failure information.
- [x] SB-M05-004 No third-party test framework required.
- [x] SB-M05-005 Current 73 checks pass (re-verified this session).
- [ ] SB-M05-006 Organize test sections as suite grows.
- [ ] SB-M05-007 Separate performance benchmark output from assertions.
- [ ] SB-M05-008 Add one-command PowerShell full-test wrapper if useful.
- [ ] SB-M05-009 Add regression test conventions to docs.
- [ ] SB-M05-010 Ensure future milestone completion requires regression pass.

### M06 — Board Renderer

First major missing technical system after the difficulty-envelope
correction. Render `BoardState` efficiently, never one Node per cell.

- [x] SB-M06-001 Define BoardRenderer responsibility (presentation-only, see docs/02_TECH_ARCHITECTURE.md).
- [x] SB-M06-002 Keep BoardRenderer separate from BoardState (never mutates it — tested).
- [x] SB-M06-003 Evaluate efficient Godot rendering options (3 candidates compared, see ADR-011 / phase log).
- [x] SB-M06-004 Choose technique based on measured simplicity/performance (Image/ImageTexture).
- [x] SB-M06-005 Record technique in ADR (ADR-011).
- [x] SB-M06-006 Render arbitrary width/height.
- [x] SB-M06-007 Support rectangular board aspect ratio (never stretched — tested at 20×27, 34×39, 48×41, 53×59).
- [x] SB-M06-008 Preserve logical pixel boundaries (integer `floor()` cell_size, no drift).
- [x] SB-M06-009 Disable unwanted texture filtering (`TEXTURE_FILTER_NEAREST`).
- [x] SB-M06-010 Render palette colors correctly (via `PaletteColors`, tested).
- [x] SB-M06-011 Render 20×20. — [x] SB-M06-012 Render 29×29.
- [x] SB-M06-013 Render 39×39. — [x] SB-M06-014 Render 49×49.
- [x] SB-M06-015 Render 50×50. — [x] SB-M06-016 Render 59×59.
- [x] SB-M06-017 Render representative rectangular boards.
- [x] SB-M06-018 Expose logical-cell center coordinate (`get_cell_center_local`/`get_cell_center_global` — geometry seam only, no movement implemented against it).
- [x] SB-M06-019 Support efficient individual-cell update (`update_cells()`, tested).
- [x] SB-M06-020 Support full reset (`refresh_all()`, tested).
- [x] SB-M06-021 Benchmark 3,481-cell display (see `SCRUBBOTS_PHASE_M06_LOG.md` for actual numbers; CPU-side only — true GPU/on-screen FPS not measurable under `--headless`, stated explicitly rather than fabricated).
- [x] SB-M06-022 Confirm no 3,481-cell Node tree exists (`get_child_count() == 0` asserted at 59×59 and every other tested size).

### M07 — Visual Reference Library `[VISUAL REFERENCE]`

- [ ] SB-M07-001 Establish reference directory structure (9.6).
- [ ] SB-M07-002 Create visual-reference README/guide.
- [ ] SB-M07-003 Separate original SCRUBBOTS art from external inspiration.
- [ ] SB-M07-004 Define canonical asset naming.
- [ ] SB-M07-005 Define asset type metadata.
- [ ] SB-M07-006 Define owner-approved status.
- [ ] SB-M07-007 Preserve source file originals.
- [ ] SB-M07-008 Inventory Scrubbot character visuals supplied by owner. **AWAITING OWNER ASSET.**
- [ ] SB-M07-009 Inventory gameplay-screen references supplied by owner. **AWAITING OWNER ASSET.**
- [ ] SB-M07-010 Inventory five-slot visual references. **AWAITING OWNER ASSET.**
- [ ] SB-M07-011 Inventory level images. **AWAITING OWNER ASSET.**
- [ ] SB-M07-012 Inventory underwater level artwork if supplied. **AWAITING OWNER ASSET.**
- [ ] SB-M07-013 Inventory other original theme artwork. **AWAITING OWNER ASSET.**
- [ ] SB-M07-014 Inventory pixel-construction reference screenshots. **AWAITING OWNER ASSET.**
- [ ] SB-M07-015 Inventory external movement references separately.
- [ ] SB-M07-016 Flag previously discussed but unavailable assets as `AWAITING OWNER ASSET` (done above, pending real files).
- [ ] SB-M07-017 Never regenerate missing references and label them originals.

### M08 — Level Art Technical Audit `[CONTENT] [VISUAL REFERENCE]`

Per candidate production pixel-art level (none exist locally yet):

- [ ] SB-M08-001 Record filename. — [ ] SB-M08-002 Record original dimensions.
- [ ] SB-M08-003 Record alpha/transparency. — [ ] SB-M08-004 Count colors.
- [ ] SB-M08-005 Detect anti-aliasing. — [ ] SB-M08-006 Detect interpolation.
- [ ] SB-M08-007 Determine logical-pixel grid.
- [ ] SB-M08-008 Determine legal difficulty band.
- [ ] SB-M08-009 Confirm width in legal range.
- [ ] SB-M08-010 Confirm height in legal range.
- [ ] SB-M08-011 Preserve original. — [ ] SB-M08-012 Never silently resize.
- [ ] SB-M08-013 Never silently reduce palette. — [ ] SB-M08-014 Produce audit report.

Examples: `27×24 -> Easy`, `35×38 -> Medium`, `43×46 -> Hard`, `53×59 -> Very Hard`.
An image must never be auto-changed to 20×20/40×40/50×50 for convenience.

### M09 — Pixel Art → Level Data Pipeline `[CONTENT]`

- [ ] SB-M09-001 Create importer tool.
- [ ] SB-M09-002 Read source pixels exactly.
- [ ] SB-M09-003 Determine width. — [ ] SB-M09-004 Determine height.
- [ ] SB-M09-005 Determine/validate difficulty.
- [ ] SB-M09-006 Extract unique palette.
- [ ] SB-M09-007 Produce stable palette ordering.
- [ ] SB-M09-008 Convert pixels to palette IDs.
- [ ] SB-M09-009 Flatten using canonical row-major mapping (`index = y*width+x`).
- [ ] SB-M09-010 Produce Level Data V1.
- [ ] SB-M09-011 Store source-asset metadata where useful.
- [ ] SB-M09-012 Deterministic output.
- [ ] SB-M09-013 Re-running importer produces no meaningless diff.
- [ ] SB-M09-014 Reconstruct image from generated data.
- [ ] SB-M09-015 Pixel-compare reconstruction.
- [ ] SB-M09-016 Generate preview.
- [ ] SB-M09-017 Reject unsupported/broken art with useful reason.
- [ ] SB-M09-018 Batch import. — [ ] SB-M09-019 Batch validation.
- [ ] SB-M09-020 Duplicate level ID protection.

### M10 — Dirty/Clean Visual Model `[DESIGN GATE]`

Review original SCRUBBOTS visual references before locking final visuals.
**Prompt 04 built the prototype infrastructure and three candidate presets
— this milestone is NOT complete.** Final DIRTY visual approval remains an
open `[DESIGN GATE]` regardless of how much tooling exists; do not mark it
resolved until the project owner has actually compared presets A/B/C at
native 50×50/59×59 scale via `scenes/debug/board_renderer_debug.tscn` and
chosen one (or requested a new preset).

- [ ] SB-M10-001 Define (approve) DIRTY appearance — 3 candidate presets exist (`DirtyCleanPresets` A/B/C), none chosen.
- [x] SB-M10-002 Define CLEAN appearance — locked: unmodified source palette color (`docs/01_GAMEPLAY_SPEC.md`).
- [x] SB-M10-003 Define grime layer relationship to source artwork — locked: DIRTY is a transform of the same color, never a separate stacked layer (ADR-011).
- [x] SB-M10-004 Implement visual mapping (`DirtyCleanPresets.apply_dirty`).
- [ ] SB-M10-005 Ensure cleaning is immediately readable — debug tooling ready to test this; actual owner visual confirmation pending.
- [ ] SB-M10-006 Preserve artwork recognition — same: tooling ready, owner confirmation pending.
- [ ] SB-M10-007 Test Easy density. — [ ] SB-M10-008 Test Medium density. (debug tool supports both sizes; awaiting owner visual review)
- [ ] SB-M10-009 Test Hard density. — [ ] SB-M10-010 Test Very Hard density. (debug tool supports both sizes; awaiting owner visual review)
- [ ] SB-M10-011 Test 59×59 readability — the single most important check per this phase's own instructions; tooling ready, **awaiting owner review**.
- [x] SB-M10-012 Add development reveal/debug toggle (`scenes/debug/board_renderer_debug.tscn` — size/pattern/preset dropdowns).

### M11 — Gameplay Session Core

- [ ] SB-M11-001 Define session states.
- [ ] SB-M11-002 Initialize level. — [ ] SB-M11-003 Load LevelData.
- [ ] SB-M11-004 Create BoardState. — [ ] SB-M11-005 Connect renderer.
- [ ] SB-M11-006 Define ready state. — [ ] SB-M11-007 Define active state.
- [ ] SB-M11-008 Define pause. — [ ] SB-M11-009 Define reset.
- [ ] SB-M11-010 Define completion transition.
- [ ] SB-M11-011 Keep UI separate from gameplay truth.
- [ ] SB-M11-012 Headless lifecycle tests where possible.

### M12 — Five-Slot Logic

- [ ] SB-M12-001 Create SlotState. — [ ] SB-M12-002 Create SlotSystem.
- [ ] SB-M12-003 Configure five gameplay slots.
- [ ] SB-M12-004 Slot identity. — [ ] SB-M12-005 Slot palette/color.
- [ ] SB-M12-006 Slot availability. — [ ] SB-M12-007 Slot activity state.
- [ ] SB-M12-008 Keep model separate from UI. — [ ] SB-M12-009 Query API.
- [ ] SB-M12-010 Five-slot tests. — [ ] SB-M12-011 Invalid slot tests.

Remaining slot mechanics are `[DESIGN GATE]`.

### M13 — Eligible Target Index `[PERFORMANCE]`

Don't rescan up to 3,481 cells unnecessarily for every bot.

- [ ] SB-M13-001 Define eligible cell.
- [ ] SB-M13-002 Group/query by color.
- [ ] SB-M13-003 Implement efficient index/cache if measured useful.
- [ ] SB-M13-004 Synchronize with BoardState.
- [ ] SB-M13-005 Remove CLEAN cells. — [ ] SB-M13-006 Handle reservations.
- [ ] SB-M13-007 No-work query. — [ ] SB-M13-008 Exhausted-color test.
- [ ] SB-M13-009 Last-target test. — [ ] SB-M13-010 3,481-cell benchmark.

### M14 — Reservation State

RESERVED was intentionally deferred in Prompt 02 (see M02-017). Add only
when target assignment requires it.

- [ ] SB-M14-001 Define reservation ownership.
- [ ] SB-M14-002 Decide whether RESERVED belongs in `BoardState.CellState` or separate data.
- [ ] SB-M14-003 Record decision (ADR).
- [ ] SB-M14-004 Reserve target atomically.
- [ ] SB-M14-005 Prevent double reservation.
- [ ] SB-M14-006 Release on dispatch failure. — [ ] SB-M14-007 Release on reset.
- [ ] SB-M14-008 Resolve arrival. — [ ] SB-M14-009 Concurrency tests.

### M15 — TargetSelector

- [ ] SB-M15-001 Create TargetSelector.
- [ ] SB-M15-002 Keep BoardState access narrow.
- [ ] SB-M15-003 Baseline deterministic strategy.
- [ ] SB-M15-004 Match Scrubbot color.
- [ ] SB-M15-005 Never target CLEAN. — [ ] SB-M15-006 Never target invalid.
- [ ] SB-M15-007 Respect reservations.
- [ ] SB-M15-008 Return no-target cleanly.
- [ ] SB-M15-009 No route generation inside selector (8.10).
- [ ] SB-M15-010 Determinism tests.
- [ ] SB-M15-011 Simultaneous assignment tests.
- [ ] SB-M15-012 3,481-cell benchmark.

### M16 — RoutingSystem Interface

- [ ] SB-M16-001 Define RoutingSystem contract.
- [ ] SB-M16-002 Define route input. — [ ] SB-M16-003 Define route output.
- [ ] SB-M16-004 Define coordinate space.
- [ ] SB-M16-005 Slot origin. — [ ] SB-M16-006 Cell destination.
- [ ] SB-M16-007 Keep independent from TargetSelector (8.10).
- [ ] SB-M16-008 Swappable implementations.
- [ ] SB-M16-009 Debug route visualization.
- [ ] SB-M16-010 Route validity checks. — [ ] SB-M16-011 Failure behavior.

### M17 — Routing Prototype Lab

One of the most important SCRUBBOTS milestones. Do not lock the first
working solution — prototype multiple options.

- [ ] SB-M17-001 Direct route baseline.
- [ ] SB-M17-002 Grid-aware route prototype.
- [ ] SB-M17-003 Organized polyline/curved prototype.
- [ ] SB-M17-004 Compare visual clarity. — [ ] SB-M17-005 Compare path crossings.
- [ ] SB-M17-006 Compare congestion. — [ ] SB-M17-007 Compare CPU cost.
- [ ] SB-M17-008 Compare route distance. — [ ] SB-M17-009 Compare determinism.
- [ ] SB-M17-010 Compare against original SCRUBBOTS visual direction.
- [ ] SB-M17-011 Test 5 bots. — [ ] SB-M17-012 Test 10 bots. — [ ] SB-M17-013 Test 25 bots.
- [ ] SB-M17-014 Stress-test higher density.
- [ ] SB-M17-015 Test 59×59. — [ ] SB-M17-016 Test rectangular Very Hard board.

`[DESIGN GATE]` — owner selects final movement language.

### M18 — Scrubbot Agent

- [ ] SB-M18-001 Lightweight agent core.
- [ ] SB-M18-002 Assigned color. — [ ] SB-M18-003 Assigned target.
- [ ] SB-M18-004 Assigned route. — [ ] SB-M18-005 Spawn origin.
- [ ] SB-M18-006 Route movement. — [ ] SB-M18-007 Arrival detection.
- [ ] SB-M18-008 Completion event. — [ ] SB-M18-009 Despawn.
- [ ] SB-M18-010 No return-to-slot. — [ ] SB-M18-011 No resource carrying.
- [ ] SB-M18-012 Reset cancellation. — [ ] SB-M18-013 No orphan nodes.
- [ ] SB-M18-014 Performance stress test.
- [ ] SB-M18-015 Pool only if profiling justifies it.

### M19 — Scrubbot Dispatcher

- [ ] SB-M19-001 Receive slot request.
- [ ] SB-M19-002 Check work before spawn.
- [ ] SB-M19-003 Ask TargetSelector.
- [ ] SB-M19-004 Refuse spawn without target.
- [ ] SB-M19-005 Reserve target.
- [ ] SB-M19-006 Spawn exactly one bot per dispatch.
- [ ] SB-M19-007 Enforce one-by-one flow.
- [ ] SB-M19-008 Prevent duplicate assignments.
- [ ] SB-M19-009 Handle dispatch failure.
- [ ] SB-M19-010 Handle rapid input.
- [ ] SB-M19-011 Concurrent slot tests. — [ ] SB-M19-012 Reset during dispatch.

### M20 — Complete Cleaning Vertical Slice

Required flow: slot activation → work validation → target selection →
target reservation → Scrubbot spawn → route generation → visual travel →
arrival → CLEAN state → renderer update → eligibility update → reservation
clear → Scrubbot disappears.

- [ ] SB-M20-001 Wire complete sequence.
- [ ] SB-M20-002 No target means no bot. — [ ] SB-M20-003 No return behavior.
- [ ] SB-M20-004 One-cell test. — [ ] SB-M20-005 One-color test.
- [ ] SB-M20-006 Multi-color test. — [ ] SB-M20-007 Five-slot test.
- [ ] SB-M20-008 Easy board test. — [ ] SB-M20-009 Medium board test.
- [ ] SB-M20-010 Hard board test. — [ ] SB-M20-011 Very Hard board test.
- [ ] SB-M20-012 59×59 stress test. — [ ] SB-M20-013 Rectangular board test.
- [ ] SB-M20-014 State-desynchronization check.

### M21 — First Real-Art Vertical Slice `[CONTENT] [VISUAL REFERENCE]`

Major project gate — uses **one owner-approved original SCRUBBOTS level
art**, not a synthetic checkerboard. Blocked until such art exists locally
(currently `AWAITING OWNER ASSET`, see Visual Reference System).

- [ ] SB-M21-001 Ingest original source artwork.
- [ ] SB-M21-002 Audit source dimensions.
- [ ] SB-M21-003 Determine legal difficulty.
- [ ] SB-M21-004 Generate level data.
- [ ] SB-M21-005 Reconstruct and compare.
- [ ] SB-M21-006 Render in gameplay.
- [ ] SB-M21-007 Populate five slots.
- [ ] SB-M21-008 Dispatch Scrubbots.
- [ ] SB-M21-009 Clean actual artwork pixels.
- [ ] SB-M21-010 Run full level.
- [ ] SB-M21-011 Profile performance.
- [ ] SB-M21-012 Capture reference gameplay output.

### M22 — Production Slot UI `[VISUAL REFERENCE]`

- [ ] SB-M22-001 Audit slot references. — [ ] SB-M22-002 Create SlotView.
- [ ] SB-M22-003 Five-slot layout. — [ ] SB-M22-004 Bind SlotState.
- [ ] SB-M22-005 Color presentation. — [ ] SB-M22-006 Touch target.
- [ ] SB-M22-007 Active state. — [ ] SB-M22-008 No-work state if approved.
- [ ] SB-M22-009 Scrubbot spawn point.
- [ ] SB-M22-010 Aspect-ratio tests. — [ ] SB-M22-011 Safe-area tests.
- [ ] SB-M22-012 Rapid-tap tests.

### M23 — Gameplay Screen Layout `[VISUAL REFERENCE]`

- [ ] SB-M23-001 Audit original gameplay reference images.
- [ ] SB-M23-002 Board region. — [ ] SB-M23-003 Five-slot region.
- [ ] SB-M23-004 HUD region. — [ ] SB-M23-005 Safe areas.
- [ ] SB-M23-006 Easy dimensions. — [ ] SB-M23-007 Medium dimensions.
- [ ] SB-M23-008 Hard dimensions. — [ ] SB-M23-009 Very Hard dimensions.
- [ ] SB-M23-010 Rectangular boards. — [ ] SB-M23-011 59×59.
- [ ] SB-M23-012 Narrow phone. — [ ] SB-M23-013 Tall phone.
- [ ] SB-M23-014 Tablet portrait. — [ ] SB-M23-015 Input coordinate accuracy.

### M24 — Mobile Touch

- [ ] SB-M24-001 Touch slot activation.
- [ ] SB-M24-002 Desktop mouse development support.
- [ ] SB-M24-003 Prevent mouse/touch double-fire.
- [ ] SB-M24-004 Touch cancel. — [ ] SB-M24-005 Focus loss.
- [ ] SB-M24-006 Rapid tapping. — [ ] SB-M24-007 Multi-touch.
- [ ] SB-M24-008 Pause during touch. — [ ] SB-M24-009 Background/foreground.

### M25 — Win/Lose Rules `[DESIGN GATE]`

Owner must explicitly decide: must every cleanable cell be cleared? timer?
move limits? can the player get stuck? fail state? free retry? score/star
grading?

- [ ] SB-M25-001 Document win condition. — [ ] SB-M25-002 Document lose condition.
- [ ] SB-M25-003 Completion evaluator. — [ ] SB-M25-004 Emit completion once.
- [ ] SB-M25-005 Stop inappropriate new dispatch.
- [ ] SB-M25-006 Resolve in-flight bots. — [ ] SB-M25-007 Retry.
- [ ] SB-M25-008 Completion regression tests.

### M26 — Cleaning Effects `[VISUAL REFERENCE] [PERFORMANCE]`

- [ ] SB-M26-001 Use original visual references where available.
- [ ] SB-M26-002 Define cleaning event.
- [ ] SB-M26-003 Prototype lightweight effect.
- [ ] SB-M26-004 Separate from BoardState.
- [ ] SB-M26-005 Toggle effects. — [ ] SB-M26-006 Concurrency limit.
- [ ] SB-M26-007 Pool only after profiling. — [ ] SB-M26-008 Stress 59×59.
- [ ] SB-M26-009 Measure frame cost.
- [ ] SB-M26-010 Reduced-effects option if required.

### M27 — Scrubbot Final Visuals `[VISUAL REFERENCE]`

- [ ] SB-M27-001 Audit original Scrubbot art. **AWAITING OWNER ASSET.**
- [ ] SB-M27-002 Select owner-approved canonical design.
- [ ] SB-M27-003 Preserve original source.
- [ ] SB-M27-004 Configure crisp import.
- [ ] SB-M27-005 Visual component. — [ ] SB-M27-006 Travel animation.
- [ ] SB-M27-007 Arrival animation. — [ ] SB-M27-008 Disappearance.
- [ ] SB-M27-009 Direction/orientation if approved.
- [ ] SB-M27-010 Density performance test.

Never replace approved Scrubbot visuals with a generic robot design without
owner instruction.

### M28 — Audio `[DESIGN GATE]`

- [ ] SB-M28-001 Audio buses. — [ ] SB-M28-002 Master volume.
- [ ] SB-M28-003 Music volume. — [ ] SB-M28-004 SFX volume.
- [ ] SB-M28-005 Dispatch SFX. — [ ] SB-M28-006 Cleaning SFX.
- [ ] SB-M28-007 Completion SFX.
- [ ] SB-M28-008 Movement audio only if pleasant at high density.
- [ ] SB-M28-009 Concurrency management. — [ ] SB-M28-010 Persist settings.

### M29 — Haptics

- [ ] SB-M29-001 Platform API research.
- [ ] SB-M29-002 Cleaning haptic if approved. — [ ] SB-M29-003 Completion haptic.
- [ ] SB-M29-004 Toggle. — [ ] SB-M29-005 Prevent vibration spam.
- [ ] SB-M29-006 Real-device test.

### M30 — Level Catalog

- [ ] SB-M30-001 Production LevelCatalog.
- [ ] SB-M30-002 Stable IDs. — [ ] SB-M30-003 Stable ordering.
- [ ] SB-M30-004 Difficulty. — [ ] SB-M30-005 Dimensions.
- [ ] SB-M30-006 Preview. — [ ] SB-M30-007 Duplicate detection.
- [ ] SB-M30-008 Missing-file detection.
- [ ] SB-M30-009 Production/test separation.
- [ ] SB-M30-010 Reject TEST fixture in production catalog.
- [ ] SB-M30-011 Batch validation.

### M31 — Difficulty System

Board bands are locked (8.3). Still unresolved: number of colors, color
distribution, slot complexity, future queue behavior, optional blockers,
route complexity, other puzzle constraints.

- [ ] SB-M31-001 Centralize board-band configuration.
- [ ] SB-M31-002 Validate production catalog.
- [ ] SB-M31-003 Define additional difficulty factors with owner. `[DESIGN GATE]`
- [ ] SB-M31-004 Create difficulty matrix. — [ ] SB-M31-005 Playtest difficulty.
- [ ] SB-M31-006 Prevent board size alone from becoming the sole difficulty metric unless owner decides so.

### M32 — Level Progression `[DESIGN GATE]`

- [ ] SB-M32-001 Unlock rule. — [ ] SB-M32-002 Current level.
- [ ] SB-M32-003 Completion tracking. — [ ] SB-M32-004 Replay.
- [ ] SB-M32-005 Difficulty sequencing.
- [ ] SB-M32-006 Level select if approved.
- [ ] SB-M32-007 Service implementation. — [ ] SB-M32-008 Tests.

### M33 — Win Streak

Use the locked mapping (8.11).

- [ ] SB-M33-001 Streak state. — [ ] SB-M33-002 Increment on valid win.
- [ ] SB-M33-003 Define reset rule with owner. `[DESIGN GATE]`
- [ ] SB-M33-004 Reward function.
- [ ] SB-M33-005 Test 1→1. — [ ] SB-M33-006 Test 2→5.
- [ ] SB-M33-007 Test 3→10. — [ ] SB-M33-008 Test 4→25.
- [ ] SB-M33-009 Test 5→100. — [ ] SB-M33-010 Test 6+→100.
- [ ] SB-M33-011 No duplicate grant. — [ ] SB-M33-012 Persistence.

### M34 — Economy `[DESIGN GATE]`

Do not implement until owner defines what rewards actually represent.

### M35 — Save System

- [ ] SB-M35-001 Versioned schema. — [ ] SB-M35-002 Settings.
- [ ] SB-M35-003 Progression. — [ ] SB-M35-004 Win streak.
- [ ] SB-M35-005 Economy if later defined.
- [ ] SB-M35-006 Safe write strategy.
- [ ] SB-M35-007 Missing-save behavior. — [ ] SB-M35-008 Corruption recovery.
- [ ] SB-M35-009 Migration strategy.
- [ ] SB-M35-010 Round-trip tests. — [ ] SB-M35-011 Corrupt-file tests.

### M36 — Settings

- [ ] SB-M36-001 Master volume. — [ ] SB-M36-002 Music. — [ ] SB-M36-003 SFX.
- [ ] SB-M36-004 Haptics. — [ ] SB-M36-005 Reduced effects.
- [ ] SB-M36-006 Persistence. — [ ] SB-M36-007 Settings UI.
- [ ] SB-M36-008 Relaunch tests.

### M37 — Home / Navigation

- [ ] SB-M37-001 Navigation architecture. — [ ] SB-M37-002 Home.
- [ ] SB-M37-003 Play/Continue. — [ ] SB-M37-004 Settings.
- [ ] SB-M37-005 Level select if approved.
- [ ] SB-M37-006 Gameplay transition. — [ ] SB-M37-007 Results transition.
- [ ] SB-M37-008 Prevent duplicate transitions. — [ ] SB-M37-009 Back navigation.

### M38 — Results Screen

- [ ] SB-M38-001 Result model. — [ ] SB-M38-002 Completion UI.
- [ ] SB-M38-003 Streak. — [ ] SB-M38-004 Reward if defined.
- [ ] SB-M38-005 Continue. — [ ] SB-M38-006 Replay if approved.
- [ ] SB-M38-007 No double reward. — [ ] SB-M38-008 Rapid-tap protection.

### M39 — Tutorial `[DESIGN GATE]`

Teach five-slot interaction, color matching, Scrubbot flow, no-work
behavior if needed. Keep tutorial logic separate from core gameplay.

### M40 — Debug Tooling

- [ ] SB-M40-001 Debug overlay. — [ ] SB-M40-002 Level ID.
- [ ] SB-M40-003 Difficulty. — [ ] SB-M40-004 Dimensions.
- [ ] SB-M40-005 Cell count. — [ ] SB-M40-006 Dirty count. — [ ] SB-M40-007 Clean count.
- [ ] SB-M40-008 Reserved count if implemented. — [ ] SB-M40-009 Active bots.
- [ ] SB-M40-010 FPS. — [ ] SB-M40-011 Frame time.
- [ ] SB-M40-012 Target markers. — [ ] SB-M40-013 Route visualization.
- [ ] SB-M40-014 Cell grid. — [ ] SB-M40-015 Effect toggle.
- [ ] SB-M40-016 Instant reset. — [ ] SB-M40-017 Level switcher.
- [ ] SB-M40-018 Disable release-facing debug UI.

### M41 — Performance `[PERFORMANCE]`

Maximum board target: 59×59 = 3,481.

- [ ] SB-M41-001 Level parsing. — [ ] SB-M41-002 BoardState. — [ ] SB-M41-003 Renderer.
- [ ] SB-M41-004 Eligibility. — [ ] SB-M41-005 TargetSelector. — [ ] SB-M41-006 Routing.
- [ ] SB-M41-007 Scrubbot agents. — [ ] SB-M41-008 Effects.
- [ ] SB-M41-009 Memory baseline. — [ ] SB-M41-010 59×59 memory.
- [ ] SB-M41-011 Per-frame allocation detection.
- [ ] SB-M41-012 Repeated restart. — [ ] SB-M41-013 Long session.
- [ ] SB-M41-014 High agent density.

Target: stable, smooth mobile gameplay. Aim for 60 FPS on reasonable target
devices, measured rather than assumed.

### M42 — Android Device Testing

- [ ] SB-M42-001 Android export setup. — [ ] SB-M42-002 Development APK.
- [ ] SB-M42-003 Real device install. — [ ] SB-M42-004 Touch.
- [ ] SB-M42-005 Portrait. — [ ] SB-M42-006 Safe areas.
- [ ] SB-M42-007 Easy performance. — [ ] SB-M42-008 Medium performance.
- [ ] SB-M42-009 Hard performance. — [ ] SB-M42-010 Very Hard 59×59 performance.
- [ ] SB-M42-011 High bot density. — [ ] SB-M42-012 Background/foreground.
- [ ] SB-M42-013 Heat/battery extended test.
- [ ] SB-M42-014 Record device and results.

### M43 — iOS Readiness

- [ ] SB-M43-001 Avoid Android-only gameplay architecture.
- [ ] SB-M43-002 Document Apple toolchain requirement.
- [ ] SB-M43-003 Prepare iOS configuration when hardware exists.
- [ ] SB-M43-004 Real-device iOS testing later.

Mark actual iOS compilation `[DEFERRED]` until macOS/Xcode is available.

### M44 — Responsive UI

- [ ] SB-M44-001 16:9 portrait. — [ ] SB-M44-002 19.5:9. — [ ] SB-M44-003 20:9.
- [ ] SB-M44-004 Tall phone. — [ ] SB-M44-005 Tablet. — [ ] SB-M44-006 Notch/cutout.
- [ ] SB-M44-007 Five slots stay usable. — [ ] SB-M44-008 Board stays visible.
- [ ] SB-M44-009 Rectangular boards remain correctly scaled.
- [ ] SB-M44-010 Touch mapping remains accurate.

### M45 — Accessibility

- [ ] SB-M45-001 Review color-only information.
- [ ] SB-M45-002 Alternative visual slot cues if necessary.
- [ ] SB-M45-003 Color vision tests. — [ ] SB-M45-004 Contrast.
- [ ] SB-M45-005 Reduced effects. — [ ] SB-M45-006 Touch sizes.
- [ ] SB-M45-007 Text readability.

### M46 — Localization Readiness

- [ ] SB-M46-001 Avoid hard-coded user text.
- [ ] SB-M46-002 Translation-key convention.
- [ ] SB-M46-003 Longer-string layouts. — [ ] SB-M46-004 Pseudo-localization.
- [ ] SB-M46-005 Actual languages decided later. `[DESIGN GATE]`

### M47 — Production Content Scale-Up `[CONTENT]`

- [ ] SB-M47-001 Import first Easy art. — [ ] SB-M47-002 Import first Medium art.
- [ ] SB-M47-003 Import first Hard art. — [ ] SB-M47-004 Import first Very Hard art.
- [ ] SB-M47-005 Validate rectangular production art.
- [ ] SB-M47-006 Batch convert. — [ ] SB-M47-007 Batch validate.
- [ ] SB-M47-008 Generate previews. — [ ] SB-M47-009 Populate catalog.
- [ ] SB-M47-010 Verify every source image preserved.
- [ ] SB-M47-011 Verify generated level reproduces source.

### M48 — Level QA `[QA]`

Every production level:
- [ ] SB-M48-001 Legal dimensions. — [ ] SB-M48-002 Correct difficulty.
- [ ] SB-M48-003 Valid palette. — [ ] SB-M48-004 Correct cell count.
- [ ] SB-M48-005 No invalid palette IDs. — [ ] SB-M48-006 Recognizable artwork.
- [ ] SB-M48-007 No unintended interpolation. — [ ] SB-M48-008 Correct transparency.
- [ ] SB-M48-009 Solvable. — [ ] SB-M48-010 No routing pathology.
- [ ] SB-M48-011 Good performance. — [ ] SB-M48-012 Correct preview.
- [ ] SB-M48-013 Unique ID.

### M49 — Regression Suite `[QA]`

- [ ] SB-M49-001 Difficulty-range tests. — [ ] SB-M49-002 Level parser tests.
- [ ] SB-M49-003 BoardState tests. — [ ] SB-M49-004 Renderer tests.
- [ ] SB-M49-005 Slot tests. — [ ] SB-M49-006 Eligibility tests.
- [ ] SB-M49-007 Reservation tests. — [ ] SB-M49-008 TargetSelector tests.
- [ ] SB-M49-009 Routing tests. — [ ] SB-M49-010 Dispatcher tests.
- [ ] SB-M49-011 Completion tests. — [ ] SB-M49-012 Save tests.
- [ ] SB-M49-013 Reward tests. — [ ] SB-M49-014 Content validation tests.
- [ ] SB-M49-015 59×59 regression test.

### M50 — Chaos / Long-Run QA `[QA]`

- [ ] SB-M50-001 Spam all five slots.
- [ ] SB-M50-002 Restart while bots travel. — [ ] SB-M50-003 Pause while bots travel.
- [ ] SB-M50-004 Background while bots travel.
- [ ] SB-M50-005 Complete with bots in flight.
- [ ] SB-M50-006 Exhaust color. — [ ] SB-M50-007 Exhaust slot work.
- [ ] SB-M50-008 Repeated scene transitions.
- [ ] SB-M50-009 Long Very Hard session.
- [ ] SB-M50-010 Memory growth monitoring.
- [ ] SB-M50-011 Duplicate signal monitoring.
- [ ] SB-M50-012 Orphan Node monitoring.
- [ ] SB-M50-013 Duplicate reward monitoring.

### M51 — Analytics `[DESIGN GATE]`

No analytics SDK without owner approval.

### M52 — Monetization `[DESIGN GATE]`

Do NOT automatically add ads, rewarded ads, IAP, subscriptions, or an
energy system. Owner decides business model first.

### M53 — Privacy & Compliance

Once external services exist:
- [ ] SB-M53-001 Third-party inventory. — [ ] SB-M53-002 Data inventory.
- [ ] SB-M53-003 Remove unnecessary collection.
- [ ] SB-M53-004 Privacy disclosures. — [ ] SB-M53-005 Store declarations.
- [ ] SB-M53-006 Age-rating review.
- [ ] SB-M53-007 Child-directed considerations if applicable.

Do not invent legal conclusions.

### M54 — Build Pipeline

- [ ] SB-M54-001 Debug export. — [ ] SB-M54-002 Release export.
- [ ] SB-M54-003 Output directories. — [ ] SB-M54-004 Versioning.
- [ ] SB-M54-005 Build numbers. — [ ] SB-M54-006 Run tests before release build.
- [ ] SB-M54-007 Run content validator. — [ ] SB-M54-008 Generate Android build.
- [ ] SB-M54-009 Verify clean clone can build.

### M55 — Release

Application ID, icon, splash, portrait config, signing, release settings,
debug removal, store screenshots, final QA, tagged source commit, release
artifact validation. **Never commit signing secrets.**

---

## RISK REGISTER

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RISK-001 | Routing works technically but looks boring/confusing | CRITICAL | Multiple prototypes (M17) + visual owner review + replaceable RoutingSystem (8.10) |
| RISK-002 | Large number of Scrubbots causes frame drops | HIGH | 59×59 density stress tests and profiling (M41) |
| RISK-003 | Old 50×50 maximum assumption survives somewhere | HIGH | Repository searches (M03) + 59×59 regression tests (M49) |
| RISK-004 | Production difficulty dimensions become inconsistent | HIGH | Central validator (M03, M30) |
| RISK-005 | Generic 3×2 test breaks after production range validation | MEDIUM/HIGH | Explicit TEST fixture path/context separate from production validation (8.6) |
| RISK-006 | Existing artwork gets silently resized or altered | HIGH | Source preservation + explicit importer + round-trip comparison (M08, M09) |
| RISK-007 | Claude loses access to visual references and invents replacements | HIGH | Canonical local visual-reference library and manifest (M07) |
| RISK-008 | External reference game is copied too closely | HIGH | Original SCRUBBOTS visuals primary; external games conceptual reference only (9.1–9.3) |
| RISK-009 | Target race assigns same pixel to multiple Scrubbots | HIGH | Reservation tests (M14) |
| RISK-010 | Renderer architecture creates thousands of Nodes | HIGH | Batched/custom rendering requirement and 3,481-cell inspection (M06) |
| RISK-011 | Desktop testing hides mobile performance issues | HIGH | Real Android profiling before content scale-up (M42) |
| RISK-012 | Future Claude session breaks explicit preload/headless compatibility | MEDIUM/HIGH | ADR-009 + regression headless startup tests |

---

## CRITICAL PATH

```text
FOUNDATION                         DONE
↓
VARIABLE LEVEL DATA                DONE
↓
BOARDSTATE                         DONE
↓
HEADLESS CORE TESTS                DONE
↓
DIFFICULTY BANDS + 59×59
↓
BOARD RENDERER
↓
VISUAL REFERENCE INGESTION
↓
PIXEL ART IMPORT PIPELINE
↓
GAMEPLAY SESSION
↓
FIVE SLOTS
↓
TARGET ELIGIBILITY
↓
RESERVATION
↓
TARGETSELECTOR
↓
ROUTING PROTOTYPES
↓
SCRUBBOT AGENT
↓
DISPATCHER
↓
COMPLETE CLEANING LOOP
↓
REAL SCRUBBOTS ART VERTICAL SLICE
↓
PRODUCTION UI / TOUCH
↓
WIN / PROGRESSION / SAVE
↓
MOBILE PERFORMANCE
↓
CONTENT SCALE-UP
↓
RELEASE QA
```

---

## FIRST TRUE PLAYABLE TARGET

The first real proof of SCRUBBOTS is **not** a menu, a polished title
screen, a store, or a currency UI. It is:

```text
ONE REAL OWNER-APPROVED SCRUBBOTS LEVEL IMAGE
+ A VALID EASY/MEDIUM/HARD/VERY-HARD BOARD SIZE
+ FIVE FUNCTIONAL SLOTS
+ CORRECT TARGET ELIGIBILITY
+ NO-WORK-NO-SPAWN
+ SCRUBBOTS LEAVING ONE BY ONE
+ VALID TARGET RESERVATION
+ SCRUBBOTS MOVING VISIBLY ACROSS THE ARTWORK
+ PIXELS BEING CLEANED
+ SCRUBBOTS DISAPPEARING AFTER CLEANING
+ A COMPLETE PLAYABLE LEVEL
+ SMOOTH MOBILE PERFORMANCE
```

That is the vertical-slice priority (see M21).

---

## RECOMMENDED PROMPT SEQUENCE

Guidance, not a hard contract. Split any prompt if scope becomes too large.
Never combine two risky architecture systems merely to save prompt count.

```text
PROMPT 01  Project Foundation                                    [DONE]
PROMPT 02  Godot Installation + Variable LevelData + BoardState
           + Headless Tests                                      [DONE]
PROMPT 03  Official Difficulty Bands + TEST vs Production
           Validation + 20..59 Board Fixture Matrix + 59×59/3481
           Performance Validation
PROMPT 04  BoardRenderer + Variable Aspect Board Rendering
           + 59×59 Renderer Benchmark
PROMPT 05  Visual Reference Library + Existing SCRUBBOTS Asset
           Audit + Asset Manifest
PROMPT 06  Pixel-Art Importer + Level Conversion + Pixel-Perfect
           Round Trip Validation
PROMPT 07  Gameplay Session Core + Five-Slot Data Model
PROMPT 08  Target Eligibility + Reservation + TargetSelector
PROMPT 09  RoutingSystem + Multiple Routing Prototypes
PROMPT 10  ScrubbotAgent + Dispatcher
PROMPT 11  Complete Cleaning Vertical Slice
PROMPT 12  First Real SCRUBBOTS Artwork Playable Level
PROMPT 13  Production Slot UI + Gameplay Layout + Touch Controls
PROMPT 14  Win/Lose Completion Rules + Results Flow
PROMPT 15  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 16  Level Catalog + Difficulty Content Rules + Production
           Level Pipeline
PROMPT 17  Progression + Win Streak + Save System
PROMPT 18  Home + Settings + Tutorial + Navigation
PROMPT 19  Android Device Performance + Full 59×59 Stress Tests
PROMPT 20  Production Content Scale-Up + Regression + Chaos QA
PROMPT 21  Release Candidate Preparation
```

---

## NEXT IMMEDIATE MILESTONE

**PROMPT 03 — Official Difficulty Bands + 59×59 Validation — COMPLETE.**
See `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M03_LOG.md` for full detail:
`DifficultyRules` + `ProductionLevelValidator` implemented, official bands
(Easy 20–29, Medium 30–39, Hard 40–49, Very Hard 50–59, max 59×59=3,481)
enforced and tested, TEST-vs-production separation proven, docs/tasks.md
updated, 131/131 tests passing.

**PROMPT 04 — Board Renderer + DIRTY/CLEAN Prototype (M06) — COMPLETE.**
See `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M06_LOG.md` for full detail:
`BoardRenderer` (single Image/ImageTexture, zero per-cell Nodes at any
size, ADR-011) implemented and tested at every official band boundary plus
rectangular boards up to 59×59/3,481 cells; `PaletteColors` and
`DirtyCleanPresets` (3 presets, A/B/C) implemented; dev comparison tool
(`scenes/debug/board_renderer_debug.tscn`) built for native-scale owner
review; 227/227 tests passing. **DIRTY visual approval remains an open
design gate** — presets exist, none is chosen (see M10 above).

**PROMPT 05 (next) — Visual Reference Library / Existing Artwork Audit (M07)**

1. Preserve everything from M00–M06 — do not rebuild working systems
   (LevelData, BoardState, DifficultyRules, ProductionLevelValidator,
   BoardRenderer, DirtyCleanPresets).
2. Establish the reference directory structure from §9.6 (Visual Reference
   System) — `assets/art/references/{gameplay,ui,scrubbots,pixel_method,
   external_inspiration}/`, etc. — as directories only unless the owner
   supplies real files this session.
3. Ask the owner for / accept any real SCRUBBOTS artwork files if supplied
   this session; inventory them with type/status metadata. Do **not**
   fabricate, guess, or promote ambiguous Desktop images into this
   inventory (see tasks.md Visual Reference System §9.5 and the M03/M06
   phase logs' explicit note that unrelated Desktop images exist but are
   not SCRUBBOTS assets).
4. If no real artwork is supplied, explicitly mark every reference category
   `AWAITING OWNER ASSET` — do not mark M07 complete on directory
   structure alone.
5. While reviewing artwork, this is also the natural point for the project
   owner to actually **use** `scenes/debug/board_renderer_debug.tscn` to
   pick a DIRTY preset (or request a new one) — closing out M10's design
   gate is not required to start M07, but should happen before real art
   is imported and rendered in M09/M21.
6. Do not begin the pixel-art importer (M09), slots (M12), Scrubbots
   (M18), target selection (M15), or routing (M16-M17) in this milestone.
7. Start the phase log immediately as `SCRUBBOTS_PHASE_M07_LOG.md`, per the
   Phase Log Workflow above.
