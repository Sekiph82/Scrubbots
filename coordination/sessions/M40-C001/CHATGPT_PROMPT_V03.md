# M40-C001 V03 — Canonical App Persistence Remediation

Read:
- CHATGPT_AUDIT_V02.md
- CHATGPT_AUDIT_CRITERIA_V03.md
- post-M37 V03 log
- post-M39 V03 log
- AUDIT_INDEX.md

Do not start M40 V03 final integration until M39 V03 is pushed.

Close F-M40-V02-001..009.

## Phase 1 — app-level canonical state composition
Create one production app-level state/persistence composition root (autoload or equivalent) owning:
AudioSettingsService, HapticsSettingsService, LevelProgressionService, EconomyServices, SaveService.

Use one canonical default user:// save path.

ProductionGameplayHost consumes this graph instead of creating a duplicate graph.
Tests/debug can inject isolated graphs and paths.

## Phase 2 — startup/load policy
Load before durable state is consumed.
Check load result.
Future schema blocks normal gameplay and remains preserved.
Missing/corrupt-without-backup follows documented safe-default policy.

Bind loaded current frontier to actual catalog/content identity.
If content is missing, fail safely rather than running stale level_path under a different progression number.

## Phase 3 — migration/settings hardening
Validate raw schema version exactly before migration.
Add 0.5/string/NaN/INF tests.

Make haptics canonical import strict and success-returning.
Malformed haptics invalidates the full save.

Stop production dual-loading of audio/haptics side files.
Keep legacy files only as one-time migration input when no canonical save exists.

## Phase 4 — durable save coordinator
Add dirty/coalesced explicit save boundaries for durable meta mutations and app lifecycle:
terminal, purchases, Daily/Gift/Collection claims, exchange, unlocks, settings, background/quit.

Do not save every frame.

Expose a narrow request_save/mark_dirty contract future M41/M42 UI can call without owning persistence.

## Phase 5 — post-M39 full schema sweep
Re-enumerate durable state after M39 V03.
Add malformed nested full-save fixtures for every V03 state boundary.
Keep +1 Slot attempt capacity transient.

## Evidence
Create task_logs_v03 for affected M40 tasks:
001,002,003,005,008,009,010,011,012,013
and any additional task directly touched.

Create `coordination/sessions/M40-C001/CLAUDE_LOG_V03.md` with:
- F-M40-V02-001..009 closure table;
- schema field inventory;
- startup/save-boundary map;
- exact tests/results;
- implementation/log SHAs.

Do not edit TASKS.md.
Do not self-audit.
Do not start M41+ as part of this remediation.

Handoff:
`AWAITING_AUDIT / M40-C001 V03 / FULL_SURFACE_REAUDIT_REQUIRED`
