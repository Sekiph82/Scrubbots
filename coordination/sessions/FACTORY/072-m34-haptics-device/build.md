STATUS: READY

# Build: M34 haptics real-device (Android) evidence + stale queue-row fix

## Summary
The code-side work is done. The device ON/OFF capture is still PENDING because the phone is unplugged, and per the coordinator's round-2 instruction SB-M34-006 stays open.

- **VIBRATE permission (Req 3).** The family APK used to declare no permissions, so Android dropped every haptic call. The preset now declares VIBRATE.
- **Stable debug key (owner-approved).** Family APKs are now signed with one debug key stored in GitHub Secrets. Each new build can then install over the previous one with `adb install -r`, keeping the save.
- **TASKS.md.** The SB-CAMPAIGN-L11-L30 row is corrected (Req 6).

Branch `factory/072-m34-haptics-device` commits (all pushed): `5fbcb019`, `8d98a73c`, `b179d341`, `64ac9084`, `a0b0fb2f`.

Files changed:
- `.github/android/export_presets_family_first10.cfg`: adds `permissions/vibrate=true` and updates the keystore comment.
- `.github/workflows/android-family-first10.yml`: the export job's keystore step now decodes `ANDROID_DEBUG_KEYSTORE_BASE64` and uses `_PASSWORD`/`_ALIAS`. It generates a key only when the secret is absent. The env vars and editor settings now use these variables. `apk_only` is unchanged.
- `docs/12_HAPTICS_PLATFORM_RESEARCH.md`: corrects the false claim that VIBRATE is "granted by default".
- `docs/M34_HAPTICS_DEVICE_VALIDATION.md`: new. Covers APK sources, the permission defect, the signing evidence, the device-run commands and the Owner note.
- `TASKS.md`: lines 45 and 959 (SB-M34-006 finding, still open) and line 138 (L11-L30 row).

GitHub Secrets set on Sekiph82/Scrubbots: `ANDROID_DEBUG_KEYSTORE_BASE64`, `ANDROID_DEBUG_KEYSTORE_PASSWORD`, `ANDROID_DEBUG_KEYSTORE_ALIAS` (alias androiddebugkey). The keystore is PKCS12, RSA 2048, valid 10000 days, with a random password. The password is not printed anywhere in the repo, the logs or this file. A `git grep` of HEAD for the password returned nothing. The local copy is kept outside the repo at `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/51e2db58-2f8f-47a6-9600-5f09840e2925/scratchpad/keystore/` (keystore plus pass.txt). This is a temp folder; the secret in GitHub is the durable copy.

## Acceptance criteria
1. [ ] ON/OFF captures in the doc: PENDING. The phone is unplugged and was not touched, as the coordinator instructed. The doc has the exact commands.
2. [x] The doc names the APK sources and has the Owner note:
   - Installed build: main `d88a3944`, run 41116404350, no permissions.
   - Fixed builds: runs 41127683939, 41129466216 and 41129478628, all declaring `android.permission.VIBRATE` (checked with `aapt2 dump badging`).
3. [ ] SB-M34-006 done with `DEVICE_AUTOMATED_PASS`: intentionally not marked. The task stays open per the coordinator. Lines 45 and 959 carry the evidence. Line 955 is unchanged because the task still waits on the device.
4. [x] SB-CAMPAIGN-L11-L30 row: it contains `06fbfbad` and "skipped by owner decision 2026-10-30 (no pass claimed)", no longer contains "m55_long_session FAIL", and keeps the m52 note.
5. [x] No GDScript changed. Both m34 suites were still re-run: `m34_haptics_production` printed "...wiring evidence: PASS" and `m34_haptics_runtime` printed "...runtime evidence: PASS". Both exited 0 with 0 SCRIPT/Parse errors. LOCAL_PASS.
6. [x] `git diff --check` is clean. The changed files are the doc, TASKS.md, the preset fix, the docs/12 drift line, and the coordinator-requested workflow signing change.

Coordinator round-2 items:
- [x] One keystore generated in scratchpad/keystore (Eclipse Adoptium JDK 17 keytool). Local cert SHA256 `77:0A:89:...:6E:BA:27`.
- [x] The 3 secrets are set (`gh secret list` shows them).
- [x] The workflow uses the secret and falls back to a generated key only when the secret is absent.
- [x] Two `apk_only` runs on `64ac9084`. Both logged "debug keystore: stable GitHub Secret", and `apksigner verify --print-certs` gives the same signer SHA-256 `770a894ee0e76737c24640f749c26142522cdd3d5fa35ca02d027591666eba27` for both. It matches the local keystore.

  | Run | Result | versionCode |
  |---|---|---|
  | 41129466216 | success | 44 |
  | 41129478628 | success | 45 |
- [x] The newest APK (versionCode 45) is at `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/51e2db58-2f8f-47a6-9600-5f09840e2925/scratchpad/apk072/ScrubBots-Family-First10-Android-Debug.apk`.

## Validation
- m34_haptics_production and m34_haptics_runtime: LOCAL_PASS.
- The workflow YAML parses (`yaml.safe_load`).
- CI runs:

  | Run | Mode | Result |
  |---|---|---|
  | 41127683939 | apk_only | success |
  | 41129466216 | apk_only | success |
  | 41129478628 | apk_only | success |
  | 41125628591 | build_apk | failed, see below |

  Run 41125628591 failed in validate on `m55_long_session FAIL (6)`. That failure is on current main and is unrelated to this branch.

## Remaining (not code)
- **Device ON/OFF run.** The phone still has the old-key build from run 41116404350. Moving it to the stable key needs one last reinstall. To keep the save:
  1. Copy the save out with `adb shell run-as com.sekiph82.scrubbots.familydev` (the build is debuggable).
  2. Uninstall the old build.
  3. Install the versionCode-45 APK.
  4. Restore the save.
  5. Run the ON/OFF commands in the doc.

  After that, every family APK installs with `-r`.
- **m55_long_session.** It fails on main in `build_apk` mode. This is a separate issue.

## Log
### Round 1
- Device absent, so the ON/OFF run was impossible.
- `aapt2` showed the installed APK had zero permissions. Fixed the preset (`permissions/vibrate=true`) and corrected docs/12.
- Both m34 suites: PASS.
- `build_apk` CI failed on unrelated m55. Rebuilt with `apk_only` (run 41127683939), which declares VIBRATE.
- Found that the signing key changed on every run.
- Wrote the doc (device section PENDING) and updated TASKS.md lines 45, 959 and 138.
- Status was BLOCKED (no device, plus the install-over-save problem).

### Round 2
No review files this round. This round carried out the coordinator follow-up: the owner approved storing a stable debug key in GitHub Secrets, option (a).
- Generated the keystore in scratchpad and set the 3 secrets without echoing the password.
- `64ac9084`: the workflow keystore step uses the secret, with a generated-key fallback. Updated the comment in the preset header.
- Ran `apk_only` twice (41129466216, 41129478628). The signer SHA-256 is identical in both and matches the local keystore.
- Kept the versionCode-45 APK in scratchpad/apk072.
- `a0b0fb2f`: updated the doc signing section and TASKS line 45.
- Phone not touched, and the haptics toggle was never changed.
- Committed only job files. The leftover `.import`/`.uid`/project.godot churn from the import step is still uncommitted in the worktree.
