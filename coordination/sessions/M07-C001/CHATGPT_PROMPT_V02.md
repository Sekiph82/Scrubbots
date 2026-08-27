---
coordinationSchema: scrubbots-coordination/v1
artifactType: chatgpt-prompt
cycleId: M07-C001
version: 2
createdAt: 2026-08-27T11:53:00+03:00
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
supersedes: CHATGPT_PROMPT_V01.md
promptAuthoringBaseline: 7a2bbb75ee9589dd48e2104335c53771fd26d91d
---

# SCRUBBOTS - PROMPT 05 / M07-C001 V02

## Supersession notice

This prompt supersedes `CHATGPT_PROMPT_V01.md` before Claude implementation begins. Use V02 as the active implementation authority for cycle `M07-C001`. Keep V01 only as immutable historical evidence.

## Objective

Build the repository-native visual reference library and intake/audit foundation for SCRUBBOTS without inventing, regenerating, downloading, resizing, or silently reclassifying artwork.

This cycle must establish the structure and rules needed for future owner-approved SCRUBBOTS artwork to enter the project safely. It must also inspect what visual assets actually exist in the repository at execution time and record truthful availability.

The cycle is ready for audit when the visual-reference infrastructure is implemented and validated, even if milestone M07 remains PARTIAL because owner artwork is still unavailable. Do not falsely complete asset-inventory tasks that require files which do not exist.

## Repository

- Repository: https://github.com/Sekiph82/Scrubbots
- Branch: `main`
- Coordination cycle: `M07-C001`
- Milestone: `M07 - Visual Reference Library`
- Previous technical milestone: M06 BoardRenderer complete
- Last known gameplay evidence before this cycle: 227/227 headless checks PASS at commit `abd9ceb`

Before implementation, safely synchronize the local working copy with `origin/main`. Never reset, force-push, delete, or overwrite local owner work merely to match GitHub. Record the actual implementation starting commit in the Claude implementation log.

## Canonical GitHub sources to read first

Read these GitHub sources in this order before modifying the local project:

1. CLAUDE.md
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. tasks.md
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI Project Dashboard
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Coordination protocol
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. Coordination session index
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. This active prompt
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
7. Project brief
   https://github.com/Sekiph82/Scrubbots/blob/main/docs/00_PROJECT_BRIEF.md
8. Gameplay specification
   https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
9. Technical architecture
   https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
10. Roadmap
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/04_ROADMAP.md
11. Technical decisions
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/05_TECH_DECISIONS.md
12. Test strategy
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
13. Claude implementation-log template
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md

If a later prompt, audit, or owner-note artifact appears in this cycle, use the newest applicable artifact in version order. Never edit a published ChatGPT prompt or audit.

## Required logs and coordination evidence

### Local phase log

