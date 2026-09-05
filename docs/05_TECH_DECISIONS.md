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

### ADR-002: Mobile-first, portrait-first responsive baseline

**Decision**: Design resolution baseline is 1080×2160 portrait, using Godot's
`canvas_items` stretch mode with `expand` aspect. UI is safe-area aware and
container/anchor driven.

**Reason**: SCRUBBOTS is mobile-first and the owner requires the gameplay
board to occupy a very large share of modern tall iPhone/Android screens.
The previous provisional 1080×1920 + `keep` baseline risked letterboxing or
wasting vertical space.

**Consequences**: Gameplay code remains resolution-independent. Required UI
validation includes 1080×2160, 1170×2532, 1290×2796, 1080×2400 and
1440×3200, plus shorter phone/tablet coverage before release. Decorative
content yields space before essential gameplay controls do.

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
fixed 40×40 / 1,600-cell size. The actual requirement is a variable-size
board engine. A fixed-40×40 architecture would unnecessarily restrict future
content and require a disruptive rewrite.

**Consequences**: All indexing, validation, rendering, targeting, routing,
and tests read width/height from board/level data. ADR-003's fixed-40×40
statement is superseded; the resolution-independence principle remains.

**Status**: Accepted.

---

### ADR-009: Explicit preload() over bare class_name for cross-script refs

**Decision**: Gameplay/data scripts reference each other via explicit
`const Foo = preload("res://path/to/foo.gd")` rather than relying on bare
`class_name` lookups.

**Reason**: Headless Godot on a clean machine may lack a global script class
cache. Explicit preloads parse reliably without a prior editor session.

**Consequences**: Slightly more boilerplate in exchange for robust headless
execution.

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

Width and height are checked independently, rectangular boards are valid,
TEST fixtures remain non-production, and the current production maximum is
59×59 = 3,481 cells. Production legality is handled by
`ProductionLevelValidator`, separate from generic structural validation.

**Reason**: Production rules must not leak into the dimension-agnostic engine.

**Consequences**: Production catalogs/import tooling call production
validation; generic board systems stay difficulty-agnostic.

**Status**: Accepted.

---

### ADR-011: BoardRenderer uses one Image/ImageTexture, not per-cell Nodes or per-frame draw calls

**Decision**: `BoardRenderer` draws the entire board as one `Image` converted
to one `ImageTexture`, nearest-neighbor filtered, with exactly one renderer
Node regardless of board size.

**Reason**: This preserves crisp logical pixels and avoids thousands of scene
objects or per-frame draw calls.

**Consequences**: Responsive UI may size/position the renderer but must never
replace it with per-cell Controls/Nodes.

**Status**: Accepted.

---

### ADR-012: Level Factory is a separate nested Godot project

**Decision**: The SCRUBBOTS Level Factory lives at `level_factory/` with its
own `project.godot`, docs, tests and coordination subtree. It is not loaded by
the shipping mobile game.

**Reason**: Generation/solver/QA workloads have different dependencies and
operational concerns from runtime gameplay.

**Consequences**: Integration is one-way through declarative data contracts.

**Status**: Accepted.

---

### ADR-013: Level Factory is constraint-based and reproducible

**Decision**: Production candidate generation is seed/config reproducible and
constraint-driven. Solver/difficulty adapters may only use canonical gameplay
semantics.

**Reason**: Reproducibility makes candidates debuggable and QA-able.

**Consequences**: Candidate provenance includes seed/config/generator version.

**Status**: Accepted, with solver semantics gated by future gameplay rules.

---

### ADR-014: Remote content is declarative data, never executable game code

**Decision**: Remote content may contain Level Data, pack/manifest metadata,
previews and explicitly supported declarative content, never executable
GDScript/native/plugin payloads.

**Reason**: Keeps app-code changes store-delivered and reduces attack surface.

**Consequences**: Payload schemas are allow-listed and validated; publishing
secrets never ship in the app.

**Status**: Accepted.

---

### ADR-015: Staging-first, versioned Content Pipeline

**Decision**: Remote publication follows validate → package/hash → upload →
staging → remote verification → explicit production promotion. Rollback and
disable operations are versioned/auditable.

**Reason**: Weekly production needs a safe operational control plane.

**Consequences**: Pack/manifests are versioned and integrity checked.

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
component/layout contract.

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
