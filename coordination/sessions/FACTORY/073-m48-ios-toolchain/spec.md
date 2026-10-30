# iOS toolchain documentation and config verification (SB-M48-002..003) plus Android-device queue rows

> Feature: SB-M48-002..003 document the Apple toolchain requirement; prepare iOS configuration. Also flip the Android-device rows SB-M42-032, SB-M47-005..010, SB-M47-011..015 from READY to OWNER ("waits for the Galaxy A10 to be plugged in; see Questions SB-M34-006"), splitting SB-M42-033 out if closable from iOS evidence.

## Context
- iOS is already built by `.github/workflows/ios-ipa.yml` (workflow_dispatch, `macos-latest`, public repo only). It downloads Godot 4.7.2 macOS plus the official export templates tpz, writes `export_presets.cfg` inline (the file is gitignored), runs a fail-closed `--headless --import`, exports an Xcode project (`application/export_project_only=true`), runs `xcodebuild` with `CODE_SIGNING_ALLOWED=NO`, zips an UNSIGNED `Scrubbots.ipa`, scans the PCK inside it (`.github/android/pck_probe`) and headless-boots it. Bundle id `com.sekiph82.scrubbots`, team id placeholder `AAAAAAAAAA`, one 1024 icon for all slots.
- Signing is NOT done in CI and there are no iOS signing secrets: the owner signs at install time via xtool using their paid Apple Developer account, driven from Windows by `C:\Users\sekip\Desktop\Iphone_Yukle_Guncel.bat` (`kurulum` once, `kontrol`, `<ipa path>`; needs the Apple Devices app, a WSL Ubuntu bridge scheduled task on 127.0.0.1:27015, `NOPAUSE=1` for automation). The owner's iPhone 16 (iOS 27) runs it.
- Successful runs: 41114924279 (2026-10-30), 41080595559, 41070827156 (also 38063217668, 38050197093 from 2026-10-10).
- Docs today: no iOS/Apple toolchain doc exists. `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md` lines ~50-67 ("iOS readiness (SB-M42-033)") are stale: they say no macOS/Xcode/template/preset exists.
- TASKS.md: queue rows at lines ~46-49 (`## Autonomous Queue`); row bodies at ~1077-1078 (M42), ~1511-1522 (M47), ~1527-1528 (M48); question `SB-M34-006` under `## Questions for Şekip` (~142).

## Requirements
1. Add `docs/IOS_TOOLCHAIN.md` (short, one page) documenting the real toolchain: macOS runner (`macos-latest`), Xcode via the runner's preinstalled Xcode + `xcodebuild`, Godot 4.7.2 macOS binary + iOS export templates (same version), the inline preset and its key options (bundle id, export_project_only, icons, exclude_filter), the unsigned-IPA policy, the Windows install path (xtool via `Iphone_Yukle_Guncel.bat`, Apple Devices app, WSL bridge), and the credentials policy: Apple credentials stay on the owner's machine / GitHub Secrets by NAME only, none are in the repo and none are currently used by CI. Include the run IDs above as evidence and how to list them (`gh run list --workflow ios-ipa.yml`).
2. Verify the preset/config is complete by reading the workflow against the Godot 4.7 iOS export options. Fix only a genuine defect found; if a fix is made, justify it in the doc and confirm with a new `ios-ipa.yml` run. If none is found, say so in the doc. Known benign: placeholder team id (export_project_only, unsigned).
3. Correct the stale "iOS readiness (SB-M42-033)" section of `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md`: preset now exists in CI, IPA builds and headless-boots; physical cinematic playback on the iPhone remains unverified unless evidence exists (do not claim it).
4. Add one line to AGENTS.md pointing to `docs/IOS_TOOLCHAIN.md` where other docs are referenced.
5. TASKS.md: mark SB-M48-002 and SB-M48-003 done in the body (`[x]`) with evidence (doc path, run IDs, honest labels; `CLAUDE_PEER_REVIEW` only if it happens). Remove the READY SB-M48-002..003 queue row.
6. TASKS.md Autonomous Queue: change `READY` to `OWNER` and append "(waits for the Galaxy A10 to be plugged in; see Questions SB-M34-006)" on the rows for SB-M47-005..010 and SB-M47-011..015. Split `SB-M42-032..033`: SB-M42-032 becomes an `OWNER` row with the same suffix; SB-M42-033 (iOS boot-flow readiness) is closed by requirement 3 (body line `[x]`, evidence = updated doc and the IPA headless-boot step in the cited runs) and has no queue row. No new Questions lines.

## Acceptance criteria
1. `docs/IOS_TOOLCHAIN.md` exists and contains `macos-latest`, `4.7.2`, `export templates`, `xtool`, `Iphone_Yukle_Guncel.bat`, `41114924279`, and states signing happens at install time with no signing secrets in CI (`grep -c` each > 0).
2. `grep -n "SB-M48-002\|SB-M48-003\|SB-M42-033" TASKS.md` shows body lines marked `[x]` with evidence and no queue row remains for them.
3. In the `## Autonomous Queue` block, `grep -n "SB-M47-005..010\|SB-M47-011..015\|SB-M42-032" TASKS.md` shows three `OWNER` rows each containing `waits for the Galaxy A10 to be plugged in; see Questions SB-M34-006`, and no `READY SB-M47-0` or `READY SB-M42-03` row.
4. `git diff -U0 TASKS.md | grep '^+' | grep -c "Questions for"` is 0 and the `## Questions for Şekip` section is unchanged.
5. `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md` no longer states "no `export_presets.cfg`/iOS preset" as current fact and still says physical iOS playback is unverified (unless evidenced).
6. `gh run view 41114924279 --json conclusion -q .conclusion` prints `success`. If the workflow was edited, a new run of the edited workflow is cited and succeeds.
7. `git diff --check` is clean; no code changed and no new test suite added unless a config defect forced one.

## Out of scope
- New test suites, new Godot code, new signing/secrets, store/TestFlight/production release.
- Re-running iOS builds without a workflow change.
- Claiming the opening cinematic was device-verified on iPhone or Android.
- Editing rows beyond the listed flips; adding Questions lines; changing SB-M34-006.

## Assumptions
- SB-M42-033 means static readiness (same boot flow/fallback/aspect rules), closable from config and the workflow's headless pack boot; physical iPhone playback is not claimed. Reason: the row says "readiness" and the existing doc table is the static checklist.
- "Signing secrets by name only" resolves to: none exist for iOS; the owner signs locally with xtool. Reason: the workflow produces an unsigned IPA.
- Placeholder team id and single-icon preset are accepted as complete for the current unsigned/xtool flow; only a real build/export defect justifies changes.
