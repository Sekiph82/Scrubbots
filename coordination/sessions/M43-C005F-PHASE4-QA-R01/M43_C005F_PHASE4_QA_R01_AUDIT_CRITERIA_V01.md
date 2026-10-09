# M43-C005F-PHASE4-QA-R01 — Long-Session Baseline Hygiene + MetaRewardFeel Await Safety — STRICT AUDIT CRITERIA V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`

## Verdict

PASS requires both:
1. M55 long-session becomes a valid strict steady-state leak test and passes;
2. MetaRewardFeel await-after-free lifecycle warning is eliminated without authority/visual regression.

## G0 — Desktop safety

- Desktop exact origin/main before work.
- owner-local files preserved.
- no destructive Desktop checkout/restore/reset/clean.
- TEMP absolute paths only.
- final Desktop exact origin/main, 0/0.
- owner project.godot hash unchanged.

Any Desktop mutation = FAIL.

## A — M55 warm-up model

PASS only if:
- transition-churn stability checks remain;
- first real 10-level lap still runs all gameplay/reward/idempotency checks;
- first-lap first-use Node/Object/static-memory materialization is recorded, not silently ignored;
- second same-workload lap is the strict steady-state leak comparison;
- lap2 Node count must exactly equal lap1 end;
- lap2 orphan count cannot grow;
- lap2 Object drift stays <= existing 64;
- lap2 static-memory drift stays <= existing 4 MiB;
- host/root-child/listener stability remains checked.

FAIL if thresholds are raised or checks removed.

## B — Long-session stability

Final corrected `m55_long_session.gd`:
- 3 consecutive runs;
- 3/3 PASS;
- no retry substitution;
- no unexpected SCRIPT ERROR.

## C — MetaRewardFeel lifecycle

PASS only if:
- no coroutine resumes on a freed RefCounted;
- target disappearing during settle is handled safely;
- no persistent helper/listener/node/tween leak;
- same trigger seams/intents/keys/targets preserved;
- Reduced semantics unchanged;
- grants/save/navigation/economy unchanged.

Exact warning:
`Resumed function '_play()' after await, but class instance is gone`
must occur 0 times in final lifecycle/M55 logs.

## D — Phase 4 product freeze

F010/F012 behavior remains:
- nav-first F010;
- WON-only SMALL bridge;
- no duplicate WIN;
- Home snapshot fields unchanged;
- MICRO Home response;
- max two serialized;
- no Home Spark;
- Reduced zero plugin/native decorative work.

Any unrelated redesign = FAIL.

## E — regression

Required PASS:
- Phase4 focused
- Phase1/2/3
- Standard/Premium QA-R01
- M30
- M40
- M41
- M42
- M43 Results
- M55 long-session
- M55 economy/core/heart/timed2x
- CP04/CP05
- root ALL PASS
- headless import/boot
- git diff --check

No failing suite allowed.

## F — scope

Allowed:
- M55 long-session test
- MetaRewardFeel lifecycle safety
- focused QA test/helper
- QA log

Forbidden:
- Remote Content/R2
- LevelData/supply/VOID
- Family APK
- Level Factory
- economy/reward values
- owner-approved Results/Home layout
- root TASKS.md by Claude

Final verdict:
- PASS
- or CHANGES_REQUIRED.
