STATUS: READY

# Build: Release gates audit (SB-M60-001..006, SB-M43-170)

## Summary
A new suite `tests/m60_release_gates.gd` computes the release gates on the real app root (main.tscn, throw-away saves) and from the surface manifest and registry. It then checks the committed `docs/RELEASE_GATES.json` against what it computed: every gate verdict, release_ready, the M43 closure state and its surface id lists must match. If only evidence text differs, it prints a "run -- --write" hint and does not fail (round 2). To regenerate, run `-s res://tests/m60_release_gates.gd -- --write`. If a gate is FAIL, BLOCKED or OPEN, the report says so and the suite still passes. The suite fails when a verdict or list is stale, or when a case does not complete. So a broken route turns its gate from PASS to FAIL, and the committed report then no longer matches. The suite is appended to the CI suite list.

Computed result (no gate is faked):
- SB-M60-001 PASS: all 14 enabled Home buttons, 9 notification deep links, the gameplay HUD (Pause, 2x, 4 boosters), the zero-Hearts PLAY and the Results CLEAN NEXT / RETRY / HOME buttons each land on a live surface. All 27 registry routes reach their registry destination. No shipping script reaches a debug scene or debug UI script.
- SB-M60-002 PASS (production-bound part): 40 surfaces are bound to live data with an existing evidence suite; 2 are explicitly not built (world_unlock_transition became live with factory 133). Every registry id is covered, and the English table has no placeholder copy. Owner approval stays open (SB-M43-170).
- SB-M60-003 PASS: on a brand-new save with the shipping FTUE and Level Intro policy, the first Home shows the DAILY tip. The Welcome task is claimed through the TASKS popup (1000 -> 1100). L1..L3 are won by RealPlayDriver on the shipped host via the Results buttons, and the player ends at Home on L4 with the FTUE closed. No test unlock or debug tool is used.
- SB-M60-004 PASS: with the default provider (no SDK), every store, ad and IAP offer shows an honest UNAVAILABLE / store-later / NO VIDEO state. Pressing these offers grants nothing and charges nothing.
- SB-M60-005 FAIL: Events L30 and Ranks L40 are enforced on real frontier 29/30/39/40 saves, and Ranks count only cleared levels. The owner's two-table RANKS (all-time + weekly) is not built (SB-M43-131..133 READY).
- SB-M60-006 FAIL: M50..M59 rows are still open and there was no release-candidate CI run.
- BLOCKED (owner): signing secrets (`gh secret list` shows only ANDROID_DEBUG_*), store submission, owner visual sign-off and device tests.
- SB-M43-170 OPEN: 42/42 surfaces are not OWNER_ACCEPTED and 32 are MASTER_REQUIRED. Not built: account_cloud_sync_conflict and friends_postlaunch. Not live: none. Debug-only: none.

Fixes (data only, no UI code needed):
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`: implementation facts re-verified, statuses unchanged.
  - level_intro and ranks were recorded as "not implemented" but are live now.
  - feature_unlock is live (SB-M43-072 suite).
  - The pack ceremony scene paths now point at real scripts.
  - 19 evidence pointers referenced folders deleted by the SB-M22-030 cleanup; they now point at the suites that test those surfaces.
  - world_unlock gap: no live trigger.
  - insufficient_sb now covers the scrub_bucks registry id.
- `data/config/ui_surface_registry_v1.json`:
  - home.scrub_bucks_plus now leads to the scrub_bucks popup (it has opened that popup since SB-POLISH-006, not the Shop).
  - Added the rewarded_ads, scrub_bucks and cards_exchange ids (cards_exchange was already a route destination).
  - Added the routes home.gift_meter, home.rewarded_ads, home.play and results.clean_next / retry / home.
- `.github/workflows/android-family-first10.yml`: `m60_release_gates` appended to the suite list line.

Files: tests/m60_release_gates.gd (new), docs/RELEASE_GATES.md (new), docs/RELEASE_GATES.json (new), assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json, data/config/ui_surface_registry_v1.json, .github/workflows/android-family-first10.yml, TASKS.md.
Commits (after the round-2 rebase on origin/main fb72fa05): 194aece2 (suite + report + fixes), bacf80ca (TASKS.md), e6da4145 (round 2: verdict-only check, provenance, World Transition), 91761977 (TASKS.md hashes).

## Acceptance criteria
1. [x] 001 no dead routes: `m60_release_gates` g001: home_buttons, nav_tabs_live, deep_links, gameplay_hud, results_buttons, registry_routes and no_debug_surface all PASS (see docs/RELEASE_GATES.md SB-M60-001).
2. [x] 002 bound surfaces + no placeholder data: g002 manifest_bound (40 bound / 2 not built / 0 broken), registry_covered and no_placeholder_copy all PASS.
3. [x] 003 fresh-save FTUE without debug tools: g003 first_home, welcome_task, l1_l3_real_play and no_debug_tools all PASS.
4. [x] 004 Shop with provider disabled: g004 no_provider, shop_store_gated, sb_plus_gated, life_video_gated, rewarded_ads_gated and nothing_charged all PASS.
5. [x] 005 Events/Ranks policy checked: unlock_table, unlock_edges and ranks_metric PASS. ranks_two_tables is reported FAIL honestly because weekly/all-time RANKS is not built.
6. [x] 006 machine-readable gate summary: docs/RELEASE_GATES.json + .md list every gate as PASS/FAIL/BLOCKED with evidence, including the owner-only gates as BLOCKED (owner). g006 fails the suite if a verdict, the closure state or a closure id list in the JSON differs from the computed result; text-only drift prints a hint.
7. [x] SB-M43-170 closure gate computed from the manifest: OPEN, with the full not-accepted, MASTER_REQUIRED, not-built and not-live lists in the report and on the TASKS row. Nothing is marked accepted. The queue row is OWNER (it closes only after the masters + owner visual review).
8. [x] TASKS.md: SB-M60-001/003/004 checked off with SHA + evidence. SB-M60-002/005/006 and SB-M43-170 annotated. Both queue rows are set to OWNER with the computed state.

## Validation
- `python tools/run_suites.py m60_release_gates` (CI rule): status=PASS exit=0 diag=0, `M60 release gates evidence: PASS (6/6 cases, 0 fail)` (LOCAL_PASS).
- `$GODOT --headless --path . -s res://tests/m43_c001b_won_results_visual.gd` (manifest governance + registry coverage): exit 0, 0 diag, PASS 11/11 (LOCAL_PASS).
- `$GODOT --headless --path . -s res://tests/m49_surface_matrix.gd` (manifest ids ledger): exit 0, 0 diag, PASS 3/3 (LOCAL_PASS).
- `-- --write` run regenerated the report and exited 0. A verify run without `--write` on the committed files passes (run_suites line above).
- `git diff --check` on the changed files: clean. `--import` churn (project.godot, .import, .uid, csv .translation) reverted; `git status --porcelain` is empty.
- No CI run, no workflow run, no phone build, nothing pushed.

