# 05 — Technical Decisions (Architecture Decision Record)

Each entry: Decision, Reason, Consequences, Status.

---

### ADR-001: Engine and language

**Decision**: Godot Engine 4.7, GDScript by default.

**Reason**: Free/open-source, strong 2D toolset, mobile export support,
GDScript is fast to iterate in for a solo-developer-plus-AI-agent workflow.
Matches explicit project requirement.

**Consequences**: No Unity/Unreal tooling or asset store ecosystem. C# only
introduced later if a concrete, strong need appears — none currently exists.

**Status**: Accepted.

---

### ADR-002: Mobile-first, portrait-first

**Decision**: Design resolution baseline **1080×2160 portrait**, using Godot's
`canvas_items` stretch mode with `expand` aspect. UI is safe-area aware and
container/anchor driven.

**Reason**: SCRUBBOTS is a mobile puzzle game; portrait is the expected
default orientation. The owner requires the gameplay board to occupy a very
large share of modern tall iPhone/Android screens, so the earlier provisional
1080×1920 + `keep` value is superseded.

**Consequences**: UI and board layout are designed/tested primarily in
portrait without hard-coding gameplay math against display resolution.
Required responsive validation includes 1080×2160, 1170×2532, 1290×2796,
1080×2400 and 1440×3200, with shorter phone/tablet portrait coverage before
release. Decorative regions yield space before essential gameplay controls.

**Status**: Accepted; supersedes the previous provisional 1080×1920/keep
value.

---

### ADR-003: 40×40 logical board, decoupled from screen resolution

**Decision**: The puzzle grid is a fixed logical 40×40 (1,600 cell) data
structure, entirely independent of the physical display resolution or zoom
level.

**Reason**: Explicit project requirement. Keeps gameplay logic
resolution-independent and lets the same level render at any device size.

**Consequences**: All gameplay code addresses cells by logical index/x/y,
never by screen pixel. Rendering/UI code is responsible for the logical-to-
screen mapping, not gameplay code.

**Status**: Superseded by ADR-008. "Fixed logical 40×40" was a documentation
error, not an owner requirement — see ADR-008. The resolution-independence
principle (cells addressed logically, never by screen pixel) still holds.

---

### ADR-004: Data-oriented cell storage, not one Node per cell

**Decision**: Board State for all 1,600 cells is represented with flat/
packed data structures (arrays of small structs/ints), not 1,600 individual
scene-tree Nodes.

**Reason**: Explicit performance requirement — mobile target, 60 FPS goal.
1,600 Node instances (each with the overhead of a Node/Control/Sprite2D) is
wasteful for what is fundamentally a big grid of small state values.

**Consequences**: Rendering must be done via batched/custom drawing or a
generated texture reflecting board state, rather than per-cell scene nodes.
This shifts some complexity into the Board Renderer module in exchange for
mobile performance headroom.

**Status**: Accepted. Amended by ADR-008 — "1,600" here was written when the
board was incorrectly assumed fixed-size; the data-oriented storage decision
itself still holds for any board size (e.g. 2,500 cells at 50×50).

---

### ADR-005: Separate TargetSelector from RoutingSystem

**Decision**: "Which cell should this Scrubbot clean" (TargetSelector) and
"how does it visually get there" (RoutingSystem) are implemented as
independent modules with a narrow interface between them.

**Reason**: Explicit architectural priority from the project owner — robot
routing/movement is expected to be iterated on heavily and possibly replaced
entirely later. Coupling target selection to one routing implementation
would force a rewrite of unrelated systems (level data, slots, scoring)
whenever routing changes.

**Consequences**: Slightly more indirection up front (two modules and an
interface instead of one script) in exchange for routing being replaceable
in isolation later.

**Status**: Accepted.

---

### ADR-006: No third-party frameworks/plugins by default

**Decision**: Rely on Godot's built-in functionality; do not add third-party
plugins, paid assets, or external frameworks unless a genuinely strong,
specific need appears and the owner approves.

**Reason**: Explicit project requirement — free/open-source, minimal
dependency surface, easier for AI agents to reason about and maintain.

**Consequences**: Some conveniences (e.g. a dedicated tweening/pathing addon)
are deferred until proven necessary; Godot's built-in `Tween`, `AStar2D`,
etc. are the default first choice when such needs arise.

