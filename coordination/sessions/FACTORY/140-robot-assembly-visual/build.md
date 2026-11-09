STATUS: READY

# Build: SB-M44-027 robot 5-stage assembly visual

## Summary
The Robots screen already showed partial progress ("Bot Parts N / 250 toward X"), so the assembly visual extends that PartsRow instead of adding a parallel widget. It adds an `Assembly` VBox holding:
- `AssemblyArt`: the next locked robot's existing portrait (`RobotRoster.asset(next, "portrait")`, no new art) with one inline canvas_item shader. A single `reveal` uniform sets stage/5, and rows above `1 - reveal` stay a dark grey silhouette, so the robot builds bottom-up (wheels first, head last, as in the owner text).
- `AssemblyStage`: a label reading "Assembly N / 5" (EN), "Montaj N / 5" (TR).

`RobotsScreen.assembly_stage(parts, cost) = clampi(parts * 5 / cost, 0, 5)` gives 50/100/150/200/250 -> 1..5, and overflow stays at 5. `refresh()` feeds the widget from `e.robots.next_robot_progress()` (the Bot Parts wallet via RobotUnlockService) and hides it once every robot is unlocked. Nothing is written to the economy: no per-part inventory, no new currency, no per-part nodes. The Robots L25 gate and the non-binding target levels are unchanged.

Files changed:
- scripts/ui/robots/robots_screen.gd
- scripts/ui/ui_text.gd, scripts/ui/ui_text_tr.gd (ROBOTS_ASSEMBLY)
- tests/m44_robot_assembly_stages.gd (new)
- .github/workflows/android-family-first10.yml (append-only: header note, suite added to the validate loop, exact `PASS (4/4 cases, 0 fail)` grep guard)
- TASKS.md (SB-M44-027 queue row and checklist row set to DONE factory 140)

Commits: 7c5e2dd4 (code, test, CI), 96f773b0 (TASKS.md).

## Acceptance criteria
1. [x] 5 stages at 50/100/150/200/250 toward the next 250-part robot: test a01 checks 0->0, 49->0, 50->1, 99->1, 100->2, 149->2, 150->3, 200->4, 249->4, 250->5, overflow 251/400/10000->5.
2. [x] Visual fed from the Bot Parts service: test a02 runs on the real main.tscn app. It credits the wallet to 49/50/149/250/400, calls refresh, and checks that `next_robot_progress().parts` matches, the stage label is right, and the shader `reveal` equals stage/5. Test a03 checks the art is Moppy's portrait, that after a facade unlock it follows the next locked robot (the 50 carried-over parts give stage 1), and that the widget is hidden when all 10 robots are unlocked.
3. [x] Visual only, economy not mutated from UI: test a04 checks parts and robots snapshot are unchanged after open + refresh, and a source guard confirms robots_screen.gd has no `.credit(` or `.debit(`.
4. [x] No new art and a cheap draw: it reuses the existing portrait, with one TextureRect plus one ShaderMaterial and no per-part nodes.
5. [x] Extends the existing partial-progress UI (PartsRow) rather than adding a parallel widget.

## Validation
All runs are LOCAL_PASS on Godot 4.7.2 headless (`--import` run once, then project.godot restored). Every suite exited 0 with 0 SCRIPT ERROR / Parse Error:
- tests/m44_robot_assembly_stages.gd: `M44 robot assembly stages evidence: PASS (4/4 cases, 0 fail)`
- tests/m43_master_c008_robots.gd: `PASS (10/10 cases, 0 fail)`
- tests/m51_localization_readiness.gd: PASS 8/8 (run because of the new text key)
- tests/m50_accessibility_audit.gd: PASS 11/11

Other checks:
- `git diff --check` was clean.
- The workflow YAML parses (python yaml.safe_load).
- Import churn (modified .import files plus untracked .uid/.import/.translation files) was reverted or removed, and the worktree is clean.

This was not run in CI, and there was no phone build.

## Log
### Round 1
First build. I extended the Robots PartsRow with the shader-revealed next-robot portrait and the stage label, added the new suite to CI validate with an exact 4/4 guard, and closed out TASKS.md. One fix to my own test along the way: after unlocking Moppy with 300 parts, the 50 carried-over parts correctly show stage 1, so I corrected the expectation from 0 to 1.
