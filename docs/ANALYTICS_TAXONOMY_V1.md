# Analytics Taxonomy V1 (SB-M56-001..023)

Machine source: `data/config/analytics_taxonomy_v1.json` (schema `scrubbots.analytics_taxonomy.v1`, version 1).
Service: `scripts/app/analytics_service.gd`, owned by `AppState.analytics`.
Tests: `tests/m56_analytics_taxonomy.gd` (CI validate, exact 27/27 guard).

## Rules

- **No provider, no network.** The default sink is `NullSink` (drops everything). `MemorySink` exists for tests. A real provider is a later, owner-approved sink (CLAUDE.md §3.6, §0D.5); it must keep these rules.
- **Consent gate.** Nothing is validated, queued or stored until `AnalyticsService.set_consent(true)`. Default is OFF; the only switch is Settings -> PRIVACY (`scripts/ui/privacy_screen.gd`, SB-M58-008). Revoking consent drops the queue and the local retention markers.
- **Privacy-minimized.** Params are only `int`, `bool`, `enum` or `enum_list`. There is no free-text type, so no names, emails, device or advertising ids, tokens, receipts, board or save data can be sent. `privacy.forbidden_param_names` lists names that may never be declared. Times and counts go out as coarse buckets (`buckets` table). No timestamps or ids are added to events. Each event carries only `event`, `v` (taxonomy version) and `params`.
- **Schema validation.** An unknown event, an undeclared param, a wrong type, an out-of-range int, a disallowed enum value or a missing required param drops the whole event and prints a debug-build warning. An enum with a `fallback` maps unknown values to the fallback (`other` / `UNKNOWN`). A missing or invalid taxonomy file drops everything. Validation never crashes.
- **Write-only (SB-M56-014).** No gameplay, economy, difficulty, solver or save code reads analytics. Events never grant rewards or change difficulty. Offline play never depends on them. Economy services only expose two signals for it (`EconomyWallet.changed`, `RewardGrantService.granted`); every other call site is one `track` line after the existing logic. `no_economy_change` plays the same session (level, spends, pack, Collection, robots, navigation, rewarded ads, reminders) with consent OFF and ON and requires identical economy and progression snapshots.
- **Versioning.** Adding a new event, a new enum value or a new optional (`required: false`) param keeps `version`. Changing or removing an existing event, param or bucket edge bumps `version` (events carry `v`).
- **Batched.** Events are queued and handed to the sink in batches of `batch_size` (20), and at session end. They are never sent per frame.
- **Local state.** `user://analytics_v1.json` (tests: `<save>_analytics.json`) holds only `consent`, the first consented local day and the retention markers already sent. It is not part of the game save.

## Buckets

| Table | Labels |
|---|---|
| `duration_s` -> `duration` | lt_30s, 30s_2m, 2m_5m, 5m_15m, 15m_60m, gt_60m |
| `attempt` | 1, 2, 3, 4_5, 6_10, gt_10 |
| `count` | 0, 1, 2, 3_5, gt_5 |
| `progress_pct` -> `progress` | 0_25, 25_50, 50_75, 75_90, 90_100 |
| `amount` | 0, 1_10, 11_50, 51_100, 101_500, 501_1000, 1001_5000, gt_5000 |

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

### Economy, Collection, navigation, ads/store, notifications (SB-M56-007..010, 012)