**Status**: Accepted.

---

### ADR-007: Git remote connection strategy

**Decision**: Cloned the existing (non-empty) `Sekiph82/Scrubbots` GitHub
repository directly into the local project directory, rather than running
`git init` and manually re-adding a remote.

**Reason**: Inspection (Prompt 01, step 10) found the local directory empty
but the GitHub repository already contained one commit (a placeholder
`README.md`). Cloning was the safe, non-destructive way to get local and
remote history aligned without risking an orphaned history or accidental
overwrite.

**Consequences**: Local `main` tracks `origin/main` from the start; the
placeholder README is preserved in history and then updated (not deleted-
and-recreated) in the bootstrap commit.

**Status**: Accepted.

---

### ADR-008: Variable-size logical board (correction of Prompt 01 error)

**Decision**: Board dimensions are defined by level data (`width`, `height`
fields), not by an engine constant. The engine supports at least 40×40 and
50×50 layouts natively, does not hard-code cell counts, and does not assume
`width == height`. Cell count is always derived as `width * height`.

**Reason**: Prompt 01's documentation incorrectly locked the board to a
fixed 40×40 / 1,600-cell size (see the correction notes in
`docs/00_PROJECT_BRIEF.md` and `docs/01_GAMEPLAY_SPEC.md`). This was a
documentation mistake, not an owner-directed rule change: the actual
requirement is a variable-size board engine, and Very Hard content requires
50×50 (2,500 cells) to work natively. A fixed-40×40 architecture would
unnecessarily restrict future content and would have required a disruptive
rewrite later.

**Consequences**: All indexing, validation, rendering, targeting, routing,
and tests must read width/height from board/level data rather than assuming
a constant. `LevelData` and `BoardState` (introduced in Prompt 02) both
carry explicit `width`/`height`; cell count is a computed property, never a
separately-trusted stored field. `docs/01_GAMEPLAY_SPEC.md`,
`docs/00_PROJECT_BRIEF.md`, `docs/02_TECH_ARCHITECTURE.md`,
`docs/03_LEVEL_DATA_SPEC.md`, `docs/04_ROADMAP.md`, and `CLAUDE.md` were all
corrected in Prompt 02 to reflect this. ADR-003's "fixed logical 40×40" is
superseded by this decision. ADR-004's data-oriented storage decision is
unaffected in principle — it now explicitly applies across board sizes
rather than being described in terms of a fixed 1,600.

**Status**: Accepted.

---

### ADR-009: Explicit preload() over bare class_name for cross-script refs

**Decision**: Gameplay/data scripts (`scripts/data/`,
`scripts/gameplay/board/`, and their tests) reference each other via
`const Foo = preload("res://path/to/foo.gd")` and do not rely on bare
`class_name` lookups or declare `class_name` themselves.

**Reason**: Discovered empirically in Prompt 02 — this machine's Godot
install has never had its project opened in the editor, so no global script
class cache exists. Headless `godot --headless -s res://tests/run_tests.gd`
runs fail to parse scripts that reference other classes by bare
`class_name` (e.g. `LevelData`, `BoardState`) with errors like
`Could not find type "LevelData" in the current scope`. Explicit `preload()`
resolves the dependency directly from the file path and parses correctly
regardless of whether the global class cache exists.

**Consequences**: Slightly more boilerplate (one `const` line per
dependency) in exchange for scripts and tests that reliably run headless
from a clean checkout/CI machine with no prior editor session. New scripts
in these areas should follow the same pattern. This does not preclude using
`class_name` later once the project has a normal editor-authored workflow
(e.g. for scenes wanting autocomplete) — it is a headless-robustness
convention, not a permanent ban.

**Status**: Accepted.

---

### ADR-010: Official difficulty→board-dimension bands, structural vs. production validation

**Decision**: Production board dimensions are defined by difficulty bands:

```text
Easy       20..29 × 20..29
Medium     30..39 × 30..39
Hard       40..49 × 40..49
Very Hard  50..59 × 50..59
```

