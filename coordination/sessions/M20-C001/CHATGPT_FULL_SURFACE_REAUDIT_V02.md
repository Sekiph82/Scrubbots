# M20-C001 — Full Attack-Surface Re-audit V02

Status: **FROZEN CORRECTION SURFACE / NO WHACK-A-MOLE**

Basis:
- V01 implementation commit `30711975cd9bb06bf1f398d0ab00ede7483d2410`;
- V01 audit `CHATGPT_AUDIT_V01.md`;
- original V01 freeze `CHATGPT_FULL_SURFACE_REAUDIT_V01.md`;
- root `TASKS.md` M20 contract;
- current M13-M19 final-closed upstream behavior.

This document freezes the complete V02 correction surface before Claude edits production.

## Public/externally-triggered M20 surface

Audit every entry/callback boundary:
- `CompleteClearingLoop.bind(...)`;
- `is_coherent()`;
- `activate_slot(...)`;
- dispatcher `assignment_arrived` -> loop arrival handler;
- `reset()`;
- `get_cleared_count()` / `get_last_outcome()` read-only queries;
- M19 `is_bound_to`, `is_arrival_pending`, `finalize_arrival` bridge;
- BoardRenderer `is_bound_to` and post-commit repaint.

## Stateful collaborators / callback boundaries

Even concrete-category dependencies may be subclasses in tests/current V01 acceptance. Treat every overridable call as an external synchronous boundary unless V02 deliberately narrows the category to exact production scripts.

Challenge:
- slot `is_configured`, `get_slot_count`, `is_slot_available`, `get_slot_palette_id`;
- candidate `is_bound_to`, `sync_cell`, `rebuild/rebind`, candidate queries used for postconditions;
- reservation `is_bound_to`, `get_owner`, `get_target_for_owner`, `get_reservation_count`, `get_reserved_indices`, `resolve_arrival`, rollback `reserve`;
- dispatcher `is_bound_to`, `get_active_count`, `dispatch`, `is_arrival_pending`, `finalize_arrival`, `reset`;
- renderer `is_bound_to`, `update_cells`, pixel readback when used as validation.

For every callback class consider:
- re-entry into bind/activate/arrival/reset;
- reset request;
- sibling dependency drift/rebind;
- mutation before false/malformed return;
- true return with missing/wrong postcondition;
- repeated call;
- stale state after reset;
- wrong owner/target/color/agent;
- unrelated ownership preservation.

## F-M20-STRICT-001 — bind / coherence transaction

Frozen V02 requirements:
- arm bind guard before first external callback;
- nested bind fails and cannot connect a second dispatcher signal;
- no signal connection occurs before complete validation;
- failed bind leaves loop unbound and callback disconnected;
- a callback-induced drift/rebind during bind is detected before commit;
- final committed bundle is exact-coherent;
- second ordinary bind after success is false/preserve;
- no destructive rebind API;
- no mutable dependency reference exposed.

Direct adversaries:
- candidate `is_bound_to` callback recursively calls loop.bind;
- reservation `is_bound_to` callback recursively calls loop.bind;
- callback rebinds candidate/reservation to same-size foreign board while returning a superficially passing value;
- ensure original/foreign dispatcher signal connection counts do not show ghost loop callbacks.

V02 may narrow selected dependencies to exact production script identity if that is the cleanest way to make a callback class impossible, but any remaining accepted subclass seam must be adversarially guarded.

## F-M20-STRICT-002 — activation transaction

Frozen requirements:
- at most one activation body active at a time;
- nested activation from any accepted callback fails before dispatcher dispatch;
- activation cannot run while an arrival transaction is mutating cross-module truth;
- reset request during activation preflight prevents the outer dispatch;
- invalid/reentrant/reset-aborted activation advances no owner ID and creates no reservation/agent;
- slot state remains unchanged;
- normal sequential later activation recovers.

## F-M20-STRICT-003 — authenticated arrival / failed-preflight recovery

Preserve the V01 M19 identity bridge.

Add direct recovery proof:
- an arrival that is correctly authenticated by M19 but intentionally fails M20 preflight remains held, not half-cleared;
- `CompleteClearingLoop.reset()` then deterministically removes the stranded active assignment/reservation without changing BoardState/candidate truth;
- stale replay after that reset cannot clear.

Do not weaken exactly-once emission merely to make tests easy.

## F-M20-STRICT-004 — transaction postconditions / rollback

### Corrected V02 order

The V01 renderer-before-finalize detail is superseded by this audit correction because renderer is presentation only.

V02 gameplay order:
1. exact preflight + pre-state snapshot;
2. BoardState ACTIVE -> CLEARED;
3. candidate sync;
4. reservation resolve;
5. dispatcher finalization;
6. optional renderer repaint from committed BoardState.

No presentation callback may sit between reservation resolution and dispatcher ownership finalization.

### Direct postconditions

After each successful return, prove the corresponding authoritative state before beginning the next phase:
- Board write: target state really CLEARED, color unchanged;
- candidate sync: candidate layer still exact-bound and raw candidate query without reservation exclusion no longer contains target;
- reservation resolve: owner->target == -1, target->owner == -1, reservation set/count equals pre-state minus exactly this target;
- dispatcher finalize: exact owner absent and active count equals pre-state minus exactly one; unrelated active entries preserved;
- renderer repaint: target alpha 0 when renderer still healthy; renderer does not define gameplay success.

