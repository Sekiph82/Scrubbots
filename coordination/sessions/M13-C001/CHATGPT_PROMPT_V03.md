# M13-C001 — Frozen Full-Surface Color Candidate Closure V03

Status: **ISSUED — FROZEN FINDING SET**

Execute ONLY this current V03 correction.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/sessions/M13-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M13-C001/CHATGPT_STRICT_REAUDIT_V01.md
- prior M13 V01/V02 artifacts
- this prompt + V03 criteria

Expected log:
`coordination/sessions/M13-C001/CLAUDE_LOG_V03.md`

Fix ONLY:
- F-M13-STRICT-001
- F-M13-STRICT-002
- F-M13-STRICT-003

Do not implement M14+ behavior.
Do not modify BoardState to close FOUNDATION-STRICT-001 in this M13 cycle.

## 1. Harden BoardState dependency boundary

ColorCandidateIndex must fail closed before committing malformed dependency
truth.

The production implementation may keep a narrow duck-typed BoardState-compatible
surface so the existing traversal spy remains usable, but unsupported Variants
must be rejected before method calls.

Required malformed initial-bind classes:
- int;
- String;
- Vector2;
- RefCounted.new();
- partial object missing one required method;
- object with all method names but wrong return type for at least:
  - get_cell_count;
  - get_cell_state;
  - get_color_id.

Required behavior:
- bind returns false;
- no runtime fault;
- is_bound() false;
- get_candidates -> [];
- has_candidates -> false;
- count_candidates -> 0;
- get_color_ids -> [];
- no partial bucket commit.

Validate the narrow API before storing/marking usable bound state.

### Transactional build

Build candidate buckets into temporary/local state.

Commit `_board`, `_buckets`, `_bound` only after the full build validates.

For each scanned index establish:
- index is valid according to dependency truth;
- cell state is exactly ACTIVE or CLEARED;
- color ID used for ACTIVE membership is an integer in the valid palette-id
  domain (>= 0).

Malformed return values fail closed rather than faulting or committing partial
buckets.

### Malformed bind after valid state

Start with a valid bound index and snapshot its query truth.

Attempt malformed bind.

Canonical failure policy for ordinary bind:
- return false;
- neutralize unsafe binding so no malformed/stale dependency remains usable;
- no partially rebuilt bucket may be exposed.

Then prove a later valid bind can recover normally.

### rebind()

Preserve rebind as the explicit destructive fresh-board replacement path.

Test:
- valid board A -> valid rebind board B replaces truth;
- rebind(null) -> false, safe unbound/empty;
- malformed rebind -> false, safe unbound/empty;
- a later valid rebind/bind recovers.

## 2. Unknown/noncanonical cell-state handling

Do not use:
```gdscript
ACTIVE -> add
else -> remove
```

Canonical:
- ACTIVE -> candidate membership;
- CLEARED -> no candidate membership;
- every other value -> failure.

Use a test-only BoardState-compatible double/spy to inject states:
- 2;
- -1;
- 255;
- another arbitrary value such as 99.

### sync_cell path

For each unknown state:
- sync_cell returns false;
- it does not silently remove the cell as CLEARED;
- unrelated color buckets do not partially mutate;
- public query truth after the failure must be fail-closed with respect to the
  unknown cell.

Choose and document one safe policy:
- invalidate/unbind the cache on unknown state, OR
- another implementation that provably prevents stale/unknown membership from
  being asserted as canonical truth.

Do not merely preserve a stale candidate and continue reporting it as ACTIVE.

### bind/rebuild path

Directly test unknown state during:
- initial bind/build;
- rebuild after an otherwise valid bind.

Required:
- initial bind with unknown state fails without partial buckets;
- rebuild encountering unknown state returns false;
- no partial rebuild is committed;
- public query state after failure is conservative/fail-closed;
- restoring canonical BoardState truth followed by valid rebuild/rebind
  recovers.

This is M13 behavior only. Do not alter BoardState in this cycle.

## 3. Harden excluded/reserved Variant seam

Supported exclusion containers:
- Array;
- PackedInt32Array;
- Dictionary, using KEYS as excluded indices.

Decide/document null behavior explicitly. Preserve null as no-exclusion only if
it is already an intentional compatible contract and test it directly.

Unsupported CONTAINERS:
- int;
- float;
- String;
- bool;
- Vector2;
- RefCounted;
- nested scalar object where a container is expected.

For every unsupported container:
- get_candidates -> [];
- has_candidates -> false;
- count_candidates -> 0;
- no runtime fault;
- cached truth unchanged.

### Entry validation inside supported containers

Only TYPE_INT entries may exclude integer candidate indices.

Direct entries:
- valid int;
- duplicate int;
- negative int;
- out-of-range int;
- float equal in numeric value to a valid index, e.g. 2.0;
- numeric String "2";
- bool;
- Vector2;
- RefCounted;
- Array;
- Dictionary.

Required:
- only valid integer indices exclude;
- 2.0 must NOT exclude integer candidate 2;
- "2" must NOT exclude candidate 2;
- invalid entry classes have no effect on valid membership;
- duplicate valid ints are harmless;
- negative/out-of-range ints have no effect;
- Dictionary values are ignored; integer keys define exclusions;
- Array/PackedInt32Array/Dictionary produce equivalent results for equivalent
  valid integer exclusion sets.

### Same normalization across all query APIs

get_candidates(), has_candidates() and count_candidates() must share consistent
exclusion semantics.

Malformed query input must never mutate cache.

## 4. Preserve candidate/cache contract

Re-run and preserve:
- unbound safe queries;
- exact grouping by color;
- only valid ACTIVE matching-color candidates;
- CLEARED removal;
- ACTIVE restoration;
- no duplicate after repeated sync;
- cross-color isolation;
- invalid sync index atomicity;
- valid rebuild;
- valid fresh-board rebind;
- present/absent/exhausted/last-candidate semantics;
- all/partial exclusion;
- exclusion removal re-exposes unchanged ACTIVE candidate;
- detached get_candidates result;
- detached get_color_ids result;
- deterministic row-major ordering;
- rectangular board;
- 59x59 / 3481 cells;
- indexed vs naive correctness agreement;
- steady-state no BoardState rescan with sensitivity-safe traversal spy.

## 5. Immediate consumer regression

Current production TargetSelector passes ReservationState.get_reserved_indices()
as PackedInt32Array.

Directly prove:
- PackedInt32Array remains supported;
- a real candidate index + real ReservationState excluded set still yields the
  correct raw candidate list;
- no M15 target-selection/reachability logic is moved into M13.

## 6. Architecture boundaries

M13 remains:
- raw ACTIVE matching-color candidate index;
- caller-exclusion aware;
- reservation-agnostic;
- reachability-agnostic.

Do NOT add:
- ReservationState ownership;
- reserve/release;
- TargetSelector;
- access/reachability;
- RoutingSystem;
- dispatch;
- ScrubbotAgent behavior;
- BoardState lifecycle changes;
- M14+ features.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/STRICT_UPSTREAM_REPAIR_SEQUENCE_V01.md
- any CHATGPT_* file
- scripts/gameplay/board/board_state.gd

Run and record separately:
- godot --version
- full root headless suite
- git diff --check

Write:
`coordination/sessions/M13-C001/CLAUDE_LOG_V03.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
