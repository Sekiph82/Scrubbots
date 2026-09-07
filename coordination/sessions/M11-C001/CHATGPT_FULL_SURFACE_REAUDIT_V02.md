# M11-C001 — Full Attack-Surface Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This supersedes the earlier M11 strict re-audit V01 as the canonical correction
basis.

Reason:
the locked audit policy now requires a full subsystem attack-surface sweep and a
frozen finding set before issuing a critical correction prompt.

## Sweep scope

ChatGPT inspected:
- GameplaySession public lifecycle/query/binding APIs;
- LevelData mutability/ownership;
- BoardState reset composition;
- BoardRenderer presentation seam;
- existing M11 lifecycle/renderer tests;
- immediate later gameplay consumers that require live BoardState access.

Godot is unavailable in the ChatGPT audit environment. Existing runtime evidence
remains E1/E2; findings below are E3 source/contract inspection.

## Frozen findings

### F-M11-STRICT-001 — mutable LevelData source ownership leak

Existing finding retained and expanded.

GameplaySession.get_level_data() returns the internally owned mutable LevelData.
LevelData exposes mutable scalar fields and packed arrays.

External code can therefore mutate session source truth and alter the next reset.

Required:
- session owns a detached internal LevelData copy after successful load;
- get_level_data() returns a detached snapshot/copy, never the internal object;
- mutating snapshot scalars, palette or cells cannot affect reset/source truth;
- failed replacement load still preserves the prior internal source and board;
- update old identity-based tests to value/source-truth assertions.

Do NOT make live BoardState read-only: later gameplay systems legitimately need
the session's current mutable runtime BoardState. This finding applies to source
LevelData, not runtime BoardState.

### F-M11-STRICT-002 — renderer dependency contract is not fail-closed

Existing finding retained.

bind_renderer() accepts arbitrary non-null values and _configure_renderer() later
calls configure() blindly.

Required:
- accept only a real BoardRenderer (exact script identity / robust BoardRenderer
  type check) or null for explicit unbind;
- malformed scalar/junk/partial renderer must never be stored or called;
- invalid replacement bind must not corrupt a prior valid session;
- direct null/int/String/Vector2/RefCounted/partial-object tests.

### F-M11-STRICT-003 — renderer size boundary accepts non-finite/invalid geometry

New full-surface finding.

available_size is typed Vector2 but may still contain NaN/INF or non-positive
geometry. BoardRenderer performs division/floor sizing and is not the right place
for session binding to inject invalid geometry.

Required:
- define a canonical finite positive renderer size contract;
- NaN/+INF/-INF/zero/negative dimensions fail closed or are deterministically
  sanitized before renderer.configure;
- invalid size must never poison renderer geometry;
- direct tests prove load/reset lifecycle still remains valid.

### F-M11-STRICT-004 — stale/freed bound renderer can fault future load/reset

New lifecycle finding.

GameplaySession stores a Node renderer reference. External code can free that
renderer while the session remains alive. A later reset/load calls
_renderer.configure() without checking instance validity.

Required:
- before every configure call, verify the stored renderer is still instance-valid;
- stale/freed renderer is safely dropped/unbound;
- load/reset lifecycle succeeds without presentation;
- direct bind -> free renderer -> reset and bind -> free renderer -> replacement
  load tests.

### F-M11-STRICT-005 — internal LevelData palette is handed directly across the presentation seam

New ownership finding related to F-001.

_configure_renderer() passes _level_data.palette directly. The session's
immutable source contract should not rely on a presentation collaborator never
retaining/mutating a passed packed array.

Required:
- pass a detached palette copy to renderer.configure;
- source palette remains unchanged after presentation configure/reconfigure;
- no full LevelData object is handed to renderer.

## Accepted / not reopened

No new material issue found with:
- lifecycle transition table;
- explicit completion only from ACTIVE;
- invalid transitions preserving state;
- reset creating a fresh BoardState;
- reset returning READY;
- failed level load preserving prior valid session;
- no automatic win/lose/timer/move-limit logic;
- headless RefCounted session core;
- live BoardState access as runtime gameplay truth;
- rectangular and 59x59 session domains.

## Frozen M11 finding set

Frozen to:
- F-M11-STRICT-001
- F-M11-STRICT-002
- F-M11-STRICT-003
- F-M11-STRICT-004
- F-M11-STRICT-005

Affected tasks remain:
- SB-M11-003
- SB-M11-005
- SB-M11-009
- SB-M11-012

Next:
`coordination/sessions/M11-C001/CHATGPT_PROMPT_V02.md`
