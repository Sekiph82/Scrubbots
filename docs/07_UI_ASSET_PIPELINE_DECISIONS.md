# 07 — UI & Visual Asset Pipeline Decisions

These owner-approved decisions supplement `docs/05_TECH_DECISIONS.md` and the canonical `docs/MASTER_UI_SYSTEM.md`.

## UI-ADR-001: Responsive 1:2 design baseline

**Decision**: Use 1080×2160 portrait as the primary reference viewport with Godot `canvas_items` stretch and `expand` aspect behavior.

**Reason**: SCRUBBOTS must make the gameplay board visually dominant on modern tall iPhone and Android screens instead of preserving a 16:9 letterboxed composition.

**Consequences**: Layout must be container/anchor driven, safe-area aware and tested at 1080×2160, 1170×2532, 1290×2796, 1080×2400 and 1440×3200. Gameplay logic remains resolution-independent.

**Status**: Owner-approved.

## UI-ADR-002: Native Godot UI plus generated decorative art

**Decision**: Production screens are composed from reusable Godot Controls. AI-generated full-screen mockups are visual references only. Generated art is restricted mainly to illustration-heavy elements such as characters, booster icons, rewards, difficulty emblems, decorative props and branded icon families.

**Reason**: Responsive UI must resize/reflow without regenerating images. Text, counters, panels, slots and progress states must remain dynamic.

**Consequences**: Use native Theme/StyleBox/PanelContainer/NinePatchRect/TextureRect/Button/container primitives. Do not ship a screenshot as the interactive UI.

**Status**: Owner-approved.

## UI-ADR-003: ChatGPT-primary image generation with Magnific fallback

**Decision**: ChatGPT image generation is the primary development-time image-generation workflow for SCRUBBOTS UI/character assets. Magnific MCP remains an approved fallback/alternate provider. Higgsfield is not a project dependency.

**Reason**: The owner prefers to create and iterate production visuals directly in the ChatGPT design workflow while retaining Magnific as a viable alternate path.

**Consequences**: `ASSET_GENERATION_MANIFEST.json` uses `chatgpt_image_generation` as its primary provider and `magnific` as fallback. No shipping build may require either provider, API credentials or generation credits at runtime.

**Status**: Owner-approved 2026-09-18.

## UI-ADR-004: Owner Desktop reference intake

**Decision**: `C:\\Users\\sekip\\Desktop\\ScrubBots Gorselleri` is an owner-confirmed SCRUBBOTS visual-reference source. Files are copied, never moved, into `assets/art/references/_owner_inbox/` through the repository intake helper.

**Reason**: Prior visual work must guide production art direction and should not remain invisible to development sessions.

**Consequences**: Desktop originals remain untouched. Inbox files are references until inventoried/classified and explicitly promoted. Generated derivatives never overwrite source references.

**Status**: Owner-approved.

## UI-ADR-005: Board-renderer preservation

**Decision**: Responsive UI work must keep the existing single-Image/ImageTexture `BoardRenderer` architecture. UI layout may size/position the renderer but may not replace it with one Node/Control per logical cell.

**Reason**: ADR-011 is already tested and performance-oriented.

**Consequences**: Board sizing is a presentation concern; board data/rendering architecture remains unchanged.

**Status**: Owner-approved.

## UI-ADR-006: Generated-asset lifecycle and Home inventory

**Decision**: Generated visual work has three separate layers: owner references, raw generated candidates and approved production assets. The canonical paths are `assets/art/references/`, `assets/ui/generated/` and `assets/ui/final/`. Home-screen asset requirements are tracked in `assets/ui/HOME_ASSET_MANIFEST.json`.

**Reason**: Raw candidates, approved art and immutable owner references must not become mixed or silently overwrite each other.

**Consequences**: Generated candidates are never production-final by default. Only approved assets are promoted to `assets/ui/final/`. Dynamic text, counters, timers and state remain native/live Godot UI and are not baked into images.

**Status**: Owner-approved 2026-09-18.
