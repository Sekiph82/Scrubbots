# M43-C003-C001 — ACQUISITION MATRIX V01

Date: 2026-09-28
Implementer: Claude
Status: AWAITING_CHATGPT_AUDIT
Scope: SB-M43-030..049

- Focused suite: `tests/m43_c003_c001_acquisition.gd` — 34 ledger cases, covering the 32 required tests plus the responsive matrix and the production-provider check.
- Evidence: `tests/tools/acquisition_snapshot.gd` renders 27 PNGs into `evidence/`.

## 1. Architecture (reuses the M43-C002 foundation; no second popup, modal or economy authority)

| Piece | File | Role |
|---|---|---|
| `RewardedAdProvider` | `scripts/economy/rewarded_ad_provider.gd` | **New.** Provider-neutral seam: `is_available(placement)` and `request(placement, token, deliver)`. The base class is the production default: **every placement is unavailable** until M57. It hardcodes no SDK, placement ids, frequency, cooldown or caps. |
| `RewardedGrantService` | `scripts/economy/rewarded_grant_service.gd` | **New.** The one rewarded-grant authority. Rules are in §3. |
| `EconomyServices` | `scripts/economy/economy_services.gd` | Owns `rewarded`. Registers the `rewarded_heart` handler (→ `HeartService.grant_one`) and `booster_charge_<id>` handlers (→ `BoosterInventory.add_charges`). |
| `HeartService.grant_one()` | `scripts/economy/heart_service.gd` | +1 without SB, never above max. Only the reward handler calls it. |
| `SpeedEntitlementService.is_level_entitled()` | `scripts/economy/speed_entitlement_service.gd` | Read-only query so the popup can show level vs timed state separately. |
| `ProductionActionFacade` | `scripts/economy/production_action_facade.gd` | Adds `rewarded_available(product)` and `start_rewarded(product, token)`. SB actions are unchanged: `buy_heart`, `refill_hearts`, the 2x purchases and the booster actions. |
| `AppState` | `scripts/app/app_state.gd` | `economy.rewarded.bind_save(request_save)`. |
| `ShopHandoff` | `scripts/app/shop_handoff.gd` | **New.** Canonical Shop/SB intent. Each ticket is a detached deep copy of the context plus `ticket_id` and `source`. `finish(ticket_id, outcome)` resolves exactly once. It sells nothing and moves no currency. |
| `AcquisitionFlow` | `scripts/ui/popup/acquisition_flow.gd` | **New.** The one controller for Life, Booster Acquire, insufficient SB and the Shop state, built on `BasePopup` + `ModalStack`. Presentation and intent only. |
| `SpeedAcquisitionPopup` | `scripts/ui/speed_acquisition_popup.gd` | **Rewritten** as a `BasePopup` subclass: the canonical 2x Acquire popup on the stack. The old `PanelContainer` is gone, so there is no parallel modal. |
| `BasePopup` | `scripts/ui/popup/base_popup.gd` | Additive options, all off by default so the approved C002 visuals do not change: hero art above the frame, a yellow `"offer"` CTA, action rows, `set_action_visible/blocked`, `add_footer_note`, and `rearm_soon()` (double-tap guard). |
| Host | `scripts/gameplay/runtime/production_gameplay_host.gd` | Adds `booster_legality(id)`, `execute_booster(id, target)`, booster routing (zero charge → Acquire; owned Selector/Tornado → USE mode), the canonical 2x popup, and the Restart zero-Heart gate. |
| App root | `scripts/app/main.gd` | Owns `ShopHandoff` + `AcquisitionFlow` and injects the flow into each host. Wires Home Heart + → Life and Home SB + → Shop. Adds zero-Heart gates on PLAY, Results Continue and Results Retry. |

## 2. Row → implementation → proof

| Row | Implementation | Test case(s) |
|---|---|---|
| 030 Life popup from the Life reference | `open_life`: sprout-Scrubby hero over the frame (`help_scrubby_pose`), royal LIFE pill, big `heart_large` with a live count, "Next life in:" panel with a clock pill, balance, yellow SB offers with +N badges, green FREE video CTA, cheer note | c01, evidence `life_*` |
| 031 Live Hearts + countdown; 5/5 static 15:00 | `life_model()` reads `HeartService.hearts/seconds_to_next`. A 1 s popup-owned redraw timer re-reads authority. Full shows the regen interval (900 s = 15:00) as static text. | c03, c04 |
| 032 Home Heart + and zero-Heart gate → the same Life | `home.hearts_purchase_requested` → `main.open_life`. `_zero_heart_gate` on PLAY, Continue and Retry. Host Restart gate when `hearts_after < 1`. | c01, c02 |
| 033 +1 Heart 500 / refill 400 × missing | `actions.buy_heart()` / `refill_hearts()` (HeartService is atomic and computes cost at commit) | c05–c08 |
| 034 Rewarded +1 Heart when available; clean unavailable state | `rewarded.can_start("heart")` → FREE, otherwise disabled **NO VIDEO** + note | c09, `production_provider_unavailable`, evidence |
| 035 Exactly once per verified completion | `RewardedGrantService.resolve` + persisted tx id | c09–c12, c32 |
| 036 Home SB + → Shop with return context | `home.scrub_bucks_purchase_requested` → `AcquisitionFlow.open_shop` → `ShopHandoff` ticket → explicit "Shop coming soon" state → `finish(..., "cancelled")` | c13 |
| 037 One data-driven Booster Acquire | `open_booster(host, id)` + `BOOSTER_DEFS` (no per-booster scene) | c14 |
| 038 Icon / name / effect / owned / live price | Production booster icons; `UiText` names and effects; `boosters.charges`; `config.booster_price` | c15 |
| 039 Charge-first; no purchase UI when a charge exists | +1 Slot / Random with a charge run directly. Selector / Tornado with a charge open USE mode (target picker only, no purchase CTA). | c16 |
| 040–043 Zero charge: SB one use (500/350/500/750) or rewarded | `sb` → `host.execute_booster` → `BoosterService` (safety pre-check, then reserve SB, then refund on failure) | c17, c18 |
| 044 Rewarded never bypasses legality; illegal → charge kept | Reward commits +1 charge. Execution only via `execute_booster` when `booster_legality` passes and a target is chosen; otherwise "Booster saved!" | c20, c21 |
| 045 2x Acquire: 200 / 300 / 500 / 750 | `SpeedAcquisitionPopup` with `speed_offers()` from `EconomyConfig` | c23 |
| 046 Entitlement state; no recharge while active | `speed_state()` (level / timed remaining, live 1 s refresh). An entitled press toggles without the popup. The level offer shows ACTIVE and is blocked. Timed offers read "+15 MIN" (extend). | c24, c26 |
| 047 Free auto-2x never opens purchase or touches entitlement | Unchanged host rule: a press while 2x goes back to 1x. `SpeedEntitlementService` is never called. | c28 |
| 048 Insufficient / rapid taps / background / ad unavailable / retry | Shared insufficient → Shop path; `rearm_soon` double-tap guard; busy pending with a UI timeout (`abandon`); `pending` product guard | c06, c22, c27, c29, c12, c10 |
| 049 Visual masters | Candidates in the approved popup family (§4). **Owner review required.** | evidence + `OWNER_ACQUISITION_REVIEW_V01.md` |
| Modal isolation / accumulation | C002 modal hold + scrim | c30, c31 |

