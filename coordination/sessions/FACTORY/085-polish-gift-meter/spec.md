# Gift Meter next-milestone cycle (1, 5, 10, 25, 100, 250, 500, 1000)

> Feature: SB-POLISH-002 — Gift Meter: target is always the NEXT milestone of the cycle 1, 5, 10, 25, 100, 250, 500, 1000, then repeat from 1 (bar 0/1, x/5 ..., not 898/1,000); gift value scales with the milestone (owner: "nerdeyse hic hediye vermiyor"); fix the Gifts list raw key REWARD_guaranteed_new_fallback_sb; values in data/config/economy_rewards_v1.json, Claude proposes them (owner pre-approved, existing currencies only). Owner feedback 2026-10-31 (phone).

## Context
Today (all paths under the worktree):
- `data/config/economy_rewards_v1.json` `gift_meter`: `cycle_max` 1000, `rollover` true, `milestones` 10/50/250/500/1000 with bundles (keys `bot_parts`, `scrub_bucks`, `standard_card_packs`, `premium_card_packs`, `random_any_booster_charges`, `selected_booster_charges`, `guaranteed_new_cards`, `guaranteed_new_fallback_sb`). `schema_version` 2; `scripts/economy/economy_config.gd` `EXPECTED_SCHEMA_VERSION := 2` (strict), accessors `gift_meter_milestone()/gift_meter_milestones()`.
- `scripts/economy/gift_meter_service.gd`: ONE cumulative per-cycle counter `_cycle_progress` 0..999 fed ONLY by Win Streak SB (`add_streak_sb`), hard-coded `MILESTONES := [10,50,250,500,1000]`, queue entries `{id "gift_ms:c<cycle>:m<ms>", cycle, milestone, claimed}`, `claim()`, `snapshot()/import_snapshot()` (rejects milestones not in MILESTONES; requires total = cycles*1000 + cycle_progress), `full_cycle_bot_parts()`.
- `scripts/economy/gift_progress_model.gd` (prev/next/segment_fraction/ticks, uses MILESTONES).
- Home: `scripts/ui/home/home_view_model.gd` (`gift_progress`, `gift_cycle_max`, `gift_next_milestone`), `scripts/ui/home/home_screen.gd` ~L1278 (`GiftMeterBar` shows `HOME_RATIO` progress/cycle_max; `GiftTickOverlay` in `scripts/ui/components/gift_tick_overlay.gd`).
- Gifts popup: `scripts/ui/daily/daily_screens.gd` `open_gift_bar` / `refresh_gift_bar` / `gift_rows` (row text `GIFTS_ROW` + `UiText.reward_text`).
- `scripts/ui/ui_text.gd` `reward_text()` builds `t("REWARD_" + key)`; there is NO `REWARD_guaranteed_new_fallback_sb` label, so the raw key leaks (the 1000 bundle contains that key). `scripts/ui/ceremony/meta_ceremonies.gd` `gift_milestone()` already special-cases the fallback key (erases it and shows `CEREMONY_GIFT_FALLBACK`).
- Owner rules: `coordination/OWNER_ECONOMY_REWARDS_V01.md` §4 (progress = Win Streak SB only; milestones; 10 Bot Parts per full cycle; fallback 500 SB). Economy lock in CLAUDE.md: no new currencies, no fifth booster.

## Design decision
**Per-cycle cumulative counter, display = progress / NEXT milestone.** Chosen because it keeps the existing counter, save fields and "total = cycles*1000 + cycle_progress" invariant, and matches the owner's "0/1, then x/5": after earning 1 the bar reads 1/5, after 5 reads 5/10, after 100 reads 100/250, after 250 reads 250/500, then 500/1000; reaching 1000 completes the cycle and the bar returns to 0/1. What earns points is unchanged (Win Streak SB only; overflow carries, e.g. 998 + 5 -> 1000 milestone queued, new cycle at 3, which also queues milestone 1).

Reward table (existing reward types only). Bot Parts per cycle stay exactly 10 so robot-unlock pacing is untouched:

| Milestone | Bundle |
|---|---|
| 1 | 25 SB |
| 5 | 1 Bot Part + 50 SB |
| 10 | 1 Bot Part + 50 SB + 1 Card Pack |
| 25 | 1 Bot Part + 100 SB + 1 Mystery Booster |
| 100 | 1 Bot Part + 150 SB + 1 Card Pack |
| 250 | 2 Bot Parts + 200 SB + 1 Booster of choice + 1 Card Pack |
| 500 | 2 Bot Parts + 300 SB + 1 Booster of choice + 1 Card Pack |
| 1000 | 2 Bot Parts + 600 SB + 2 Boosters of choice + 1 Premium Pack + 1 guaranteed-new card (fallback 500 SB if no eligible card) |

