# SCRUBBOTS Master UI / Magnific Task Appendix

This file is a staging appendix for the canonical root `tasks.md`. `tasks.md` remains the single task ledger. Claude Code must merge these items into the appropriate M22/M23/M37/M44/M45/M46 milestones during the next local synchronized implementation session and then delete this appendix once the merge is verified.

## M22 Production Slot UI additions

- [ ] SB-M22-013 Build slot visuals as reusable Godot components, not flattened screenshots.
- [ ] SB-M22-014 Preserve five visible slots at all required responsive test sizes.
- [ ] SB-M22-015 Keep quantities/text live; do not bake them into generated textures.

## M23 Gameplay Screen Layout additions [OWNER-APPROVED]

- [ ] SB-M23-016 Use `docs/MASTER_UI_SYSTEM.md` as the canonical gameplay layout contract.
- [ ] SB-M23-017 Remove Goal/Moves panel from approved production gameplay composition.
- [ ] SB-M23-018 Make board the dominant gameplay-screen region and allow it to expand before decorative regions.
- [ ] SB-M23-019 Keep color-selection panel at protected usable width; never shrink it merely to preserve decoration.
- [ ] SB-M23-020 Place Scrubby low at the left of the color-selection region.
- [ ] SB-M23-021 Place Scrubby speech bubble above Scrubby instead of consuming a full-width row.
- [ ] SB-M23-022 Preserve right-side cleaning props as decorative art with lower layout priority than gameplay controls.
- [ ] SB-M23-023 Move four booster controls to a compact horizontal row below the selection region.
- [ ] SB-M23-024 Place pause to the left of the bottom/ad row and settings to the right.
- [ ] SB-M23-025 Prove BoardRenderer coordinate mapping remains correct after responsive scaling.

## M37 Home / Navigation additions

- [ ] SB-M37-010 Build Home as responsive Godot containers/components, not a flattened screen image.
- [ ] SB-M37-011 Recreate owner-approved Home art direction with TopCurrencyHUD, SeasonProgress, MainWorldArea, PlayButton, RewardTrack and BottomNav regions.
- [ ] SB-M37-012 Keep left/right shortcut columns independently responsive around the central Scrubby/world area.

## M44 Responsive UI expansion [OWNER-APPROVED]

- [ ] SB-M44-011 Adopt 1080×2160 as reference design viewport and `canvas_items` + `expand` stretch policy.
- [ ] SB-M44-012 Implement reusable SafeAreaRoot.
- [ ] SB-M44-013 Implement centralized UI tokens.
- [ ] SB-M44-014 Implement COMPACT/NORMAL/TALL layout classification.
- [ ] SB-M44-015 Validate 1080×2160.
- [ ] SB-M44-016 Validate 1170×2532.
- [ ] SB-M44-017 Validate 1290×2796.
- [ ] SB-M44-018 Validate 1080×2400.
- [ ] SB-M44-019 Validate 1440×3200.
- [ ] SB-M44-020 Validate minimum touch target 88 reference pixels unless accessibility pass raises it.
- [ ] SB-M44-021 Confirm popups fit safe area without clipping at all required target sizes.
- [ ] SB-M44-022 Confirm text containers survive longer localized strings without image regeneration.

## M45 Accessibility additions

- [ ] SB-M45-008 Do not encode important state solely in decorative generated artwork.
- [ ] SB-M45-009 Keep labels/counts as live Godot text and preserve contrast independently from the illustration layer.

## Master UI Asset Kit / Magnific pipeline [LOCKED OWNER DECISION]

- [ ] SB-UI-001 Treat `docs/MASTER_UI_SYSTEM.md` as UI architecture source of truth.
- [ ] SB-UI-002 Treat `ASSET_GENERATION_MANIFEST.json` as machine-readable generation queue.
- [ ] SB-UI-003 AI image provider for this pipeline is Magnific MCP only unless owner explicitly changes it.
- [ ] SB-UI-004 Do not add Higgsfield as a project dependency.
- [ ] SB-UI-005 Import owner visual references from `C:\Users\sekip\Desktop\ScrubBots Gorselleri` with `tools/import_desktop_visual_refs.ps1`.
- [ ] SB-UI-006 Preserve imported reference originals byte-for-byte and classify/inventory them before production promotion.
- [ ] SB-UI-007 Select canonical Scrubby master reference from owner-supplied artwork before generating new character poses.
- [ ] SB-UI-008 Use Magnific primarily for character/booster/reward/difficulty/decorative illustration assets.
- [ ] SB-UI-009 Prefer native Godot controls/styles for panels, text, slots, color tiles, counters, progress bars and responsive layout.
- [ ] SB-UI-010 Store raw Magnific outputs separately from owner-approved production-final assets.
- [ ] SB-UI-011 Never silently regenerate/overwrite an approved asset.
- [ ] SB-UI-012 Add reusable popup base and derive Level Intro, Life, Need a Hand, Victory, Fail and Out of Moves flows from it.
- [ ] SB-UI-013 Implement reusable BoosterButton states (AVAILABLE/EMPTY/SELECTED/LOCKED/FREE_AD) without baking quantity badges into art.
- [ ] SB-UI-014 Add automated/manual responsive validation evidence before marking UI milestones complete.
- [ ] SB-UI-015 Keep existing single-Image/ImageTexture BoardRenderer architecture; never create per-cell UI nodes.

## Removal condition

Delete this appendix only after all items above have been merged into root `tasks.md` without losing existing task history. Do not treat this appendix as a competing canonical ledger.