Maintain the existing local phase log:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M07_LOG.md`

This local file is the detailed crash-safe phase journal and must never be committed.

### GitHub Claude implementation log

Create and maintain this repository file:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md

Repository path:

`coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md`

Use this template:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md

The implementation log is Claude-owned and append-only for the life of this cycle. Record starting/ending commits, files changed, commands/tests, failures/fixes, decisions, task/doc updates, push state, blockers, and handoff state. Do not erase failure history after a fix.

At substantial-work start, update the session index and dashboard to `CLAUDE_IN_PROGRESS` when practical. Before ending, update both again and hand the cycle back as `AWAITING_AUDIT` or `BLOCKED`, whichever is truthful.

Canonical coordination URLs:

- Session index:
  https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- H!veAI Project Dashboard:
  https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- Expected ChatGPT audit after implementation:
  https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md

## Locked visual-reference hierarchy

Preserve the existing visual authority:

1. Owner-approved original SCRUBBOTS artwork is canonical visual evidence.
2. Owner-supplied SCRUBBOTS reference images are secondary project reference evidence.
3. External game references are limited inspiration only and must never be copied into SCRUBBOTS art, characters, levels, UI, compositions, animations, or code.

Colony Flow may be referenced only for the broad feeling of many small agents flowing across a play area. SCRUBBOTS behavior remains:

`slot -> Scrubbot leaves -> travels to valid pixel -> cleans/reveals pixel -> disappears`

Never reproduce Colony Flow assets or exact visual design.

## Expected visual categories are not proof of availability

Prior planning references these expected categories:

- original Scrubbot character concepts;
- gameplay-screen concepts;
- five-slot gameplay/layout concepts;
- original pixel-art level artwork;
- themed level artwork, including a previously discussed underwater SCRUBBOTS scene;
- original UI/effect concepts;
- pixel-construction-method reference screenshots;
- external movement-flow references such as Colony Flow, conceptually only.

These descriptions are intake expectations, not evidence that files exist locally. Do not regenerate missing artwork from descriptions and label it as original.

The repository also contains Akilta branding under `assets/brand/`. That is project/company attribution branding and must not be classified as SCRUBBOTS gameplay/reference artwork.

## In scope

### A. Repository visual-asset inspection

Inspect the repository for visual assets and classify what actually exists. At minimum inspect `assets/`, `assets/art/`, `assets/brand/`, relevant debug/reference scenes, and clearly named project visual/reference directories.

Do not roam the user's Desktop to ingest arbitrary images. Do not copy ambiguous files from outside the project. If identity or owner approval cannot be established from repository evidence or explicit owner instruction, treat the asset as unavailable or unverified.

### B. Visual reference directory structure

Establish a clean version-controlled structure consistent with the master plan:

- `assets/art/references/gameplay/`
- `assets/art/references/ui/`
- `assets/art/references/scrubbots/`
- `assets/art/references/pixel_method/`
- `assets/art/references/external_inspiration/`
- `assets/art/characters/scrubbots/`
- `assets/art/levels/source/easy/`
- `assets/art/levels/source/medium/`
- `assets/art/levels/source/hard/`
- `assets/art/levels/source/very_hard/`
- `assets/art/levels/previews/`

Use `.gitkeep` only where required to retain intentionally empty directories. Do not destructively move verified owner assets.

### C. Human-readable visual reference guide

Create the canonical guide at:

`assets/art/references/README.md`

It must define:

- visual authority hierarchy;
- source classes;
- owner-approval semantics;
- availability states;
- canonical asset IDs/naming;
- source-original preservation;
- allowed use of external inspiration;
- prohibition on fabricated original replacements;
- intake process for new owner assets;
- progression from reference to production candidate;
- M08 boundary for full technical pixel/dimension audit;
- relationship to the M10 DIRTY/CLEAN design gate.

### D. Machine-readable reference inventory

Create a simple dependency-free inventory/manifest under `assets/art/references/`, preferably JSON unless the repository clearly establishes another simple format.

The inventory must distinguish:

- physically existing verified assets;
- expected-but-missing owner assets;
- external inspiration references;
- project branding that is outside SCRUBBOTS gameplay/reference art.

Use stable logical asset IDs. Support, where applicable:

- stable ID;
- category;
- source class;
- approval status;
- availability status;
- repository path or null when missing;
- original filename when known;
- intended use;
- notes/provenance;
- optional width/height only when reliably known;
- optional candidate difficulty only when reliably known.

Do not invent unknown dimensions or difficulty metadata. Do not perform M08's full pixel-level audit here.

### E. Canonical naming and source preservation

Define predictable, cross-platform-safe IDs/naming. Preserving an owner original is more important than cosmetic renaming. A manifest ID may normalize identity while the source retains its original filename.

Owner originals must be preserved byte-for-byte once ingested. Future resized, converted, palette-derived, preview, or gameplay forms must be separate derived artifacts, never in-place overwrites.

### F. Approval and availability semantics

Define clear states equivalent to:

- owner-approved / canonical;
- owner-supplied but not production-approved;
- external inspiration only;
- awaiting owner asset;
- unverified / ambiguous.

### G. Missing-asset inventory

If expected owner assets are absent, explicitly record them as `AWAITING OWNER ASSET` or the established exact equivalent. At minimum account for:

- Scrubbot character visuals;
- gameplay-screen references;
- five-slot references;
- level artwork;
- underwater level artwork;
- other original theme artwork;
- pixel-construction reference screenshots.

Do not create fake placeholder images to make these entries look complete.

### H. External reference separation

Record external inspiration separately from original SCRUBBOTS art. Do not download new reference images during this cycle. A textual record of the established Colony Flow movement inspiration is acceptable only as provenance/context and must explicitly state that no copied asset is adopted as project art.

### I. DIRTY/CLEAN design-gate continuity

Do not choose a final DIRTY preset in this cycle. Preserve the existing A/B/C design gate.

The guide must preserve these rules:

- CLEAN settles to the original source palette color;
- DIRTY must remain recognizably related to the underlying hue while being clearly distinct using both saturation and brightness/value differences;
- final DIRTY treatment requires owner review at realistic 50x50 and 59x59 display scale;
- M07 work must not silently mark M10 complete.

## Out of scope

Do not begin:

- M08 full technical pixel-art audit;
- M09 importer/converter;
- image palette extraction;
- anti-aliasing or pixel-perfect round-trip implementation;
- production level conversion;
- source-image resizing/resampling;
- BoardRenderer redesign;
- final DIRTY/CLEAN preset selection;
- slots;
- target selection;
- routing;
- Scrubbot agents;
- gameplay completion rules;
- audio, effects, economy, or progression.

Do not generate new SCRUBBOTS artwork in this cycle.

## Task-status rules

`tasks.md` remains the only canonical task ledger:

https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md

Update only M07 items that are actually implemented and validated.

Infrastructure tasks such as directory structure, guide, separation rules, naming, metadata, owner-approval semantics, source-preservation policy, and missing-asset flagging may become complete if repository evidence supports them.

Asset-specific inventory tasks such as SB-M07-008 through SB-M07-014 must remain open when required owner files are absent. Preserve or improve their `AWAITING OWNER ASSET` notes.

Do not mark all of M07 complete merely because the library framework exists. If verified owner assets unexpectedly exist, inventory them truthfully but do not infer production approval from filenames alone.

## Documentation requirements

Update documentation only where this cycle creates new project truth. Inspect at minimum:

- tasks.md: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- CHANGELOG.md: https://github.com/Sekiph82/Scrubbots/blob/main/CHANGELOG.md
- Roadmap: https://github.com/Sekiph82/Scrubbots/blob/main/docs/04_ROADMAP.md
- relevant visual/reference sections in existing docs

Do not create an ADR unless an actual durable architecture decision warrants one. Do not rewrite unrelated docs.

## Validation requirements

Before changes, record baseline repository status and run the existing regression suite when practical.

Before completion run at minimum:

`godot --version`

`powershell -File tools\verify_project.ps1`

`godot --headless --path . --quit-after 5`

`godot --headless --path . -s res://tests/run_tests.gd`

