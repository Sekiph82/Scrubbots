# M47-FAMILY-APK-TOUCH-R01 | Claude Code MASTER PROMPT V02
Date: 2026-10-10. Repo: Sekiph82/Scrubbots. Engine: Godot 4.7.2.
STATUS: READY_FOR_CLAUDE_IMPLEMENTATION. This V02 supersedes V01.

## EXECUTION OWNER: CLAUDE CODE ONLY
CLAUDE must perform ALL coding, investigation, fixes, tests, Git commits/push, Desktop synchronization and new Android/iOS builds. ChatGPT must NOT implement code, build APK/IPA or perform Claude's work. ChatGPT's separate responsibilities are preparing the prompt, independently auditing Claude's evidence and updating root TASKS.md after audit. Claude must NEVER modify root TASKS.md or write ChatGPT audit verdicts.

Read CLAUDE.md, root TASKS.md, coordination/AUDIT_POLICY.md, OWNER_DEVICE_FEEDBACK_V02.md, CHATGPT_AUDIT_CRITERIA_V02.md, V01 prompt/criteria and accepted subsystem contracts BEFORE starting. Three physical devices: owner's iPhone tested FIRST IPA (not proven current), Samsung Flip Android and daughter's Samsung Android tablet. Treat these as owner observations, not root-cause proof.

## CLAUDE IMPLEMENTATION STEPS
A. SUPPLY: Reproduce lost stationary touch down/up through the real GameplayScreen/BatchSupplyPanel GUI route. Trace hit areas, overlay/mouse_filter, 200ms emulated-mouse dedup, safe-area transforms and actual transaction rejection. Fix so a SINGLE TAP on a valid front colored batch transfers exactly one whole FIFO batch via ProductionInputController/FiveSlotBatchEngine to rightmost EMPTY slot. No dragging, hold, second tap or slot targeting. Keep preview rows inert and preserve full/paused/modal/terminal atomic rejection and desktop mouse behavior. Test 3/4/5 columns, 5/6 slots and iOS/Android phone/tablet viewports.

B. COLLECTION: Reproduce stuck finger scroll in real Collection popup. Investigate ScrollContainer, nested row VIEW controls, BasePopup input propagation, clipping/layout and frame stalls. Make swipe-up scroll down smoothly through all 15 sets and Master row, swipe-down scroll up. Scrolling must not accidentally press VIEW; button taps, detail/exchange and mouse wheel remain correct across compact/tall/tablet viewports.

C. REWARDED ADS: Wire existing Home RewardedAdsButton.set_badge into derived HomeBadges logic. Display red numeric "1" exactly when ONE sequential frontier reward is presently actionable (ready_free or provider-eligible ready_ad); otherwise hide for claimed/locked/pending/unavailable/rollback. Recalculate on Home refresh, claim, provider change and new day. Do not alter reward authority, save, provider verification or sequential progression. New owner badge decision overrides older R15 'no badge required' wording for this indicator.

## CLAUDE SAFETY + DELIVERY
Before implementation, non-destructively sync C:\Users\sekip\Desktop\ScrubBots with latest origin/main, logging tracked/untracked/stashes/worktrees and project.godot SHA. Preserve all owner-local changes; do not reset/restore/clean Desktop. Work/test in bounded TEMP worktree with absolute git -C and godot --path; do not install giant SDKs on Windows. If V01 work exists, reconcile without deleting it.

Prove before/after real GUI tests, focused M28/M29/M39/M42/M43/R15/M49 suites, root tests/run_tests.gd ALL PASS, Godot import and git diff --check. Do not weaken M55 tests or alter unrelated gameplay/R2/assets. After fixes, CLAUDE must invoke existing GitHub Actions to produce NEW first-ten Android APK and NEW iOS IPA where supported, logging source SHA, artifact links, signatures and hashes. First iPhone IPA is not proof of new fix; signed Android debug updates may require uninstall and lose save data.

CLAUDE writes coordination/sessions/M47-FAMILY-APK-TOUCH-R01/CLAUDE_LOG_V02.md, pushes code to main, safely synchronizes Desktop, then returns AWAITING_CHATGPT_INDEPENDENT_AUDIT / OWNER_THREE_DEVICE_RETEST_PENDING. Only the owner can confirm the new builds on physical devices.
