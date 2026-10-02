# M43-C004-C001 — Failure Assistance Matrix V01

Date: 2026-10-02
Scope: SB-M43-050..062
Focused suite: `tests/m43_c004_c001_fail_need_a_hand.gd` (40 cases)

## 1. Ownership map

| Concern | Owner (production path) | UI touches it? |
|---|---|---|
| Terminal LOST: Heart, Win Streak, failed-level 2x, save, receipt | `ProductionGameplayHost._drive_economy_terminal` (unchanged, exactly once) | No |
| Fail presentation | `ResultsScreen` LOST layout (reads the committed receipt only) | Read-only |
| Terminal Retry | `main.retry_from_results` → zero-Heart gate → `host.retry()` (M30 `RetryCoordinator`) | Intent only |
| Same-level failure counter | `FailureAssistanceService` (one instance per AppState; private one for harness hosts) | No |
| Threshold / repeat / fallback order / context weights | `data/config/failure_assistance_v1.json` (`scrubbots.failure_assistance.v1`) | No |
| Need a Hand offer (due + two picks) | `host._record_assistance`, decided once inside the latched terminal | No |
| Next-start legality | `host.next_start_prover()`: detached fresh board, same initial supply, empty five slots, the same `ProductionBoosterAdapter` proofs | No |
| Ranking | `FailureAssistanceService.recommend(prove, context)` | No |
| Need a Hand UI | `AcquisitionFlow.open_need_a_hand` on the one `ModalStack` / `BasePopup` | Presentation |
| SB charge purchase | `ProductionActionFacade.buy_booster_charge` → `BoosterInventory.buy_charge` | Intent only |
| Rewarded charge | `RewardedGrantService` (C003), product `booster:<id>`, tx `rewarded:<token>` | Intent only |
| Insufficient SB | C003 `open_insufficient` → `ShopHandoff` ticket | Intent only |
| Analytics seam (M56) | `FailureAssistanceService.assistance_event(kind, data)` | No |

## 2. Counter rules

| Rule | Implementation | Test |
|---|---|---|
| Progression terminal failures only | `host.is_progression_attempt()`: `progression_level == progression.current_level()` | t13 |
| Same level | A failure on another level restarts the count (`reset_level_change`) | t12 |
| Failures 1 and 2: no assistance | `is_due(n)` false | t07, t08 |
| Failure 3: due exactly once | `n == trigger` (3) | t09 |
| Failure 4+: suppressed until reset (V1) | `repeat_every_failures_after_trigger: 0` | t10 |
| Win resets | progression WON → `reset_win` | t11 |
| Level change resets | `on_attempt_started(level)` and `record_terminal` on a new level | t12 |
| Replay excluded | non-frontier attempts → `excluded_non_progression`; the count is unchanged | t13 |
| Versioned config, fail closed | a missing or malformed config is never due and recommends nothing | config_and_events |
| The UI does not own the counter | AppState / host own it; the popup only reads `get_assistance_offer()` | t24 (X leaves `state()` unchanged) |

**Persistence scope:** the counter is session-scoped. It lives with the AppState for the app's lifetime and survives Home, Retry and route changes. It is **not** in the save file, so a cold relaunch restarts the count.

No save-schema migration was added for it. The owner can request persistence later.

## 3. Recommendation

1. **Context.** These signals are read-only from the terminal board, slots and supply:
   - `slots_full`: every slot is occupied;
   - `dominant_color`: one colour holds at least 40% of the remaining ACTIVE cells;
   - `supply_remaining`: the supply is not exhausted.
2. **Score.** Each booster scores the sum of the weights of its true signals (V1 weights below). Ties fall back to `fallback_order`: +1 Slot, Selector, Tornado, Random.

   | Signal | Weights |
   |---|---|
   | `slots_full` | +1 Slot 2, Selector 1 |
   | `dominant_color` | Tornado 2 |
   | `supply_remaining` | Selector 1 |
3. **Proof.** The ranking is walked in order, and each booster is proved legal on the **next canonical start-state**:
   - +1 Slot: `can_grow_to_sixth`;
   - Random: `propose_random_reorder().safe`, which is the 3-step solver proof;
   - Selector: `has_eligible_safe_batch`, which uses the same solver proof as `eligible_safe_batches` and stops at the first hit;
   - Tornado: `present_colors`.

   Proving stops at two legal boosters. If fewer than two are legal, the result is `insufficient_meaningful`: no popup, the reason is recorded, and Fail/Retry stay usable (t17).
4. The live terminal board, supply and slots are never mutated (t15, t34).
5. The UI never claims a guaranteed win. The card copy is a benefit line, and the popup shows the note "Boosters help — the win is still yours to make." (t23)

**Performance (headless CPU, not device evidence).** For catalog levels 1–10:

- The full third-failure terminal (economy + save + decision + Results + popup build) took **216–272 ms**.
- Proving all four boosters on the same levels takes 258–4,894 ms, because the Random solver proof is costly. Lazy proving is why Random is proved only when the ranking reaches it.

## 4. Need a Hand card contract

| Card state | Visible controls |
|---|---|
| Zero charges | `BUY · <price> SB` (gold offer) **and** `WATCH AD` (green). Both are inside the card. |
| Zero charges, ad unavailable for this placement | `BUY` is enabled. `WATCH AD` is shown but disabled, with the note "No video right now". The other card is unaffected. |
| ≥1 owned charge | Shows `Owned: N` and "Ready for your next try!". There is no acquisition CTA (charge-first). |

- Action ids are exactly `buy:<id>` and `watch:<id>` for each card, and each is a descendant of its own card.
- The footer holds no actions, and there is no NO THANKS button.
- Dismissal is the top-right X, Back or Escape. It has zero effect: no spend, no grant, no counter change and no Retry.

## 5. Transactions

| Path | Guarantee | Test |
|---|---|---|
| BUY with enough SB | The debit is the exact canonical price, exactly +1 charge is granted, one `action_committed`, one save, and it persists | t27 |
| BUY with insufficient SB | No debit and no grant. The insufficient popup opens, and the Shop ticket carries `source=need_a_hand`, `product=booster:<id>`, the booster, price and level | t28 |
| Unknown booster id | `unknown_booster`, nothing moves | t27 |
| WATCH AD verified | Exactly +1 charge for that card's booster; the other card is untouched | t29 |
| cancel / skip / fail / timeout / unverified / missing verified flag / late after UI timeout | 0 granted | t30 |
| Duplicate callbacks + background/resume | Granted once; the token persists | t31 |
| Rapid taps | 6 BUY taps → 1 purchase; 5 WATCH taps → 1 provider request; X refused while pending | t36 |
| Terminal board | Acquisition only saves charges. The next attempt uses them through `request_booster` | t34 |

## 6. Lifecycle / modal

- There is one `ModalStack`. Need a Hand opens over Fail (Fail is the route screen), and clicks on Fail behind it do nothing (t35).
- Over 20 Fail → Need a Hand → close cycles, node, signal-connection and timer counts stay stable (t37).
- Reduced Effects produces an identical offer, counter and rows (t39).
