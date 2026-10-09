# M39-C003 — SB-M39-054 Random-Any-Booster Reward Semantics Correction — CLAUDE LOG V01

Date: 2026-10-09
Prompt: `coordination/sessions/M39-C003/M39_C003_SB_M39_054_RANDOM_ANY_BOOSTER_PROMPT_V01.md`
Criteria: `coordination/sessions/M39-C003/M39_C003_SB_M39_054_AUDIT_CRITERIA_V01.md`
Owner authority: `coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md`
Final state: **AWAITING_GPT_SB_M39_054_STRICT_AUDIT**

Root `TASKS.md` was read only. Claude did not edit it.

## 1. Gate 0 — persistent Desktop sync

| Item | Value |
|---|---|
| Desktop path | `C:\Users\sekip\Desktop\ScrubBots` |
| Before fetch | HEAD `1cb13a24`, behind `origin/main` by 10, ahead 0 |
| Incoming commits touching owner-dirty files | none (`git diff --name-only HEAD origin/main` has no overlap with the four dirty files) |
| Sync | `git fetch --prune origin` + `git merge --ff-only origin/main` (fast-forward only, nothing restored, reset, cleaned or stashed) |
| After sync | HEAD == `origin/main` == `5af6ed7e`, ahead/behind `0 0` |
| Tracked dirty (owner work, preserved) | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked | 2616 entries (owner/import artifacts, untouched) |
| Stashes | 2 (untouched) |
| Other worktrees | 3 Codex worktrees on `codex/*` branches, none on `main`. No other writer was active on `main`. |
| Desktop `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

M43-C005F-PHASE4 had not started. This task ran first and contains no Phase 4 work.

### TEMP worktree

`git -C "C:/Users/sekip/Desktop/ScrubBots" worktree add --detach "<scratchpad>/wt054" origin/main`, HEAD `5af6ed7e`.
- All edits, imports, tests and evidence captures ran there, using absolute `git -C "<TEMP>"` and `godot --path "<TEMP>"` paths.
- After each `--import`, only the TEMP copy of `project.godot` was restored (`git -C "<TEMP>" checkout -- project.godot`), after printing the absolute TEMP target.
- Nothing was written to the Desktop checkout except the final fast-forward.

## 2. What changed

### Semantics (economy)

- **New `scripts/economy/random_booster_reward_picker.gd`.** A pure, stateless helper.
  - Charge `ordinal` of reward tx `tx_id` is selected from `SHA-256(UTF-8 "<tx_id>|random_any_booster|<ordinal>")`.
  - Bytes 0..3 are read as an unsigned big-endian 32-bit integer, then taken `% BoosterInventory.BOOSTERS.size()` (4).
  - 2^32 is a multiple of 4, so each of the four indices is exactly equally likely at the algorithm level.
  - It does not use the global RNG, card-pack RNG, gameplay RNG or level/solver RNG.
  - It persists nothing.
  - `RESOURCE = "random_any_booster_charges"`, `LEGACY_RESOURCE = "random_booster_charges"`.
- **`scripts/economy/economy_services.gd`.**
  - The old handler `random_booster_charges -> add_charges(BoosterInventory.RANDOM, n)` is removed.
  - One `random_any` handler adds one charge per ordinal `0..n-1` to `Picker.pick(reward.current_tx(), i)`. `current_tx()` is the authoritative parent tx of the running grant.
  - It is registered for the canonical key and for the legacy alias key, so the alias has the same random-any meaning. No handler maps a generic reward to `RANDOM` any more.
- **`RewardGrantService` is unchanged** and is still the only idempotency authority.
  - A duplicate tx is refused before any handler runs, so it cannot reroll.
  - A crash before save re-derives the same pick from the same tx.
  - No selection ledger was added.

### Config

- `data/config/economy_rewards_v1.json`:
  - Gift Meter 50: `random_booster_charges` → `random_any_booster_charges` (amount 1).
  - Daily D3: `random_booster_charges` → `random_any_booster_charges` (amount 1).
  - `daily.all_tasks_random_booster_charges` → `daily.all_tasks_random_any_booster_charges` (amount 1).
  - `schema_version` is unchanged because the structural schema is the same.
- `data/config/rewarded_daily_v1.json`: slot 3 (seeded 1:1 from Daily D3) now uses `random_any_booster_charges`.
- `data/config/events_v1.json`, `data/config/comeback_v1.json`: `approved_reward_types` lists the new key instead of the old one. Both lists still have no configured offer that uses it.
- `scripts/economy/economy_config.gd`: a focused validation rule rejects the canonical config if:
  - any Gift Meter milestone or Daily login bundle contains the legacy key `random_booster_charges`; or
  - `daily.all_tasks_random_booster_charges` is present.

  This only rejects legacy keys. It does not loosen any existing validation.
- `scripts/economy/daily_service.gd`:
  - reads `all_tasks_random_any_booster_charges`;
  - grants `{"random_any_booster_charges": n}` under the existing `daily_all_tasks:<day>` tx;
  - returns the same key in its result.
- `scripts/economy/rewarded_daily_service.gd`: `RESOURCES` allows `random_any_booster_charges`. The config fails closed on the old key.

### Presentation

- `scripts/ui/ui_text.gd`:
  - `REWARD_random_any_booster_charges` = **"Mystery Booster"**.
  - The legacy alias label also reads "Mystery Booster".
  - `CEREMONY_ROW_RANDOM_BOOSTER` "+%s Random Booster" is replaced by `CEREMONY_ROW_MYSTERY_BOOSTER` "+%s Mystery Booster".
- `scripts/ui/ceremony/meta_ceremonies.gd`:
  - The `REWARD_ROWS` key is now `random_any_booster_charges`. Its icon key `mystery_booster` points to the existing neutral `res://assets/ui/final/rewards/gift_box.png`.
  - The `random_booster` → `boosters/random.png` entry is removed, so ceremonies no longer bind the RANDOM gameplay icon anywhere.
