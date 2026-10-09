# M39-C003 — SB-M39-054 Random-Any-Booster Reward Semantics Correction — STRICT AUDIT CRITERIA V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`

## Verdict

PASS only if “random booster reward” now means one uniformly eligible selection from all four canonical boosters, while the named gameplay booster RANDOM remains unchanged.

## G0 — Desktop safety

PASS only if:
- Desktop exact origin/main before implementation;
- owner-local work preserved;
- no destructive checkout/restore/reset/clean on persistent Desktop;
- TEMP work uses absolute paths;
- final Desktop exact origin/main, 0/0;
- project.godot hash unchanged.

## A — semantic distinction

- canonical reward resource is `random_any_booster_charges` or an equivalently unambiguous new key;
- canonical config no longer uses ambiguous old semantics;
- legacy alias, if retained, routes to random-any behavior;
- no handler directly maps the generic reward to `BoosterInventory.RANDOM`.

## B — exact pool

Eligible pool is exactly `BoosterInventory.BOOSTERS`:
- plus_one_slot
- random
- selector
- tornado

No fifth booster.

All four are reachable.

## C — deterministic pseudo-random selection

Selection:
- uses tx id + charge ordinal;
- is platform-stable;
- uses no mutable gameplay/pack/solver/level RNG;
- same tx+ordinal always yields same booster;
- differing tx ids can produce differing boosters;
- modulo maps into exact pool size 4.

## D — grant/idempotency

For one-unit reward:
- total charges +1 exactly;
- one and only one booster counter +1;
- duplicate tx +0;
- duplicate tx never rerolls.

For n>1:
- exactly n charges total;
- one deterministic selection per ordinal;
- repeats allowed.

## E — shipping surfaces

Gift 50:
- +1 Bot Part unchanged;
- +1 random-any booster;
- exactly-once claim.

Daily D3:
- +1 random-any booster.

3/3 Tasks / ScrubBox:
- +1 random-any booster.

Selected booster rewards at Gift 500/1000 and D5:
- unchanged;
- remain player-choice pending_selected.

## F — named RANDOM booster protection

- canonical id/name/config remains RANDOM / `random`;
- gameplay Random effect unchanged;
- price unchanged;
- no rename/removal.

## G — presentation

- generic random-any reward no longer uses the actual RANDOM gameplay icon;
- generic wording distinguishes the reward from the RANDOM gameplay booster;
- Daily presentation uses the new generic label;
- Booster-of-Choice presentation unchanged.

## H — persistence/backward safety

- existing BoosterInventory snapshot/import shape remains valid;
- older save state with four charge counters imports unchanged;
- no new unnecessary persistent RNG/selection ledger;
- same tx replay derives same booster.

## I — regression

Required PASS:
- focused M39-C003
- M39 boosters
- M39 daily/collection
- M39 full matrix
- M39 V02/V03/V04
- M40 save
- M42 Home/Daily
- M43 Gift/Daily/Tasks/acquisition
- Phase3 feel
- root ALL PASS
- headless import/boot
- git diff --check

First-run failures must be disclosed.

## J — scope

FAIL if implementation changes:
- Remote Content/R2
- LevelData/supply/VOID
- Family APK
- Level Factory
- pack RNG
- pack ceremony behavior
- Phase4 feel work
- root TASKS.md by Claude

Final verdict:
- PASS
- or CHANGES_REQUIRED.
