# SCRUBBOTS Master UI / Magnific Task Appendix

This file is a staging appendix for the canonical root `tasks.md`. `tasks.md` remains the single task ledger. Claude Code must merge the policy block and task items below into the appropriate locations in root `tasks.md` during the next local synchronized implementation session. After verifying that no existing task history was lost and every item below has been integrated exactly once, delete this appendix.

> **OWNER-LOCKED SCOPE:** Visual generation is part of the main SCRUBBOTS game production roadmap. It is **not** a sidecar project, separate art project, or runtime service. Magnific MCP is a development-time asset-generation tool used inside the relevant main-game milestones. Approved outputs become normal Godot project assets under `res://`; the shipping game never depends on Magnific/MCP at runtime.

---

## A. GLOBAL POLICY BLOCK TO ADD NEAR THE TOP OF `tasks.md` [OWNER-APPROVED]

Claude Code must add the following policy near the beginning of root `tasks.md`, alongside the other master execution rules, without deleting or weakening existing policy:

### VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]

1. Visual production is an integral part of the **main SCRUBBOTS mobile game project and roadmap**. It must not be split into a Level Factory/Content Pipeline-style sidecar or treated as an unrelated final art pass.
2. Magnific MCP is the only approved AI image-generation provider for this workflow unless the owner explicitly changes that decision. Do not add Higgsfield as a dependency.
3. Magnific is a **development-time tool only**. The shipping game must never require Magnific, MCP, network generation, API credentials, or generation credits at runtime. Owner-approved generated outputs become ordinary versioned Godot assets.
4. Existing owner-created SCRUBBOTS artwork is the first visual authority. Import/copy and classify owner references before generating replacements or variants. Never overwrite or delete the owner's Desktop originals.
5. AI-generated full-screen mockups are art-direction/reference material, not shippable UI. Production screens must be composed from responsive Godot Controls/Containers plus approved illustration assets.
6. Prefer native Godot UI for panels, buttons/interaction containers, progress bars, slots, color tiles, currency counters, text, popup bodies, dim layers and responsive layout. Use Magnific for art that genuinely benefits from illustration generation: characters, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event art and similar branded artwork.
7. Raw Magnific candidates and owner-approved production assets are different lifecycle states. Never silently regenerate, replace or overwrite an approved production asset.
8. Every milestone that requires new visual assets owns its own visual-generation/review/import tasks. Do not postpone all visual production to one disconnected end-of-project art phase.
9. `docs/MASTER_UI_SYSTEM.md` is the canonical responsive UI architecture contract. `ASSET_GENERATION_MANIFEST.json` is the machine-readable Magnific generation queue/provenance contract.
10. `BoardRenderer` remains the existing single-`Image`/`ImageTexture` data-oriented renderer. The Master UI system must not replace logical board rendering with one UI node per cell.
11. Visual milestone completion requires actual owner-approved assets where required, correct Godot import/binding, responsive validation and regression evidence. A generated image existing on disk is not by itself completion.

---

## B. VISUAL PRODUCTION ORDER TO INTEGRATE INTO THE MAIN ROADMAP

The intended production sequence is:

1. **Reference intake and canonical visual selection first.** Import `C:\Users\sekip\Desktop\ScrubBots Gorselleri` copy-only into the repository reference inbox, inventory/classify it, and select canonical Scrubby/gameplay/home/popup references before broad Magnific generation.
2. **Core gameplay engineering continues without waiting for decorative art.** Target selection, routing, dispatcher/agent behavior, cleaning rules and other gameplay-critical work must not be blocked by decorative asset production when programmer art is sufficient.
3. **First real-art vertical slice.** Validate gameplay with owner-approved real level/pixel artwork before treating production visuals as proven. Magnific must not invent canonical logical level data or replace the level-data pipeline.
4. **Production gameplay UI asset generation begins when the relevant gameplay UI milestones open.** Generate only assets required by that milestone, review them, promote approved variants, then bind them to reusable Godot components.
5. **Final Scrubbot visual production happens in the existing Scrubbot visual milestone**, using the canonical Scrubby reference and approved visual language.
6. **Home, Results, Tutorial, Collection, Shop, Events and later screens generate their own required Magnific assets inside their existing milestones.** They do not wait for a separate global art project.
7. Final visual polish is a consolidation/QA pass over already-integrated milestone-owned art, not the first time production art is introduced.

---

## C. EARLY VISUAL REFERENCE LIBRARY / CANONICAL STYLE GATE

