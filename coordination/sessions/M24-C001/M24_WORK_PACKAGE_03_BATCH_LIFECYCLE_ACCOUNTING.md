# M24 Work Package 03 — Batch Lifecycle Accounting

Covers: `SB-M24-016..022`

## Goal

Implement M24's remaining/committed accounting, completion, rollback and WAITING/ACTIVE state machine without implementing M25 target arbitration or M26 robot dispatch.

## Opaque committed-work ledger

M24 must support registering future work against an occupied batch using an opaque unique work identity.

The work identity is accounting-only. It must not encode or choose a target pixel, route, reservation, robot or solver decision.

Recommended semantics:

- `commit_work(slot/batch, work_id)` or equivalent:
  - requires occupied ACTIVE/WAITING batch;
  - requires remaining capacity > 0;
  - work identity globally/session-unique while live;
  - records exact slot + batch identity;
  - increments `committed` by exactly one;
  - leaves `remaining_to_clear` unchanged.

- `resolve_clear(work_id)` or equivalent:
  - accepts only a live work identity previously committed by this engine;
  - resolves against its engine-owned original slot/batch identity, not caller-supplied mutable fields;
  - decrements `committed` exactly one;
  - decrements `remaining_to_clear` exactly one;
  - removes live work identity;
  - triggers completion check.

- `rollback_work(work_id)` or equivalent:
  - accepts only a live committed identity;
  - decrements `committed` exactly one;
  - leaves `remaining_to_clear` unchanged;
  - removes live work identity.

## Hard rules

Never decrement `remaining_to_clear` for:

- supply selection;
- slot placement;
- state query;
- WAITING/ACTIVE transition;
- future target claim;
- future route calculation;
- future robot spawn;
- rollback/cancel.

Only successful resolution of a previously committed live work identity may decrement remaining count.

## Counter invariant

Enforce after every operation:

`0 <= committed <= remaining_to_clear <= initial_count`

Capacity is always:

`remaining_to_clear - committed`

Attempts to exceed capacity, underflow counters, reuse work IDs, resolve unknown IDs, resolve against wrong batch/slot, double-resolve, rollback unknown IDs or rollback twice fail closed with exact prestate preserved.

## Completion

A batch completes only when both:

- `remaining_to_clear == 0`
- `committed == 0`

If the last clear makes both zero, immediately return that slot to exact EMPTY truth.

Do not shift neighbors.

A slot must not free while any live committed work remains.

## WAITING / ACTIVE

M24 models state but does not decide target claimability.

Provide a narrow authoritative notification/update seam such as:

- `set_claimable_work_available(slot/batch, bool)`
- `refresh_claimability(...)`
- or an injected read-only claimability provider

The seam must not expose target selection/claim logic.

Required behavior:

- occupied batch with remaining quota and `claimable=false` -> WAITING;
- WAITING + authoritative `claimable=true` -> ACTIVE automatically;
- no player re-selection needed;
- WAITING preserves batch identity and all counters;
- ACTIVE/WAITING transitions never mutate M23 supply;
- EMPTY cannot become WAITING/ACTIVE through this seam;
- completed batch cannot resume;
- state notification with stale/wrong batch identity fails closed.

If a callback/provider is used, guard against synchronous re-entry/reset/state drift and add adversarial tests.

## Future M25/M26 boundary

Document explicitly:

- M25 will decide which target, if any, is claimable and which same-color batch has priority;
- M26 will create real dispatcher/robot work and connect authenticated clear/rollback outcomes to these M24 accounting seams;
- M24 must not pre-assign target pixels or spawn robots.

## Direct tests

Include at minimum:

- capacity 0/full boundaries;
- commit until capacity exhausted;
- over-commit rejection;
- duplicate work ID rejection;
- resolve one work;
- rollback one work;
- double resolve/rollback rejection;
- random work ID rejection;
- remaining unchanged on commit/rollback/state change;
- final legitimate resolve -> EMPTY;
- WAITING -> ACTIVE notification;
- invalid EMPTY transitions;
- same-color slots maintain separate work ledgers;
- reset-stale work IDs will be completed in WP04.

## Completion criterion

Do not proceed to WP04 until every accounting/state-machine invariant passes focused headless tests.
