---
coordinationSchema: scrubbots-coordination/v1
artifactType: chatgpt-prompt
cycleId: M07-C001
version: 1
createdAt: 2026-08-27T11:42:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M07
taskRefs:
  - SB-M07-001
  - SB-M07-002
  - SB-M07-003
  - SB-M07-004
  - SB-M07-005
  - SB-M07-006
  - SB-M07-007
  - SB-M07-008
  - SB-M07-009
  - SB-M07-010
  - SB-M07-011
  - SB-M07-012
  - SB-M07-013
  - SB-M07-014
  - SB-M07-015
  - SB-M07-016
  - SB-M07-017
baselineCommit: c12bed98c60eacf02aa26f0da711b73a36315e43
---

# SCRUBBOTS - PROMPT 05

## PHASE M07 - Visual Reference Library Foundation + Asset Availability Audit

## Objective

Build the repository-native visual reference library and intake/audit foundation for SCRUBBOTS without inventing, regenerating, downloading, resizing, or silently reclassifying artwork.

This cycle must establish the structure and rules needed for future owner-approved SCRUBBOTS artwork to enter the project safely. It must also inspect what visual assets actually exist in the repository at execution time and record truthful availability.

This is the first normal implementation cycle under the new ChatGPT <-> Claude coordination protocol.

The cycle is complete when the visual-reference infrastructure is implemented and validated, even if the M07 milestone remains PARTIAL because owner artwork is still unavailable.

Do not falsely complete asset-inventory tasks that require files which do not exist.

## Repository baseline

- Repository: `Sekiph82/Scrubbots`
- Branch: `main`
- Prompt-authoring baseline: `c12bed98c60eacf02aa26f0da711b73a36315e43`
- Coordination cycle: `M07-C001`
- Milestone: `M07 - Visual Reference Library`
- Previous technical milestone: M06 BoardRenderer complete, last gameplay evidence 227/227 headless checks PASS at commit `abd9ceb`
- Relevant prior process cycle: `META-C001`

IMPORTANT: this prompt is committed to GitHub after the baseline above. Before implementation, synchronize the local repository with `origin/main` using a safe fast-forward pull and record the actual implementation starting commit in the Claude implementation log.

Do not reset, force-push, or destroy local owner work to match GitHub.

## Authoritative sources to read first

Read in this order before modifying anything:

1. `CLAUDE.md`
2. `tasks.md`
3. `.hiveai/PROJECT_DASHBOARD.md`
4. `coordination/README.md`
5. `coordination/SESSION_INDEX.md`
6. this exact file: `coordination/sessions/M07-C001/CHATGPT_PROMPT_V01.md`
7. relevant project docs, especially:
   - `docs/00_PROJECT_BRIEF.md`
   - `docs/01_GAMEPLAY_SPEC.md`
   - `docs/02_TECH_ARCHITECTURE.md`
   - `docs/04_ROADMAP.md`
   - `docs/05_TECH_DECISIONS.md`
   - `docs/06_TEST_STRATEGY.md`
8. current visual/art directories and repository tree

If an owner note or later audit/prompt version appears in this cycle, read artifacts in version order. Never edit this published prompt.

## Mandatory local phase log

Continue the permanent one-phase-one-log workflow.

