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


---

### ADR-019: ACTIVE/CLEARED board lifecycle replaces the DIRTY/CLEAN grime/reveal model

**Decision** (owner, 2026-09-05, cycle META-C004): the gameplay-semantic
DIRTY/CLEAN visual model is replaced entirely by an ACTIVE/CLEARED cell
lifecycle:

- Every logical artwork pixel starts **ACTIVE**: present, shown at its
  **original source palette color, opaque**, a color-matching candidate, and
  it occupies/blocks board space for access/path semantics.
- A successfully cleaned cell becomes **CLEARED**: rendered at **alpha 0**
  (fully transparent) so the gameplay background shows through, no longer a
  color candidate, and it becomes open/free space for access/path semantics.
- `BoardState.CellState` is `ACTIVE = 0`, `CLEARED = 1` (numeric order
  preserved so existing packed-byte storage stays valid).
- `BoardRenderer` draws ACTIVE = exact source color/opaque, CLEARED =
  `Color(0,0,0,0)`. No black/gray/palette substitute for CLEARED.

There is **no** DIRTY state, no CLEAN-colored transform state, no grime
transform, no A/B/C dirty preset, and no hidden second artwork layer being
revealed. The visible pixel artwork itself is progressively cleared away.

**Candidate ≠ reachable target (AL-028):** a matching-color ACTIVE cell is
only a *raw color candidate*. It is not a valid final target unless it is
also currently reachable under board-access semantics: non-target ACTIVE
cells block access, CLEARED/background space is open, and a fully enclosed
matching-color ACTIVE cell is not targetable until prior clears open access.
The M13 `ColorCandidateIndex` (`scripts/gameplay/targeting/`) proves color
membership only; reachability filtering, `TargetSelector` (M15) and
`RoutingSystem` (M16+) remain separate systems (see ADR-005). `TargetSelector`
never generates routes; `RoutingSystem` never silently retargets.

**Reason**: the owner replaced the prototype visual model with a concrete,
testable transparency rule that also defines board-access semantics for
future routing. Directly observable renderer alpha is a stronger test target
than a subjective dirty-preset comparison.

**Consequences**: `scripts/gameplay/board/dirty_clean_presets.gd` is removed;
the M13 index moved from `scripts/gameplay/routing/eligible_target_index.gd`
(`EligibleTargetIndex`) to `scripts/gameplay/targeting/color_candidate_index.gd`
(`ColorCandidateIndex`) with candidate-specific API. ADR-011's one-Image/
ImageTexture renderer architecture is unchanged. The historical DIRTY/CLEAN
design-gate reasoning (audit learning AL-007, prior phase/M10 notes) is
preserved as history and marked superseded, not erased. Owner manual QA of the
new transparent model (`tasks.md` SB-M10-005..011) remains open.

**Status**: Owner-locked.


---

### ADR-020: Global 15-color production pixel-art palette and difficulty color bands

**Decision**: Production logical pixel artwork uses one owner-locked global
palette, C01..C15 exactly, defined in
`data/palettes/scrubbots_palette_v1.json` and
`docs/08_PIXEL_ART_PALETTE_RULES.md`.

Distinct canonical logical colors actually used by cells must be:

```text
EASY       3..5
MEDIUM     6..7
HARD       8..9
VERY_HARD  10..12
```

CLEARED alpha-0 transparency is runtime state, not a palette color. Gameplay
background and presentation-only cell-grid/border overlays also do not count.

**Reason**: A fixed color vocabulary gives SCRUBBOTS a stable visual identity,
keeps slot/Scrubbot color matching deterministic, prevents references or AI
generation from quietly expanding the color space, and gives Level Factory a
hard content contract. The non-overlapping difficulty bands increase visual
complexity predictably while Very Hard's 10–12 cap avoids excessive color
noise even though the global library contains 15 available colors.

**Consequences**: External/reference/AI source colors must be explicitly
mapped or rejected. A production local palette is a used subset of C01..C15
in ascending global C-ID order. The older M09 exact-source importer remains
valid generic tooling but does not by itself make arbitrary palettes
production-legal. Production art audit, Factory validation and M48 QA must
enforce this decision before shipping.