`git diff --check`

`git status --short`

Record exact results in both the local M07 phase log and GitHub Claude implementation log. The previous known gameplay baseline is 227/227, but report the actual count observed in this session. Do not claim a pass that was not run.

This is primarily reference-library/documentation work. Do not invent GPU/FPS or unrelated performance measurements.

## Git requirements

Before modifying:

`git status`

`git fetch origin`

`git pull --ff-only origin main`

If local owner work prevents a safe fast-forward, preserve it and record the situation instead of destroying it.

Before commit:

`git status`

`git diff`

`git diff --check`

Ensure no Desktop phase log, secrets, cache, `.godot/`, generated build output, arbitrary Desktop images, or unverified external art is committed.

Use a focused commit such as:

`docs: establish Scrubbots visual reference library`

Push safely to `origin/main` according to the repository workflow. Never force-push.

## Coordination requirements before ending Claude work

1. Append evidence to the GitHub Claude implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md
2. Update task truth only when validated:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. Update the session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
4. Update the H!veAI Project Dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
5. Keep H!veAI single-dashboard-watch intact.
6. Set the cycle to `AWAITING_AUDIT` when implementation evidence is ready for ChatGPT review.
7. Use `BLOCKED` only when the cycle objective truly cannot continue without owner/external input.
8. Never set `AUDITED_PASS`; that status is reserved for ChatGPT audit.
9. Never edit V01 or this V02 after acting on them.

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
- missing owner asset categories are represented without fabrication;
- external movement inspiration is isolated with non-copying rules;
- the DIRTY/CLEAN owner design gate remains open;
- relevant M07 `tasks.md` items reflect validated truth;
- validation commands and actual results are recorded;
- local M07 phase log is current;
- GitHub Claude implementation log is current;
- session index and H!veAI dashboard are synchronized;
- commit/push evidence exists or a precise blocker is recorded.

M07 may truthfully remain PARTIAL / AWAITING OWNER ASSET after this cycle.

## Expected Claude final response

Return a concise report containing:

- Cycle: `M07-C001`
- Cycle state: `AWAITING_AUDIT` or `BLOCKED`
- implementation starting commit
- ending commit
- visual reference library status
- repository asset audit summary
- which M07 task IDs changed and why
- actual regression test result
- GitHub implementation log URL
- push status
- remaining owner-asset blockers
- `READY FOR CHATGPT AUDIT` when applicable

Then stop. Do not begin M08 or any later milestone.