Totals per full cycle (was -> now): Bot Parts 10 -> 10 (1+1+1+1+2+2+2); SB 850 -> 1,475 (25+50+50+100+150+200+300+600), plus the 500 SB fallback only in place of the new card; Card Packs 3 -> 4 (milestones 10, 100, 250, 500); Premium Pack 1 -> 1; Mystery Booster 1 -> 1; Booster of choice 3 -> 4 (250, 500, 1000x2); guaranteed-new card 1 -> 1. A cycle costs 1000 streak SB, so return is about 1.5 SB per SB earned, plus the small early gifts the owner asked for; SB is spent at the existing Heart/booster prices, no inflationary currency added.

Migration (config bumps to a new model):
- `data/config/economy_rewards_v1.json`: `schema_version` 2 -> 3 (and `EXPECTED_SCHEMA_VERSION` 3); `gift_meter.milestones` becomes the 8-entry table above; add `gift_meter.legacy_milestones` containing ONLY the old milestone-50 bundle (`bot_parts` 1, `random_any_booster_charges` 1), used solely to pay an already-queued unclaimed old "50" occurrence.
- `GiftMeterService.MILESTONES` becomes `[1,5,10,25,100,250,500,1000]`; `CYCLE_MAX` stays 1000.
- `import_snapshot` accepts queue milestones in the new set OR the legacy 50. It carries `cycle_progress`, `total_progress`, `cycles_completed`, `applied`, and every queue entry (claimed flags and ids untouched, so claimed rewards are never lost or re-granted). Then, deterministically and only for the CURRENT cycle (`cycle == cycles_completed`), it appends an unclaimed occurrence `gift_ms:c<cycle>:m<ms>` for every new milestone `ms <= cycle_progress` that has no queue entry yet (new milestones 1, 5, 25, 100 backfill; milestone 10/250/500 already exist). Past cycles are not backfilled. Unclaimed entries are paid with the NEW table (milestone 10/250/500/1000), the legacy 50 entry with `legacy_milestones["50"]`. Migration is idempotent: importing the migrated snapshot again changes nothing.

## Requirements
1. Config and `EconomyConfig` updated as above (schema 3, 8 milestones, `legacy_milestones`); config validator still rejects `random_booster_charges` and still requires every milestone key to be a positive int <= `cycle_max`.
2. `GiftMeterService` uses the 8-milestone cycle, crosses multiple milestones in one call exactly once each (existing behaviour), and migrates old snapshots per "Migration". `claim()` uses `legacy_milestones` for a legacy 50 occurrence. `full_cycle_bot_parts()` returns 10.
3. Add a read helper returning the next milestone for a given progress (reuse `GiftProgressModel.build()["next"]`; do not duplicate the loop in `home_view_model.gd`).
4. Home bar (`GiftMeterBar`) shows `progress/next` (label via `HOME_RATIO`, bar fill = progress/next); at cycle start it reads `0/1`. The old `progress/1000` text is gone. `GiftTickOverlay` must not draw cycle-scaled milestone marks that contradict the new fill (draw ticks of the current gap only, or none).
5. Gifts popup header (`GIFTS_PROGRESS`) reads progress against the next milestone. Rows list the cycle's gifts in order with clean reward text.
6. Add `REWARD_guaranteed_new_fallback_sb` handling so no raw key shows: in the Gifts popup and everywhere `UiText.reward_text` is used, the fallback renders as a clean label (e.g. "SB if no new card" via a new UiText key), never `REWARD_...`. Audit every reward key reachable from the config (`gift_meter.milestones`, `legacy_milestones`, `daily.login_rewards`, other bundles passed to `reward_text`) and add any missing `REWARD_<key>` UiText label. Unknown keys must degrade to a title-cased label without underscores, not a raw key.
7. New focused suite `tests/sb_polish_002_gift_meter.gd` (register it in the same CI workflow list that runs `m43_master_c005r_gift_micro_progress`, `.github/workflows/android-family-first10.yml`).
8. Update the existing gift suites that hard-code the old model (grep `tests/` for `gift_bar`, `gift_meter`, `GiftMeterService`, `MILESTONES`, `10, 50`, `schema_version`): at least `m38_win_streak`, `m39a_economy_core`, `m39_v03_full_surface`, `m43_master_c005r_gift_micro_progress`, `m43_master_c005_meta_ceremonies`, `m43_c005_c074_c077_celebrations`, `m42_home*`, `m43_master_c009_daily`, `m43_master_c010_meta`.
9. Docs: `coordination/OWNER_ECONOMY_REWARDS_V01.md` §4.2/§4.3 rewritten to the new milestones/table with a dated note "owner 2026-10-31 (SB-POLISH-002)"; `scripts/economy/README.md` and the header comments of `gift_meter_service.gd`/`gift_progress_model.gd` updated; TASKS.md entry closed with evidence per the factory loop.

