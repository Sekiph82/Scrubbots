# M41-C001 V01 — Early Audio/Haptics Settings UI Prompt

Owner-authorized early slice only:
SB-M41-001 Master volume
SB-M41-002 Music
SB-M41-003 SFX
SB-M41-004 Haptics
SB-M41-006 Persistence
SB-M41-007 Settings UI
SB-M41-008 Relaunch tests

Do NOT implement SB-M41-005 Reduced Effects in this slice unless already trivially present and owner-approved.

Use existing canonical AudioSettingsService, HapticsSettingsService / M40 SaveService integration. Do not create competing persistence.

UI requirements:
- Master slider/toggle
- Music slider/toggle
- SFX slider/toggle
- Haptics toggle
- current values visible
- live apply
- save/load persistence
- relaunch tests
- mobile-safe layout

Create per-task logs under `coordination/sessions/M41-C001/task_logs/` and `CLAUDE_LOG_V01.md`.
Do not edit TASKS.md.

Handoff:
`AWAITING_AUDIT / M41-C001 V01 / SETTINGS_OWNER_F6_REQUIRED`