- `scripts/ui/daily/daily_screens.gd`:
  - The earned ScrubBox reward icon is now `ART["gift"]` (`gift_box.png`) instead of `boosters/random.png`, and the unused `ART["random"]` entry is removed.
  - Its text reads from the new key.
- No new art was generated. Booster-of-choice wording and art (`booster_of_choice.png`, "Booster of choice") are unchanged.
- The named gameplay booster keeps its RANDOM art on gameplay, shop and acquisition surfaces (`gameplay_screen.gd`, `shop_screen.gd`, `acquisition_flow.gd`, all untouched).

### Not changed

- `selected_booster_charges`: Gift 500/1000 and D5 still go to `pending_selected`.
- `BoosterInventory` (ids, `BOOSTERS`, snapshot/import shape).
- RANDOM gameplay behaviour, booster prices, booster use legality and Need-a-Hand ranking.
- Pack RNG and `CardPackService`, pack ceremonies, Remote Content/R2, LevelData/supply/VOID, Family APK, Level Factory, and Phase 4 feel work.
- Root `TASKS.md`.

### Tests

- **New `tests/m39_c003_random_any_booster_rewards.gd`:** 87 passing assertions (0 fail), sections A–K (see §3).
- **Updated** (they asserted the old RANDOM-only semantics or used the old key):
  - `m43_master_c009_daily`, `m43_c005f_phase3_meta_rewards_acquisition`, `m43_r15_owner_remediation`: "+1 RANDOM charge" → "+1 charge across the four boosters".
    - c009 also asserts the ScrubBox icon is `gift_box.png`.
  - `m42_home`: D3 text "Random Booster x1" → "Mystery Booster x1".
  - `m39a_economy_core`, `m39d_daily_collection`, `m39_v03_full_surface`: fixture handler key renamed.
  - `m43_c005_c001_ceremony_visual_masters` plus the preview harness `tests/tools/ceremony_preview/ceremony_candidates.gd` / `ceremony_snapshot.gd`: generic reward key and icon renamed.
- **New tool `tests/tools/random_any_booster_evidence.gd`:** renders the shipping Gift 50 ceremony and the ScrubBox popup from the real config. It uses no AppState, no save and no economy mutation.

Known edge (not reachable from canonical config): a single grant that carries BOTH the canonical and the legacy key would derive the same ordinals for both. The charge total is still correct. Canonical config now refuses the legacy key, so no shipping surface can produce this.

## 3. Focused suite evidence (`m39_c003_random_any_booster_rewards`)

**First run: FAIL (2).** Both failures were in the test, not the implementation:
- `config m50 = …` and `config D3 = …` compared a JSON-parsed dictionary (`1.0` float) with a literal int dictionary using `==`.
- The fix compares through `int(...)`.

Second and later runs: **PASS, 0 fail**.