## Validation (round 2)
- Rebased onto origin/main (fb72fa05, factory 133 worlds). The only conflict was the CI suite list line; the resolved line ends `m43_172_local_notifications m54_world_regression m60_release_gates; do`.
- Before `--write`, the verify run correctly FAILED: the not_live list changed because world_unlock_transition is now live. That shows a list change fails the suite.
- `-- --write` exited 0.
- Drift test: after editing evidence text in docs/RELEASE_GATES.json, the suite still PASSED 6/6 and printed the hint. The files were then restored.
- `python tools/run_suites.py m60_release_gates m54_world_regression`: both PASS (6/6, 7/7), diag 0 (LOCAL_PASS).
- `m43_c001b_won_results_visual`: exit 0, diag 0, PASS 11/11 (LOCAL_PASS).
- Import churn reverted; `git status --porcelain` is empty. Nothing pushed.

## Log
### Round 1
Built the gate suite and report, fixed stale manifest implementation facts and registry route drift that the gates exposed, and appended the suite to the CI list. Ran m60 / c001b / m49_surface_matrix LOCAL_PASS and updated TASKS.md.

Notes for review:
- The suite runs ~10 app boots plus a real L1..L3 play (about 2 min locally).
- The report also embeds manifest statuses. When another job changes a manifest status, m60 fails until someone runs `-- --write`. That is intended: the report must never go stale.
- The g001 Results walk emits the host's completion terminal (the same seam as m42_navigation / m43_c004). Real wins are covered by g003.
- §0D.1 says pending owner visual sign-offs are GIVEN. The job brief keeps the M43 closure gated on owner visual review, so the report lists that gate as BLOCKED (owner). The automated part of the gate is open anyway, because 32 surfaces still have no master.

### Round 2
Review round-1 VERDICT CHANGES:
- Must-fix 1 (recorded_by provenance overwritten): fixed. Every entry whose recorded_by I had replaced now keeps its original text, with the factory 132 note appended after "; ".
  - This covers profile, achievements and events_main ("factory 075 (Claude): master approved by Claude under owner-delegated authority 2026-10-31, not owner visual review").
  - It also covers the 22 "M43 master V01 ..." entries.
  - event_detail was never touched.
- Design concern (CI red on every manifest change): fixed. g006 now compares only per-gate status, release_ready, the closure state and the not_owner_accepted / master_required / not_built / not_live / debug_only lists against docs/RELEASE_GATES.json. Narrative or evidence drift in the .json / .md prints a "run -- --write" hint and does not fail. A changed manifest status still changes the not_owner_accepted list, so that case does fail; this matches the coordinator's spec ("id lists").
- Coordinator: rebased onto origin/main with factory 133.
  - world_unlock_transition is now recorded as built and live: CeremonyPresenter trigger, evidence tests/m54_world_regression.gd. Its status stays MASTER_REQUIRED (not owner-accepted).
  - The suite's route ledger points reward.world_unlock at m54_world_regression.
  - The report was regenerated: 002 now has 40 bound / 2 not built, and SB-M43-170 has not live = none (still OPEN).
  - TASKS rows were updated with the rebased hashes and these facts.

