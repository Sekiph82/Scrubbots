# Review round 1, 100-ci-red-fixes

Checks: git diff --check clean. Ran m44_ftue (23/23 PASS), sb_polish_003_booster_vfx (PASS), m42_c003_scrubby_animation (25/25, 0 failures). project.godot restored. m55 not run; its threshold is untouched (no tests/m55 file in the diff).

1. t21 (m44_ftue): not a weakening. opening_screen.gd still must contain no "skip" in code (comments stripped by _code_only, only the token skip_logo removed), and skip_logo() must call _player.play(), so a tap can only end the logo splash and then starts the video. The actual source matches (skip_logo plays the video; _gui_input only skips during logo). A real skip of the cinematic would add a new "skip" token or drop play() and fail. Minor: slice by "func skip_logo()" would yield "" if renamed, which fails the play() check, so it fails closed.
2. booster_vfx: is_instance_valid first is the correct fix (a freed Object fails `is CanvasItem` with a script error). Both sites fixed; new _freed_view test frees the view then ticks and stops.
3. home_scrubby_hero visibility hook: safe. _init builds _gesture_rect and _idle_mat, so step(0.0) is valid even before binding. step() with is_visible_in_tree()==false takes the inert branch: _end_gesture() stops and releases the stream, _was_open=false, so the next shown step takes the "open and not _was_open" path and draws a fresh 6..12 s wait (new test checks this). Parent visibility changes propagate the notification to this node, so is_visible_in_tree is the right test. Visibility notifications do not fire on tree exit or free, and _exit_tree is untouched. step(0.0) is idempotent, so repeat notifications are harmless.

No must-fix items.

VERDICT: PASS