**Status**: Accepted — owner locked 2026-09-06.


---

### ADR-021: Production gameplay background is BG01 Midnight Slate

**Decision** (owner-locked 2026-09-06): the production gameplay surface behind
the board is **BG01 Midnight Slate**, exactly `#202533` / RGB(32,37,51).

BG01 is deliberately separate from the locked C01..C15 production logical
pixel-art palette. It is not C16, never appears as a logical cell color in
LevelData, and never counts toward a level's difficulty color total.

**Reason**: CLEARED cells are alpha-0 holes. A dedicated non-palette background
keeps those holes visually distinct from ACTIVE C14 Charcoal/C08 Deep Blue
cells, gives the bright 15-color palette strong contrast, and makes the
ACTIVE->CLEARED state readable without inventing another gameplay color.

**Consequences**:

- BoardRenderer continues to output alpha 0 for CLEARED cells; the containing
  gameplay surface supplies BG01 underneath.
- Production gameplay uses BG01 unless the owner explicitly versions this
  rule.
- Debug/transparency-test scenes may intentionally use conspicuous non-production
  backgrounds such as magenta; those debug colors are not palette additions.
- UI/decorative colors outside logical pixel art remain governed by UI rules;
  this ADR only locks the gameplay board background.

**Status**: Owner-locked.

### ADR-022: Reservation is a separate ephemeral assignment layer, not a cell state

