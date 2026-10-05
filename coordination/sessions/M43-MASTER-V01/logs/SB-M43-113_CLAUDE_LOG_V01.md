# SB-M43-113 — CLAUDE LOG V01

Child: **SB-M43-113** — "Produce/owner-approve Tasks visual master."
Parent: M43-C009 — Tasks / Daily / Gift Bar Destinations
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `f100c89` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- coordination/OWNER_ECONOMY_REWARDS_V01.md §9 (Daily: three tasks 75/100/125 SB, all-3 = one random Booster Charge, consecutive-login count, repeating 5-day cycle, local-day rules, rollback fail-closed) + data/config/economy_rewards_v1.json `daily` / `gift_meter`
- TASKS M43-C009R (owner-approved 2026-09-30): Daily Scrub Orders archetypes, deterministic per local day, easy/normal/stretch, earned ScrubBox never sold, surprise slot disabled until M56 + owner
- M43 master prompt V01 §C009 + resume V02 §5

## Implementation

| File | Change |
|---|---|
| `data/config/daily_scrub_orders_v1.json` | **new** versioned order pool (8 archetypes, 3 tiers; targets PROVISIONAL, max 3 wins; no reward values) |
| `scripts/economy/daily_orders.gd` | **new** DailyOrders: strict pool load, deterministic per-day generation over eligible orders, forward-only day, progress from committed wins, marks DailyService tasks done, strict `daily_orders` section |
| `scripts/economy/daily_service.gd` | read-only `local_day`, `is_task_done`, `task_claimed`, `all_tasks_bonus_claimed` |
| `scripts/economy/economy_services.gd` | `orders` service + `daily_orders` section (absent = fresh, present = strict) |
| `scripts/app/app_state.gd` | `orders_context()` (frontier, class lookup, playable catalog levels ahead) |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | per-attempt committed booster count; committed progression WON feeds `orders.on_level_won` before the terminal save |
| `scripts/ui/daily/daily_screens.gd` | **new** Tasks (orders, progress, 75/100/125, ScrubBox), ScrubBox ceremony, Daily (D1..D5 cards, consecutive count, claim + Day celebration), Gift Bar (claim + history) |
| `scripts/app/main.gd` | TASKS / DAILY / Gift Meter / SHOP / COLLECTION shortcuts -> app-level destinations (`APP_SHORTCUTS`) |
| `scripts/ui/home/home_screen.gd` | `set_app_shortcuts` (app root registers its destinations; a standalone Home keeps its M42 popups), invisible GiftMeterButton hit area (hidden under modals), shortcut enablement includes app destinations |
| `scripts/ui/ui_text.gd` | Tasks / ScrubBox / Daily keys |
| `tests/m43_master_c009_daily.gd` | **new** lane suite t01–t12 |
| `tests/tools/daily_snapshot.gd` | **new** rendering evidence tool |

Shared C009 + C009R implementation (one commit).

## Tests

`tests/m43_master_c009_daily.gd` → **PASS 12/12** (real app root, injected clock + local day, real gameplay host terminals):
t01 Home TASKS (and SHOP / COLLECTION / DAILY) panels tappable; TASKS opens the app-level Tasks (no Home placeholder); exactly three orders easy / normal / stretch; per-task 75 / 100 / 125 SB from config; ScrubBox closed until 3/3.
t02 orders persisted and identical on relaunch, pure function of (pool version, local day, eligibility); next local day regenerates; clock rollback neither regenerates nor counts.
t03 LOST terminal counts nothing; committed WON advances win / no-booster / pixel orders and marks DailyService tasks done; saved at the terminal boundary; a committed booster makes a win non-boosterless.
t04 CLAIM blocked until done; +75 SB once; facade re-claim refused; survives relaunch.
t05 3/3 → OPEN → ScrubBox ceremony after the commit; exactly +1 Random Booster Charge shown and granted; second open refused.
t06 Home DAILY opens the app-level Daily; D1..D5 rewards from config; states today / claimed today / upcoming; consecutive count; day 6 repeats the cycle at D1 while the count keeps 6.
t07 local-day rollover resets orders and tasks; missed days → D1 and streak 1; clock rollback refuses login and task claims.
t08 Gift Meter tap opens Gift Bar; claim grants the milestone and leaves the Gift Meter unchanged (non-recursive); claimed moves to history; re-claim refused; rollover queues the next cycle while history stays.
t09 eligibility: MEDIUM-or-harder order only when such a level is within 3 playable levels; win-N needs N playable levels; no playable content → no order, shown honestly and not claimable; live context from progression + catalog.
t10 7 malformed `daily_orders` sections rejected with state untouched; absent section → fresh; a pool with target 0 rejected, shipped pool valid.
t11 no spend / ad / price path in Tasks / ScrubBox; ScrubBox absent from the Shop; ordinary-play metrics only, no reward field or surprise slot; at most 3 wins for any order.
t12 5+5 taps on a task CLAIM → +100 once; 4 taps on OPEN → one charge.


## Regression

Lane checkpoint (all exit 0, 0 script errors): m43_master_c009_daily 12/12, m43_master_c008_robots 10/10; closed m42_home, m42_home_composition 9/9, m42_home_v04 18/18, v05 13/13, v06 13/13, v07_safe_area 9/9, m42_navigation; m43_c001a 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40; m43_master c005 32/32, c005r 8/8, c006 11/11, c007 13/13; m28_c002_c002_static_shell 16/16; m39a, m39d_daily_collection, m39_v03_full_surface, m39_v04_integration, m40_save_system, m40_v03_canonical, m40_v04_bootstrap, m55_economy_release_regression PASS; root `tests/run_tests.gd` **ALL PASS 5323 checks**; `git diff --check` clean. No closed test changed (standalone M42 Home keeps its popups; the app root registers its destinations).

## Runtime evidence

Rendering tool `tests/tools/daily_snapshot.gd` → frames under `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-112/` (Tasks, ScrubBox, Daily fresh / claimed, Gift Bar claimable + history).

## Blockers / gates

Runtime screen uses only existing approved art (daily check, reward chest, Random booster) in the popup family; evidence frames produced. **Missing authority:** owner visual master.

BLOCKED_AWAITING_AUTHORITY — SB-M43-113
