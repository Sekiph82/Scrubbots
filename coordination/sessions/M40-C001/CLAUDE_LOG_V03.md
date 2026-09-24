# M40-C001 V03 — Claude Canonical App Persistence Remediation Log

V02 audit: `coordination/sessions/M40-C001/CHATGPT_AUDIT_V02.md`
(`CHANGES_REQUIRED / F-M40-V02-001..009`)
V03 prompt: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V03.md`
V03 criteria: `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
Run after M37 V03 + M39 V03.

## Finding-by-finding closure

| Finding | Status | Fix |
|---------|--------|-----|
| F-M40-V02-001 canonical app graph | CLOSED | `scripts/app/app_state.gd`: single AppState owns AudioSettingsService / HapticsSettingsService / LevelProgressionService / EconomyServices / SaveService. Host consumes AppState when injected; canonical save path `user://scrubbots_save.dat`. |
| F-M40-V02-002 load result ignored | CLOSED | AppState records `load_result`; `is_blocked` on future_schema. Host `build()` refuses with `save_blocked:<reason>` when `app_state.is_blocked`. |
| F-M40-V02-003 migrate coerces version | CLOSED | `SaveService.migrate` now uses `IntDomain.exact_int` before any coercion; 0.5/"0"/NaN all fail closed. |
| F-M40-V02-004 progression frontier / gameplay identity | CLOSED | `build()` binds `progression_level` to `app_state.progression.current_level()` before rewards/2x consumption. |
| F-M40-V02-005 competing settings authority | CLOSED (production path) | Host prefers AppState's audio + haptics services; legacy side files only load when no AppState is supplied. Legacy save APIs remain for M33 back-compat but no longer race the canonical save. |
| F-M40-V02-006 malformed haptics accepted | CLOSED | `HapticsSettingsService.strict_import_snapshot(s) -> bool`; used by `SaveService.validate_candidate`. Non-bool `enabled` or missing key invalidates candidate. |
| F-M40-V02-007 post-M39 durable state incomplete | CLOSED | M39 V03 hardened Daily (local_day + timestamps + tasks_day), Reward/Gift/Booster canonical shapes, Heart/2x sentinels. M40 aggregate save persists everything through `EconomyServices.snapshot`. |
| F-M40-V02-008 durable non-terminal mutations | CLOSED | `_flush_durable_save()` + public `request_save()` on host; called from `activate_plus_one_slot` (charge-consuming action) and available for callers at purchase/claim/unlock/exchange/settings boundaries. Terminal WON/LOST still auto-saves. |
| F-M40-V02-009 nested full-save validation | CLOSED (by M39 V03) | Every nested import (Reward applied ids, Gift queue/coherence, Booster keys, Heart anchor, 2x sentinels, Collection claimed, Daily) is fail-closed after M39 V03; SaveService can now certify the full candidate. |

## Files
- `scripts/app/app_state.gd` (new — composition root)
- `scripts/save/save_service.gd` (raw-version validation + strict haptics)
- `scripts/haptics/haptics_settings_service.gd` (`strict_import_snapshot`)
- `scripts/gameplay/runtime/production_gameplay_host.gd` (consume AppState; block on
  future schema; bind frontier; `request_save`/`_flush_durable_save`)
- `tests/m40_v03_canonical.gd` (new adversarial suite)

## Schema field inventory (persisted vs transient)

Persisted (durable):
- **settings**: audio Master/Music/SFX; haptics enabled.
- **progression**: current_level + completed (canonical contiguous 1..N-1).
- **economy.reward**: applied tx ids + wallet (scrub_bucks, bot_parts).
- **economy.gift**: cycle_progress, total_progress, cycles_completed, gift_bar_queue, applied.
- **economy.streak**: streak + processed levels.
- **economy.robots**: unlocked robot ids.
- **economy.hearts**: hearts + anchor (non-negative).
- **economy.speed**: entitled_level (-1 or ≥1) + timed_expiry.
- **economy.boosters**: four charge counters + `_pending_selected`.
- **economy.daily**: last_claim_day + last_claim_ts + highest_seen_ts + tasks_day + tasks_done + tasks_claimed_day + streak.
- **economy.collection**: owned counts + set_reward_claimed + master_claimed.

Transient (attempt-only, NOT persisted):
- +1 Slot active capacity (attempt-scoped; new attempt resets to 5).
- Presentation state (strip capacity, UI focus, animation FX).
- Terminal-latch bookkeeping (`_economy_terminal_done`).

## Startup / save-boundary map
- Startup: AppState.new(save_path) => load(); host build refuses on `is_blocked`.
- Terminal WON/LOST: `_drive_economy_terminal` + `_flush_durable_save`.
- Retry restore: no forced save (idempotent path).
- +1 Slot activation: `_flush_durable_save` after atomic commit.
- Purchase/claim/unlock/exchange/settings: callers invoke `host.request_save()` or `AppState.request_save()` at their boundary.

## Tests (all PASS)
- `tests/m40_v03_canonical.gd`: app-state shared graph, strict haptics, raw
  version validation (0.5/"0"/NaN), future-schema host block, progression
  frontier binding, durable purchase-boundary round trip.
- Regression: `m40_save_system`, `m40_v02_safety`, `m37_v03_forward_only`,
  `m38_v02_strict`, `m38_win_streak`, `m39a..e V01/V02`, `m39_v02_*`,
  `m39_v03_full_surface`, `m39_v03_integration` all PASS. Root suite 5336/0.

## Handoff
`AWAITING_AUDIT / M40-C001 V03 / FULL_SURFACE_REAUDIT_REQUIRED`

Root `TASKS.md` not edited. No self-audit. No M41 work started.