Merge these tasks into the earliest appropriate main-game visual/reference milestone (prefer the existing M07 visual-reference area if present; otherwise place them before production UI asset generation):

- [ ] SB-UI-001 Treat `docs/MASTER_UI_SYSTEM.md` as the UI architecture source of truth.
- [ ] SB-UI-002 Treat `ASSET_GENERATION_MANIFEST.json` as the machine-readable generation/provenance queue.
- [ ] SB-UI-003 Keep Magnific MCP as the only approved AI image provider unless the owner explicitly changes it.
- [ ] SB-UI-004 Do not add Higgsfield as a project dependency.
- [ ] SB-UI-005 Import owner visual references from `C:\Users\sekip\Desktop\ScrubBots Gorselleri` using `tools/import_desktop_visual_refs.ps1`.
- [ ] SB-UI-006 Preserve Desktop originals untouched and imported reference copies byte-for-byte; inventory/classify references before production promotion.
- [ ] SB-UI-007 Classify owner references at minimum into Scrubby/characters, gameplay UI, Home UI, popup/level-intro, logo/icon, pixel-construction, level-art and outdated/conflicting references.
- [ ] SB-UI-008 Select and record the canonical Scrubby master reference before generating new Scrubby poses/portraits.
- [ ] SB-UI-009 Select and record the canonical gameplay-screen art-direction reference.
- [ ] SB-UI-010 Select and record the canonical Home-screen art-direction reference.
- [ ] SB-UI-011 Select and record canonical popup/level-intro references.
- [ ] SB-UI-012 Identify conflicting/outdated references and keep them clearly non-canonical rather than deleting historical owner work.
- [ ] SB-UI-013 Validate manifest reference paths/IDs after canonical references are selected; do not begin broad Magnific production against placeholder reference IDs.

---

## D. FIRST REAL-ART VERTICAL SLICE ADDITIONS

Merge into the existing first playable/real-art vertical-slice milestone:

- [ ] SB-UI-014 Run at least one gameplay vertical slice using owner-approved real pixel/level artwork rather than treating a Magnific illustration as logical level data.
- [ ] SB-UI-015 Prove the logical board renderer, DIRTY/CLEAN treatment and responsive board presentation remain data-driven and independent of full-screen concept art.
- [ ] SB-UI-016 Record which visual gaps genuinely require Magnific generation before opening production gameplay UI generation.

---

## E. M22 — PRODUCTION SLOT UI + GAMEPLAY ASSET PRODUCTION ADDITIONS

- [ ] SB-M22-013 Confirm canonical gameplay UI references are approved/recorded before final asset generation.
- [ ] SB-M22-014 Validate the M22 entries in `ASSET_GENERATION_MANIFEST.json` before spending Magnific credits.
- [ ] SB-M22-015 Generate required gameplay booster assets with Magnific using the canonical SCRUBBOTS visual references.
- [ ] SB-M22-016 Generate only the gameplay decorative assets/props required by this milestone; do not generate unrelated future-screen art early.
- [ ] SB-M22-017 Keep raw Magnific candidates separate from production-final assets and preserve generation provenance.
- [ ] SB-M22-018 Require owner selection/approval before promoting a candidate to production-final status.
- [ ] SB-M22-019 Never silently regenerate or overwrite an approved production asset.
- [ ] SB-M22-020 Build slot visuals as reusable Godot components, not flattened screenshots.
- [ ] SB-M22-021 Keep quantities/text/state badges live in Godot; do not bake them into generated textures.
- [ ] SB-M22-022 Implement reusable BoosterButton states (`AVAILABLE`, `EMPTY`, `SELECTED`, `LOCKED`, `FREE_AD`) without baking quantity/state text into art.
- [ ] SB-M22-023 Bind approved Magnific booster/decorative art to the reusable Godot components.
- [ ] SB-M22-024 Preserve five visible slots at all required responsive test sizes.
- [ ] SB-M22-025 Validate asset import settings, transparency, filtering and mobile memory footprint before marking the visual portion complete.

---

## F. M23 — GAMEPLAY SCREEN LAYOUT + INTEGRATED VISUAL PRODUCTION [OWNER-APPROVED]

