# SCRUBBOTS — Project Operating Manual for AI Agents

This file is the persistent operating manual for any Claude Code (or other AI
agent) session working in this repository. Read it fully before modifying
anything.

## 0. What SCRUBBOTS is

SCRUBBOTS is an original mobile puzzle game: a visible pixel-art image is
progressively cleared away by tiny cleaning robots ("Scrubbots") dispatched
from a limited set of color/robot slots. Cells start ACTIVE (source palette
color); a cleaned cell becomes CLEARED (transparent, background shows
through). See `docs/05_TECH_DECISIONS.md` ADR-019,
`docs/00_PROJECT_BRIEF.md` for the full pitch and
`docs/01_GAMEPLAY_SPEC.md` for locked gameplay rules.

## 1. Required reading order

1. This file (`CLAUDE.md`).
2. `docs/05_TECH_DECISIONS.md` — why the architecture looks the way it does.
3. Any `docs/` file relevant to the system you are about to touch
   (e.g. read `docs/03_LEVEL_DATA_SPEC.md` before touching level loading).
4. `docs/04_ROADMAP.md` to confirm you are working on the current milestone,
   not a future one.

## 2. Hard rules

1. Preserve established game rules unless the owner explicitly changes them.
2. Never invent major game mechanics. If a system is marked "TO BE DESIGNED"
   in `docs/01_GAMEPLAY_SPEC.md`, propose a design, do not silently ship one.
3. Never silently change an existing rule (grid size, slot count, win-streak
   reward mapping, etc.). If a change seems necessary, say so explicitly and
   explain why before doing it.
4. Work in small, testable milestones. Do not jump ahead in
   `docs/04_ROADMAP.md`.
5. Prefer simple, modular systems over clever ones. Avoid both a single
   giant manager script and dozens of empty abstraction layers.
6. Keep gameplay logic separate from presentation (rendering, animation, UI).
7. Keep level data separate from scene/script code — data lives in
   `data/levels/`, not hard-coded in scripts.
8. Avoid unnecessary dependencies. No paid plugins, paid SDKs, subscription
   services, or third-party frameworks unless the owner explicitly approves.
9. Prefer Godot 4.7 built-in systems over custom or external ones.
10. Target **Godot 4.7** APIs and syntax. Do not use Godot 3.x conventions.
11. Use **GDScript** by default. Do not introduce C# unless a future
    requirement absolutely demands it and the owner approves.
12. Keep mobile performance in mind from the start. Target stable 60 FPS on
    reasonable mobile hardware.
13. Never represent board artwork (any size — 1,600 cells at 40×40, 2,500 at
    50×50, etc.) as one heavyweight Node per cell. Use data-oriented storage
    (arrays/PackedArrays) and batched rendering. See
    `docs/02_TECH_ARCHITECTURE.md`.
14. Keep **target selection** (deciding WHAT cell a Scrubbot cleans) and
    **routing** (deciding HOW it visually travels there) as separate systems.
    Never merge `TargetSelector` and `RoutingSystem` into one script.
15. Validate modified systems before declaring work complete. Actually run
    what you can (headless Godot, GDScript parse checks) rather than
    asserting success from file existence alone.
16. Check Godot output for parse/runtime errors whenever the editor or
    headless binary is available.
17. Inspect `git diff` before every commit.
18. Never use destructive Git operations (`reset --hard`, `clean -fd`, force
    push) without explicit owner permission.
19. Update the relevant `docs/` file when architecture or game rules change.
    Documentation drift is a bug.
20. Keep commits focused and understandable — one logical change per commit.
21. Do not commit generated/cache files (`.godot/`, `.import/`, build output).
22. Do not download or generate placeholder assets merely to make a
    prototype look prettier. Programmer art / empty placeholders are fine.
23. When something about the current project state is unknown, inspect the
    code/project first. Do not guess.
24. Never destroy existing user work. If the working directory contains
    files you don't recognize, investigate before deleting or overwriting.
25. Prefer reversible actions. Stash or rename before removing anything you
    are not certain is disposable.
