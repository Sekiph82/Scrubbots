# M43-C004-C001 — OWNER FAIL / RETRY / NEED-A-HAND LOCK V01

Date: 2026-10-02
Authority: OWNER
Status: IMPLEMENTATION AUTHORIZED
Scope: SB-M43-050..062

## 1. Visual family

Use the already accepted M43 popup family:
- cream panel;
- royal/cyan rim;
- live Godot text;
- existing Scrubby and booster art;
- 60% scrim;
- responsive native controls;
- no second popup/modal authority.

Canonical references:
- Need a Hand: `assets/art/references/_owner_inbox/Additionals/need a hand.png`
- Results family: M43-C001B
- Popup/modal family: M43-C002-C001
- Booster acquisition family: M43-C003-C001

## 2. Terminal Fail / Retry

Terminal LOST becomes the production Fail surface.

Required:
- sad/failure Scrubby presentation;
- `LEVEL FAILED`;
- authoritative already-committed loss truth;
- Retry primary;
- Home secondary;
- no Victory art;
- no Replay;
- no rewarded CTA on Fail itself.

Critical economy law:
terminal LOST already consumes the one Heart and resets the Win Streak through the accepted terminal path. Retry from terminal Fail must not consume a second Heart or reset the streak again.

If the terminal loss leaves 0 Hearts, Retry routes through the existing canonical Life gate.

M43-C002 Pause -> Restart remains a separate mid-attempt action with its existing consequence confirmation.

## 3. Same-level assistance trigger

For progression play:
- count consecutive terminal failures on the same progression level;
- third failure makes Need a Hand due;
- win resets;
- progression level change resets;
- replay failures do not increment;
- V1 default: show once at failure 3, then suppress until reset;
- keep threshold/repeat policy data-driven.

## 4. Need a Hand recommendations

Show exactly two distinct useful booster recommendations.

Use only the four canonical boosters:
- +1 Slot;
- Random;
- Selector;
- Tornado.

Recommendations:
- evaluate usefulness for the next canonical retry/start-state, not the already-terminal board;
- prefer solver/context evidence;
- never imply guaranteed success;
- use deterministic configurable fallback order when needed;
- if two meaningful recommendations cannot be established, fail closed and leave normal Fail/Retry usable.

## 5. Need a Hand card layout — OWNER LOCK

Need a Hand has exactly two booster cards.

Each card shows:
- booster icon;
- booster name;
- concise benefit text;
- owned charge count/state;
- canonical SB price;
- its own SB acquisition control;
- its own rewarded acquisition control.

### Two acquisition choices per recommended booster

For a zero-charge recommended booster, BOTH acquisition choices must be present on that booster card:

1. **BUY · <canonical price> SB**
2. **WATCH AD**

Therefore the two-card layout normally exposes:
- Card A: BUY with SB + WATCH AD
- Card B: BUY with SB + WATCH AD

There is never one shared BUY control and never one shared WATCH AD control.

SB prices remain canonical:
- +1 Slot 500 SB
- Random 350 SB
- Selector 500 SB
- Tornado 750 SB

If the player has enough SB, BUY is enabled and atomically purchases exactly one charge for that selected booster.
If SB is insufficient, that card's BUY path routes through the existing canonical insufficient-SB -> ShopHandoff flow with exact booster context preserved.

WATCH AD availability is per booster/product. One unavailable ad offer must not disable the other booster card.

### Owned charge

If a recommended booster already has one or more owned charges, preserve charge-first UX. Do not pressure the player to buy another charge merely to use the recommendation. Present the owned state clearly and let the player Retry/use the owned charge through normal gameplay. The two acquisition controls are required for zero-charge cards.

## 6. Dismissal

- NO `NO THANKS` button.
- Use the accepted popup-family top-right X.
- Back/Escape = same dismissal.
- Dismissal changes no economy/gameplay state and does not auto-Retry.

## 7. Acquisition authority

Reuse M43-C003:
- existing RewardedGrantService/provider-neutral seam;
- existing exactly-once reward token behavior;
- existing ModalStack/BasePopup;
- existing insufficient-SB -> ShopHandoff;
- existing booster inventory and canonical prices.

Need a Hand acquisition grants one booster charge for the selected booster. It does not execute the booster against the terminal board.

If necessary, add the smallest authoritative buy-one-booster-charge service/facade action. UI must not debit wallet or mutate inventory directly.

No ad SDK/provider tuning here. M57 owns provider/placement/cooldown/cap/No-Ads policy.