Width and height are checked independently against the same band, so
rectangular boards are valid (e.g. Hard `48×41`) as long as both dimensions
fall in range — `width == height` is never required. Test/development
fixtures (identified by `difficulty == "TEST"`, e.g. the 3×2 generic-size
fixture) may exist outside every production band and must never be treated
as production content. Current maximum production requirement is
**59×59 = 3,481 cells**. This is implemented as a separate
`ProductionLevelValidator` (`scripts/data/production_level_validator.gd`)
consuming a single source of truth for the band table,
`DifficultyRules` (`scripts/data/difficulty_rules.gd`) — the existing
generic `LevelValidator`/`LevelData`/`BoardState` core is **not** modified
and remains fully dimension-agnostic.

**Reason**: The game uses increasing logical artwork dimensions as part of
its difficulty/content structure, while the underlying board engine must
stay generic (ADR-008) — conflating "is this level data structurally valid"
with "is this a legal production level" would either force the generic
engine to reject legitimate test/engine-proof fixtures like the 3×2 board,
or force production content rules to leak into code that has no business
knowing about difficulty at all (e.g. a future `BoardRenderer` or
`RoutingSystem`). Prompt 02's own correction (ADR-008) had already fixed
the fixed-40×40 assumption but under-specified the actual requirement as
"40×40 standard / 50×50 required for Very Hard" — this ADR records the full
band table the project owner actually specified.

**Consequences**: Production validation (level catalogs, content import
tooling, future authoring tools) must call `ProductionLevelValidator`.
Generic `BoardState`/`LevelValidator`/tests must **not** enforce these
bands — doing so would break the 3×2 engine-proof fixture and reintroduce a
disguised fixed-size assumption. Test fixtures under `data/levels/` use
`"difficulty": "TEST"` explicitly (an existing mislabeling in
`test_50x50.json`, which had claimed `"VERY_HARD"`, was corrected to `TEST`
as part of this decision — see the Prompt 03 phase log). 59×59 becomes the
current maximum benchmark workload for performance sanity checks going
forward (`docs/06_TEST_STRATEGY.md`).

**Status**: Accepted.

---

### ADR-011: BoardRenderer uses one Image/ImageTexture, not per-cell Nodes or per-frame draw calls

**Decision**: `BoardRenderer` (`scripts/gameplay/board/board_renderer.gd`)
extends `TextureRect` and draws the entire board as a single `Image` (one
pixel per logical cell) converted to one `ImageTexture`, displayed with
`texture_filter = TEXTURE_FILTER_NEAREST`. Node count is exactly **one**
regardless of board size (verified at every official band boundary and at
the 59×59/3,481-cell maximum). Updates are `Image.set_pixel()` +
`ImageTexture.update()` — no custom immediate-mode drawing, no per-cell
scene objects.

**Reason**: Three approaches were evaluated (full detail and expected-cost
reasoning in `SCRUBBOTS_PHASE_M06_LOG.md`, Architecture Decisions):
(1) one Node per cell — explicitly forbidden, this is exactly what ADR-004/
ADR-008 already ruled out; (2) a single Node's custom `_draw()` re-issuing
one `draw_rect()` per cell every redraw — single node, but reissues up to
3,481 immediate-mode draw commands on every visual change; (3) one `Image`/
`ImageTexture` per board, GPU-upscaled with nearest-neighbor filtering.
Option 3 was chosen: it satisfies the constant-node-count requirement, the
pixel-art crispness requirement (nearest-neighbor sampling gives sharp
block edges with zero extra code), and composes directly with the
project's existing `Control`-based UI (`scenes/app/main.tscn`).

**Consequences**: A full redraw costs one `Image.set_pixel()` per cell
(O(cells), max 3,481) plus one texture upload; a partial update
(`update_cells()`) still triggers one full texture upload regardless of how
few cells changed, since Godot 4's `Texture2D` has no partial/sub-rect
update API — acceptable at this resolution (measured: ~0.007ms per
`update_cells()` call regardless of board size, dominated by the fixed
upload cost, not cell count — see phase log Performance Measurements). This
strategy would need revisiting if the logical grid ever grew far beyond the
current 59×59 maximum. `BoardRenderer` remains presentation-only: it reads
`BoardState`/palette data and never mutates gameplay state (see
docs/02_TECH_ARCHITECTURE.md).

**Status**: Accepted.


---

### ADR-012: Level Factory is a separate nested Godot project

**Decision**: The SCRUBBOTS Level Factory lives at `level_factory/` with
its own `project.godot`, docs, tests and coordination subtree. It is not a
module loaded by the mobile game's root Godot project.

