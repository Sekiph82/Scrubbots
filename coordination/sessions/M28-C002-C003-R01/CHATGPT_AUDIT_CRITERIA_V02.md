# M28-C002-C003-R01 — CHATGPT AUDIT CRITERIA V02

Date: 2026-09-29
Auditor: ChatGPT

This V02 supersedes the V01 criteria for this remediation cycle.

Expected technical verdict if clean:

`AUDITED_PASS / OWNER FINAL REPLAY REQUIRED`

## A. Timed 2x

PASS requires:
- active timed entitlement auto-starts every new gameplay/level at live 2x;
- relaunch + gameplay does the same while time remains;
- manual 1x/2x switching remains free;
- next new level returns to default 2x while timed remains;
- expiry returns normal new gameplay to 1x;
- current-level 200 SB product remains level-scoped;
- M55 anti-rollback and M23 free auto-2x remain correct;
- UI countdown and runtime factor cannot disagree at new-level start.

## B. Slot labels

PASS requires no visible `WAITING` or `ACTIVE` text on the five-slot row (and shared sixth-slot component), with slot truth/state otherwise unchanged.

## C. Railway-first routing

PASS requires Scrubbots to:
- join the existing railway from the slot connector;
- remain on the perimeter railway until the nearest valid exit to the assigned target;
- use only a short final direct leg into the board;
- avoid long direct/diagonal board shortcuts;
- preserve target, claim, reservation, clearing and solver truth.

Representative left/right/top/bottom/corner targets must be tested.

## D. Pixel grid / bevel

PASS requires:
- dynamic grid derived from real logical board dimensions;
- no fixed universal mask;
- no per-pixel Node explosion;
- visible logical-cell separation;
- subtle tile/bevel effect;
- no ghost grid on cleared cells;
- palette and coordinate truth unchanged;
- representative 20–59-ish density coverage.

## E. Home background

PASS requires runtime Home to use exactly:

`assets/ui/final/home/background/home_background.png`

No regeneration/substitution. Live UI stays separate and functional. No duplicate old background layer.

## F. Scope / regression

FAIL for:
- price/duration drift;
- Heart/booster rule drift;
- M23 auto-2x regression;
- solver/target/claim truth changes caused by visual routing;
- unrelated Gameplay/Home redesign;
- root `TASKS.md` modified by Claude.

Required regression evidence must cover relevant M28/M29/M30/M39/M40/M42/M43/M52/M55 plus routing/solver/clearing and root suite.

## G. Owner gate

Technical PASS does not close SB-M28-C002-020.

Owner must replay/inspect:
1. timed 2x across level transition;
2. slot row without WAITING/ACTIVE;
3. railway-first motion;
4. grid/bevel readability;
5. Home with the selected new background.

Only owner acceptance closes M28-C002.
