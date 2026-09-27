# SB-M54-C001 — FIRST 10 FINAL REGRESSION / CONTENT VALIDATION

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Task scope

Execute the **applicable current First 10 M54 regression block: SB-M54-001 through SB-M54-021**.

Do NOT work on SB-M54-022..032. Those belong to later M43+ Player Experience systems that are not built yet.

Read:
1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_FIRST10_ACCEPTED_DIFFICULTY_DEFERRED_V01.md`
4. `coordination/sessions/M52-C001/FINAL_OWNER_ACCEPTANCE_V01.md`
5. relevant M52 R01/R02 audits/evidence
6. current tests and production code for SB-M54-001..021

## Owner lock

All Levels 1–10 are accepted for the current build.

Do NOT:
- recalculate or retune difficulty;
- modify difficulty classes/targets/models;
- invent new level solutions;
- optimize batch/color choice;
- alter First 10 art, LevelData, supply plans or owner-provided solution sequences;
- implement M43+ UI/meta systems.

Use the existing owner-provided First 10 sequences as the canonical replay inputs.

## Mission

Prove that the accepted First 10 pack and all currently implemented supporting systems remain stable together on current `main`.

Validate SB-M54-001..021 as applicable to the current codebase:

- difficulty/progression regression only for existing behavior, not score recalibration;
- Level parser;
- BoardState;
- renderer;
- slot engine;
- color candidate/reachability;
- reservations;
- TargetSelector;
- routing/Railroad V1;
- dispatcher;
- completion;
- save;
- rewards;
- content validation;
- 59x59 regression;
- Wallet/Gift Meter/Daily/Cards Exchange/Collection idempotency;
- set/master collection exactly-once rewards where implemented;
- Heart regeneration;
- 2x entitlement/free auto-2x;
- +1 Slot;
- Random/Selector safety;
- Tornado conservation/rollback/no-ghost.

## First 10 production proof

Re-run the canonical First 10 production validation using the existing owner-approved plans.

Required:
- Levels 1–10 all load correctly;
- Levels 1–10 all replay/complete with their existing approved inputs;
- Levels 2–10 production runtime reaches WON;
- Level 1 remains playable/accepted;
- Level 11 remains CONTENT_MISSING if that is still the canonical frontier;
- no content bytes are changed;
- no owner plan bytes are changed.

## Regression integrity

Run focused suites for SB-M54-001..021 plus:
- M52 owner-plan suite;
- R01;
- R02;
- root `tests/run_tests.gd`;
- `git diff --check`.

Reject false-green suites:
- check exit code;
- check FAIL count;
- check SCRIPT ERROR/runtime error output;
- use existing completion ledgers where present.

If an existing M54 row cannot honestly be validated because its owning implementation does not exist yet, report it as `NOT_APPLICABLE_CURRENT_BUILD` with exact evidence rather than inventing implementation. Do not expand scope.

## Evidence

Create:

`coordination/sessions/M54-C001/FIRST10_M54_REGRESSION_MATRIX_V01.md`

`coordination/sessions/M54-C001/CLAUDE_LOG_V01.md`

The matrix must map **SB-M54-001..021** to:
- PASS;
- NOT_APPLICABLE_CURRENT_BUILD; or
- FAIL/BLOCKED;
with exact test/evidence references.

## Stop conditions

If any regression affects production First 10 gameplay/content stability:
- do not change level design;
- isolate the regression;
- report exact failing task IDs and evidence;
- stop for ChatGPT audit/remediation.

Do not edit `TASKS.md`.

## Handoff

Commit and push all test/evidence work.

Finish with:

`AWAITING_CHATGPT_AUDIT / M54-C001 FIRST 10 FINAL REGRESSION`
