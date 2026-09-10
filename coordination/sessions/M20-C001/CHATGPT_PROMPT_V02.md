# M20-C001 — Strict-v2 Transaction Correction V02

Status: **ISSUED — SAME FROZEN F-M20-STRICT-001..007 SET**

Canonical live tracker: repository-root `TASKS.md` only.

Read FIRST:
- root `TASKS.md`;
- `AGENTS.md`;
- `CLAUDE.md`;
- `coordination/AUDIT_POLICY.md`;
- `coordination/AUDIT_INDEX.md`;
- `coordination/VERSIONED_LOG_POLICY.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V01.md`;
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`;
- this prompt;
- `CHATGPT_AUDIT_CRITERIA_V02.md`.

Expected evidence log:
`coordination/sessions/M20-C001/CLAUDE_LOG_V02.md`

Do not begin M21.

## 0. Root TASKS start transition

Current canonical state before this correction is expected to still be:
- M20-C001 V01;
- AWAITING_AUDIT;
- Required Actor CHATGPT;
- progress 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06.

`CHATGPT_AUDIT_V01.md` + this V02 prompt are the independent authorization for the V02 correction.

Before ANY V02 production/test edit:
1. safely sync `origin/main`, preserving owner work;
2. verify the V01 audit and V02 prompt/criteria exist on synced main;
3. verify root `TASKS.md` has not moved to another milestone/task;
4. update ONLY the top Project Status lifecycle fields to:
   - Current Milestone: M20
   - Current Sprint: M20-C001 V02 — strict-v2 transaction correction
   - Current Task: M20-C001-V02 — close frozen M20 transaction/re-entry/rollback gaps
   - Current Task Status: IN_PROGRESS
   - Required Actor: CLAUDE
   - Next Task/Action: implement V02, run required validation, write CLAUDE_LOG_V02.md, then hand off AWAITING_AUDIT to ChatGPT
   - progress unchanged 290/719 main+ui, 290/943 overall
   - lastCompletedTaskId unchanged M19-C001-V06
5. commit + push this tracker-only transition BEFORE any local V02 production/test edit;
6. verify remote main contains it.

Do not create/revive `.hiveai/*` or any competing live tracker.
Do not mark any SB-M20 row `[x]`.

If state moved: `TRACKER_STATE_CONFLICT`.
If start transition cannot push: `GITHUB_TRACKING_NOT_SYNCED`.

## 1. Preserve accepted V01 architecture

Keep:
- separate `CompleteClearingLoop`;
- M19 assignment/agent ownership;
- BoardState physical truth;
- ColorCandidateIndex derived truth;
- ReservationState ephemeral ownership;
- M15 target-selection separation;
- M17 production routing/access law;
- M18 movement-only agent;
- authenticated M19 arrival bridge;
- no second access cache;
- no win/lose/scoring/session-complete/auto-next behavior.

Do not redesign working upstream systems.

## 2. Make bind a real transaction

Add a bind-in-progress guard armed BEFORE the first collaborator callback.

Required:
- nested bind from candidate `is_bound_to()` callback -> false;
- nested bind from reservation `is_bound_to()` callback -> false;
- outer bind either commits one coherent bundle once or fails fully unbound;
- no inner/ghost `assignment_arrived` connection survives a failed/nested bind;
- no callback is connected until validation is complete;
- callback-induced same-size foreign-board drift is detected before commit;
- second ordinary bind after successful bind remains false and preserves original bundle.

Prefer exact production script/category identity for BoardState, SlotSystem, ScrubbotDispatcher and BoardRenderer because M20 has no production reason to accept arbitrary subclasses there. If you keep subclass acceptance for any of those, the V02 adversarial callback matrix applies to them too.

ColorCandidateIndex / ReservationState subclasses may remain accepted only if needed for controlled rollback testing. If accepted, their callback boundaries MUST be transaction-safe.

## 3. Serialize activation

Add an activation guard and reset-generation/reset-request handling.

`activate_slot()` must fail closed before dispatcher dispatch when:
- another activation is already running;
- an arrival transaction is currently committing;
- loop reset is active/requested;
- live coherence changes during preflight.

Direct adversaries:
- recursive `activate_slot()` injected from candidate/reservation coherence callback;
- `reset()` injected from activation coherence callback.

Required direct observations:
- nested activation creates zero additional reservation/agent;
- outer activation aborted by reset does not dispatch afterward;
- no owner-id advance from rejected nested/reset-aborted activation;
- slots unchanged;
- later ordinary activation recovers.

Use an existing DispatchResult failure reason consistently (`REENTRANT`, `RESETTING` or `INVALID_REQUEST` as appropriate). Do not invent UI policy.

## 4. Serialize authenticated arrivals losslessly

Add one serial arrival processor.

A second **distinct** authenticated dispatcher arrival that occurs synchronously while the first arrival transaction is active MUST NOT be silently dropped, because M19 emits the bridge once.

Use a private queue/deferred drain or equivalent lossless serial mechanism.

Requirements:
- at most one cross-module arrival transaction mutates truth at a time;
- nested distinct arrival is queued and processed after the current transaction;
- duplicate same assignment is not queued/resolved twice;
- queued tuple is immutable owner/target/color/exact-agent identity;
- activation is rejected while arrival commit is active;
- queue is cleared when reset makes queued arrivals stale;
- no public query leaks the mutable queue.

## 5. Reset during activation/arrival must be transactional

Introduce a loop generation/reset-request mechanism.

Do NOT call `dispatcher.reset()` in the middle of a partially-mutated arrival tuple.

When reset is requested during activation/arrival:
- mark reset/generation immediately;
- stop any new downstream phase;
- if arrival has not mutated BoardState yet, abort before clear;
- if arrival mutation already began, restore/prove a coherent rollback state first;
- only then apply dispatcher reset;
- clear queued stale arrivals;
- final reset truth: BoardState/candidate state preserved, in-flight reservation/dispatcher ownership removed, no orphan agent;
- owner id monotonicity preserved;
- later activation works.

Direct injection required at least:
- reset inside candidate sync callback;
- reset inside reservation resolve callback;
- reset inside activation live-coherence callback.

If finalization/presentation remains an overridable callback seam, inject reset there too.

## 6. Correct V02 transaction order

V02 supersedes V01's renderer-before-finalize detail.

Renderer is presentation only. It MUST NOT sit between gameplay ownership resolution and dispatcher finalization.

Correct order:
1. authenticated preflight + exact pre-state snapshot;
2. BoardState target ACTIVE -> CLEARED;
3. ColorCandidateIndex single-cell sync + postcondition;
4. ReservationState exact arrival resolve + postcondition;
5. ScrubbotDispatcher exact finalization + postcondition;
6. optional BoardRenderer single-cell repaint from already-committed BoardState.

Normal path remains single-cell/O(1)-style. No normal-path full-board scan.

## 7. Capture pre-state needed for exact rollback

Before step 2 capture enough detached truth to prove exact rollback without leaking/aliasing mutable internals.

At minimum capture:
- target index/color/state;
- target's raw candidate membership WITHOUT applying reservation exclusion;
- reservation count and detached reserved-index set;
- exact owner->target and target->owner pair;
- dispatcher active count and exact arrival-pending truth;
- renderer target pixel when renderer is bound, for presentation rollback assertions.

Do not full-scan BoardState.

## 8. Verify postconditions after every success return

A return value alone is not proof.

### BoardState
After `set_cell_state(...CLEARED)` returns true, require:
- target state == CLEARED;
- immutable color id unchanged.

### Candidate index
After `sync_cell(target)` returns true, require:
- still exact-bound to original board;
- raw candidate query for target color, with NO reservation exclusion, no longer contains target.

### Reservation
After `resolve_arrival(target, owner)` returns true, require:
- `get_owner(target) == -1`;
- `get_target_for_owner(owner) == -1`;
- reservation count/set equals pre-state minus exactly this target;
- unrelated reservations unchanged.

### Dispatcher
After `finalize_arrival(...)` returns true, require:
- exact owner absent;
- active count is pre-state minus exactly one;
- unrelated active assignments remain valid in tests.

### Renderer
After gameplay commit/finalization, if healthy renderer bound:
- update exactly `[target]`;
- pixel alpha == 0 within RGBA8 tolerance;
- unrelated pixel unchanged.

Renderer postcondition failure is presentation failure, NOT permission to roll authoritative gameplay truth backward after dispatcher finalization.

## 9. Replace friendly rollback tests with mutation-sensitive ones

Keep ordinary false-without-mutation tests, AND add these classes.

### Candidate mutation-before-false
A real accepted candidate subclass/test seam must:
1. perform the actual CLEARED sync/removal for target;
2. return false.

M20 must restore:
- BoardState ACTIVE;
- raw target candidate membership present again;
- exact reservation held;
- dispatcher arrived assignment held;
- no renderer false-clear;
- unrelated candidate truth unchanged.

### Candidate neutralize/drift-before-false
Where safely injectable, candidate sync neutralizes/rebinds then returns false.
Rollback must restore/rebind canonical candidate truth to original board and prove it. Exceptional full candidate rebuild/rebind is allowed ONLY on rollback recovery.

### Reservation mutation-before-false
A real accepted reservation subclass/test seam must:
1. actually remove the exact owner<->target pair using the canonical resolve;
2. return false.

Rollback must restore BoardState ACTIVE + candidate membership + exact reservation pair and preserve unrelated reservations/dispatcher assignment.

### True-without-postcondition
Add lying-success sensitivity for candidate and reservation where accepted subclass seams permit it:
- candidate returns true without removing target;
- reservation returns true without removing owner pair.

M20 must detect the missing postcondition and enter rollback/fail-closed handling. It must not finalize a half-clear.

### Board / dispatcher subclass rule
If V02 still accepts BoardState or ScrubbotDispatcher subclasses at bind, directly add:
- Board write mutation/lie cases;
- dispatcher finalize false/lie cases.

Preferred minimal architecture is to require exact production scripts for these two dependencies, making those malicious subclass callback classes impossible at the M20 boundary.

## 10. Rollback must return/prove success

Replace `_restore_candidate()` best-effort semantics with an explicit verified result.

Rollback success requires the complete intended tuple, not merely attempted calls.

For a pre-finalize rollback prove:
- BoardState target ACTIVE;
- raw target candidate membership restored;
- candidate exact-bound to original board;
- exact reservation owner<->target present;
- reservation count/set equals pre-state;
- dispatcher exact arrived assignment still pending;
- renderer still shows pre-clear source pixel if renderer was bound;
- unrelated reservation/candidate/dispatcher truth preserved.

If reservation callback removed the pair before reporting failure, restore BoardState/candidate first, then re-reserve the exact pair and verify.

If rollback itself cannot restore/prove the tuple, expose a stable `ROLLBACK_FAILED` (or equivalent explicit fatal outcome) and perform deterministic safe recovery so no contradictory cross-module state is reported as ordinary rollback success.

Do not silently swallow rollback failure.

## 11. Dispatcher finalization must be transactionally terminal

Because renderer now runs after finalization, a healthy exact production dispatcher should deterministically finalize after preflight and reservation success.

If `finalize_arrival()` returns false:
- do NOT call renderer;
- restore the pre-arrival BoardState/candidate/reservation tuple if the dispatcher still retains the exact arrived assignment;
- prove rollback;
- surface a distinct failure outcome;
- do not increment cleared count.

If dispatcher subclass acceptance remains and a subclass can mutate `_active` then lie, directly challenge it and provide a safe fail-closed strategy. Prefer exact production dispatcher identity to avoid reopening M19 semantics through arbitrary subclass behavior.

## 12. Renderer is post-commit presentation

Renderer absent remains valid.

With renderer:
- exact board coherence at bind;
- renderer is checked/live at presentation time;
- update occurs only AFTER dispatcher finalization success;
- candidate/reservation/finalization rollback produces NO transparent false-clear frame;
- candidate and reservation rollback tests MUST include a real renderer and assert source/ACTIVE pixel stays opaque;
- renderer cannot cause a gameplay rollback after authoritative commit.

Do not modify BoardRenderer beyond narrowly necessary read-only/presentation behavior unless a test proves it required.

## 13. Complete AL-028 second activation proof

Using the real production stack:
1. B initially unreachable;
2. A is the reachable gate/blocker;
3. attempt to activate B's color before A clear -> no dispatch where topology/color setup permits a direct check;
4. dispatch/arrive/clear A;
5. confirm A CLEARED, absent from candidates and OPEN to ProductionAccessQuery;
6. call `CompleteClearingLoop.activate_slot(...)` again;
7. prove the second dispatch selected/reserved B;
8. drive B to arrival;
9. prove B clears and final tuple is synchronized.

A standalone `is_targetable(B)==true` probe is not sufficient for criterion 224/226.

## 14. Fix direct-observability gaps

Add all:

### True 1x1 generic board
- actual BoardState width=1 height=1 cell_count=1;
- one ACTIVE target;
- dispatch from outside board;
- arrive/clear;
- second activation no work.

Do not substitute a 20x20 board with one ACTIVE cell.

### Five-slot direct identity proof
Before arrivals prove:
- five success results;
- five unique owner IDs;
- five distinct target indices;
- five exact ReservationState pairs;
- dispatcher active_count == 5.

After first arrival prove other four remain exact/in-flight. Then resolve all.

### Renderer rollback proof
Run candidate mutation-before-false and reservation mutation-before-false with renderer bound. Pixel must remain/return source-color opaque after rollback; no transparent false clear.

### Actual deferred destruction
The synchronous root runner currently cannot prove that queue_free actually completes after a frame. Add a small dedicated headless smoke script if needed, e.g. `tests/m20_queue_free_smoke.gd`, that:
- creates a real production M20 bundle;
- dispatches and reaches arrival;
- proves agent queued for deletion immediately;
- processes/awaits at least one SceneTree frame;
- proves the agent instance is no longer valid / no orphan child;
- exits nonzero on failure.

Run and record that command separately in CLAUDE_LOG_V02.

## 15. Failed-preflight safe recovery

Directly create an authenticated arrived assignment, then induce one preflight desync (e.g. reservation missing/wrong before loop handles it) so M20 rejects while dispatcher assignment remains arrived.

Then call `loop.reset()` and prove:
- dispatcher active entry removed;
- any still-held reservation removed;
- BoardState unchanged;
- candidate truth coherent;
- stale replay cannot clear;
- later normal activation works when work exists.

This defines recovery for the one-shot arrival bridge without weakening exactly-once authentication.

## 16. Preserve all accepted V01 + upstream regressions

Keep green:
- V01 bind/no-work/happy-path tests;
- BoardState canonical state;
- renderer ACTIVE/CLEARED;
- M11 session;
- M12 slots;
- M13 candidates;
- M14 reservation;
- M15-C002 final selector;
- M16 routing contract;
- M17 production routing;
- M18 agent;
- every M19 V01-V06 test;
- M20 59x59 + rectangular + rapid sequential coverage.

No M20 fix may weaken M19 authentication/finalization identity.

## 17. Scope

Allowed production:
- `scripts/gameplay/clearing/complete_clearing_loop.gd`;
- minimal M19 arrival-bridge hardening only if required by frozen V02 findings;
- minimal renderer read-only/presentation seam only if required.

Allowed tests:
- `tests/run_tests.gd`;
- narrow `tests/support/m20_*`;
- dedicated M20 frame/deferred-free smoke script.

Allowed docs:
- M20 architecture clarification;
- CLAUDE_LOG_V02;
- root TASKS top lifecycle fields.

Do NOT modify upstream BoardState/SlotSystem/ColorCandidateIndex/ReservationState/TargetSelector/routing/ScrubbotAgent production behavior unless a V02 test proves a genuine blocker. If so STOP `BLOCKED` and record it instead of silently widening scope.

Claude MUST NOT modify:
- any `CHATGPT_*` file;
- `coordination/AUDIT_INDEX.md`;
- audit verdicts;
- SB-M20 checkbox completion truth;
- `.hiveai/*` or archived live-tracker snapshots;
- M21+ task rows.

## 18. Validation

Record individually:
- `godot --version`;
- pre-fix V01 sensitivity results for at least:
  - nested bind;
  - reset during arrival;
  - candidate mutation-before-false;
  - reservation mutation-before-false;
  - true-without-postcondition candidate/reservation;
  - true 1x1 gap (test absent before V02 can be recorded as coverage gap, not necessarily failing code);
- final full root suite `godot --headless --path . -s res://tests/run_tests.gd`;
- dedicated queue-free smoke command/result;
- `git diff --check`;
- exact changed-file list;
- exact root TASKS start/final lifecycle;
- any failed attempts/fixes.

Tests must directly observe state; aggregate green count is insufficient.

## 19. Final handoff

On success:
- root `TASKS.md` Current Sprint = M20-C001 V02 — strict-v2 transaction correction;
- Current Task = M20-C001-V02;
- Current Task Status = AWAITING_AUDIT;
- Required Actor = CHATGPT;
- Next Task/Action = independent ChatGPT V02 audit against CLAUDE_LOG_V02 + V02 criteria;
- progress remains 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId remains M19-C001-V06;
- no SB-M20 row closed;
- commit/push implementation + tests + log + tracker handoff to origin/main;
- verify remote main.

Return exactly:
`AWAITING_AUDIT`

Tracking push failure:
`GITHUB_TRACKING_NOT_SYNCED`

Frozen blocker:
`BLOCKED`

Then STOP.
