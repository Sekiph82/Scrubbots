# M43-C004-C001 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-10-02
Scope: SB-M43-050..062
Implementation: `1acaf408b2518adcb941ca54c3223253c43a8c7a`
Evidence/log: `351edd43b4c400e465b3659885798d9b486fa48d`
Result: **TECHNICAL_PASS / OWNER_VISUAL_AND_TUNING_GATE_REQUIRED**

## Executive result

The implementation satisfies the technical M43-C004-C001 contract. No blocking functional defect was found.

The production Fail path, third-failure assistance authority, deterministic two-booster recommendation flow, per-card SB purchase, per-card rewarded acquisition, dismissal rules, terminal-board safety, responsive/lifecycle coverage, and regression evidence all pass the published criteria.

No remediation prompt is required before owner review.

Final task closure still requires the explicit owner gate requested by the cycle:
- Fail/Need-a-Hand visuals;
- Fail copy;
- V1 recommendation order/weights;
- unavailable-ad presentation;
- whether the failure counter remains session-scoped;
- final card-art-direction acceptance.

## 1. Terminal loss / Retry

**PASS**

The existing terminal LOST authority remains the only loss mutation:
- Heart consume exactly once;
- progression-loss streak reset exactly once;
- failed-level speed entitlement handling;
- durable save;
- terminal receipt.

The implementation correctly avoids adding loss mutation to the new Fail UI.

Focused evidence proves:
- LOST 5 -> 4 Hearts;
- terminal Retry leaves Hearts at 4, including a case with a real player action before terminal;
- terminal Home does not apply a second loss;
- Retry at 0 Hearts routes to the existing Life popup;
- M43-C002 Pause -> Restart remains unchanged.

The code path also supports the result: terminal LOST clears the gameplay-started state through the accepted progression-loss path before M30 Retry restore, so terminal Retry cannot consume a second Heart through the restart-after-action law.

## 2. Failure-assistance authority

**PASS**

`FailureAssistanceService` is non-UI authority and owns the counter/read model.

Verified contract:
- progression/frontier failures only;
- same-level sequence;
- failure 1/2 no assistance;
- failure 3 due;
- default failure 4+ suppression until reset;
- win reset;
- level-change reset;
- replay/non-frontier excluded;
- versioned config controls trigger/repeat policy;
- analytics seam is local/event-only and does not affect gameplay.

The counter is intentionally session-scoped in this implementation. This is not a technical violation because persistence was not locked in the owner contract, but it remains an explicit owner tuning decision before final closure.

## 3. Recommendation engine

**PASS**

The service returns exactly two distinct canonical boosters or fails closed.

Important safety properties are correctly implemented:
- terminal/lost board is used only for read-only context signals;
- each candidate is separately proven on a detached fresh next-start state;
- no recommendation executes on or mutates the terminal board;
- the pair/order is deterministic for the same input;
- fewer than two meaningful/legal choices prevents Need a Hand from opening;
- no win-guarantee claim is presented.

Current V1 tuning:
- fallback: +1 Slot -> Selector -> Tornado -> Random;
- slots-full weight: +1 Slot +2, Selector +1;
- dominant-colour weight: Tornado +2;
- remaining-supply weight: Selector +1.

Random's expensive proof is lazily evaluated only if ranking reaches it. Evidence reports all ten catalog levels produce a valid two-card offer and third-failure terminal cost remains 175-355 ms headless.

The ranking/weights are technically valid but remain an owner tuning gate because they were implementer-selected.

## 4. Need a Hand UI / owner lock

**PASS**

The focused suite directly proves the user's locked layout:

- exactly two booster cards;
- each zero-charge card has its own BUY action;
- each zero-charge card has its own WATCH AD action;
- two zero-charge recommendations therefore produce **2 BUY + 2 WATCH AD**;
- no shared BUY;
- no shared WATCH AD;
- canonical prices;
- per-card rewarded availability;
- owned-charge state removes unnecessary acquisition pressure;
- top-right X;
- no NO THANKS;
- Back/Escape equals X;
- dismissal performs no economy/gameplay mutation.

The production provider is intentionally unavailable until M57, so both WATCH AD controls remain visible but disabled with a no-video state. This preserves the final layout while honestly reflecting provider availability.

