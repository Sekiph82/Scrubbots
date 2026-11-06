STATUS: READY

# Build: analytics events 2 (SB-M56-007..010, 012..016)

## Summary
The branch `factory/122-analytics-events-2` extends the factory 116 analytics seam (taxonomy v1, `AnalyticsService`, consent default OFF, NullSink) with these new events: economy, collection/robots, navigation, ads/store, notifications. All params are int/bool/enum only, with no ids or tokens. Taxonomy `version` stays 1: the change only adds events. The doc now has a versioning rule saying that changing an existing event bumps the version.

Wiring:
- `EconomyWallet.changed(resource, delta, tag)`: spends carry a tag and reward credits carry their RewardGrantService tx id.
- `RewardGrantService.granted(tx_id)`.
- `AppState` maps these onto the new events. It also handles the rewarded `resolved` signal and facade robot actions.
- Every other call site is one `_track`/`track` line.

Commits: fbab334f (taxonomy + tests + CI guard), 8749f381 (call sites), 084b5fbf (event rename to `notification_prompt`; the m43_146 source guard forbids the string `notify_permission` in main.gd), 2d5ea0ec (docs + TASKS).

Files: data/config/analytics_taxonomy_v1.json, scripts/app/{app_state,main}.gd, scripts/economy/{economy_wallet,reward_grant_service,booster_inventory,heart_service,speed_entitlement_service,economy_services,production_action_facade}.gd, scripts/progression/robot_unlock_service.gd, scripts/ui/popup/acquisition_flow.gd, scripts/ui/daily/rewarded_ads_screen.gd, scripts/ui/profile/profile_screens.gd, tests/m56_analytics_taxonomy.gd, .github/workflows/android-family-first10.yml, docs/ANALYTICS_TAXONOMY_V1.md, docs/PRIVACY_DATA_INVENTORY.md, TASKS.md.

## Acceptance criteria
1. [x] Economy (007): `economy_source` (currency, amount bucket, source from tx prefix: first_clear, win_streak, gift, daily_*, rewarded_*, cards_exchange, collection, ...), `economy_sink` (booster_use/buy, heart_plus_one/refill, speed_level/timed = 2x, robot_unlock), `hearts_empty`. m56 `economy_events`: each wallet change gives exactly one event, and the sinks carry the exact canonical prices.
2. [x] Collection/robots (008): `pack_opened` (new/duplicate buckets, best rarity; replays are not re-sent), `collection_set_complete` x15 once each, `collection_master_complete` once, `robot_unlock`/`robot_equip`. Checked by m56 `collection_robot_events`.
3. [x] Navigation (009): `screen_view` (routes, shortcuts, BottomNav, Settings, Help), `shop_open` (entry source), `launch_failed`. Checked by m56 `navigation_events`.
4. [x] Ads/store (010): `ad_offer_shown`, `ad_request`, `ad_result` through the mocked provider double. Cancelled, a late duplicate ignored, a verified grant, and the no-SDK case showing unavailable are all covered. Store page view is `shop_open`; no purchases exist. Checked by m56 `ads_store_events`.
5. [x] Notifications (012): `notify_toggle`, `notification_prompt` (explainer_shown / allowed / declined / os_granted / os_denied), `deep_link_open`. Checked by m56 `notification_events`. There is no send path in the game, so no send event; this is documented.
6. [x] Dashboard metrics (013): KPI formula table in docs/ANALYTICS_TAXONOMY_V1.md. It is a doc only, with no server.
7. [x] No-gameplay-effect (014): `no_economy_change` now runs a level, then spends, a pack, all Collection cards, a robot, navigation, rewarded ads and reminders, once with consent OFF and once ON. The economy and progression snapshots come out identical.
8. [x] Consent/age/provider gating (015): documented section in docs/ANALYTICS_TAXONOMY_V1.md, together with M58.
9. [x] Schema tests (016): every event is schema-checked. `config_schema` now also requires every event to be listed in both the taxonomy doc and PRIVACY_DATA_INVENTORY.md. `pii_scan` requires every event except retention_day/assist_fail_closed to be emitted on a real path with 0 drops. Duplicate guards are tested. `provider_offline`: 1000 events into a dropping sink never queue 20 or more.
10. [x] Privacy inventory updated for every new event; m58 stays green.
11. [x] m56 CI exact guard updated 15/15 -> 21/21 in .github/workflows/android-family-first10.yml.

## Validation
Godot 4.7.2 headless, after one `--import`. project.godot and the .import/.uid/.translation churn were restored or removed, and the tree is clean. All suites below are LOCAL_PASS: exit 0, no SCRIPT ERROR or Parse Error, last line PASS.
- m56_analytics_taxonomy: PASS (21/21 cases, 0 fail)
- m58_privacy_inventory: PASS (7/7), re-run after the doc edit
- m43_146_notification_permission: 8/8. The first run failed on its source guard; after the rename it passes.
- m43_c003_c001_acquisition 34/34
- m43_c004_c001_fail_need_a_hand 40/40
- m39a/b/c/d/e
- m39_v02_atomicity, m39_v02_integration, m39_v03_full_surface, m39_v03_integration, m39_v04_integration
- m40_save_system, m40_v04_bootstrap
- m42_navigation, m42_home
- m43_r15_owner_remediation 18/18, m43_r15_001_r01_sequential_unlock 14/14
- m43_master_c006_shop 15/15, c007_collection 19/19, c007r_pity 11/11, c008_robots 10/10, c010_meta 12/12
- m54_collection_set_master_exactly_once, m54_regression_pack_022_027 12/12
- m44_pending_packs_gate 6/6, m44_unlock_gate 6/6
- m55_economy_release_regression
- m41_settings

`git diff --check` is clean. No phone build. Nothing pushed.

## Log
### Round 1
Built the full scope. Two test fixes during the build: 5000 SB falls in the bucket `1001_5000`, and the boot `screen_view` is not captured because the MemorySink is attached after boot. I also renamed the permission event after m43_146 flagged `notify_permission` appearing in main.gd. Self-tested only; peer review is pending.
