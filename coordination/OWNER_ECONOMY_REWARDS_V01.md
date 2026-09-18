# OWNER ECONOMY & REWARDS V01

Date: 2026-09-18
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: Economy, rewards, Hearts, Win Streak, Gift Meter/Gift Bar, Cards Exchange, robot unlock progression, 2x entitlements, boosters and Daily retention.

This file is the canonical owner decision for SCRUBBOTS Economy & Rewards V1. When older documents conflict, this file wins unless a later explicit owner decision supersedes it.

## 1. Canonical economic values

SCRUBBOTS V1 uses these player-facing values:

- **Scrub Bucks (SB)**: the single general-purpose spendable soft currency.
- **Hearts**: attempt/life capacity. Not a currency balance and not exchangeable.
- **Bot Parts**: non-purchasable robot-unlock progression resource. Bot Parts may be spent ONLY to unlock robots.
- **Collection Cards**: collectible inventory. The first owned copy is protected; extra copies are exchangeable.
- **Booster Charges**: inventory charges for exactly four canonical boosters.
- **2x entitlements**: either a current-level entitlement or a wall-clock timed entitlement.

The following systems are removed from V1 economic/progression truth:

- **Stars as currency/progression points: REMOVED.**
- **Event Points: REMOVED.**
- **XP as the Home profile progression bar: REMOVED.** The Home bar becomes next-robot Bot Parts progress.

Decorative sparkles, star-shaped art accents or trophy decoration may exist visually, but they never imply a Star balance.

## 2. First-clear level rewards

Economic progression rewards are granted on the FIRST successful completion of a progression level only. Replay cannot farm SB, Bot Parts, Gift Meter progress, Win Streak or first-clear Collection milestones.

| Difficulty | First-clear Scrub Bucks |
|---|---:|
| EASY | 50 SB |
| MEDIUM | 75 SB |
| HARD | 100 SB |
| VERY_HARD | 150 SB |

Every first-clear progression win additionally grants:

- **+1 Bot Part**
- normal Win Streak processing
- any level/collection milestone processing

A replay may exist for fun/QA/score purposes but does not grant these progression-economic rewards.

## 3. Win Streak

The existing owner-locked consecutive-win SB mapping remains exact:

| Consecutive progression wins | SB streak bonus |
|---|---:|
| 1 | +1 SB |
| 2 | +5 SB |
| 3 | +10 SB |
| 4 | +25 SB |
| 5 or more | +100 SB per win |

This SB bonus is added to the first-clear difficulty reward.

Every time the active progression Win Streak reaches a multiple of 5 (5, 10, 15, 20, ...), grant:

- **+1 Bot Part**

Loss of a progression level resets the active Win Streak to 0. A restart after real gameplay has begun counts as a loss for Heart and Win Streak purposes. Entering and leaving before the first real gameplay action consumes neither Heart nor streak.

Replays do not advance Win Streak.

## 4. Gift Meter and Gift Bar

### 4.1 Progress source

Gift Meter progress comes from **Win Streak SB only**.

If a win produces a +25 SB Win Streak bonus:
- wallet receives +25 SB;
- Gift Meter receives +25 progress.

The following NEVER advance Gift Meter:
- base level SB;
- Daily rewards;
- Tasks rewards;
- Gift Meter/Gift Bar rewards;
- Cards Exchange;
- Shop/refunds;
- any future paid purchase.

Gift Meter progress is therefore a mirror of earned streak-bonus SB, not a second spend.

### 4.2 Milestones

Each Gift Meter cycle has claimable milestones at:

- 10
- 50
- 250
- 500
- 1000

Crossing a milestone queues that reward in **Gift Bar**. A single streak reward may cross more than one milestone; every newly crossed milestone is queued exactly once.

At 1000 the cycle completes. Overflow carries into the next cycle. Example: 950 + 100 streak-SB grants the 1000 milestone and the next cycle begins at 50.

### 4.3 Gift Meter rewards

| Milestone | Reward |
|---|---|
| 10 | 1 Bot Part + 1 Standard Card Pack |
| 50 | 1 Bot Part + 1 random Booster Charge |
| 250 | 2 Bot Parts + 100 SB + 1 Standard Card Pack |
| 500 | 2 Bot Parts + 250 SB + 1 player-selected Booster Charge + 1 Standard Card Pack |
| 1000 | 4 Bot Parts + 500 SB + 2 player-selected Booster Charges + 1 Premium Card Pack + 1 guaranteed-new eligible Collection card |

