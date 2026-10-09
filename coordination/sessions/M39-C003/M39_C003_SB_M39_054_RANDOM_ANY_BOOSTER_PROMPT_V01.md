# M39-C003 — SB-M39-054 Random-Any-Booster Reward Semantics Correction — CLAUDE MASTER PROMPT V01

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-09

## Owner authority

Read and obey first:

`coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md`

The current bug is semantic:

`random_booster_charges` currently grants `BoosterInventory.RANDOM` every time.

That is wrong.

The intended reward means:

> choose one booster uniformly from ALL FOUR canonical boosters and grant one saved charge of the chosen booster.

Canonical pool:

- `plus_one_slot`
- `random`
- `selector`
- `tornado`

The gameplay booster named RANDOM remains one valid member of the pool, with 25% probability. It must no longer receive 100% of these meta rewards.

Root `TASKS.md` is READ-ONLY for Claude. ChatGPT is its sole writer.

---

# EXECUTION ORDER

This remediation has priority over the already-prepared M43-C005F-PHASE4 presentation lane.

Do not mix Phase 4 work into this change.

If Phase 4 has not started, execute this task first.
If another ScrubBots implementation agent is actively changing the same repository, STOP and report the conflict instead of racing two writers on main.

---

# GATE 0 — PERSISTENT DESKTOP SYNC

Before implementation:

1. Work from:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Record:
   - Desktop HEAD
   - origin/main
   - ahead/behind
   - tracked dirty files
   - untracked count
   - stashes/worktrees
   - SHA-256 of persistent Desktop `project.godot`
3. Run:
   `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin`
4. Non-destructively reconcile Desktop to exact current origin/main while preserving all owner-local work.
5. Implementation may begin only when Desktop HEAD == origin/main and ahead/behind = 0/0.
6. Never run against persistent Desktop:
   - `git checkout -- <file>`
   - `git restore <file>`
   - `git reset --hard`
   - `git clean`
   - destructive stash/pop
   - force checkout/rebase/push
7. TEMP worktree is allowed after Gate 0 only.
8. Every TEMP command must use explicit absolute paths:
   - `git -C "<TEMP>" ...`
   - `godot --path "<TEMP>" ...`
9. If TEMP creation fails, STOP. Never fall back to modifying Desktop.
10. After final push, sync Desktop again to final origin/main and prove `project.godot` hash unchanged.

---

# READ FIRST

- `coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md`
- root `TASKS.md`
- `data/config/economy_rewards_v1.json`
- `scripts/economy/economy_services.gd`
- `scripts/economy/reward_grant_service.gd`
- `scripts/economy/booster_inventory.gd`
- `scripts/economy/booster_service.gd`
- `scripts/economy/daily_service.gd`
- `scripts/economy/gift_meter_service.gd`
- `scripts/ui/ceremony/meta_ceremonies.gd`
- `scripts/ui/ui_text.gd`
- relevant M39/M42/M43 Gift/Daily/booster tests

Inspect actual current APIs before coding.

---

# OWNER-LOCKED SEMANTICS

## 1. New canonical resource name

Replace ambiguous canonical reward naming with:

`random_any_booster_charges`

This means:

“for each charge, choose one of the four canonical booster ids and grant one charge of that selected id.”

The old resource name:

`random_booster_charges`

must NOT remain the canonical config/runtime meaning.

A legacy handler alias is allowed for compatibility, but if present it MUST call the new random-any-booster behavior. It must never directly grant `BoosterInventory.RANDOM`.

## 2. Equal pool

The eligible set is exactly:

`BoosterInventory.BOOSTERS`

Current expected members:

- PLUS_ONE_SLOT
- RANDOM
- SELECTOR
- TORNADO

Each must be equally likely.

Do not hard-code a different hidden fifth pool.

## 3. Stable deterministic transaction selection

Selection must be pseudo-random across different authoritative transactions, but deterministic for the SAME transaction.

