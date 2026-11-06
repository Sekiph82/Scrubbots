STATUS: READY

# Build: SB-M56-001..006 analytics taxonomy V1 (session, level funnel, retention, assistance, booster)

## Summary
Adds a versioned, privacy-minimized analytics taxonomy and one local analytics seam. There is no provider and no network. The game emits events at the real call sites, but nothing is tracked until consent is granted. Consent is OFF by default until the M58 consent screen exists.

- `data/config/analytics_taxonomy_v1.json` (new): the event catalogue (11 events), param types limited to int / bool / enum / enum_list (no free text), forbidden PII param names, coarse buckets, batch_size 20.
- `scripts/app/analytics_service.gd` (new): `AnalyticsService` with `NullSink` (default) and `MemorySink`. It has a consent gate persisted in a small local file (`user://analytics_v1.json`, never in the game save), schema validation (invalid event = dropped + debug warning, never a crash), batched hand-over, session start/end with a duplicate guard, and local d1/d3/d7/d14/d30 retention markers counted from the first consented day.
- `scripts/app/app_state.gd`: owns `analytics`; forwards FailureAssistanceService `assistance_shown` / `assistance_fail_closed` events.
- `scripts/app/main.gd`: session_start on cold boot and OS resume; session_end on OS pause and close; level_end exit on a pre-action Back; binds analytics into AcquisitionFlow.
- `scripts/gameplay/runtime/production_gameplay_host.gd`: level_start (launch / retry_results / retry_pause), level_first_action, level_end (won / lost / exit / restart), and booster_use from the host facade's `action_committed` / `action_refused`.
- `scripts/ui/popup/acquisition_flow.gd`: booster_acquire (Need a Hand BUY sb, rewarded outcome for Need a Hand / Booster popup) and assist_dismissed (acquired false = declined).
- `scripts/economy/failure_assistance_service.gd`: `shown_level`, which feeds level_end `assisted`.
- `scripts/progression/level_progression_service.gd`: `model_version()` (difficulty metadata version).
- `tests/m56_analytics_taxonomy.gd` (new, 15 cases) and `.github/workflows/android-family-first10.yml` (suite added with an exact 15/15 guard).
- `docs/ANALYTICS_TAXONOMY_V1.md` (new), `AGENTS.md` (short pointer), `TASKS.md` (queue row DONE, SB-M56-001..006 checked).

Commits: 71f6c643 (config + service + tests + CI), d9a992d9 (call sites), faf40000 (docs / tasks). Not pushed.

