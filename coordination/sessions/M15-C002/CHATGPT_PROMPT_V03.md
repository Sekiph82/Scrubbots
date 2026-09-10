# M15-C002 — TargetSelector Strict Closure V03

Status: **ISSUED — SAME FROZEN FINDING SET / FINAL TRANSACTIONAL CLOSURE**

H!veAI contract: **GitHub-first v3**.

Fix ONLY the remaining parts of:
- F-M15-STRICT-004
- F-M15-STRICT-005

Do not implement M19 here. M19-C001 remains blocked until this V03 is independently audited.

## Read first

- `.hiveai/RULES.md`
- `.hiveai/TASKS.md`
- `.hiveai/PROJECT.json`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `coordination/sessions/M15-C002/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`
- `coordination/sessions/M15-C002/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M15-C002/CHATGPT_AUDIT_V02.md`
- `coordination/sessions/M15-C002/CHATGPT_PROMPT_V02.md`
- this prompt + `CHATGPT_AUDIT_CRITERIA_V03.md`

Expected log:
`coordination/sessions/M15-C002/CLAUDE_LOG_V03.md`

## H!veAI start ordering is mandatory

Safely sync `origin/main`, preserve owner work, and re-read canonical `.hiveai/TASKS.md`.

Expected:
- currentTaskId = `M15-C002-V03`
- workflowState = `CHANGES_REQUIRED`
- requiredActor = `CLAUDE`
- progress = `278 / 719 = 38.66%`

Before writing ANY production or test edit for V03:
1. update canonical tracker to `IN_PROGRESS`;
2. append the matching event;
3. commit;
4. push that transition to `origin/main`;
5. only then edit production/tests.

V02 disclosed a local-ordering violation. Do not repeat it.

If canonical state differs: `HIVEAI_STATE_CONFLICT`.
If tracker push fails: `GITHUB_TRACKING_NOT_SYNCED`.

## 1. Block selection during a bind transaction

Current V02 has `_in_bind`, but selection only rejects `_in_selection`.

Required:
- `select_and_reserve()` returns `-1` immediately when `_in_bind` is true;
- rejection happens before candidate/reservation/access callbacks;
- zero reservation mutation;
- zero targetability query.

Direct tests must start with selector already validly bound to bundle A, then call outer `bind(B)` and inject nested selection from:
- B candidate `is_bound_to()` callback;
- B reservation `is_bound_to()` callback.

For each:
- nested selection = -1;
- old A reservation count unchanged;
- B has no reservation before outer bind commits;
- outer valid bind B commits once;
- selector ends coherent with B;
- a later ordinary selection on B succeeds.

This closes F-M15-STRICT-005.H.

## 2. Treat post-targetability owner query as a full external boundary

Required exact order after `access_query.is_targetable(idx)`:
1. check operation coherence;
2. call `rs.get_target_for_owner(owner_id)`;
3. validate actual TYPE_INT;
4. check operation coherence AGAIN;
5. only then inspect owner assignment / targetability verdict;
6. only then continue or reserve.

Direct tests:

### true verdict + candidate drift in owner query
- targetability returns true;
- post-targetability owner-query callback rebinds candidate index to board B;
- owner query returns normal int -1;
- selector returns -1;
- reserve call count = 0;
- no reservation.

### true verdict + ReservationState drift in owner query
Same expectations, with original ReservationState rebind.

### false or non-bool verdict + owner-query drift
At least one direct case must prove the selector stops immediately after detecting owner-query drift and does not query a later candidate.

Preserve same-owner side-effect law from V02.

This closes F-M15-STRICT-005.I.

## 3. Bracket post-reserve ownership proof one callback at a time

After `reserve()` returns actual true:

1. verify operation coherence;
2. call `get_owner(idx)`;
3. validate TYPE_INT immediately;
4. if malformed: exact-pair rollback and return -1, with NO target-proof query;
5. if typed: check operation coherence;
6. call `get_target_for_owner(owner_id)`;
7. validate TYPE_INT immediately;
8. if malformed: exact-pair rollback and return -1;
9. if typed: check operation coherence;
10. compare exact owner/target identity;
11. only then return idx.

Any drift/proof failure after reserve must exact-pair rollback the current selector-created reservation.

Direct tests:

### get_owner callback drifts candidate
- reserve stores exact pair;
- get_owner returns correct owner but callback rebinds candidate to B;
- selector returns -1;
- exact pair removed;
- target-proof call count = 0 after drift detection;
- unrelated reservation preserved.

### get_owner callback drifts ReservationState
Same fail-closed/no-success expectation. If rebind clears the pair itself, selector still returns -1 and creates no replacement/orphan.

### target-proof callback drifts candidate
- get_owner is correct;
- target-proof returns correct target but callback drifts candidate;
- selector returns -1;
- exact pair removed;
- unrelated reservation preserved.

### target-proof callback drifts ReservationState
Same fail-closed/no-success expectation.

### malformed get_owner ordering
- exact pair stored;
- get_owner returns malformed;
- selector returns -1;
- exact pair removed;
- prove `get_target_for_owner` proof callback was NOT invoked after the known malformed owner result.

Preserve the V02 malformed `get_target_for_owner` rollback case.

This closes F-M15-STRICT-005.J and preserves F-M15-STRICT-004 cleanup behavior.

## 4. Preserve all accepted V01/V02 hardening

Do not regress:
- real BoardState requirement;
- RefCounted candidate/reservation/access categories;
- actual-bool bind coherence;
- scalar/Node access rejection;
- actual-bool targetability only;
- dynamic return-type validation;
- non-int candidate entry guard;
- guard before first selection coherence callback;
- recursive selection rejection during selection;
- nested bind rejection during selection;
- bind-in-progress nested bind rejection;
- is_reserved true/false coherence check;
- mutation-before-malformed-reserve exact rollback;
- get_owner-independent exact-pair rollback;
- same-owner side effect no-later-query;
- post-reserve exact ownership proof;
- contention law;
- deterministic ascending candidate choice;
- ACTIVE + matching color + reachable filtering;
- no routing/path generation;
- no BoardState/candidate mutation;
- no full-board scan;
- exact `is_bound_to(board,reservation_state)` seam;
- rectangular + 59x59 regressions.

## 5. Direct observability rules

Do not satisfy a test by arranging an unrelated earlier failure.

For each V03 drift test:
- prove the preceding phase was genuinely valid;
- use call counters to prove the forbidden downstream phase did not execute;
- observe reservation ownership/count after return;
- preserve at least one unrelated reservation where rollback isolation is material.

For post-reserve proof ordering, a test must fail if the coherence check after the proof callback is removed.

## 6. Production scope

Allowed production:
- `scripts/gameplay/targeting/target_selector.gd` only.

Allowed test/support:
- `tests/run_tests.gd`;
- narrow M15 test doubles only.

Do NOT modify production:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- routing;
- ScrubbotAgent;
- M19 dispatcher.

If an upstream production change outside TargetSelector is genuinely required, stop `BLOCKED` instead of widening scope.

## 7. Governance

Claude MUST NOT edit:
- root `tasks.md` completion checkboxes;
- `coordination/AUDIT_INDEX.md`;
- any `CHATGPT_*` artifact;
- legacy H!veAI trackers;
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`.

Claude MAY update only canonical lifecycle files:
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

## 8. Validation

Run and record individually:
- `godot --version`;
- full root headless suite;
- zero SCRIPT/Parse errors;
- `git diff --check`;
- exact changed files;
- V03 focused adversarial outcomes;
- relevant V01/V02 regression outcomes;
- start/final H!veAI events/commits;
- any failed attempts.

Write:
`coordination/sessions/M15-C002/CLAUDE_LOG_V03.md`

## Final successful handoff

Set:
- currentTaskId = `M15-C002-V03`;
- workflowState = `AWAITING_AUDIT`;
- requiredActor = `CHATGPT`;
- blockers = [];
- progress stays `278/719 = 38.66%`;
- lastCompletedTaskId stays `FOUNDATION-C001-V01`;
- nextAction = independent ChatGPT V03 audit, then M19 V04 only if M15 passes.

Append matching `IN_PROGRESS -> AWAITING_AUDIT` event and push all intended implementation/log/tracker changes to `origin/main`.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.
Do NOT self-audit.

Success: `AWAITING_AUDIT`
Tracking failure: `GITHUB_TRACKING_NOT_SYNCED`
Genuine blocker: `BLOCKED`

Then STOP.
