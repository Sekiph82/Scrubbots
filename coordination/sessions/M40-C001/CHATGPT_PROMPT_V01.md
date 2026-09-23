# M40-C001 V01 — Versioned Save System Master Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M40-001..SB-M40-013`

Read first:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- M33 audio settings implementation
- M34 haptics implementation produced in this batch
- M37 progression implementation
- M38 streak implementation
- M39 economy implementation and every M39 task log

## Batch end rule
M40 is the final implementation milestone of the owner-authorized overnight batch.
Implement/test/commit/push M40 completely.
Do NOT self-audit or edit root `TASKS.md`.
At the end, produce all task logs + canonical M40 log and stop at AWAITING_AUDIT for the entire batch.

## Implement one canonical SaveSystem
Suggested path:
`scripts/save/save_service.gd`
with supporting schema/migration/validation helpers as needed.

The service must:
1. own the versioned save-file lifecycle, not gameplay/economy truth;
2. collect immutable snapshots from M33/M34/M37/M38/M39 services;
3. validate snapshots before writing;
4. use safe temp + replace + backup strategy;
5. parse/migrate/validate a complete candidate before applying;
6. apply through narrow service import methods;
7. never partially import corrupt data;
8. support deterministic test paths;
9. keep UI/presentation transient state out of canonical save.

## Schema
Create explicit schema ID/version and document every field.
Persist all M40 criteria fields.
Do not persist deprecated Star/Event/profile-XP economy.
Do not persist transient agents/routes/FX/audio voices.

## Settings integration
Do not create two competing authorities.
Integrate current M33 audio settings and M34 haptics setting through snapshot/import adapters.
If existing `audio_settings.cfg` needs migration, implement a one-time compatibility path and tests.
M41 UI is out of scope.

## Safe write / recovery
Use a validated temp file and atomic/near-atomic replacement strategy supported by Godot/filesystem APIs.
Keep/recover last-known-good backup.
Inject write/rename failures in tests.
A failed save must leave previous valid save recoverable.

## Migration
Implement at least:
- missing save -> new-player defaults once
- old save missing Economy V1 fields -> safe defaults without duplicate grant
- prior settings/progression preserved
- future schema -> explicit unsupported/fail closed
- no Stars/Event balances invented

## Wall-clock safety
Heart regen, timed 2x and Daily claim timestamps must survive relaunch and resist rollback/duplicate-claim behavior.
Do not derive wall-clock state from gameplay delta/time_scale.

## Mandatory per-task logs
Create 13 separate files:
`coordination/sessions/M40-C001/task_logs/SB-M40-001.md`
through `SB-M40-013.md`.

Every task log includes requirement, schema/service ownership, changed files, direct tests, expected/failure condition, actual result, migration/rollback notes, commit evidence.

Create canonical:
`coordination/sessions/M40-C001/CLAUDE_LOG_V01.md`
indexing all 13 logs and recording:
- implementation SHA(s)
- schema version
- save path + backup/temp strategy
- migration table
- test commands/results
- M34..M40 batch dependency status
- blockers/unverified assumptions
- confirmation root TASKS.md was not edited

## Final integration validation
Run fresh-process round trips for progression + streak + full Economy V1.
Run corruption/backup/migration matrix.
Run root suite and required M37-M39 regressions.
Use only test paths.

## Git
Preserve owner work. No destructive reset/clean/force push.
Commit implementation/tests first, docs/evidence second.
Push all M40 work and verify GitHub URLs exist.

Final M40 log handoff:
`AWAITING_AUDIT / M40-C001 V01 / CRITICAL_FULL_SURFACE_AUDIT_REQUIRED`

Then write no more production code. Return the overnight batch completion response required by the master pipeline.