| Section | Proof (from the run output) |
|---|---|
| A pool | `BOOSTERS == [plus_one_slot, random, selector, tornado]`. Over 400 tx ids `gift_ms:c<i>:m50`: `{selector: 99, tornado: 95, random: 101, plus_one_slot: 105}`, no unknown id. |
| B algorithm | `index == u32(sha256(key)[0..3]) % 4`. An independent `sha256_text().hex_to_int()` path agrees. All indices 0..3 occur. Known answer: key `gift_ms:c0:m50\|random_any_booster\|0` gives sha256 `33b0a7e24a67530d…` → `selector`. The global RNG state is unchanged after 100 picks. |
| C replay | `gift_ms:c3:m50` → `tornado` on every repeat. A fresh `EconomyServices` with the same tx `replay_tx` gives the identical `{tornado: 1}`. |
| D idempotency | Tx `T`: total +1, exactly one counter +1 (`{selector: 1}`). Duplicate `T`: +0, no reroll. The legacy alias gives the same random-any pick and reaches all four ids. n=7: total 7 = the seven ordinal picks `{plus_one_slot: 2, random: 3, selector: 0, tornado: 2}`. |
| E Gift 50 | Config is `{bot_parts: 1, random_any_booster_charges: 1}`. Each of 12 cycles: +1 Bot Part, +1 one booster, second claim refused. Picks c0..c11 = selector, tornado, tornado, tornado, tornado, tornado, selector, tornado, selector, **random** (c9), **plus_one_slot** (c10), random (c11). This is not always RANDOM, and both RANDOM and non-RANDOM cases occur. |
| F Daily D3 | `daily_login:20002`: exactly one charge (`random`). The same-day duplicate grants nothing. |
| G ScrubBox | `daily_all_tasks:20100..20105` → random, tornado, tornado, tornado, random, plus_one_slot. Each is exactly one charge, and each duplicate grants nothing. |
| H selected | Gift 500/1000 and D5 still `selected_booster_charges`. Claims raise `pending_selected` only, with no counter change, and `selected_booster_charges` never picks. |
| I RANDOM booster | `BoosterInventory.RANDOM == "random"`, still in the pool, price 350, `min_solver_safe_moves` 3, still purchasable by id. The reward wording never contains "Random". |
| J presentation | The ceremony row binds the new key → `gift_box.png`, and no ceremony `ART` value is `boosters/random.png`. The real `MetaCeremonies.gift_milestone(50)` row is icon `gift_box.png` with text `+1 Mystery Booster`. Daily/list text is `Mystery Booster x1`. Booster of choice is unchanged. The ScrubBox source no longer references `boosters/random.png`. |
| K config/save | The legacy key in Gift 50 is refused (`legacy reward key random_booster_charges: use random_any_booster_charges`). The legacy all-tasks key is refused, and the shipping config is valid. An old four-counter + `_pending_selected` booster snapshot imports byte-identical. A granted pick persists through the normal `BoosterInventory` save, a relaunch cannot re-grant the same tx, and the save gains no new section. |

### Runtime presentation evidence

Rendered with the shipping builders (`tests/tools/random_any_booster_evidence.gd`, windowed driver):
- `coordination/sessions/M39-C003/evidence/gift_50_mystery_booster.png`: GIFT METER 50!, rows "+1 Bot Parts" and "+1 Mystery Booster" with the neutral gift-box icon.
- `coordination/sessions/M39-C003/evidence/scrubbox_mystery_booster.png`: SCRUBBOX, "Mystery Booster x1" with the neutral gift-box icon.

Neither image uses the RANDOM gameplay booster icon.

## 4. Regression (TEMP worktree, after `--import`)

