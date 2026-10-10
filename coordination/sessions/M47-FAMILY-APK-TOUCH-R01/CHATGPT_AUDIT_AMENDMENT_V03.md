# M47 — Independent iOS Audit Clarification V03
Date: 2026-10-10. This amendment corrects the blocking interpretation of CHATGPT_INDEPENDENT_AUDIT_V02.md. The original audit is retained for provenance.

## Verified successful IPA production
The iOS run 38063217668, job 114245531483, built source c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0 and explicitly finished Xcode with BUILD SUCCEEDED. The unsigned Scrubbots-ipa artifact 11674890339 exists. Its ZIP digest is sha256:9adb0a0541df0fc596512d7deacce1a820081dbf450623c93bd5a583eecc733d. Signing with xtool at installation is expected. The owner's Claude log correctly states IPA creation succeeded. Saying the IPA build failed would be incorrect.

## Additional import diagnostics versus actual build
A separate, detailed GitHub Actions job log contains Godot import errors for evidence-only WebPs under coordination/sessions/M42-C003/evidence_v03, plus ERR_FILE_CORRUPT / Error importing assets/ui/final/gameplay/buttons/icon_pause.png. The current workflow uses headless --import with a shell fallback that continues despite import errors. These diagnostics justify future workflow quality hardening, but do NOT establish that the finished IPA is broken. The shipped GameplayScreen Pause button draws its glyph programmatically; exhaustive non-use of the old icon file has not been proven. No missing app resource or startup failure on the iPhone has been observed on this new build.

## Corrected decision
**MOBILE_UX_CODE_TECH_PASS / ANDROID_EXPORT_TECH_PASS / IOS_IPA_BUILD_SUCCESS_UNSIGNED / IOS_IMPORT_DIAGNOSTICS_NONBLOCKING_FOR_FAMILY_TEST / OWNER_THREE_DEVICE_RETEST_PENDING.**

The newly produced iOS IPA is available for immediate owner installation and testing on the iPhone through xtool. It is a provisional family-test build, not a certified clean-import production release. The existing M47-FAMILY-APK-IOS-EXPORT-R02 prompt is retained but DEFERRED as optional non-blocking QA hardening. It is not a prerequisite to mobile testing and should not trigger another build unless actual runtime issues are found or the owner prioritizes packaging QA.

Sources:
iOS workflow: https://github.com/Sekiph82/Scrubbots/actions/runs/38063217668
IPA artifact: https://github.com/Sekiph82/Scrubbots/actions/runs/38063217668/artifacts/11674890339
Android artifact: https://github.com/Sekiph82/Scrubbots/actions/runs/38063215568/artifacts/11674660273