For M07 use exactly:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M07_LOG.md`

Create it at the start if it does not exist. If it already exists, read it and continue the same file.

Update it continuously after meaningful checkpoints, including inspection, decisions, file changes, test runs, failures/fixes, commit and push.

Never commit this Desktop log.

## Mandatory GitHub implementation log

Create and maintain:

`coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md`

Use `coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md` as the starting structure.

This file is Claude-owned and append-only for the life of this cycle. If this cycle spans multiple Claude sessions, append new session entries. Do not rewrite earlier failure/history entries to make the work look cleaner.

At the beginning of substantial work, update `coordination/SESSION_INDEX.md` and `.hiveai/PROJECT_DASHBOARD.md` to accurately reflect `CLAUDE_IN_PROGRESS` when practical.

Before ending the implementation pass, update both again and hand the cycle back as `AWAITING_AUDIT` or `BLOCKED`, whichever is truthful.

## Locked visual-reference hierarchy

Preserve the visual authority already defined in `tasks.md` and `CLAUDE.md`:

1. Owner-approved original SCRUBBOTS artwork is canonical visual evidence.
2. Owner-supplied SCRUBBOTS reference images are secondary project reference evidence.
3. External game references are limited inspiration only and must never be copied into SCRUBBOTS art, characters, levels, UI, compositions, animations, or code.

Colony Flow may be referenced only for the broad feeling of many small agents flowing across a play area. SCRUBBOTS behavior remains:

`slot -> Scrubbot leaves -> travels to valid pixel -> cleans/reveals pixel -> disappears`

Never reproduce Colony Flow assets or exact visual design.

## Known expected visual categories, not proof of file availability

Prior project planning references these expected categories:

- original Scrubbot character concepts;
- gameplay-screen concepts;
- five-slot gameplay/layout concepts;
- original pixel-art level artwork;
- themed level artwork, including a previously discussed underwater SCRUBBOTS scene;
- original UI/effect concepts;
- pixel-construction-method reference screenshots;
- external movement-flow references such as Colony Flow, conceptually only.

These descriptions are intake expectations, NOT evidence that files exist locally.

Do not regenerate any missing artwork from these descriptions and label it as original.

## Current known project state to verify, not blindly trust

The last verified project audit found no owner-approved SCRUBBOTS artwork inside the repository art folders. The repository now also contains an Akilta brand wordmark under `assets/brand/`; that is company/project attribution branding and must NOT be misclassified as SCRUBBOTS gameplay/reference artwork.

Inspect the current repository again because files may have changed since that audit.

## In scope

### A. Repository visual-asset inspection

Inspect the repository for visual assets and classify what actually exists.

At minimum inspect:

- `assets/`
- `assets/art/`
- `assets/brand/`
- relevant debug/reference scenes that may point to artwork
- any clearly named project visual/reference directories

Do not roam the user's Desktop and ingest arbitrary images merely because they exist there.

Do not copy ambiguous images from outside the project into the repository.

If an asset's identity or owner approval cannot be established from repository evidence or explicit owner instruction, treat it as unavailable/unverified.

### B. Visual reference directory structure

Establish a clean version-controlled reference structure consistent with the master plan. Prefer the existing planned hierarchy unless current repo structure provides a clearly better non-destructive fit:

`assets/art/references/gameplay/`
`assets/art/references/ui/`
`assets/art/references/scrubbots/`
`assets/art/references/pixel_method/`
`assets/art/references/external_inspiration/`

Also ensure the future production-art structure is clearly represented without destructively moving existing files:

`assets/art/characters/scrubbots/`
`assets/art/levels/source/easy/`
`assets/art/levels/source/medium/`
`assets/art/levels/source/hard/`
`assets/art/levels/source/very_hard/`
`assets/art/levels/previews/`

Use `.gitkeep` only where required to retain intentionally empty directories.

Do not reorganize or move existing verified owner assets unless there is an explicit safe reason and original source preservation is guaranteed.

### C. Human-readable visual reference guide

Create a canonical guide under the reference area, preferably:

`assets/art/references/README.md`

It must define at minimum:

- the authority hierarchy;
- source classes;
- owner-approval semantics;
- availability states;
- canonical asset-ID/naming convention;
- source-original preservation rule;
- allowed use of external inspiration;
- prohibition on fabricated "original" replacements;
- how new owner assets are ingested;
- how an asset graduates from reference to production candidate;
- where full pixel/dimension audit begins in M08 rather than M07;
- relationship to the M10 DIRTY/CLEAN visual design gate.

### D. Machine-readable/reference inventory

Create a simple durable inventory/manifest under `assets/art/references/` using a built-in, dependency-free format such as JSON unless the existing repo strongly favors another simple format.

The inventory must distinguish:

- assets that physically exist and were verified;
- expected-but-missing owner assets;
- external inspiration references;
- project branding that is explicitly outside SCRUBBOTS gameplay/reference art.

Use stable logical asset IDs instead of relying only on filenames.

Metadata should support, where applicable:

- stable ID;
- category;
- source class;
- approval status;
- availability status;
- repository path or null when missing;
- original filename when known;
- intended use;
- notes/provenance;
- optional logical width/height when already known from reliable evidence;
- optional candidate difficulty when reliably known.

Do not run M08's full pixel-level technical audit in this cycle.

Do not invent dimensions or difficulty metadata when unknown.

### E. Canonical naming rules

Define a naming/ID system that is predictable and cross-platform safe.

Important: preserving the original source file is more important than cosmetic renaming.

Do not destructively rename an owner original solely to satisfy the new naming convention. A stable manifest ID may be used to normalize identity while the source file retains its original filename.

### F. Owner approval and source preservation

Define at least the semantic difference between states equivalent to:

- owner-approved/canonical;
- owner-supplied but not yet approved for production;
- external inspiration only;
- awaiting owner asset;
- unverified/ambiguous.

Use names that are clear and consistent with the repository.

Owner originals must be preserved byte-for-byte once ingested. Any future derived, resized, palette-converted, preview, or gameplay form must be a separate derived artifact, never an in-place overwrite of the source original.

### G. Missing-asset inventory

If expected owner assets are not present, explicitly record them as `AWAITING OWNER ASSET` or the exact established equivalent.

At minimum account for the M07 task categories:

- Scrubbot character visuals;
- gameplay-screen references;
- five-slot references;
- level artwork;
- underwater level artwork if not present;
- other original theme artwork;
- pixel-construction reference screenshots.

Do not create fake placeholder images to make these rows appear complete.

### H. External reference separation

Record external inspiration separately from original SCRUBBOTS art.

Do not download new web/reference images during this cycle.

A textual record of the already-established Colony Flow movement inspiration is acceptable as provenance/context, but it must make clear that no copied asset is being adopted as project art.

### I. DIRTY/CLEAN design-gate continuity

Do not choose a final DIRTY preset in this cycle.

The repository currently has A/B/C prototypes. Preserve the design gate.

The visual reference guide should note the existing locked readability principle:

- CLEAN settles to the original source palette color;
- DIRTY must remain visually distinct at tiny physical cell sizes using both saturation and brightness/value differences;
- final DIRTY treatment requires owner review at realistic 50x50 and 59x59 display scale;
- M07 library work must not silently mark M10 complete.

## Out of scope

Do NOT begin:

- M08 full technical pixel-art audit;
- M09 pixel-art importer/converter;
- image palette extraction;
- anti-aliasing/pixel-perfect round-trip implementation;
- production level conversion;
- source-image resizing or resampling;
- BoardRenderer redesign;
- final DIRTY/CLEAN preset selection;
- slots;
- target selection;
- routing;
- Scrubbot agents;
- gameplay completion rules;
- audio/effects/economy/progression.

Do not generate new SCRUBBOTS art in this cycle.

## Task-status rules

Use `tasks.md` as the only canonical task ledger.

After implementation and validation, update only M07 items that are truly complete.

Likely infrastructure tasks such as directory structure, guide, separation rules, naming, metadata, owner-approval semantics, source-preservation policy and missing-asset flagging may become `[x]` if actual repository evidence supports them.

Asset-specific inventory tasks such as SB-M07-008 through SB-M07-014 must remain `[ ]` when the required owner files are absent. Keep or improve their `AWAITING OWNER ASSET` notes.

Do not mark all of M07 complete simply because the library framework exists.

If the repository unexpectedly contains clearly verified owner assets, inventory them truthfully, but do not infer owner approval from filename alone.

## Documentation requirements

Update documentation only where this implementation creates new project truth.

At minimum inspect whether changes are required in:

- `tasks.md`
- `CHANGELOG.md`
- `docs/04_ROADMAP.md`
- relevant visual/reference sections in existing docs

Do not create an ADR unless an actual durable architecture decision warrants one.

Do not rewrite unrelated project docs.

## Validation requirements

Before changes, record baseline repository status and run the existing regression suite when practical.

Before completion, run at minimum:

`godot --version`

`powershell -File tools\verify_project.ps1`

`godot --headless --path . --quit-after 5`

`godot --headless --path . -s res://tests/run_tests.gd`

