---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: META-C002
version: 1
createdAt: 2026-09-05T12:38:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
---

# META-C002 Audit Criteria V01

ChatGPT will audit this cycle only after Claude returns it as `AWAITING_AUDIT`.

Pass requires all of the following:

1. Owner Desktop visuals were ingested copy-only from `C:\Users\sekip\Desktop\ScrubBots Gorselleri`; originals were not modified/deleted/overwritten.
2. Imported references were inventoried/classified and canonical Scrubby/gameplay/Home/popup references were selected or explicitly marked `OWNER_REQUIRED` where ambiguous.
3. Every policy/task in `docs/UI_TASKS_APPENDIX.md` was merged exactly once into canonical root `tasks.md` in coherent existing main-game milestone order, with no unrelated task/history loss. The global visual-production policy exists near the top of `tasks.md`.
4. Visual production is represented as part of the main SCRUBBOTS roadmap, not as a sidecar/parallel art project.
5. `docs/UI_TASKS_APPENDIX.md` was deleted only after verified migration.
6. Magnific-only development-time policy, no-Higgsfield rule, raw-vs-final lifecycle, owner approval, no dynamic text baking, and milestone-owned generation rules are preserved in tasks/docs/manifest.
7. `docs/MASTER_UI_SYSTEM.md`, `ASSET_GENERATION_MANIFEST.json`, `CLAUDE.md`, `docs/02_TECH_ARCHITECTURE.md`, `docs/05_TECH_DECISIONS.md`, `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`, and `project.godot` do not contain material contradictions about the approved UI/visual pipeline.
8. `project.godot` 1080x2160 + `canvas_items` + `expand` and the new UI foundation files were actually validated against current startup/regression behavior. Any editor/device-only gaps are explicitly recorded rather than claimed as passed.
9. The full current Godot 4.7.1 headless regression suite and standard parse/startup checks were run with exact commands/results recorded in `CLAUDE_LOG_V01.md`; no new regressions are hidden.
10. Existing BoardRenderer architecture and TargetSelector/Routing separation remain intact.
11. No broad/final Magnific generation was performed in this cycle.
12. Required coordination/H!veAI artifacts and PR #3 were updated truthfully, and the cycle ends `AWAITING_AUDIT` or `BLOCKED`, never self-assigned `AUDITED_PASS`.
