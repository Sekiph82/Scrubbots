# M15-C002 — TargetSelector Upstream Strict Repair V01

Status: **ISSUED — FROZEN FINDING SET / M19 BLOCKER GATE**

H!veAI contract: **GitHub-first v3**.

Fix ONLY:
- F-M15-STRICT-004
- F-M15-STRICT-005

Do not implement M19 dispatcher behavior here.

## Read first

- `.hiveai/RULES.md`
- `.hiveai/TASKS.md`
- `.hiveai/PROJECT.json`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `coordination/sessions/M15-C002/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`
- historical M15-C001 V02 prompt/log/audit
- `coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`
- this prompt + criteria

Expected log:
`coordination/sessions/M15-C002/CLAUDE_LOG_V01.md`

## H!veAI start transition

Safely sync `origin/main`, preserve owner work, then re-read canonical `.hiveai/TASKS.md`.

Expected:
- currentTaskId = `M15-C002-V01`
- workflowState = `CHANGES_REQUIRED`
- requiredActor = `CLAUDE`
- progress = `278 / 719 = 38.66%`

If canonical task/actor differs, return `HIVEAI_STATE_CONFLICT` and do not overwrite it.

Before production edits:
- transition to `IN_PROGRESS`;
- keep progress unchanged;
- update machine + all human current-state text in `.hiveai/TASKS.md` so there is no stale M19/V02/V03 “awaiting implementation” statement;
- append one truthful `hiveai-event/v1` WORKFLOW_CHANGED row;
- commit + push start transition to `origin/main`.

If tracker push fails: `GITHUB_TRACKING_NOT_SYNCED`.

## 1. Harden bind dependency categories and return contracts

TargetSelector canonical dependency contract:

### board
- MUST be real `BoardState`;
- null/scalar/String/Vector2/Array/Dictionary/RefCounted-junk/Node-junk rejected before escaped calls.

### candidate_index
- MUST be `RefCounted`;
- required API: `get_candidates`, `is_bound_to`;
- method-compatible Node rejected.

### reservation_state
- MUST be `RefCounted`;
- required API:
  - `reserve`
  - `release`
  - `get_target_for_owner`
  - `get_owner`
  - `get_reserved_indices`
  - `is_reserved`
  - `is_bound_to`
- method-compatible Node rejected.

Before committing a successful bind:
- `candidate_index.is_bound_to(board)` must return actual TYPE_BOOL true;
- `reservation_state.is_bound_to(board)` must return actual TYPE_BOOL true.

Non-bool true-ish values do NOT pass.

Preserve current documented failed-bind neutralization semantics when bind is not occurring during an active selection.

## 2. Guard bind against active-selection re-entry

Add explicit selection-operation lifecycle protection.

While `select_and_reserve()` is executing:
- any `bind()` call returns false;
- it MUST NOT clear or replace the active operation's original binding;
- nested/reentrant bind from access/candidate/reservation callbacks cannot move the selector to another bundle.

Outside an active selection, ordinary explicit bind/rebind semantics remain as currently documented.

Use a selection generation/version or equivalent immutable operation token.

## 3. Harden per-call access_query boundary

`access_query` must be:
- `RefCounted`;
- expose `is_targetable`.

Reject safely with `-1`:
- null;
- int;
- float;
- String;
- bool;
- Vector2;
- Array;
- Dictionary;
- plain RefCounted missing method;
- method-compatible Node.

Do not call `has_method()` on unsupported scalar Variants.

For each candidate:
- call `is_targetable(idx)`;
- accept targetability ONLY when return value is TYPE_BOOL true;
- TYPE_BOOL false skips candidate;
- null/int/float/String/Vector2/Object/Array/Dictionary verdicts fail closed for that candidate and must never be treated as truthy approval.

## 4. Validate every dynamic collaborator return before typed use

Do NOT bind an arbitrary Variant directly into typed local variables before validation.

Required:

### reservation owner query
`get_target_for_owner(owner_id)`:
- TYPE_INT only;
- malformed return -> selection returns -1, no new reservation.

### reserved snapshot
`get_reserved_indices()`:
- MUST be PackedInt32Array;
- malformed return -> -1/no mutation/no fault.

### candidate query
`get_candidates(color_id, excluded)`:
- MUST be Array;
- malformed return -> -1/no mutation/no fault.

Each candidate entry:
- MUST be TYPE_INT before BoardState methods are called;
- unsupported entry types are skipped/fail-closed without runtime fault.

### is_reserved
- MUST return TYPE_BOOL;
- malformed return aborts selection fail-closed.

### reserve
- MUST return TYPE_BOOL;
- only actual true may count as a successful reservation;
- malformed return must not be treated as success.

### get_owner
- TYPE_INT when used for post-reserve ownership proof.

## 5. Make one select operation snapshot-stable

At select entry capture the exact original operation bundle:
- selector binding generation/version;
- board identity;
- candidate-index identity;
- reservation-state identity.

