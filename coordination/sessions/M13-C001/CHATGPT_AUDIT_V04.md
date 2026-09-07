# M13-C001 — ChatGPT Independent Audit V04

Decision: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**

Audited implementation commit:
`227fd9a1e3fd050ddffb424fa0e6d088cc5bbd1b`

Prompt:
`coordination/sessions/M13-C001/CHATGPT_PROMPT_V04.md`

Criteria:
`coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

Claude log:
`coordination/sessions/M13-C001/CLAUDE_LOG_V04.md`

Prior audit:
`coordination/sessions/M13-C001/CHATGPT_AUDIT_V03.md`

Frozen basis:
`coordination/sessions/M13-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`

## Independence / runtime disclosure

Claude reports Godot 4.7.1 and **2264 / 2264 ALL PASS**. This is E1/E2 runtime
evidence.

Godot is unavailable in the ChatGPT audit environment, so the suite was not
independently rerun. ChatGPT independently inspected the exact V04 commit,
production ColorCandidateIndex, both V04 test doubles, the V04 adversarial test
block, preserved V03/V02 tests and immediate M15/M14 consumer assumptions as E3
source/diff evidence.

## V04 improvements accepted

V04 correctly fixes several remaining F-M13-STRICT-001 branches:

- bind(null) now neutralizes stale state;
- ordinary bind failures now share one fail-closed policy;
- accepted board dependency category is narrowed to RefCounted + required API;
- method-compatible Nodes are rejected;
- live sync non-bool is_valid_index return neutralizes;
- live non-int state neutralizes;
- ACTIVE/CLEARED non-int or negative color returns neutralize;
- negative get_cell_count is directly rejected;
- transactional build directly covers non-bool/false is_valid_index, state
  corruption and color corruption after earlier valid indices;
- V03 unknown-state and exclusion fixes remain present.

BoardState remains unchanged.

## Remaining F-M13-STRICT-001 defects

### F-M13-STRICT-001.E — V04 sensitivity test misclassifies an in-range false as a healthy invalid caller index

The V04 test says:

```gdscript
var hdbl := M13MalformedBoardDouble.new() # count = 4
...
hdbl.invalid_index_false_at = 2
_check_eq(hix.sync_cell(2), false, "healthy invalid index")
_check(hix.is_bound(), "healthy invalid index leaves binding intact")
```

But with count = 4, index 2 is inside the declared domain 0..3.

The dependency therefore says two contradictory things:
- get_cell_count() says index 2 exists;
- is_valid_index(2) says it does not.

That is dependency truth corruption, not a healthy caller mistake.

Production currently treats ANY boolean false from is_valid_index() as harmless:

```gdscript
if not valid:
    return false
```

So this sequence remains possible:

```text
bind board with indexed cells [0..3]
dependency later reports is_valid_index(2) == false
sync_cell(2) -> false
index remains bound
old cached candidate 2 remains queryable
```

This violates the live-drift requirement that stale cache must not remain
authoritative after dependency truth becomes contradictory.

Required distinction:
- caller index outside the successfully indexed domain -> false, healthy cache
  remains;
- caller index inside the successfully indexed domain but live dependency now
  rejects it -> dependency drift, neutralize/fail closed.

The implementation needs to retain the successfully indexed cell-count/domain
(or equivalent immutable domain truth) from transactional build so sync can
make that distinction without a full rescan.

### F-M13-STRICT-001.F — dependency count has no production maximum bound

The full strict attack-surface includes max-size/boundary validation.

Current _scan() accepts every non-negative integer count:

```gdscript
if typeof(count) != TYPE_INT or count < 0:
    return null
for i in count:
    ...
```

The project production maximum is 59x59 = 3,481 cells. A malformed duck-typed
RefCounted dependency can return a huge positive count and force an unbounded
scan before M13 rejects anything.

Examples:
- 3,482;
- 1,000,000;
- very large integer.

This is a dependency-boundary/performance-safety defect inside the already
frozen F-M13-STRICT-001 finding.

Required:
- explicitly reject count > 3,481 before iteration;
- 3,481 remains accepted;
- 3,482 rejected;
- a much larger count rejected without per-cell traversal;
- rejection leaves unbound/empty and no partial buckets;
- valid 59x59 real BoardState path remains green.

## Frozen finding status

- F-M13-STRICT-001 — **OPEN**
- F-M13-STRICT-002 — **source-accepted**
- F-M13-STRICT-003 — **source-accepted**

No new finding ID is created. Both remaining issues are dependency-contract
closure inside F-M13-STRICT-001.

## Full post-fix sweep result

No additional M13-owned material defect was found in:
- bind(null) neutralization;
- RefCounted lifecycle category;
- malformed method-shape rejection;
- transactional local bucket commit;
- unknown-state handling;
- exclusion normalization;
- query result detachment;
- valid ACTIVE/CLEARED sync;
- rebuild/rebind;
- deterministic ordering;
- rectangular/59x59 correctness;
- steady-state no-rescan path;
- immediate ReservationState PackedInt32Array consumer;
- M14+/M15 architecture separation.

## Governance

Commit 227fd9a changes only:
- ColorCandidateIndex;
- tests/run_tests.gd;
- two M13 test doubles;
- matching CLAUDE_LOG_V04.md.

BoardState and ChatGPT-owned governance surfaces remain untouched.

## Verdict

**CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**

Keep open:
- SB-M13-001
- SB-M13-004

Progress remains:
- Ecosystem: **272 / 943 = 28.84%**
- Main + UI: **272 / 719 = 37.83%**
- Level Factory: **0 / 112**
- Content Pipeline: **0 / 112**

Next:
`coordination/sessions/M13-C001/CHATGPT_PROMPT_V05.md`
