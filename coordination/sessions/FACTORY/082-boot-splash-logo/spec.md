# Boot splash: SCRUBBOTS logo instead of the Godot logo

> Feature: owner request 2026-10-31: "oyun acilirken hala godot logosu cikiyor video oncesinde. bu godot logosunun oldugu yere bizim oyunun logosunu koy". Replace Godot's default boot splash with the SCRUBBOTS logo on Android and iOS.

## Context
- `project.godot` `[application]` (line ~17) has only `boot_splash/bg_color=Color(0.070588, 0.078431, 0.098039, 1)` (BG01 #121419-ish dark). No `boot_splash/image`, so the engine shows its built-in Godot logo before the main scene.
- The main scene then runs `scripts/app/opening_screen.gd`, which plays `assets/brand/opening/scrubbots_opening_720p30.ogv` over a pure black `BACKGROUND := Color(0,0,0,1)` ColorRect (line 22). Splash bg and opening bg differ today (a visible flash).
- Logo art already exists and is owner-approved, no new art: `assets/ui/final/system/splash/splash_logo.png` (Phase 2 item P2-010 "Boot splash logo", derived from the canonical production logo; 2172x724 RGBA, listed in `assets/ui/VISUAL_ASSET_INDEX.md`). Sibling `assets/ui/final/branding/logo_colorful.png` is its source (P2-001). Use `splash_logo.png`.
- Android: `.github/android/export_presets_family_first10.cfg` (copied to export_presets.cfg by `.github/workflows/android-family-first10.yml`, which has an `apk_only` mode and an aapt2 metadata step near line 455). Launcher icons are set (lines 45-47); no gradle build, so Android 12+ system splash = launcher icon on a theme background, not a Godot logo.
- iOS: preset is inline in `.github/workflows/ios-ipa.yml` (lines ~76-105), icons only; the Godot iOS export generates the launch screen from `application/boot_splash` project settings (`boot_splash/image`, `bg_color`) via its `LaunchScreen.storyboard`; there is no separate custom option set in the preset today.
- The Godot logo shown "before the video" is the engine boot splash, which is project-level, so one project.godot change covers both platforms.

## Requirements
1. In `project.godot` `[application]` set `boot_splash/image="res://assets/ui/final/system/splash/splash_logo.png"`, `boot_splash/show_image=true`, `boot_splash/fullsize=false` (centered, not stretched), `boot_splash/use_filter=true` (smooth, the art is not pixel art), keeping `boot_splash/bg_color`. Builder verifies the exact Godot 4.7.2 key names (`"$GODOT" --headless --path . --export-pack` not needed; check via `ProjectSettings.has_setting` or editor docs) and fixes names if different.
2. Set `boot_splash/bg_color` equal to the opening video's first frame colour. Builder samples frame 0 of the .ogv (e.g. ffmpeg/Godot VideoStreamPlayer capture); if it is black set bg_color to black AND leave `BACKGROUND` in `opening_screen.gd` unchanged; if it is another colour set both so the splash, the Opening background and the video start match. No flash between splash and video.
3. The logo must be readable on phones: at 1080x2160 viewport it shows at native 2172x724 only if it fits; Godot does not scale a non-fullsize splash, so builder checks the displayed width is at most the screen width on small phones and, if 2172 px exceeds typical 1080-wide screens, reports it (do not create new art; if it overflows, allow Godot's default behaviour of fitting and record the result in the job evidence).
4. No Godot logo anywhere at launch: confirm no `application/boot_splash` default remains, Android 12+ system splash uses only the app launcher icon (verify via aapt2 on the built APK: `application-icon`, theme/`windowSplashScreen*` references contain no Godot asset), and iOS launch screen derives from the same settings (verify in the generated Xcode project from the `ios-ipa.yml` export step if run; otherwise record as code-reviewed with the storyboard reference).
5. Do not change gameplay, opening video, scene flow or any asset. If the Godot importer produces a `.import` for the splash image already present, leave it; do not re-import other files.
6. Doc updates: add one line to `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md` row 1 (or its notes) stating the splash is the SCRUBBOTS logo on the opening-matching colour; update `AGENTS.md` only if it documents project.godot application settings; add the TASKS.md evidence entry through the factory loop.

## Acceptance criteria
1. `grep -E "boot_splash/(image|show_image|fullsize|use_filter|bg_color)" project.godot` shows all five keys with the values from Requirement 1/2.
2. A headless check prints the settings: `"$GODOT" --headless --path <worktree> --script <scratch script>` reading `ProjectSettings.get_setting("application/boot_splash/image")` equals the splash_logo path and `ResourceLoader.exists()` on it is true, and `application/boot_splash/bg_color` equals the sampled video frame-0 colour (builder records the script output in the job evidence).
3. Local desktop capture (feasible, no save overwrite: run a throwaway scene or `--headless` is not enough; use a windowed run with a save override and never boot `main.tscn` against the owner save) of the first frames shows the SCRUBBOTS logo, not the Godot logo; screenshot path recorded in evidence. If not feasible, say so honestly and rely on criteria 1, 2 and 4.
4. One `apk_only` run of `android-family-first10.yml` succeeds; in the downloaded APK `unzip -l` shows the PCK/`assets` containing the splash and `project.binary` (the project settings blob is stored in the PCK/`res://project.binary`) includes `boot_splash/image` (check with `strings`/`grep -a "splash_logo"`); the aapt2 metadata output (`apk_metadata.txt`) shows the family launcher icon and no Godot icon/splash reference.
5. `git diff --check` clean; existing quick suites still PASS, at minimum the suite covering the opening screen (find with `grep -l opening_screen tests/*.gd`) via `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd` printing its PASS line.
6. The changed-file set is limited to `project.godot`, optionally `scripts/app/opening_screen.gd` (only the BACKGROUND colour, requirement 2), the docs lines, and job/TASKS evidence.

## Out of scope
- New or regenerated logo art, new splash animation, extra loading screens.
- Changing the opening video, its timing or skip behaviour.
- A production store build, Android adaptive-icon or iOS icon changes, gradle/custom-template builds.
- Per-platform differing splashes.

## Assumptions
- `splash_logo.png` (P2-010) is the approved boot-splash asset since it is the derived-for-splash version of `logo_colorful.png`; chosen over the latter to match the asset plan.
- Godot 4.7 provides `application/boot_splash/{image,show_image,fullsize,use_filter,bg_color}` (minimum_display_time may also exist; not required); builder verifies names.
- The Android 12 system splash already shows only the app icon (no Godot logo) for non-gradle builds; verified by aapt2, not changed unless a Godot asset is found.
- iOS launch screen is produced from the same project settings by the Godot exporter, so no workflow preset change is needed unless the generated storyboard still references a Godot image.
