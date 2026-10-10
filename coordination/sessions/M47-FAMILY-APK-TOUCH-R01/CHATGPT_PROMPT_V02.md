# Mobile QA Prompt V02
Date: 2026-10-10
Repo: Sekiph82/Scrubbots
Claude: read CLAUDE.md, TASKS.md and OWNER_DEVICE_FEEDBACK_V02.md first.
V02 supersedes V01.
Task: investigate and fix three owner-reported issues on iPhone, Samsung Flip Android and Samsung Android tablet:
1. One tap on a supply front batch should instantly load exactly one batch into the rightmost available slot. No dragging.
2. Collection must scroll smoothly to all 15 sets and master reward.
3. Home Rewarded Ads shortcut must show the existing red badge "1" when one reward is currently claimable, and clear it when no reward is actionable.
Do not change grants, gameplay rules, approved art, or remote-content logic. Preserve owner files; work in TEMP. Run focused input/UI tests and full regression. Produce new Android APK and iOS IPA artifacts with source SHA, test logs and download references. Hand off for independent audit and real-device retest. Do not edit root TASKS.md. Companion: CHATGPT_AUDIT_CRITERIA_V02.md.