26. **Phase log workflow (supersedes the old per-prompt handoff log,
    starting with Phase M03).** One development *phase* (a `tasks.md`
    milestone such as `M03`, which may span multiple prompts/sessions) gets
    **one continuous** Desktop log:
    `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md`. Create it at the
    **start** of the phase's first prompt, before inspection or code
    changes. If it already exists, read it and keep updating the *same*
    file — never create a second log for the same phase (`_RETRY`, `_B`,
    etc.). Update it after every meaningful checkpoint (inspection,
    baseline tests, decisions, each implementation step, failures and how
    they were fixed, final tests, before/after commit, after push) so
    another agent can resume mid-phase if a session stops unexpectedly.
    Keep past failures in the log even after they're fixed — don't erase
    history. Only set `PHASE STATUS: COMPLETE` and write the Final Phase
    Summary when the phase is genuinely done, without deleting the earlier
    chronological journal. Start a new log only when moving to a new phase.
    **Never commit any phase log to the Scrubbots Git repository** — it
    lives only on the Desktop. (Prompts 01–02 and the master-plan prompt
    used one-log-per-prompt; those historical logs —
    `SCRUBBOTS_PROMPT_01_LOG.md`, `SCRUBBOTS_PROMPT_02_LOG.md`,
    `SCRUBBOTS_MASTER_TASKS_LOG.md` — are not retroactively converted.) Full
    detail: `tasks.md` "PHASE LOG WORKFLOW."
27. `tasks.md` (project root) is the master execution checklist for the
    entire project. Read it at the start of every session, alongside this
    file. Update it after every numbered implementation prompt.
28. Never mark a `tasks.md` item `[x]` without actual validation evidence
    (it ran, it passed, it was inspected) — code existing is not enough.
29. Never delete unfinished `tasks.md` items to make progress look cleaner.
    Leave them `[ ]` and, if abandoned, say so explicitly rather than
    silently removing the line.
30. Official production board difficulty/size bands (see `tasks.md` §8.3):
    Easy 20–29×20–29, Medium 30–39×30–39, Hard 40–49×40–49, Very Hard
    50–59×50–59. Maximum current production requirement is **59×59 = 3,481
    cells**. Boards are not required to be square — width and height are
    validated independently against the same band.
31. `TEST`/dev fixtures (e.g. the 3×2 generic-size fixture) may exist
    outside the production dimension bands and must never enter production
    content or the production level catalog.
32. Existing original SCRUBBOTS artwork, once it physically exists in this
    project, is the canonical visual reference and outranks any generic
    placeholder. Missing artwork must never be fabricated or presented as
    an original — mark it `AWAITING OWNER ASSET` instead. External game
    references (including Colony Flow) are conceptual inspiration only,
    never a source to copy characters/art/levels/UI/code from.
33. The ADR-009 explicit-`preload()` convention (over bare `class_name`) in
    `scripts/data/` and `scripts/gameplay/board/` must be preserved unless a
    future task deliberately revisits it and proves an alternative equally
    reliable under headless Godot.
34. `BoardRenderer` (`scripts/gameplay/board/board_renderer.gd`) draws the
    board as one `Image`/`ImageTexture` per board (ADR-011) — never one
    Node per cell, never per-cell draw calls. Under the owner-locked
    ACTIVE/CLEARED model (ADR-019, `docs/01_GAMEPLAY_SPEC.md`): an ACTIVE
    cell renders its exact original source palette color, opaque; a CLEARED
    cell renders fully transparent (`Color(0,0,0,0)`) so the gameplay
    background shows through — never a black/gray/palette substitute. There
    is no DIRTY/CLEAN/grime transform and no A/B/C preset. Owner manual QA of
    the transparent model (`tasks.md` SB-M10-005..011) via
    `scenes/debug/board_renderer_debug.tscn` remains an open gate.
35. Renderer output is read back through an 8-bit `Image`
    (`Image.FORMAT_RGBA8`) — comparing rendered pixels to an
    independently-computed float `Color` with `is_equal_approx()` will
    spuriously fail from quantization. Use a tolerant comparison (see
    `_colors_close()` in `tests/run_tests.gd`) or test meaningful HSV
    properties instead, per `docs/06_TEST_STRATEGY.md`.

