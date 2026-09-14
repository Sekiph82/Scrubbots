# ScrubBots — Canonical GitHub Task State

This root TASKS.md is the only authoritative project-status tracker consumed by H!veAI. GitHub repository metadata and the latest commit are the remaining project-truth inputs. Hidden .hiveai control-plane files are historical only and are not read for current project state.

## Project Status

- Current Milestone: M22
- Current Sprint: M22-C001 V01 — production five-slot UI foundation
- Current Task: M22-C001-V01
- Current Task Status: IN_PROGRESS
- Next Task/Action: Claude executes `coordination/sessions/M22-C001/CHATGPT_PROMPT_V01.md` against `CHATGPT_AUDIT_CRITERIA_V01.md`, preserving M21 gameplay authority and root `TASKS.md`, then pushes `CLAUDE_LOG_V01.md` and hands back `AWAITING_AUDIT`; ChatGPT performs the independent M22 V01 audit and owns subsequent tracker updates/owner-gate decisions.
- Required Actor: CLAUDE
- Tracking Repository: Sekiph82/Scrubbots
- Tracking Branch: main
- Progress: 319 / 719 = 44.37% (main+ui); overall 319 / 943 = 33.83%; lastCompletedTaskId M21-C001-V10.
- Note: M21-C001 is `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` in `coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`. The owner manual V07 Godot gate passed and V08–V10 preserved production while closing strict validation evidence. Closed in this tracker update: `SB-M21-001..012` and `SB-UI-014..016`. M22 remains independent: the functional slot subset pulled forward into the M21 debug/owner harness is evidence/reuse input, not final production UI closure. M22 V01 builds reusable native-Godot five-slot components, validates the canonical owner gameplay reference and manifest, spends zero Magnific credits, and must not reopen accepted M21 gameplay truth. Root `TASKS.md` remains ChatGPT-write-owned.

## Tasks
# SCRUBBOTS — MASTER TASK PLAN

> **H!veAI tracking [OWNER-LOCKED — updated 2026-09-14]:** repository-root `TASKS.md` is the one and only live project-status tracker. The top `Project Status` block controls current milestone, sprint, task, actor, next action, workflow status, and progress. Former `.hiveai` control-plane files are archived under `docs/migration/legacy-task-trackers/` and are historical evidence only. Never recreate or synchronize a competing live tracker. **ChatGPT is the sole writer of root `TASKS.md`; Claude/Codex read it but do not edit it. ChatGPT updates it after each independent audit, owner-gate decision, and before handing off the next implementation prompt.**

Permanent master execution roadmap for the SCRUBBOTS project. This file is
authoritative alongside `CLAUDE.md`. Read both at the start of every
session. ChatGPT updates this file after audit/owner-gate decisions; implementation agents do not mutate it.

Canonical local project: `C:\Users\sekip\Desktop\ScrubBots`
Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Primary branch: `main`