## Acceptance criteria
1. [x] Versioned event catalogue for the six rows, with typed required/optional params and allowed values, PII rules and coarse buckets: `analytics_taxonomy_v1.json` v1. Case `config_schema` checks every param type is int/bool/enum/enum_list, no forbidden name, all enums and fallbacks resolve, bucket labels match their enums, and the events cover SB-M56-002..006.
2. [x] Analytics service with a pluggable sink (NullSink default, MemorySink for tests): case `defaults_null_sink_consent_off` shows the shipping graph has a NullSink, consent off and the catalogue loaded.
3. [x] Consent gate, default off: case `consent_off_real_paths` runs launch, first action, LOST, Retry, background and foreground with consent off. Result: 0 events, 0 queued, no local state file. `consent_persist_revoke`: consent persists across relaunch; revoking drops the queue and markers.
4. [x] Schema validation (unknown event/param dropped with a debug warning, never a crash): case `invalid_dropped`, 10 malformed events dropped, enum fallback applied, missing catalogue fails closed.
5. [x] Batched, never blocking: case `batching`, 25 events give one batch of 20 handed to the sink and 5 queued until flush or session end.
6. [x] Session start/end at real call sites: case `session_events` uses main.gd OS notifications. Result: background end (30s_2m), duplicate pause ignored, one foreground start, close end (5m_15m).
7. [x] Level funnel start/first action/win/lose/retry/quit at real call sites: cases `level_funnel` and `pause_restart_and_exit` cover launch level_start with difficulty / cadence slot / model version, exactly one level_first_action, level_end lost then won with duration / progress / attempt, retry_results with latency, Pause restart (level_end restart + level_start retry_pause), exit_to_home exit without a duplicate, and pre-action Back exit.
8. [x] Retention markers derived locally: case `retention_markers` gives exactly d1/d3/d7/d14/d30 once each. Also first_attempt / attempts-to-clear / retry_latency / session_end after_level are covered in `level_funnel`.
9. [x] Assistance (Need a Hand): case `assistance` covers assist_shown with the two recommended ids, BUY giving booster_acquire sb/need_a_hand, close giving assist_dismissed acquired true, later WON with assisted true (attempt 4_5), Back close giving acquired false (declined), and assist_fail_closed. Case `booster_acquire_rewarded`: a verified ad gives ok true; a cancelled ad gives ok false.
10. [x] Booster use/charge: case `booster_use` covers +1 Slot success, Tornado fail-closed `color_not_present`, Tornado with a charge giving paid_with charge, and level_end boosters_used equal to the host's committed attempt counter.
11. [x] No PII fields: case `pii_scan` checks every event emitted in the suite carries only declared int/bool/enum params, no real call site produced a dropped event, and every real-path event was emitted at least once.
12. [x] No effect on gameplay/economy: case `no_economy_change` plays the same sequence (LOST, Retry, WON) with consent OFF and ON and gets identical economy and progression snapshots (only the per-profile random card-pack RNG seed is excluded). 200 analytics calls plus a revoke leave economy and progression untouched.
13. [x] Throw-away saves only: every boot uses `boot_save_path_override` temp paths, and cleanup removes the saves and `_analytics.json` files. No `user://m56_*` files are left over.

## Validation
- `godot --headless --path . --import` once. The worktree's `project.godot` was restored after it, and the import churn (`.import` LF rewrites, generated `.uid` / `.translation`) was reverted, so the tree is clean.
- `python tools/run_suites.py m56_analytics_taxonomy m43_c003_c001_acquisition m42_navigation m40_save_system m40_v04_bootstrap m39c_boosters m39_v04_integration m37_level_progression m44_unlock_gate m43_c001a_results_foundation m28_c002_c001_gameplay_v02 m39_v03_integration m55_economy_release_regression m43_master_c010_meta`: aggregate=PASS (14/14), every suite exit 0, diag 0. m56: `M56 analytics taxonomy evidence: PASS (15/15 cases, 0 fail)`. LOCAL_PASS.
- `godot --headless --path . -s res://tests/m43_c004_c001_fail_need_a_hand.gd` (not in the CI list; directly affected): exit 0, `PASS (40/40 cases, 0 fail)`, no SCRIPT ERROR / Parse Error. LOCAL_PASS.
- `python tools/run_suites.py --selftest`: PASS (workflow still parses after the suite was added).
- `git diff --check` on the commits: clean.
- No CI run and no phone build (as instructed).

## Log
### Round 1
- Built the taxonomy config, AnalyticsService, call sites, suite, CI guard, docs and TASKS update as above.
- There was no spec.md in the job folder; the acceptance criteria came from the job prompt and the SB-M56-001..006 rows.
- Design choices:
  - `attempt` = committed WON/LOST terminals on the level (PlayerRecords) + 1, so restarts and exits do not count.
  - Retry entry is classified by the host's latched terminal (`_economy_terminal_done`), not `completion.is_terminal()`, so it also works when the terminal signal is emitted directly.
  - Local retention state is stored only while consent is on.
  - The existing +1 Slot path does not increment the host's attempt booster counter. That is unchanged existing behaviour, and `boosters_used` reports that counter.
- During development, the first m56 runs failed on retry classification (fixed as above) and on a cross-profile card-pack RNG seed difference in the economy parity check. The seed is random per fresh profile and is now excluded with a comment.
