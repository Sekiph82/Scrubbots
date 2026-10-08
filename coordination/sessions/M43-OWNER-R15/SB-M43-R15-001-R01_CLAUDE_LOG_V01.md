# SB-M43-R15-001-R01 — Rewarded Ads Sequential Unlock — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-OWNER-R15/CHATGPT_PROMPT_R15_001_R01_SEQUENTIAL_UNLOCK_V01.md`
- Criteria: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_CRITERIA_R15_001_R01_SEQUENTIAL_UNLOCK_V01.md`
- Repository / branch: `Sekiph82/Scrubbots` / `main`, owner-local checkout `C:/Users/sekip/Desktop/ScrubBots`
- Godot: 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `d5eead7d08aa3a05ad01e8553ef8a3a2c2a7312c` (= `origin/main` after sync)
- Final SHA: the implementation commit that adds this log (reported in the hand-off message)

## 1. Owner-local sync evidence

- Before sync: local `main` was at `7d0d148b` and `origin/main` was at `d5eead7d`, so local was 0 ahead and 5 behind. Those five upstream commits were the VOID audit, TASKS updates, and this prompt and its criteria.
- `git fetch` was followed by `git merge --ff-only origin/main`, a non-destructive fast-forward. There was no reset, clean, stash, or force.
- Pre-existing owner-local work was preserved, untouched and uncommitted:
  - modified `project.godot`, `scenes/app/main.tscn` and the two owner-review `.tscn` files;
  - untracked `addons/`, `.mcp.json`, art/source PNGs, and `.uid` / `.import` files.
- Other Codex worktrees (`m42-c003-v02`, `m43-c005-c002-v02`, `m43-c005-c003-cards`) were not touched.
- Root `TASKS.md` was **not** edited.

## 2. Design

The sequential position is **derived** from the canonical `RewardGrantService` applied-tx ledger that R15 already uses. There is no new ledger and no save section.

- `current_slot(day)` returns the lowest slot `n` in 1..5 whose `daily_rewarded:<day>:<n>` is not applied, or 6 when all five are granted.
- A slot `n > current_slot()` is `locked_sequence`.
- **Precedence** in `slot_state`: `unavailable` (bad config) > `claimed` > `locked_rollback` > `locked_sequence` > `ready_free` / `ready_ad` / `pending` / `ad_unavailable`.
- **Enforced twice, both before any provider request:**
  - `RewardedDailyService.start_ad` returns `locked_sequence` before calling the grant service.
  - `RewardedGrantService.can_start_daily` / `start_daily_slot` require `daily_rewarded:<day>:1..n-1` to be applied, so even a direct call into the lower service cannot start a future slot.
- Grants still happen only in `RewardedGrantService.resolve` on `completed` + `verified == true`, under the unchanged deterministic id `daily_rewarded:<day>:<slot>`. A no-grant outcome therefore writes nothing and cannot move `current_slot`. A duplicate or late callback hits the same deterministic id, so it is idempotent.
- Pending requests are still session-local. After a relaunch the position comes only from durable grants.
- **Forward day:** `current_slot` for a new day is 1.
- **Rollback:** the existing high-water lock takes precedence over the sequence lock and is unchanged.
- **Legacy ledgers** written under the superseded parallel rule (for example slots {1,4} granted) cannot reopen or skip anything. Granted slots stay `claimed`, and the frontier walks to the lowest ungranted slot.

## 3. Progression-state truth table (TEST provider available, current local day)

| Granted today | Slot 1 | Slot 2 | Slot 3 | Slot 4 | Slot 5 | `current_slot` |
|---|---|---|---|---|---|---|
| none (fresh day) | ready_free | locked_sequence | locked_sequence | locked_sequence | locked_sequence | 1 |
| 1 | claimed | ready_ad | locked_sequence | locked_sequence | locked_sequence | 2 |
| 1, slot 2 pending | claimed | pending | locked_sequence | locked_sequence | locked_sequence | 2 |
| 1 + any no-grant outcome on 2 | claimed | ready_ad | locked_sequence | locked_sequence | locked_sequence | 2 |
| 1-2 | claimed | claimed | ready_ad | locked_sequence | locked_sequence | 3 |
| 1-3 | claimed | claimed | claimed | ready_ad | locked_sequence | 4 |
| 1-4 | claimed | claimed | claimed | claimed | ready_ad | 5 |
| 1-5 | claimed | claimed | claimed | claimed | claimed | 6 |
| 1, production provider (unavailable until M57) | claimed | ad_unavailable | locked_sequence | locked_sequence | locked_sequence | 2 |
| any, local day < high-water | claimed / locked_rollback | locked_rollback | locked_rollback | locked_rollback | locked_rollback | (refused) |
| forward local day | ready_free | locked_sequence | locked_sequence | locked_sequence | locked_sequence | 1 |
| legacy {1,4} (old parallel rule) | claimed | ready_ad | locked_sequence | claimed | locked_sequence | 2 |

Refusal reasons:
- `locked_sequence`: a future slot, refused with no provider request.
- `pending`: the current slot was started a second time.
- `already_claimed`, `clock_rollback`, `unavailable` and `provider_refused`: unchanged.

## 4. Exact files changed

Code:
- `scripts/economy/rewarded_daily_service.gd`:
  - adds `current_slot()`, `is_sequence_locked()` and the `locked_sequence` state;
  - `start_ad` refuses future slots before the provider is asked;
  - header doc updated.
- `scripts/economy/rewarded_grant_service.gd`: `can_start_daily` (and therefore `start_daily_slot`) refuses slot `n` unless slots 1..n-1 of that day are granted.
- `scripts/ui/daily/rewarded_ads_screen.gd`:
  - the `locked_sequence` row shows CTA **LOCKED**, disabled, with state text "Unlocks after reward n-1";
  - `locked_sequence` maps to an order note.
  - No geometry, art, or row-count change.
- `scripts/ui/ui_text.gd`: three new strings: `RADS_STATE_NEXT`, `RADS_LOCKED` and `RADS_ORDER_NOTE`.

Tests:
- `tests/m43_r15_001_r01_sequential_unlock.gd` (new): the focused R01 suite, 14 cases.
- `tests/m43_r15_owner_remediation.gd`: assertions that encoded the superseded parallel rule were moved to the owner's sequential rule. Every case and every non-sequence assertion is kept.
  - **r02:** a fresh day is `[ready_free, locked×4]`.
  - **r03:** the production provider is checked after the slot 1 claim. Slot 2 is `unavailable` and slots 3-5 are `locked_sequence`.
  - **r04:** the no-grant loop now runs on slot 2, the chain walks 2→3, and then the original slot-4 pending / tx / duplicate checks and the slot-5 abandon / late checks run.
  - **r05:** refusal and unavailable are checked on slot 2, with no advance.
  - **r06 / r07:** the expected state vectors are sequential.
  - **r08:** relaunch is checked after slots 1-3. Slot 4 is next and slot 5 is `locked_sequence`.
  - **r10:** the real popup shows LOCKED rows, slot 2 cancel then verify, then slot 3 unlocks.
  - Result: 18/18 cases; 115 ok assertions, up from 110.

Evidence: this log.

**Not touched** (verified with `git diff --name-only`):
- `scripts/content_runtime/**`, `data/config/remote_content_runtime_v1.json` and `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/**`;
- Level Factory / R2 / publisher code;
- root `TASKS.md`;
- `data/config/rewarded_daily_v1.json` (bundles unchanged);
- the Home screen, Home badges and the R15-004 CTA code;
- the Daily / Orders / Gift / Hearts / boosters / 2x services.

## 5. Test results (owner-local checkout, headless)

| Suite | Result |
|---|---|
| `tests/m43_r15_001_r01_sequential_unlock.gd` (focused, new) | **PASS 14/14 cases, 68 ok, 0 fail** |
| `tests/m43_r15_owner_remediation.gd` (existing R15) baseline before changes | PASS 18/18 (110 ok) |
| `tests/m43_r15_owner_remediation.gd` after changes | **PASS 18/18 (115 ok)** |
| `tests/run_tests.gd` (root) | **5329 / 5329 ALL PASS** |
| Regressions | see section 5.1 |

Focused case coverage:
- **s01:** a fresh day exposes only slot 1. Slots 2-5 are refused with zero provider requests.
- **s02:**
  - the slot 1 claim unlocks only slot 2;
  - each verified grant on slots 2, 3 and 4 unlocks only the next slot;
  - the slot 5 grant completes the day (`current_slot` = 6);
  - at every step, every later slot is refused before the provider is asked.
- **s03:** facade, `RewardedDailyService.start_ad`, `RewardedGrantService.start_daily_slot` and `can_start_daily` for slots 3, 4 and 5 all fail closed with `locked_sequence`. There is no request, nothing pending, and nothing granted.
- **s04:** none of these advance the sequence:
  - outcomes: cancelled, skipped, failed, timeout, verified `false`, verified `"true"` (string), empty outcome;
  - an abandoned (UI timeout) request;
  - an unknown token;
  - provider refusal;
  - provider unavailable.

  A later verified completion still unlocks exactly slot 3.
- **s05:** while slot 3 is pending, slots 4-5 stay locked and slot 3 cannot start twice. There is no new request.
- **s06:**
  - a duplicate callback does not double-advance;
  - a late callback after abandon grants nothing;
  - a request started on day D and verified after midnight grants D's slot only, and D+1 stays at slot 1.
- **s07:**
  - a relaunch from the saved ledger reconstructs exactly slots 1-3 claimed, slot 4 next and slot 5 locked;
  - a pending slot 4 at shutdown is never granted;
  - there is no new save section.
- **s08:** a forward local day returns to slot 1, under a new deterministic id.
- **s09:**
  - rollback below the high-water day refuses every slot with no request;
  - returning to the high-water day restores the exact position.
- **s10:** a legacy partial ledger {1,4} walks 2 → 3 → 5 and never re-grants 4.
- **s11:** the booster rewarded grant is unchanged (`rewarded:<token>`, placement `rewarded_booster_random`) and does not advance the daily track. The Heart full / not-full rule is unchanged.
- **s12:** after the full five-slot track these sections are unchanged:
  - Gift, streak, robots, hearts, speed / 2x;
  - Daily login, Daily Scrub Orders;
  - records, events, return, notifications, pack pity, pack receipts.

  `collection` changes only because the slot 2, 4 and 5 card-pack bundles open immediately (pre-existing M39 grant-and-resolve semantics).
- **s13:** in the real app popup:
  - there are exactly five rows; rows 2-5 show LOCKED (disabled) with "Unlocks after reward n-1" and the configured reward text;
  - pressing the locked rows sends nothing;
  - after CLAIM only slot 2 becomes WATCH AD.
- **s14:** the Home CTA is still under COLLECTION at the same size and x position. The `HomeBadges` model has no Rewarded Ads entry, so there is no Home badge.

### 5.1 Regressions

| Suite | Result (exit 0, 0 FAIL, 0 SCRIPT ERROR) |
|---|---|
| M39 Daily: `m39d_daily_collection` | PASS |
| M39 full matrix: `m39e_full_matrix` | PASS |
| M40 save: `m40_save_system`, `m40_v02_safety`, `m40_v03_canonical`, `m40_v04_bootstrap` | PASS (all four) |
| M41 settings: `m41_settings` | PASS |
| M43 acquisition: `m43_c003_c001_acquisition` | PASS 34/34 |
| M43 Need a Hand: `m43_c004_c001_fail_need_a_hand` | PASS 40/40 |
| M43 Daily / Tasks / Gift: `m43_master_c009_daily` | PASS 12/12 |
| M43 meta (badges): `m43_master_c010_meta` | PASS 12/12 |
| M43 C011-C014: `m43_master_c011_c014` | PASS 28/28 |
| M43 popup / modal: `m43_c002_c001_popup_modal_pause` | PASS 23/23 |
| M42 Home: `m42_home` | PASS |

`git diff --check`: clean.
No unexplained script errors. The only engine `ERROR:` lines are the standard headless exit-time resource / ObjectDB leak notices, which are also present in the baseline runs.

## 6. Governance

- The original R15-001 owner visual gate is **not** closed by this functional remediation.
- Remote Content / R2 files were explicitly left untouched (section 4).
- No audit verdict is claimed.

AWAITING_GPT_SB_M43_R15_001_R01_AUDIT