`git diff --check`

`git status --short`

Record exact results in both the Desktop M07 phase log and the GitHub Claude implementation log.

The previous known gameplay baseline is 227/227. Report the actual count you observe. Do not claim 227/227 unless the command actually passes in this session.

Because this cycle is primarily reference-library/documentation structure, do not invent GPU/FPS measurements or unrelated performance claims.

## Git requirements

Before modifying, synchronize safely with remote `main` when possible:

`git status`

`git fetch origin`

`git pull --ff-only origin main`

If local owner work prevents a safe fast-forward, preserve it and record the situation instead of destroying it.

Before commit:

`git status`

`git diff`

`git diff --check`

Ensure no Desktop phase log, secrets, cache, `.godot/`, generated build output, arbitrary Desktop images, or unverified external art is committed.

Use a focused commit message, for example:

`docs: establish Scrubbots visual reference library`

Push safely to `origin/main` according to the repository's existing workflow. Never force-push.

## Coordination requirements before ending Claude work

1. Append full evidence to `coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md`.
2. Update `tasks.md` only for validated M07 truth.
3. Update `coordination/SESSION_INDEX.md` for `M07-C001`.
4. Update `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary and current-cycle row.
5. Keep H!veAI's `single-dashboard-watch` model intact.
6. If the implementation pass is ready for review, set cycle state to `AWAITING_AUDIT`.
7. If work cannot proceed because required owner input is necessary for the cycle objective, set `BLOCKED` and state exactly what is needed.
8. Do not mark `AUDITED_PASS`; that state is reserved for the subsequent ChatGPT audit.
9. Do not edit `CHATGPT_PROMPT_V01.md`.

## Definition of done for M07-C001

This cycle is ready for ChatGPT audit when:

- repository asset availability has been re-inspected;
- visual reference directory structure exists and is coherent;
- visual reference guide exists;
- a simple durable inventory/manifest exists;
- original vs owner reference vs external inspiration is explicitly separated;
- canonical IDs/naming policy is defined;
- owner approval semantics are defined;
- source-original preservation is defined;
- missing owner asset categories are explicitly represented without fabrication;
- external movement inspiration is isolated and non-copying rules are clear;
- DIRTY/CLEAN owner design gate remains open;
- relevant M07 `tasks.md` items reflect actual validated truth;
- regression/verification commands are recorded;
- Desktop M07 log is current;
- GitHub Claude implementation log is current;
- session index and H!veAI dashboard are synchronized;
- commit/push evidence exists or a precise blocker is recorded.

M07 itself may truthfully remain PARTIAL / AWAITING OWNER ASSET after this cycle.

## Expected Claude final response

Return a concise report in this form:

Cycle: M07-C001
Phase: M07 - Visual Reference Library
Implementation status: <COMPLETE FOR CYCLE / BLOCKED>
Milestone status: <PARTIAL / COMPLETE>

Starting commit: <sha>
Ending commit: <sha>
Push: <status>

Reference structure: <status>
Reference guide: <status>
Manifest/inventory: <status>
Verified owner SCRUBBOTS assets found: <count>
Awaiting owner asset categories: <list/count>
External references copied into project: NO
Source originals modified: NO
Final DIRTY preset selected: NO

Regression tests: <passed>/<total>
Headless boot: <status>
Project verification: <status>

Desktop phase log:
C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M07_LOG.md

GitHub implementation log:
coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md

Coordination state: AWAITING_AUDIT or BLOCKED
Blockers: <none or exact blocker>

READY FOR CHATGPT AUDIT

Then STOP.

Do not begin M08 or any later milestone.