- [ ] SB-M23-016 Use `docs/MASTER_UI_SYSTEM.md` as the canonical gameplay layout contract.
- [ ] SB-M23-017 Remove Goal/Moves panel from the approved production gameplay composition.
- [ ] SB-M23-018 Make the board the dominant gameplay-screen region and allow it to expand before decorative regions.
- [ ] SB-M23-019 Keep the color-selection panel at protected usable width; never shrink it merely to preserve decoration.
- [ ] SB-M23-020 Place Scrubby low at the left of the color-selection region.
- [ ] SB-M23-021 Place Scrubby speech bubble above Scrubby instead of consuming a full-width row or narrowing the selection panel.
- [ ] SB-M23-022 Preserve right-side cleaning props as decorative art with lower layout priority than gameplay controls.
- [ ] SB-M23-023 Move four booster controls to a compact horizontal row directly above the bottom/ad row.
- [ ] SB-M23-024 Place pause to the left of the ad and settings immediately to the right of the ad.
- [ ] SB-M23-025 Do not add the removed right-side Level/lock rail back into the approved gameplay composition.
- [ ] SB-M23-026 Bind only owner-approved gameplay illustrations/props; keep the screen itself responsive/native rather than flattening it into one generated image.
- [ ] SB-M23-027 Prove `BoardRenderer` coordinate mapping remains correct after responsive scaling.
- [ ] SB-M23-028 Capture validation evidence at all required viewport sizes before marking the production gameplay composition complete.

---

## G. M27 — SCRUBBOT FINAL VISUALS / MAGNIFIC CHARACTER PRODUCTION

Merge these into the existing Scrubbot final-visual milestone rather than creating a separate art project:

- [ ] SB-M27-UI-001 Use the owner-approved canonical Scrubby master reference for Magnific character generation.
- [ ] SB-M27-UI-002 Validate character-generation manifest entries and required pose/state list before generation.
- [ ] SB-M27-UI-003 Generate only the gameplay poses required by implemented Scrubbot behavior.
- [ ] SB-M27-UI-004 Generate required Scrubby portrait/profile variants using the same canonical reference.
- [ ] SB-M27-UI-005 Generate additional emotion/state variants only when an implemented screen/flow requires them.
- [ ] SB-M27-UI-006 Preserve raw candidates and generation provenance separately from production-final character assets.
- [ ] SB-M27-UI-007 Require owner visual approval before any generated character variant becomes production-final.
- [ ] SB-M27-UI-008 Lock approved character assets against silent regeneration/overwrite.
- [ ] SB-M27-UI-009 Configure Godot import/filter/compression settings appropriate to each approved character asset.
- [ ] SB-M27-UI-010 Integrate approved art with travel, arrival, cleaning and disappearance animation/presentation without coupling visual animation to TargetSelector logic.
- [ ] SB-M27-UI-011 Validate character readability and scale on the required phone viewport matrix.

---

## H. M37 — HOME / NAVIGATION + HOME-SPECIFIC VISUAL PRODUCTION

- [ ] SB-M37-010 Build Home as responsive Godot containers/components, not a flattened screen image.
- [ ] SB-M37-011 Recreate owner-approved Home art direction with `TopCurrencyHUD`, `SeasonProgress`, `MainWorldArea`, `PlayButton`, `RewardTrack` and `BottomNav` regions.
- [ ] SB-M37-012 Keep left/right shortcut columns independently responsive around the central Scrubby/world area.
- [ ] SB-M37-013 Validate Home-specific manifest entries before Magnific generation.
- [ ] SB-M37-014 Generate only Home-specific illustrative assets that cannot reasonably be native Godot UI, using canonical references.
- [ ] SB-M37-015 Keep currency values, level/XP, timers, notification counts, labels and navigation state as live Godot UI.
- [ ] SB-M37-016 Require owner approval before promoting Home illustration candidates to production-final.
- [ ] SB-M37-017 Bind approved Home art to responsive components and validate on the required viewport matrix.

---

## I. POPUPS / LEVEL INTRO / RESULTS / TUTORIAL / COLLECTION / SHOP / EVENTS

Claude Code must merge these principles/tasks into the relevant existing milestones rather than creating a new standalone visual project:

- [ ] SB-UI-017 Implement one reusable `BasePopup` composition and derive Level Intro, Life, Need a Hand, Victory, Fail and Out of Moves flows from it.
- [ ] SB-UI-018 Keep popup text, rewards, quantities, buttons and state dynamic in Godot; Magnific may provide decorative headers/emblems/illustrations only where needed.
- [ ] SB-UI-019 For every later screen milestone (Results, Tutorial, Collection, Shop, Events and similar), identify required illustration assets inside that milestone, add/validate manifest entries, generate with Magnific, obtain owner approval, promote final assets and bind them before closing that milestone's visual work.
- [ ] SB-UI-020 Do not pre-generate large speculative asset libraries for screens whose actual component/state requirements are not yet known.
- [ ] SB-UI-021 Treat final visual polish as consolidation/QA of milestone-integrated art, not as the first production-art implementation phase.