A full 0→1000 Gift Meter cycle therefore grants exactly **10 Bot Parts**.

The guaranteed-new card at 1000 must come from an unlocked, incomplete eligible set. If no eligible missing card exists, substitute **500 SB**.

Gift Bar is the claim surface/history for queued Gift Meter milestone rewards. Gift Bar rewards do not feed Gift Meter.

## 5. Bot Parts and robot unlock progression

Scrubby is unlocked at game start.

Every subsequent robot costs:

- **250 Bot Parts**

Bot Parts are not purchasable with SB or real money in V1.

Canonical Bot Part sources:
- +1 per first-clear progression level;
- +1 each time Win Streak reaches a multiple of 5;
- per-set Collection completion rewards defined in §10;
- +20 Master Collection bonus after all 15 sets are completed;
- Gift Meter milestone rewards defined above.

Target pacing is approximately one new robot every 150 progression levels for an average engaged player:

- Robot 2 ~ Level 150
- Robot 3 ~ Level 300
- Robot 4 ~ Level 450
- Robot 5 ~ Level 600
- Robot 6 ~ Level 750

These are pacing targets, not hard level gates. Skilled/high-streak players may unlock somewhat earlier and low-streak players somewhat later.

Bot Part overflow is preserved. Example: 263/250 unlock -> 13 parts remain toward the next robot.

### Robot perks

Robots may have different passive/meta benefits, but a robot perk may NEVER change puzzle solvability truth, TargetSelector ordering, BoardState legality, route legality, batch conservation, reservation uniqueness or authenticated-clearing rules.

Allowed perk families include economy/convenience modifiers such as:
- small first-clear SB bonus;
- Cards Exchange bonus;
- 2x purchase discount;
- booster purchase discount;
- Gift Bar SB modifier.

Exact robot roster/perks are a later owner tuning decision.

## 6. Hearts

- Maximum Hearts: **5**
- Regeneration: **1 Heart every 30 real-world minutes**
- Win: no Heart loss
- Loss: -1 Heart
- Restart after gameplay begins: -1 Heart
- Exit before first real gameplay action: no Heart loss
- Offline/background/menu time counts toward Heart regeneration.
- At 5/5, the next-heart timer is hidden/stopped.

SB refill:
- +1 Heart: **500 SB**
- Full refill: **400 SB per missing Heart**

Example: 2/5 -> three missing Hearts -> full refill costs 1200 SB.

## 7. 2x speed economy

Gameplay supports exactly 1x and 2x temporal factors.

### 7.1 Paid manual 2x products

| Product | Price |
|---|---:|
| 2x for current level | 200 SB |
| 2x for 15 minutes | 300 SB |
| 2x for 30 minutes | 500 SB |
| 2x for 60 minutes | 750 SB |

Current-level entitlement is bound to the current progression level ID and remains valid through retries/restarts of that same level until that level is successfully completed.

Timed 2x uses an absolute real-world expiry timestamp. Purchased time continues counting:
- during gameplay;
- in menus/Home;
- while paused;
- while the app is backgrounded;
- while the app is closed.

Timed purchases may extend an existing timed expiry by adding duration. They are not active-gameplay-only clocks.

If a timed entitlement is active, manual 1x<->2x switching requires no additional SB. A current-level entitlement likewise permits manual switching for that level.

### 7.2 Free automatic endgame 2x

The existing authoritative **M23 supply exhausted -> automatic 2x** rule remains free and does not require any paid entitlement.

Automatic endgame 2x:
- does not grant/refund/extend a timed entitlement;
- does not charge SB;
- remains gameplay-time acceleration only;
- never changes FIFO, slot accounting, target selection, claims, routing, quotas or solver truth.

## 8. Exactly four boosters

V1 has exactly four boosters. Booster Charges may be earned from Gift Bar and Daily or purchased/consumed with SB.

When a charge exists, use the charge first. When no charge exists, the player may pay the listed SB price for one use.

### 8.1 +1 Slot — 500 SB

