# OWNER FAILURE RECOVERY AND ACQUISITION V01

Date: 2026-09-26
Authority: OWNER
Status: PLANNED / REQUIRED
Scope: Hearts, boosters, 2x, failure recovery, Need a Hand, rewarded acquisition.

## 1. Same-level assistance trigger

For progression play, track consecutive failed attempts on the same progression level.

- On the third consecutive failed attempt, after authoritative fail/Heart/Win-Streak accounting, show Need a Hand.
- A progression win resets the counter.
- Changing to a different progression level resets the counter.
- Replay failures do not increment the progression assistance counter.
- Closing the assistance popup has no gameplay/economy side effect.
- Post-third-failure repeat frequency is data-driven and should avoid harassment.

## 2. Need a Hand

Need a Hand presents exactly two useful booster recommendations.

Recommendation requirements:
- recommend only currently meaningful/legal booster types;
- prefer context/solver evidence where available;
- never claim a booster guarantees a win;
- use a deterministic owner-configured fallback pair if contextual ranking is inconclusive;
- acquisition must use the same canonical booster inventory/economy authority as normal gameplay.

Each recommended booster offers:
- canonical Scrub Bucks acquisition;
- rewarded-video acquisition when available and allowed.

## 3. Booster acquisition

Exactly four V1 boosters remain authoritative:

- +1 Slot: 500 SB
- Random: 350 SB
- Selector: 500 SB
- Tornado: 750 SB

When an owned charge exists, use charge-first rules. With zero charge, the canonical Booster Acquire popup may offer SB or rewarded-video acquisition.

A rewarded acquisition produces exactly one charge/use entitlement after a verified completed reward callback. Cancel, skip, timeout, provider failure or duplicate callbacks grant nothing.

Rewarded acquisition never bypasses solver-safety or booster legal-execution rules.

## 4. Hearts

Canonical Hearts remain:
- max 5;
- +1 every 30 real-world minutes;
- +1 Heart for 500 SB;
- full refill cost = 400 SB per missing Heart.

The Home Heart + control and zero-Heart attempt gate use the same Life popup.

Life may offer rewarded video for exactly +1 Heart when an approved placement is available.

## 5. 2x

Canonical paid manual options remain:
- current level 200 SB;
- 15 minutes 300 SB;
- 30 minutes 500 SB;
- 60 minutes 750 SB.

Existing entitlement permits free 1x/2x switching during that entitlement.
Free automatic endgame 2x from authoritative M23 supply exhaustion remains unrelated to purchases and never opens acquisition UI.

## 6. Transaction safety

All SB spends, charge grants, Heart grants and entitlements must:
- use authoritative services;
- be atomic/idempotent;
- lock duplicate UI input while pending;
- survive background/resume safely;
- never infer success before authoritative callback/commit;
- never double-grant after relaunch.

## 7. Ad tuning boundary

Provider, placement IDs, frequency, cooldowns, caps, regional availability and No Ads interaction are M57 tuning/provider decisions.

Do not hardcode pressure/frequency into popup scenes.

## 8. Visual authority

- Life visual authority: `life screens.png`
- Need a Hand visual authority: `need a hand.png`
- Booster Acquire and 2x Acquire require new owner-approved masters in the same visual family.
