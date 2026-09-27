# SB-M55-C001 — CORE CHAOS / LONG-RUN QA + HEART 900s RECONCILIATION

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Scope

Execute **SB-M55-001..017 only**.

Do NOT implement SB-M55-018..024. Those depend on later M43+ Player Experience surfaces.

Do NOT edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_HEART_REGEN_INTERVAL_V01.md`
4. `coordination/sessions/M54-C001/CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M54-C001/CHATGPT_AUDIT_V02.md`
6. relevant M39/M40/M52 runtime/audit evidence
7. current production code/tests for M55 scope

## OWNER-LOCKED Heart ruling

Canonical Heart regen is:

**900 seconds / 15 real-world minutes per Heart.**

Preserve:
- max 5;
- wall-clock/offline/background/menu semantics;
- +1 Heart = 500 SB;
- full refill = 400 SB per missing;
- clock-rollback safety.

The 30-minute paid 2x product is unrelated and must NOT be changed.

## Step 0 — reconcile stale active references

Before chaos work, reconcile active nonhistorical planning/config references to the owner ruling.

At minimum inspect and correct if stale:
- `data/config/player_experience_plan_v1.json`: Heart regen 30 -> 15 minutes;
- `docs/MASTER_UI_SYSTEM.md`: active Home/Heart semantics 30 -> 15 minutes;
- any other **active, nonhistorical** docs/config that assert Heart regen = 30 min / 1800 s.

Rules:
- do not rewrite historical owner decision files merely to erase provenance;
- the new owner ruling supersedes their interval field;
- do not alter any unrelated 30-minute 2x duration;
- current `economy_rewards_v1.json`, HeartService and M39B tests already use 900; preserve them unless a real defect is found.

Add a focused consistency/regression check so the active Heart authorities cannot silently drift back to 30 minutes.

## M55 current-build chaos scope

Validate the real production stack for:

- SB-M55-001 spam all five slots;
- SB-M55-002 restart while bots travel;
- SB-M55-003 pause while bots travel;
- SB-M55-004 background while bots travel;
- SB-M55-005 complete with bots in flight;
- SB-M55-006 exhaust color;
- SB-M55-007 exhaust slot work;
- SB-M55-008 repeated scene transitions;
- SB-M55-009 long high-load session;
- SB-M55-010 memory growth monitoring;
- SB-M55-011 duplicate signal monitoring;
- SB-M55-012 orphan Node monitoring;
- SB-M55-013 duplicate reward monitoring;
- SB-M55-014 spam booster use/purchase/charge actions and prove no double spend/use;
- SB-M55-015 background/foreground across **900-second Heart regen** and timed 2x expiry;
- SB-M55-016 Tornado while matching-color agents are in flight; prove atomic reconciliation;
- SB-M55-017 Cards Exchange-all under repeated taps; prove protected first copies and no duplicate SB grant.

## Evidence quality

For every row:
- exercise the production authority, not a parallel toy implementation;
- record exact repetitions/duration/fixtures;
- reject false-green results by checking exit code, FAIL, SCRIPT ERROR and runtime ERROR output;
- distinguish expected historical fixture errors from new runtime faults;
- where memory/node/signal growth is measured, record before/after values and a bounded pass rule rather than saying "looks stable";
- repeated actions must prove idempotency/atomicity, not merely "no crash".

Do not weaken tests to make chaos cases pass.

## First 10/content lock

Do not change:
- Levels 1–10 art/LevelData;
- owner supply plans or owner-provided solution sequences;
- difficulty models/classes/targets;
- automatic solution/batch-color work.

## Required outputs

Create:

- `coordination/sessions/M55-C001/M55_CORE_CHAOS_MATRIX_V01.md`
- `coordination/sessions/M55-C001/CLAUDE_LOG_V01.md`

Map SB-M55-001..017 to PASS / FAIL / OWNER_REQUIRED / NOT_APPLICABLE with exact evidence.

Run:
- focused new M55 suites;
- Heart 900-second consistency/regression;
- M39B Hearts/2x;
- relevant M39C/M39D/M39E;
- M40 save;
- M52 R01/R02 and applicable production-runtime regression;
- root `tests/run_tests.gd`;
- `git diff --check`.

## Stop rule

If a real production defect appears, fix only within the owning current-build subsystem and add a sensitivity regression. If the needed behavior is owner-design-gated or belongs to M43+ future surfaces, stop and report the exact gate rather than inventing policy.

## Handoff

Commit and push all authorized work.

Finish with:

`AWAITING_CHATGPT_AUDIT / M55-C001 CORE CHAOS LONG-RUN QA`

Do not edit TASKS.md.