- Expands normal slot capacity from 5 to **6** for the current attempt.
- May be activated at most once per attempt.
- Does not stack to 7+ slots.
- On a new attempt after loss/restart, capacity returns to 5 unless another charge/use is consumed.
- Sixth slot is authoritative gameplay state, not presentation-only.

### 8.2 Random — 350 SB

- Reorders the REMAINING unselected color/count batches.
- Batch identities, colors, counts and total per-color conservation remain unchanged.
- The resulting order must be solver-validated to provide at least **3 consecutive safe/easy front selections**.
- For V1, a qualifying 3-move sequence means three legal accepted supply-front choices exist in sequence and the solver confirms the resulting state remains solvable/non-DEADLOCK through those moves.
- If no qualifying reorder can be found within deterministic search bounds, the booster fails closed and consumes no charge/SB.

### 8.3 Selector — 500 SB

- Presents eligible remaining batches/colors to the player.
- One selected remaining batch may bypass normal front-only supply order for this single transaction.
- It is atomically removed from its authoritative supply position and placed into the normal rightmost EMPTY execution slot.
- If +1 Slot is active, the sixth slot is eligible.
- No empty slot => booster cannot be committed and consumes no charge/SB.
- UI should expose only solver-safe eligible choices. If none exist, booster is unavailable and consumes nothing.
- No duplicate batch may be created; conservation remains exact.

### 8.4 Tornado — 750 SB

- Player selects exactly one color currently present in the level.
- All remaining ACTIVE artwork cells of that selected color are cleared/swept in one authoritative booster transaction.
- The implementation must reconcile/remove the selected color's corresponding remaining supply quota, slot batches, committed/in-flight assignments, claims and reservations so no ghost batch, duplicate clear or impossible quota remains.
- In-flight agents for that color must be cancelled/reconciled safely before/within the transaction.
- After the transaction, runtime solvability/deadlock state is recomputed from the new authoritative state.
- If the transaction cannot be made atomically/safely, consume nothing.

No fifth booster is authorized in V1.

## 9. Daily retention and consecutive-login streak

Daily has:
- three daily tasks;
- a visible **Consecutive Login Days** count;
- a repeating 5-day login reward cycle.

A login reward may be claimed once per local calendar day. Missing a calendar day resets consecutive-login count and reward-cycle position to Day 1.

The displayed lifetime/current consecutive count may continue above 5 (e.g. 12 days) while the reward cycle repeats every 5 days.

### 9.1 Daily login rewards

| Day in 5-day cycle | Reward |
|---|---|
| Day 1 | 100 SB |
| Day 2 | 1 Standard Card Pack |
| Day 3 | 1 random Booster Charge |
| Day 4 | 250 SB + 1 Standard Card Pack |
| Day 5 | 300 SB + 1 player-selected Booster Charge + 1 Premium Card Pack |

After Day 5, a continuing streak moves to the next 5-day cycle without resetting the visible consecutive-days count.

Clock rollback must never permit duplicate claims. Save at minimum the last claimed local-date key, claim timestamp and highest-seen trusted/system timestamp; fail closed on backwards time until a new valid day is reached.

### 9.2 Daily tasks

Initial V1:
- 3 tasks per day;
- individual rewards: 75 SB, 100 SB, 125 SB;
- completing all 3 grants **1 random Booster Charge**.

Daily rewards do not advance Gift Meter and do not grant Bot Parts.

## 10. Collection and card packs

Owner reference structure is **15 Collection sets × 9 cards**.

Collection completion rewards are **not uniform**. Reward size reflects:
1. card-rarity burden in the owner-approved set art;
2. how late the set becomes realistically completable as the player's eligible card pool grows;
3. the expected duplicate pressure required to finish the last missing cards.

Sets 1–14 use the standard owner-approved rarity profile of **4 Common / 2 Rare / 2 Epic / 1 Legendary**. Their reward grows with later collection access because later sets compete inside a wider eligible draw pool and are therefore slower to close. Set 15 **Ultimate Cleaners** is a separate rarity-heavy finale with **3 Rare / 3 Epic / 3 Legendary**, so it receives a much larger completion reward.

### 10.1 Per-set 9/9 completion rewards

