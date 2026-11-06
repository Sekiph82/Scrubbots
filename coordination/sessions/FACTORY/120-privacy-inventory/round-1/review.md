# Review round 1: 120-privacy-inventory (SB-M58-001..006)

Verified against code in the worktree:
- Remote content: data/config/remote_content_runtime_v1.json has enabled=false and empty URLs. TRUE.
- Analytics: consent defaults false, NullSink default, state file user://analytics_v1.json. TRUE.
- Android preset: only permissions/post_notifications=true and vibrate=true; internet=false. TRUE.
- iOS preset: no privacy/capabilities/entitlements keys set. TRUE.
- user:// literals in scripts: every one is listed in section 2 (save, analytics, audio_settings, haptics_settings, scratch, content/, debug playtest, real_play). TRUE.
- "No data collected" draft answers are justified for the current build. Planned SDK sections are labelled unverified / "verify at submission". Everything is DRAFT, nothing claims submission, no secrets.
- Guard test: ran it, `M58 privacy inventory evidence: PASS (7/7 cases, 0 fail)`, ~3 s. Has a scanner self-check; a missing doc entry makes it fail (builder's mutation run documented). CI entry (suite list + exact-summary guard) follows the m56 pattern. TASKS edit is scoped to SB-M58-001..006 with an honest "drafts, pending" caveat.
- Note: running Godot --import in the worktree left .import file modifications (worktree is disposable; discard or delete it).

## Must-fix
1. docs/PRIVACY_DATA_INVENTORY.md line 60 (planned "Local notifications plugin" row) cites SB-M43-171; local notification scheduling is SB-M43-172. Change to SB-M43-172.
2. docs/PRIVACY_DATA_INVENTORY.md line 117 (post_notifications row: "no local-notification plugin, SB-M43-171") has the same wrong cite; change to SB-M43-172. (Line 133, SB-M43-171 for iOS notification authorization, is correct; leave it.)

VERDICT: CHANGES
