# Analytics Taxonomy V1 (SB-M56-001..006)

Machine source: `data/config/analytics_taxonomy_v1.json` (schema `scrubbots.analytics_taxonomy.v1`, version 1).
Service: `scripts/app/analytics_service.gd`, owned by `AppState.analytics`.
Tests: `tests/m56_analytics_taxonomy.gd` (CI validate, exact 15/15 guard).

## Rules

- **No provider, no network.** The default sink is `NullSink` (drops everything). `MemorySink` exists for tests. A real provider is a later, owner-approved sink (CLAUDE.md §3.6, §0D.5); it must keep these rules.
- **Consent gate.** Nothing is validated, queued or stored until `AnalyticsService.set_consent(true)`. Default is OFF until the M58 consent screen exists (SB-M58-008). Revoking consent drops the queue and the local retention markers.
- **Privacy-minimized.** Params are only `int`, `bool`, `enum` or `enum_list`. There is no free-text type, so no names, emails, device or advertising ids, tokens, receipts, board or save data can be sent. `privacy.forbidden_param_names` lists names that may never be declared. Times and counts go out as coarse buckets (`buckets` table). No timestamps or ids are added to events. Each event carries only `event`, `v` (taxonomy version) and `params`.
- **Schema validation.** An unknown event, an undeclared param, a wrong type, an out-of-range int, a disallowed enum value or a missing required param drops the whole event and prints a debug-build warning. An enum with a `fallback` maps unknown values to the fallback (`other` / `UNKNOWN`). A missing or invalid taxonomy file drops everything. Validation never crashes.
- **Write-only.** No gameplay, economy, difficulty, solver or save code reads analytics. Events never grant rewards or change difficulty. Offline play never depends on them (SB-M56-014).
- **Batched.** Events are queued and handed to the sink in batches of `batch_size` (20), and at session end. They are never sent per frame.
- **Local state.** `user://analytics_v1.json` (tests: `<save>_analytics.json`) holds only `consent`, the first consented local day and the retention markers already sent. It is not part of the game save.

## Buckets

| Table | Labels |
|---|---|
| `duration_s` -> `duration` | lt_30s, 30s_2m, 2m_5m, 5m_15m, 15m_60m, gt_60m |
| `attempt` | 1, 2, 3, 4_5, 6_10, gt_10 |
| `count` | 0, 1, 2, 3_5, gt_5 |
| `progress_pct` -> `progress` | 0_25, 25_50, 50_75, 75_90, 90_100 |

## Events

| Event | Task | Call site | Params |
|---|---|---|---|
| `session_start` | 002 | `main.gd` `_boot` (cold_start), `NOTIFICATION_APPLICATION_RESUMED` (foreground) | trigger |
| `session_end` | 002, 004 | `main.gd` `NOTIFICATION_APPLICATION_PAUSED` (background), `NOTIFICATION_WM_CLOSE_REQUEST` (close) | trigger, duration, after_level (none / won / lost / exit / restart: abandonment after a level) |
| `retention_day` | 004 | `AnalyticsService.start_session` | day (d1 / d3 / d7 / d14 / d30 local days after the first consented session, each sent once) |
| `level_start` | 003, 004 | `ProductionGameplayHost.build` (launch), `_on_retry_restored` (retry_results / retry_pause) | level, progression, entry, attempt, retry_latency (Retry from Results only: time since the terminal), difficulty, cadence_slot, difficulty_model |
| `level_first_action` | 003 | host `_on_activation_event` (first accepted supply activation of the attempt) | level, attempt, elapsed |
| `level_end` | 003, 004, 005 | host terminal (won / lost), Pause Restart (restart), `exit_to_home` and pre-action Back (exit) | level, outcome, progression, attempt, first_attempt, duration, progress (cleared share of the artwork), boosters_used, assisted (Need a Hand was shown for this level this session), difficulty, cadence_slot, difficulty_model |
| `assist_shown` | 005 | `FailureAssistanceService.note_shown` via `AppState` | level, boosters (the two recommended booster ids) |
| `assist_fail_closed` | 005 | `FailureAssistanceService.note_fail_closed` via `AppState` | level, reason |
| `assist_dismissed` | 005 | `AcquisitionFlow` Need a Hand `closed` | level, acquired (false = declined) |
| `booster_acquire` | 005, 006 | `AcquisitionFlow`: Need a Hand BUY (sb), rewarded outcome for Need a Hand / Booster popup | booster, path (sb / rewarded), source (need_a_hand / booster_popup), ok |
| `booster_use` | 006 | host facade `action_committed` / `action_refused` for the four boosters | booster, ok, paid_with (charge / sb, when the service reports it), reason (ok or the fail-closed reason), level, attempt, difficulty |

Definitions:

- `attempt`: committed WON/LOST terminals on this level (`PlayerRecords.attempts_on_level`) + 1. Restarts and exits do not count. Replays count from 1. On a WON, it is attempts-to-clear; `first_attempt` is attempt 1.
- `difficulty` / `cadence_slot`: the Difficulty V1 cadence class and slot of the level number. `difficulty_model` is the progression config version. Recovery-level performance is `level_end` filtered by a recovery slot after a peak.
- `progression`: the attempt was on the canonical frontier.

Not in V1 (later M56 rows): economy, collection, navigation, ads/store, events/ranks, notifications (SB-M56-007..012, 017..023), dashboard definitions (013) and the provider consent/age gating (015, with M58).