| Set | Collection | Rarity profile | Exactly-once completion reward |
|---:|---|---|---:|
| 1 | Meet the Scrubbots | 4C/2R/2E/1L | 350 SB + 5 Bot Parts |
| 2 | Cleaning Crew | 4C/2R/2E/1L | 400 SB + 5 Bot Parts |
| 3 | Mess Monsters | 4C/2R/2E/1L | 450 SB + 6 Bot Parts |
| 4 | Color Bots | 4C/2R/2E/1L | 500 SB + 7 Bot Parts |
| 5 | Scrubbot Workshop | 4C/2R/2E/1L | 550 SB + 7 Bot Parts |
| 6 | Bathroom Mayhem | 4C/2R/2E/1L | 600 SB + 8 Bot Parts |
| 7 | Kitchen Chaos | 4C/2R/2E/1L | 700 SB + 9 Bot Parts |
| 8 | Garage Grime | 4C/2R/2E/1L | 750 SB + 9 Bot Parts |
| 9 | Sewer Squad | 4C/2R/2E/1L | 800 SB + 10 Bot Parts |
| 10 | Clean City | 4C/2R/2E/1L | 900 SB + 10 Bot Parts |
| 11 | Jungle Cleanup | 4C/2R/2E/1L | 1000 SB + 11 Bot Parts |
| 12 | Bath Time Blitz | 4C/2R/2E/1L | 1100 SB + 12 Bot Parts |
| 13 | Underwater Heroes | 4C/2R/2E/1L | 1250 SB + 13 Bot Parts |
| 14 | Space Cleaners | 4C/2R/2E/1L | 1500 SB + 15 Bot Parts |
| 15 | Ultimate Cleaners | 3R/3E/3L | 2500 SB + 20 Bot Parts |

Total rewards from the 15 individual set completions are:
- **13,350 SB**
- **147 Bot Parts**

Each set reward is granted exactly once, on the first transition of that set to 9/9. Re-opening, viewing, replaying or re-synchronizing a completed set never grants it again.

### 10.2 Master Collection reward

When **all 15 sets are completed at 9/9**, grant one additional exactly-once **Master Collection** reward:

- **2,500 SB**
- **20 Bot Parts**

This is additional to Set 15's own reward.

Therefore a player who completes the entire current 15-set Collection receives, across set-completion milestones plus Master Collection:

- **15,850 SB total**
- **167 Bot Parts total**

The Master Collection reward is tied to the first authoritative transition from fewer than 15 completed sets to all 15 completed sets. It must be idempotent and persist its claimed/granted transaction identity.

### 10.3 Collection reward balancing rule

Future Collection sets must not reuse one flat reward blindly. For any added set, reward tuning must consider:
- rarity composition;
- eligible-pack pool size when the set becomes available;
- expected number of duplicate draws before final completion;
- whether the set contains multiple Legendary cards.

A rarity-heavy set must never pay less than an easier standard-profile set at a comparable/later progression position.

The first owned copy of every card is permanently protected from Cards Exchange.

### Standard Card Pack
- 3 card draws
- from currently unlocked/eligible Collection sets
- duplicates allowed

### Premium Card Pack
- 5 card draws
- duplicates allowed
- at least one draw is guaranteed Rare-or-better among eligible cards

Card-pack rarity tables are data-driven tuning and must be versioned before implementation; no paid random pack is authorized by this decision.

## 11. Cards Exchange

The old Star Exchange concept is removed. Home shortcut becomes **CARDS EXCHANGE**.

Only duplicate copies above the protected first copy are exchangeable.

| Card rarity | Duplicate exchange value |
|---|---:|
| Common | 25 SB |
| Rare | 75 SB |
| Epic | 200 SB |
| Legendary | 500 SB |

Support per-card exchange and **EXCHANGE ALL EXTRAS**. The operation must be atomic and must never reduce owned count below 1 for a collected card.

Cards Exchange rewards do not advance Gift Meter.

## 12. Shop / SB sinks

V1 SB sinks:
- Heart +1: 500 SB
- full Heart refill: 400 SB per missing Heart
- current-level 2x: 200 SB
- 15m 2x: 300 SB
- 30m 2x: 500 SB
- 60m 2x: 750 SB
- +1 Slot booster: 500 SB/use
- Random booster: 350 SB/use
- Selector booster: 500 SB/use
- Tornado booster: 750 SB/use

No premium gem/star currency is authorized.

Real-money IAP, ads, rewarded ads, subscriptions and cash pricing remain separate M57 Monetization decisions. Scrub Bucks are not cash-out value and are not real-world money.

