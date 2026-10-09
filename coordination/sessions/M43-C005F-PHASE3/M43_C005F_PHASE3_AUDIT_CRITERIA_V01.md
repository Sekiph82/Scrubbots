# M43-C005F-PHASE3 — Meta Rewards + Acquisition Feel — STRICT AUDIT CRITERIA V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`

## Verdict

PASS requires all three children to satisfy presentation-only, idempotent, fail-open behavior with no Remote Content/R2 changes.

Harness-only evidence is insufficient where a shipping surface exists.

## G0 — Desktop sync process gate

PASS only if builder evidence proves:
- persistent `C:\Users\sekip\Desktop\ScrubBots` was reconciled to exact current origin/main BEFORE implementation;
- owner-local files were preserved;
- no destructive reset/clean/force operation;
- after final push, persistent Desktop tracked HEAD was reconciled again to final origin/main;
- final Desktop ahead/behind = 0/0.

A TEMP-only implementation with stale owner Desktop = FAIL.

## A — architecture boundary

- FeedbackAdapter remains the only production plugin gateway.
- no direct GameFeelFlow/Spark production call outside adapter.
- no GFF forcing onto Control via invented wrapper/reparent architecture.
- native Tween is allowed for Control presentation.
- no flash/camera/freeze/time-scale/global Spark.clear.
- feel code owns no grant/save/navigation/progression authority.
- no new durable feel state.
- Reduced produces zero plugin work.

## B — F006 Collection completion

Set:
- existing canonical ceremony only;
- one REWARD-tier event per authoritative ceremony key.

Master:
- existing canonical ceremony only;
- stronger MAJOR_REWARD tier, still capped.

Both:
- one-shot under refresh/reopen/resize/drain repeats;
- no change to 9/9, 15-set, rewards, acknowledgement or save truth;
- serialized with current CeremonyPresenter.

## C — F008 Gift/Daily/Tasks/ScrubBox

- Gift milestone feedback comes from canonical shown event only.
- Gift claim only after committed action.
- Daily login only after committed action.
- individual task claim stays restrained.
- ScrubBox only after committed all-tasks bonus and existing shipping ScrubBox opens.
- stable presentation identities are canonical, not random counters.
- duplicate/refused/rollback claims produce zero success feel.
- Home refresh/reopen/resize produces zero replay.
- pack-opening ordering and pending-pack authority unchanged.
- all reward amounts/idempotency/local-day rules unchanged.

## D — F009 Acquisition

- success feedback only after canonical commit.
- Heart buy/refill success one-shot.
- booster charge/use success one-shot.
- rewarded success one-shot by canonical token/tx.
- insufficient/illegal/cancel/fail/timeout/unverified/duplicate = zero success feel.
- no generic button coating.
- no use of forbidden GFF UI combos.
- grant/save/booster legality remains authoritative and unchanged.

## E — plugin failure/fallback

For all three children:
- plugin absent: shipping action/ceremony succeeds unchanged.
- plugin throws: caller authority still succeeds unchanged.
- Reduced: final static truth readable, zero plugin dispatch.
- adapter budgets respected.
- no orphan emitter/tween ownership after popup/route closure.

## F — regression

Required PASS:
- Phase1 foundation
- Phase2 Results/Pack
- earned pack R01/R02
- relevant M39
- M41
- M43 Collection/ceremony
- M43 C003 acquisition
- M43 C009/R09 Daily/Tasks/Gift
- M43 C014 meta feedback
- R15 Rewarded Ads functional sequence
- root run_tests
- headless boot/import
- git diff --check

Any one-off flaky failure must be disclosed with exact test and rerun evidence; do not silently relabel a failing first run as clean.

## G — scope exclusion

FAIL if implementation changes Remote Content/R2 semantics, endpoint configuration, LevelData, supply, VOID, Family APK flow or Level Factory.

Root `TASKS.md` must remain untouched by Claude.

## H — runtime evidence

Mandatory real shipping captures:
- Set Complete FULL
- Master Collection FULL
- Gift milestone FULL
- ScrubBox FULL
- acquisition success FULL
- representative REDUCED state(s)
- acquisition failure/no-success case

At 1080×2160 and 1536×2048 where applicable.

Technical PASS may still remain AWAITING OWNER VISUAL ACCEPTANCE.

Final verdict:
- `PASS / AWAITING OWNER VISUAL ACCEPTANCE`, or
- `CHANGES_REQUIRED`.