## Acceptance criteria
Run with `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd`.
1. `sb_polish_002_gift_meter.gd` prints its final PASS line and covers 2-12 below.
2. Config: 8 milestone keys exactly {1,5,10,25,100,250,500,1000}; schema_version 3 loads (`is_ok()`), schema 2 is rejected; summed Bot Parts = 10, SB = 1475; every bundle uses only existing reward keys.
3. Fresh service: `cycle_progress` 0 -> next milestone 1; after `add_streak_sb(tx,1)` queues milestone 1 once, next = 5, progress 1; after total 5 -> next 10; 10 -> 25; 25 -> 100; 100 -> 250; 250 -> 500; 500 -> 1000.
4. `add_streak_sb` of 1000 from 0 queues all 8 milestones once each; 998 then +5 queues 1000, rolls to cycle 1 with progress 3 and queues c1:m1; duplicate tx id queues nothing.
5. Claiming each milestone grants exactly its table bundle once; a second claim returns `already_claimed` and wallet/inventory unchanged.
6. Migration fixture A: old snapshot cycle_progress 898, queue [m10 claimed, m50 claimed, m250 unclaimed, m500 unclaimed] imports ok; claimed flags preserved; queue gains unclaimed c0:m1, m5, m25, m100; no duplicate ids; progress still 898; next shows 898/1000.
7. Migration fixture B: old unclaimed m50 entry stays claimable and pays the legacy bundle (1 Bot Part + 1 Mystery Booster) once; old unclaimed m10 pays the NEW m10 bundle; re-importing a migrated snapshot is a no-op (same queue); a past-cycle (c0 while cycles_completed 1) snapshot gets no backfill.
8. Invalid snapshots (milestone 7, duplicate id, fractional progress, total != cycles*1000+progress) still fail closed.
9. Home view model/screen: progress 0 shows `0/1`; progress 7 shows `7/10`; progress 898 shows `898/1,000`-style via `UiText.num` of next milestone 1000 only because 1000 is the next milestone; no `/1,000` shown when next < 1000. Fill ratio = progress/next.
10. Gifts popup text: for every queued and legacy occurrence the displayed row string contains neither `REWARD_` nor `_`; the 1000 row shows the fallback as clean text.
11. Over all `UiText.reward_text` outputs for every bundle in the config (milestones, legacy, daily login rewards) assert no `REWARD_` and no `_` in the string; every key used has a `UiText` `REWARD_<key>` label (test iterates the config keys).
12. Unknown key into `reward_text({"foo_bar": 2})` yields no `_` and no `REWARD_`.
13. Updated suites pass: m38_win_streak, m39a_economy_core, m39_v03_full_surface, m43_master_c005r_gift_micro_progress, m43_master_c005_meta_ceremonies, m43_c005_c074_c077_celebrations, m42_home, m42_home_v06, m43_master_c009_daily, m43_master_c010_meta (each prints its existing PASS line).
14. `grep -n "REWARD_guaranteed_new_fallback_sb\|schema_version" scripts/ui/ui_text.gd data/config/economy_rewards_v1.json` shows the label key present and `"schema_version": 3`; `git diff --check` clean.
15. OWNER doc `coordination/OWNER_ECONOMY_REWARDS_V01.md` §4.3 table equals the config table (checked by the new suite parsing nothing, by reviewer reading).

## Out of scope
- Changing what earns meter points (still Win Streak SB only), Win Streak values, Daily, hearts, boosters, shop prices.
- New currencies, a fifth booster, free manual 2x, pity changes.
- Reset-per-milestone counters or a new save format beyond the described import migration.
- New art, new popups or ceremonies; only text/fill changes in existing ones.
- Backfilling past cycles, removing claimed history.

## Assumptions
- Cumulative per-cycle counter (not reset per milestone): keeps save invariants and matches "x/5 after 0/1".
- Reward values are Claude proposals (owner pre-approved recommendations); Bot Parts per cycle held at 10 to protect robot-unlock pacing.
- Backfilling new low milestones in the CURRENT cycle only is generous but deterministic and cannot duplicate claims (ids are unique per cycle/milestone).
- Schema bump to 3 is required because milestone keys and the `legacy_milestones` table change economy model rules.
- Legacy 50 gets its own legacy table so an already-queued unclaimed gift is honoured exactly.
