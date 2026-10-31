STATUS: READY

# Build: SB-POLISH-008 Akilta logo step in the boot sequence

## Acceptance criteria (written by the builder, no spec-writer)
1. Boot order: Godot boot splash (SCRUBBOTS, factory 082), then the Akilta wordmark, then the opening video. The Akilta step lives inside the existing opening flow (OpeningScreen), not as a second Godot splash.
2. Akilta screen: assets/brand/akilta-wordmark.svg centred on the same black background, about 1.5 s total with fade in and fade out.
3. Tapping during the Akilta step skips to the video. A tap during the video does not change the video's behaviour.
4. Same playback rule as the video: shown once per cold launch, not on root re-creation, internal navigation or resume; no logo when the opening is not played.
5. The SVG imports as a sharp texture at phone sizes (no upscaling at 1080 and 1440 px wide); any derivative has provenance.
6. tests/m42_opening.gd gets an Akilta case and passes (only suite to run, per the job prompt).

## Summary
OpeningScreen.begin() now loads the stream, shows the Akilta wordmark (TextureRect, 60% of screen width, centred, alpha fade 0.4 s in / 0.4 s out over LOGO_SEC 1.5 s), then skip_logo() starts the video (either on timeout or on a tap through _gui_input). The owner SVG has a #111111 fill, which would not show on black, so a white derivative (only the fill changed) is used. It is imported with svg/scale=0.5, which gives a 1233x390 texture. main.gd is unchanged, so the logo follows the opening's existing once-per-cold-launch rule. _t_begin_ms (the startup and playback metrics) now starts when the video starts, and begin() no longer returns false on play_failed. That failure is now reported via the deferred `failed` signal, which main.gd already handles. The existing device_instrumentation case calls skip_logo() so it still measures the video.

Files:
- scripts/app/opening_screen.gd
- tests/m42_opening.gd (new akilta_logo case; device_instrumentation skips the logo)
- assets/brand/akilta-wordmark-light.svg (+ .import, svg/scale=0.5)
- assets/brand/PROVENANCE.md (new)
- TASKS.md (queue row + checklist line)

Commits: 881a6c66, 9c73d759, 179f8d07 (not pushed).

## Acceptance criteria evidence
1. [x] Order: `cold launch: Akilta logo is the first step of the opening` (boot main.tscn with save override + boot_opening_override=1); the begin() case asserts the logo shows first and the video is not playing; boot splash case still passes.
2. [x] `(1080, 2160): logo centred, 60% of width ([P: (216.0, 0.0), S: (648.0, 2160.0)])`, same at 1440x3200; `fades in, holds, fades out (0.00 0.50 1.00 0.38)`; `after 1.5 s the video starts`; `wordmark is white on the black background (65 lit samples)`.
3. [x] `tap skips the logo straight to the video`; `tap during the video does not skip it`.
4. [x] `same rule as the video: no logo when the opening is not replayed` (root re-created in the same process); the existing once_per_cold_launch and boot_opening_to_home_once cases still pass (a finished or failed signal during the logo still ends at Home exactly once).
5. [x] `SVG imports as a 1233x390 texture`; `texture never upscaled (648 <= 1233)` and `(864 <= 1233)`; `derivative = owner SVG with only the fill set to white (source unchanged)`; `derivative and import scale recorded in PROVENANCE.md`.
6. [x] see Validation.

## Validation
- `$GODOT --headless --path . -s res://tests/m42_opening.gd` -> exit 0, `M42 opening cases completed: 10/10`, `M42 opening evidence: PASS`, no SCRIPT ERROR / Parse Error (LOCAL_PASS). It prints only the usual leak warnings at exit.
- `git diff --check` on the changed scripts: clean.
- No CI run and no phone build (per the job prompt).
- project.godot: the worktree already had a Godot-rewritten project.godot when I started. I restored it to HEAD with `git checkout -- project.godot` and re-ran the suite. It is unchanged after that.
- Worktree note: many `*.import` / `*.uid` files were already modified or untracked by Godot import churn before this job started. I staged only job files and committed none of that churn, so `git status --porcelain` is not empty because of it.

## Log
### Round 1
Wrote the criteria above. Added the Akilta step to OpeningScreen, created the white SVG derivative with an import scale and provenance, and added the akilta_logo case. The first test version matched a SHA-256 of the derivative, but that hash changes with autocrlf line endings. I replaced it with a content check (the derivative equals the source with the fill swapped) in 9c73d759. TASKS.md is marked DONE.