---

## J. M44 — RESPONSIVE UI EXPANSION [OWNER-APPROVED]

- [ ] SB-M44-011 Adopt 1080×2160 as reference design viewport and `canvas_items` + `expand` stretch policy.
- [ ] SB-M44-012 Implement reusable `SafeAreaRoot`.
- [ ] SB-M44-013 Implement centralized UI tokens.
- [ ] SB-M44-014 Implement `COMPACT` / `NORMAL` / `TALL` layout classification.
- [ ] SB-M44-015 Validate 1080×2160.
- [ ] SB-M44-016 Validate 1170×2532.
- [ ] SB-M44-017 Validate 1290×2796.
- [ ] SB-M44-018 Validate 1080×2400.
- [ ] SB-M44-019 Validate 1440×3200.
- [ ] SB-M44-020 Validate minimum touch target 88 reference pixels unless the accessibility pass raises it.
- [ ] SB-M44-021 Confirm popups fit safe area without clipping at all required target sizes.
- [ ] SB-M44-022 Confirm text containers survive longer localized strings without image regeneration.
- [ ] SB-M44-023 Confirm board dominance does not cause protected bottom gameplay controls to clip or become unusable on compact devices.
- [ ] SB-M44-024 Add automated/manual responsive validation evidence before any production UI milestone is marked complete.

---

## K. M45 — ACCESSIBILITY ADDITIONS

- [ ] SB-M45-008 Do not encode important state solely in decorative generated artwork.
- [ ] SB-M45-009 Keep labels/counts as live Godot text and preserve contrast independently from the illustration layer.
- [ ] SB-M45-010 Ensure generated icon families remain distinguishable at actual mobile display size, not only at Magnific source resolution.
- [ ] SB-M45-011 Ensure essential gameplay meaning remains understandable if decorative illustration is hidden or fails to load.

---

## L. MAGNIFIC ASSET LIFECYCLE / DEFINITION OF DONE

Merge these into the appropriate global validation/asset-production section of `tasks.md`:

- [ ] SB-UI-022 Use Magnific primarily for character, booster, reward, difficulty/emblem, decorative prop, collection/event and similar branded illustration assets.
- [ ] SB-UI-023 Prefer native Godot controls/styles for panels, interaction containers, text, slots, color tiles, counters, progress bars, popup bodies and responsive layout.
- [ ] SB-UI-024 Every generated asset must have traceable manifest ID, intended use, reference source(s), raw candidate location and production-final location/status.
- [ ] SB-UI-025 Raw generation output is never automatically production-final.
- [ ] SB-UI-026 Owner approval is required before production promotion for character identity, major branded art and screen-defining illustration assets.
- [ ] SB-UI-027 Approved assets must be imported/configured in Godot and actually bound to the relevant reusable component/screen before their implementation task can be complete.
- [ ] SB-UI-028 Never silently regenerate/overwrite an approved asset. A deliberate replacement must create reviewable provenance/history.
- [ ] SB-UI-029 Do not bake dynamic text, quantities, timers, prices, currency values or gameplay state into generated images.
- [ ] SB-UI-030 Keep the existing single-`Image`/`ImageTexture` `BoardRenderer` architecture; never create per-cell UI nodes as part of the visual pipeline.
- [ ] SB-UI-031 Validate transparency, edge quality, source resolution, final resize, texture filtering/compression, memory footprint and visual readability before production promotion where applicable.
- [ ] SB-UI-032 Record Magnific credit-conscious behavior: reuse canonical references, avoid speculative bulk generation, generate by milestone need, and prefer Godot-native construction when generation adds no meaningful visual value.

---

## Removal condition

Delete this appendix only after Claude Code has:

1. added the **Global Visual Production / Master UI Workflow** policy near the top of root `tasks.md`;
2. merged every applicable task above into the correct existing main-game milestone/validation section exactly once;
3. preserved all pre-existing `tasks.md` history and task IDs;
4. verified that visual production is represented as part of the main SCRUBBOTS roadmap, not as a sidecar project;
5. verified that Magnific generation occurs at the milestone where each asset is actually needed;
6. updated any required coordination/H!veAI evidence under repository governance; and
7. reviewed the final `tasks.md` diff for accidental deletion, duplication or milestone-order corruption.

Do not treat this appendix as a competing canonical ledger. Until the verified merge is complete, it is only the owner-approved migration specification for `tasks.md`.