| Suite | Exit | Result |
|---|---|---|
| `m39_c003_random_any_booster_rewards` (new) | 0 | PASS (first run FAIL 2: test float/int compare, see §3) |
| `m39a_economy_core` | 0 | PASS |
| `m39b_hearts_speed` | 0 | PASS |
| `m39c_boosters` | 0 | PASS |
| `m39d_daily_collection` | 0 | PASS |
| `m39e_full_matrix` | 0 | PASS |
| `m39_v02_atomicity` | 0 | PASS |
| `m39_v02_capacity` | 0 | PASS |
| `m39_v02_integration` | 0 | PASS |
| `m39_v03_full_surface` | 0 | PASS |
| `m39_v03_integration` | 0 | PASS |
| `m39_v04_integration` | 0 | PASS |
| `m39_v04_tornado_inflight` | 0 | PASS |
| `m40_save_system` | 0 | PASS |
| `m40_v02_safety` | 0 | PASS |
| `m40_v03_canonical` | 0 | PASS |
| `m40_v04_bootstrap` | 0 | PASS |
| `m41_settings` | 0 | PASS |
| `m42_home` | 0 | PASS |
| `m42_home_composition` | 0 | 9/9, 0 failures |
| `m42_home_v04` | 0 | 18/18, 0 failures |
| `m42_home_v05` | 0 | 13/13, 0 failures |
| `m42_home_v06` | 0 | 13/13, 0 failures |
| `m42_home_v07_safe_area` | 0 | 9/9, 0 failures |
| `m42_navigation` | 0 | PASS |
| `m43_master_c005_meta_ceremonies` (Gift ceremonies) | 0 | PASS (32/32) |
| `m43_master_c005r_gift_micro_progress` | 0 | PASS (8/8) |
| `m43_c005_c001_ceremony_visual_masters` | 0 | PASS (17/17) |
| `m43_master_c009_daily` (Daily/Tasks) | 0 | PASS (12/12) |
| `m43_master_c010_meta` | 0 | PASS (12/12) |
| `m43_master_c011_c014` | 0 | PASS (28/28) |
| `m43_c003_c001_acquisition` (C003 acquisitions) | 0 | PASS (34/34) |
| `m43_c005f_phase3_meta_rewards_acquisition` (Phase 3 feel) | 0 | PASS (15/15), 1 announced fault-injection SCRIPT ERROR (baseline) |
| `m43_c005f_phase2_r01_earned_pack_runtime` | 0 | PASS (22/22), 3 announced fault injections (baseline) |
| `m43_c005f_phase1_foundation` | 0 | PASS (23/23), 1 announced fault injection (baseline) |
| `m43_c005f_phase2_results_pack_feel` | 0 | PASS (22/22), 6 announced fault injections (baseline) |
| `m43_master_c005f_feel` | 0 | PASS (10/10) |
| `m43_r15_owner_remediation` (Rewarded Ads functional) | 0 | PASS (18/18) |
| `m43_r15_001_r01_sequential_unlock` (Rewarded Ads sequential) | 0 | PASS (14/14) |
| `m43_c002_c001_popup_modal_pause` | 0 | PASS (23/23) |
| `m43_c004_c001_fail_need_a_hand` | 0 | PASS (40/40) |
| `m43_master_c006_shop` | 0 | PASS (11/11) |
| `m43_master_c007_collection` | 0 | PASS (13/13) |
| `m43_master_c007r_pity` | 0 | PASS (9/9) |
| `m43_master_c008_robots` | 0 | PASS (10/10) |
| `m43_c005_c008_pack_commit_transaction` | 0 | PASS (27/27) |
| `m43_c005_c009_card_state_celebration` | 0 | PASS (25/25) |
| `m54_collection_set_master_exactly_once` | 0 | PASS |
| `m55_economy_release_regression` | 0 | PASS |
| `m30_completion_authority` | 0 | PASS |
| `m30_manual_playtest_smoke` | 0 | PASS |
| `cp04_remote_content_runtime` | 0 | PASS (28/28) |
| `cp05_remote_content_cache` | 0 | PASS (15/15) |
| root `tests/run_tests.gd` | 0 | RESULT: ALL PASS |
| headless import (TEMP, after all edits) | 0 | clean |
| headless boot (`--quit-after 120`) | 0 | clean; only the engine exit notice `29 resources still in use at exit` (same as every baseline) |
| `git diff --check` | 0 | clean |

54/54 suites PASS. The only first-run failure was the focused suite's own float/int assertion, disclosed in §3. No existing suite failed on its first run.

## 5. Changed-file set

```text
M  data/config/comeback_v1.json
M  data/config/economy_rewards_v1.json
M  data/config/events_v1.json
M  data/config/rewarded_daily_v1.json
M  scripts/economy/daily_service.gd
M  scripts/economy/economy_config.gd
M  scripts/economy/economy_services.gd
M  scripts/economy/rewarded_daily_service.gd
M  scripts/ui/ceremony/meta_ceremonies.gd
M  scripts/ui/daily/daily_screens.gd
M  scripts/ui/ui_text.gd
A  scripts/economy/random_booster_reward_picker.gd
A  tests/m39_c003_random_any_booster_rewards.gd
A  tests/tools/random_any_booster_evidence.gd
M  tests/m39_v03_full_surface.gd
M  tests/m39a_economy_core.gd
M  tests/m39d_daily_collection.gd
M  tests/m42_home.gd
M  tests/m43_c005_c001_ceremony_visual_masters.gd
M  tests/m43_c005f_phase3_meta_rewards_acquisition.gd
M  tests/m43_master_c009_daily.gd
M  tests/m43_r15_owner_remediation.gd
M  tests/tools/ceremony_preview/ceremony_candidates.gd
M  tests/tools/ceremony_preview/ceremony_snapshot.gd
A  coordination/sessions/M39-C003/evidence/gift_50_mystery_booster.png
A  coordination/sessions/M39-C003/evidence/scrubbox_mystery_booster.png
A  coordination/sessions/M39-C003/M39_C003_SB_M39_054_CLAUDE_LOG_V01.md
```

Import-generated `.import` / `.uid` artifacts in TEMP were not committed.

## 6. Final Desktop sync (after push)

After the push, the Desktop checkout is fast-forwarded with `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` and `merge --ff-only origin/main`.
- Owner `project.godot` is never touched.
- Its SHA-256 is re-verified against `d2546c0b…3574`.

The resulting HEAD, `origin/main`, 0/0 and hash check are reported in the hand-off response. A commit cannot contain the result of its own post-push sync.

## 7. Status

`AWAITING_GPT_SB_M39_054_STRICT_AUDIT`. No self-awarded audit verdict.