## 5. Scrub Bucks acquisition

**PASS**

Need a Hand does not mutate wallet/inventory from UI.

The new authoritative path is:
`ProductionActionFacade.buy_booster_charge(id)`
-> `BoosterInventory.buy_charge(id)`
-> canonical EconomyConfig price.

Verified:
- canonical booster id only;
- canonical price only;
- atomic debit;
- exactly +1 charge;
- insufficient balance changes neither wallet nor charge;
- successful action requests one durable save;
- rapid taps are latched;
- insufficient balance routes through the existing ShopHandoff with exact booster/price/level/source context.

## 6. Rewarded acquisition

**PASS**

Need a Hand reuses the M43-C003 RewardedGrantService and does not create a second rewarded ledger.

Each card maps to its exact `booster:<id>` product.

Verified:
- verified completion -> one charge for that card;
- cancel/skip/fail/timeout/unverified -> zero;
- duplicate callback -> once;
- late callback after UI timeout -> no grant;
- background/resume safe;
- one card unavailable does not disable the other card;
- no SDK/provider ids/tuning were introduced.

Real ads remain M57 work.

## 7. Terminal-board safety

**PASS**

BUY and WATCH AD only create saved booster charges.

They do not execute a booster on the terminal board.

Focused evidence compares terminal board/supply/slot/capacity state before and after acquisition and proves no mutation. After Retry the normal canonical gameplay booster path consumes the saved charge under existing solver-safety authority.

## 8. Fail presentation / responsive / lifecycle

**TECHNICAL PASS, OWNER VISUAL GATE OPEN**

Fail replaces the old LOST technical fallback while leaving WON Results unchanged.

Verified:
- LEVEL FAILED production surface;
- accepted cream/royal popup-family language;
- approved help Scrubby + fail emblem;
- committed Heart/streak loss rows;
- Retry primary, Home secondary;
- no Victory art;
- no Replay;
- no rewarded CTA on Fail.

Responsive evidence covers:
- 1080x2160;
- 1170x2532;
- 1290x2796 for Need a Hand;
- 1080x1920;
- 1536x2048.

The focused suite checks bounds, text fit, four zero-charge acquisition CTAs and minimum touch height.

Lifecycle proof:
- 20 Fail -> Need a Hand -> X cycles;
- node count stable;
- connections/timers stable;
- modal input does not leak;
- Reduced Effects leaves logic unchanged.

The remaining question is visual preference, not technical correctness.

## 9. Tests / regressions

**PASS**

Focused:
- `tests/m43_c004_c001_fail_need_a_hand.gd`: **40/40 PASS**.

Required regressions:
- M30 PASS;
- M39 PASS;
- M40 PASS;
- M42 PASS;
- M43-C001A PASS;
- M43-C001B migrated to the new Fail truth and rerun **11/11 PASS**;
- M43-C002 **23/23 PASS**;
- M43-C003 **34/34 PASS**;
- M52 PASS;
- M55 PASS;
- root `tests/run_tests.gd`: **5323 checks, 0 failures**.

Full top-level sweep:
- 123/126 exit cleanly;
- the two historical M21 corridor suites remain the same known baseline failures;
- the temporary C001B non-zero result was an expected stale LOST visual assertion and passed after its scoped C004 migration.

No routing work was changed.

## 10. Governance / diff

**PASS**

Comparison `52ca20b...351edd4` is two focused commits.

Claude did not edit root `TASKS.md`.

No ad SDK/provider tuning, fifth booster, Heart-regeneration change, WON restyle, Pause restyle, Life restyle, Booster Acquire restyle, or 2x restyle was introduced.

`git diff --check` is reported clean.

## 11. Independent audit limitation

I inspected the published implementation, config, logs, criteria, diff metadata, and test/evidence reports in GitHub.

The GitHub connector in this audit did not provide the committed PNG evidence as independently renderable image bytes, so I am not independently asserting aesthetic approval of those screenshots. That is also intentionally reserved for the owner visual gate.

## Result

**M43-C004-C001 = TECHNICAL_PASS / OWNER_VISUAL_AND_TUNING_GATE_REQUIRED**

No implementation remediation is required at this time.

Owner review is now the only open gate.