Verified at time of writing (end of Phase M06):
- HEAD commit at phase start: `89c7d43` ("feat: enforce Scrubbots
  difficulty board ranges") — see `docs/05_TECH_DECISIONS.md` and
  CHANGELOG for the Phase M06 commit that follows it.
- Working tree: clean, `main` up to date with `origin/main`
- Godot: `4.7.1.stable.official.a13da4feb` (installed, `godot --version` confirmed)
- Headless test suite (`tests/run_tests.gd`): **774/774 checks PASS**, exit
  code 0 (grown through M09/M11/M12/M13 and the META-C004 ACTIVE/CLEARED
  renderer migration; recomputed from the suite summary, not hardcoded)
- Official production difficulty bands (Easy/Medium/Hard/Very_Hard,
  20..59, max 59×59 = 3,481 cells) implemented and enforced via
  `DifficultyRules` + `ProductionLevelValidator`, kept separate from the
  generic dimension-agnostic `LevelValidator`/`BoardState` core.
- `BoardRenderer` implemented (single Image/ImageTexture, zero per-cell
  Nodes at any board size — ADR-011) with the owner-locked ACTIVE/CLEARED
  model (ADR-019): ACTIVE = source palette color/opaque, CLEARED =
  transparent (background shows through). **Owner manual QA of the
  transparent model is complete** (SB-M10-005..011 owner-approved on 2026-09-06).

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
- `TASKS.md` is updated by ChatGPT after independent audit/owner-gate review to reflect true status.
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
2. Read `TASKS.md` (this file) without modifying it.
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
15. Update authorized subsystem docs/evidence only.
16. **Do not edit root `TASKS.md`; ChatGPT owns tracker changes after audit/owner-gate review.**
17. Review `git diff` and ensure `TASKS.md` is absent from the implementation diff.
18. Commit (focused, descriptive message).
19. Push safely (`git push origin main`, never force).
20. Never force-push.
21. Write/update the matching GitHub `CLAUDE_LOG_VNN.md` and hand back `AWAITING_AUDIT`; ChatGPT then audits and updates `TASKS.md`.

---

## PHASE LOG WORKFLOW (supersedes the old per-prompt handoff-log convention)

**One development phase = one continuous Desktop log file**, not one log
per prompt. A "phase" is a milestone-level unit of work (e.g. `M03`, `M04`)
that may span multiple Claude prompts/sessions.

- Naming: `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` (e.g.
  `SCRUBBOTS_PHASE_M03_LOG.md`). `MXX` matches the `TASKS.md` milestone ID
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

### 8.3 — Official difficulty / board size bands `[LOCKED HISTORICAL RUNTIME COMPATIBILITY]`

The legacy production validator currently retains these dimension bands while Difficulty V1 migration is still open. They are not current player-facing difficulty truth; see `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md` and `CLAUDE.md`.

| Difficulty | Width range | Height range | Min cells | Max cells |
|---|---|---|---|---|
| EASY | 20–29 | 20–29 | 20×20 = 400 | 29×29 = 841 |
| MEDIUM | 30–39 | 30–39 | 30×30 = 900 | 39×39 = 1521 |
| HARD | 40–49 | 40–49 | 40×40 = 1600 | 49×49 = 2401 |
| VERY_HARD | 50–59 | 50–59 | 50×50 = 2500 | 59×59 = **3481** |

Examples of legacy-validator-valid boards: Easy `20×27`, Medium `34×39`, Hard `48×41`, Very Hard `53×59`.

**Current required production-capable maximum: 59×59 = 3,481 logical cells.**

### 8.4 — Rectangular boards `[LOCKED]`

Boards do **not** have to be square. Width and height are validated
independently. Never assume `width == height` in generic systems.

### 8.5 — Current maximum required workload `[LOCKED]`

`59×59 = 3,481` cells. All systems whose cost scales with board size must
eventually be tested against this workload: LevelData validation,
BoardState, BoardRenderer, color candidate index, reachability/access,
target selection, routing-related board queries, clearing updates, save/load
of level state if used, and production content validation.

### 8.6 — Test/dev fixtures vs. production levels `[LOCKED TECHNICAL RULE]`

The existing `test_3x2.json` fixture (6 cells) is valuable because it
proves the board engine is genuinely generic — it is **not** a production
level and must never be treated as one. Development fixtures may use a
`TEST` difficulty/context. `TEST` must never become a production difficulty
exposed to players, and the future production `LevelCatalog` must reject
accidental `TEST` fixtures (see M03, M30).

### 8.7 — Logical pixels `[LOCKED]`

One logical artwork square = one logical pixel = one board cell. Logical
cells are game data, never physical display pixels, and are never
represented as thousands of heavyweight Godot Nodes (see ADR-004, ADR-008).

### 8.7A — Global 16-color pixel-art palette `[LOCKED OWNER DECISION]`

Canonical machine-readable palette:
`data/palettes/scrubbots_palette_v2.json`

Canonical human-readable rule:
`docs/08_PIXEL_ART_PALETTE_RULES.md`

Production logical artwork cells may use **only C01..C16**. No other logical
pixel color is legal without an explicit owner rule change and palette version
change. CLEARED alpha-0 transparency, gameplay background and
presentation-only grid/border overlays are not logical artwork colors and do
not add palette IDs.

### 8.7B — Production used-color envelope `[OWNER-LOCKED DIFFICULTY V1]`

Production artwork may use **3–12** distinct canonical C01..C16 colors. The older class-specific `3–5 / 6–7 / 8–9 / 10–12` mapping is historical and superseded as difficulty-class legality; color count/distribution are Difficulty V1 score inputs instead.

### 8.8 — Five slots `[LOCKED]`

Primary gameplay presentation: **5 slots**. Player-visible gameplay uses
five slots. Internal code may stay configurable where sensible, but the
production game currently requires exactly five visible active slots.

### 8.9 — Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot does not leave unless a reachable/targetable matching target
  exists (a blocked/unreachable matching-color ACTIVE cell is not enough).
- A Scrubbot has a valid, reachable target *before* being dispatched.
- It visually moves from slot to target.
- On arrival the target logical pixel becomes CLEARED (transparent; the
  gameplay background shows through).
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

### 8.10A — Target selection positional priority `[LOCKED OWNER DECISION — 2026-09-13]`

For a requested slot/color, TargetSelector keeps the canonical eligibility
rules: the candidate must be a valid board index, ACTIVE, matching the requested
color, unreserved, and currently targetable/reachable according to authoritative
access truth. **Among candidates that can otherwise proceed under that contract,
selection priority is bottom-most first (largest board-local `y`), then left-most
within that row (smallest board-local `x`).** A blocked/unreachable lower or
leftward raw candidate never wins merely because of position; the selector
continues to the next candidate in deterministic bottom-to-top / left-to-right
priority. This is a WHAT-policy in TargetSelector only. Routing still decides HOW
to travel to the already-selected target and must not retarget based on geometry.

### 8.10B — One-cell exterior routing corridor `[LOCKED OWNER DECISION — 2026-09-13]`

Production routing must model a **one logical-cell-wide routing-only walking ring around all four board sides**. For board `W×H`, the exterior planner cells are: top `y=-1, x=-1..W`; bottom `y=H, x=-1..W`; left `x=-1, y=0..H-1`; right `x=W, y=0..H-1`, including all four corners. This ring is routing space only: it does not change LevelData, BoardState dimensions, palette cells, difficulty, or artwork. A clicked slot origin may connect through valid outside/background space to the ring; the Scrubbot may travel around the ring and enter an assigned ACTIVE perimeter target only as final arrival. Non-target ACTIVE cells remain blockers and enclosed interior ACTIVE targets remain unreachable until a legal opening exists.

### 8.10C — Slot-click-only owner gameplay activation `[LOCKED OWNER DECISION — 2026-09-13]`

The owner-playable gameplay path is **visible color-slot click only**. The SPACE gameplay fallback is superseded and must be removed; do not replace it with another hidden keyboard dispatch shortcut. A successful activation begins from the exact clicked SlotView spawn anchor and then follows the real CompleteClearingLoop → TargetSelector → Routing → Dispatcher → ScrubbotAgent → authenticated clear chain.

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

### Production gameplay background `[LOCKED]`

- BG01 **Midnight Slate** = `#202533` / RGB(32,37,51).
- CLEARED alpha-0 cells reveal BG01 underneath.
- BG01 is not part of C01..C16 and is never a logical LevelData cell
  color, and never counts toward difficulty distinct-color totals.
- Debug-only transparency backgrounds may differ for visibility.

---

## VISUAL REFERENCE SYSTEM

SCRUBBOTS has (per the owner) prior artwork and visual concepts. The
project must use them rather than defaulting to generic programmer art —
but **only artwork that physically exists in this project or is supplied
during a task counts as available**. A visual discussed in a prior chat is
not automatically a local file.

**Verified at time of writing**: owner references and the approved M21 Hazard Bot are now present in-repo; historical “all empty” statements elsewhere are superseded by current inventory/coordination evidence.

### 9.1 — Visual reference priority `[LOCKED]`

**Priority 1 — Owner-approved original SCRUBBOTS artwork.** Canonical
visual reference: character concepts, gameplay concepts, five-slot layouts,
pixel-art level artwork, themed level artwork, original UI ideas, effects
concepts, screen compositions. If original approved artwork conflicts with a
generic placeholder, the original artwork wins.

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
characters, compositions, object placement, or level art. External-reference
colors must never redefine the SCRUBBOTS palette. The exact production palette
is owner-locked in §8.7A / `data/palettes/scrubbots_palette_v2.json`.
The goal is understanding how a readable image is built from a limited
logical grid. SCRUBBOTS level artwork remains original.

### 9.4 — Existing SCRUBBOTS level art `[LOCKED]`

Existing original SCRUBBOTS level artwork is intended to become real playable
content once owner-approved source files are supplied/recorded. Never regenerate
such pieces from memory and present the result as “the original.” The M21 Hazard
Bot source is the first owner-approved production-art fixture and must remain
byte-identical unless the owner explicitly replaces it.

### 9.5 — Reference file availability `[LOCKED]`

Claude only has access to artwork physically present in the project or
supplied during the current task. If an expected visual does not exist
locally: `STATUS = AWAITING OWNER ASSET`. Do not fabricate it, do not mark
its audit complete, do not claim a pixel-accurate comparison was performed
against something that doesn't exist locally.

### 9.6 — Recommended visual directory structure

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

## VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]

1. Visual production is an integral part of the **main SCRUBBOTS mobile game project and roadmap**. It must not be split into a Level Factory/Content Pipeline-style sidecar or treated as an unrelated final art pass.
2. Magnific MCP remains the approved illustration-generation provider for the UI/character visual-production workflow unless the owner explicitly changes that decision. PixelLab/native pixel AI work is separately scoped to semantic pixel-art generation and does not own puzzle logic.
3. AI image generation is a **development-time tool only**. The shipping game must never require generation APIs, credentials, or credits at runtime. Owner-approved generated outputs become ordinary versioned Godot assets.
4. Existing owner-created SCRUBBOTS artwork is the first visual authority. Import/copy and classify owner references before generating replacements or variants. Never overwrite or delete the owner's originals.
5. AI-generated full-screen mockups are art-direction/reference material, not shippable UI. Production screens must be composed from responsive Godot Controls/Containers plus approved illustration assets.
6. Prefer native Godot UI for panels, buttons/interaction containers, progress bars, slots, color tiles, currency counters, text, popup bodies, dim layers and responsive layout. Use generation for art that genuinely benefits from illustration generation: characters, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event art and similar branded artwork.
7. Raw generation candidates and owner-approved production assets are different lifecycle states. Never silently regenerate, replace or overwrite an approved production asset.
8. Every milestone that requires new visual assets owns its own visual-generation/review/import tasks. Do not postpone all visual production to one disconnected end-of-project art phase.
9. `docs/MASTER_UI_SYSTEM.md` is the canonical responsive UI architecture contract. `ASSET_GENERATION_MANIFEST.json` is the machine-readable Magnific generation queue/provenance contract.
10. `BoardRenderer` remains the existing single-`Image`/`ImageTexture` data-oriented renderer. The Master UI system must not replace logical board rendering with one UI node per cell.
11. Visual milestone completion requires actual owner-approved assets where required, correct Godot import/binding, responsive validation and regression evidence. A generated image existing on disk is not by itself completion.

### Visual production order

1. **Reference intake and canonical visual selection first.** Import owner references copy-only into the repository reference inbox, inventory/classify them, and select canonical Scrubby/gameplay/home/popup references before broad generation.
2. **Core gameplay engineering continues without waiting for decorative art.** Target selection, routing, dispatcher/agent behavior, cleaning rules and other gameplay-critical work must not be blocked by decorative asset production when programmer art is sufficient.
3. **First real-art vertical slice.** Validate gameplay with owner-approved real level/pixel artwork before treating production visuals as proven. AI image generation must not invent canonical puzzle truth or replace the level-data/puzzle-validation pipeline.
4. **Production gameplay UI asset generation begins when the relevant gameplay UI milestones open.** Generate only assets required by that milestone, review them, promote approved variants, then bind them to reusable Godot components.
5. **Final Scrubbot visual production happens in the existing Scrubbot visual milestone**, using the canonical Scrubby reference and approved visual language.
6. **Home, Results, Tutorial, Collection, Shop, Events and later screens generate their own required assets inside their existing milestones.** They do not wait for a separate global art project.
7. Final visual polish is a consolidation/QA pass over already-integrated milestone-owned art, not the first time production art is introduced.

---

## DESIGN GATES

Unresolved. Do not silently invent final decisions for these:

Exact slot refill/replacement behavior; whether slots hold quantities;
hidden/upcoming slot queue; exact route visual styling beyond the locked
one-cell exterior corridor/access law; route collision/congestion presentation;
exact win condition; exact lose condition; timer; move limits; lives; blockers;
boosters; hints; progression structure; currency meaning; economy; shop;
monetization; ads; IAP; energy system; analytics; achievements; leaderboard;
social features; cloud save; tutorial wording; audio direction.

**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, one-cell exterior routing corridor, and visible-slot-click-only owner activation are owner-locked.

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
- [x] SB-M02-004 ACTIVE state implemented (`CellState.ACTIVE = 0`; fresh board all-ACTIVE).
- [x] SB-M02-005 CLEARED state implemented (`CellState.CLEARED = 1`).
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
- [x] SB-M02-017 Add RESERVED only when reservation architecture is designed (see M14). — resolved by ADR-022: reservation is a separate assignment layer; BoardState remains ACTIVE/CLEARED only.

### M03 — Official Difficulty Bands + 59×59 Envelope

Historical runtime-validator milestone. Difficulty V1 later superseded class=dimension as player-facing truth, but the completed compatibility implementation remains audited evidence until separately migrated.

**Documentation**
- [x] SB-M03-001 Search docs for old claim that 40×40 is "standard."
- [x] SB-M03-002 Search docs for claim 50×50 is the Very Hard requirement without a range.
- [x] SB-M03-003 Search for `2500` used as a maximum.
- [x] SB-M03-004 Update `CLAUDE.md`.
- [x] SB-M03-005 Update project brief.
- [x] SB-M03-006 Update gameplay specification.
- [x] SB-M03-007 Update technical architecture.
- [x] SB-M03-008 Update Level Data spec.
- [x] SB-M03-009 Update roadmap.
- [x] SB-M03-010 Update test strategy.
- [x] SB-M03-011 Add/amend ADR for official difficulty dimension bands (ADR-010).

**Production difficulty representation**
- [x] SB-M03-012 Define canonical legacy runtime production difficulty IDs (`DifficultyRules`).
- [x] SB-M03-013 EASY = dimensions 20..29.
- [x] SB-M03-014 MEDIUM = dimensions 30..39.
- [x] SB-M03-015 HARD = dimensions 40..49.
- [x] SB-M03-016 VERY_HARD = dimensions 50..59.
- [x] SB-M03-017 Keep TEST/dev fixture concept separate.
- [x] SB-M03-018 Production validator rejects TEST.

**Validation**
- [x] SB-M03-019 Add production difficulty/dimension validation.
- [x] SB-M03-020 Accept Easy rectangular boards.
- [x] SB-M03-021 Accept Medium rectangular boards.
- [x] SB-M03-022 Accept Hard rectangular boards.
- [x] SB-M03-023 Accept Very Hard rectangular boards.
- [x] SB-M03-024 Reject cross-band Easy dimensions.
- [x] SB-M03-025 Reject cross-band Medium dimensions.
- [x] SB-M03-026 Reject cross-band Hard dimensions.
- [x] SB-M03-027 Reject cross-band Very Hard dimensions.
- [x] SB-M03-028 Produce explicit errors.

### M04 — Expanded Board Fixtures & Test Matrix

Do not replace existing Prompt 02 fixtures — add to them.

- [x] SB-M04-001 3×2 generic non-square fixture exists.
- [x] SB-M04-002 20×20. — [x] SB-M04-003 29×29. — [x] SB-M04-004 20×27.
- [x] SB-M04-005 30×30. — [x] SB-M04-006 39×39. — [x] SB-M04-007 34×39.
- [x] SB-M04-008 40×40 generic fixture exists.
- [x] SB-M04-009 49×49. — [x] SB-M04-010 48×41.
- [x] SB-M04-011 50×50 generic fixture exists.
- [x] SB-M04-012 59×59. — [x] SB-M04-013 53×59.
- [x] SB-M04-014 Easy 20×30 fails legacy production validation.
- [x] SB-M04-015 Medium 39×40 fails.
- [x] SB-M04-016 Hard 49×50 fails.
- [x] SB-M04-017 Very Hard 49×59 fails.
- [x] SB-M04-018 59×59 loads successfully.
- [x] SB-M04-019 `cell_count == 3481`.
- [x] SB-M04-020 Coordinate/index tests pass at 59×59.
- [x] SB-M04-021 State mutation tests pass at 59×59.
- [x] SB-M04-022 Performance sanity benchmark runs at 3,481 cells.
- [x] SB-M04-023 Record results without arbitrary strict timing threshold.

### M05 — Test Harness Maturity

- [x] SB-M05-001 Headless test script exists.
- [x] SB-M05-002 Test process returns failure exit code.
- [x] SB-M05-003 Current tests print PASS/failure information.
- [x] SB-M05-004 No third-party test framework required.
- [x] SB-M05-005 Current baseline checks pass.
- [ ] SB-M05-006 Organize test sections as suite grows.
- [ ] SB-M05-007 Separate performance benchmark output from assertions.
- [ ] SB-M05-008 Add one-command PowerShell full-test wrapper if useful.
- [ ] SB-M05-009 Add regression test conventions to docs.
- [ ] SB-M05-010 Ensure future milestone completion requires regression pass.

### M06 — Board Renderer

- [x] SB-M06-001 Define BoardRenderer responsibility.
- [x] SB-M06-002 Keep BoardRenderer separate from BoardState.
- [x] SB-M06-003 Evaluate efficient Godot rendering options.
- [x] SB-M06-004 Choose Image/ImageTexture technique.
- [x] SB-M06-005 Record technique in ADR.
- [x] SB-M06-006 Render arbitrary width/height.
- [x] SB-M06-007 Support rectangular board aspect ratio.
- [x] SB-M06-008 Preserve logical pixel boundaries.
- [x] SB-M06-009 Disable unwanted texture filtering.
- [x] SB-M06-010 Render palette colors correctly.
- [x] SB-M06-011 Render 20×20. — [x] SB-M06-012 Render 29×29.
- [x] SB-M06-013 Render 39×39. — [x] SB-M06-014 Render 49×49.
- [x] SB-M06-015 Render 50×50. — [x] SB-M06-016 Render 59×59.
- [x] SB-M06-017 Render representative rectangular boards.
- [x] SB-M06-018 Expose logical-cell center coordinate.
- [x] SB-M06-019 Support efficient individual-cell update.
- [x] SB-M06-020 Support full reset.
- [x] SB-M06-021 Benchmark 3,481-cell display.
- [x] SB-M06-022 Confirm no 3,481-cell Node tree exists.

### M07 — Visual Reference Library `[VISUAL REFERENCE]`

- [x] SB-M07-001 Establish reference directory structure.
- [x] SB-M07-002 Create visual-reference README/guide.
- [x] SB-M07-003 Separate original SCRUBBOTS art from external inspiration.
- [x] SB-M07-004 Define canonical asset naming.
- [x] SB-M07-005 Define asset type metadata.
- [x] SB-M07-006 Define owner-approved status.
- [x] SB-M07-007 Preserve source file originals.
- [x] SB-M07-008 Inventory Scrubbot character visuals supplied by owner.
- [x] SB-M07-009 Inventory gameplay-screen references supplied by owner.
- [x] SB-M07-010 Inventory five-slot visual references.
- [ ] SB-M07-011 Inventory level images beyond current M21 source as they are supplied/approved.
- [ ] SB-M07-012 Inventory underwater level artwork if supplied.
- [ ] SB-M07-013 Inventory other original theme artwork.
- [x] SB-M07-014 Inventory pixel-construction reference screenshots.
- [x] SB-M07-015 Inventory external movement references separately.
- [x] SB-M07-016 Flag unavailable assets as `AWAITING OWNER ASSET`.
- [x] SB-M07-017 Never regenerate missing references and label them originals.

**Master UI / Magnific visual reference tasks (from UI_TASKS_APPENDIX migration)**
- [ ] SB-UI-001 Treat `docs/MASTER_UI_SYSTEM.md` as the UI architecture source of truth.
- [ ] SB-UI-002 Treat `ASSET_GENERATION_MANIFEST.json` as the machine-readable generation/provenance queue.
- [ ] SB-UI-003 Keep approved provider decisions scoped by asset type and newest owner decisions.
- [ ] SB-UI-004 Do not add unapproved generation providers as project runtime dependencies.
- [x] SB-UI-005 Import owner visual references copy-only.
- [x] SB-UI-006 Preserve originals/copies byte-for-byte and inventory before promotion.
- [x] SB-UI-007 Classify owner references.
- [ ] SB-UI-008 Select and record canonical Scrubby master reference before final Scrubby production generation.
- [x] SB-UI-009 Select canonical gameplay-screen art-direction reference.
- [x] SB-UI-010 Select canonical Home-screen art-direction reference.
- [x] SB-UI-011 Select canonical popup/level-intro references.
- [x] SB-UI-012 Identify conflicting/outdated references and retain as non-canonical history.
- [ ] SB-UI-013 Validate manifest reference paths/IDs after canonical references are selected.

### M08 — Level Art Technical Audit `[CONTENT] [VISUAL REFERENCE]`

Per candidate production pixel-art level:

- [ ] SB-M08-001 Record filename. — [ ] SB-M08-002 Record original dimensions.
- [ ] SB-M08-003 Record alpha/transparency. — [ ] SB-M08-004 Count colors.
- [ ] SB-M08-005 Detect anti-aliasing. — [ ] SB-M08-006 Detect interpolation.
- [ ] SB-M08-007 Determine logical-pixel grid.
- [ ] SB-M08-008 Determine legal production envelope/context.
- [ ] SB-M08-009 Confirm width in legal engine envelope.
- [ ] SB-M08-010 Confirm height in legal engine envelope.
- [ ] SB-M08-011 Preserve original. — [ ] SB-M08-012 Never silently resize.
- [ ] SB-M08-013 Explicitly map/reject source colors against locked C01..C16; never invent C17+; record deterministic mapping/rejection evidence.
- [ ] SB-M08-014 Produce audit report.

### M09 — Pixel Art → Level Data Pipeline `[CONTENT]`

- [x] SB-M09-001 Create importer tool.
- [x] SB-M09-002 Read source pixels exactly.
- [x] SB-M09-003 Determine width. — [x] SB-M09-004 Determine height.
- [x] SB-M09-005 Determine/validate legacy compatibility difficulty where required.
- [x] SB-M09-006 Extract unique palette.
- [x] SB-M09-007 Produce stable palette ordering.
- [x] SB-M09-008 Convert pixels to palette IDs.
- [x] SB-M09-009 Flatten using canonical row-major mapping.
- [x] SB-M09-010 Produce Level Data V1.
- [x] SB-M09-011 Store source-asset metadata where useful.
- [x] SB-M09-012 Deterministic output.
- [x] SB-M09-013 Re-running importer produces no meaningless diff.
- [x] SB-M09-014 Reconstruct image from generated data.
- [x] SB-M09-015 Pixel-compare reconstruction.
- [x] SB-M09-016 Generate preview.
- [x] SB-M09-017 Reject unsupported/broken art with useful reason.
- [x] SB-M09-018 Batch import.
- [x] SB-M09-019 Batch validation.
- [x] SB-M09-020 Duplicate level ID protection.

**M09 palette-lock note:** M09's completed exact-source-pixel importer remains valid historical/generic tooling evidence, but production acceptance additionally obeys current canonical palette/art/difficulty systems. Historical completion is not rewritten.

### M10 — ACTIVE/CLEARED Board Visual Model `[OWNER DECISION LOCKED]`

- [x] SB-M10-001 ACTIVE appearance locked to original source palette color, opaque.
- [x] SB-M10-002 CLEARED appearance locked to alpha 0/background visible.
- [x] SB-M10-003 Define artwork-clearing relationship.
- [x] SB-M10-004 Implement visual mapping.
- [x] SB-M10-005 Owner-confirm clearing readability.
- [x] SB-M10-006 Owner-confirm ACTIVE artwork recognition.
- [x] SB-M10-007 Owner test Easy density. — [x] SB-M10-008 Owner test Medium density.
- [x] SB-M10-009 Owner test Hard density. — [x] SB-M10-010 Owner test Very Hard density.
- [x] SB-M10-011 Owner test 59×59 transparent-model readability.
- [x] SB-M10-012 Development debug tool migrated/proven.

### M11 — Gameplay Session Core

- [x] SB-M11-001 Define session states.
- [x] SB-M11-002 Initialize level. — [x] SB-M11-003 Load LevelData.
- [x] SB-M11-004 Create BoardState. — [x] SB-M11-005 Connect renderer.
- [x] SB-M11-006 Define ready state. — [x] SB-M11-007 Define active state.
- [x] SB-M11-008 Define pause. — [x] SB-M11-009 Define reset.
- [x] SB-M11-010 Define completion transition.
- [x] SB-M11-011 Keep UI separate from gameplay truth.
- [x] SB-M11-012 Headless lifecycle tests.

### M12 — Five-Slot Logic

- [x] SB-M12-001 Create SlotState. — [x] SB-M12-002 Create SlotSystem.
- [x] SB-M12-003 Configure five gameplay slots.
- [x] SB-M12-004 Slot identity. — [x] SB-M12-005 Slot palette/color.
- [x] SB-M12-006 Slot availability. — [x] SB-M12-007 Slot activity state.
- [x] SB-M12-008 Keep model separate from UI. — [x] SB-M12-009 Query API.
- [x] SB-M12-010 Five-slot tests. — [x] SB-M12-011 Invalid slot tests.

Remaining slot mechanics are `[DESIGN GATE]` except where newer owner decisions explicitly lock behavior.

### M13 — Color Candidate Index `[PERFORMANCE]`

- [x] SB-M13-001 Define color candidate.
- [x] SB-M13-002 Group/query by color.
- [x] SB-M13-003 Implement efficient index/cache if measured useful.
- [x] SB-M13-004 Synchronize with BoardState.
- [x] SB-M13-005 Remove CLEARED cells from the index. — [x] SB-M13-006 Handle caller exclusions/reservations seam.
- [x] SB-M13-007 No-candidate query. — [x] SB-M13-008 Exhausted-color test.
- [x] SB-M13-009 Last-candidate test. — [x] SB-M13-010 3,481-cell benchmark.

### M14 — Reservation State

- [x] SB-M14-001 Define reservation ownership.
- [x] SB-M14-002 Decide RESERVED placement.
- [x] SB-M14-003 Record decision.
- [x] SB-M14-004 Reserve target atomically.
- [x] SB-M14-005 Prevent double reservation.
- [x] SB-M14-006 Release on dispatch failure. — [x] SB-M14-007 Release on reset.
- [x] SB-M14-008 Resolve arrival. — [x] SB-M14-009 Concurrency tests.

### M15 — TargetSelector

M15 strict closure remains accepted. V04 later superseded only its target ordering policy while preserving strict safety contracts.

- [x] SB-M15-001 Create TargetSelector.
- [x] SB-M15-002 Keep BoardState access narrow.
- [x] SB-M15-003 Deterministic strategy. **Current production ordering is owner rule §8.10A: bottom-most then left-most among targetable candidates.**
- [x] SB-M15-004 Match Scrubbot color.
- [x] SB-M15-005 Never target CLEARED. — [x] SB-M15-006 Never target invalid or blocked/unreachable ACTIVE cells.
- [x] SB-M15-007 Respect reservations.
- [x] SB-M15-008 Return no-target cleanly.
- [x] SB-M15-009 No route generation inside selector.
- [x] SB-M15-010 Determinism tests.
- [x] SB-M15-011 Simultaneous assignment tests.
- [x] SB-M15-012 3,481-cell benchmark.

### M16 — RoutingSystem Interface

- [x] SB-M16-001 Define RoutingSystem contract.
- [x] SB-M16-002 Define route input. — [x] SB-M16-003 Define route output.
- [x] SB-M16-004 Define coordinate space.
- [x] SB-M16-005 Slot origin. — [x] SB-M16-006 Cell destination.
- [x] SB-M16-007 Keep independent from TargetSelector.
- [x] SB-M16-008 Swappable implementations.
- [x] SB-M16-009 Debug route visualization.
- [x] SB-M16-010 Route validity checks.
- [x] SB-M16-011 Failure behavior/no silent retarget.

### M17 — Routing Prototype Lab / Production Routing

M17-C002 V03 strict full-surface audit remains accepted as the pre-V07 production-routing baseline. V07 is an owner-directed extension of the production planner domain, not a rewrite of WHAT-selection or access truth.

- [x] SB-M17-001 Direct route baseline.
- [x] SB-M17-002 Grid-aware route prototype.
- [x] SB-M17-003 Organized polyline/curved prototype.
- [x] SB-M17-004 Compare visual clarity. — [x] SB-M17-005 Compare path crossings.
- [x] SB-M17-006 Compare congestion. — [x] SB-M17-007 Compare CPU cost.
- [x] SB-M17-008 Compare route distance. — [x] SB-M17-009 Compare determinism.
- [x] SB-M17-010 Owner-selected organized/curved production movement language.
- [x] SB-M17-011 Test 5 bots. — [x] SB-M17-012 Test 10 bots. — [x] SB-M17-013 Test 25 bots.
- [x] SB-M17-014 Stress-test higher density.
- [x] SB-M17-015 Test 59×59. — [x] SB-M17-016 Test rectangular board.

**V07 owner amendment:** production routing must add the one-cell exterior walking ring in §8.10B while preserving M17 strict route validation, no-retarget, ACTIVE-blocker/CLEARED-open semantics, rectangular support and 59×59 behavior.

### M18 — Scrubbot Agent

- [x] SB-M18-001 Lightweight agent core.
- [x] SB-M18-002 Assigned color. — [x] SB-M18-003 Assigned target.
- [x] SB-M18-004 Assigned route. — [x] SB-M18-005 Spawn origin.
- [x] SB-M18-006 Route movement. — [x] SB-M18-007 Arrival detection.
- [x] SB-M18-008 Completion event. — [x] SB-M18-009 Despawn.
- [x] SB-M18-010 No return-to-slot. — [x] SB-M18-011 No resource carrying.
- [x] SB-M18-012 Reset cancellation. — [x] SB-M18-013 No orphan nodes.
- [x] SB-M18-014 Performance stress test.
- [x] SB-M18-015 Pool only if profiling justifies it.

### M19 — Scrubbot Dispatcher

**Strict-v2 final closure:** M19-C001 V06 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`.

- [x] SB-M19-001 Receive slot request.
- [x] SB-M19-002 Check reachable work before spawn.
- [x] SB-M19-003 Ask TargetSelector.
- [x] SB-M19-004 Refuse spawn without reachable target.
- [x] SB-M19-005 Reserve target.
- [x] SB-M19-006 Spawn exactly one bot per dispatch.
- [x] SB-M19-007 Enforce one-by-one flow.
- [x] SB-M19-008 Prevent duplicate assignments.
- [x] SB-M19-009 Handle dispatch failure.
- [x] SB-M19-010 Handle rapid input.
- [x] SB-M19-011 Concurrent slot tests. — [x] SB-M19-012 Reset during dispatch.

### M20 — Complete Clearing Vertical Slice

- [x] SB-M20-001 Wire complete sequence.
- [x] SB-M20-002 No target means no bot. — [x] SB-M20-003 No return behavior.
- [x] SB-M20-004 One-cell test. — [x] SB-M20-005 One-color test.
- [x] SB-M20-006 Multi-color test. — [x] SB-M20-007 Five-slot test.
- [x] SB-M20-008 Easy board test. — [x] SB-M20-009 Medium board test.
- [x] SB-M20-010 Hard board test. — [x] SB-M20-011 Very Hard board test.
- [x] SB-M20-012 59×59 stress test. — [x] SB-M20-013 Rectangular board test.
- [x] SB-M20-014 State-desynchronization check.

### M21 — First Real-Art Vertical Slice `[CONTENT] [VISUAL REFERENCE]`

**Strict-v2 final closure:** M21-C001 V10 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` (`coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`). Owner manual V07 Godot gate PASS remains part of the closure basis. V08–V10 were production-immutable validation passes.

The owner-approved real Hazard Bot source is:
`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.

Locked runtime outcomes carried forward:
- visible slot-click-only gameplay activation; no SPACE/hidden keyboard dispatch;
- exact one-logical-cell exterior routing ring on all four sides;
- TargetSelector bottom-most then left-most among currently targetable matching cells;
- fresh Hazard Bot C08 first target index `380`, coordinate `(0,19)`;
- real clicked-slot spawn anchor -> routing -> authenticated arrival -> ACTIVE→CLEARED transparency;
- exact ReservationState/dispatcher/agent lifecycle under rapid input and reset;
- full 400-cell real-art clear across all five colors;
- reference composite and generated LevelData/preview/metadata reproducible/unchanged.

- [x] SB-M21-001 Ingest original source artwork.
- [x] SB-M21-002 Audit source dimensions.
- [x] SB-M21-003 Determine legal compatibility context.
- [x] SB-M21-004 Generate level data.
- [x] SB-M21-005 Reconstruct and compare.
- [x] SB-M21-006 Render in gameplay.
- [x] SB-M21-007 Populate and visibly present exactly five functional slots bound to the real SlotSystem.
- [x] SB-M21-008 Dispatch a visibly moving real ScrubbotAgent from the clicked visible slot through board-aligned presentation and exterior corridor.
- [x] SB-M21-009 Clear actual artwork pixels (ACTIVE→CLEARED; transparent background reveal).
- [x] SB-M21-010 Run full level.
- [x] SB-M21-011 Profile performance.
- [x] SB-M21-012 Capture reference gameplay output.

**First real-art vertical slice additions**
- [x] SB-UI-014 Run at least one gameplay vertical slice using owner-approved real pixel/level artwork.
- [x] SB-UI-015 Prove logical renderer/ACTIVE-CLEARED treatment/responsive presentation remain data-driven.
- [x] SB-UI-016 Record visual gaps requiring later illustration generation.

### M22 — Production Slot UI `[VISUAL REFERENCE]`

**Current sprint:** M22-C001 V01 production five-slot UI foundation. The functional SlotView subset pulled forward into M21 V04–V07 is accepted reuse/evidence input, but final M22 closure remains independent and must not be inferred from the temporary/debug owner harness.

V01 builds reusable native-Godot production SlotCell/ColorSelectionPanel components, audits canonical owner slot/gameplay references, validates/corrects the generation manifest's stale palette/difficulty contract, proves responsive touch/spawn/active behavior, and preserves the closed M21 gameplay authority. V01 spends **zero Magnific credits**. `SB-M22-008` no-work visual styling remains design-gated; `SB-M22-015..019` generation/promotion rows remain outside V01 unless later owner scope explicitly opens them.

- [ ] SB-M22-001 Audit slot references. — [ ] SB-M22-002 Create SlotView.
- [ ] SB-M22-003 Five-slot layout. — [ ] SB-M22-004 Bind SlotState.
- [ ] SB-M22-005 Color presentation. — [ ] SB-M22-006 Touch target.
- [ ] SB-M22-007 Active state. — [ ] SB-M22-008 No-work state if approved.
- [ ] SB-M22-009 Scrubbot spawn point.
- [ ] SB-M22-010 Aspect-ratio tests. — [ ] SB-M22-011 Safe-area tests.
- [ ] SB-M22-012 Rapid-tap tests.
- [ ] SB-M22-013 Confirm canonical gameplay UI references before final asset generation.
- [ ] SB-M22-014 Validate M22 manifest entries before spending generation credits.
- [ ] SB-M22-015 Generate required gameplay booster assets when milestone scope opens.
- [ ] SB-M22-016 Generate only milestone-required decorative assets.
- [ ] SB-M22-017 Keep raw candidates separate from production-final assets/provenance.
- [ ] SB-M22-018 Require owner selection/approval before production promotion.
- [ ] SB-M22-019 Never silently regenerate/overwrite approved production art.
- [ ] SB-M22-020 Build slot visuals as reusable Godot components.
- [ ] SB-M22-021 Keep quantities/text/state badges live in Godot.
- [ ] SB-M22-022 Implement reusable BoosterButton states when booster scope opens.
- [ ] SB-M22-023 Bind approved booster/decorative art to reusable components.
- [ ] SB-M22-024 Preserve five visible slots at required responsive sizes.
- [ ] SB-M22-025 Validate import/transparency/filtering/mobile memory before visual closure.

### M23 — Gameplay Screen Layout `[VISUAL REFERENCE]`

- [ ] SB-M23-001 Audit original gameplay reference images.
- [ ] SB-M23-002 Board region. — [ ] SB-M23-003 Five-slot region.
- [ ] SB-M23-004 HUD region. — [ ] SB-M23-005 Safe areas.
- [ ] SB-M23-006 Easy dimensions. — [ ] SB-M23-007 Medium dimensions.
- [ ] SB-M23-008 Hard dimensions. — [ ] SB-M23-009 Very Hard dimensions.
- [ ] SB-M23-010 Rectangular boards. — [ ] SB-M23-011 59×59.
- [ ] SB-M23-012 Narrow phone. — [ ] SB-M23-013 Tall phone.
- [ ] SB-M23-014 Tablet portrait. — [ ] SB-M23-015 Input coordinate accuracy.
- [ ] SB-M23-016 Use `docs/MASTER_UI_SYSTEM.md` as canonical gameplay layout contract.
- [ ] SB-M23-017 Remove Goal/Moves panel from approved production gameplay composition.
- [ ] SB-M23-018 Make board dominant gameplay-screen region.
- [ ] SB-M23-019 Keep color-selection panel protected/usable.
- [ ] SB-M23-020 Place Scrubby low at left of color-selection region.
- [ ] SB-M23-021 Place speech bubble above Scrubby.
- [ ] SB-M23-022 Preserve right-side cleaning props as lower-priority decoration.
- [ ] SB-M23-023 Put four booster controls in compact horizontal row above bottom/ad row.
- [ ] SB-M23-024 Pause left of ad, settings right of ad.
- [ ] SB-M23-025 Do not restore removed Level/lock rail.
- [ ] SB-M23-026 Bind owner-approved illustrations while keeping screen responsive/native.
- [ ] SB-M23-027 Prove BoardRenderer coordinate mapping after responsive scaling.
- [ ] SB-M23-028 Capture viewport validation evidence.

### M24 — Mobile Touch

- [ ] SB-M24-001 Touch slot activation.
- [ ] SB-M24-002 Desktop mouse development support.
- [ ] SB-M24-003 Prevent mouse/touch double-fire.
- [ ] SB-M24-004 Touch cancel. — [ ] SB-M24-005 Focus loss.
- [ ] SB-M24-006 Rapid tapping. — [ ] SB-M24-007 Multi-touch.
- [ ] SB-M24-008 Pause during touch. — [ ] SB-M24-009 Background/foreground.

### M25 — Win/Lose Rules `[DESIGN GATE]`

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

- [ ] SB-M27-001 Audit original Scrubbot art.
- [ ] SB-M27-002 Select owner-approved canonical design.
- [ ] SB-M27-003 Preserve original source.
- [ ] SB-M27-004 Configure crisp import.
- [ ] SB-M27-005 Visual component. — [ ] SB-M27-006 Travel animation.
- [ ] SB-M27-007 Arrival animation. — [ ] SB-M27-008 Disappearance.
- [ ] SB-M27-009 Direction/orientation if approved.
- [ ] SB-M27-010 Density performance test.
- [ ] SB-M27-UI-001 Use owner-approved canonical Scrubby reference for character generation.
- [ ] SB-M27-UI-002 Validate pose/state manifest entries before generation.
- [ ] SB-M27-UI-003 Generate only poses required by implemented behavior.
- [ ] SB-M27-UI-004 Generate required portrait/profile variants.
- [ ] SB-M27-UI-005 Generate emotion/state variants only when implemented flow needs them.
- [ ] SB-M27-UI-006 Preserve raw candidates/provenance separately.
- [ ] SB-M27-UI-007 Require owner visual approval before promotion.
- [ ] SB-M27-UI-008 Lock approved character assets against silent overwrite.
- [ ] SB-M27-UI-009 Configure Godot import settings.
- [ ] SB-M27-UI-010 Integrate approved art without coupling animation to TargetSelector logic.
- [ ] SB-M27-UI-011 Validate readability/scale on phone viewport matrix.

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

**Difficulty V1 owner decision now governs future work.** Board dimensions remain an engine/content envelope and Session Load input, not the definition of EASY/MEDIUM/HARD/VERY_HARD.

- [ ] SB-M31-001 Migrate legacy runtime class=dimension configuration to Difficulty V1 without breaking board envelope validation.
- [ ] SB-M31-002 Validate production catalog against current Difficulty V1 + compatibility requirements.
- [ ] SB-M31-003 Implement/version Challenge components and owner-approved additional factors.
- [ ] SB-M31-004 Create Difficulty V1 matrix/calibration fixtures.
- [ ] SB-M31-005 Playtest difficulty.
- [ ] SB-M31-006 Prove board size alone cannot determine difficulty class.

### M32 — Level Progression

- [ ] SB-M32-001 Implement owner-locked repeating 10-level class cadence.
- [ ] SB-M32-002 Current level.
- [ ] SB-M32-003 Completion tracking. — [ ] SB-M32-004 Replay.
- [ ] SB-M32-005 Implement progression target curve/micro modifiers from Difficulty V1.
- [ ] SB-M32-006 Level select if approved.
- [ ] SB-M32-007 Service implementation. — [ ] SB-M32-008 Tests.

### M33 — Win Streak

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
- [ ] SB-M37-010 Build Home as responsive Godot containers/components.
- [ ] SB-M37-011 Recreate owner-approved Home art direction with canonical regions.
- [ ] SB-M37-012 Keep shortcut columns responsive around central area.
- [ ] SB-M37-013 Validate Home-specific manifest entries before generation.
- [ ] SB-M37-014 Generate only Home-specific required illustrative assets.
- [ ] SB-M37-015 Keep dynamic values/timers/counts/labels live in Godot UI.
- [ ] SB-M37-016 Require owner approval before production promotion.
- [ ] SB-M37-017 Bind approved art and validate viewport matrix.

### M38 — Results Screen

- [ ] SB-M38-001 Result model. — [ ] SB-M38-002 Completion UI.
- [ ] SB-M38-003 Streak. — [ ] SB-M38-004 Reward if defined.
- [ ] SB-M38-005 Continue. — [ ] SB-M38-006 Replay if approved.
- [ ] SB-M38-007 No double reward. — [ ] SB-M38-008 Rapid-tap protection.

**Shared later-screen visual production rules**
- [ ] SB-UI-017 Implement reusable `BasePopup` composition.
- [ ] SB-UI-018 Keep popup text/rewards/quantities/buttons/state dynamic in Godot.
- [ ] SB-UI-019 For each later screen milestone, identify/generate/approve/bind required illustration assets inside that milestone.
- [ ] SB-UI-020 Do not pre-generate speculative asset libraries for unknown future states.
- [ ] SB-UI-021 Treat final visual polish as consolidation/QA, not first production-art implementation.

### M39 — Tutorial `[DESIGN GATE]`

Teach five-slot interaction, color matching, Scrubbot flow, no-work behavior if needed. Keep tutorial logic separate from core gameplay.

### M40 — Debug Tooling

- [ ] SB-M40-001 Debug overlay. — [ ] SB-M40-002 Level ID.
- [ ] SB-M40-003 Difficulty. — [ ] SB-M40-004 Dimensions.
- [ ] SB-M40-005 Cell count. — [ ] SB-M40-006 ACTIVE count. — [ ] SB-M40-007 CLEARED count.
- [ ] SB-M40-008 Reserved count if implemented. — [ ] SB-M40-009 Active bots.
- [ ] SB-M40-010 FPS. — [ ] SB-M40-011 Frame time.
- [ ] SB-M40-012 Target markers. — [ ] SB-M40-013 Route visualization.
- [ ] SB-M40-014 Cell grid. — [ ] SB-M40-015 Effect toggle.
- [ ] SB-M40-016 Instant reset. — [ ] SB-M40-017 Level switcher.
- [ ] SB-M40-018 Disable release-facing debug UI.

### M41 — Performance `[PERFORMANCE]`

Maximum board target: 59×59 = 3,481.

- [ ] SB-M41-001 Level parsing. — [ ] SB-M41-002 BoardState. — [ ] SB-M41-003 Renderer.
- [ ] SB-M41-004 Color candidate index + reachability/access. — [ ] SB-M41-005 TargetSelector. — [ ] SB-M41-006 Routing.
- [ ] SB-M41-007 Scrubbot agents. — [ ] SB-M41-008 Effects.
- [ ] SB-M41-009 Memory baseline. — [ ] SB-M41-010 59×59 memory.
- [ ] SB-M41-011 Per-frame allocation detection.
- [ ] SB-M41-012 Repeated restart. — [ ] SB-M41-013 Long session.
- [ ] SB-M41-014 High agent density.

### M42 — Android Device Testing

- [ ] SB-M42-001 Android export setup. — [ ] SB-M42-002 Development APK.
- [ ] SB-M42-003 Real device install. — [ ] SB-M42-004 Touch.
- [ ] SB-M42-005 Portrait. — [ ] SB-M42-006 Safe areas.
- [ ] SB-M42-007 Easy performance. — [ ] SB-M42-008 Medium performance.
- [ ] SB-M42-009 Hard performance. — [ ] SB-M42-010 Very Hard/59×59 performance.
- [ ] SB-M42-011 High bot density. — [ ] SB-M42-012 Background/foreground.
- [ ] SB-M42-013 Heat/battery extended test.
- [ ] SB-M42-014 Record device/results.

### M43 — iOS Readiness

- [ ] SB-M43-001 Avoid Android-only gameplay architecture.
- [ ] SB-M43-002 Document Apple toolchain requirement.
- [ ] SB-M43-003 Prepare iOS configuration when hardware exists.
- [ ] SB-M43-004 Real-device iOS testing later.

### M44 — Responsive UI

- [ ] SB-M44-001 16:9 portrait. — [ ] SB-M44-002 19.5:9. — [ ] SB-M44-003 20:9.
- [ ] SB-M44-004 Tall phone. — [ ] SB-M44-005 Tablet. — [ ] SB-M44-006 Notch/cutout.
- [ ] SB-M44-007 Five slots stay usable. — [ ] SB-M44-008 Board stays visible.
- [ ] SB-M44-009 Rectangular boards remain correctly scaled.
- [ ] SB-M44-010 Touch mapping remains accurate.
- [ ] SB-M44-011 Adopt 1080×2160 reference design viewport and stretch policy.
- [ ] SB-M44-012 Implement reusable SafeAreaRoot.
- [ ] SB-M44-013 Implement centralized UI tokens.
- [ ] SB-M44-014 Implement COMPACT/NORMAL/TALL classification.
- [ ] SB-M44-015 Validate 1080×2160.
- [ ] SB-M44-016 Validate 1170×2532.
- [ ] SB-M44-017 Validate 1290×2796.
- [ ] SB-M44-018 Validate 1080×2400.
- [ ] SB-M44-019 Validate 1440×3200.
- [ ] SB-M44-020 Validate minimum touch target.
- [ ] SB-M44-021 Confirm popups fit safe area.
- [ ] SB-M44-022 Confirm text containers survive localization expansion.
- [ ] SB-M44-023 Confirm protected bottom controls remain usable on compact devices.
- [ ] SB-M44-024 Add automated/manual responsive validation evidence.

### M45 — Accessibility

- [ ] SB-M45-001 Review color-only information.
- [ ] SB-M45-002 Alternative visual slot cues if necessary.
- [ ] SB-M45-003 Color vision tests. — [ ] SB-M45-004 Contrast.
- [ ] SB-M45-005 Reduced effects. — [ ] SB-M45-006 Touch sizes.
- [ ] SB-M45-007 Text readability.
- [ ] SB-M45-008 Do not encode important state solely in decorative art.
- [ ] SB-M45-009 Keep labels/counts live and contrast-independent from illustration.
- [ ] SB-M45-010 Ensure generated icon families distinguishable at mobile size.
- [ ] SB-M45-011 Ensure essential gameplay understandable without decoration.

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
- [ ] SB-M48-001 Legal dimensions/envelope. — [ ] SB-M48-002 Correct Difficulty V1 metadata/score context.
- [ ] SB-M48-003 Valid locked C01..C16 palette and current 3–12 used-color envelope; old class-specific color bands are not difficulty truth.
- [ ] SB-M48-004 Correct cell count.
- [ ] SB-M48-005 No invalid palette IDs. — [ ] SB-M48-006 Recognizable ACTIVE source artwork.
- [ ] SB-M48-007 No unintended interpolation. — [ ] SB-M48-008 Correct CLEARED transparency.
- [ ] SB-M48-009 Solvable under canonical routing/access semantics, including exterior corridor where applicable.
- [ ] SB-M48-010 No routing pathology; fully enclosed matching ACTIVE target remains untargetable until legal opening.
- [ ] SB-M48-011 Good performance. — [ ] SB-M48-012 Correct preview.
- [ ] SB-M48-013 Unique ID.

### M49 — Regression Suite `[QA]`

- [ ] SB-M49-001 Difficulty/progression tests. — [ ] SB-M49-002 Level parser tests.
- [ ] SB-M49-003 BoardState tests. — [ ] SB-M49-004 Renderer tests.
- [ ] SB-M49-005 Slot tests. — [ ] SB-M49-006 Color-candidate/reachability tests.
- [ ] SB-M49-007 Reservation tests. — [ ] SB-M49-008 TargetSelector tests.
- [ ] SB-M49-009 Routing tests including exterior corridor. — [ ] SB-M49-010 Dispatcher tests.
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
- [ ] SB-M50-009 Long high-load session.
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

## MAGNIFIC / GENERATED ASSET LIFECYCLE / DEFINITION OF DONE

- [ ] SB-UI-022 Use image generation primarily for branded illustrative assets where it adds value.
- [ ] SB-UI-023 Prefer native Godot controls/styles for interactive/dynamic UI.
- [ ] SB-UI-024 Every generated asset has traceable manifest/provenance.
- [ ] SB-UI-025 Raw generation output is never automatically production-final.
- [ ] SB-UI-026 Owner approval required before production promotion for identity/major art.
- [ ] SB-UI-027 Approved assets must be imported/configured/bound before implementation task closes.
- [ ] SB-UI-028 Never silently regenerate/overwrite approved asset.
- [ ] SB-UI-029 Do not bake dynamic text/quantities/timers/prices/state into generated images.
- [ ] SB-UI-030 Keep single-Image/ImageTexture BoardRenderer; no per-cell UI nodes.
- [ ] SB-UI-031 Validate transparency/edges/resolution/filtering/compression/memory/readability.
- [ ] SB-UI-032 Use generation credits consciously; generate by milestone need.

---

## RISK REGISTER

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RISK-001 | Routing works technically but looks boring/confusing | CRITICAL | Replaceable RoutingSystem + owner review + corridor/route QA |
| RISK-002 | Large number of Scrubbots causes frame drops | HIGH | 59×59 density stress tests and profiling |
| RISK-003 | Legacy difficulty assumptions survive as current truth | HIGH | Difficulty V1 migration + config/doc/regression checks |
| RISK-004 | Production difficulty metadata becomes inconsistent | HIGH | Versioned Difficulty V1 evaluator/calibration |
| RISK-005 | Generic small test fixtures break after production validation | MEDIUM/HIGH | TEST fixture path/context separate from production |
| RISK-006 | Existing artwork gets silently resized/altered | HIGH | Source preservation + explicit compiler/importer + round-trip comparison |
| RISK-007 | AI agent invents missing references | HIGH | Canonical reference library/manifest |
| RISK-008 | External reference game copied too closely | HIGH | Original SCRUBBOTS visual authority; external references conceptual only |
| RISK-009 | Target race assigns same pixel to multiple Scrubbots | HIGH | Reservation strict tests |
| RISK-010 | Renderer creates thousands of Nodes | HIGH | Batched renderer requirement |
| RISK-011 | Desktop testing hides mobile performance issues | HIGH | Real Android profiling |
| RISK-012 | Future agent breaks explicit preload/headless compatibility | MEDIUM/HIGH | ADR-009 + regression tests |
| RISK-013 | Target ordering looks wrong because routing targetability lacks exterior access | HIGH | Owner-locked one-cell four-side exterior routing corridor + exact Hazard Bot (0,19) regression |
| RISK-014 | Hidden debug input diverges from production slot-origin behavior | HIGH | Slot-click-only owner gameplay activation; no SPACE dispatch |

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
ENGINE/CONTENT ENVELOPE
↓
BOARD RENDERER
↓
VISUAL REFERENCE INGESTION
↓
PIXEL ART IMPORT / SEMANTIC ART PIPELINES
↓
GAMEPLAY SESSION
↓
FIVE SLOTS
↓
COLOR CANDIDATES + REACHABILITY
↓
RESERVATION
↓
TARGETSELECTOR
↓
ROUTING + EXTERIOR WALKING CORRIDOR
↓
SCRUBBOT AGENT
↓
DISPATCHER
↓
COMPLETE CLEANING LOOP
↓
REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
PRODUCTION UI / TOUCH                         ACTIVE (M22+)
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

The first real proof of SCRUBBOTS is now achieved by M21:

```text
ONE REAL OWNER-APPROVED SCRUBBOTS LEVEL IMAGE
+ FIVE FUNCTIONAL VISIBLE COLOR SLOTS
+ SLOT-CLICK-ONLY OWNER GAMEPLAY ACTIVATION
+ CORRECT COLOR CANDIDATES + REACHABLE TARGET SELECTION
+ BOTTOM-MOST / LEFT-MOST PRIORITY AMONG CURRENTLY TARGETABLE MATCHING CELLS
+ ONE-LOGICAL-CELL FOUR-SIDE EXTERIOR ROUTING CORRIDOR
+ NO-REACHABLE-TARGET-NO-SPAWN
+ VALID TARGET RESERVATION
+ SCRUBBOTS LEAVING THE CLICKED SLOT
+ SCRUBBOTS MOVING VISIBLY THROUGH VALID ROUTES
+ PIXELS BEING CLEANED TO TRANSPARENCY
+ SCRUBBOTS DISAPPEARING AFTER CLEANING
+ A COMPLETE PLAYABLE LEVEL
```

M22+ now productionizes the UI/touch presentation around that closed gameplay slice.

---

## RECOMMENDED PROMPT SEQUENCE

Guidance, not a hard contract. Split any prompt if scope becomes too large.
Never combine two risky architecture systems merely to save prompt count.

```text
PROMPT 01  Project Foundation                                    [DONE]
PROMPT 02  Godot Installation + Variable LevelData + BoardState
           + Headless Tests                                      [DONE]
PROMPT 03  Official Difficulty Bands + TEST vs Production        [HISTORICAL COMPAT DONE]
PROMPT 04  BoardRenderer + Variable Aspect Board Rendering       [DONE]
PROMPT 05  Visual Reference Library                              [DONE/ONGOING ASSETS]
PROMPT 06  Pixel-Art Importer + Round Trip Validation            [DONE]
PROMPT 07  Gameplay Session Core + Five-Slot Data Model          [DONE]
PROMPT 08  Color Candidates + Reservation + TargetSelector       [DONE]
PROMPT 09  RoutingSystem + Production Routing                    [DONE]
PROMPT 10  ScrubbotAgent + Dispatcher                            [DONE]
PROMPT 11  Complete Clearing Vertical Slice                      [DONE]
PROMPT 12  First Real SCRUBBOTS Artwork Playable Level           [DONE — M21 V10]
PROMPT 13  Production Slot UI + Gameplay Layout + Touch Controls [M22 ACTIVE]
PROMPT 14  Win/Lose Completion Rules + Results Flow
PROMPT 15  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 16  Level Catalog + Difficulty V1 Content Rules
PROMPT 17  Progression + Win Streak + Save System
PROMPT 18  Home + Settings + Tutorial + Navigation
PROMPT 19  Android Device Performance + Full 59×59 Stress Tests
PROMPT 20  Production Content Scale-Up + Regression + Chaos QA
PROMPT 21  Release Candidate Preparation
```

---

## NEXT IMMEDIATE MILESTONE

**Current implementation gate — M22-C001 V01:** execute
`coordination/sessions/M22-C001/CHATGPT_PROMPT_V01.md` against
`coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V01.md`.

M21 is closed and must remain a protected gameplay basis. M22 V01 creates reusable production SlotCell/ColorSelectionPanel components, audits the canonical owner gameplay/five-slot references, corrects stale active manifest palette/difficulty truth, validates touch size/active state/spawn anchors across the required responsive matrix, and proves integration with the accepted M21 slot-click chain. No Magnific generation or credit spend is authorized in V01. Claude/Codex must not edit this `TASKS.md`; ChatGPT audits the implementation and updates tracker/checkbox state afterward.

---

## PARALLEL SIDECAR PROJECTS — SCRUBBOTS LEVEL PLATFORM

These tasks are canonical SCRUBBOTS tasks but belong to sidecar systems isolated from the mobile runtime:

- `SB-LFxx-xxx`: SCRUBBOTS Level Factory / Level Generator.
- `SB-CPxx-xxx`: SCRUBBOTS Content Pipeline.

The repository-root `TASKS.md` remains the only canonical task ledger and is ChatGPT-write-owned.

### Locked sidecar boundaries

- Mobile game never preloads/imports `level_factory/` scripts.
- Factory exports declarative Level Data / production artifacts through documented contracts.
- Existing M09 tooling remains compatibility/evidence; do not rewrite it merely because Factory exists.
- Content Pipeline distributes declarative content only, never executable gameplay code.
- Runtime remote content installs under `user://`, never writes into `res://`.
- Staging precedes production; publication is versioned, integrity-checked, reversible and auditable.
- Existing M30/M47/M48 remain main-game catalog/scale-up/QA milestones.
- Campaign/difficulty work obeys Difficulty V1 owner decisions, not historical class=dimension/color rules.

### GitHub-native ChatGPT ↔ Claude coordination for sidecars [LOCKED]

1. ChatGPT writes versioned `CHATGPT_PROMPT_VNN.md` and `CHATGPT_AUDIT_CRITERIA_VNN.md`.
2. **Before handoff, ChatGPT updates root `TASKS.md` to the audited/current next actor/action.**
3. Claude safely syncs, reads `TASKS.md` without editing it, implements only the active prompt, runs validation, writes/pushes the matching `CLAUDE_LOG_VNN.md`, and returns `AWAITING_AUDIT`.
4. Claude never creates an audit verdict/file and never mutates root `TASKS.md`.
5. ChatGPT reads the log + actual commits/diff/source/tests, independently audits them, writes `CHATGPT_AUDIT_VNN.md`, and **updates root `TASKS.md` itself** with audit result/closures/progress/next frontier.
6. If correction is required, ChatGPT issues the next prompt version only after the full-surface audit/frozen finding set and tracker update.

### LF00 — Level Factory Project Bootstrap & Isolation [SIDECAR PROJECT]

- [ ] SB-LF00-001 Establish `level_factory/` as independently openable Godot project.
- [ ] SB-LF00-002 Maintain Factory-specific README/governance/docs/scenes/scripts/tests/output boundaries.
- [ ] SB-LF00-003 Enforce one-way integration: Factory exports data; main game never preloads Factory scripts.
- [ ] SB-LF00-004 Keep Factory logic headless-testable/data-oriented.
- [ ] SB-LF00-005 Define Factory verification commands separately.
- [ ] SB-LF00-006 Define generated/candidate/cache/secret folders and exclusions.
- [ ] SB-LF00-007 Establish Factory coordination structure while root TASKS remains sole ledger.
- [ ] SB-LF00-008 Prove clean checkout boots nested Factory headlessly.

### LF01 — Deterministic Generation Configuration & Seeds

- [ ] SB-LF01-001 Define deterministic LevelGenerationConfig.
- [ ] SB-LF01-002 Store/replay seed for every candidate.
- [ ] SB-LF01-003 Same config + seed produces byte-identical candidate data.
- [ ] SB-LF01-004 Distinct seeds can produce distinct legal candidates.
- [ ] SB-LF01-005 Support width/height selection within current engine/content envelope and workload guidance.
- [ ] SB-LF01-006 Support rectangular boards.
- [ ] SB-LF01-007 Exercise 59×59 where cost scales.
- [ ] SB-LF01-008 Record seed/config/generator-version provenance.
- [ ] SB-LF01-009 Separate TEST/development candidates from production.
- [ ] SB-LF01-010 Reject obsolete semantic assumptions.

### LF02 — Semantic/Constraint Candidate Generator

- [ ] SB-LF02-001 Implement evaluator-guided candidate architecture rather than blind random filling.
- [ ] SB-LF02-002 Support reverse construction when canonical mechanics permit.
- [ ] SB-LF02-003 Support PUZZLE_FIRST mode.
- [ ] SB-LF02-004 Support ART_FIRST mode consuming owner/AI-approved pixel art/masks.
- [ ] SB-LF02-005 Implement reusable shape/topology primitives without declaring them difficulty rules.
- [ ] SB-LF02-006 Implement connected color-region representation/generation.
- [ ] SB-LF02-007 Preserve one logical artwork square = one logical board cell.
- [ ] SB-LF02-008 Never fabricate missing owner artwork or label AI output owner-original.
- [ ] SB-LF02-009 Keep unresolved dependency semantics behind design-gated adapters.
- [ ] SB-LF02-010 Keep unresolved slot/stack quantity/order generation design-gated.
- [ ] SB-LF02-011 Record candidate provenance.
- [ ] SB-LF02-012 Add deterministic unit/property tests.

### LF03 — Puzzle Simulation, Solver & State Search

- [ ] SB-LF03-001 Create pure/headless puzzle simulation boundary.
- [ ] SB-LF03-002 Define compact solver state.
- [ ] SB-LF03-003 Define legal-move-provider interface.
- [ ] SB-LF03-004 Implement deterministic baseline search when semantics available.
- [ ] SB-LF03-005 Add visited-state memoization/hashing.
- [ ] SB-LF03-006 Record solution path/states/dead ends/depth/branching/solve time.
- [ ] SB-LF03-007 Add correctness-preserving pruning/order only with tests.
- [ ] SB-LF03-008 Add bounded solution-count/entropy analysis.
- [ ] SB-LF03-009 Reuse canonical reachability/routing semantics rather than importing another game's rules.
- [ ] SB-LF03-010 Reproduce solver bugs by candidate/seed/config/version.
- [ ] SB-LF03-011 Define budgets/timeouts and UNSOLVED vs INCONCLUSIVE.
- [ ] SB-LF03-012 Add regression fixtures.

### LF04 — Difficulty Intelligence & Metrics

- [ ] SB-LF04-001 Define versioned LevelMetrics.
- [ ] SB-LF04-002 Record solution depth/move count where meaningful.
- [ ] SB-LF04-003 Record states/dead ends/branching/forced moves.
- [ ] SB-LF04-004 Add dependency depth only when canonical.
- [ ] SB-LF04-005 Add slot pressure only when canonical.
- [ ] SB-LF04-006 Add bait/deadlock metrics only when canonical.
- [ ] SB-LF04-007 Add color/remaining-state volatility where useful.
- [ ] SB-LF04-008 Implement/version Difficulty V1 Challenge Score components/coefficients.
- [ ] SB-LF04-009 Map predicted score to current lane/class rhythm without equating class to board size.
- [ ] SB-LF04-010 Keep metric provenance/versioning.
- [ ] SB-LF04-011 Design future calibration against player data under approved analytics policy.
- [ ] SB-LF04-012 Tests prove analysis does not mutate gameplay/art source.

### LF05 — Factory Validation & Level QA

- [ ] SB-LF05-001 Compose structural LevelData validation with current production compatibility + Difficulty V1 evaluation.
- [ ] SB-LF05-002 Reuse audited M09 round-trip contract for art-first exports.
- [ ] SB-LF05-003 Validate dimensions/envelope/C01..C16/3..12 used colors/cells/opacity/transparency/provenance/duplicate IDs.
- [ ] SB-LF05-004 Reject proven-unsolvable candidates when solver authoritative.
- [ ] SB-LF05-005 Distinguish INCONCLUSIVE from UNSOLVABLE.
- [ ] SB-LF05-006 Actionable rejection reasons.
- [ ] SB-LF05-007 Machine-readable QA report.
- [ ] SB-LF05-008 Preserve owner source images byte-for-byte.
- [ ] SB-LF05-009 Visual recognizability/readability gates, not structural-only false positives.
- [ ] SB-LF05-010 Feed accepted artifacts into M30/M47/M48 rather than bypassing them.

### LF06 — Human-in-the-Loop Godot Factory Editor

- [ ] SB-LF06-001 Build @tool/editor-facing workspace.
- [ ] SB-LF06-002 Target difficulty/dimensions/seed/mode/candidate controls.
- [ ] SB-LF06-003 Generate/Solve/Validate/Analyze/Reproduce actions.
- [ ] SB-LF06-004 Crisp board/art preview.
- [ ] SB-LF06-005 Display solution/difficulty/load/risk/art QA metrics/provenance.
- [ ] SB-LF06-006 Owner/designer paint/edit where appropriate.
- [ ] SB-LF06-007 Approved puzzle-config edits only.
- [ ] SB-LF06-008 Revalidate after manual changes.
- [ ] SB-LF06-009 Never auto-promote generated candidate.
- [ ] SB-LF06-010 Keep editor presentation separate from truth.
- [ ] SB-LF06-011 Reproduce candidate by seed/config.
- [ ] SB-LF06-012 Editor smoke + headless core tests.

### LF07 — Mutation & Automatic Difficulty Targeting [V2]

- [ ] SB-LF07-001 Mutation interface/immutable lineage.
- [ ] SB-LF07-002 Safe hardening mutations only for canonical mechanics.
- [ ] SB-LF07-003 Safe easing mutations only for canonical mechanics.
- [ ] SB-LF07-004 Re-solve/revalidate after every mutation.
- [ ] SB-LF07-005 Preserve seed/parent/mutation provenance.
- [ ] SB-LF07-006 Target Challenge Score range while respecting load/risk/retention constraints.
- [ ] SB-LF07-007 Bound mutation attempts.
- [ ] SB-LF07-008 Compare mutate vs regenerate efficiency.
- [ ] SB-LF07-009 Never mutate owner source art silently.
- [ ] SB-LF07-010 Deterministic mutation regression tests.

### LF08 — Batch Factory & Weekly Production

- [ ] SB-LF08-001 Generate requested accepted counts by lane/class cadence.
- [ ] SB-LF08-002 Separate generated from accepted count.
- [ ] SB-LF08-003 Rejection statistics.
- [ ] SB-LF08-004 Deterministic/resumable batch jobs.
- [ ] SB-LF08-005 Prevent duplicate IDs/seeds/artifacts.
- [ ] SB-LF08-006 Accepted LevelData/previews/metadata/QA reports as batch result.
- [ ] SB-LF08-007 Owner review/approval queue before publication.
- [ ] SB-LF08-008 Production-ready handoff to Content Pipeline.
- [ ] SB-LF08-009 Stress high rejection rates safely.
- [ ] SB-LF08-010 Reruns create no meaningless diffs.

### LF09 — Advanced Generation Research [V3 / EXPERIMENTAL]

- [ ] SB-LF09-001 Prototype evolutionary selection behind experimental flag.
- [ ] SB-LF09-002 Versioned fitness metrics.
- [ ] SB-LF09-003 Prototype procedural/semantic art helpers without replacing owner-approved art direction.
- [ ] SB-LF09-004 Telemetry-calibrated difficulty only after approved analytics/data policy.
- [ ] SB-LF09-005 Keep live/runtime level generation disabled unless explicitly approved.
- [ ] SB-LF09-006 Preserve reproducibility/lineage.
- [ ] SB-LF09-007 Compare advanced generation quality/compute cost.
- [ ] SB-LF09-008 No production promotion without separate audit decision.

### LF10 — Campaign/Sequencing Adapter

- [ ] SB-LF10-001 Define CampaignBuilder interface.
- [ ] SB-LF10-002 Consume owner-locked Difficulty V1 rhythm/progression/retention rules.
- [ ] SB-LF10-003 Select accepted production levels without modifying their data.
- [ ] SB-LF10-004 Prevent duplicate/unavailable/disabled selection.
- [ ] SB-LF10-005 Preserve deterministic campaign-build provenance.
- [ ] SB-LF10-006 Rebuild campaign ordering without regenerating levels.
- [ ] SB-LF10-007 Future events/featured selection as data, not code.
- [ ] SB-LF10-008 Campaign validation against challenge/load/frustration/similarity constraints.

### CP00 — Content Pipeline Architecture & Security [SIDECAR PROJECT]

- [ ] SB-CP00-001 Establish `content_pipeline/` separate publisher/control-plane project.
- [ ] SB-CP00-002 Define app code vs remote content boundary.
- [ ] SB-CP00-003 Remote content declarative only; forbid executable payloads.
- [ ] SB-CP00-004 Separate staging/production.
- [ ] SB-CP00-005 Versioned/auditable publish/promotion/rollback state.
- [ ] SB-CP00-006 Secret handling; no credentials in Git.
- [ ] SB-CP00-007 Publisher dry-run/validation-only before remote mutation.
- [ ] SB-CP00-008 Provider abstraction.
- [ ] SB-CP00-009 Content Pipeline GitHub coordination under ChatGPT-owned root tracker.
- [ ] SB-CP00-010 Re-verify mobile/store-policy boundary before release.

### CP01 — .scrubpack Format & Packager

- [ ] SB-CP01-001 Define versioned .scrubpack spec.
- [ ] SB-CP01-002 Package declarative levels only.
- [ ] SB-CP01-003 Record pack ID/version/time/levels.
- [ ] SB-CP01-004 Per-pack SHA-256.
- [ ] SB-CP01-005 Deterministic pack serialization/order.
- [ ] SB-CP01-006 Prevent duplicate level IDs.
- [ ] SB-CP01-007 Validate every level before pack.
- [ ] SB-CP01-008 Unpack/inspect tooling.
- [ ] SB-CP01-009 Deterministic bytes where container permits.
- [ ] SB-CP01-010 Reject unsupported versions safely.

### CP02 — Remote Manifest & Content Versioning

- [ ] SB-CP02-001 Define versioned manifest schema.
- [ ] SB-CP02-002 schema_version + monotonic content_version.
- [ ] SB-CP02-003 minimum_game_version compatibility.
- [ ] SB-CP02-004 Pack IDs/locations/hashes.
- [ ] SB-CP02-005 Level metadata without unnecessary contiguous-ID assumption.
- [ ] SB-CP02-006 disabled_levels.
- [ ] SB-CP02-007 Scheduled activation windows.
- [ ] SB-CP02-008 Reject duplicate pack/level ownership conflicts.
- [ ] SB-CP02-009 Validate references before publish.
- [ ] SB-CP02-010 Keep prior manifests/version history.
- [ ] SB-CP02-011 App/content schema compatibility behavior.
- [ ] SB-CP02-012 Parser/schema tests.

### CP03 — Publisher, Staging & Production Promotion

- [ ] SB-CP03-001 Publisher validation-only mode.
- [ ] SB-CP03-002 Serialize accepted Factory output into packs.
- [ ] SB-CP03-003 Hashes + candidate manifest.
- [ ] SB-CP03-004 Upload packs before active manifest references them.
- [ ] SB-CP03-005 Verify remote object integrity.
- [ ] SB-CP03-006 Publish STAGING first.
- [ ] SB-CP03-007 Verify staging through real download.
- [ ] SB-CP03-008 Explicit staging→production promotion.
- [ ] SB-CP03-009 New versioned production manifest.
- [ ] SB-CP03-010 No silent live overwrite.
- [ ] SB-CP03-011 One-command publish only after stages individually testable.
- [ ] SB-CP03-012 Publish report.

### CP04 — Godot Remote Content Runtime

- [ ] SB-CP04-001 Implement RemoteContentManager only when runtime integration milestone opens.
- [ ] SB-CP04-002 Fetch production manifest over HTTPS.
- [ ] SB-CP04-003 Compare remote/local content versions.
- [ ] SB-CP04-004 Determine missing packs without redundant downloads.
- [ ] SB-CP04-005 Download to `user://content/`, never `res://`.
- [ ] SB-CP04-006 Verify SHA-256.
- [ ] SB-CP04-007 Validate pack/schema/level before activation.
- [ ] SB-CP04-008 Activate verified content preserving last-known-good.
- [ ] SB-CP04-009 Expose remote levels to catalog/loader through narrow data interface.
- [ ] SB-CP04-010 Keep generator/publisher code out of runtime.
- [ ] SB-CP04-011 Add INTERNET permission only when runtime enabled.
- [ ] SB-CP04-012 Handle network/server/parse/hash failures without blocking offline play.
- [ ] SB-CP04-013 App/content version compatibility tests.
- [ ] SB-CP04-014 Reject executable remote artifacts.

### CP05 — Offline Cache & Last-Known-Good Recovery

- [ ] SB-CP05-001 Define local content registry under `user://`.
- [ ] SB-CP05-002 Preserve last-known-good manifest/packs.
- [ ] SB-CP05-003 Boot/play cached content offline.
- [ ] SB-CP05-004 Safe fallback on manifest fetch failure.
- [ ] SB-CP05-005 Reject corrupt/incomplete downloads without replacing good cache.
- [ ] SB-CP05-006 Interrupted-download recovery/cleanup.
- [ ] SB-CP05-007 Cache size/retention policy.
- [ ] SB-CP05-008 Builtin app levels playable independently.
- [ ] SB-CP05-009 First launch no-network test.
- [ ] SB-CP05-010 Upgrade with partial/corrupt cache.
- [ ] SB-CP05-011 Downgrade/compatibility behavior.
- [ ] SB-CP05-012 Never delete only known-good set before replacement validates.

### CP06 — Rollback, Disable & Scheduling

- [ ] SB-CP06-001 Rollback as new auditable content version.
- [ ] SB-CP06-002 Roll back to known-good manifest/pack set.
- [ ] SB-CP06-003 Disable individual level IDs.
- [ ] SB-CP06-004 Disabled levels skipped safely.
- [ ] SB-CP06-005 Scheduled future activation.
- [ ] SB-CP06-006 Timezone/time-source behavior.
- [ ] SB-CP06-007 No schedule activates incompatible/unverified content.
- [ ] SB-CP06-008 Cancel/edit future schedules with audit history.
- [ ] SB-CP06-009 Rollback after bad live release test.
- [ ] SB-CP06-010 Single-level disable test.
- [ ] SB-CP06-011 Multiple weekly packs prepared together.
- [ ] SB-CP06-012 Reproducible publish/rollback reports.

### CP07 — Storage/CDN Provider Integration

- [ ] SB-CP07-001 Evaluate provider candidates.
- [ ] SB-CP07-002 Select provider with owner approval.
- [ ] SB-CP07-003 Provider adapter; no credentials in project data.
- [ ] SB-CP07-004 Separate staging/production storage.
- [ ] SB-CP07-005 Immutable/versioned object naming where practical.
- [ ] SB-CP07-006 Upload/download/hash round trip.
- [ ] SB-CP07-007 Cache-control/CDN strategy.
- [ ] SB-CP07-008 Backup/export/migration path.
- [ ] SB-CP07-009 Least-privilege publishing credentials.
- [ ] SB-CP07-010 Keep provider-specific code outside gameplay/content schemas.

### CP08 — Content Operations, QA & Observability

- [ ] SB-CP08-001 Weekly batch summary.
- [ ] SB-CP08-002 Record staging/production versions.
- [ ] SB-CP08-003 Record hashes/remote verification.
- [ ] SB-CP08-004 Record disabled/scheduled/rollback changes.
- [ ] SB-CP08-005 Content-health check.
- [ ] SB-CP08-006 Safe operational errors/alerts without unnecessary player data.
- [ ] SB-CP08-007 Content incident runbook.
- [ ] SB-CP08-008 Clean-machine publish dry run.
- [ ] SB-CP08-009 Disaster recovery from backups.
- [ ] SB-CP08-010 Logs free of secrets.

### CP09 — Store Policy, Security & Release Gate

- [ ] SB-CP09-001 Re-verify current Google Play remote-content/code policy before launch.
- [ ] SB-CP09-002 Re-verify Apple requirements before iOS remote-content launch.
- [ ] SB-CP09-003 Prove remote payloads declarative only.
- [ ] SB-CP09-004 Prevent content data from embedding/evaluating executable expressions/scripts.
- [ ] SB-CP09-005 HTTPS-only endpoints.
- [ ] SB-CP09-006 Threat-model tampering/rollback attacks.
- [ ] SB-CP09-007 Define authenticity upgrade if hash-only insufficient.
- [ ] SB-CP09-008 No publishing secret ships in app.
- [ ] SB-CP09-009 Privacy impact if telemetry enabled.
- [ ] SB-CP09-010 Independent audit before production remote-content delivery.