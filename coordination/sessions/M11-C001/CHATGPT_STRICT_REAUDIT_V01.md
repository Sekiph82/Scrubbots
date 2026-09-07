# M11-C001 — Strict Re-Audit V01

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Strict-v2 inspection of the current GameplaySession and LevelData contract.

Godot is not available in the ChatGPT audit environment. Existing green runtime results remain E1/E2; findings below are E3 source/contract inspection.

## F-M11-STRICT-001 — session exposes mutable "immutable" LevelData truth

Severity: **material state-ownership defect**

GameplaySession.get_level_data() returns the internally owned _level_data object directly.

LevelData itself exposes public mutable fields including width, height, palette and cells. Therefore external code can obtain the session-owned source object, mutate it, and later reset() will rebuild BoardState from mutated source truth.

This violates M11's locked contract that the session preserves immutable LevelData source truth and reset recreates runtime state from that immutable source.

Required correction:
- do not expose a mutable internally owned LevelData reference;
- use a detached snapshot/read-only query surface or make the underlying representation truly immutable at the public boundary;
- add a regression that mutates whatever public query result is returned and proves reset source truth cannot be changed externally.

Affected:
- SB-M11-003
- SB-M11-009
- SB-M11-012

## F-M11-STRICT-002 — renderer binding does not validate the narrow dependency contract

Severity: **boundary robustness defect**

bind_renderer(renderer) accepts any non-null object and _configure_renderer() later calls renderer.configure(...) without checking that the required narrow API exists.

Required correction:
- fail closed or reject malformed non-null renderer dependencies before storing/using them;
- preserve null as the supported unbind path;
- add malformed non-null dependency coverage proving no runtime call escapes.

Affected:
- SB-M11-005
- SB-M11-012

## Strict task state

Reopen:
- SB-M11-003
- SB-M11-005
- SB-M11-009
- SB-M11-012

Other M11 task truth remains accepted.
