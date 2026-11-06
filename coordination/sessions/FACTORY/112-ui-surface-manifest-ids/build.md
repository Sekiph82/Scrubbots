STATUS: READY

# Build: SB-M43-169 PLAYER_EXPERIENCE_ASSET_MANIFEST covers every ui_surface_registry id + Rewarded Ads

## Summary
`assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json` now covers every screen/popup id in
`data/config/ui_surface_registry_v1.json` (36 ids) and lists the Rewarded Ads surface (M43-C015
list item 39, TASKS.md). A guard in the existing manifest test fails if any registry id is uncovered.

Design choice: 16 of the 19 missing registry ids are the SAME surfaces the manifest already tracks
under the M43-C015 names (results = victory_results, life = life_heart_refill, error/loading =
generic_error_offline_loading, ...). Instead of duplicating those entries (two statuses for one
surface would drift, and a duplicate "results" entry would sidestep c001b's owner-authority check
on victory_results), each existing entry got an optional `registry_ids` list naming the registry
ids it covers; the manifest `note` documents the field. Only surfaces with no entry at all got new
entries: `home`, `settings`, `rewarded_ads`.

New entries (same schema; recorded_by "factory 112 (Claude) — implementation facts only; no owner visual review recorded"):
- `home` REFERENCE_SELECTED (owner canonical reference `main screen.png` + component inventory in
  assets/ui/HOME_ASSET_MANIFEST.json; same convention as gameplay_v02), scene scripts/ui/home/home_screen.gd, evidence tests/m42_home.gd.
- `settings` MASTER_REQUIRED (native panel, no master), scripts/ui/settings_panel.gd, tests/m41_settings.gd.
- `rewarded_ads` MASTER_REQUIRED, scripts/ui/daily/rewarded_ads_screen.gd, tests/m43_r15_owner_remediation.gd,
  gap "no ad provider yet (M57): video rewards show NO VIDEO and grant nothing; no dedicated visual master".

No status promoted, no OWNER_ACCEPTED/owner review claimed, no art created.

Alias mapping: gameplay_v02->gameplay, victory_results->results, collection_album->collection,
collection_set_detail->collection_set, robots_main->robots, events_main->events,
friends_postlaunch->friends, life_heart_refill->life, speed_2x_acquire->speed_acquire,
generic_reward_confirmation->reward+confirm, standard_pack_open+premium_pack_open->pack_open,
world_unlock_transition->world_unlock, generic_error_offline_loading->error+loading,
account_cloud_sync_conflict->account_conflict, comeback_summary->comeback.

Files changed: assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json, tests/m43_c001b_won_results_visual.gd, TASKS.md.
Commits: 3abf6508 (manifest + test), e59799cf (TASKS.md).

## Acceptance criteria
1. [x] Manifest covers every ui_surface_registry id: python check over screens+popups vs id+registry_ids prints `[]`; Godot case prints `ok: manifest covers every ui_surface_registry id, missing []`.
2. [x] Rewarded Ads surface added as MASTER_REQUIRED with M57 no-provider note: `ok: manifest lists the Rewarded Ads surface`.
3. [x] True statuses, real script/test references, no false owner claims: all referenced scripts/tests exist (home_screen.gd, settings_panel.gd, rewarded_ads_screen.gd, m42_home.gd, m41_settings.gd, m43_r15_owner_remediation.gd).
4. [x] JSON valid: python json.load OK, Godot JSON.parse_string OK; written with the file's existing 2-space indent and CRLF.
5. [x] Static guard extended in the existing manifest test (tests/m43_c001b_won_results_visual.gd, case art_and_manifest_governance), no new framework.
6. [x] TASKS.md queue line DONE + checklist [x] with SHA and evidence.

## Validation
- `$GODOT --headless --path . -s res://tests/m43_c001b_won_results_visual.gd`: exit 0, 0 SCRIPT ERROR/Parse Error, last line `M43-C001B WON results visual evidence: PASS (11/11 cases, 0 fail)` — LOCAL_PASS. (Only test referencing the manifest; no other manifest guard suites exist.)
- `git diff --check`: clean. `--import` churn (.import/.uid/project.godot) reverted in the worktree; tree clean.
- No CI, no phone build (per job instructions).

## Log
### Round 1
Added registry_ids aliases + home/settings/rewarded_ads entries, extended the c001b manifest governance case, ran it LOCAL_PASS 11/11, updated TASKS.md. Note for review: the `registry_ids` alias field deviates from a literal "one new entry per missing id" to avoid duplicate status records for the same surface.
