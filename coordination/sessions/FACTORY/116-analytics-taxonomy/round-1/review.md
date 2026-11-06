# Review round 1: 116-analytics-taxonomy (SB-M56-001..006)

## Checks
- git diff --check origin/main...HEAD: pass
- tests/m56_analytics_taxonomy.gd: PASS (15/15, 0 fail)
- tests/m43_c003_c001_acquisition.gd: PASS (34/34)
- tests/m28_c002_c001_gameplay_v02.gd: PASS (14/14)

## Strict checks
- No network/provider/SDK: only a RefCounted service with NullSink (default) and MemorySink; no HTTP/SDK code. OK.
- Consent default OFF: `_state.consent=false`; `track()` returns before validation or queueing when off; retention markers and first_day are only written inside `start_session` after the consent check; `set_consent(false)` clears the queue and markers. OK. (`set_consent` writes the small state file only on an explicit call.)
- No PII: param types are limited to int / bool / enum / enum_list; no timestamps or ids; durations and counts are bucketed; the level number is the only int, and it is not PII. OK.
- Failure isolation: all host calls go through `_track`, which is null-guarded. `level_end_params` returns {} without context. The AcquisitionFlow `_track` is null-guarded, and no awaits or blocking were added. The service itself drops invalid events instead of throwing. Calls are write-only and occur after or beside the economy actions; `exit_to_home` and the retry end-event are read-only snapshots taken before the existing logic, with no change of order. OK.
- Call-site order: `_drive_economy_terminal` tracks after `_record_assistance`; `handle_back` reads before `nav.back` and tracks after `on_pre_action_exit`; the retry restores then tracks. Game logic is unchanged. OK.
- Consent file: `user://analytics_v1.json` (tests use `<save>_analytics.json`), separate from the game save, so save import/export neither exports nor overwrites it. Sensible.
- AGENTS.md: a short section pointing to the service, taxonomy and test with usage rules. It is a doc pointer, not an instruction change. OK.
- CI: suite appended to the loop list plus an exact-PASS grep guard in the same pattern as the neighbouring M54 guard. Consistent.

## Must-fix
None.

## Notes (non-blocking)
- `handle_back` on a pre-action exit passes `{}` to `track("level_end")` if the host had no attempt context. With consent on this counts a `dropped` plus a debug warning. Harmless; could skip when empty.
- `_validate` assumes a well-formed shipped config (e.g. `p["min"]`); the config_schema test guards this.

VERDICT: PASS
