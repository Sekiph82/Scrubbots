STATUS: READY

# Build: Boot splash: SCRUBBOTS logo instead of the Godot logo

## Summary
The engine boot splash now shows the SCRUBBOTS logo on black instead of the Godot logo. One set of `project.godot` settings covers both Android and iOS. Following the orchestrator's decision, the splash image is a new portrait derivative: a 1080x2160 opaque black canvas with `splash_logo.png` (P2-010) Lanczos-downscaled to 864x288 (80% of the width) and centred at (108, 936). It is a resize/pad only, with no new art, and `splash_logo.png` is unchanged. It uses `stretch_mode=1` (Keep), so it fits every aspect ratio without being cropped or distorted, and the letterbox is the same black as `bg_color`.

Godot 4.7.2 has no `boot_splash/fullsize`. The headless property dump shows `application/boot_splash/{bg_color, show_image, stretch_mode (Disabled,Keep,Keep Width,Keep Height,Cover,Ignore), use_filter, image, minimum_display_time}`, so `stretch_mode` replaces `fullsize` from spec Requirement 1.

Commits on `factory/082-boot-splash-logo`: `06728002` (code/asset/test/docs) and `28559dd5` (TASKS.md).

Files changed:
- `project.godot`: 5 `boot_splash/*` keys
- `assets/ui/final/system/splash/boot_splash_portrait.png` (new, 237,558 bytes)
- `ASSET_GENERATION_MANIFEST.json`: entry `boot_splash_portrait`, provider `derivative_resize_pad`, source P2-010
- `assets/ui/VISUAL_ASSET_INDEX.md`: 1 row
- `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md`: row 1 note
- `tests/m42_opening.gd`: new case `boot_splash_logo`
- `TASKS.md`: queue row `SB-BOOT-SPLASH-LOGO`

`scripts/app/opening_screen.gd` is unchanged because the video's frame 0 is black (see AC2). `AGENTS.md` is unchanged because it does not document `project.godot` application settings.

**APK for the phones:** `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/51e2db58-2f8f-47a6-9600-5f09840e2925/scratchpad/apk082/ScrubBots-Family-First10-Android-Debug.apk/ScrubBots-Family-First10-Android-Debug.apk`
- sha256 `597b3d9e0be80313f3af75ab73043f0b24a51c75654378987f4e05cc102fdca9`
- versionCode 49, package `com.sekiph82.scrubbots.familydev`

## Acceptance criteria
1. [x] **grep shows all keys:** `bg_color=Color(0, 0, 0, 1)`, `image="res://assets/ui/final/system/splash/boot_splash_portrait.png"`, `show_image=true`, `stretch_mode=1`, `use_filter=true`. `fullsize` does not exist in 4.7.2 and is replaced by `stretch_mode`, as explained in the Summary.
2. [x] **Headless settings check** (`--script ac2.gd`):
   - Output: `image=res://assets/ui/final/system/splash/boot_splash_portrait.png exists=false file=true`, `show_image=true`, `stretch_mode=1`, `use_filter=true`, `bg_color=(0.0, 0.0, 0.0, 1.0)`, `bg_is_black=true`.
   - `ResourceLoader.exists` is false locally only because this worktree never ran an editor import. The boot splash is loaded as the raw PNG, which `FileAccess` confirms is present, and the CI export imports it: the APK holds `boot_splash_portrait.png-777ab….ctex` plus the raw PNG.
   - **Frame 0 colour:** ffmpeg frame 0 of `scrubbots_opening_720p30.ogv` is near-black. The most common colours are (11,11,11), (10,10,10) and (15,15,15). I treated that as black, so `bg_color` is pure black, which equals `OpeningScreen.BACKGROUND` (the letterbox bars around the video). `BACKGROUND` is left unchanged.
3. [x] **Windowed desktop capture:** a scratch `--script hold.gd` that only waits 6 s, so `main.tscn` was never booted and no save was touched. The boot splash shows the SCRUBBOTS logo, not the Godot logo, in both captures:
   - 450x900 portrait: `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/51e2db58-2f8f-47a6-9600-5f09840e2925/scratchpad/splash_capture_portrait.png`
   - 700x500 wide: `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/51e2db58-2f8f-47a6-9600-5f09840e2925/scratchpad/splash_capture_wide.png`
   - In both, the logo is centred and uncropped, with black letterboxing.
4. [x] **CI apk_only run 41219945108 succeeded** (head `06728002`; export success, validate skipped by mode). In the downloaded APK:
   - `assets/assets/ui/final/system/splash/boot_splash_portrait.png` (237,558 bytes, the raw file) and its imported `.ctex` are present.
   - `assets/project.binary` contains `boot_splash/image`, `boot_splash/bg_color` and `boot_splash_portrait`.
   - The Android 12+ system splash `res/drawable/splash_icon.webp` (1254x1254) is the SCRUBBOTS app icon, and `splash_branding_image.webp` is fully transparent.
   - The launcher `res/mipmap-hdpi-v4/icon.webp` is the SCRUBBOTS icon.
   - No Godot image exists under `res/`. The only `godot` names there are layout/xml files.
   - `apk_metadata.txt` has 0 `godot` matches. It contains no `application-icon` line, so I checked the icon by extracting the webp files directly.
   - **iOS (code-reviewed, no IPA run):** the 4.7.2 binary's iOS exporter maps `storyboard/image_scale_mode` (default "same as splash") to `application/boot_splash/stretch_mode`, mapped as center / scaleAspectFit / scaleAspectFill / scaleToFill. `ios-ipa.yml` sets no `storyboard/*` options, so the launch storyboard uses the boot splash image, `bg_color` and Keep (scaleAspectFit).
5. [x] **`git diff --check`** on the changed files is clean. Suite results:
   - `tests/m42_opening.gd`: exit 0, `M42 opening cases completed: 9/9`, `M42 opening evidence: PASS`, all 6 `boot_splash_logo` asserts ok.
   - `tests/m44_ftue.gd`: exit 0, `M44 FTUE evidence: PASS (23/23 cases, 0 fail)`.
   - Neither printed `SCRIPT ERROR` or `Parse Error`.
6. [x] **Changed-file set:** `project.godot`, docs lines and job/TASKS evidence, plus the orchestrator-mandated derivative PNG, its manifest and index provenance, and the permanent test case. `opening_screen.gd` is not touched.

## Validation
- `$GODOT --headless --path . -s res://tests/m42_opening.gd`: LOCAL_PASS (9/9)
- `$GODOT --headless --path . -s res://tests/m44_ftue.gd`: LOCAL_PASS (23/23)
- headless settings script `ac2.gd`: printed the expected values
- `python -I -c json.load(ASSET_GENERATION_MANIFEST.json)`: ok
- `git diff --check` on the changed files: clean
- CI `android-family-first10.yml` `mode=apk_only` run 41219945108: success. Remote branch deleted afterwards (`git ls-remote` shows 0 heads).

## Log
### Round 1
- Implemented the spec as modified by the orchestrator: a portrait derivative plus a stretch mode instead of a raw 2172 px logo with `fullsize=false`.
- Verified the 4.7.2 key names and set the background to black after sampling the video's frame 0.
- Added the permanent `boot_splash_logo` case to `m42_opening.gd`. Captured desktop splash screenshots and ran CI apk_only, then inspected the APK.
- **Worktree not clean:** `git status --porcelain` is not empty. It still shows pre-existing `.import` modifications and untracked `.uid`/`.import` files created by the local Godot runs. The orchestrator said not to commit that churn, so I left it uncommitted for worktree deletion.
