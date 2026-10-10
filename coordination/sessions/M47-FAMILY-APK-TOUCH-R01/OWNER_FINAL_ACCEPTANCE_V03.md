# M47 Family Test — Owner Acceptance V03
Date: 2026-10-10. Exact fixed gameplay source: c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0.

## New owner acceptance
The owner reports direct physical use of the NEW iPhone IPA on their iPhone: "iphonumda yeni ipa yi denedim. hersey ok. super." Owner explicitly approves all three M47 V02 mobile UX fixes and the existing Android APK family builds: "apk larda eminim okeydir. hepsini onayliyorum. devam".

- **iPhone physical result: OWNER DEVICE PASS**, NEW iOS IPA from GitHub Actions run 38063217668, artifact 11674890339, previously confirmed source c2b1c3c7. Owner confirms the tested functions all OK. In scope: Supply front one-tap, Collection touch scrolling, Rewarded Ads red 1 notification, within the reviewed new mobile UX build.
- **Android release decision: OWNER ACCEPTED BY EXPLICIT WAIVER**, not a falsely reported Samsung Flip or Samsung Android tablet retest. The owner has NOT in this message individually retested the new Android APK build 38063215568 / artifact 11674660273; explicitly approved the Android builds based on confidence from iOS result and technical CI evidence. Historic first-APK physical failures were fixed in code and automated coverage, but there is no new Android real-touch evidence to claim.
- **M47 V02 narrow fixes: OWNER ACCEPTED / CLOSED BY OWNER APPROVAL**. The distinct platform-test provenance remains recorded, not rewritten into 3/3 verified physical passes.
- Broader milestone matrices remain separate: M47 full Android performance/heat/background/safe-area, M48 production iOS readiness, general M49 modal/responsive set and full M43-134 badges, all NOT closed by this limited Family UX signoff.
- Offline Family builds still contain only built-in Levels 1–10. R2 live level 11–50 publishing, manifest binding, content integrity/E2E and new online builds remain OPEN and are not approved as complete by this mobile-UX signoff.

## Supporting existing technical evidence
Independent M47 code audit CHATGPT_INDEPENDENT_AUDIT_V02.md and owner IPA clarification CHATGPT_AUDIT_AMENDMENT_V03.md. GitHub Actions Android run 38063215568 validation and signed APK scan passed; iOS run 38063217668 Xcode BUILD SUCCEEDED. M47 R02 sparse-workflow improvement 6edd1733 was later published, but **did not change the already installed iOS IPA**.

Owner states to record:
- M47-FAMILY-APK-TOUCH-R01 V02: OWNER_FINAL_ACCEPTED.
- SB-M47-004 touch narrow acceptance: CLOSED_BY_OWNER_SIGNOFF (iPhone physically verified, Android device reruns waived).
- SB-M49-028 Collection scroll *sub-scope* ACCEPTED; parent broad matrix OPEN.
- SB-M43-134 Rewarded Ads shortcut badge *sub-scope* ACCEPTED; broad system OPEN.
- No additional SDK / APK / IPA build is authorized by this acceptance.
