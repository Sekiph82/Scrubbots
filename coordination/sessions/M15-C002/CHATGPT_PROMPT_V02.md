# M15-C002 — TargetSelector Strict Closure V02

Status: **ISSUED — SAME FROZEN FINDING SET / CORRECTION + ADVERSARIAL CLOSURE**

H!veAI contract: **GitHub-first v3**.

Fix ONLY the remaining parts of:
- F-M15-STRICT-004
- F-M15-STRICT-005

Do not implement M19 here. M19-C001 remains blocked until this cycle independently passes.

## Read first

- `.hiveai/RULES.md`
- `.hiveai/TASKS.md`
- `.hiveai/PROJECT.json`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `coordination/sessions/M15-C002/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`
- `coordination/sessions/M15-C002/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M15-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M15-C002/CHATGPT_AUDIT_V01.md`
- this prompt + `CHATGPT_AUDIT_CRITERIA_V02.md`

Expected log:
`coordination/sessions/M15-C002/CLAUDE_LOG_V02.md`

## H!veAI start

Safely sync `origin/main`, preserve owner work, then re-read canonical `.hiveai/TASKS.md`.

Expected:
- currentTaskId = `M15-C002-V02`
- workflowState = `CHANGES_REQUIRED`
- requiredActor = `CLAUDE`
- progress = `278/719 = 38.66%`

If authoritative state differs, fail closed as `HIVEAI_STATE_CONFLICT`.

Before production edits:
- transition tracker to `IN_PROGRESS`;
- requiredActor remains `CLAUDE`;
- progress unchanged;
- machine and ALL human current-state text agree;
- append truthful `hiveai-event/v1` WORKFLOW_CHANGED row;
- commit + push the start transition before substantial implementation.

If push fails: `GITHUB_TRACKING_NOT_SYNCED`.

## 1. Arm selection transaction BEFORE the first external callback

Current V01 guard starts too late.

Required `select_and_reserve()` lifecycle:
- if `_in_selection` is already true, immediately return `-1` with zero collaborator mutation;
- after pure local input/category checks, set the selection guard BEFORE the first `_op_coherent()` / candidate/reservation coherence callback;
- capture the exact board/candidate/reservation/generation snapshot before external work;
- every exit from the guarded operation must clear the guard deterministically;
- initial coherence failure must not leave the selector stuck busy.

Direct tests:
- candidate `is_bound_to()` callback attempts `selector.bind(boardB, ...)` during INITIAL operation coherence -> nested bind false;
- reservation `is_bound_to()` callback attempts same -> false;
- original A binding preserved;
- B receives no reservation;
- later clean select succeeds.

## 2. Block recursive selection itself

While one `select_and_reserve()` is active, a nested `select_and_reserve()` on the same selector must return `-1` immediately.

Inject recursion from at least:
- `access_query.is_targetable()`;
- candidate query callback;
- reservation query callback.

Test:
- same-owner nested call;
- different-owner nested call;
- nested call creates zero reservation;
- outer operation either succeeds normally on its original transaction or fails cleanly according to the injected scenario;
- later sequential non-reentrant call still works.

## 3. Add bind-in-progress protection

`bind()` itself is a stateful transaction and currently calls external coherence methods before commit.

Required:
- nested `bind()` while an outer bind is validating returns false;
- outer bind cannot be overwritten by a callback-triggered inner bind;
- candidate bind-time coherence callback re-entry tested;
- reservation bind-time coherence callback re-entry tested;
- outer successful bind commits only the requested original bundle;
- failed outer bind leaves the documented neutralized state;
- later clean bind remains possible.

Do not change the accepted ordinary failed-bind neutralization semantics outside re-entry.

## 4. Coherence check after EVERY collaborator boundary, including `is_reserved == true`

Current V01 code checks coherence after `is_reserved()` only on the false branch.

Required:

```text
rs.is_reserved(idx)
↓
validate TYPE_BOOL
↓
re-check operation coherence
↓
only then branch on true/false
```

If an `is_reserved()` callback drifts candidate/reservation state and returns true:
- return `-1` before any later candidate is inspected;
- no targetability query on later candidates;
- no new reservation.

Add injection hooks to the narrow candidate/reservation doubles so V01 criteria 80/81/82 become directly testable:
- owner query drift;
- reserved-snapshot drift;
- candidate-query drift;
- is_reserved drift.

Every such drift must stop before the next consequential phase.

## 5. Malformed `reserve()` return AFTER mutation must rollback exact requested pair

The V01 test used `do_store=false`, which does not sensitivity-test partial failure.

Direct V02 adversary:
- before call owner has no reservation and target is free;
- `reserve(idx, owner)` stores the exact `(idx, owner)` pair;
- method returns non-bool integer `1`;
- selector must return `-1`;
- exact `(idx, owner)` pair must be absent afterward;
- unrelated reservations remain untouched.

Production rule:
- after any reserve call that may have mutated state but whose return is malformed, attempt rollback of the exact requested pair through `release(idx, owner_id)`;
- do not rely on the malformed reserve return as proof no mutation happened.

## 6. Rollback must not depend on the ownership query that just failed

Current `_rollback_own()` calls `get_owner(idx)` first. If `get_owner()` is malformed, exact requested ownership can leak.

