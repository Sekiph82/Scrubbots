---
hiveaiDashboardSchema: hiveai-project-dashboard/v1
projectKey: scrubbots
repository: Sekiph82/Scrubbots
branchPolicy: main
dashboardMode: source-map
refreshPolicy: watcher-driven source invalidation; no generated status commits
---

# H!veAI Project Dashboard Manifest

This file is a pointer map for H!veAI. It is not a task ledger and must not duplicate task checkboxes.

## Project identity

Project: Scrubbots
Repository: `Sekiph82/Scrubbots`
Default branch: `main`

## Source authorities

Canonical task source: `tasks.md`
Handoff source: none verified
Roadmap source: task/phase planning currently lives inside `tasks.md`
Progress/history source: `CHANGELOG.md`
Architecture source: none verified at repository root
Decision source: none verified
Agent instruction source: `CLAUDE.md`
Security source: none verified
Build/test metadata: `project.godot`, `tests/`, project scripts and tools

## Authority notes

Keep the existing lowercase `tasks.md` filename. Filename casing is project truth and should not be changed merely for style.

`tasks.md` is the canonical task ledger. `CHANGELOG.md` is historical execution evidence and must not override task state.

If a dedicated handoff or architecture ledger is added later, this manifest should be updated to point to it rather than duplicating its contents here.

## Refresh model

H!veAI should derive live state from Registry/Git/watcher evidence plus the canonical sources above. This manifest should remain pointer-only and should not be rewritten as a generated status snapshot.
