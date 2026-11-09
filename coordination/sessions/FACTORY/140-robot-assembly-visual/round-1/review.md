# Review 140-robot-assembly-visual (SB-M44-027), round 1

Checks:
- git diff --check: clean
- m44_robot_assembly_stages: PASS 4/4
- m43_master_c008_robots: PASS 10/10
- m51_localization_readiness: PASS 8/8
- m60_release_gates: PASS 6/6 (docs/RELEASE_GATES.json equals the computed verdicts; the new UiText key did not break it, no `-- --write` needed)

Findings:
- assembly_stage = clampi(parts*5/cost, 0, 5): 50/100/150/200/250 -> 1..5, overflow stays 5. Correct.
- Shader: UV.y=0 is the top; rows with UV.y < 1-reveal go dark, so the robot reveals bottom-up (reveal 0 = fully dark). Correct.
- The widget is hidden when no locked robot remains (tested). Fed from next_robot_progress; no wallet writes (source guard in the test).
- TR/EN key ROBOTS_ASSEMBLY exists in both ui_text.gd and ui_text_tr.gd.
- CI: append-only (header note, suite appended to the loop, exact -qxF 4/4 guard before aggregate). Fine.
- TASKS rows: queue row and checklist row are both DONE and consistent.
- One ShaderMaterial and one TextureRect, no per-part nodes, no new art. The Robots L25 gate is untouched.

Must-fix: none.

VERDICT: PASS
