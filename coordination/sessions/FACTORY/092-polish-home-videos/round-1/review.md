VERDICT: CHANGES

## Checks
- git diff --check origin/main...HEAD: pass
- godot --import, then tests/m42_c003_scrubby_animation.gd: pass (25/25 cases, 0 failures; the ERROR lines come from the deliberate missing.ogv case)

## Findings
1. scripts/ui/home/home_scrubby_hero.gd:230 and :254-258. A failed play retries on every frame. In step(), `_wait` is already <= 0 when start_gesture() fails and `_end_gesture()` does not reset it. The next tick calls start_gesture again, which means a fresh stream assignment and play() every frame at 60 fps. In the test this is exactly "30 s of failed attempts". On a device where a clip is unplayable that is per-frame decoder open/close churn and log spam, and the intended "failed play keeps the still" never settles. Fix: in the failure branch of start_gesture, or in step() when start_gesture returns false, set `_wait = _next_interval()`. Tighten the failure test to assert the number of play attempts, for example at most 6 in 30 s, instead of only "nothing counted".

## Notes
- Lifecycle gates are sound. Hidden, modal, focus-out, paused and Reduced Effects all go through `_end_gesture()`, which stops the player, nulls the stream and hides the player. There is only one VideoStreamPlayer, and the 9 s watchdog covers a missing `finished` signal. The frame fallback is intact and still used when no video set binds.
- Manifest provenance is honest: the shas are pinned, `ships` is true, the masters are not committed and that is stated, and the validator enforces the pins.
- A modal opening mid-clip cuts the video abruptly back to the still. That is acceptable.