**Decision** (M14): target reservation lives in a dedicated
`ReservationState` module
(`scripts/gameplay/targeting/reservation_state.gd`), **separate from
BoardState**. `BoardState.CellState` remains exactly `ACTIVE`/`CLEARED`
(ADR-019); **no `RESERVED` cell state is added**. This formally resolves the
deferred gate SB-M02-017 ("add RESERVED only when reservation architecture is
designed") — the architecture is now designed, and the answer is that RESERVED
does not belong in the cell lifecycle.

Reservation is **temporary target-assignment metadata**, not artwork/access
state. A reservation binds a target cell index to a single future in-flight
dispatch/agent assignment, identified by a deterministic integer `owner_id`
(`>= 0`). The owner token is NOT a color id, slot id, or cell id — it stands
for one future assignment supplied by the later dispatcher/agent layer.

**Rules enforced by the layer**:

- One target index has at most one owner.
- One `owner_id` holds at most one target at a time.
- `reserve()` is synchronous check-and-set: validation, conflict check and
  insertion happen in one uninterrupted call with no `await`/deferred gap, so
  competing calls for the same target are serialized and exactly one wins.
- A reservation is legal only for a currently valid ACTIVE cell of the bound
  board; invalid index, CLEARED target, invalid owner, already-reserved
  target, or an owner already holding a target all fail without mutation.
- `release()`/`resolve_arrival()` are ownership-safe: only the current owner
  may remove a reservation, and it is removed exactly once.
- `resolve_arrival()` clears only the reservation — it does **not** mutate the
  BoardState cell. Board mutation (ACTIVE->CLEARED) on successful cleaning
  stays a later orchestration responsibility.
- `reset()` clears all reservations but keeps the board binding; `rebind()`
  clears all reservations from the prior board.

**Reason**: reservation is transient coordination truth with a lifetime tied
to an in-flight assignment, not to the artwork. Folding it into `CellState`
would (1) overload the physical lifecycle enum with scheduling concerns, (2)
break the packed-byte cell storage invariant's clean two-state meaning, and
(3) entangle the renderer (which must only ever see ACTIVE/CLEARED) with
assignment bookkeeping. A separate O(1) map-backed layer keeps each concern
independently testable and replaceable.

**Integration seam**: `ColorCandidateIndex` (M13) stays reservation-agnostic —
it owns no reservation state and never reads `ReservationState`. Callers pass
`ReservationState.get_reserved_indices()` (a detached, ascending copy) as the
excluded set into `ColorCandidateIndex.get_candidates()/has_candidates()`. The
future `TargetSelector` (M15) will *consume* reservation exclusions but will
not own them; the future dispatcher/agent (M18/M19) is the caller that
supplies unique owner tokens. This preserves the
ColorCandidateIndex -> reachability -> TargetSelector -> RoutingSystem
separation (ADR-005, ADR-020).

**Consequences**:

- Reservation lookup/reserve/release are O(1) average (dictionary-backed); no
  full-board scan runs on a normal reservation query. Verified at 59×59 =
  3481 cells.
- `get_reserved_indices()` returns a fresh detached `PackedInt32Array` in
  ascending order every call; no mutable internal collection leaks.
- The renderer and slot mechanics are untouched by M14.

**Status**: Accepted (M14).

### ADR-023: TargetSelector selects-and-reserves in one call over an injected access seam

**Context**: M15 must choose WHICH reachable candidate a Scrubbot assignment
gets. Two forces shape the design. (1) M16/M17 routing topology is still TO BE
DESIGNED, so the selector cannot depend on a real reachability/pathing
subsystem yet, but it also must not assume every raw color candidate is
reachable — a matching ACTIVE cell can be fully enclosed with no legal access
(AL-028). (2) M14 established atomic reservation ownership; exposing a
`target = choose()` … `reserve(target)` caller sequence would reintroduce a
race window between selection and ownership even on the synchronous main
thread.

**Decision**: `TargetSelector`
(`scripts/gameplay/targeting/target_selector.gd`, extends `RefCounted`) binds
three narrow dependencies — `BoardState` (final truth checks only),
`ColorCandidateIndex` (raw ascending candidates), `ReservationState` (atomic
ownership) — and exposes one primary path:
`select_and_reserve(color_id, owner_id, access_query) -> int`.

- **Injected access seam**: reachability truth is a per-call duck-typed
  `access_query` with `is_targetable(index) -> bool`. The selector never
  computes route geometry, runs AStar, inspects route points, or invents
  neighborhood topology — it *consumes* authoritative access truth. When
  `access_query` is null or lacks `is_targetable()`, the selector **fails
  closed** and returns -1. This lets M16+ supply a real reachability query
  later without changing the selector.
- **One atomic operation**: selection and `ReservationState.reserve()` happen
  inside the same synchronous call, removing the choose-then-reserve race.
- **Deterministic strategy**: first targetable candidate in ascending
  row-major candidate order — no random pick, no distance/route-length
  scoring, no fallback route logic. Per candidate: valid index → ACTIVE →
  matching color → unreserved → `access_query.is_targetable()` → atomic
  reserve. If a reserve loses to a competing synchronous assignment, iteration
  continues for the still-unassigned owner.
- **Narrow BoardState use**: final validation only, so stale/corrupt upstream
  candidate data can never yield an invalid, CLEARED, or wrong-color target.
  The selector never scans the whole board, duplicates board arrays, mutates
  any dependency, or owns the ACTIVE/CLEARED lifecycle.

**Reason**: keeping the reachability contract to a tiny injected query
preserves the ColorCandidateIndex → reachability → TargetSelector →
RoutingSystem separation (ADR-005, ADR-020, ADR-022) while unblocking M15
before routing exists. Fusing select+reserve keeps the M14 atomicity guarantee
end-to-end. Fail-closed-on-missing-query encodes AL-028 as a safety default:
absence of proof of reachability is treated as unreachable.

**Consequences**:

- Steady-state selection iterates only the requested color's candidate bucket;
  access-query calls are bounded by candidate iteration, not board size
  (verified at 59×59 = 3481 cells). Selection issues exactly one access query
  per call when the first candidate is targetable.
- `TargetSelector` exposes no route-generation/pathfinding API; M16
  RoutingSystem stays a separate, later module.
- The selector owns no mutable collection it hands out (no state leakage,
  AL-020); it mutates only `ReservationState` via its public `reserve()`.

**Status**: Accepted (M15).

### ADR-024: RoutingSystem interface — board-local route contract with injected access seam

**Context**: M16 opens the routing layer. TargetSelector (ADR-023) already
decides WHAT target a Scrubbot assignment gets and reserves it atomically.
M16 must define HOW a routing implementation answers "give me a route to that
already-assigned target" — but the real path algorithm and movement language
(4-neighbour vs 8-neighbour vs curves vs pixel collision vs AStar vs navmesh)
are deliberately deferred to M17. So M16 is a CONTRACT/interface milestone, not
a pathfinder. It also must be resolution-independent: routes cannot bake in
1080×2160, BoardRenderer pixel sizes, safe areas, or UI layout, because those
change per device and per milestone.

**Decision**: A small swappable routing contract plus detached data types under
`scripts/gameplay/routing/` (all `extends RefCounted`, explicit `preload`,
AL-001):

- **Board-local cell coordinate space** (resolution-independent): board
  top-left = `Vector2(0,0)`; one logical cell = 1.0×1.0 units; cell `(x,y)`
  spans `[x,x+1]×[y,y+1]`; cell center = `Vector2(x+0.5, y+0.5)`; the board
  rectangle spans `[0,board_width]×[0,board_height]`. This is NOT screen pixels
  and NOT global Canvas coordinates. Presentation maps these to pixels later
  using live BoardRenderer geometry. Cell index↔position math stays centralized
  in `BoardState`; routing never re-derives row-major indexing.
- **`RouteRequest`** (`route_request.gd`): exactly one already-assigned target —
  `start_position` (slot origin, board-local, **may lie outside the board**),
  `target_index`, `target_position` (canonical target cell center), plus
  `board_width`/`board_height`. It carries NO alternate/color candidate list, NO
  random fallback, NO target-selection or reservation-mutation callback, so a
  routing implementation structurally cannot retarget. `for_target(board, …)`
  derives the center and dimensions from BoardState so the caller cannot supply
  a mismatched center; BoardState itself is passed as a method argument, never
  stored in route data (AL-020).
- **`RouteResult`** (`route_result.gd`): detached, immutable-by-convention —
  `success`, `target_index`, board-local `points` (PackedVector2Array), stable
  `failure_reason` StringName. Success ⇒ `success==true`, target matches the
  request, `points.size() >= 2`, first point == slot origin, last point ==
  assigned target center, every segment accepted by access truth. Failure ⇒
  `success==false`, empty points, original target retained, explicit reason.
  Points are copied in and handed back detached so callers cannot mutate routing
  truth. "No route" is first-class failure, never an exception.
- **`RoutingSystem`** (`routing_system.gd`): swappable base contract
  `compute_route(request, board, access_query) -> RouteResult`. It is NOT a
  global singleton, so implementations swap per caller with no TargetSelector
  change. The base implementation invents no route — it returns a clean
  `NOT_IMPLEMENTED` failure. M16 ships no production algorithm.
- **Injected access/validity seam**: route validity consumes an authoritative
  duck-typed `access_query.is_segment_traversable(from, to, target_index) ->
  bool`, encoding the locked law (non-target ACTIVE cells block; CLEARED /
  background / outside-board free space is open; the assigned ACTIVE target may
  be the final endpoint). M16 does not decide HOW that truth is computed or what
  topology it uses — that is M17. Missing access truth fails closed.
- **`RouteValidator`** (`route_validator.gd`): stateless static checks for
  request structure and for a claimed route (target identity, ≥2 points, exact
  endpoints, and every consecutive segment through injected access truth).
- **Debug visualization** (`scripts/debug/route_debug_overlay.gd`): generic,
  debug-only, consumes a RouteResult ONLY (polyline + start/end markers on
  success; failure/no-route text otherwise) via a pure, directly-testable
  `build_draw_model()`. It never computes a route, never retargets, never
  mutates BoardState, and is not production gameplay UI.

**Reason**: a tiny board-local value contract keeps routing independent of phone
resolution and of the WHAT/HOW boundary (CLAUDE.md hard rule 14). Injecting the
access seam lets M17 supply real topology without touching route data, slot
logic, cell state, scoring, or rendering. The critical law is encoded
structurally: *route failure for target X is not permission to pick target Y* —
RoutingSystem has no handle to TargetSelector / ColorCandidateIndex /
ReservationState and cannot retarget.

**Consequences**:

- M17 owns the final routing algorithm and movement language; it subclasses
  `RoutingSystem` and supplies/consumes the real access-truth implementation.
- No AStar/BFS/DFS/direct/curved/collision-radius/congestion logic exists in
  M16; only tests/debug fixtures emit small fake routes to prove the interface.
- Coordinate contract verified up to 59×59 (max) and Very Hard rectangular
  53×59; segment queries are directly observed in tests (AL-018).

**Status**: Accepted (M16).

### ADR-025: Production routing — owner-selected Organized/curved on a grid-aware backbone

**Context**: M17 built three EXPERIMENTAL routing prototypes (Direct, Grid-aware,
Organized/curved) behind the M16 `RoutingSystem` contract (ADR-024) and a
Routing Prototype Lab for neutral comparison (M17-C001). The final movement
language was an explicit **owner design gate**; Claude was forbidden from
selecting a winner. The owner reviewed the lab and resolved the gate
(`coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md`,
2026-09-07): **OWNER_SELECTS_ORGANIZED**.

**Decision** (M17-C002): promote the owner-selected direction from experimental
prototype scope into PRODUCTION routing code under
`scripts/gameplay/routing/` (outside `prototypes/`):

- **`ProductionRoutingSystem`** (`production_routing_system.gd`, subclasses
  `RoutingSystem`): a deterministic **grid-aware planner** (4-neighbour
  board-local cell-centre lattice, fixed neighbour order up/right/down/left,
  deterministic nearest-first capped exterior perimeter bridge for outside-board
  slot origins) establishes valid reachability and an orthogonal path; a
  validity-preserving **organized/curved post-process** (collinear reduction →
  bounded shortcut → controlled quadratic-bezier corner rounding) is the movement
  language. Every emitted segment is re-checked through injected access truth and
  the shared `RouteValidator`; any invalid shortcut/curve falls back to the last
  valid section. It never selects/retargets and never mutates
  BoardState/ReservationState.
- **`ProductionAccessQuery`** (`production_access_query.gd`): the canonical
  production access truth (non-target ACTIVE blocks; CLEARED/outside-board open;
  assigned ACTIVE target enterable only as the final endpoint).
- **Direct** straight routing is **rejected for production** and retained only as
  a debug/baseline comparison tool in `prototypes/`.
- **Conservative production defaults** (owner tuning preference — reduce
  aggressive diagonal shortcuts, keep curves controlled/readable): bounded
  `max_shortcut_span = 2` (vs the experimental prototype's unbounded greedy
  shortcut) and `corner_radius = 0.25` (vs 0.35). Verified more conservative than
  the experimental Organized default on 59×59 (more points kept, ≥ distance,
  strictly smaller max segment — no board-spanning diagonals). Route validity is
  never sacrificed for aesthetics.

**Reason**: this is the direction the owner selected after visual review; it
keeps grid-aware full reachability while giving the organized/curved movement
language that is SCRUBBOTS' core visual identity, with conservative defaults so
dense scenes stay readable. Production is independent of experimental scope so
the M17 lab/prototypes/comparison remain intact as diagnostic evidence.

**Consequences**:

- M16 (ADR-024) contract, `RouteRequest`/`RouteResult`/`RouteValidator` are
  unchanged; production is a swappable subclass.
- The M17 experimental prototypes, lab scene, metrics, scenarios and
  `ROUTING_COMPARISON_V01.md` are retained (not production, not deleted).
- Collision radius, multi-bot congestion optimisation, ScrubbotAgent, Dispatcher,
  spawning, movement playback and arrival remain out of scope (M18+). No crossing/
  congestion optimisation beyond conservative route-shape defaults before
  profiling.
- Verified deterministic and RouteValidator-clean up to 59×59 (max) and
  rectangular Very Hard 53×59.

**Status**: Accepted (M17-C002).