### Failure/rollback classes

Challenge separately:
1. callback returns false without mutation;
2. callback mutates exact target/pair then returns false;
3. callback returns true but fails required postcondition;
4. candidate neutralizes/rebinds itself before failure;
5. reservation removes exact pair before failure;
6. reset requested inside candidate/reservation callback;
7. finalization false before mutation (if accepted dispatcher seam can produce it);
8. finalization mutation-before-false / true-without-postcondition if dispatcher subclasses remain accepted.

Rollback must be verified, not best-effort.

Candidate rollback after BoardState is restored ACTIVE must recover exact canonical raw membership. If candidate is neutralized/drifted, the exceptional rollback may use a full `rebind(_board)`/rebuild only as needed; normal healthy clear remains one-cell O(1)/bucket-sync behavior.

Reservation rollback after a failed/malformed resolve must restore the exact owner<->target pair when that callback removed it, while preserving unrelated reservations. Because ReservationState requires ACTIVE target for `reserve`, BoardState/candidate restoration must occur before re-reserving.

If exact rollback itself cannot be proven, use an explicit `ROLLBACK_FAILED`/fatal fail-closed outcome and a deterministic safe recovery strategy. Never claim ordinary rollback success while authoritative layers contradict one another.

## F-M20-STRICT-005 — newly-opened reachability

V02 must continue beyond the probe:
- B initially not targetable;
- dispatch/arrive/clear gate A;
- confirm A OPEN live;
- call `CompleteClearingLoop.activate_slot(...)` again through the real production stack;
- prove second dispatch selects/reserves B;
- drive B to arrival;
- prove B clears and final tuple is synchronized.

No route retarget hack or explicit access-cache refresh.

## F-M20-STRICT-006 — arrival serialization / reset

Introduce an arrival transaction guard plus a deterministic strategy for nested **distinct** authenticated arrivals.

A second legitimate arrival that fires synchronously while one arrival is processing must not be silently dropped, because M19 bridge emission is one-shot. Queue/defer and drain it serially, or implement an equivalent lossless serial mechanism.

Duplicate same assignment remains idempotent.

Activation is blocked/rejected while arrival commit is active.

Reset during arrival:
- must not call dispatcher.reset in the middle of a partially-mutated cross-module tuple;
- record/defer reset intent;
- if no mutation yet, abort before clear;
- if mutation has begun, restore/prove a coherent pre-clear gameplay tuple first;
- then apply dispatcher reset so final reset truth is coherent: BoardState/candidate preserved, in-flight reservation/dispatcher ownership removed, no orphan agent;
- clear any queued stale arrival items;
- later normal activation works.

Test reset injected at least:
- candidate sync callback;
- reservation resolve callback;
- before/around finalization if a controllable seam remains.

## F-M20-STRICT-007 — direct-observability completion

V02 must add:
- a real generic **1x1 BoardState** test, not 20x20 with one ACTIVE cell;
- five-slot pre-arrival proof of five unique owner IDs;
- five distinct target indices;
- five exact reservation pairs;
- one arrival preserves the other four before they arrive;
- renderer-present candidate rollback leaves source pixel visually ACTIVE/opaque;
- renderer-present reservation rollback leaves source pixel visually ACTIVE/opaque;
- actual queued-free/deferred-destruction proof after SceneTree processes at least one frame, preferably via a dedicated small headless smoke script if the synchronous root runner cannot await safely;
- later-B real second activation from F-M20-STRICT-005;
- reset-during-arrival from F-M20-STRICT-006.

## Scale / performance preservation

Normal successful clear must remain:
- one BoardState target write;
- one candidate single-cell sync;
- O(1) reservation resolution;
- O(1) dispatcher finalization/bookkeeping;
- one renderer cell repaint if present;
- no full-board scan in the normal path;
- no second access cache;
- no per-cell Node tree.

Full candidate rebuild/rebind is acceptable only on exceptional rollback recovery, never the healthy path.

Preserve 59x59 and rectangular production coverage.

## Upstream invariants

Do not modify unless V02 proves a blocker:
- BoardState core;
- SlotSystem core;
- ColorCandidateIndex core;
- ReservationState core;
- TargetSelector core;
- routing algorithms/access law;
- ScrubbotAgent core.

M19 may receive only minimal arrival-bridge hardening needed by the frozen V02 transaction. If a broader M19 change becomes necessary, stop BLOCKED rather than silently reopening M19.

## Design gates / out of scope

Still forbidden:
- win/lose;
- `GameplaySession.complete()` automation;
- scoring/reward/streak;
- auto-follow-up dispatch;
- slot queue/cooldown/consumption;
- save/progression/economy;
- M21 real-art work;
- production UI;
- collision-radius invention.

## Task/progress state

SB-M20-001..014 remain open through V02 implementation and audit.
Progress remains 290/719 main+ui and 290/943 overall until independent final closure.