**Reason**: Generation, solver search, difficulty analysis, bulk candidate
production and human authoring are development workloads with very different
dependencies/performance/security concerns from the shipping mobile game.

**Consequences**: Integration is one-way through declarative data contracts.
The game never preloads Factory scripts. Existing M09 importer/validation
remains the audited compatibility gate for art-first Level Data output.

**Status**: Accepted.

---

### ADR-013: Level Factory is constraint-based and reproducible

**Decision**: Production candidate generation is seed/config reproducible and
constraint-driven. Blind random filling is not considered sufficient
production generation. Solver/difficulty adapters may only use gameplay
semantics that have been explicitly defined by the project.

**Reason**: Reproducible candidates are debuggable; constraint/solver-backed
generation can reject invalid or unsolved candidates instead of producing an
opaque stream of random boards.

**Consequences**: Candidate provenance includes seed/config/generator version.
Historical Colony Flow-derived assumptions remain experimental until mapped
to canonical SCRUBBOTS rules.

**Status**: Accepted, with solver semantics gated by future gameplay rules.

---

### ADR-014: Remote content is declarative data, never executable game code

**Decision**: The Content Pipeline may distribute Level Data, pack/manifest
metadata, previews and other explicitly supported declarative content. It
must not distribute or activate GDScript, native libraries, bytecode,
plugins, evaluable expressions or other executable gameplay code.

**Reason**: Keeps app-code changes in store-delivered builds, reduces remote
attack surface, and preserves a clear review/security boundary.

**Consequences**: Remote payload schemas are allow-listed and validated.
Runtime downloads install under `user://`; publishing secrets never ship
inside the app. Current store policies must be re-verified before launch.

**Status**: Accepted.

---

### ADR-015: Staging-first, versioned Content Pipeline

**Decision**: Remote level publication follows validate → package/hash →
upload → staging manifest → real remote verification → explicit production
promotion. Rollback/disable/scheduling create auditable versioned state
changes instead of silently rewriting history.

**Reason**: Weekly high-volume level publishing needs a safe operational
control plane with last-known-good recovery and reproducible evidence.

**Consequences**: `.scrubpack` and manifest formats are versioned; hashes
are verified before activation; production promotion is explicit; provider
choice remains behind an adapter until selected.

**Status**: Accepted.

---

### ADR-016: Production UI is native responsive Godot composition

**Decision**: Full-screen AI/mockup images are art-direction references only.
Production screens are assembled from reusable Godot `Control` scenes,
containers, Themes/StyleBoxes and selectively generated decorative textures.

**Reason**: SCRUBBOTS must fit varied iPhone/Android portrait ratios, safe
areas, localization and dynamic counters without image regeneration.

**Consequences**: Text, quantities, progress, slots, color tiles, popup bodies
and interactive states stay live. `docs/MASTER_UI_SYSTEM.md` is the detailed
component/layout contract. The existing `BoardRenderer` remains intact.

**Status**: Owner-approved.

---

### ADR-017: Magnific-only Master UI image generation pipeline

**Decision**: Magnific MCP is the sole approved AI image-generation provider
for the Master UI Asset Kit unless the owner explicitly changes this rule.
Higgsfield is not a project dependency. Owner-supplied references outrank
Magnific output.

**Reason**: The owner already has usable Magnific credits and wants to avoid
an additional paid image service. Magnific covers required generation,
reference, background-removal, resize/upscale and related workflows.

**Consequences**: `ASSET_GENERATION_MANIFEST.json` is the machine-readable
queue. Magnific is used mainly for Scrubby/robot character art, booster icons,
rewards, difficulty emblems and decorative assets. Native Godot UI is
preferred for scalable structural elements. Raw generated assets are kept
separate from explicitly approved production finals.

**Status**: Owner-approved.

---

### ADR-018: Owner Desktop visual-reference intake is copy-only

**Decision**: `C:\Users\sekip\Desktop\ScrubBots Gorselleri` is an owner-
confirmed SCRUBBOTS reference source. Intake copies files into
`assets/art/references/_owner_inbox/` and never moves/deletes Desktop source
files.

**Reason**: Prior approved/concept work must be visible to future Claude Code
sessions while preserving source originals.

**Consequences**: Inbox files are references until inventoried, classified
and promoted. Magnific may not overwrite owner-source references.

**Status**: Owner-approved.