## 3. Rewarded integrity rules (RewardedGrantService)

- **Products:** `heart` and `booster:<id>` for exactly the four boosters. There is **no rewarded 2x.**
- **Offer gate:** `can_start` requires a known product, `provider.is_available(placement)`, no request already pending for that product, and (for Heart) Hearts not full.
- **Commit:** `start` records a pending token (or uses a provider transaction id). `resolve(token, result)` runs once per token. It commits only when `outcome == "completed"` and `verified is true`. It checks Hearts again at commit time (`already_full` fails closed). The grant goes through `RewardGrantService.grant("rewarded:<token>", ...)`, which is atomic, idempotent, and persists its applied-tx set. Only then does it call `request_save()` and emit `resolved`.
- **No grant:**
  - `cancelled`, `skipped`, `failed`, `timeout`, unverified, unknown token, duplicate;
  - a UI timeout calls `abandon(token)`, and a later completion for that token is a duplicate that grants nothing;
  - after relaunch, pending tokens are gone (the token is unknown) and applied tokens remain persisted, so a replayed callback is still a duplicate.

## 4. Assets (existing production art only; no art generated)

Frames: `popup_medium_frame` for Life, Booster, 2x, Shop and insufficient SB.

| Asset | Use |
|---|---|
| `popups/help/help_scrubby_pose.png` | Life hero (the reference's sprout Scrubby) |
| `popups/failure/heart_large.png` | Life heart |
| `common/icons/icon_clock.png` | Countdown pill |
| `common/currencies/icon_currency_heart.png` | Heart +N badges |
| `common/currencies/icon_currency_scrub_bucks.png` | Balance row |
| `boosters/extra_slot.png`, `random.png`, `selector.png`, `tornado.png` | Booster Acquire |
| `shop/shop_speed_2x_icon.png` | 2x Acquire |
| `shop/shop_header_emblem.png` | Shop state |

The play glyph on FREE and the yellow offer body are native Godot drawing / StyleBoxes. All counts, prices, timers and balances are live Labels.

## 5. Evidence (`evidence/`)

| Required | File(s) |
|---|---|
| Life partial | `life_partial_rewarded_available_1080x2160.png` |
| Life full 5/5 | `life_full_5of5_1080x2160.png` |
| Life insufficient SB | `life_insufficient_sb_1080x2160.png` |
| Life rewarded available / unavailable / loading | `life_partial_rewarded_available_*`, `life_rewarded_unavailable_*`, `life_rewarded_loading_*` |
| Zero-Heart gate | `life_zero_heart_gate_1080x2160.png` |
| Booster +1 Slot / Random / Selector / Tornado | `booster_plus_one_slot_*`, `booster_random_*`, `booster_selector_*`, `booster_tornado_*` |
| Booster rewarded available / unavailable | `booster_*_1080x2160.png` (available), `booster_tornado_rewarded_unavailable_*` |
| Booster owned USE mode / safety state | `booster_selector_owned_use_mode_*`, `booster_plus_one_slot_already_used_*` |
| Booster insufficient → Shop | `booster_insufficient_sb_*`, `booster_shop_handoff_*` |
| Home SB + → Shop | `shop_handoff_from_home_sb_plus_*` |
| 2x no entitlement / timed active / insufficient | `speed_no_entitlement_*`, `speed_timed_active_*`, `speed_insufficient_sb_*` |
| Short phone 1080×1920 | `life_short_phone_*`, `booster_selector_short_phone_*`, `speed_short_phone_*` |
| 1170×2532 / 1290×2796 | `life_phone_1170_*`, `booster_tornado_phone_1290_*` |
| Tablet 1536×2048 | `life_tablet_*`, `booster_tornado_tablet_*`, `speed_tablet_*` |

The `responsive_matrix` case checks 7 surfaces at each of the 5 sizes: Life, +1 Slot, Selector, Tornado, 2x, insufficient SB and Shop. It uses synthetic insets of 96 px top and 64 px bottom. Every surface stays inside the safe area, nothing clips, and every CTA and target chip is at least 88 px.
