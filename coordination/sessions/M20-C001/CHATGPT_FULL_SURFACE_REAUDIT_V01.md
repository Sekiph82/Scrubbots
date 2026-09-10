# M20-C001 — Full Attack-Surface Strict-v2 Design/Audit Freeze V01

Status: **IMPLEMENTATION_REQUIRED / CONTRACT_FROZEN**

Canonical tracker: repository-root `TASKS.md` only.

Current root task contract:
- M20 — Complete Clearing Vertical Slice
- SB-M20-001..014 are open.
- Current frontier before issuance: M20-C001-PREP / READY_FOR_NEXT_TASK / CHATGPT.

This document freezes the complete M20 V01 implementation/audit surface before Claude implementation. It is not an implementation verdict.

## Owner-locked gameplay law

Required flow from root TASKS.md and `docs/01_GAMEPLAY_SPEC.md`:

slot activation
→ reachable-work validation
→ TargetSelector selection
→ ReservationState ownership
→ exactly one ScrubbotAgent
→ route/travel
→ authenticated arrival
→ target ACTIVE -> CLEARED
→ ColorCandidateIndex truth update
→ access truth immediately reflects the clear
→ reservation resolved exactly once
→ Scrubbot disappears/finishes
→ no return / no carried pixel color.

CLEARED is alpha 0 and reveals BG01 through the transparent hole. There is no DIRTY/CLEAN transform or hidden second artwork.

M20 MUST NOT invent:
- win condition;
- lose condition;
- scoring/economy;
- `GameplaySession.complete()` auto-transition;
- automatic follow-up bot dispatch;
- slot cooldown/queue/consumption rules;
- slot active-state policy beyond the existing M12 model;
- collision-radius behavior.

Those remain later/design-gated concerns.

## Current accepted upstream truth

### BoardState
- exact cell domain is ACTIVE=0 / CLEARED=1;
- `set_cell_state(index, state)` explicitly rejects noncanonical state values;
- CLEARED is the physical gameplay truth.

### ColorCandidateIndex
- derived cache of ACTIVE color candidates only;
- `sync_cell(index)` is the one-cell synchronization seam;
- `is_bound_to(board)` proves exact BoardState identity;
- CLEARED cells must disappear from the bucket.

### ReservationState
- separate ephemeral owner<->target truth;
- exact one-owner/one-target invariant;
- `resolve_arrival(target, owner)` releases only the exact owner pair, once;
- it never mutates BoardState.

### ProductionAccessQuery
- reads BoardState live;
- CLEARED cells are immediately OPEN;
- therefore M20 must not maintain a second access cache or explicit access-state copy.

### BoardRenderer
- presentation-only;
- `update_cells([index])` redraws changed cell from current BoardState;
- CLEARED renders alpha 0;
- no current exact-board identity query exists.

### ScrubbotDispatcher M19 final law
- V05 production blob `0d1a6b1f6e9a6f1788ceb2078473c87bec8986e3` final-closed by V06;
- successful reservation remains held after arrival;
- `_active` assignment remains present after arrival;
- dispatcher validates owner/target/color/source identity and marks `arrived=true`;
- M19 deliberately does NOT clear board, sync candidates, resolve successful reservation, or remove the successful arrived assignment;
- current `_on_agent_completed` is internal and does not expose a clean M20 resolver signal/API.

### SlotSystem
- exactly five slots;
- validated palette/color assignment;
- availability/activity are stored model state;
- remaining slot mechanics are a design gate.

## Architecture decision frozen for V01

Do NOT turn ScrubbotDispatcher into the owner of BoardState/candidate/rendering mutation.

Create one narrow M20 orchestration layer under:

`scripts/gameplay/clearing/`

Recommended canonical name:

`complete_clearing_loop.gd`

Its responsibility is ONLY:
- translate one slot activation event into one M19 dispatch request;
- resolve an authenticated M19 arrival across the already-separate state modules;
- keep their post-arrival truth synchronized.

M19 dispatcher remains owner of dispatch/agent assignment identity. M20 clearing loop remains owner of the cross-module arrival transaction.

Minimal M19 extension is allowed ONLY to expose safe arrival-resolution seams; it must not move BoardState/candidate/rendering mutation into dispatcher.

Recommended M19 extension:
1. `signal assignment_arrived(owner_id, target_index, color_id, agent)` emitted exactly once only after existing M19 completion identity validation marks the assignment arrived;
2. read-only exact bundle/arrival query needed by M20, e.g. `is_bound_to(board, reservations)` and/or `is_arrival_pending(owner,target,color,agent)`;
3. narrow `finalize_arrival(owner,target,color,agent) -> bool` that removes the already-arrived dispatcher assignment and schedules the agent for safe destruction, but NEVER clears BoardState or ReservationState itself.

Because finalization is called from a completion-signal stack, do NOT synchronously `free()` a signal emitter if Godot can report locked-object errors. Prefer safe `queue_free()`/deferred destruction while erasing dispatcher bookkeeping deterministically.

