# M35-C001 V01 — ChatGPT Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M35-C001 V01**

Implementation: `6abe17c96f46b4b34906438b98c982bfd833b3a1`
Claude log: `coordination/sessions/M35-C001/CLAUDE_LOG_V01.md`

## Blocking finding F-M35-001 — catalog entries are not immutable
`get_entries_ordered()` duplicates only the Array, not its LevelCatalogEntry objects. `get_entry_by_id()` returns the internal entry object directly.

A consumer can mutate `id/order/path/difficulty/dimensions` and corrupt the catalog's canonical read model. The existing test only proves the returned Array container can be changed, not that entry objects are isolated.

This violates the read-only/immutable catalog contract.

## Blocking finding F-M35-002 — legacy dimension=difficulty gate remains in the production load path
`LevelCatalog.load_manifest()` calls `ProductionLevelValidator.validate(level)`.
That validator still enforces:
- EASY 20..29
- MEDIUM 30..39
- HARD 40..49
- VERY_HARD 50..59

The owner-locked Difficulty V1 explicitly supersedes that class=dimension legality model. As written, a legitimate 24x24 VERY_HARD or 38x38 EASY level cannot enter the production catalog.

M36's separate compatibility checker does not repair this because M35 rejects such entries first.

## Blocking finding F-M35-003 — integer order contract is too permissive
The catalog accepts TYPE_FLOAT for `order` and coerces with `int(order_value)`. Fractional order values therefore silently truncate instead of failing closed.

## Finding F-M35-004 — path alias normalization is incomplete
`_normalize_path()` collapses slashes and `/./` only. It does not canonicalize `..` segments. Alias duplicate detection can therefore be bypassed with path traversal-style equivalent paths where Godot resolves them.

## Required next step
M35 V02 must harden immutable entry ownership/order/path canonicalization. The class=dimension production-gate removal is coordinated with M36 V02 and must be regression-tested from M35 after M36 lands.

Verdict string:
`CHANGES_REQUIRED / M35-C001 V01 / CATALOG_HARDENING_REQUIRED`
