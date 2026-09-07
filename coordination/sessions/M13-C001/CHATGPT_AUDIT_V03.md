# M13-C001 — ChatGPT Independent Audit V03

Decision: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**

Audited implementation commit:
`50f1f6c2b9d5f2bab082de2a8ada0c6d548cb4a6`

Prompt:
`coordination/sessions/M13-C001/CHATGPT_PROMPT_V03.md`

Criteria:
`coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

Claude log:
`coordination/sessions/M13-C001/CLAUDE_LOG_V03.md`

Frozen basis:
`coordination/sessions/M13-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`

## Independence / runtime disclosure

Claude reports Godot 4.7.1 and **2203 / 2203 ALL PASS**. This is E1/E2 runtime
evidence.

Godot is unavailable in the ChatGPT audit environment, so the suite was not
independently rerun. ChatGPT independently inspected the exact implementation
commit, production ColorCandidateIndex, malformed-board double, current M13
tests, immediate TargetSelector/ReservationState consumer assumptions and the
post-fix public attack surface as E3 source/diff evidence.

## What V03 successfully closes

### F-M13-STRICT-002 — implementation CLOSED

Unknown/noncanonical state handling is materially corrected:
- sync_cell explicitly distinguishes ACTIVE and CLEARED;
- 2/-1/255/99 trigger false + cache neutralization;
- initial transactional build rejects unknown state;
- rebuild rejects unknown state and neutralizes;
- canonical restoration permits recovery.

The old ACTIVE/else-CLEARED fallthrough no longer exists.

### F-M13-STRICT-003 — implementation CLOSED

The exclusion seam is materially hardened:
- Array supported;
- PackedInt32Array supported;
- Dictionary keys supported;
- null explicitly means no exclusion;
- unsupported containers return conservative empty/false/0 results;
- only TYPE_INT entries enter the exclusion set;
- float 2.0 and String "2" cannot exclude integer 2;
- invalid entries do not mutate cache;
- real ReservationState PackedInt32Array consumer remains correct.

### F-M13-STRICT-001 — PARTIALLY CLOSED, remains OPEN

V03 adds a transactional build, narrow API method checks and return validation
during _scan(). Most malformed initial-bind cases now fail safely.

However the complete dependency lifecycle is not yet fail-closed.

## Remaining full-surface defects/gaps

### F-M13-STRICT-001.A — bind(null) after a valid bind preserves stale usable truth

Current production:

```gdscript
func bind(board) -> bool:
    if board == null:
        return false
    if not _has_board_api(board):
        _neutralize()
        return false
    ...
```

The null path is the only ordinary bind failure that returns before
`_neutralize()`.

Therefore:

```text
bind(valid board)
→ cache/query truth live

bind(null)
→ false

BUT is_bound() remains true
AND prior candidates remain queryable
```

This contradicts V03's own documented contract:
- null bind fails closed to unbound/empty;
- ordinary malformed bind after valid state neutralizes prior state.

The V03 tests exercise fresh bind(null) and rebind(null), but not bind(null)
after an already valid binding. This is a sensitivity gap hiding a real
production defect.

### F-M13-STRICT-001.B — live sync dependency return drift can leave stale cache usable

V03 validates dependency return types during transactional bind/rebuild, but
sync_cell() handles several malformed live returns by merely returning false:

```gdscript
if not _board.is_valid_index(index):
    return false

var state = _board.get_cell_state(index)
if typeof(state) != TYPE_INT:
    return false

...
if typeof(color_id) != TYPE_INT or color_id < 0:
    return false
```

If a previously compatible dependency later becomes malformed:
- non-bool is_valid_index return;
- non-int cell-state return;
- non-int/negative color return;

sync_cell() can fail while the index remains bound and the old cached candidate
truth remains queryable.

For a malformed canonical dependency, returning false is not sufficient if stale
cache continues to present itself as authoritative current truth.

Required:
- distinguish a valid boolean false index result from malformed non-bool;
- malformed live dependency return must neutralize/invalidate the cache;
- valid out-of-range index still returns false without destroying a healthy
  cache;
- recovery through a later valid bind/rebind must work.

### F-M13-STRICT-001.C — build return-contract coverage is incomplete

V03 criteria require validation of every scanned index and ACTIVE color domain.

Source code does perform checks, but runtime tests do not directly attack:
- is_valid_index returning a non-bool;
- is_valid_index returning false for an index inside get_cell_count range;
- negative ACTIVE color id;
- negative get_cell_count.

These are explicit public dependency return boundaries and should be directly
proven before strict final closure.

### F-M13-STRICT-001.D — broad Object acceptance admits lifecycle-risk Node dependencies

`_has_board_api()` currently accepts any `Object` with the required method names.

Canonical production BoardState and the M13 traversal/malformed spies are
RefCounted. M13 does not require Node ownership.

A method-compatible Node can therefore be bound, externally freed, and leave
the index holding stale cached truth or an invalid object lifecycle.

This is the same class of dependency-lifecycle risk previously hardened in
strict foundation work.

Preferred correction:
- narrow accepted board dependency category to RefCounted + required narrow API;
- reject a method-compatible Node before binding.

Alternative Node support is acceptable only if every public cache/query path
detects invalid instance lifecycle and fails closed before exposing stale truth.
The narrower RefCounted contract is preferred because it matches the real
BoardState architecture and existing test spies.

## Full post-fix matrix result

No additional material defect was found in:
- exclusion normalization;
- query detachment;
- deterministic order;
- valid ACTIVE/CLEARED sync;
- transactional rebuild;
- valid rebind;
- cache no-rescan behavior;
- 59x59 correctness;
- reservation exclusion consumer;
- M14+ architecture boundaries.

The frozen finding set remains:
- F-M13-STRICT-001 — OPEN;
- F-M13-STRICT-002 — source-accepted;
- F-M13-STRICT-003 — source-accepted.

No new finding ID is created. The remaining issues are all part of the already
frozen dependency-boundary finding.

## Governance

Commit 50f1f6c changes only:
- ColorCandidateIndex production source;
- M13 tests;
- M13 malformed-board test double;
- matching CLAUDE_LOG_V03.

BoardState is unchanged. Claude did not modify tasks.md, H!veAI, coordination
indexes/queues or ChatGPT-owned artifacts and stopped at AWAITING_AUDIT.

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
`coordination/sessions/M13-C001/CHATGPT_PROMPT_V04.md`