| Event | Task | Call site | Params |
|---|---|---|---|
| `economy_source` | 007 | `AppState` on `EconomyWallet.changed` (credit) | currency (scrub_bucks / bot_parts), amount (bucket), source: the RewardGrantService tx-id prefix mapped by `AppState.ANALYTICS_SOURCES` (first_clear, win_streak, gift, daily_login, daily_task, rewarded_daily, rewarded_ad, cards_exchange, collection, event, comeback, achievement, starter, refund; anything else other) |
| `economy_sink` | 007 | `AppState` on `EconomyWallet.changed` (debit) | currency, amount (bucket), sink: the spend tag (booster_use = SB-paid booster, booster_buy = saved charge, heart_plus_one, heart_refill, speed_level / speed_timed = 2x products, robot_unlock) |
| `hearts_empty` | 007 | `main.gd` `_zero_heart_gate` (Heart starvation: a new attempt refused at 0 Hearts) | at (home_play / results_retry) |
| `pack_opened` | 008, 019 | `AppState.commit_pack` (committed, not a replayed receipt) | kind, new_cards, duplicates (count buckets), best_rarity, pity (the PackPity guarantee was due for this pack), dry_streak (count bucket of the pity counter after it: earned packs in a row without a new card) |
| `collection_set_complete` | 008, 019 | `AppState` on `RewardGrantService.granted` `collection_set:<n>` (applied exactly once) | set (1..15), level (campaign frontier when the set completed) |
| `collection_master_complete` | 008 | `AppState` on `RewardGrantService.granted` `collection_master` | (none) |
| `robot_unlock` / `robot_equip` | 008 | `AppState` on the app facade `action_committed` (unlock_robot / equip_robot) | robot (roster order 1..10) |
| `screen_view` | 009 | `main.gd` route change (opening / home / gameplay / results; results = a LOST / ERROR terminal only, a win goes Home since SB-PHONE-2026-11-12-E), Home shortcuts and BottomNav, Settings, Help | screen |
| `shop_open` | 009, 010 | `main.gd` on `ShopHandoff.shop_requested` (every Shop entry; store page view, no purchases exist) | source (home_shop, home_sb_plus, life, booster, speed, need_a_hand) |
| `launch_failed` | 009 | `main.gd` `launch_gameplay` refusals | reason (APP_BLOCKED, CONTENT_MISSING, CATALOG_INVALID, LEVEL_DISABLED, BUILD_FAILED) |
| `ad_offer_shown` | 010 | `AcquisitionFlow` Life / Booster / Need a Hand popup opened | placement, available (provider + product state allow a video now) |
| `ad_request` | 010 | `AcquisitionFlow._start_rewarded`, `RewardedAdsScreen._watch` (player accepted the offer) | product (heart, booster_<id>, daily_slot), ok, reason (refusal reason) |
| `ad_result` | 010 | `AppState` on `RewardedGrantService.resolved` (once per token; late duplicates are not resolved again) | product, outcome (granted = verified completion committed; cancelled, skipped, failed, timeout, unverified, already_full, duplicate) |
| `notify_toggle` | 012 | `ProfileScreens.open_notifications` | category (all or one reminder category), on |
| `notification_prompt` | 012 | explainer popup shown / Allow / Not now; `main.gd` on `SceneTree.on_request_permissions_result` | step (explainer_shown, allowed, declined, os_granted, os_denied) |
| `deep_link_open` | 012 | `main.gd` `open_deep_link` | dest (the destination actually opened) |

Not sent: transaction ids, tokens and receipts (forbidden names; the ad result only says whether the verified grant committed). There is no purchase path, so purchase fulfilment has no event yet. Local notifications are not delivered by the game yet (no send path), so there is no send event; `deep_link_open` covers the open. A pack whose commit is later rolled back (save failure) may already have sent its events; analytics is best effort and never feeds back.

### Feature measures (SB-M56-011, 017..023)