For reward transaction `tx_id` and charge ordinal `i`, the selected booster must be a pure function of:

`tx_id + resource-domain-separator + i`

Requirements:

- same tx + same ordinal => same booster across retry/relaunch/platform;
- different tx ids can map to different boosters;
- no mutable global RNG state is consumed;
- do not consume CardPackService RNG;
- do not consume gameplay RNG;
- do not consume level/solver RNG.

Use a stable platform-independent hash/selector.

Preferred implementation:
- one small pure helper, e.g.
  `scripts/economy/random_booster_reward_picker.gd`
- derive an unsigned deterministic value from SHA-256 bytes of a UTF-8 key;
- modulo `BoosterInventory.BOOSTERS.size()`.

Do not use Python-style runtime hash or any platform-randomized hash.

## 4. N charges

For amount `n`:

- ordinals are `0..n-1`;
- each ordinal is selected independently;
- repeated booster ids are allowed;
- each selected id receives exactly one charge.

## 5. Grant idempotency

RewardGrantService remains the canonical idempotency authority.

Duplicate grant of the same authoritative tx:
- grants nothing again;
- cannot reroll;
- cannot change the selected booster.

Crash/retry before durable save must still derive the same selected booster for the same tx.

Do not add a second persistent selection ledger unless current architecture truly requires it. Prefer pure deterministic selection from tx id.

---

# REQUIRED REWARD-SURFACE CORRECTION

Update every CURRENT shipping reward that semantically means “random one of all boosters”.

At minimum:

## Gift Meter milestone 50

Current:
`"random_booster_charges": 1`

Correct:
`"random_any_booster_charges": 1`

Expected result:
exactly one of the four canonical booster charge counters increments by one.

## Daily Login Day 3

Change the same resource meaning to random-any.

## Daily all-3-tasks / ScrubBox bonus

Current DailyService constructs:
`{"random_booster_charges": ...}`

Correct it to the new canonical resource.

Do not change amount = 1 unless the current config says otherwise.

## Do NOT change

- `selected_booster_charges`
- Gift Meter 500/1000 Booster of Your Choice
- Daily D5 Booster of Your Choice
- actual RANDOM gameplay booster behavior
- booster prices
- Need-a-Hand booster ranking
- booster use legality

---

# PRESENTATION CORRECTION

Current UI wrongly reinforces the bug:

- reward key `random_booster_charges`
- text “Random Booster”
- generic row uses the actual RANDOM gameplay booster icon.

Fix the distinction.

## Canonical generic reward wording

Add a dedicated string for the random-any reward.

Preferred English label:

**Mystery Booster**

or another equally clear wording approved by existing UI style.

It must not look like the named gameplay booster **RANDOM**.

## Gift ceremony

In `MetaCeremonies.REWARD_ROWS`:

- use the new canonical resource key;
- use a neutral reward/gift visual for pre-claim display;
- DO NOT use `assets/ui/final/boosters/random.png` for the generic reward.

No new art generation is required.

Use an existing neutral gift/reward asset already in the repo.

## Daily presentation

Daily reward text for the new key must say Mystery Booster / equivalent.

The actual named gameplay booster remains displayed as RANDOM only on booster gameplay/acquisition surfaces.

---

# CONFIG / SCHEMA

Update `data/config/economy_rewards_v1.json`.

Do NOT silently weaken EconomyConfig validation.

If schema_version does not need to change because the file remains the same structural schema, keep it unchanged.

If validation should explicitly reject ambiguous coexistence of old+new keys in canonical config, add a focused validation rule.

Do not break older save imports. Reward config keys are not permission to corrupt persisted BoosterInventory state.

---

# TEST REQUIREMENTS

Create a focused permanent suite, e.g.:

`tests/m39_c003_random_any_booster_rewards.gd`

At minimum prove all of the following.

## A. Pool correctness

For deterministic test tx ids across a sufficiently broad sample:

