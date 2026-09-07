# M13-C001 — Strict Dependency Closure V04

Status: **ISSUED — SAME FROZEN FINDING SET**

This continues the SAME M13 frozen set. Do not create new M13 semantics.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/sessions/M13-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M13-C001/CHATGPT_PROMPT_V03.md
- coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V03.md
- coordination/sessions/M13-C001/CLAUDE_LOG_V03.md
- coordination/sessions/M13-C001/CHATGPT_AUDIT_V03.md
- this prompt + V04 criteria

Expected log:
`coordination/sessions/M13-C001/CLAUDE_LOG_V04.md`

Frozen status:
- F-M13-STRICT-001: OPEN;
- F-M13-STRICT-002: preserve V03 correction;
- F-M13-STRICT-003: preserve V03 correction.

Do not modify BoardState.
Do not implement M14+ behavior.

## 1. Fix bind(null) stale-binding escape

Ordinary bind failure must have one consistent fail-closed policy.

Direct sequence:
1. bind valid board A;
2. prove exact candidate truth;
3. call bind(null);
4. return false;
5. is_bound() == false;
6. get_candidates() == [];
7. has_candidates() == false;
8. count_candidates() == 0;
9. get_color_ids() == [];
10. is_bound_to(board A) == false;
11. later valid bind(board A or B) recovers exact truth.

Do not let null be the only bind failure that preserves stale state.

Fresh bind(null) must remain safe.

## 2. Narrow dependency lifecycle category

Canonical BoardState is RefCounted, as are the compatible M13 spies.

Preferred contract:
- accepted dependency must be RefCounted;
- plus the complete narrow API:
  get_cell_count, is_valid_index, get_cell_state, get_color_id.

Directly test:
- real BoardState accepted;
- BoardState traversal spy accepted;
- M13 malformed RefCounted double accepted only when its returns are canonical;
- plain RefCounted without API rejected;
- Node without API rejected;
- method-compatible Node rejected.

This prevents externally-freed Node dependency lifecycle from entering M13.

If you choose to support Node instead, you must add lifecycle-validity checks to
EVERY public path that can expose cache truth and directly test
bind-compatible-Node -> external free -> query/rebuild/sync fail closed.
The RefCounted-only route is preferred.

## 3. Complete transactional build return-contract adversaries

Extend the malformed-board double as needed.

Direct fresh bind cases:

### get_cell_count
- String/wrong type -> false/unbound/empty (preserve V03);
- negative integer -> false/unbound/empty;
- zero may remain valid only if documented as intentional and harmless.

### is_valid_index
For an index inside the declared count:
- non-bool return -> bind false/unbound/empty;
- boolean false -> bind false/unbound/empty.

### get_cell_state
- non-int -> false/unbound/empty;
- unknown int -> false/unbound/empty.

### ACTIVE get_color_id
- non-int -> false/unbound/empty;
- negative int -> false/unbound/empty.

At least one malformed value must occur AFTER one or more earlier indices have
already produced valid ACTIVE data, proving transactional local buckets are not
partially committed.

## 4. Harden sync_cell against live dependency return drift

After a valid bind, mutate the compatible test dependency so one live return
becomes malformed.

Direct cases:

### is_valid_index
- normal boolean false for a genuinely invalid index:
  - sync returns false;
  - healthy binding/cache remains intact.
- malformed non-bool return for an otherwise valid index:
  - sync returns false;
  - cache neutralizes/unbinds;
  - all public candidate truth becomes empty/fail-closed.

### get_cell_state
- non-int return:
  - sync false;
  - neutralize/unbind;
  - no stale candidate truth remains.

### get_color_id
For canonical ACTIVE and CLEARED states:
- non-int return;
- negative int return.

Each malformed case:
- sync false;
- neutralize/unbind;
- no stale candidate truth remains.

Then restore canonical dependency truth and prove later valid bind/rebind
recovers.

Do not treat a healthy out-of-range index request as dependency corruption.
Only malformed dependency truth should neutralize.

## 5. Preserve F-M13-STRICT-002 unknown state correction

Keep direct tests for:
- 2;
- -1;
- 255;
- 99;
- sync path;
- initial bind;
- rebuild;
- fail-closed query state;
- recovery.

Unknown state must never silently become CLEARED.

FOUNDATION-STRICT-001 remains separate. BoardState source must remain unchanged.

## 6. Preserve F-M13-STRICT-003 exclusion correction

Keep direct tests for:
- Array;
- PackedInt32Array;
- Dictionary keys;
- null no-exclusion;
- unsupported container fail-closed;
- valid integer entries;
- duplicate/negative/out-of-range integer behavior;
- 2.0 and "2" non-coercion;
- bool/Vector2/RefCounted/nested Array/Dictionary entries;
- consistent get_candidates/has_candidates/count_candidates semantics;
- real ReservationState PackedInt32Array consumer.

Malformed exclusion inputs must not mutate cache.

## 7. Full M13 regression

Preserve all V03/V02 M13 tests:
- grouping;
- ACTIVE/CLEARED;
- repeated sync;
- invalid sync;
- rebuild/rebind;
- exhausted/last candidate;
- exclusion behavior;
- detached results;
- deterministic order;
- rectangular;
- 59x59 / 3481;
- no-rescan sensitivity;
- indexed vs naive agreement.

No reservation ownership, reachability, selector, routing, dispatch or agent
behavior may move into M13.

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
`coordination/sessions/M13-C001/CLAUDE_LOG_V04.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
