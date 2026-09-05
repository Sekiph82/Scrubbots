---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: META-C002
version: 1
createdAt: 2026-09-05T12:38:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V01.md
baselineCommit: 1a8525a6892ae4563b7e2a27ea544568d7f0ae96
---

# SCRUBBOTS - Master UI + Magnific Main-Project Integration

## FIRST ACTION

Safely synchronize the local repository while preserving all owner work. Continue on `feature/master-ui-magnific-pipeline` / PR #3. Never use destructive Git operations or create a duplicate PR.

## Objective

Integrate the owner-approved Master UI and Magnific visual-production architecture into the **main SCRUBBOTS game roadmap**, ingest the owner's existing Desktop visuals as references, merge the full `docs/UI_TASKS_APPENDIX.md` migration specification into canonical `tasks.md`, validate the UI foundation and viewport changes, and stop before broad/final Magnific generation.

Visual production is part of the main mobile-game project. It is not a Level Factory/Content Pipeline-style sidecar and is not a separate art project.

## Canonical sources to read

Read repository governance first, then:

- `CLAUDE.md`
- `tasks.md`
- `docs/UI_TASKS_APPENDIX.md`
- `docs/MASTER_UI_SYSTEM.md`
- `ASSET_GENERATION_MANIFEST.json`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`
- `project.godot`
- PR #3 and all files changed by it

Follow current GitHub-only coordination/versioned-log policy. Create `coordination/sessions/META-C002/CLAUDE_LOG_V01.md`. Claude must not create an audit file or assign an audit verdict.

## Owner visual reference intake

Owner source folder:

`C:\Users\sekip\Desktop\ScrubBots Gorselleri`

Run the repository intake helper:

`powershell -ExecutionPolicy Bypass -File .\tools\import_desktop_visual_refs.ps1`

The operation is copy-only. Do not modify, delete, rename or overwrite Desktop originals.

Inventory/classify imported references at minimum as:

- Scrubby / characters
- gameplay screen
- five-slot / color-selection
- Home
- popup / level-intro
- logo / app icon
- boosters / rewards / props
- pixel-art construction
- level art
- conflicting/outdated references

Identify and record the best canonical Scrubby, gameplay, Home and popup/level-intro references. If a choice is ambiguous, mark it `OWNER_REQUIRED`; do not invent certainty. Historical/non-canonical references must be preserved, not deleted.

## tasks.md migration

`docs/UI_TASKS_APPENDIX.md` is an owner-approved migration specification, not a competing ledger.

Merge **all** policy and task content from it into root `tasks.md`, including:

- the global `VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]` block near the top;
- visual-production sequencing;
- early reference/canonical-style tasks;
- first real-art vertical-slice additions;
- M22 gameplay/slot asset production;
- M23 gameplay layout integration;
- M27 Scrubbot final Magnific character production;
- M37 Home-specific visual production;
- popup/level-intro/Results/Tutorial/Collection/Shop/Events integration rules;
- M44 responsive additions;
- M45 accessibility additions;
- Magnific asset lifecycle / Definition of Done.

Visual generation must occur inside the existing main-game milestone where each asset is actually required. Do not create a separate Magnific/art sidecar or second roadmap.

Preserve every existing `tasks.md` task/history item. Do not renumber unnecessarily, delete unfinished tasks, or mark new tasks complete without real evidence. Verify every appendix item exists exactly once and no existing task disappeared. Only after that verification delete `docs/UI_TASKS_APPENDIX.md`.

## Master UI / Magnific locked rules

- `docs/MASTER_UI_SYSTEM.md` is the responsive UI architecture contract.
- `ASSET_GENERATION_MANIFEST.json` is the generation/provenance queue.
- Magnific MCP only unless owner changes the decision. Do not add Higgsfield.
- Magnific is development-time only; the shipping game must never depend on MCP/API/network generation.
- AI full-screen mockups are art direction, not shippable flattened screens.
- Native Godot should own panels, interaction containers, text, counters, slots, color tiles, progress bars, popup bodies, safe-area and responsive layout.
- Magnific should be used for character art, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event/screen-specific branded illustration when needed.
- Raw candidates are not production-final. Preserve provenance and require owner approval where specified.
- Never silently regenerate or overwrite approved art.
- Never bake dynamic values/text/state into generated images.
- Keep existing `BoardRenderer` single-`Image`/`ImageTexture` architecture. Never introduce per-cell UI nodes.

## Responsive/UI validation

Review and validate the PR #3 changes, especially:

- `project.godot`: 1080x2160, `canvas_items`, `expand`
- `scripts/ui/ui_tokens.gd`
- `scripts/ui/responsive_layout.gd`
- `scripts/ui/safe_area_root.gd`
- `scenes/components/ui/common/safe_area_root.tscn`

Required viewport matrix:

- 1080x2160
- 1170x2532
- 1290x2796
- 1080x2400
- 1440x3200

Validate that existing startup/debug scenes remain healthy and that responsive scaling does not break BoardRenderer coordinate mapping. If real-device/editor-only checks remain, record them honestly rather than fabricating evidence.

## Approved gameplay composition

Preserve these owner-approved rules in tasks/docs:

- no Goal/Moves panel
- no right-side Level/lock rail
- board is dominant and expands before decoration
- color-selection panel width is protected
- five visible slots
- Scrubby low on the left of selection region
- speech bubble above Scrubby without narrowing selection panel
- cleaning props on the right with lower priority than controls
- four boosters in a compact horizontal row directly above the ad row
- pause left of ad, settings right of ad
- safe-area compliant, portrait mobile-first

Home remains responsive Godot composition using TopCurrencyHUD, SeasonProgress, MainWorldArea with left/center/right regions, PlayButton, RewardTrack and BottomNav. Popups should share a reusable BasePopup architecture and keep dynamic text/rewards/buttons live in Godot.

## Preserve gameplay architecture

Do not rebuild or damage established LevelData, BoardState, validators, BoardRenderer, GameplaySession, SlotState/SlotSystem or the TargetSelector WHAT vs RoutingSystem HOW boundary.

## Validation and evidence

Run the complete current Godot 4.7.1 headless regression suite and standard startup/parse checks. Record exact commands/results in `CLAUDE_LOG_V01.md`. Inspect the final diff for task loss/duplication and viewport/UI regressions.

Update required coordination indexes and H!veAI sources/dashboard before handoff. Update PR #3 with actual implementation/validation status.

## Stop condition

Do **not** begin broad or final Magnific generation in this pass.

Stop after:

1. Desktop references are safely ingested and classified;
2. canonical Scrubby/gameplay/Home/popup references are selected or explicitly owner-blocked;
3. all `UI_TASKS_APPENDIX.md` content is merged into `tasks.md` and the appendix is removed only after verified migration;
4. UI foundation/viewport changes are validated or remaining real-device checks are clearly recorded;
5. docs/manifest/coordination/H!veAI state is consistent;
6. PR #3 is updated;
7. cycle state is `AWAITING_AUDIT` or `BLOCKED`.

## Expected Claude response

Keep the chat response concise: cycle/state, commit/push status, `CLAUDE_LOG_V01.md` GitHub URL, test summary, owner decisions/blockers, and `READY FOR CHATGPT AUDIT` when appropriate.
