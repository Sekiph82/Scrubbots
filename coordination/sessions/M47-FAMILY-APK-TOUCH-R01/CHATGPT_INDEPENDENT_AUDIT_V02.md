# M47-FAMILY-APK-TOUCH-R01 — ChatGPT Independent Audit V02
Date: 2026-10-10
Implementer: CLAUDE CODE. Auditor / sole TASKS.md writer: ChatGPT.
Code: c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0
Builder log: 709bbf0e6ada88009b098c0f5f983d91e4e51e75 (CLAUDE_LOG_V02.md)
Live main initially checked after handoff: one commit beyond fix, log only, no later code delta.

## Independent verdict
- **A Supply single-tap code: TECHNICAL PASS; owner device verification OPEN.**
- **B Collection swipe scrolling code: TECHNICAL PASS; owner device verification OPEN.**
- **C Rewarded Ads numeric red badge code: TECHNICAL PASS; owner device verification OPEN.**
- **New Android offline Family APK: TECHNICAL EXPORT PASS; actual Samsung Flip / Android tablet retest OPEN.**
- **New iOS IPA: XCODE BUILD + ARTIFACT EXISTENCE VERIFIED, but CLEAN IMPORT / PACKAGED RESOURCE INTEGRITY NOT VERIFIED; TARGETED IOS EXPORT-HYGIENE REMEDIATION REQUIRED.** The IPA is unsigned. Owner iPhone retest and clean export gate remain OPEN.
- Therefore overall state: **MOBILE_UX_CODE_PASS / ANDROID_EXPORT_PASS / IOS_EXPORT_HYGIENE_CHANGES_REQUIRED / OWNER_THREE_DEVICE_RETEST_PENDING**. Do NOT record full end-to-end/physical PASS or close SB-M47-004 / SB-M49-028 / SB-M43-134 parents.

## Evidence checked by independent auditor
1. Fetched original GitHub code commit c2b1c3c7, exact diff and source files. Diff is limited to input, six popup scroll surfaces, home badge, 3 tests plus new shared helper; it leaves M23/M24 gameplay engines, reward authority, master art, R2 and project.godot untouched. Root TASKS.md was not in Claude commit.
2. Supply: BatchSupplyPanel now ignores InputEvent.DEVICE_ID_EMULATION mouse events before touch gesture arming. Godot documents DEVICE_ID_EMULATION explicitly as synthesized mouse/touch; Root-viewport test uses Input.parse_input_event and actual Godot dispatch, and six canvas SubViewport scenarios test 3/4/5 Supply columns, 5/6 slots, safe-area insets, exactly one canonical rightmost-empty placement. Additional tests check preview inertness, full-slot atomic rejection, modal gate, multi-touch and real mouse.
3. Scroll: TouchScroll.enable converts nested STOP controls to PASS and configures 16px scroll_deadzone on album, Exchange, Robots, Shop, Gift and Achievements lists. Real popup touch-swipe tests exercise start-on-VIEW, start-on-row, Master reachability, reverse swipe, VIEW tap no accidental swipe press, repeated opens, desktop wheel and other lists; no economy source modified. Some other lists do not overflow in test fixture and so are not physically validated there.
4. Home badge: HomeBadges computes rewarded_ads only from RewardedDailyService current_slot/slot_state; HomeScreen calls existing RewardedAdsButton.set_badge. Slot 1 free, provider-enabled slot 2+, unavailable, pending, granted, next day, rollback, relaunch and all-claimed states have dedicated tests. Old R15 no-badge assertions were deliberately replaced to match owner's V02 decision.
5. GitHub Actions Android run 38063215568, both validate job 114245522985 and export job 114246994403 have all steps SUCCESS. Auditor fetched job logs directly: 13 focused validate commands return exit=0, including M55 and root RESULT: ALL PASS. Independent job log lines show PCK_SCAN files=1982 forbidden=0 required=664 missing=0 main_scene=true PASS; APK_SCAN forbidden_total=0; apksigner Verifies (v2/v3); package com.sekiph82.scrubbots.familydev, versionCode 3, 0.1.3-family-first10-dev. Workflow artifact API confirms artifact 11674660273 is available and was built on exact c2b1c3c7, zip digest sha256:049ebbcb0fb836293185ec90f1a69ebbbcabaeffd304f8bd793c22088a6140e3. Builder's inner APK SHA256 36f0be58d6c1ea2a74b476cac12466d3db907d7975594976a2adb2e136ea55da is supported by its log; auditor did not independently hash 513MB inner APK locally.
6. Builder reports additional 71/71 TEMP test suites PASS and 14/14 focused GUI cases on the fix (18 failed assertions before fix), clean diff, clean headless boot, Desktop synced to 709bbf0e while preserving 4 dirty files, 2616 untracked and 2 stashes. These TEMP/owner-desktop observations were not rerun/inspected on owner computer by ChatGPT; GitHub code and Android CI corroborate major acceptance paths.