Required:
- after an actual-bool-true reserve, any post-reserve coherence/ownership-proof failure must attempt exact `release(idx, owner_id)` directly;
- canonical `ReservationState.release()` is exact-pair safe and will not erase another owner's reservation;
- do not delete a different target merely because the same owner appears elsewhere;
- do not delete another owner's target.

Direct tests:
1. exact pair stored + `get_owner()` returns malformed -> `-1`, exact pair gone;
2. exact pair stored + `get_target_for_owner()` returns malformed -> `-1`, exact pair gone;
3. target actually belongs to other owner -> preserved;
4. owner maps to another target only -> other target preserved;
5. drift-after-reserve exact pair -> exact pair rolled back.

If `release()` itself returns malformed, do not treat that return as proof of success. Verify the exact requested pair is no longer simultaneously observable where the available typed query contract permits. Do not use broad `release_for_owner` behavior that could erase unrelated ownership.

## 7. Re-check same-owner assignment immediately after targetability callback

Preserve historical contention law:
- once a callback independently assigns `owner_id`, selector stops and queries no later candidates;
- that external reservation is preserved.

V02 must cover the branch V01 missed:

### targetability callback side effect + bool false
- callback reserves another target for same owner;
- returns actual false;
- selector returns `-1` immediately;
- later candidate access query count remains zero;
- side-effect reservation preserved.

### same side effect + malformed/non-bool verdict
- same result: `-1`, no later candidate query, external reservation preserved.

Therefore after each targetability callback + operation-coherence check, validate `get_target_for_owner(owner_id)` as TYPE_INT before deciding to continue.

## 8. Preserve V01 hardening

Keep green and do not weaken:
- real BoardState bind category;
- RefCounted candidate/reservation dependency categories;
- method-compatible Node rejection;
- actual-bool `is_bound_to` gates;
- scalar/non-object access_query fail-closed;
- actual-bool targetability;
- dynamic return validation;
- non-int candidate-entry guard;
- immutable operation snapshot;
- post-reserve exact ownership proof;
- candidate/reservation rebind detection from targetability callbacks;
- same-owner side-effect preservation;
- different-owner contention continuation;
- deterministic ascending selection;
- ACTIVE/color/reachability checks;
- no route generation;
- no BoardState/candidate truth mutation;
- no full-board scan;
- exact `is_bound_to(board,reservation_state)` seam;
- rectangular + 59x59 regressions.

## 9. V02 pre-fix sensitivity

Before modifying V01 production source, add/run focused probes against commit `5a2ed2765a1d2d77578223f88e2b456d2709d985` for at least:
- initial candidate-coherence callback nested bind;
- initial reservation-coherence callback nested bind;
- recursive `select_and_reserve()` from targetability callback;
- `is_reserved == true` plus dependency drift;
- `reserve()` stores exact pair then returns int `1`;
- successful reserve stores exact pair then malformed `get_owner()` causes proof failure;
- same-owner side effect + targetability false continues/no-continues observation.

Record exact pre-fix outcomes in `CLAUDE_LOG_V02.md` before applying correction.

These are sensitivity checks. Do not construct them so an unrelated earlier failure makes them green.

## 10. Full attack-surface regression

Run the entire root suite and preserve M13/M14/M15-C001/M16/M17/M18/M19 V02/V03 regressions.

No M19 dispatcher production change in this cycle.

## Production scope

Allowed production change:
- `scripts/gameplay/targeting/target_selector.gd` only.

Allowed test/support:
- `tests/run_tests.gd`;
- narrow M15 doubles/hooks.

Do NOT modify production:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- M19 dispatcher;
- routing;
- ScrubbotAgent.

## Governance

Claude MUST NOT change:
- root `tasks.md` audit/completion checkboxes;
- `coordination/AUDIT_INDEX.md`;
- any `CHATGPT_*` artifact;
- legacy H!veAI tracker files;
- `.hiveai/PROJECT.json`;
- `.hiveai/RULES.md`.

Claude MUST update lifecycle state in:
- `.hiveai/TASKS.md`;
- `.hiveai/EVENTS.jsonl`.

## Validation / log

Run and separately record:
- `godot --version`;
- focused V02 sensitivity results;
- full root `godot --headless --path . -s res://tests/run_tests.gd`;
- zero SCRIPT/Parse errors;
- `git diff --check`.

Write:
`coordination/sessions/M15-C002/CLAUDE_LOG_V02.md`

Record exact changed files, failures/fixes, start/final tracker events and pushed commits.

## Final successful H!veAI handoff

Before reporting success:
- workflowState = `AWAITING_AUDIT`;
- requiredActor = `CHATGPT`;
- currentTaskId = `M15-C002-V02`;
- blockers = [];
- progress remains `278/719 = 38.66%`;
- lastCompletedTaskId remains `FOUNDATION-C001-V01`;
- nextAction points to independent V02 audit;
- append `IN_PROGRESS -> AWAITING_AUDIT` event;
- push production/tests/log/tracker/events to `origin/main`.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

Successful return exactly:
`AWAITING_AUDIT`

Tracking failure:
`GITHUB_TRACKING_NOT_SYNCED`

Genuine blocker:
`BLOCKED`

Then STOP.
