STATUS: READY

# Build: Worlds table (SB-M43-136..141, SB-M43-073, SB-M54-032)

## Summary
The owner world table (TASKS.md SB-M43-136, 2026-10-22) is now data. `data/config/worlds_v1.json` (schema `scrubbots.worlds.v1`) lists 20 worlds x 150 levels = 3000. Each world has an id, a number, the owner's English name, a first..last level range and an art ref. World 01 points at its real art. Worlds 2-20 have `art: null` and fall back to `fallback_art` (the World 01 art), shown with the world's name.

`scripts/progression/world_service.gd` is pure logic. It provides `load_table`, `load_worlds`, `world_for_level`, `world_by_id`, `next_world`, `is_world_complete`, `progress` and `states`. A table with a gap or overlap, one that doesn't cover 1..last_level, or one with bad fields fails closed to `[]`. It replaces the unused `world_registry.gd` (tests only), which kept ranges in `home_worlds_v1.json`; that file is deleted.

Live trigger: `CeremonyPresenter.world_events()` adds one `world_unlock` event (key `world:<id>`) once the frontier has passed a world's last level and the next world's first level is in the playable catalog (`AppState.catalog_has_level`). The event is acknowledged through MetaUiState (the same path as the other ceremonies), so it survives relaunch and cloud import. It only covers the current world, so an imported save far ahead gets no backlog. It grants nothing, because no owner-approved world reward exists. With 30 shipped levels nothing triggers in production.

Turkish names are `UiTextTr.DATA` `WORLD_NAME_1..20`, read with `UiText.data()`. The subtitle reuses `HOME_AREA_NUMBER` ("AREA %d" / "BÖLGE %d").

Home: there is no native world label. "WHISPERING PARK / AREA 1" is baked into the World 01 background, so per the job's "if such a label exists" Home is unchanged.

Files: data/config/worlds_v1.json (new), scripts/progression/world_service.gd (new), scripts/progression/world_registry.gd (deleted), scripts/app/app_state.gd, scripts/ui/ceremony/ceremony_presenter.gd, scripts/ui/ceremony/meta_ceremonies.gd (world_unlock doc comment only), scripts/ui/ui_text_tr.gd, scripts/ui/home/home_world_catalog.gd (comment), data/config/home_worlds_v1.json (notes), tests/m54_world_regression.gd (new), tests/m43_master_c011_c014.gd (w01..w04 now on WorldService), tests/m51_localization_readiness.gd (world names in the DATA count), .github/workflows/android-family-first10.yml (suite + exact 7/7 guard), TASKS.md.

Commits: 8f8ea175 (data + service + tests), 90c54b86 (trigger + CI), 00479875 (TASKS.md).

## Acceptance criteria
1. [x] worlds_v1.json, versioned, has 20 worlds with id, owner EN name, ranges 1-150 .. 2851-3000 and art refs (World 01 real, others null -> World 01 fallback). Evidence: m54 r01 "20 worlds, owner names, ranges", "World 10 Sunken Harbor 1351-1500 == factory 107 art manifest", "World 01 real art; worlds 2-20 no art yet -> World 01 fallback (exists)".
2. [x] TR names via UiText keys. Evidence: m54 r05 (TR "Fısıltılı Park", "Batık Liman", 20 non-English); m51 l05 counts the WORLD_NAME_n DATA entries (8/8).
3. [x] WorldService: world_for_level, progress, is_world_complete, next_world, plus validation (contiguous, non-overlapping, covers 1..3000). Evidence: m54 r02 (13 bad tables -> []), r03, r04.
4. [x] Live trigger fires once when the last level of a world is first-cleared and the next world is in the catalog, persisted and idempotent across relaunch and import, with no economy change. Evidence: m54 r06 (frontier 150 -> none; shipped 30-level catalog -> none; injected catalog -> one "Bubble District" event; popup opens; after CONTINUE never pending again; economy (minus the ack), progression, personal rank and events unchanged) and r07 (relaunch before/after CONTINUE, import of acked/unacked saves, frontier 301 -> only World 03).
5. [x] Home shows the current world name where a World 01 label exists: no native label exists (the title is baked art), so nothing changed. No layout redesign.
6. [x] SB-M54-032 regression: every n in 1..3000, boundaries 150/151, 2850/2851, 3000 (and 0/-1/3001), ceremony once, relaunch/import idempotent, Ranks/Events unaffected. Evidence: m54 r03/r06/r07.
7. [x] Fast suite added to CI: appended to the suite loop line, with a comment line and an exact guard `M54 world regression evidence: PASS (7/7 cases, 0 fail)`.

## Validation
All runs were local Godot 4.7.2 headless, using `python tools/run_suites.py` (the CI rule: exit 0, no script diagnostics, last line PASS). LOCAL_PASS:
- m54_world_regression 7/7 (new)
- m43_master_c011_c014 29/29
- m51_localization_readiness 8/8
- m43_master_c005_meta_ceremonies 32/32
- m43_c005f_phase6_unlock_feel 8/8
- m43_c005_c072_feature_unlock_ceremony 9/9
- m43_personal_ranks 8/8
- m43_c001a_results_foundation 11/11
- m54_regression_pack_028_036 12/12
- m43_master_c010_meta 12/12
- run directly (not in the CI list): sb_video_009_polish_011b_region_need_a_hand_video 7/7, m42_home_v04 18/18 (0 failures, 0 diagnostics)

Other checks:
- `git diff --check` on the changed paths: clean.
- The `--import` churn (.import/.uid/.translation files, project.godot) was restored or removed, and the tree is clean.
- No CI run, no phone build.

## Log
### Round 1
- Built the data, the service, the trigger, the TR names and the CI suite as above.
- Retired WorldRegistry instead of keeping two world truths, and moved its 4 cases in m43_master_c011_c014 (same case ids) to WorldService.
- Trigger decision: the event is derived from the frontier, not from `is_completed(last)`, so a CP06-skipped last level still opens the next world. It covers the current world only, so imports get no backlog.
- SB-M43-138 (approved art for every world) stays open in TASKS.md: no art was produced, and worlds 2-20 use the World 01 fallback.
- SB-M43-141 is marked done because the world is derived from the frontier and never stored. Note for review: Home still shows the World 01 background (with its baked sign) for every world, because no other world art exists.