BoardRenderer may receive one minimal read-only exact-board coherence query such as `is_bound_to(board)` if required. Do not otherwise change M10 rendering behavior.

## Frozen findings / implementation obligations

### F-M20-STRICT-001 — complete-loop ownership, bind and exact bundle coherence

There is currently no M20 coordinator.

Required bind contract:
- initialization-only ordinary `bind()`;
- real BoardState;
- real SlotSystem;
- real ColorCandidateIndex exact-bound to board;
- real ReservationState exact-bound to board;
- real ScrubbotDispatcher exact-bound to the same board + ReservationState;
- optional real live BoardRenderer exact-bound to the same board;
- SlotSystem configured with exactly five slots;
- dispatcher has zero pre-existing active assignments at initial M20 bind, so the clearing loop never begins after missing prior arrivals.

Use exact production lifecycle categories, not broad method-name-only duck typing for the M20 coordinator's canonical dependencies.

Every activation and arrival must re-check live exact coherence before a consequential mutation. If a sibling is rebound/replaced, fail closed and do not clear the wrong board.

Ordinary second bind must return false and preserve the original bundle.

No mutable internal dependency/transaction map may be leaked by query APIs.

### F-M20-STRICT-002 — slot activation boundary and no-work semantics

Expose one headless-testable API, recommended:

`activate_slot(slot_id, start_position, speed = dispatcher default) -> DispatchResult`

The API call itself represents the player's slot activation event. Do NOT invent a new meaning for `SlotState.active`.

Before dispatch:
- loop bound/coherent;
- slot id actual int in [0,4];
- SlotSystem configured;
- slot available;
- slot palette id valid nonnegative int;
- start/speed obey M19 finite request contract.

Do NOT mutate slot active/availability/palette state as a side effect of M20 unless an existing locked rule explicitly requires it. M12 says remaining slot mechanics are design-gated.

The loop must delegate reachability/work truth to the already-audited dispatcher/TargetSelector/ProductionTargetAccess chain. It must not implement a second candidate/route algorithm.

No reachable target:
- zero bot;
- zero new reservation;
- zero BoardState mutation;
- slot state unchanged.

One activation creates at most one bot.

### F-M20-STRICT-003 — authenticated, exactly-once arrival handoff

M20 must never clear a cell merely because some agent-like object emits a signal.

Dispatcher must first authenticate the existing immutable M19 identity:
- exact owner;
- exact target;
- exact color;
- exact agent instance;
- assignment is known and arrived.

Only then may it emit/offer the M20 arrival seam.

M20 clearing loop must additionally verify before mutation:
- target valid;
- target still ACTIVE;
- target color equals assignment color;
- ReservationState owner->target and target->owner both match;
- candidate index still exact-bound to the same board;
- dispatcher still exposes the exact arrived assignment.

Wrong/stale/duplicate/spoofed completion:
- no clear;
- no candidate change;
- no reservation release;
- no unrelated agent removal.

Repeated correct completion/finalization must be idempotent. One assignment clears exactly one cell exactly once.

### F-M20-STRICT-004 — atomic ACTIVE->CLEARED cross-module transaction

Authoritative post-arrival order is frozen:

1. preflight exact identity/coherence while reservation is still held;
2. BoardState target ACTIVE -> CLEARED;
3. ColorCandidateIndex `sync_cell(target)` so the cleared target leaves the raw candidate bucket;
4. resolve exact ReservationState arrival once;
5. update optional renderer for exactly that changed target from current BoardState;
6. finalize the dispatcher arrival bookkeeping and schedule the Scrubbot agent to disappear safely.

ProductionAccessQuery requires NO explicit update because it reads BoardState live; test that this is true.

Every step must have direct postconditions.

If step 2 fails:
- nothing else changes.

If candidate sync in step 3 fails unexpectedly:
- restore BoardState target to ACTIVE;
- restore/rebuild candidate truth to the original pre-arrival state;
- keep reservation and dispatcher arrived assignment held;
- do not finalize the agent;
- report/return failure without pretending the cell cleared.

If reservation resolution in step 4 fails unexpectedly:
- rollback BoardState to ACTIVE;
- resync/rebuild candidate truth back to ACTIVE;
- keep dispatcher arrival held;
- do not finalize the agent.

The concrete healthy production bundle should make these failures unreachable after preflight, but the rollback behavior must still be explicit and directly tested with controlled doubles/subclasses only where the production category safely permits them.

Do NOT clear reservation before the BoardState/candidate mutation succeeds.

Do NOT erase dispatcher assignment before reservation resolution succeeds.

Renderer is presentation, not gameplay authority. A missing optional renderer must not block headless gameplay truth. When bound, its displayed target pixel must become fully transparent after the successful transaction.

### F-M20-STRICT-005 — clear must immediately change future reachability