## 3. Known-locked game parameters (do not silently alter)

- Puzzle grid: **variable-size**, defined per level (`width` × `height`,
  cell count = `width * height`, always derived, never hard-coded). Official
  production difficulty/size bands (see `tasks.md` §8.3 for the full table
  and examples): Easy 20–29×20–29, Medium 30–39×30–39, Hard 40–49×40–49,
  Very Hard 50–59×50–59 (max 59×59 = 3,481 cells). Boards need not be
  square — width and height are validated independently. Do not reintroduce
  a fixed board-size assumption anywhere in code or docs — this corrects a
  Prompt 01 documentation error refined further in the post-Prompt-02
  planning pass (see `docs/05_TECH_DECISIONS.md` ADR-008 and `tasks.md`).
- Robot/color slots: **5**.
- Win-streak reward mapping (consecutive wins → reward):
  `1→1, 2→5, 3→10, 4→25, 5+→100`.
- Cell lifecycle: cells start **ACTIVE** (source palette color, opaque,
  color candidate, blocks access); a cleaned cell becomes **CLEARED**
  (transparent alpha 0, background shows through, no longer a candidate,
  opens access). No DIRTY/CLEAN/grime/reveal model (ADR-019).
- Color candidate ≠ reachable target: a matching-color ACTIVE cell is only a
  raw candidate; it is a valid final target only if also reachable
  (non-target ACTIVE cells block access, CLEARED/background is open). A fully
  enclosed matching-color ACTIVE cell must not cause dispatch (AL-028).
- Scrubbots: leave their slot one at a time, only when a reachable matching
  target exists; travel to that target cell; clear it (ACTIVE→CLEARED); then
  disappear. They do not carry color and do not return to origin.

Full detail: `docs/01_GAMEPLAY_SPEC.md`.

## 4. Architecture boundaries

See `docs/02_TECH_ARCHITECTURE.md` for the full module list. The one boundary
that must never be violated without owner sign-off:

```
ColorCandidateIndex -> raw ACTIVE matching-color candidates (M13; no reachability)
Reachability/access -> filters blocked/unreachable candidates (future)
TargetSelector      -> decides WHAT target among reachable candidates
RoutingSystem       -> decides HOW a Scrubbot visually travels there
```

These stay separate scripts/modules so routing can be replaced later without
touching level data, slot logic, cell state, scoring, or rendering.

## 5. H!veAI dashboard contract

36. Before ending a run that materially changes project state, refresh
    `.hiveai/PROJECT_DASHBOARD.md` so it remains the single H!veAI-facing
    status contract.

## 6. Working style

- Inspect before modifying. Never assume file contents or environment state.
- Small, verifiable steps over large speculative rewrites.
- When a decision can be safely and reversibly inferred from the docs, make
  it and document it rather than stalling on a question the owner already
  answered in a spec doc.
- Only stop and ask when proceeding would risk destroying user work,
  exposing secrets, adding a paid dependency, or making an irreversible
  choice that contradicts the spec docs.

## 7. GitHub coordination protocol

The repository now has a versioned ChatGPT↔Claude communication layer under
`coordination/`. This **adds** durable GitHub handoff evidence; it does not
replace `tasks.md` or the local Desktop phase log.

37. Before any material implementation session, read in this order after
    reading this file: `tasks.md`, `.hiveai/PROJECT_DASHBOARD.md`,
    `coordination/README.md`, `coordination/SESSION_INDEX.md`, then every
    prompt/audit/owner-note artifact in the active coordination cycle in
    version order, followed by the relevant `docs/` sources.
38. Every scoped ChatGPT→Claude handoff has one stable coordination cycle ID
    such as `M07-C001`. Do not create a new cycle merely because Claude Code
    or chat restarted. Continue the same cycle until it reaches
    `AUDITED_PASS`, `BLOCKED`, `SUPERSEDED`, or an explicitly defined end.
39. ChatGPT prompt files (`CHATGPT_PROMPT_VNN.md`) and ChatGPT audit files
    (`CHATGPT_AUDIT_VNN.md`) are evidence artifacts. Claude must **never
    rewrite them** to make later implementation appear compliant. If an
    audit requires changes, wait for/read the next prompt version in the
    same cycle.
