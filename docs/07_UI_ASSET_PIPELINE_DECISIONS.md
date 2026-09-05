# 07 — UI & Visual Asset Pipeline Decisions

These owner-approved decisions supplement `docs/05_TECH_DECISIONS.md` and are intended to be folded into the main ADR file during the next local Claude Code documentation pass.

## UI-ADR-001: Responsive 1:2 design baseline

**Decision**: Use 1080×2160 portrait as the primary reference viewport with Godot `canvas_items` stretch and `expand` aspect behavior.

**Reason**: SCRUBBOTS must make the gameplay board visually dominant on modern tall iPhone and Android screens instead of preserving a 16:9 letterboxed composition.

**Consequences**: Layout must be container/anchor driven, safe-area aware and tested at 1080×2160, 1170×2532, 1290×2796, 1080×2400 and 1440×3200. Gameplay logic remains resolution-independent.

**Status**: Owner-approved.

## UI-ADR-002: Native Godot UI plus generated decorative art

**Decision**: Production screens are composed from reusable Godot Controls. AI-generated full-screen mockups are visual references only. Magnific-generated art is restricted mainly to illustration-heavy elements such as characters, booster icons, rewards, difficulty emblems and decorative props.

**Reason**: Responsive UI must resize/reflow without regenerating images. Text, counters, panels, slots and progress states must remain dynamic.

**Consequences**: Use native Theme/StyleBox/PanelContainer/NinePatchRect/TextureRect/Button/container primitives. Do not ship a screenshot as the interactive UI.

**Status**: Owner-approved.

## UI-ADR-003: Magnific-only AI image provider

**Decision**: Magnific MCP is the sole AI image-generation provider for the SCRUBBOTS Master UI Asset Kit unless the owner explicitly revises this decision. Higgsfield is not a project dependency.

**Reason**: The owner already has Magnific credits and does not want an additional paid image provider. Magnific provides image generation, references, background removal, resize/upscale and vector-related tooling sufficient for the planned asset pipeline.

**Consequences**: `ASSET_GENERATION_MANIFEST.json` must use `provider: magnific`. No implementation may require Higgsfield credentials or subscription access.

**Status**: Owner-approved.

## UI-ADR-004: Owner Desktop reference intake

**Decision**: `C:\Users\sekip\Desktop\ScrubBots Gorselleri` is an owner-confirmed SCRUBBOTS visual-reference source. Files are copied, never moved, into `assets/art/references/_owner_inbox/` through the repository intake helper.

**Reason**: Prior visual work must guide production art direction and should not remain invisible to Claude Code sessions.

**Consequences**: Desktop originals remain untouched. Inbox files are references until inventoried/classified and explicitly promoted. Magnific never overwrites source references.

**Status**: Owner-approved.

## UI-ADR-005: Board-renderer preservation

**Decision**: Responsive UI work must keep the existing single-Image/ImageTexture `BoardRenderer` architecture. UI layout may size/position the renderer but may not replace it with one Node/Control per logical cell.

**Reason**: ADR-011 is already tested and performance-oriented.

**Consequences**: Board sizing is a presentation concern; board data/rendering architecture remains unchanged.

**Status**: Owner-approved.
