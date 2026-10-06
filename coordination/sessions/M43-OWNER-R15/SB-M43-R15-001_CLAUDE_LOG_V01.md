# SB-M43-R15-001 — REWARDED ADS DAILY FIVE-SLOT SURFACE — CLAUDE LOG V01

Prompt: `coordination/sessions/M43-OWNER-R15/CHATGPT_PROMPT_V01.md` §1.
Code commit: `24828bb`. Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit.

## Files changed

| File | Change |
|---|---|
| `data/config/rewarded_daily_v1.json` | **new**. `scrubbots.rewarded_daily.v1` v1 holds exactly 5 slots: slot 1 `requires_ad:false`, slots 2–5 `true`. The bundles are copied 1:1 from `economy_rewards_v1.json` `daily.login_rewards` D1..D5 (no value invented). |
| `scripts/economy/rewarded_daily_service.gd` | **new**. Strict config load (fails closed); slot states; slot 1 `claim_free()`; slots 2–5 `start_ad()` routed through the canonical rewarded authority; derived rollback high-water. |
| `scripts/economy/rewarded_grant_service.gd` | Narrow extension for daily slots: `start_daily_slot(day, slot, rewards, token)`, `can_start_daily`, `daily_tx`, placement `rewarded_daily_slot_<n>`. `resolve()` grants a daily-slot request under its stored deterministic tx instead of `rewarded:<token>`. Heart / booster paths are unchanged. |
| `scripts/economy/reward_grant_service.gd` | Read-only `applied_ids()`. |
| `scripts/economy/economy_services.gd` | Owns `rewarded_daily`, built on the same `RewardGrantService` / `RewardedGrantService` and on DailyService's existing `local_day()` (one calendar). |
| `scripts/economy/production_action_facade.gd` | `claim_rewarded_daily_free()` (committed and saved through `_finish`) and `start_rewarded_daily(slot)`. |
| `scripts/ui/daily/rewarded_ads_screen.gd` | **new**. REWARDED ADS popup (BasePopup, large frame, no floating hero, five cream rows, green CTA, tan CLOSE). |
| `scripts/ui/home/home_screen.gd` | Compact REWARDED ADS CTA. It is a child of `Shortcut_daily`, anchored 14 px under DAILY, 210×88, green M43 CTA with the native PLAY triangle, and disabled unless the app registers the destination. |
| `scripts/app/main.gd` | `rewarded_ads` app shortcut opens `RewardedAdsScreen`. |
| `scripts/ui/ui_text.gd` | Copy keys `HOME_SC_REWARDED_ADS`, `RADS_*`. |
| `scripts/ui/feel/meta_feedback.gd` | `claim_rewarded_daily` maps to the existing `reward` moment. |
| `tests/m43_r15_owner_remediation.gd` | **new**. Cases r01–r11. |
| `tests/tools/r15_snapshot.gd` | **new**. Evidence tool. |

## Architecture / authority preserved

**Home.** The four primary panels are untouched: SHOP / COLLECTION / TASKS / DAILY. The closed M42 tests pinning the column children still pass. The CTA is not a fifth panel. It hangs under DAILY and hides with the action layer under a modal. It only emits `shortcut_requested("rewarded_ads")`, with no economy access.

**One rewarded authority.** Slots 2–5 go `RewardedDailyService.start_ad`, then `RewardedGrantService.start_daily_slot`, then `provider.request`, then `RewardedGrantService.resolve`. A grant happens only when the outcome is `completed` and `verified == true` (a real bool). There is no second callback-to-reward path.

**Deterministic economy identity.** The canonical `RewardGrantService` tx is `daily_rewarded:<local_day>:<slot>`.
- Slot 1 is a direct exactly-once grant with no ad request.
- The provider token is never the economy idempotency key (r04 asserts that `rewarded:<token>` is never applied).

**Local-day safety, with no new save section and no migration.**
- Claimed state and the rollback high-water day are derived from the canonical applied-tx ledger, which M40 already persists atomically with each grant.
- An old save simply has no `daily_rewarded:*` ids, so the track starts fresh.
- If today's local day is below the highest granted day, every slot is `locked_rollback`: the free claim and ad requests are refused and no provider request is sent.
- A new forward local day offers five fresh slots.

