# OWNER RANDOM-ANY-BOOSTER REWARD SEMANTICS CORRECTION V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`
Authority: OWNER
Status: **LOCKED**

## Problem

The existing reward resource `random_booster_charges` is currently interpreted as:

`grant one charge of the canonical gameplay booster whose id is "random"`

That is NOT the owner's intended reward meaning.

The game has four canonical boosters:

1. `plus_one_slot`
2. `random`
3. `selector`
4. `tornado`

The gameplay booster named **RANDOM** remains a real booster whose effect shuffles remaining supply. It must not be confused with a meta reward that means “give me one randomly selected booster”.

## Owner ruling

A reward described as **one random booster** means:

> grant one charge of ONE booster selected from the complete canonical four-booster pool.

All four canonical boosters are eligible, including the gameplay booster named `random`.

For one reward unit, each canonical booster must have equal selection probability:

- +1 Slot: 25%
- Random: 25%
- Selector: 25%
- Tornado: 25%

For `n > 1`, select each charge independently. Repeats are allowed.

## Transaction/idempotency ruling

Selection must be stable for the same authoritative reward transaction.

A crash/retry, duplicate callback, reload or re-entry must NOT reroll the booster.

The selection must derive deterministically from:
- the canonical reward transaction id;
- the charge ordinal within that transaction.

It must NOT consume:
- gameplay RNG;
- card-pack RNG;
- level-generation RNG;
- solver RNG.

Once granted, the selected charge persists through the normal BoosterInventory save state.

## Scope

This semantic correction applies to every reward surface that currently means “one random booster from all boosters”, including at least:

- Gift Meter milestone 50;
- Daily Login Day 3;
- Daily all-3-tasks / earned ScrubBox bonus.

It does NOT change:

- the canonical gameplay booster named RANDOM;
- its gameplay behavior or price;
- `selected_booster_charges` / Booster of Your Choice at Gift Meter 500/1000 and Daily D5;
- booster purchase/use rules;
- Need-a-Hand ranking.

## Naming/presentation rule

Code/config must no longer use an ambiguous canonical resource name that can be read as “charge for the RANDOM booster”.

Canonical resource name:

`random_any_booster_charges`

A temporary legacy alias `random_booster_charges` may be accepted only for backward compatibility, but if accepted it must use the NEW random-any-booster semantics. It must never directly mean `BoosterInventory.RANDOM` again.

Presentation must also distinguish the concepts:

- gameplay booster: **RANDOM**
- meta reward: **MYSTERY BOOSTER** / equivalent clear wording meaning “randomly selected booster”

Do not use the RANDOM gameplay booster icon as the generic pre-claim reward icon. Use a neutral reward/gift presentation unless the actual selected booster is explicitly known.

## Final acceptance law

A valid implementation must prove over deterministic test transactions that all four canonical booster ids are reachable, while one repeated transaction always produces the exact same selected booster and exactly one charge.
