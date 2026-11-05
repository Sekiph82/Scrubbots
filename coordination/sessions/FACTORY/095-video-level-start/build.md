STATUS: READY

# Build: SB-VIDEO-005 Level start "ready" Scrubby video (Level Intro overlay)

## Summary
Every gameplay start launched by the app root (Home PLAY, Results Continue, Results Retry) gets a
short Level Intro overlay on top of the gameplay host: dim scrim, "LEVEL N" (FONT_HERO), the owner's
keyed Scrubby "ready" Flow video centred (one VideoStreamPlayer, magenta key via the 093
chroma_key_magenta.gdshader). The video plays once, then the overlay fades (0.25 s) and frees itself
and its decoder. Any tap skips at once and is consumed. Reduced Effects or a video that fails to start:
no decoder, the keyed still with CharacterMotion `ready` bounce for 0.8 s, then the fade. Not shown
while an FTUE coachmark is up (first-time L1-L3). Presentation only.

Commits on factory/095-video-level-start:
- 44b2a788 ui/gameplay: Level Intro overlay ... tests + capture
- 2b224c1e docs/tasks: SB-VIDEO-005 done (44b2a788)

Files:
- scripts/ui/level_intro_overlay.gd (new)
- scripts/app/main.gd (boot_level_intro_override seam, level_intro_enabled, _show_level_intro on PLAY / Continue / Retry)
- scripts/ui/ui_text.gd (LEVEL_INTRO key)
- tools/build_result_scrubby_videos.py (extended: `results` (default, unchanged output) and `level_start` sets)
- assets/ui/final/gameplay/videos/ (level_start_scrubby.ogv + keyed still + PROVENANCE.md)
- tests/sb_video_005_level_intro.gd (new), tests/tools/level_intro_capture.gd (new)
- TASKS.md (SB-VIDEO-005 queue + checklist lines)

## Acceptance criteria (spec-less; from the job prompt)
1. [x] Asset built like 093 from level_start_scrubby_short_master.mp4 (crop to robot bbox, Theora .ogv, keyed frame-0 still, PROVENANCE.md), extending the 093 tool: `python tools/build_result_scrubby_videos.py <flow_videos> level_start` -> crop 624x640 @ (13,317), 84 frames. Re-running the default `results` set gave byte-identical sizes and identical PROVENANCE text except the .ogv sha (Ogg stream serial), so the refactor preserves 093 output (those regenerated files were restored, not committed).
2. [x] Overlay on level start with dim scrim, keyed video centred, "LEVEL N": sb_video_005 cases video_level_label, app_play_retry (label equals host.progression_level); still factory/jobs/095-video-level-start/evidence/level_intro_0_1080x2160.png (real app root, L1, video playing over the dimmed board; dim verified by pixel compare, background 0.4x brightness with the overlay vs without).
3. [x] Plays once, fades ~0.25 s, frees itself and decoder: case finish_frees (overlay gone ~1.0 s at 8x time scale).
4. [x] Any tap skips immediately and is consumed; board input blocked only while the overlay exists: case tap_skips_consumed (SubViewport push_input: press closes + frees decoder, press+release never reach a Control underneath (0 hits), overlay freed after fade, then taps reach it again (2 hits)).
5. [x] Reduced Effects: no video, keyed still + CharacterMotion `ready` bounce ~0.8 s, then fade: case reduced_still (no VideoStreamPlayer).
6. [x] Video fails to start = Reduced path: case no_video_fallback (video = null and an unplayable VideoStreamTheora both -> no decoder, still + bounce).
7. [x] Not over a tutorial overlay: case app_not_over_coachmark (fresh profile, FTUE on, L1 coachmark showing -> no intro). Rule is dynamic (`coachmarks.is_showing()` right after the GAMEPLAY route change), so first-time L1-L3 lessons skip it; later replays show it.
8. [x] Retry shows it again: case app_play_retry (LOST -> retry_from_results -> new LevelIntro on the same host).
9. [x] No change to gameplay logic, timers, economy, saves or level data: only main.gd presentation wiring + new overlay; retry_from_results return value unchanged.
10. [x] Existing suites unaffected: boot_level_intro_override (-1 auto = ON only for the canonical save path, like boot_ftue_override); case app_off_for_test_save; m42_navigation and m43_c001a pass.

## Validation
Godot 4.7.2 console, `--headless --path <wt> --import` once (project.godot rewrite restored).
- sb_video_005_level_intro: LOCAL_PASS, exit 0, 8/8 cases, no SCRIPT ERROR / Parse Error (the one engine `ERROR: Cannot open file 'res://tests/__missing_video__.ogv'` is the intended unplayable-video case, same as 093).
- m42_navigation (main-based PLAY / Results / Retry): LOCAL_PASS, exit 0.
- m43_c001a_results_foundation: LOCAL_PASS 11/11, exit 0.
- m44_ftue: 1 FAIL "opening cinematic has no skip path" - pre-existing on base: it greps scripts/app/opening_screen.gd for "skip", which HEAD already contains (881a6c66 Akilta logo skip); file untouched here.
- Capture: `godot --path . --rendering-driver opengl3 -s res://tests/tools/level_intro_capture.gd -- <evidence>` -> level_intro_0/1_1080x2160.png (video playing at both).
- `git diff --cached --check` clean. No CI run, no phone build.

## Log
### Round 1
Built the asset, overlay, wiring, test and capture. Judgement calls:
- Hooked in the app root (main.gd) after each accepted GAMEPLAY start rather than inside ProductionGameplayHost, so host-level gameplay suites never see it; auto-off for injected save paths mirrors boot_ftue_override.
- Tutorial rule implemented as "skip while a coachmark is showing" (covers first-time L1-L3 lessons) instead of a hard "skip L1".
- Reduced Effects still runs the small `ready` bounce (CharacterMotion.play with reduced=false) because the job asked for it explicitly, although CharacterMotion's own convention is Reduced = static.
- Overlay sits as the host's last child (below the app ModalStack and the coachmark CanvasLayer).
- New suite not added to the CI workflow list (sb_polish_011 isn't either; the workflow has exact-count guards).
- Worktree still holds Godot import churn (.import / .uid) from the import run; deliberately not committed or deleted.