After EVERY external collaborator call that can precede a reserve or success return, verify:
- selector binding/version unchanged;
- original candidate index still exact-bound to original board;
- original reservation state still exact-bound to original board.

At minimum check after:
- initial candidate/reservation coherence probes;
- `get_target_for_owner`;
- `get_reserved_indices`;
- `get_candidates`;
- `is_reserved`;
- `is_targetable`;
- `reserve`;
- post-reserve ownership queries.

If drift is detected before reserve:
- return -1;
- make no reservation.

If drift occurs during/after reserve:
- verify whether THIS operation owns the selected target;
- release only that exact owner/target entry if it exists;
- return -1;
- do not erase unrelated contention reservations.

## 6. Direct drift adversaries

Use real BoardState + real ColorCandidateIndex/ReservationState where possible.

Directly inject from `access_query.is_targetable()`:

### selector bind re-entry
- callback attempts `selector.bind(boardB, candidateB, reservationB)`;
- nested bind returns false;
- selector stays on A;
- selection either continues safely on A or returns -1 according to deterministic contract;
- no reservation exists in B.

### ReservationState rebind
- callback calls original reservation object's `rebind(boardB)`;
- selection detects lost A coherence before reserve;
- no target is returned;
- no new reservation is created in B by the selector.

### CandidateIndex rebind
- callback rebinds candidate index to boardB;
- selection detects drift before reserve;
- returns -1;
- no reservation.

Also inject drift from `get_candidates()` and/or reservation query doubles if needed to prove snapshot checks are not access-query-only.

## 7. Post-reserve ownership proof

A successful return from TargetSelector means exact atomic ownership is true.

Before returning selected `idx`, prove:
- `get_target_for_owner(owner_id) == idx`;
- `get_owner(idx) == owner_id`;
- both return values are actual ints.

Direct doubles:
- `reserve()` returns true but stores nothing;
- `reserve()` returns true but reports another target;
- `reserve()` returns true but target owner differs;
- non-bool truthy reserve return.

All must return -1 and not leak a selector-created ownership entry.

## 8. Preserve contention semantics

Existing accepted behavior MUST remain:

- same-owner callback side effect that independently reserves another target:
  - selector returns -1;
  - preserves the external side-effect reservation;
  - queries no later candidates after owner is known assigned.

- different-owner contention on first target:
  - requester may continue to next candidate;
  - never double-reserves one target;
  - deterministic order preserved.

## 9. Preserve M15 architecture

No:
- route generation;
- routing-system calls;
- BoardState mutation;
- candidate-index mutation;
- full-board scan;
- M19 agent/dispatcher behavior.

Preserve:
- ACTIVE/color final checks;
- blocked/unreachable filtering;
- `is_bound_to(board, reservation_state)` exact identity seam used by M19;
- 59x59 / rectangular regressions.

## 10. Validation-first promotion evidence

Before production fix, add focused adversarial tests for at least:
- scalar `access_query`;
- non-bool `is_targetable` true-ish return;
- selector bind re-entry from targetability callback;
- ReservationState rebind during targetability callback.

Run them against CURRENT pre-fix TargetSelector and record exact outcomes in `CLAUDE_LOG_V01.md`.

If any case faults, accepts non-bool reachability, or reserves across a drifted bundle, record:
`M15-C002 DEFECT CONFIRMED`.

Then apply the frozen minimal correction.

Do not skip pre-fix sensitivity evidence.

## Governance

Claude MUST NOT modify:
- root `tasks.md` completion checkboxes;
- `coordination/AUDIT_INDEX.md`;
- any `CHATGPT_*` artifact;
- legacy H!veAI tracker files;
- BoardState;
- ColorCandidateIndex production;
- ReservationState production;
- M19 dispatcher production.

Allowed production:
- `scripts/gameplay/targeting/target_selector.gd` only.

Allowed test/support:
- `tests/run_tests.gd`;
- narrowly-scoped M15 test doubles.

## Final H!veAI handoff

After implementation + full validation:
- `.hiveai/TASKS.md` -> `AWAITING_AUDIT`;
- `requiredActor = CHATGPT`;
- currentTaskId stays `M15-C002-V01`;
- blockers = [];
- progress stays `278/719 = 38.66%` until independent audit decides task reopen/re-close;
- lastCompletedTaskId remains `FOUNDATION-C001-V01`;
- append IN_PROGRESS -> AWAITING_AUDIT event;
- commit + push production/tests/log/tracker/events to origin/main.

Write:
`coordination/sessions/M15-C002/CLAUDE_LOG_V01.md`

Record:
- synced starting SHA;
- pre-fix sensitivity evidence;
- exact changed files;
- focused adversarial results;
- full root suite result;
- Godot version;
- `git diff --check`;
- H!veAI start/final commits/events;
- no self-audit verdict.

Success return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Genuine scope blocker:
`BLOCKED`

Then STOP.
