# Changelog

## Unreleased

### Added — Project foundation (M0)

- Connected local project directory to `origin/main` at
  `https://github.com/Sekiph82/Scrubbots.git` (cloned existing remote
  history rather than re-initializing).
- Godot 4.7 project shell (`project.godot`), portrait mobile baseline
  (1080×1920, `canvas_items` stretch, `keep` aspect).
- Full directory structure for assets, data, scenes, scripts, docs, tests,
  tools per the agreed module layout.
- `CLAUDE.md` — persistent operating manual for future AI agent sessions.
- Source-of-truth documentation set under `docs/`: project brief, gameplay
  spec (including the locked win-streak reward mapping), tech architecture,
  level data spec (v1 proposal), roadmap, tech decisions (ADR), test
  strategy.
- Minimal bootstrap scene (`scenes/app/main.tscn` + `scripts/app/main.gd`)
  displaying project/version confirmation only — no gameplay.
- `.gitignore` for Godot-generated/cache content.
- `tools/verify_project.ps1` and `tools/run_headless.ps1` PowerShell helpers.

No gameplay systems (board, level loading, slots, Scrubbot dispatch,
targeting, routing) are implemented yet — out of scope for this milestone.