## Newly discovered iOS export defect: blocking a CLEAN iOS release assertion
Auditor independently fetched iOS job 114245531483 log for workflow run 38063217668. It confirms Xcode **BUILD SUCCEEDED**, an artifact Scrubbots-ipa id 11674890339 exists, source SHA c2b1c3c7, zip digest sha256:9adb0a0541df0fc596512d7deacce1a820081dbf450623c93bd5a583eecc733d. The application is intentionally UNSIGNED (CODE_SIGNING_ALLOWED=NO, owner signs with xtool at installation).

BUT the same iOS CI import log contains actual errors:
- `ERROR: Failed decoding WebP image` and `Error importing` multiple `res://coordination/sessions/M42-C003/evidence_v03/runtime_captures/*_runtime_24fps.webp` assets.
- `WARNING: read beyond end of data`; `ERROR: ... ERR_FILE_CORRUPT`; `ERROR: Error loading image: 'res://assets/ui/final/gameplay/buttons/icon_pause.png'`; `ERROR: Error importing` that final-gameplay PNG.
- Existing `.github/workflows/ios-ipa.yml` explicitly uses `"$GODOT" --headless --import || true`; therefore import errors do NOT fail workflow. iOS CI has no required-resource scan or forbidden-path scan of the actual IPA/PCK. Successful Xcode link cannot certify package art integrity.
- GameplayScreen currently draws its Pause glyph procedurally, so the broken `icon_pause.png` *may* be unused. This is NOT established across the entire app, nor proof the exported resource is safe to drop. No new M47 code modified this icon or the evidence WebPs, so this could be pre-existing export debt. Do not redraw/remove approved artwork without proof/owner authorization.
- iOS inner IPA SHA256 is not in logs; only GitHub artifact ZIP digest is independently available.
For these reasons, iOS archive EXISTENCE is verified, but *clean iOS export* is NOT a pass. Targeted Claude-only remediation prompt: `coordination/sessions/M47-FAMILY-APK-IOS-EXPORT-R02/CHATGPT_PROMPT_V01.md`. Do not rerun Android or discard already verified UI code while fixing the separate iOS export gate.

## Non-blocking Android warning
Android export PCK boot exits 0 and passes required-resource scan but logs 59 ObjectDB instances leaked at exit and 29 resources still in use. They are disclosed as headless shutdown warnings, not proven on-device leaks or attributable to this change. Separate M55 long-session QA remains OPEN as previously tracked.

## Owner actions / final release gate
- Android retest may proceed using the NEW APK: https://github.com/Sekiph82/Scrubbots/actions/runs/38063215568/artifacts/11674660273 . Old debug builds use different CI signing keys, so uninstall may be required and will erase local progress. Do not uninstall automatically.
- iOS artifact https://github.com/Sekiph82/Scrubbots/actions/runs/38063217668/artifacts/11674890339 exists and is unsigned, but **do not describe it as clean/verified**; prioritize R02 import/package integrity before treating it as a release-quality retest source.
- Three-device owner acceptance requires exact new build identification and explicit checks: Supply single stationary tap; Collection swipe from row and VIEW to Master; Rewarded Ads red 1 when free/currently actionable and disappearing after grant without provider. iPhone FIRST IPA observations are historical, not evidence of latest version.
- No root task closures until these explicit owner physical checks; audit status recorded in root TASKS.md by ChatGPT only.
