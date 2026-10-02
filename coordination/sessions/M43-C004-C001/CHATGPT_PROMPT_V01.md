# M43-C004-C001 — CLAUDE MASTER PROMPT V01

Status: READY FOR CLAUDE
Date: 2026-10-02
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: **SB-M43-050 through SB-M43-062**

Do not edit root `TASKS.md`. ChatGPT owns tracker state.

## Mission

Complete the production Fail / Retry / Need a Hand recovery cycle.

Implement:
- canonical terminal Fail UI;
- safe terminal Retry/Home flow;
- same-level consecutive-failure assistance state;
- third-failure Need a Hand trigger;
- deterministic two-booster recommendation engine;
- Need a Hand popup with exactly two booster cards;
- **per-card SB purchase + per-card WATCH AD acquisition**;
- top-right X dismissal, no NO THANKS;
- tests, responsive evidence, owner-review pack, log and safe push.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/sessions/M43-C004-C001/OWNER_FAIL_RETRY_NEED_HAND_V01.md`
5. `coordination/sessions/M43-C004-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
6. `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`
7. newest Heart authority: `coordination/OWNER_HEART_REGEN_INTERVAL_V01.md`
8. M43-C001B technical audit + final owner visual acceptance
9. M43-C002-C001 technical audit + owner popup/pause gate
10. M43-C003-C001 technical audit + owner acquisition gate
11. current ResultsScreen, BasePopup/ModalStack/Popups/AcquisitionFlow, ProductionGameplayHost, AppState/save/progression/economy/rewarded files and tests.

## A. Critical terminal-loss truth

Inspect the live production terminal path before editing.

Current LOST already commits exactly once:
- Heart consume;
- progression-loss Win Streak reset;
- failed-level 2x handling;
- save;
- terminal receipt.

The new Fail UI displays that committed truth. It does not apply the loss again.

### Terminal Retry

Retry from terminal Fail:
- uses the existing transaction-safe host retry path;
- must not consume a second Heart;
- must not reset streak twice;
- if terminal loss left 0 Hearts, route to the existing canonical Life popup;
- prove with tests that one LOST + Retry changes Hearts exactly once total.

Do not change M43-C002 Pause -> Restart semantics.

## B. Production Fail surface — SB-M43-050

Replace the current LOST technical fallback with production presentation in the accepted popup family.

Requirements:
- sad/failure Scrubby or existing approved failure pose;
- `LEVEL FAILED`;
- live level/context;
- authoritative committed loss summary;
- Retry primary;
- Home secondary;
- no Victory decoration;
- no Replay;
- no ad CTA;
- responsive on required phone/tablet sizes.

Home after terminal failure must not apply another loss.

## C. Failure-assistance state — SB-M43-051/052/053/060/061

Create one authoritative, non-UI counter/read model.

Rules:
- progression terminal failures only;
- same canonical level;
- failure 1/2: no assistance;
- failure 3: assistance due;
- failure 4+: suppressed by V1 default until reset;
- win resets;
- progression level change resets;
- replay failures excluded;
- threshold/repeat policy from versioned/configurable data;
- expose local event/read seams for future M56 analytics without adding analytics provider work.

Do not invent a large save migration solely for this if no safe existing meta-state seam exists. Document persistence scope honestly.

## D. Need a Hand sequencing

On third due failure:
1. terminal loss/economy/save already committed;
2. canonical Fail remains the recovery base;
3. Need a Hand opens through the existing ModalStack over/after Fail;
4. closing Need a Hand returns to usable Fail;
5. no automatic Retry;
6. close changes nothing.

## E. Recommendation engine — SB-M43-055/056/057

Output exactly two distinct booster recommendations.

Use only:
- plus_one_slot
- random
- selector
- tornado

Evaluate usefulness against the next canonical retry/start-state, never by mutating the terminal board.

Prefer existing solver/context evidence.

Never claim guaranteed success.

Use deterministic owner-configured fallback order in versioned data.

If fewer than two meaningful recommendations can honestly be produced, do not show Need a Hand; keep Fail/Retry usable and record the reason.

## F. Need a Hand UI — owner locked

Use the selected `need a hand.png` as art-direction authority and the accepted popup/acquisition family for live responsive UI.

Exactly two booster cards.

Each card includes:
- booster icon;
- name;
- concise benefit;
- owned count/state;
- canonical price;
- SB acquisition state;
- rewarded acquisition state.

### REQUIRED: two controls per zero-charge card

For every recommended booster with zero owned charges, show BOTH:

- `BUY · <price> SB`
- `WATCH AD`

Therefore two zero-charge recommendations produce four acquisition CTAs total:
- Booster A BUY
- Booster A WATCH AD
- Booster B BUY
- Booster B WATCH AD

There must be:
- no shared BUY button;
- no shared WATCH AD button.

WATCH AD maps to that card's exact product:
`booster:<booster_id>`

Availability is independent per card.

If the player already owns a charge for that recommended booster, preserve charge-first UX: clearly show OWNED/available-for-next-attempt rather than encouraging unnecessary acquisition.

### Dismissal

- no NO THANKS button;
- top-right accepted-family X closes;
- Back/Escape is equivalent to X;
- close = no spend, no grant, no Retry, no counter mutation beyond the fact assistance was already shown.

## G. SB purchase — SB-M43-058

Need a Hand is terminal recovery, so acquisition buys one charge; it does not execute a booster.

Add/reuse the smallest authoritative action needed:

`buy_booster_charge(booster_id)` or equivalent:
- validates canonical booster id;
- reads canonical price from EconomyConfig;
- atomically debits SB;
- grants exactly +1 charge;
- insufficient balance => no debit/no grant;
- committed success requests save exactly once;
- idempotent/rapid-tap safe;
- UI never writes wallet/inventory directly.

Canonical prices:
- +1 Slot 500
- Random 350
- Selector 500
- Tornado 750

If enough SB: that card's BUY works immediately.
If insufficient SB: route via existing M43-C003 ShopHandoff with exact booster id/price/return context.

## H. Rewarded purchase — SB-M43-058

Reuse M43-C003 rewarded infrastructure.

Per booster card:
- query availability for exact `booster:<id>`;
- verified completion grants exactly one charge for that card's booster;
- cancel/skip/fail/timeout/unverified => 0;
- duplicate callback => once;
- background/resume cannot duplicate;
- success shown only after authoritative grant/save;
- one card unavailable must not disable the other card.

Do not add ad SDK/provider IDs/tuning.

## I. Booster use after acquisition

Acquired charge is saved for the next attempt.

Need a Hand must not auto-execute a booster on the terminal board.

Player closes/continues to Fail, taps Retry, then uses the charge through the canonical gameplay booster path and existing solver safety.

## J. Modal/lifecycle/accessibility

Reuse one ModalStack/BasePopup.

- top modal owns input;
- no input leaks to Fail/gameplay behind;
- X/Back exactly once;
- rewarded busy path reuses C003 safety;
- rapid taps cannot double buy/grant;
- 20 Fail->Need-a-Hand->close cycles do not accumulate nodes/signals/timers;
- Reduced Effects changes decorative motion only, not logic;
- touch targets meet existing project minimum.

## K. Responsive evidence

Validate:
- 1080x2160
- 1170x2532
- 1290x2796
- 1080x1920
- 1536x2048

Need a Hand must fit:
- 2 cards;
- per-card BUY button;
- per-card WATCH AD button;
- top-right X;
- no NO THANKS.

## L. Focused tests

At minimum prove:

1. terminal LOST consumes exactly one Heart;
2. Retry after LOST consumes no second Heart;
3. terminal Home applies no second loss;
4. 0 Hearts -> Retry opens Life;
5. Fail has no Victory/Replay/ad CTA;
6. Fail reads committed loss truth;
7. fail count 1 no assistance;
8. fail count 2 no assistance;
9. fail count 3 due exactly once;
10. fail count 4+ suppressed until reset;
11. win reset;
12. level-change reset;
13. replay excluded;
14. exactly 2 distinct recommendations;
15. both meaningful for next start-state;
16. deterministic same input -> same pair/order;
17. fewer than 2 meaningful -> fail closed;
18. Need a Hand exactly 2 cards;
19. each zero-charge card has BUY;
20. each zero-charge card has WATCH AD;
21. two zero-charge cards => 2 BUY + 2 WATCH AD;
22. no shared BUY/ad control;
23. no NO THANKS control;
24. X dismissal zero mutation;
25. Back == X;
26. exact canonical price per recommended booster;
27. enough SB buys exactly +1 charge;
28. insufficient SB changes nothing and preserves Shop context;
29. verified ad grants exactly +1 card-specific charge;
30. cancel/fail/timeout/unverified grants 0;
31. duplicate ad completion grants once;
32. one card unavailable does not disable other rewarded CTA;
33. owned-charge card preserves charge-first UX;
34. Need a Hand never executes terminal-board booster;
35. modal isolation;
36. rapid tap safety;
37. 20-cycle lifecycle stability;
38. responsive matrix;
39. Reduced Effects logic parity.

Run relevant existing:
- M30 completion/retry
- M39 economy/boosters
- M40 save/AppState
- M42 Home/navigation
- M43-C001 Results
- M43-C002 popup/modal/pause
- M43-C003 acquisition/rewarded
- M52 supply/2x
- M55 economy/timed 2x
- root `tests/run_tests.gd`
- `git diff --check`

## M. Evidence and owner-review pack

Create:
`coordination/sessions/M43-C004-C001/evidence/`

Include at minimum:
- Fail reference phone;
- Fail short-phone;
- Fail tablet;
- third-failure Need a Hand;
- Need a Hand showing 2 cards with **2 BUY + 2 WATCH AD**;
- one-card rewarded-unavailable state;
- insufficient-SB card/Shop handoff;
- owned-charge card;
- top-right X, no NO THANKS;
- zero-heart Retry -> Life;
- Reduced Effects;
- lifecycle report.

Write:
- `FAILURE_ASSISTANCE_MATRIX_V01.md`
- `OWNER_VISUAL_REVIEW_V01.md`
- `CLAUDE_LOG_V01.md`

Do not self-approve final visuals. Owner reviews the real production screenshots after ChatGPT technical audit.

## Scope locks

Do not:
- edit root TASKS.md;
- change Heart regen away from current 900 s authority;
- change booster prices;
- add fifth booster;
- add ad CTA to Fail/Retry/Home;
- use one shared Watch Ad button;
- use one shared SB purchase button;
- add NO THANKS;
- bypass solver safety;
- auto-execute acquired booster on terminal board;
- implement ad SDK/provider tuning;
- implement M43-C005+;
- restyle accepted WON Results, Pause, Life, Booster Acquire or 2x beyond necessary shared additions.

## Finish

Preserve owner/local dirty files. Use isolated worktree if required.

Commit focused changes, push safely to `origin/main`, never force.

Return final SHA, focused/regression summary, direct log URL and owner-review URL.

Finish exactly:

`AWAITING_GPT_M43_C004_C001_AUDIT`
