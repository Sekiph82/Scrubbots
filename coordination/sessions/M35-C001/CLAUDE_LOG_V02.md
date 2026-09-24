# M35-C001 V02 — Claude Remediation Log

V01 audit: `coordination/sessions/M35-C001/CHATGPT_AUDIT_V01.md`
(`CHANGES_REQUIRED / CATALOG_HARDENING_REQUIRED`; F-M35-001/002/003/004)
V02 prompt: `coordination/sessions/M35-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M35-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Fixes
- **F-M35-001 (immutable entries)**: `LevelCatalogEntry.duplicate()` added;
  `get_entries_ordered()` and `get_entry_by_id()` return deep copies. Mutating a
  returned entry (id/order/path/difficulty/dims) cannot corrupt the canonical
  read model.
- **F-M35-003 (integer order)**: order accepts exact integers only. JSON numbers
  arrive as int or float; an integral float (1.0) is accepted, a fractional
  value (1.5), NaN or INF fails closed.
- **F-M35-004 (path canonicalization)**: `_normalize_path` resolves `.` and `..`
  segments, collapses redundant slashes, and confines to the `res://` root.
  Dot-dot aliases resolving to the same file collide; escapes above root and
  non-`res://` paths fail closed.
- **F-M35-002 (class=dimension gate)**: fixed in M36 V02 (validator now envelope-
  based). Revalidated here: 24x24 VERY_HARD and 38x38 EASY enter the production
  catalog; TEST still rejected; M21 still valid.

## Tests
- `tests/m35_v02_hardening.gd` — immutable entries (field-level, not just Array),
  strict-int order, path canonicalization (dot-dot alias / escape / non-res),
  Difficulty-V1 acceptance, TEST rejection, M21 validity. **PASS**.
- Regression: `tests/m35_level_catalog.gd` updated (synthetic level files moved
  to `res://` per the new confinement) **PASS**; `tests/m36_v02_migration.gd`
  PASS; root suite 5336/0.

Note: `project.godot`'s `[audio]` bus-layout section is stripped by headless
runs that cannot load the bus `.tres`; it was restored with `git checkout` and
is unchanged in the committed tree.

## Task logs
`coordination/sessions/M35-C001/task_logs_v02/SB-M35-002,003,005,007,009,010,011`.

## Handoff
`AWAITING_AUDIT / M35-C001 V02`

Root `TASKS.md` not edited. Continuing to M37 V02.
