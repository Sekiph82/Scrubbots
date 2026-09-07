# M13-C001 — Full Attack-Surface Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This is the canonical strict-v2 correction basis for current M13 and supersedes
the narrower CHATGPT_STRICT_REAUDIT_V01 correction scope.

The locked full attack-surface rule in coordination/AUDIT_POLICY.md requires a
complete subsystem sweep before a correction prompt.

## Current subsystem

Current production:
`scripts/gameplay/targeting/color_candidate_index.gd`

Historical M13 names such as EligibleTargetIndex are superseded by the
META-C004/current ColorCandidateIndex implementation.

## Sweep scope

ChatGPT independently inspected:
- current ColorCandidateIndex source;
- current BoardState source;
- complete current M13 test block;
- BoardState traversal spy;
- prior M13 V01/V02 artifacts;
- M13 task/spec/architecture boundaries;
- immediate downstream TargetSelector consumer;
- current FOUNDATION-STRICT-001 BoardState validation gap.

Godot is unavailable in the ChatGPT audit environment. Existing runtime totals
remain E1/E2. Findings below are E3 current-source/contract inspection.

## Public surface reviewed

- create();
- bind(board);
- rebind(board);
- rebuild();
- sync_cell(index);
- get_candidates(color_id, excluded);
- has_candidates(color_id, excluded);
- count_candidates(color_id, excluded);
- is_bound();
- is_bound_to(board);
- get_color_ids().

Attack classes considered:
- null;
- scalar/non-object Variant;
- partial API object;
- wrong-return API object;
- stale/mismatched board;
- unknown/noncanonical state;
- repeated bind/rebuild/sync;
- invalid index;
- malformed exclusion container;
- malformed exclusion entry;
- duplicate exclusions;
- detached result mutation;
- max 59x59;
- immediate downstream consumer assumptions.

## Frozen findings

### F-M13-STRICT-001 — BoardState dependency boundary is not fail-closed

Retained and expanded from CHATGPT_STRICT_REAUDIT_V01.

Current bind(board):
1. rejects null only;
2. stores `_board`;
3. sets `_bound = true`;
4. only then calls BoardState methods through _rebuild_internal().

A malformed non-null dependency can therefore fault after bound truth/state has
already been committed.

The full-surface issue includes:
- scalar/non-object Variants;
- RefCounted junk;
- partial API objects;
- wrong-return API objects;
- malformed bind after a previously valid binding;
- malformed rebind.

Required:
- validate the narrow BoardState API/return contract before committing usable
  bound truth;
- never call has_method or BoardState methods on unsupported scalar Variants;
- bind failure cannot leave a malformed object marked bound;
- malformed initial bind leaves safe unbound truth;
- malformed replacement cannot expose partially rebuilt buckets;
- rebind remains the explicit destructive fresh-board path;
- successful bind/rebind still supports the test traversal spy or an equivalent
  narrow compatible BoardState surface;
- direct adversarial doubles must prove no runtime call escapes.

At minimum M13 consumes:
- get_cell_count();
- is_valid_index();
- get_color_id();
- get_cell_state().

The build path must validate returned values sufficiently to prevent malformed
state from being committed as valid cache truth.

### F-M13-STRICT-002 — unknown cell state is silently mapped to CLEARED semantics

Retained from CHATGPT_STRICT_REAUDIT_V01 and expanded to every rebuild path.

Current sync_cell():
```gdscript
if state == ACTIVE:
    _bucket_add(...)
else:
    _bucket_remove(...)
```

Thus any state other than ACTIVE, including 2/99/corrupt/future enum values, is
silently removed as if CLEARED.

Current _rebuild_internal() has the sibling problem:
- ACTIVE -> add;
- every other state -> silently omitted.

Therefore bind/rebuild can also silently classify unknown state as non-candidate
truth.

