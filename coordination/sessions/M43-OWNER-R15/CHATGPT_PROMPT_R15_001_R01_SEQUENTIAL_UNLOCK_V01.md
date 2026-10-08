# SB-M43-R15-001-R01 — Rewarded Ads Sequential Unlock Remediation V01

Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:/Users/sekip/Desktop/ScrubBots`
Status: AUTHORIZED PARALLEL LANE
Date: 2026-10-08

## Purpose

Implement the owner's locked sequential Rewarded Ads rule without touching the active Remote Level Update / R2 content-runtime lane.

Owner rule:

`Slot 1 CLAIM -> Slot 2 WATCH AD -> verified grant unlocks Slot 3 -> verified grant unlocks Slot 4 -> verified grant unlocks Slot 5`.

Future slots cannot be started early. Any no-grant outcome does not advance the sequence. No Home badge is required.

## Safe sync / governance

Before coding:
- inspect owner-local branch/status/HEAD, origin/main, ahead/behind, untracked files and worktrees;
- non-destructively synchronize `C:/Users/sekip/Desktop/ScrubBots` with latest `origin/main` while preserving owner-local work;
- no `reset --hard`, `git clean`, force checkout/push, destructive overwrite, or silent stash loss;
- root `TASKS.md` is read-only for Claude;
- do not edit `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/**`, `scripts/content_runtime/**`, or `data/config/remote_content_runtime_v1.json`;
- do not implement any LF/R2/publisher work.

## Current accepted authority

Retain the existing R15 implementation:
- exactly five daily Rewarded Ads slots;
- slot 1 is direct exactly-once claim;
- slots 2-5 use the canonical provider-neutral rewarded pipeline;
- deterministic economy IDs remain `daily_rewarded:<local_day>:<slot>`;
- provider token remains separate from economy identity;
- Daily login streak/cycle, Daily Scrub Orders, Hearts, boosters, Gift Meter and 2x remain unchanged;
- production rewarded provider remains honestly unavailable until M57;
- current Home placement and accepted R15-004 visual binding remain unchanged.

## Required remediation

Change only availability/progression so the five-slot track is strictly sequential.

For the current local day:

1. Fresh day: only Slot 1 is actionable.
2. Until Slot 1 grants successfully, Slots 2-5 are future-locked and cannot start.
3. After Slot 1 is successfully granted, Slot 2 becomes the sole current ad slot.
4. Slot 3 unlocks only after Slot 2 receives a verified successful grant.
5. Slot 4 unlocks only after Slot 3 receives a verified successful grant.
6. Slot 5 unlocks only after Slot 4 receives a verified successful grant.
7. After Slot 5 grants, all five are claimed for that local day.

For Slots 2-5:
- cancel, skip, fail, timeout, unverified callback, provider refusal/unavailable, unknown token, abandoned request, duplicate callback, or any other no-grant outcome must NOT unlock the next slot;
- while the current slot is pending, future slots remain locked;
- duplicate/late callback cannot advance twice;
- attempting to start a future slot through service/facade/UI bypass must fail closed before provider request;
- relaunch must reconstruct the same current sequential position from canonical durable grant truth;
- forward local-day reset returns to Slot 1;
- existing rollback/high-water protection remains intact and cannot reopen or skip sequence positions.

Do not add a second progress ledger if the canonical applied transaction IDs can derive the sequence safely.

## UI boundary

Do not redesign Rewarded Ads.

Preserve:
- existing popup geometry and Home CTA;
- approved R15-004 placement;
- five visible reward rows;
- configured reward amounts;
- existing production provider unavailable behavior.

Future slots must be visibly non-actionable. Reuse the existing state/copy system where possible. If one small code-rendered locked-state label is necessary, keep it minimal and do not add new art.

No Home badge.

## Tests

Extend permanent R15 coverage to prove at minimum:

- fresh day: slot 1 actionable, slots 2-5 cannot start;
- slot 1 successful claim unlocks only slot 2;
- slot 2 verified grant unlocks only slot 3;
- slot 3 verified grant unlocks only slot 4;
- slot 4 verified grant unlocks only slot 5;
- slot 5 verified grant completes the day;
- direct service/facade attempts to jump to slots 3/4/5 fail closed;
- unavailable/refused/cancelled/skipped/failed/timeout/unverified/unknown/abandoned outcomes do not advance;
- pending current ad does not expose later slots;
- duplicate/late callback does not advance twice;
- relaunch preserves exact sequential position;
- forward local day resets to slot 1;
- rollback protection remains correct;
- existing Heart/booster rewarded behavior unchanged;
- Daily login / Daily Scrub Orders / Gift / economy snapshots unaffected outside the intended rewarded-daily state;
- current Home shortcut placement remains unchanged.

Run:
- focused R15 remediation suite;
- existing R15 suite;
- M39 Daily regressions;
- M40 save regressions;
- M43 acquisition / Need a Hand regressions;
- M41 settings regression if touched indirectly;
- root test suite;
- `git diff --check`.

No unexplained script errors.

## Evidence / log

Write:

`coordination/sessions/M43-OWNER-R15/SB-M43-R15-001-R01_CLAUDE_LOG_V01.md`

Record:
- starting and final SHA;
- owner-local sync evidence;
- exact files changed;
- progression-state truth table;
- focused and regression results;
- explicit assertion that Remote Content / R2 files were untouched.

Do not edit root `TASKS.md`.

Finish exactly:

`AWAITING_GPT_SB_M43_R15_001_R01_AUDIT`
