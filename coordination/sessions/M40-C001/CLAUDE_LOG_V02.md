# M40-C001 V02 — Claude Save-System Safety & Bootstrap Remediation Log

V01 audit: `coordination/sessions/M40-C001/CHATGPT_AUDIT_V01.md`
(`CHANGES_REQUIRED / FINDING_SET_FROZEN`, F-M40-001..007)
V02 prompt: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Run after M39 V02 (post-M39 schema/state graph).

## Finding-by-finding closure

| Finding | Status | Fix |
|---------|--------|-----|
| F-M40-001 atomic replace | CLOSED | `save()` writes a validated temp then `DirAccess.rename_absolute` over the primary (near-atomic), freeing the primary path first so no truncating second write occurs. Platform note: rename replaces on POSIX; the primary is removed/rotated before rename so it also succeeds where rename() refuses an existing destination (Windows). |
| F-M40-002 backup protection | CLOSED | Backup rotates ONLY from a fully re-validated existing primary; a corrupt/unvalidated primary is discarded, never rotated into `.bak`. Every I/O result is checked. Fault injection at temp_write / temp_validate / backup_rotate / primary_replace proves the last valid save survives. |
| F-M40-003 future schema | CLOSED | `load()` returns `{ok:false, source:"future_schema"}` for a future-version primary with no compatible backup (no fresh-profile fall-through); `save()` refuses with `would_overwrite_future_schema`; the future file is preserved on disk. |
| F-M40-004 strict integer types | CLOSED | Schema `version` via `IntDomain.exact_int`; all integer-only economy fields reject fractional/NaN/INF through the M39-V02-hardened service imports. |
| F-M40-005 daily task persistence | CLOSED | `DailyService.snapshot/import` (M39 V02) persist current-day `tasks_done` + `tasks_claimed_day`; carried in the aggregate save and proven by round trip. |
| F-M40-006 bootstrap lifecycle | CLOSED | `ProductionGameplayHost` instantiates ONE canonical `SaveService` when `save_path` is set, LOADS at build (before gameplay consumes economy/progression/settings), and SAVES at the terminal boundary (not per-frame). Empty `save_path` keeps the host disk-free for tests/suite. |
| F-M40-007 post-M39 completeness | CLOSED | Save aggregates the hardened M39-V02 `EconomyServices.snapshot` (daily task state, boosters, hearts anchor, speed expiry, collection tx ids, etc.). The transient +1 slot capacity is attempt-scoped in the engine and NOT persisted as permanent base. |

## Files
- `scripts/save/save_service.gd` (safe temp->rename replace, backup protection,
  future-schema block, exact-int version, `_rename` helper)
- `scripts/gameplay/runtime/production_gameplay_host.gd` (canonical SaveService
  bootstrap: `save_path`, load-before-consume, terminal save, `get_save()`)
- `tests/m40_v02_safety.gd` (new adversarial suite)
- `tests/m40_save_system.gd` (V01 suite updated to the V02 future-schema policy +
  `primary_replace` fault stage)

## Tests (all PASS)
- `tests/m40_v02_safety.gd` — atomic replace + backup protection (corrupt primary
  never poisons the good backup), future-schema explicit unsupported + overwrite
  refusal + file preserved, fractional schema rejected, fault injection at every
  write/rotate stage preserves the last valid save, real host bootstrap
  load-before-consume + terminal-save round trip.
- Regression: `tests/m40_save_system.gd` PASS; `m37_v02_strict`, `m38_v02_strict`,
  `m39_v02_atomicity`, `m39_v02_integration` PASS; root suite **5336 / 0**.

## Task logs
`coordination/sessions/M40-C001/task_logs_v02/SB-M40-001,002,005,006,008,009,010,011,012,013`.

## Handoff
`AWAITING_AUDIT / M40-C001 V02 / STRICT_V2_REAUDIT_REQUIRED`

Root `TASKS.md` not edited. No self-audit. No M41 work.