Required:
- ACTIVE and CLEARED must be handled explicitly;
- any other state must fail closed;
- unknown state must never be silently treated as CLEARED;
- sync failure must not partially mutate unrelated buckets;
- full rebuild/build must be transactional: an unknown state cannot leave a
  partially rebuilt cache committed;
- after unknown-state failure, public queries must not present the unknown cell
  as confidently canonical ACTIVE/CLEARED truth;
- test both incremental sync and full rebuild/bind paths.

Use a test double/spy capable of injecting noncanonical state values. Do NOT fix
BoardState inside M13. FOUNDATION-STRICT-001 remains a separate cross-cutting
BoardState validation gap.

### F-M13-STRICT-003 — excluded/reserved query seam accepts arbitrary Variant containers/entries without a contract

New full-surface finding.

Current query APIs expose an untyped `excluded = []` parameter.

get_candidates()/has_candidates() call:
```gdscript
excluded.is_empty()
_to_set(excluded)
```

without first validating the Variant container.

Consequences:
- unsupported scalar/object containers may fault on is_empty()/iteration;
- String/other iterable-like values can enter a contract intended for cell
  indices;
- invalid entry types are inserted into the exclusion Dictionary without an
  integer-index domain gate;
- numeric cross-type keys such as float 2.0 must not be allowed to behave as
  integer index 2 by accidental Variant equality/hash semantics.

Existing accepted M13 semantics allow Array, PackedInt32Array and Dictionary-key
style exclusion input. Invalid negative/out-of-range integer entries simply have
no effect on valid candidate membership.

Required:
- explicitly define supported exclusion container classes;
- unsupported containers fail closed without runtime fault;
- supported containers accept only integer index entries;
- float/String/bool/Vector2/Object/nested container entries must not exclude
  integer candidates;
- duplicate integer exclusions remain harmless;
- negative/out-of-range integers remain no-effect;
- Dictionary support uses keys as exclusion indices and ignores values;
- malformed exclusion input cannot mutate cached truth;
- get_candidates/has_candidates/count_candidates obey the same normalization;
- production TargetSelector's PackedInt32Array reservation seam remains valid.

For unsupported container input, prefer conservative fail-closed query results:
- get_candidates -> [];
- has_candidates -> false;
- count_candidates -> 0.

## Accepted / not reopened

### Cache/performance
- initial full scan builds color buckets;
- steady-state query path does not rescan BoardState;
- traversal spy sensitivity remains strong;
- 59x59 correctness/performance evidence remains informational CPU/index only.

### Ordering / detachment
- candidate buckets remain ascending row-major;
- get_candidates returns detached Array;
- get_color_ids returns detached keys collection;
- repeated sync does not duplicate membership.

### Valid lifecycle
- ACTIVE sync adds;
- CLEARED sync removes;
- valid rebuild matches live board truth;
- valid rebind discards stale old-board candidates.

### Architecture
- M13 owns raw color candidate cache only;
- no reachability claim;
- no reservation ownership;
- no TargetSelector;
- no routing/pathfinding;
- no dispatch/agent behavior;
- no BoardState lifecycle redesign.

### Immediate consumer
Current TargetSelector obtains exclusions from ReservationState as a
PackedInt32Array and calls get_candidates(color_id, excluded). That supported
production path must remain valid.

## Repeated bind note

The sweep considered repeated bind/re-entry. ColorCandidateIndex owns only
derived cache state, not ephemeral reservation/assignment ownership. Current
valid repeated bind behaves as a deterministic replacement rebuild and does not
by itself lose independent gameplay ownership. It is therefore not frozen as a
material finding in this pass.

Malformed repeated bind/rebind remains covered by F-M13-STRICT-001.

## Frozen M13 finding set

Frozen to:
- F-M13-STRICT-001
- F-M13-STRICT-002
- F-M13-STRICT-003

Affected tasks remain:
- SB-M13-001
- SB-M13-004

No other M13 task is reopened.

Next:
`coordination/sessions/M13-C001/CHATGPT_PROMPT_V03.md`
