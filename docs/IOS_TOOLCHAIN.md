# iOS / Apple toolchain (SB-M48-002..003)

How Scrubbots is built for iOS and installed on the owner's iPhone. The only build path is
`.github/workflows/ios-ipa.yml`; nothing here needs a Mac on the owner's side.

## Build: GitHub Actions (`ios-ipa.yml`)

- Trigger: `workflow_dispatch` only (Actions tab "Run workflow" or `gh workflow run ios-ipa.yml`).
  Runs only while the repo is public (`!github.event.repository.private`), on the free standard
  `macos-latest` runner. No larger/paid runners.
- Xcode: the runner's preinstalled Xcode and `xcodebuild` (`-sdk iphoneos`,
  `-destination 'generic/platform=iOS'`, Release). Nothing is installed or pinned for Xcode.
- Godot: the official Godot 4.7.2 macOS universal binary plus the official 4.7.2
  export templates (`Godot_v4.7.2-stable_export_templates.tpz`, same version, unpacked into
  `~/Library/Application Support/Godot/export_templates/4.7.2.stable`).
- Steps: sparse checkout without developer trees -> fail-closed `--headless --import` ->
  `--export-release "iOS"` to an Xcode project -> `xcodebuild` unsigned -> zip `Payload/` into
  `Scrubbots.ipa` (fixed export / Xcode / binary / .pck basename) -> rename to
  `build/ios/<build_type>/ScrubBots-iOS-<build_type>-v<version>-b<build>.ipa` (SB-M59,
  `docs/RELEASE_BUILDS.md`) -> scan the PCK inside the IPA (`.github/android/pck_probe`,
  verdict=PASS) -> headless boot of that PCK (`--main-pack`, no missing resources / script errors).
- Optional input `local_notifications` (default `false`, SB-M43-171/172): builds the
  ScrubbotsNotify GDExtension (`native/ios/scrubbots_notify`, UNUserNotificationCenter
  permission + one local reminder) into `res://bin/` before the import; details in
  `docs/RELEASE_BUILDS.md`. Its load error on the macOS import / headless boot (no macOS library)
  is filtered out of those two gates.
- Artifacts: `ScrubBots-iOS-<build_type>-v<version>-b<build>.ipa` (the IPA) and
  `ScrubBots-iOS-<build_type>-ipa-inspection` (import/export logs, SHA-256, PCK scan report).

## Export preset

`export_presets.cfg` is gitignored; the workflow writes it inline in the "iOS export preset" step.
Key options:

| Option | Value | Why |
|---|---|---|
| `application/bundle_identifier` | `com.sekiph82.scrubbots` | app id |
| `application/app_store_team_id` | `AAAAAAAAAA` (placeholder) | benign: export is project-only and unsigned |
| `application/export_project_only` | `true` | Godot emits an Xcode project; CI builds it with `xcodebuild` |
| `icons/icon_1024x1024`, `icons/app_store_1024x1024` | `res://assets/ui/final/branding/app_icon_ios_1024.png` | Godot 4.3+ derives every other size from the 1024 icon |
| `exclude_filter` | coordination, docs, tests, tools, level_factory, content_pipeline, art references, generated/candidate UI, `.github` | developer files stay out of the pack (also absent from the checkout) |

Portrait orientation comes from `project.godot` (`display/window/handheld/orientation=1`).

Config review (SB-M48-003, 2026-10-31): the workflow was read against the Godot 4.7 iOS export
options. **No defect found, workflow unchanged.** The legacy per-size `icons/iphone_*`,
`icons/ipad_*`, `icons/spotlight_*`, `icons/settings_*`, `icons/notification_*` keys are leftovers
from Godot 4.2; 4.7 ignores them and the required `icons/icon_1024x1024` is set. Harmless,
left as is.

## Signing and install (Windows, owner's machine)

- `build_type: debug` (default): CI never signs. `xcodebuild` runs with `CODE_SIGNING_ALLOWED=NO`; the IPA is UNSIGNED.
- `build_type: release` (SB-M59-002): distribution-signed IPA from the `IOS_*` GitHub Secrets only, fails fast
  when they are absent; never uploaded. See `docs/RELEASE_BUILDS.md`.
- Signing happens at install time: xtool signs the IPA with the owner's paid Apple Developer
  account while installing it on the iPhone 16 (iOS 27).
- Driver: `C:\Users\sekip\Desktop\Iphone_Yukle_Guncel.bat` - `kurulum` (one-time setup),
  `kontrol` (check device/bridge), `<ipa path>` (sign + install). Needs the Apple Devices app,
  the WSL Ubuntu bridge scheduled task on 127.0.0.1:27015, and `NOPAUSE=1` for unattended runs.

## Credentials policy

- No Apple credentials, certificates, provisioning profiles or team ids are in the repository.
- The debug path uses no iOS signing secrets. The release path reads `IOS_DIST_CERT_P12_BASE64`,
  `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_TEAM_ID` (owner adds them; not set yet).
- Apple credentials stay on the owner's machine (xtool login). If CI signing / TestFlight is ever
  added, credentials go to GitHub Secrets and are referenced by NAME only.

## Evidence

Successful `ios-ipa.yml` runs (all `success`):

| Run ID | Date | Head SHA |
|---|---|---|
| 41114924279 | 2026-10-30 | `fd936d6a` |
| 41080595559 | 2026-10-30 | `b1c2d1da` |
| 41070827156 | 2026-10-30 | `1087a361` |
| 38063217668 | 2026-10-10 | - |
| 38050197093 | 2026-10-10 | - |

List / check them:

```
gh run list --workflow ios-ipa.yml
gh run view 41114924279 --json conclusion -q .conclusion
```

Not covered here: physical opening-cinematic playback on the iPhone (see
`docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md`), TestFlight and any store release.
