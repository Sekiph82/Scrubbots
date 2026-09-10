# M20-C001 — Complete Clearing Vertical Slice V01

Status: **ISSUED — CONTRACT FROZEN / IMPLEMENTATION REQUIRED**

Canonical live tracker: repository-root `TASKS.md` only.

This prompt implements the full M20 strict-v2 contract frozen in:

`coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`

Expected evidence log:

`coordination/sessions/M20-C001/CLAUDE_LOG_V01.md`

## 0. Tracking / start-order law

Read first:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M19-C001/CHATGPT_AUDIT_V06.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`;
- this prompt;
- matching V01 audit criteria.

Root `TASKS.md` is the ONLY live project-status tracker. Do not create/revive `.hiveai/*`, dashboards, cycle maps, session indexes or other competing current-state trackers.

This ChatGPT prompt authorizes the handoff from the current M20-C001-PREP state to M20-C001-V01 implementation.

Before ANY M20 production/test edit:
1. safely sync `origin/main` while preserving owner work;
2. verify root `TASKS.md` still points to M20 prep and has not moved to another actor/task;
3. update only the top Project Status block to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V01 — Complete Clearing Vertical Slice
   - Current Task: M20-C001-V01 — implement frozen complete-clearing orchestration contract
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: implement this prompt, run the full validation matrix, write CLAUDE_LOG_V01.md, then hand off AWAITING_AUDIT to ChatGPT
   - Progress remains 290 / 719 = 40.33% main+ui; overall 290 / 943 = 30.75%; lastCompletedTaskId M19-C001-V06
4. commit + push that tracker start transition before any local M20 production/test edit;
5. verify remote main contains the IN_PROGRESS transition.

If the tracker has moved to another task/actor, stop with `TRACKER_STATE_CONFLICT`.
If the start transition cannot be pushed, stop with `GITHUB_TRACKING_NOT_SYNCED`.

Do NOT mark any SB-M20 row complete. Audit closure belongs to ChatGPT.

## 1. Implement a separate M20 clearing-loop orchestrator

Create:

`scripts/gameplay/clearing/complete_clearing_loop.gd`

Prefer `extends RefCounted` unless a concrete Node lifecycle is actually required by the implementation. Do not create a God-manager.

This class owns ONLY:
- one slot activation event -> one M19 dispatch request;
- authenticated arrival -> synchronized cross-module clear transaction;
- reset of in-flight dispatch state without undoing already-cleared artwork.

It does NOT own:
- target-selection algorithm;
- routing algorithm;
- reservation storage;
- BoardState storage;
- candidate buckets;
- Scrubbot movement;
- win/lose/scoring;
- session completion;
- slot cooldown/queue/consumption policy.

Use explicit `preload()` for core scripts per AL-001.

## 2. Clearing-loop bind contract

Recommended API:

`bind(board, slot_system, candidate_index, reservation_state, dispatcher, renderer = null) -> bool`

Ordinary bind is initialization-only.

Require:
- real BoardState;
- real SlotSystem;
- configured SlotSystem;
- slot count exactly 5;
- real ColorCandidateIndex exact-bound to board;
- real ReservationState exact-bound to board;
- real ScrubbotDispatcher exact-bound to the same board + ReservationState;
- dispatcher active count == 0 at initial M20 bind;
- optional renderer is a live real BoardRenderer exact-bound to the same board.

Use concrete production categories, not broad method-name-only duck typing for canonical M20 dependencies.

If BoardRenderer lacks a safe exact-board identity query, add the smallest read-only method required, e.g.:

`func is_bound_to(board) -> bool`

Do not alter renderer behavior.

The loop must expose at least:
- `is_bound() -> bool`;
- an exact read-only coherence query if useful for tests.

Second bind:
- false;
- original bundle preserved;
- no destructive rebind.

Construct a fresh loop for a new board/session bundle.

## 3. Add the narrow M19 arrival bridge

M19 production is final-closed. Modify it minimally.

Add an outward signal such as:

`signal assignment_arrived(owner_id: int, target_index: int, color_id: int, agent)`

Emit it ONLY after the existing M19 `_on_agent_completed` identity checks succeed.

Required:
- correct owner;
- correct target;
- correct color;
- exact source agent;
- known active assignment;
- emit once only.

A repeated completion for an already-arrived assignment must not emit the M20 arrival signal twice.

Add the smallest read-only exact queries M20 needs, recommended:
- `is_bound_to(board, reservation_state) -> bool`;
- `is_arrival_pending(owner_id, target_index, color_id, agent) -> bool`.

Add narrow finalization:

`finalize_arrival(owner_id, target_index, color_id, agent) -> bool`

It MUST:
- act only on the exact authenticated arrived assignment;
- remove the dispatcher `_active` entry exactly once;
- leave BoardState mutation to M20;
- leave ReservationState resolution to M20;
- schedule the Scrubbot for safe destruction without a return path;
- be safe while called from a completion-signal stack.

Do not synchronously `free()` the currently emitting agent if that can produce a locked-object error. Prefer safe queue/deferred free.

Wrong/stale/mismatched finalization returns false and changes nothing.

Preserve all M19 V01-V06 tests.

## 4. Slot activation API

Recommended API:

`activate_slot(slot_id, start_position: Vector2, speed: float = 6.0) -> RefCounted`

Return the existing DispatchResult type.

The METHOD CALL itself represents the user activation event. Do NOT silently redefine `SlotState.active` as a dispatch transaction flag.

Before dispatcher call require:
- loop bound and coherent;
- actual integer slot id;
- slot id in 0..4;
- SlotSystem still configured;
- slot is available;
- slot palette id is nonnegative;
- finite start position;
- finite positive speed.

Delegate the actual no-work/reachability decision to the M19 dispatcher + TargetSelector + ProductionTargetAccess path. Do not perform a second target-selection or routing algorithm in M20.

All slot fields must be unchanged by activate success/failure unless an already-locked M12 rule requires otherwise.

No target / blocked target:
- zero new agent;
- zero reservation;
- no BoardState mutation;
- no slot mutation.

One activation creates at most one Scrubbot.

## 5. Arrival preflight

The clearing loop listens only to the M19 authenticated arrival signal.

Before mutating any gameplay truth re-check:
- clearing loop still bound/coherent;
- dispatcher still exact-bound to board + same ReservationState;
- dispatcher reports exact pending arrived owner/target/color/agent;
- target is a valid BoardState index;
- BoardState target state is exactly ACTIVE;
- BoardState target color equals the assignment color;
- ReservationState owner -> target exact;
- ReservationState target -> owner exact;
- ColorCandidateIndex is still exact-bound to board;
- optional renderer is still live and exact-bound to board.

If any preflight fails:
- do not clear;
- do not release reservation;
- do not remove dispatcher assignment;
- do not alter unrelated state.

Do not accept direct agent signals as clearing authority.

## 6. Authoritative clear transaction

On one authenticated healthy arrival execute exactly:

1. `BoardState.set_cell_state(target, CLEARED)`;
2. `ColorCandidateIndex.sync_cell(target)`;
3. `ReservationState.resolve_arrival(target, owner)`;
4. if renderer bound: `BoardRenderer.update_cells([target])`;
5. `ScrubbotDispatcher.finalize_arrival(owner, target, color, agent)`.

ProductionAccessQuery receives NO explicit mutation/update. It reads BoardState live.

### Step 1 failure
Nothing after it may run.

### Candidate sync failure
Rollback to the exact pre-arrival state:
- BoardState target -> ACTIVE;
- restore/rebuild candidate truth so the target is again a canonical ACTIVE candidate;
- reservation remains held;
- dispatcher arrived assignment remains held;
- no agent finalization.

### Reservation resolve failure
Rollback:
- BoardState target -> ACTIVE;
- candidate truth restored/resynced;
- reservation remains whatever it was before the failed resolve;
- dispatcher assignment remains;
- no agent finalization.

Use explicit postconditions. Never pretend success after half-clear.

Renderer is presentation-only. `renderer == null` is a valid headless M20 configuration. With a bound renderer, successful clear must update exactly that target and render alpha 0.

Dispatcher finalization must be after gameplay-state commit. Because it is preflighted and no arbitrary external callback should intervene in the concrete transaction, a healthy production finalization must deterministically succeed. If it does not, fail visibly in tests/log and do not hide it.

## 7. Exactly-once / spoof / stale arrival

Directly test:
- wrong owner;
- wrong target;
- wrong color;
- wrong source agent;
- unknown owner;
- duplicate correct completion;
- stale completion after reset;
- target externally already CLEARED before arrival;
- reservation removed before arrival;
- reservation wrong owner;
- candidate index rebound/unbound before arrival;
- renderer wrong-board/unbound/freed where safely reproducible.

None may clear unrelated cells or release unrelated ownership.

One assignment can clear exactly one cell exactly once.

## 8. Clear opens future reachability

Build one real production integration where:
- target B is initially unreachable because ACTIVE cell A blocks the legal path;
- slot activation clears reachable A;
- BoardState A becomes CLEARED;
- candidate A disappears;
- ProductionAccessQuery now sees A as open;
- a later activation can select/route to B without any explicit access-cache refresh.

Use real:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- ProductionAccessQuery;
- ProductionTargetAccess;
- ProductionRoutingSystem;
- ScrubbotDispatcher;
- CompleteClearingLoop.

This is a mandatory semantic regression for AL-028.

## 9. Reset / lifecycle

Add a clearing-loop reset API with narrow semantics:
- cancel/reset all currently in-flight M19 dispatcher assignments;
- release their reservations through existing dispatcher reset behavior;
- preserve all BoardState cell states;
- preserve candidate truth for cells whose BoardState did not change;
- do not resurrect already CLEARED cells;
- do not rewind owner ids;
- stale completion after reset cannot clear anything.

Reset must be re-entry-safe.

If reset is injected during an arrival transaction in a controllable test seam, the outcome must be either:
- reset before mutation, zero clear; or
- complete documented rollback to the pre-arrival tuple.

Never leave:
- CLEARED + still candidate;
- CLEARED + still reserved;
- ACTIVE + candidate removed;
- dispatcher active entry after successful finalized arrival;
- orphan Scrubbot node.

## 10. Required synchronized post-arrival tuple

After every successful arrival assert all of the following directly:

- `BoardState.get_cell_state(target) == CLEARED`;
- target absent from raw candidate bucket for its color;
- ProductionAccessQuery treats that cell as OPEN for later traversal;
- `ReservationState.get_owner(target) == -1`;
- `ReservationState.get_target_for_owner(owner) == -1`;
- `ScrubbotDispatcher.has_owner(owner) == false`;
- agent is queued/freed and never returns;
- unrelated cells/candidates/reservations/agents unchanged;
- renderer pixel alpha == 0 if renderer bound.

Use RGBA8-tolerant color assertions per AL-002.

## 11. Required M20 scenario matrix

Add a dedicated M20 test section to `tests/run_tests.gd` plus narrow support doubles only where required.

Directly cover:
- one-cell synthetic board;
- one-color repeated clearing until exhausted;
- multi-color board;
- five configured slots;
- five distinct simultaneous/in-flight assignments where targets permit it;
- no target;
- fully enclosed matching candidate no-spawn;
- newly-opened-after-clear target;
- Easy production dimensions;
- Medium production dimensions;
- Hard production dimensions;
- Very Hard production dimensions;
- 59x59 maximum;
- rectangular production board;
- rapid 25+ sequential activate/arrival cycles where practical;
- reset with multiple in-flight agents;
- state-desynchronization adversaries from §§5-9.

Do not fake all of these with a single method-compatible toy stack. At least the scale/reachability/clearing spine must use real production dependencies.

## 12. Performance / architecture

A normal successful clear must not full-scan the whole board in M20 code.

Use:
- one BoardState cell mutation;
- ColorCandidateIndex single-cell sync;
- ReservationState O(1) owner resolution;
- BoardRenderer single-cell update when present.

Do not introduce one Node per cell.

Do not create a second access cache. ProductionAccessQuery already reads current BoardState.

## 13. M21+ boundary

Do NOT:
- load/generate owner real artwork;
- implement M21 real-art vertical slice;
- build production slot UI;
- add scoring/win/lose/session completion;
- implement level progression/save/economy;
- auto-dispatch the next bot;
- add slot queues/cooldowns/consumption rules;
- change the owner-locked palette or ACTIVE/CLEARED law.

## 14. Documentation

Update only durable architecture docs required to describe the new M20 orchestration seam.

Record that:
- M20 clearing-loop owns the cross-module arrival transaction;
- M19 dispatcher remains assignment/agent orchestration;
- access truth updates by reading BoardState live;
- no win/session-completion policy is introduced.

Do not rewrite historical audit evidence.

## 15. Validation and evidence

Run and record individually:
- `godot --version`;
- full root headless suite: `godot --headless --path . -s res://tests/run_tests.gd`;
- `git diff --check`;
- exact changed-file list;
- grep/source proof that no M21+/win/scoring/session-complete behavior was added;
- exact root TASKS lifecycle state before/after;
- any failed tests, runtime errors and fixes.

The final `CLAUDE_LOG_V01.md` must map the implementation/test evidence to the V01 criteria, not only report one green aggregate number.

## 16. Governance / final handoff

Claude MAY modify:
- `scripts/gameplay/clearing/*`;
- the minimal M19 dispatcher seams authorized above;
- minimal BoardRenderer read-only coherence seam if required;
- `tests/run_tests.gd`;
- narrow `tests/support/*`;
- durable architecture docs directly affected by M20;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V01.md`;
- root `TASKS.md` Project Status lifecycle fields as authorized here.

Claude MUST NOT modify:
- any `CHATGPT_*` artifact;
- `coordination/AUDIT_INDEX.md`;
- audit verdicts;
- SB-M20 checkbox completion truth;
- `.hiveai/*` or archived tracker snapshots;
- M21+ task rows;
- unrelated production systems.

On successful implementation/test completion, before reporting:
- update root `TASKS.md` Project Status to M20-C001-V01 / AWAITING_AUDIT / Required Actor CHATGPT;
- Next Task/Action points to independent ChatGPT audit of `CLAUDE_LOG_V01.md` + V01 criteria;
- progress remains 290/719 = 40.33% main+ui and 290/943 = 30.75% overall;
- lastCompletedTaskId remains M19-C001-V06;
- commit/push implementation + tests + log + tracker handoff;
- verify remote main contains the intended handoff.

Do NOT mark COMPLETE or READY_FOR_NEXT_TASK.

Successful return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Frozen-scope blocker:
`BLOCKED`

Then stop.