## 13. Home UI semantic migration

The owner-approved Home composition remains the visual reference, but these semantics replace old placeholder concepts:

- coin -> **Scrub Bucks**
- profile XP bar -> **Bot Parts to next robot** (e.g. 184/250)
- top event progress -> **Gift Meter**
- top event timer -> **removed**
- Star Exchange -> **Cards Exchange**
- star-based reward track -> **Win Streak SB Reward Track**
- Star balance/current-star amount -> **removed**
- Event Points -> **removed**

Dynamic labels, counters, timers, prices and quantities remain live Godot UI, never baked into art.

## 14. Save-state requirements

At minimum persist:
- scrub_bucks
- hearts_current
- heart_regen_anchor/next_regen timestamp
- bot_parts
- unlocked_robot_ids
- active_robot_id
- first-clear progression flags
- active win_streak
- gift_meter_cycle_progress
- gift_meter_cycle_index
- gift milestone claimed/queued state
- unclaimed Gift Bar rewards
- owned card counts
- duplicate/extra card counts derivable from owned counts
- completed Collection sets
- booster charge counts for exactly four boosters
- current-level 2x entitlement level_id if any
- timed 2x expiry timestamp
- Daily last-claim date/timestamp, consecutive-login count and 5-day cycle position
- Daily task state/claims

All grants/spends/exchanges must use idempotent/atomic transaction IDs so UI retries or duplicate callbacks cannot double-grant or double-spend.

## 15. Planned runtime module boundaries

Implementation should use explicit services rather than scattering economy mutation through UI:

- `scripts/economy/economy_wallet.gd` — SB authoritative balance + atomic spend/grant.
- `scripts/economy/reward_grant_service.gd` — idempotent reward bundles/transactions.
- `scripts/economy/heart_service.gd` — Heart consumption/regeneration/refill.
- `scripts/economy/gift_meter_service.gd` — streak-SB-only meter, milestones, rollover.
- `scripts/economy/daily_service.gd` — login streak + daily task reward state.
- `scripts/economy/booster_inventory.gd` — exactly four booster charge counts.
- `scripts/economy/speed_entitlement_service.gd` — level/timed 2x ownership and wall-clock expiry.
- `scripts/economy/cards_exchange_service.gd` — protected-copy duplicate exchange.
- `scripts/progression/robot_unlock_service.gd` — Bot Parts and 250-part unlocks.
- `scripts/collection/collection_inventory.gd` — card counts, set completion, pack grants.

UI requests actions through these services; UI never mutates balances/inventory directly.

## 16. Engine touchpoints and invariants

This decision requires future engine work in addition to UI/economy services:

1. M24/FiveSlotBatchEngine must evolve from a hard-coded five-slot invariant to an authoritative runtime capacity of 5 or 6 while +1 Slot is active.
2. M27 solver/deadlock state encoding must include active slot capacity and prove both 5-slot and 6-slot states.
3. M28/M49 presentation must support a sixth slot without destroying portrait safe-area/readability.
4. Random booster needs a deterministic remaining-supply reorder API plus M27 solver validation for the three-safe-move guarantee.
5. Selector needs an atomic remove-from-any-remaining-supply-position + rightmost-empty-placement transaction with solver-safe eligibility.
6. Tornado needs one authoritative color-purge transaction spanning BoardState, M23 supply, M24 slots, M25 claims/reservations, M26 in-flight scheduler/agents and M27 recomputation.
7. GameplaySpeedAuthority remains only a temporal factor authority; manual 2x permission/payment is gated by SpeedEntitlementService/consumer logic. Automatic M23-exhausted 2x bypasses entitlement.
8. Timed 2x and Hearts use wall-clock timestamps and must never be implemented using gameplay delta/time_scale.
9. Save migrations must safely initialize these fields for old saves.

## 17. Precedence / superseded assumptions

This decision supersedes:
- any wording that treats manual 1x<->2x as always free;
- any Star currency / Star Exchange / current-star reward-track semantics;
- Event Points/event-progress semantics on Home;
- Home XP-bar semantics;
- the prior Economy `[TO BE DESIGNED]` gate for the systems explicitly defined here;
- generic booster design gates for the four boosters explicitly defined here.

It does NOT authorize real-money monetization. M57 remains a separate owner gate.
