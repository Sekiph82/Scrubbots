STATUS: READY

# Build: SB-DEV-GODOT-001 verify-close

## Spec (light path)
Queue row: "verify-close: owner F5 given (§0D.1); confirm main opens and plays via F5 path in Godot 4.7.2, record result, tick".
Acceptance:
1. The production main scene (`run/main_scene="res://scenes/app/main.tscn"`) boots to Home in Godot 4.7.2 with no SCRIPT ERROR / Parse Error.
2. A real campaign level can be started from Home and played.
3. The owner's real save (`user://scrubbots_save.dat`) is never used; a throw-away save override is used and cleaned up.
4. TASKS.md item ticked with a 2026-10-22 evidence note and its queue row set to DONE. Only TASKS.md changes; `git diff --check` clean.

## Summary
Verification only; no source changes. Commit `1fd4dbdf` on `factory/014-dev-godot-001` changes only `TASKS.md`: line 13 queue row READY -> DONE, line 157 item `- [ ]` -> `- [x]` with an evidence note. Tested source: `f7f23060`.

## Acceptance criteria
1. [x] Main boots to Home: `$GODOT --version` = `4.7.2.stable.official.ed1daf0bf`. `"$GODOT" --headless --path <worktree> -s res://tests/m42_navigation.gd` exits 0 and prints `ok: real main.tscn root owns the navigation authority, at HOME` and `M42 navigation evidence: PASS` (12/12 cases). `m42_opening.gd` (headless) exits 0, prints `ok: opening released, normal Home shown` / `ok: completion -> Home` / `M42 opening evidence: PASS`. `m42_home.gd` exits 0, `M42 home evidence: PASS`. All logs: 0 `SCRIPT ERROR` / `Parse Error`.
2. [x] Level played: m42_navigation instantiates the real `main.tscn`, calls `play_current_frontier()` (Home Play path), and the real level 1 GameplayHost reaches WON: `ok: real gameplay reached WON`, `ok: minimal payload { "status": "WON", "level": 1, "attempt": 1 }`, `ok: Results visible: WON / CLEAN NEXT`. Also covers the double-tap Play, retry, back and no-orphan host cases. `m44_ftue.gd`: exit 0, `M44 FTUE evidence: PASS (23/23 cases, 0 fail)`.
   A windowed run (no `--headless`; OpenGL 3.3 Compatibility, Intel Iris Xe, like F5) of m42_navigation also reached real WON with 0 script errors. It exits 1 on 2 asserts (`real main.tscn root owns the navigation authority, at HOME`, `main Settings opens via nav overlay`), and the windowed m42_opening exits 1 on `auto policy in a headless run (no display) boots straight to Home`. These asserts only hold headless: when a display exists, the auto boot policy (`boot_opening_override = -1`) plays the opening cinematic before Home, as F5 does. The same windowed run shows `opening released, normal Home shown` / `completion -> Home`. The CI suites run headless, so this is expected and not a product defect.
3. [x] Save safety: every suite sets `MainScript.boot_save_path_override` to `user://m42nav_<tag>_<usec>.save` (or similar) and deletes those files afterwards. After all runs, no `m42*` files remain in `%APPDATA%\Godot\app_userdata\SCRUBBOTS`. `scrubbots_save.dat` mtime is still `2026-10-22 11:55:46` (before the runs at ~16:36). I never launched `main.tscn` directly as the main scene.
4. [x] TASKS.md: line 13 `- DONE SB-DEV-GODOT-001 — verify-close 2026-10-22: ...`, line 157 `- [x] **SB-DEV-GODOT-001 ...` plus the VERIFY-CLOSE note (factory verify-close, commands, results, owner F5 acceptance per CLAUDE.md §0D.1, LOCAL_PASS). `git diff --check` clean. LF endings of both lines are preserved (the file has mixed endings). `git diff --stat`: 1 file, 2+/2-.

## Validation
- m42_navigation (headless): exit 0, PASS
- m42_opening (headless): exit 0, PASS
- m42_home (headless): exit 0, PASS
- m44_ftue (headless): exit 0, PASS 23/23
- m42_navigation and m42_opening windowed: real WON / opening -> Home reached; headless-only asserts fail as explained above (informational, not a CI configuration)
- `git diff --check`: clean

Note: `git status --porcelain` lists untracked `addons/game_feel_flow/**.uid` / `.import` files. The Godot import created them before this job started, and the owner's main checkout has the same set. I didn't create them and left them alone.

## Log
### Round 1
Checked the branch. Read the TASKS item (line 157), the queue row and the playable-sync V01 acceptance. Found the existing suites that boot the real main.tscn under the save override (m42_navigation, m42_opening, m42_home, m44_ftue). Ran them headless, plus m42_navigation and m42_opening windowed for the F5 display path. Confirmed the owner save was untouched. Ticked the item and set the queue row to DONE in commit 1fd4dbdf.