Critical semantic regression:
- an ACTIVE gate/blocker can make a same-color or other-color interior target unreachable;
- after the gate cell is successfully CLEARED, ProductionAccessQuery reads it as OPEN;
- the next activation may then find/route to a target that was previously unreachable.

Test this with real:
- BoardState;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- ProductionAccessQuery;
- ProductionTargetAccess;
- ProductionRoutingSystem;
- ScrubbotDispatcher;
- CompleteClearingLoop.

No explicit access-cache mutation or route retarget hack is allowed.

### F-M20-STRICT-006 — reset, stale arrival, re-entry and safe agent disappearance

M20 needs deterministic reset semantics without resetting board artwork:
- cancel/reset all currently in-flight dispatcher assignments through the dispatcher;
- release their reservations;
- do NOT turn already-CLEARED cells ACTIVE;
- do NOT mutate ColorCandidateIndex for cells whose BoardState did not change;
- stale completion after reset cannot clear anything.

Arrival resolution must be serial/re-entry-safe:
- one arrival transaction at a time;
- duplicate/nested arrival callback cannot double-resolve;
- reset during an in-flight M19 dispatch remains M19 law;
- reset invoked after successful M20 clear must not resurrect the cell or reservation;
- reset during a controlled arrival phase must either occur before mutation or result in a documented fail-closed rollback, never half-clear state.

Successful arrived agent:
- is removed from dispatcher active truth;
- reservation gone;
- safely queued/deferred for destruction;
- no return path;
- no carried pixel color/resource;
- after SceneTree processes the queued free, no orphan node remains.

### F-M20-STRICT-007 — scale, deterministic integration and state-desynchronization coverage

Required direct integrations:
- one-cell synthetic board;
- one-color repeated clearing/exhaustion;
- multi-color board;
- all five slots;
- Easy band;
- Medium band;
- Hard band;
- Very Hard band;
- 59x59 maximum;
- rectangular production board.

After every successful arrival assert the synchronized tuple:

`BoardState[target] == CLEARED`

AND

`target absent from ColorCandidateIndex raw bucket`

AND

`ProductionAccessQuery classifies target cell OPEN for later traversal`

AND

`ReservationState.get_owner(target) == -1`

AND

`ReservationState.get_target_for_owner(owner) == -1`

AND

`ScrubbotDispatcher.has_owner(owner) == false`

AND

`agent scheduled/freed, no return`

AND, if renderer bound,

`rendered alpha(target) == 0` within RGBA8 tolerance.

Unrelated cells/candidates/reservations/agents must remain unchanged.

The loop must never rescan the whole board as part of one normal clear. Use the existing single-cell synchronization/update seams.

## M19/M20 boundary

M20 MAY add narrow M19 public seams required for authenticated arrival and finalization.

M20 MUST preserve every M19 V01-V06 regression.

M20 MUST NOT:
- move BoardState mutation into ScrubbotAgent;
- move target selection into RoutingSystem;
- move routing into TargetSelector;
- add RESERVED to BoardState;
- turn ColorCandidateIndex into reservation owner;
- automatically dispatch a replacement bot after arrival;
- auto-complete GameplaySession;
- score/reward/streak;
- implement win/lose;
- modify LevelData source truth.

## Full attack matrix frozen

V01 must cover:
- null/scalar/wrong-category dependencies;
- same-size different-board identity;
- unconfigured slots;
- invalid slot id / unavailable slot;
- invalid palette id if a corrupted test seam can expose one;
- NaN/INF positions and speed through activation;
- no candidate / blocked candidate;
- duplicate reservation;
- successful arrival;
- wrong owner/target/color/source;
- completion twice;
- target already CLEARED before callback;
- reservation missing/wrong-owner before callback;
- candidate/index dependency drift before callback;
- dispatcher/reset stale arrival;
- arrival resolution re-entry;
- candidate-sync failure rollback;
- reservation-resolve failure rollback;
- renderer absent/present;
- renderer exact-board mismatch at bind;
- safe queue-free/deferred disappearance;
- newly-opened-after-clear routing;
- 5 concurrent slot assignments to distinct targets;
- 25+ sequential clears where practical;
- one-cell, one-color, multi-color;
- production difficulty bands, 59x59, rectangular;
- no full-board scan per normal arrival;
- no M21+ real-art/content dependency.

## Task closure candidates

Only after independent strict-v2 audit may ChatGPT close:
- SB-M20-001
- SB-M20-002
- SB-M20-003
- SB-M20-004
- SB-M20-005
- SB-M20-006
- SB-M20-007
- SB-M20-008
- SB-M20-009
- SB-M20-010
- SB-M20-011
- SB-M20-012
- SB-M20-013
- SB-M20-014

Because M20 is critical/stateful and V01 introduces production code, a clean V01 implementation is not automatically final closure. ChatGPT may require a correction pass and/or auditor-authored validation-only pass before task closure.