| Event | Task | Call site | Params |
|---|---|---|---|
| `journey_progress` | 018 | `main.gd` win -> Home (`_track_win_journey`, anchor = the won level; was the WON Results route before SB-PHONE-2026-11-12-E) | slot (1..10), cycle (1..), cycle_complete (slot 10 of 10), first_clear (progression win vs replay) |
| `daily_order_done` | 020 | `ProductionGameplayHost` committed progression win (`DailyOrders.on_level_won` newly done) | tier (easy / normal / stretch), metric (archetype metric), target |
| `daily_order_claim` | 020 | `AppState` on the facade `action_committed` (`claim_daily_task`, `claim_daily_all_tasks`) | tier (easy / normal / stretch; scrubbox = the all-3 bonus) |
| `weekly_event` | 021 | host progression terminal (`_track_event_progress`: joined = first counted win, milestone_reached), `AppState` on `claim_event_milestone` (milestone_claimed) | step, milestone (1-based; 0 for joined) |
| `first_try` | 021 | `AppState` on `join_first_try` / `claim_first_try`; host progression terminal on a first attempt of a joined run (advanced / completed / reset) | step (joined, advanced, completed, reset, claimed), run (depth after the win, or the depth a first-attempt loss reset) |
| `comeback_window` | 022 | `main.gd` boot / OS resume when `ReturnService.on_active` opens a return window | catchup_offered (a Catch-Up track runs for the window) |
| `catchup_step` | 022 | host first-clear win (`ReturnService.on_first_clear_win` grants) | step (1..3), complete (the last step) |
| `ranks_view` | 011 | `ProfileScreens.open_ranks` | table (`all_time` when the screen opens, `weekly` / `all_time` on each RANKS tab switch, SB-M43-131/132), band (the player's 1-based personal rank tier on either table, 0 = ladder unavailable) |

No ids leave: weekly events, orders and cards are described by small ints and enums, never by their config ids.

Not sent, by design or because no path exists yet:

- **Notifications (023).** The game delivers no local notification yet (no send path; local delivery is a separate job), so eligible / suppressed / sent / opened events do not exist. Measured today: `notify_toggle` (category on / off), `notification_prompt` (explainer, Allow / Not now, OS granted / denied) and `deep_link_open` (destination). When delivery lands, its events go here, carrying only the category and a dedup / suppress reason enum.
- **Weekly expiry.** No code path observes an event ending; expiry is derived offline (see the formulas). Events carry no event id, so the per-event split uses the receipt week. No Weekly event or First-Try is scheduled in `data/config/events_v1.json` yet, so these events stay silent in the shipped build.
- **Catch-Up expiry.** Derived: a `comeback_window` with Catch-Up offered and no complete `catchup_step` within `catchup_expire_days`.
- **Daily order time-to-complete.** Events carry no timestamps; it is the provider receipt time of `daily_order_done` minus the day's first `session_start`.

## Dashboard metrics (SB-M56-013)

Definitions only; there is no dashboard server. "Player-day" = one installation on one local day with at least one `session_start`. All rates are over consented players only.

| Metric | Formula |
|---|---|
| Daily active (DAU-style) | distinct player-days with `session_start` |
| D1 / D7 / D30 retention | players with `retention_day` d1 (d7, d30) / players whose first consented day is at least 1 (7, 30) days old |
| Session length | distribution of `session_end.duration`; median bucket per day |
| Level drop-off | for level L: 1 - (players with `level_start` on L+1) / (players with `level_end` won on L) |
| Level funnel | `level_start` -> `level_first_action` -> `level_end` won, by level and by `cadence_slot` |
| First-attempt clear rate | `level_end` won with `first_attempt` / all `level_end` won, by `difficulty` |
| Fail-progress distribution | histogram of `level_end.progress` where outcome = lost, by level / difficulty |
| Help (Need a Hand) conversion | `assist_dismissed` acquired / `assist_shown`; assisted clear rate = `level_end` won with `assisted` / levels with `assist_shown` |
| Assist rate | `assist_shown` / `level_end` lost |
| Booster reliance | `level_end` won with `boosters_used` != 0 / all `level_end` won; `booster_use` ok per 100 `level_start` |
| Heart starvation | `hearts_empty` per DAU; share of player-days with >= 1 `hearts_empty`; refill response = `economy_sink` heart_plus_one / heart_refill and `ad_result` heart granted after it |
| Economy balance | per currency and day: sum of `economy_source` minus sum of `economy_sink`, using the bucket midpoint (gt_5000 counted as 5000); split by source / sink |
| 2x product use | `economy_sink` speed_level + speed_timed per DAU |
| Rewarded funnel | `ad_offer_shown` (available) -> `ad_request` ok -> `ad_result` granted, by placement / product |
| Shop entry | `shop_open` by source per DAU |
| Collection | `pack_opened` new_cards share, duplicate share, `collection_set_complete` by set |
| Next Cleanup conversion (017) | retired 2026-11-12 (SB-PHONE-2026-11-12-B): Results no longer offers CLEAN NEXT or the Next Cleanup teaser (a win goes Home), so `next_cleanup_shown` / `next_cleanup_tap` were removed. The next level starts from Home PLAY (`level_start`) |
| Journey (018) | reach of slot s = players with `journey_progress` slot s / players with slot 1 in the same cycle; drop-off after slot s = 1 - reach(s+1) / reach(s); cycle completion = `journey_progress` cycle_complete with first_clear / cycles started. Content tuning only, never a per-player difficulty change |
| Collection fairness (019) | new-card rate = packs with new_cards != 0 / `pack_opened`; dry-streak distribution = `pack_opened.dry_streak`; pity frequency = `pack_opened` with pity / all; guarantee fulfilment = pity packs with new_cards != 0 / pity packs; Set-1 completion level = distribution of `collection_set_complete.level` where set = 1 |
| Daily Scrub Orders (020) | completion per archetype = `daily_order_done` by (tier, metric, target) / player-days; 3/3 = player-days with three `daily_order_done`; ScrubBox claim = `daily_order_claim` scrubbox / player-days with 3/3; grind / Heart waste check = `hearts_empty` and `level_end` lost per player-day, by the archetype active that day |
| Weekly / First-Try (021) | participation = players with `weekly_event` joined / players active in the week; milestone completion = `weekly_event` milestone_reached m / joined; expiry = milestone_reached minus milestone_claimed per week (forfeit events); First-Try run depth = distribution of `first_try.run` on reset / completed; reset frequency = reset / joined. Reported apart from campaign retention |
| Comeback (022) | return session = the session that sends `comeback_window`; three-win completion = `catchup_step` complete / `comeback_window` catchup_offered; later return = `session_start` on the following days and `retention_day` d1 / d7. The Daily login streak stays its own metric (`economy_source` daily_login) |
| Notifications (023) | opt-in = `notify_toggle` all on / players; per category = `notify_toggle` by category; OS grant = `notification_prompt` os_granted / allowed; opens = `deep_link_open`. No frequency target: the owner cap and copy rules are never tuned from this |
| Ranks (011) | Ranks reach = players with `ranks_view` / players at the Ranks unlock level; band distribution = `ranks_view.band` |
| Screen reach | `screen_view` per screen / DAU |

## Consent, age and provider gating (SB-M56-015, with M58)

A production provider (a real sink) may only be switched on when all of these hold:

1. The owner has chosen the provider (CLAUDE.md §0D.5: new service) and SB-M58-008 records the consent / legal basis per region for it.
2. The M58 consent screen (Settings -> PRIVACY, `scripts/ui/privacy_screen.gd`, done in factory 135; guard `tests/m58_privacy_consent.gd` p05) is the only caller of `AnalyticsService.set_consent`. Default stays OFF; no event, queue or local marker exists before consent; revoking drops the queue and the markers.
3. Age: until an age gate exists, the provider runs in its most restrictive mode (no advertising id, no cross-app tracking, no personalised ads), and an under-age or unknown-age answer leaves consent OFF.
4. The store privacy forms (`docs/PRIVACY_DATA_INVENTORY.md` §6) are updated in the same change ("App interactions -> Analytics").
5. The provider adds no identifiers beyond what its own SDK requires, and `forbidden_param_names` and the int/bool/enum-only rule still apply to every event.

## Schema and fail-safe tests (SB-M56-016)

`tests/m56_analytics_taxonomy.gd` checks every event declaration (types, enums, fallbacks, forbidden names), drops malformed events without crashing, exercises every event through its real call site (except `retention_day` / `assist_fail_closed`, covered at service level), scans all emitted events for PII, guards duplicates (session end, level exit, replayed pack receipts, set / Master once, late ad callbacks) and proves an offline provider (a sink that drops everything) never grows the queue past one batch.

> Events fire when the wallet change or grant happens, not when the surrounding save commits. A save failure followed by a retry can emit an event twice (analytics overcount only; balances are never affected).