40. For every cycle with Claude implementation work, create or append to
    `coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md`. Keep it
    append-only across multiple Claude sessions. Record starting/ending
    commits, files, commands/tests, failures and fixes, performance evidence,
    prompt deviations, task/doc changes, push/PR state, blockers, and the
    handoff state. Do not erase failure history after fixing it.
41. The GitHub implementation log and Desktop phase log are both required
    and serve different purposes: the Desktop phase log is the detailed,
    crash-safe local phase journal; the GitHub implementation log is durable
    communication evidence for ChatGPT/H!veAI/owner review. Never commit the
    Desktop phase log.
42. Before ending any **material** Claude session, update both
    `coordination/SESSION_INDEX.md` and `.hiveai/PROJECT_DASHBOARD.md`.
    Dashboard updates must include timestamp, actor, cycle ID/status,
    milestone/task refs, concise summary, evidence, blocker/waiting state,
    and next expected actor/action. `tasks.md` remains the only canonical
    task ledger; never duplicate its checkbox list in the dashboard.
43. When implementation is ready for review, set the cycle state to
    `AWAITING_AUDIT`. Do not mark a cycle `AUDITED_PASS` yourself; that state
    is reserved for the ChatGPT audit step unless the owner explicitly
    changes the protocol.
44. Never commit secrets or sensitive environment values to coordination
    artifacts. Prompts/logs/audits may reference secret **names** or masked
    evidence when needed, never secret values.
45. Use templates under `coordination/templates/` when creating new prompt,
    audit, or implementation-log artifacts. If the template and a newer
    explicit owner instruction conflict, the owner instruction wins and the
    deviation should be recorded.

Full protocol: `coordination/README.md`.


## Nested sidecar projects: Level Factory and Content Pipeline

This repository contains two deliberately isolated sidecar systems:

- `level_factory/`: independently openable Godot project for offline level
  generation, solving, difficulty analysis, human review and QA.
- `content_pipeline/`: offline publisher/control-plane for pack/manifest,
  staging, production, rollback, disable and scheduling workflows.

Root `tasks.md` is the only canonical task ledger. Sidecars use
`SB-LFxx-xxx` and `SB-CPxx-xxx` task IDs.

The main game must never preload/import `level_factory/` scripts. Shipping
runtime never includes Factory/Publisher implementation. Remote content is
declarative data only.

### GitHub coordination rule for sidecars

Sidecar work uses the same evidence chain as the main project, but each
sidecar has its own `coordination/` subtree:

1. ChatGPT authors versioned `CHATGPT_PROMPT_VNN.md` and
   `CHATGPT_AUDIT_CRITERIA_VNN.md`.
2. Claude reads them from GitHub, implements/tests only, and appends to the
   cycle's single `CLAUDE_IMPLEMENTATION_LOG.md`.
3. Claude updates root `tasks.md`, the sidecar session index and root
   H!veAI dashboard, pushes safely, returns `AWAITING_AUDIT`, and stops.
4. Claude does not create audit/self-audit files or assign audit verdicts.
5. ChatGPT reads GitHub log + real diff/code/tests, publishes
   `CHATGPT_AUDIT_VNN.md`, and either closes the cycle or issues the next
   prompt version in the same cycle.


## Coordination v4 owner override — version-matched Claude logs [LOCKED]

This section supersedes older references in this file to a single
`CLAUDE_IMPLEMENTATION_LOG.md` per cycle.

For every material ChatGPT prompt version:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

The prompt version and Claude log version must match exactly. Work performed
under VNN is recorded in `CLAUDE_LOG_VNN.md` in the same cycle directory.
If V02 and V03 are intentionally delivered/executed together, Claude still
creates both logs and identifies shared commits/tests explicitly.

Historical `CLAUDE_IMPLEMENTATION_LOG.md` files are legacy evidence only.
Do not delete them, but do not use that naming pattern for new prompt work.

Before ending a material session, update these derived H!veAI sources:

- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`

Then materialize the latest state into
`.hiveai/PROJECT_DASHBOARD.md`. H!veAI actively watches only the dashboard.
`tasks.md` remains the only canonical task ledger.

Canonical policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md


## GitHub-only logging owner override [LOCKED, effective M12-C001]

This owner instruction supersedes every earlier Desktop/local phase-log rule
in this file.

Starting with M12-C001 and for every later main-game, Level Factory, and
Content Pipeline prompt:

1. The **first action** is to safely synchronize the local repository with
   `origin/main` while preserving all owner work.
2. Do not create, update, or rely on Desktop phase logs or any other local
   handoff log outside the repository.
3. All durable implementation/test/coordination evidence goes to GitHub in the
   active cycle's version-matched `CLAUDE_LOG_VNN.md`.
4. Local temporary files needed by tools are not evidence and must not be
   presented as handoff records.
5. Never use destructive sync operations (`reset --hard`, `clean -fd`,
   force push) without explicit owner permission.


## Master UI / visual generation owner override [LOCKED, 2026-09-05]

The owner has approved the SCRUBBOTS Master UI architecture and visual asset
pipeline. For UI/visual work, also read `docs/MASTER_UI_SYSTEM.md`,
`docs/07_UI_ASSET_PIPELINE_DECISIONS.md`, and
`ASSET_GENERATION_MANIFEST.json` before changing presentation code or art.

46. Production UI must be composed from responsive Godot `Control` scenes and
    containers. Full-screen AI/mockup images are art-direction references,
    not shippable interactive UI.
47. The reference portrait design viewport is **1080×2160**, using
    `canvas_items` stretch with `expand` aspect. UI remains resolution-
    independent and safe-area aware.
48. The gameplay board is the dominant visual region. Preserve the existing
    single-`Image`/`ImageTexture` `BoardRenderer`; never replace it with one
    node/control per logical cell.
49. Five visible slots and the color-selection panel must remain usable across
    target phone sizes. Decorative character/prop art yields space before
    gameplay controls do.
50. The approved gameplay composition removes the Goal/Moves panel, places
    Scrubby low at the left of the color-selection region with the speech
    bubble above Scrubby, keeps cleaning props on the right, places boosters
    in a compact horizontal row below, pause left of the bottom/ad row, and
    settings right of it.
51. **Magnific MCP is the only approved AI image-generation provider for the
    Master UI Asset Kit unless the owner explicitly changes this rule.** Do
    not add Higgsfield as a required dependency or subscription.
52. Prefer Godot-native styles/components for panels, buttons, text,
    progress bars, slots, color tiles, counters, popup bodies and layout.
    Use Magnific primarily for character, booster, reward, difficulty and
    decorative illustration assets.
53. Never silently regenerate or overwrite an owner-approved asset. Raw
    generated files and approved production-final assets must remain
    separate.
54. The owner-confirmed local visual-reference source is
    `C:\Users\sekip\Desktop\ScrubBots Gorselleri`. Use
    `tools/import_desktop_visual_refs.ps1` locally to copy these references
    into `assets/art/references/_owner_inbox/`; never move/delete the Desktop
    originals. Inbox files are references until inventoried/classified and
    explicitly promoted.
55. `ASSET_GENERATION_MANIFEST.json` is the machine-readable generation queue.
    Do not generate assets whose status/reference prerequisites are not met.


## Non-self-referential final SHA rule [LOCKED]

Do not repeatedly commit a Claude log merely to make it contain the SHA of the
commit that contains itself.

The versioned log records pre-commit evidence. After push, when exact final
SHA evidence is required, use the prompt-specified external GitHub receipt
(PR comment for PR cycles) and do not create another commit after the receipt.


## Preserve pre-existing tracked local work [LOCKED]

A pre-existing tracked modification or deletion in the owner's working tree is
owner/local work until explicitly proven otherwise.

Do not use `git restore`, checkout-from-origin, reset, clean, or equivalent
commands merely to make the tree clean before a task.

Record and preserve such changes. Do not stage them unless the active prompt
explicitly owns them. If they prevent safe synchronization or implementation,
fail closed as `BLOCKED` rather than overwriting owner intent.
