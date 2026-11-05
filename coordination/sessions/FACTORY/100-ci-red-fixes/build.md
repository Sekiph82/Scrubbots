STATUS: READY

# Build: CI red fixes (validation run 42074308049)

## Summary
Fixes the 3 suites that turned CI validation red after the last green run 41192324690 (job 080), each at its root cause. No thresholds changed.

1. m44_ftue t21: the guard banned any "skip" in opening_screen.gd. It protected M42's rule that the opening cinematic can't be skipped. SB-POLISH-008 (881a6c66) added a tap that only ends the 1.5 s Akilta logo splash, and `skip_logo()` then starts the video. t21 now allows only `skip_logo` (comments stripped) and requires `skip_logo()` to call `_player.play()`. Any other skip path in the file still fails.
2. m28 "Left operand of 'is' is a previously freed instance" (booster_vfx.gd:122, plus the same pattern in stop()): `view is CanvasItem and is_instance_valid(view)` ran `is` on a fade_in slot view that had already been freed. The order is now `is_instance_valid(view) and view is CanvasItem` in `_process` and `stop`. The VFX behaviour is unchanged.
3. m55 transition static-memory drift of 7888520 B against a 4 MiB limit. This was a real presentation bug, not an intended asset. In each of the test's 40 transition cycles, Home goes to Gameplay and back to Home within one frame. Home's `visible` flips false and then true before `HomeScrubbyHero._process` runs, so `step()` never saw Home hidden. The 5-6 s video hold therefore carried over and kept counting down across cycles. Around cycle 32 it started a Home Flow video, and the live Theora decoder (about 10.5 MB, +4 Objects) was present at the cycle-40 sample. A diagnostic loop printing per-cycle static memory showed a +10519799 B jump at cycle 32 before the fix and no jump after. The fix: on NOTIFICATION_VISIBILITY_CHANGED, when the hero is hidden, it runs its existing hidden path (`step(0.0)`). That ends the gesture, releases the stream and re-arms the resume hold. This matches the hero's documented rule: "resume: fresh hold, no catch-up". Drift is now 502808 B (the old green run had 256728 B). An oscillating 3134087 B / 4-object step remains in the diagnostic. It goes up and down in both the old and new runs and never accumulates; I did not investigate it further.

Files changed:
- scripts/ui/feel/booster_vfx.gd
- scripts/ui/home/home_scrubby_hero.gd
- tests/m44_ftue.gd (t21)
- tests/sb_polish_003_booster_vfx.gd (new `_freed_view` regression)
- tests/m42_c003_scrubby_animation.gd (video_gates: hidden for less than a frame stops the video and re-arms the hold)
- TASKS.md (Autonomous Queue DONE row SB-CI-RED-2026-11-05)

Commits: ff47b649 (fixes + tests), ca62bfb2 (TASKS.md).

## Acceptance criteria
1. [x] m44_ftue t21 matches intended behaviour and still guards the non-skippable cinematic: `m44_ftue exit=0 diag=0 | M44 FTUE evidence: PASS (23/23 cases, 0 fail)`.
2. [x] booster_vfx.gd can't access a freed instance; VFX behaviour kept: `m28_c002_c001_gameplay_v02 exit=0 diag=0 | PASS (14/14 cases, 0 fail)`; `sb_polish_003_booster_vfx exit=0 diag=0 | SB-POLISH-003 BOOSTER VFX: PASS` including "ok: freed fade-in view: the effect ticks and stops without touching it". Negative check: with the pre-fix booster_vfx.gd the new case gives `exit=1 diag=2`, `FAIL: freed fade-in view...` (the same SCRIPT ERROR as CI).
3. [x] m55 static drift is fixed at the cause and the threshold is untouched: `m55_long_session exit=0 diag=0 | M55 LONG SESSION: PASS`, "ok: static memory drift 502808 B <= 4194304 B". Before the fix it failed locally with exactly 7888520 B, the same as CI. The new m42_c003 check fails on the pre-fix hero (`FAIL: hidden for under a frame: video stopped, still`) and passes after the fix.
4. [x] TASKS.md queue row `- DONE SB-CI-RED-2026-11-05 — ...` added above the top DONE rows.

## Validation
All runs are local, headless, Godot 4.7.2 (LOCAL_PASS):
- m44_ftue: PASS 23/23, exit 0, no SCRIPT ERROR
- m28_c002_c001_gameplay_v02: PASS 14/14, exit 0, 0 SCRIPT ERROR
- m55_long_session: PASS, exit 0
- sb_polish_003_booster_vfx: PASS, exit 0
- m42_c003_scrubby_animation: 25/25 cases, 0 failures, exit 0 (suite for home_scrubby_hero.gd)
- m42_opening: PASS, exit 0 (suite for opening_screen.gd behaviour)
- m43_c005f_phase1_foundation: PASS 23/23, exit 0. Its 2 SCRIPT ERROR lines are the suite's own labelled EXPECTED_FAULT_INJECTION, which CI excludes.
- m43_master_c005f_feel: PASS 10/10, exit 0
- `git diff --check` on the changed scripts/tests: clean.
- Not pushed; CI not run (as instructed).

Tree note: the worktree still holds uncommitted Godot `--import` artefacts: modified *.import files, plus untracked *.uid, *.import and docs/*.translation files. My cleanup command (`git checkout -- '*.import'` + `git clean -- '*.uid' '*.import'`) was denied by permissions, so they remain. None are committed, and project.godot is unchanged.

## Log
### Round 1
- Read the CI failures and downloaded the validation-log artifacts for run 42074308049 and for the last green run 41192324690 to compare m55 samples.
- t21: relaxed the check only for the logo-splash `skip_logo` path, and required it to start the video.
- BoosterVfx: moved the is_instance_valid check ahead of `is` in both places; added a regression case that frees the fade_in view mid-effect.
- m55: reproduced locally (7888520 B). A per-cycle static-memory diagnostic located a 10.5 MB step at cycle about 32, traced to the Home hero video hold carrying over across within-one-frame hide/show. Fixed in HomeScrubbyHero with a visibility notification and added an m42_c003 regression. Confirmed both new checks fail on the pre-fix code.
