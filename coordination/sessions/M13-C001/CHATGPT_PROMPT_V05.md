# M13-C001 — Final Dependency-Domain Closure V05

Status: **ISSUED — SAME FROZEN FINDING SET**

This continues the SAME M13 frozen finding set.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/sessions/M13-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M13-C001/CHATGPT_PROMPT_V04.md
- coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V04.md
- coordination/sessions/M13-C001/CLAUDE_LOG_V04.md
- coordination/sessions/M13-C001/CHATGPT_AUDIT_V04.md
- this prompt + V05 criteria

Expected log:
`coordination/sessions/M13-C001/CLAUDE_LOG_V05.md`

Frozen status:
- F-M13-STRICT-001: OPEN;
- F-M13-STRICT-002: preserve;
- F-M13-STRICT-003: preserve.

Do not modify BoardState.
Do not implement M14+ behavior.

## 1. Preserve successful indexed domain truth

A successful transactional bind/rebuild must retain enough immutable domain
metadata to distinguish:
- caller supplied an index that was never inside the indexed board domain;
- dependency later contradicts the domain that was successfully indexed.

Preferred implementation:
- retain the successfully validated cell count from the same transactional scan
  result that produced the buckets;
- commit count + buckets + board atomically;
- neutralize resets the stored count.

Do not call a second mutable get_cell_count() after the scan merely to populate
metadata. The count must belong to the same validated transactional snapshot.

No full-board rescan may be added to steady-state queries.

## 2. Correct healthy-invalid vs dependency-drift sync semantics

After valid bind of count 4:

### Healthy caller invalid index
Directly test:
- sync_cell(-1);
- sync_cell(4);
- sync_cell(999).

Required:
- each returns false;
- binding remains valid;
- cached candidates remain unchanged;
- no dependency corruption is inferred.

### Contradictory live dependency
For an index INSIDE the successfully indexed domain, e.g. index 2 of count 4:

```text
indexed domain says 0..3 exists
live is_valid_index(2) returns false
```

Required:
- sync_cell(2) returns false;
- cache neutralizes/unbinds;
- get_candidates -> [];
- has_candidates -> false;
- count_candidates -> 0;
- get_color_ids -> [];
- is_bound_to(old board) false;
- later valid bind/rebind recovers exact truth.

Also preserve non-bool is_valid_index drift neutralization.

The V04 “healthy invalid index” test using in-range index 2 must be corrected.
It must not remain as an assertion that contradictory dependency truth is
healthy.

## 3. Production max-count guard

Project production max:
```text
59 * 59 = 3,481 cells
```

Transactional _scan must reject a dependency count > 3,481 BEFORE iteration.

Directly test:
- count 0: preserve current intentional behavior if desired;
- count 3,481: accepted when the dependency provides canonical returns;
- count 3,482: rejected;
- count 1,000,000: rejected;
- a very large positive integer: rejected.

For rejected counts:
- bind false;
- unbound;
- no buckets;
- no per-cell traversal calls should occur after reading the count.

Use a counting test double/spy to prove the 3,482/huge rejection happens before
is_valid_index/get_cell_state/get_color_id traversal.

Do not introduce a hardware timing threshold. This is structural evidence.

## 4. Transactional rebuild domain metadata

Directly prove:
1. bind board A with count N;
2. successful rebuild with same canonical domain preserves correct count/buckets;
3. valid rebind to board B with different count updates both domain metadata and
   bucket truth atomically;
4. failed rebuild leaves no stale/partial usable cache under the existing
   fail-closed policy;
5. neutralization resets all domain metadata.

## 5. Preserve all V04 dependency corrections

Keep green:
- bind(null) after valid -> unbound/empty;
- fresh bind(null);
- RefCounted-only dependency category;
- real BoardState accepted;
- traversal spy accepted;
- canonical malformed-board double accepted;
- plain RefCounted rejected;
- bare Node rejected;
- method-compatible Node rejected;
- wrong/negative count;
- non-bool/false is_valid_index build rejection;
- non-int/unknown state build rejection;
- non-int/negative color build rejection;
- late malformed build has no partial buckets;
- live non-bool index return neutralizes;
- live non-int state neutralizes;
- live non-int/negative ACTIVE/CLEARED color neutralizes;
- recovery.

## 6. Preserve F-M13-STRICT-002

Keep unknown-state direct tests:
- 2;
- -1;
- 255;
- 99;
- sync;
- initial bind;
- rebuild;
- fail-closed public truth;
- recovery.

Do not modify BoardState. FOUNDATION-STRICT-001 stays separate.

## 7. Preserve F-M13-STRICT-003

Keep exclusion coverage:
- Array;
- PackedInt32Array;
- Dictionary keys;
- null no-exclusion;
- unsupported containers;
- integer-only entry semantics;
- float/String non-coercion;
- invalid nested entries;
- consistent get/has/count semantics;
- no cache mutation;
- real ReservationState PackedInt32Array consumer.

## 8. Full M13 regression

Preserve:
- exact color grouping;
- ACTIVE/CLEARED;
- no duplicate repeated sync;
- cross-color isolation;
- rebuild/rebind;
- exhausted/last candidate;
- detachment;
- deterministic ordering;
- rectangular board;
- real 59x59 / 3481 board;
- no-rescan sensitivity;
- indexed vs naive agreement.

No M14+ behavior.

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
`coordination/sessions/M13-C001/CLAUDE_LOG_V05.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
