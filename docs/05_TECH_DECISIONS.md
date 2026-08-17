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

**Decision**: Design resolution baseline 1080×1920 portrait, using Godot's
`canvas_items` stretch mode with `keep` aspect.

**Reason**: SCRUBBOTS is a mobile puzzle game; portrait is the expected
default orientation for this genre.

**Consequences**: UI and board layout should be designed/tested primarily in
portrait. The 1080×1920 baseline is provisional and easy to change (it is a
display setting, not gameplay logic) — do not hardcode gameplay math against
it.

**Status**: Accepted, provisional value.

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

**Status**: Accepted (locked — see `docs/01_GAMEPLAY_SPEC.md`).

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

**Status**: Accepted.

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