**Unchanged systems.** Daily login streak / cycle / claim, Daily Scrub Orders, Gift Meter, pack RNG, Hearts, boosters and 2x are untouched. r02 asserts the Daily streak, claim state, orders and gift snapshots; the M39d / C009 suites pass.

**Production provider.** The default `RewardedAdProvider` is unchanged and stays honestly unavailable: slots 2–5 show a disabled **NO VIDEO**. The test provider exists only inside the test and evidence scripts.

## Focused tests

`tests/m43_r15_owner_remediation.gd` → **PASS 17/17** (this child: r01–r11).

- **r01:** bundles == Daily D1..D5. Schema v1; slot 1 has no ad, 2–5 need one. Seven malformed configs (4 slots, slot 1 needing an ad, slot 3 free, unknown resource, zero amount, duplicate slot, future version) disable the track.
- **r02:** slot 1 gives +100 SB under `daily_rewarded:<day>:1` once; a second claim is refused. Daily streak, claim, Gift and Orders are untouched, and the Daily login still claims independently.
- **r03:** with the production provider, slots 2–5 are refused as `unavailable` and nothing is granted.
- **r04:**
  - Cancelled, skipped, failed, timeout, unverified (`false`), string `"true"` and empty outcomes all grant nothing.
  - A pending slot cannot start twice; placement is `rewarded_daily_slot_4`; token ≠ tx.
  - A verified completion grants the slot bundle only under `daily_rewarded:<day>:4`.
  - A duplicate callback grants nothing; re-requesting a granted slot is refused.
  - A UI-timeout abandon followed by a late callback grants nothing; an unknown token grants nothing.
  - Each slot can be granted exactly once.
- **r05:** provider refusal or unavailability grants nothing.
- **r06:** the next local day offers five fresh slots, and both days' ids are kept.
- **r07:** after rolling back to an earlier day, every slot is locked, nothing is granted and no request is sent. A deeper rollback is still refused. Returning forward restores the true state.
- **r08:** after relaunch, granted slots stay claimed and cannot be re-granted; the rollback lock survives relaunch; there is no new save section.
- **r09:** the heart / booster product list, placement and `rewarded:<token>` tx are unchanged.
- **r10** (real app root):
  - The CTA is live and attached to DAILY, with the four panels unchanged.
  - The popup is in the BasePopup family with exactly five rows, each showing its config text.
  - In production: CLAIM plus four disabled NO VIDEO. CLAIM gives +100 SB, then CLAIMED and the "Collected" note.
  - With the injected test provider: WATCH AD; pending is busy with nothing granted; cancel shows "No reward" and the slot stays available; a verified completion grants Random Booster x1 and shows CLAIMED.
- **r11:** the CTA is inside the viewport, ≥ 88 px, and overlaps none of PLAY, the Journey strip, Gift Meter, BottomNav, the track, the four panels or the HUD, and is clear of Scrubby. This holds at 683×1366, 720×1280, 1080×1920, 1080×2160, 1170×2532, 1290×2796 and 1536×2048, each rendered at its stretch-expand logical canvas.

Regression and root results are in `M43_OWNER_R15_MASTER_CLAUDE_LOG_V01.md`. All PASS, including acquisition 34/34 (Heart / booster rewarded) and C004 40/40.

## Evidence

`coordination/sessions/M43-OWNER-R15/evidence/` (rendered real app root; each at 683×1366 and 1080×2160):
- `1_home_rewarded_ads_cta_*`
- `2_rewarded_ads_fresh_slot1_ready_production_no_video_*`
- `3_rewarded_ads_slot1_claimed_production_provider_unavailable_*`
- `4_TEST_PROVIDER_rewarded_ads_watch_ad_*`
- `5_TEST_PROVIDER_rewarded_ads_verified_slot2_claimed_*`

Frames 4–5 use an injected **test** provider. They carry an on-image red banner, "TEST / EVIDENCE PROVIDER - NOT PRODUCTION (no ad SDK; M57 gate)", and do not imply a production ad SDK exists.

## Remaining owner / provider gates

- **M57:** real rewarded-video SDK / provider, placement-id mapping, frequency / cooldown caps, regional policy, No-Ads interaction. Until then slots 2–5 show NO VIDEO in production.
- **Owner presentation acceptance** of the CTA placement and popup.
- **Not invented:** no slot ordering (any ready slot may be claimed) and no Home badge for the track. Both are owner choices if wanted.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-R15-001
