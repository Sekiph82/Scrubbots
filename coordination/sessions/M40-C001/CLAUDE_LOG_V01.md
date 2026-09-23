# M40-C001 V01 — Claude Implementation Log (Versioned Save System)

Prompt: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Master batch: `coordination/sessions/M34-M40-BATCH/CHATGPT_MASTER_PROMPT_V01.md`

CRITICAL/STATEFUL. Claude implemented + tested (E1/E2). No self-audit, root
`TASKS.md` not edited. Final implementation milestone of the batch — M41 not started.

## Implementation
- `scripts/save/save_service.gd` — the one canonical SaveSystem.
- Import-contract hardening in `reward_grant_service.gd`, `gift_meter_service.gd`,
  `win_streak_service.gd`, `heart_service.gd`, `robot_unlock_service.gd`: a
  MISSING snapshot section defaults safely; a PRESENT-but-invalid section fails
  closed (SB-M40-012).
- `tests/m40_save_system.gd` — adversarial matrix.

## Schema
- Schema ID: `scrubbots.save`, version `1`.
- Save path: injected (production `user://`); backup `<path>.bak`; temp `<path>.tmp`.
- Strategy: serialize -> temp write -> validate temp -> back up last good ->
  replace. A failed write never corrupts the last valid save.
- Load transaction: read -> parse -> migrate -> validate full candidate on a
  scratch service graph -> apply atomically (capture + restore live on failure).
  Fallback chain: primary -> backup -> new-player defaults.

## Migration table
| from | to | action |
|------|----|--------|
| (no file) | 1 | new-player defaults once (1000 SB, Scrubby unlocked) |
| 0 (or missing sections) | 1 | backfill safe empty economy / default progression / default settings; no double-grant |
| 1 | 1 | load as-is |
| > 1 (future) | — | refused, fail closed, no destructive downgrade |
| legacy `user://audio_settings.cfg` present, no save | 1 | one-time audio value migration into the canonical save |

## Persisted fields (SB-M40-005)
Wallet scrub_bucks + bot_parts; hearts current + regen anchor; unlocked robots;
gift cycle progress/index/queue/claimed; win streak + processed set; first-clear
completed set + frontier; four booster charge counts + pending selected; current-
level 2x entitlement + timed 2x expiry; daily last-claim day + streak; collection
owned counts + per-set + master completion tx ids; RewardGrantService applied tx
ids. No Stars / Event Points / profile-XP economic state (rejected on validate).

## Tests
```
godot --headless --path . -s res://tests/m40_save_system.gd
```
Result: **PASS**. Missing-save defaults, broad round-trip, save/load twice,
crash-before-replace, corrupt-primary+valid-backup, corrupt-both, future-schema
refusal, older-schema migration, missing-economy-fields migration, stale-tx
after reload (no re-grant), wall-clock hearts/timed-2x across relaunch + rollback
+ huge forward jump, daily duplicate-claim resistance, removed-economy rejection.
All isolated `user://` test paths.

Regression: M37/M38/M39 state tests PASS after M40; M33 audio settings + M34
haptics settings persist through the save adapters.

## Task log index
SB-M40-001..013 under `coordination/sessions/M40-C001/task_logs/`.

## Handoff
`AWAITING_AUDIT / M40-C001 V01 / CRITICAL_FULL_SURFACE_AUDIT_REQUIRED`

Root `TASKS.md` was not edited. No audit verdict self-assigned. No M41 work started.