- +1 Slot is reachable;
- Random is reachable;
- Selector is reachable;
- Tornado is reachable.

No unknown booster id can be selected.

## B. Equal-selection algorithm

The selection mapping must be unbiased at the algorithm level:
- SHA-derived integer modulo exact pool size 4;
- every index 0..3 is valid.

Do not fake “equal probability” by cycling based only on test fixture order.

A deterministic distribution sanity test over many distinct tx ids is welcome, but exact 25/25/25/25 counts are not required for a finite pseudo-random sample.

## C. Stable replay

For one tx:
- first derived selection = X;
- repeated derivation = X;
- recreate EconomyServices / relaunch fixture with same tx = X.

## D. Reward idempotency

Grant one random-any charge under tx T:
- total booster charges increase by exactly 1;
- exactly one canonical booster charge counter increases;
- duplicate grant T increases nothing;
- duplicate cannot reroll into another booster.

## E. Gift Meter 50

Claim `gift_ms:c0:m50`:
- one Bot Part still grants as before;
- exactly one random-any canonical booster charge grants;
- it is NOT always RANDOM across varied cycle/tx fixtures;
- claim remains exactly-once.

## F. Daily D3

Prove D3 grants exactly one random-any booster and no duplicate.

## G. All-tasks / ScrubBox

Prove 3/3 daily task bonus grants exactly one random-any booster and no duplicate.

## H. Selected-booster protection

Prove:
- Gift 500/1000 selected-booster pool still increments `pending_selected`;
- D5 remains selected-booster/player-choice;
- no random selection occurs for `selected_booster_charges`.

## I. Named RANDOM booster remains intact

Prove:
- `BoosterInventory.RANDOM == "random"`;
- Random gameplay booster still has its existing config/price/behavior;
- random-any reward does not rename/remove the gameplay booster.

## J. Presentation

Prove:
- canonical generic reward row no longer binds the actual RANDOM booster icon;
- generic text no longer reads as the named gameplay booster;
- Daily label uses the new generic wording;
- selected-booster wording/art unchanged.

---

# REGRESSION

Run and record at minimum:

- new focused M39-C003 suite
- M39 boosters
- M39 daily/collection
- M39 full matrix
- M39 V02/V03/V04 suites
- M40 save/import
- M42 Home/Daily
- M43 Gift ceremonies
- M43 Daily/Tasks
- M43 C003 acquisitions
- M43 Phase 3 feel
- Rewarded Ads functional suite
- root `tests/run_tests.gd`
- headless import/boot
- `git diff --check`

Any first-run failure must be disclosed.

---

# SCOPE EXCLUSIONS

Do NOT modify:

- Remote Content/R2
- LevelData
- supply
- VOID
- Family APK
- Level Factory
- pack RNG or pack opening behavior
- gameplay Random booster semantics
- M43 Phase 4 feel work
- root TASKS.md

Do not introduce a fifth booster.

---

# RUNTIME EVIDENCE

Provide evidence sufficient to inspect the result without manipulating production state by hand.

At minimum capture/log:

1. Gift Meter 50 claim before/after charge counters
2. several deterministic Gift/Daily test tx ids showing different selected booster ids
3. one case where RANDOM is selected
4. one case where a non-RANDOM booster is selected
5. generic Gift/Daily reward presentation showing “Mystery Booster” / equivalent and not the RANDOM gameplay icon

No owner visual redesign gate is required if existing neutral reward art is reused cleanly.

---

# PUBLICATION

Builder log:

`coordination/sessions/M39-C003/M39_C003_SB_M39_054_CLAUDE_LOG_V01.md`

Push implementation, tests, evidence and log normally to `main`.

After push:
- non-destructively sync persistent Desktop to final origin/main;
- prove Desktop HEAD == origin/main;
- prove ahead/behind 0/0;
- prove owner `project.godot` hash unchanged.

Final state:

`AWAITING_GPT_SB_M39_054_STRICT_AUDIT`
