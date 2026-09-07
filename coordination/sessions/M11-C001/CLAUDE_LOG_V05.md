# M11-C001 — CLAUDE_LOG_V05

Cycle: M11-C001
Prompt: CHATGPT_PROMPT_V05.md (Frozen Full-Surface Session-Core Closure V05)
Criteria: CHATGPT_AUDIT_CRITERIA_V05.md
Handoff state: **AWAITING_AUDIT**
Base commit (synced origin/main): `e6f814ced777e6259d2204e181f360968d213a4e`

## Scope

Fixed ONLY the frozen M11 finding set
(F-M11-STRICT-001..005 from CHATGPT_FULL_SURFACE_REAUDIT_V02.md).
No M12+ gameplay features added. Governance files untouched.

## Sync

First action: safe fast-forward of local `main` to `origin/main`
(14 commits, `1f95842..e6f814c`), `git merge --ff-only`. Pre-existing owner
working-tree changes (`project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
`scenes/debug/scrubbot_agent_debug.tscn`) were preserved untouched and NOT
staged — none conflict with upstream. No destructive sync used.

## Changes

### scripts/gameplay/session/gameplay_session.gd

- **F-001 (LevelData source ownership):** session now owns an internal DETACHED
  LevelData copy built via new `_duplicate_level_data()` (duplicates packed
  palette + cells). `load_level()` builds BoardState from the internal copy, not
  the loader's object. `get_level_data()` returns a fresh detached snapshot each
  call (null when uninitialized). Hostile mutation of a snapshot's
  scalars/palette/cells (incl. in-place packed-array edits) cannot alter source
  truth or the next reset. Failed replacement load still early-returns before any
  mutation, preserving prior source + BoardState identity.
- **F-002 (renderer binding fail-closed):** `bind_renderer()` returns `bool`.
  `null` explicitly unbinds (true). Non-null accepted only if `_is_real_renderer`
  (typeof==Object, is_instance_valid, `is BoardRenderer`) — rejects
  int/String/Vector2/RefCounted junk/partial fake without storing or configuring;
  invalid replacement preserves a prior valid binding.
- **F-003 (renderer size contract):** `_is_valid_size()` requires finite
  (`is_finite`) and strictly positive x/y. Policy = **reject** (invalid bind
  returns false, preserves prior valid renderer/size). NaN/±INF/zero/negative
  never reach `renderer.configure`.
- **F-004 (freed/stale renderer):** `_configure_renderer()` checks
  `is_instance_valid(_renderer)` before every configure; a freed renderer is
  dropped (binding cleared) and the session continues headlessly. load/reset
  succeed after external free.
- **F-005 (palette aliasing):** configure receives `_level_data.palette.duplicate()`;
  the LevelData object is never passed to the renderer.
- Docstring corrected (immutable-reference → detached-source-copy wording).

Existing callers that ignore the `bind_renderer` return value are unaffected.

### tests/run_tests.gd

- M11-07 rewritten from object-identity to value/source-truth assertions
  (snapshots are now distinct objects).
- New adversarial coverage: M11-29 (detached source ownership + reset after
  hostile snapshot mutation), M11-30 (malformed renderer rejection + fake never
  called), M11-31 (NaN/±INF/zero/negative size rejection), M11-32 (freed
  renderer reset + replacement load), M11-33 (palette copy isolation via spy).

### tests/support/fake_renderer.gd (new)

Partial fake exposing `configure()` but not a BoardRenderer — must be rejected.

### tests/support/palette_spy_renderer.gd (new)

Real BoardRenderer subclass recording the palette it was handed, to prove the
session passes a detached copy.

## Validation (Godot 4.7.1.stable.official.a13da4feb, headless)

- `godot --version` → `4.7.1.stable.official.a13da4feb`
- `godot --headless -s res://tests/run_tests.gd` → **Total checks: 1835,
  Failures: 0, RESULT: ALL PASS**
- `git diff --check` → clean (only benign LF→CRLF warnings, no whitespace errors)

## Governance

Not modified: `tasks.md`, `.hiveai/*`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, any ChatGPT audit/re-audit file, strict
sequence/queue controllers. No self-audit written. Independent Godot rerun
available to ChatGPT.

Return: **AWAITING_AUDIT**
