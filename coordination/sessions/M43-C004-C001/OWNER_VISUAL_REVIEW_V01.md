# M43-C004-C001 — Owner Visual Review V01

Date: 2026-10-02
Status: **OWNER_REVIEW_REQUIRED.** This is not self-approved. Final visuals close only after the ChatGPT technical audit and an owner decision.
Evidence: `coordination/sessions/M43-C004-C001/evidence/`. These are real production renders: `main.tscn`, the real gameplay host on catalog level 2, and the real terminal signal.

Reproduce the evidence with:

```bash
godot --path . -s res://tests/tools/fail_need_a_hand_snapshot.gd -- coordination/sessions/M43-C004-C001/evidence
```

## 1. What to look at

| Surface | Evidence file(s) |
|---|---|
| Fail, reference phone | `fail_reference_phone_1080x2160.png` |
| Fail, short phone / 1170 / tablet | `fail_short_phone_1080x1920.png`, `fail_phone_1170_1170x2532.png`, `fail_tablet_1536x2048.png` |
| Third-failure Need a Hand, 2 cards, 2 BUY + 2 WATCH AD, top-right X, no NO THANKS | `need_a_hand_third_failure_2buy_2watch_1080x2160.png` |
| Need a Hand, short phone / 1170 / 1290 / tablet | `need_a_hand_short_phone_1080x1920.png`, `need_a_hand_phone_1170_1170x2532.png`, `need_a_hand_phone_1290_1290x2796.png`, `need_a_hand_tablet_1536x2048.png` |
| One card's video unavailable (the other card's WATCH AD stays live) | `need_a_hand_one_card_rewarded_unavailable_1080x2160.png` |
| Production provider (no ads until M57): both WATCH AD shown and disabled | `need_a_hand_production_provider_unavailable_1080x2160.png` |
| Video loading (busy) | `need_a_hand_rewarded_loading_1080x2160.png` |
| Insufficient SB → Shop handoff | `need_a_hand_insufficient_sb_1080x2160.png`, `need_a_hand_shop_handoff_1080x2160.png` |
| Owned-charge card (charge-first) | `need_a_hand_owned_charge_1080x2160.png` |
| After a BUY (card flips to OWNED) | `need_a_hand_after_buy_1080x2160.png` |
| X closed → usable Fail | `fail_after_need_a_hand_closed_1080x2160.png` |
| Zero-Heart Retry → Life | `zero_heart_retry_life_1080x2160.png` |
| Reduced Effects | `fail_reduced_effects_1080x2160.png`, `need_a_hand_reduced_effects_1080x2160.png` |
| Lifecycle report | `evidence/LIFECYCLE_REPORT_V01.md` |

## 2. Owner decisions requested

1. **Failure pose.** No approved sad or failure Scrubby pose exists. Fail reuses the approved help Scrubby pose (`popups/help/help_scrubby_pose.png`) with the approved fail emblem (`popups/failure/fail_header_emblem.png`). No art was generated. Is this accepted, or should a dedicated sad pose be commissioned?
2. **Fail loss rows.** Fail shows "Hearts N → N-1" and "Win Streak N ended" (shown only when a streak was lost), plus the line "So close! Give it another try." Confirm the copy.
3. **Recommendation fallback order and weights** (`data/config/failure_assistance_v1.json`).
   - Fallback order: +1 Slot, Selector, Tornado, Random.
   - Context weights: all slots full → +1 Slot 2 / Selector 1; one colour ≥ 40% of the remaining cells → Tornado 2; supply left over → Selector 1.
   - Random is offered only when the ranking reaches it, because its solver proof is the costliest. This was measured at up to ~4.9 s headless on a 32×32 board.

   Approve, or give an order and weights.
4. **WATCH AD when no video is available.** Per the lock, each zero-charge card always shows both controls. When the provider has no video, WATCH AD stays visible but disabled, with "No video right now". Until M57 connects a provider, that is the production state on every card. Confirm this rather than hiding the button.
5. **Counter persistence.** The same-level counter is session-scoped (no save migration), so a cold relaunch restarts it. Persist it later?
6. **Card art direction.** Compared with `need a hand.png`:
   - kept: the cream frame, royal title pill, top-right X, two side-by-side cards with icon, name and benefit, and a Scrubby speech bubble;
   - differences: the X is the accepted royal family X, not the reference's red X; there is a gold BUY plus a green WATCH AD instead of a single green "Claim"; there is no clapper icon (no approved asset); there is a "no guarantee" footer line.

## 3. Unchanged accepted surfaces

- WON Results, Pause, Life, Booster Acquire and 2x are not restyled.
- The only shared addition is `BasePopup.add_action(..., parent)`, an opt-in that places a CTA inside a card.
