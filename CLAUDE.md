# SCRUBBOTS — Project Operating Manual for AI Agents

This file is the persistent operating manual for any Claude Code (or other AI
agent) session working in this repository. Read it fully before modifying
anything.

## 0. What SCRUBBOTS is

SCRUBBOTS is an original mobile puzzle game: pixel-art images are revealed by
tiny cleaning robots ("Scrubbots") dispatched from a limited set of
color/robot slots. See `docs/00_PROJECT_BRIEF.md` for the full pitch and
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
13. Never represent the 40×40 artwork (1,600 cells) as 1,600 heavyweight
    Node objects. Use data-oriented storage (arrays/PackedArrays) and batched
    rendering. See `docs/02_TECH_ARCHITECTURE.md`.
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

## 3. Known-locked game parameters (do not silently alter)

- Puzzle grid: **40 × 40** logical cells (1,600 total).
- Robot/color slots: **5**.
- Win-streak reward mapping (consecutive wins → reward):
  `1→1, 2→5, 3→10, 4→25, 5+→100`.
- Scrubbots: leave their slot one at a time, only when valid work exists for
  them; travel to a target cell; clean/reveal it; then disappear. They do not
  carry color and do not return to origin.

Full detail: `docs/01_GAMEPLAY_SPEC.md`.

## 4. Architecture boundaries

See `docs/02_TECH_ARCHITECTURE.md` for the full module list. The one boundary
that must never be violated without owner sign-off:

```
TargetSelector   -> decides WHAT cell to clean
RoutingSystem    -> decides HOW a Scrubbot visually travels there
```

These stay separate scripts/modules so routing can be replaced later without
touching level data, slot logic, cell state, scoring, or rendering.

## 5. Working style

- Inspect before modifying. Never assume file contents or environment state.
- Small, verifiable steps over large speculative rewrites.
- When a decision can be safely and reversibly inferred from the docs, make
  it and document it rather than stalling on a question the owner already
  answered in a spec doc.
- Only stop and ask when proceeding would risk destroying user work,
  exposing secrets, adding a paid dependency, or making an irreversible
  choice that contradicts the spec docs.
