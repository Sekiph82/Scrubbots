# M47 Mobile Family QA — Independent Audit Criteria V02
Date: 2026-10-10. Repo: Sekiph82/Scrubbots. Supersedes V01 for the combined mobile QA cycle.
Owner-tested physical devices: iPhone (FIRST IPA, source version unconfirmed), Samsung Flip Android phone, Samsung Android tablet. All reported mobile problems remain OPEN until actual retesting.

## G0 Safety
Claude must read CLAUDE.md, TASKS.md, owner feedback V02, and previous prompt V01. All implementation/testing in isolated TEMP worktree; non-destructive sync of persistent Desktop before and after. No loss of local changes. Claude must not edit root TASKS.md. Only input, scrolling, badge presentation and matching tests/logs may change.

## A Supply
Show pre-fix failure and corrected press/release through the actual Godot GUI input route, not only a direct method call. One stationary single tap on a visible enabled Supply front (row 0) yields exactly one canonical M29 transactional placement into the rightmost empty execution slot. Test 3/4/5 columns, 5/6 slots, iPhone-like portrait and Android phone/tablet dimensions, safe areas, rapid taps, emulated mouse dedup, multitou​​ch, focus, full slots, exhausted columns, pause and modal. No drag requirement or preview-row acceptance. Preserve FIFO and gameplay authority.

## B Collection
Reproduce before-fix finger scroll sticking in a real Collection popup. After fix, swipe up moves down through all 15 sets and Master; swipe down reverses. Buttons inside rows must not steal drag. Ordinary taps still activate intended VIEW, detail, Exchange and Close; no accidentally triggered reward or altered card/economy behavior. Test repeated open/close, compact and tablet layouts, scrolling with card art, mouse wheel, performance evidence.

## C Rewarded Ads
Existing red badge on Home Rewarded Ads shows exact "1" when next sequential reward is currently actionable: ready_free; ready_ad only if provider available. Otherwise badge zero for claimed, locked, pending, unavailable, rollback and invalid/blocked state. Count only one sequential frontier, not all five. Verify initial Home render, claim then refresh, next slot, provider unavailable, daily reset and app relaunch. No altered reward grant / save / verified video logic. Older no-badge requirement is superseded by owner.

## D Tests and delivery
Headless Godot 4.7.2 import, focused failing-before/passing-after tests, relevant M28/M29/M43/R15/M49 and root run_tests.gd ALL PASS; git diff --check clean. Build a NEW Android Family APK and NEW iOS IPA if toolchain permits, with separate exact source SHAs, GitHub Actions runs, signing status, hashes and genuine artifact links; Android export still has zero forbidden developer trees. An unavailable IPA is reported as blocked, never fabricated. Previous first iOS IPA is not proof of latest code. Do not claim physical-device PASS from synthetic tests.

Technical verdict: MOBILE_UX_TECHNICAL_PASS / OWNER_THREE_DEVICE_RETEST_PENDING only when source and evidence validate A/B/C. Physical acceptance only after owner confirms on iPhone, Samsung Flip and Samsung Android tablet.