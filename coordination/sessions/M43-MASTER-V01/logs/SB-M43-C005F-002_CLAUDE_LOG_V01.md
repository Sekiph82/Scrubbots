# SB-M43-C005F-002 — CLAUDE LOG V01

Child: **SB-M43-C005F-002** — "One fail-open SCRUBBOTS feedback adapter + intensity policy (MICRO/SMALL/REWARD/MAJOR_REWARD/WIN/MAJOR_UNLOCK) so plugin calls are never scattered through economy/gameplay code."
Parent: M43-C005F — Game Feel Presentation Layer — GameFeelFlow + Saltmire Spark
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `18e2e31` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- TASKS SB-M43-C005F-002 seam: ephemeral presentation layer created from `scripts/app/main.gd::_ready()`, reading `EffectsSettingsService.changed`; never durable AppState authority.
- TASKS C005F intensity vocabulary + FULL particle ceilings MICRO 0 / SMALL 0–4 / REWARD 4–8 / MAJOR_REWARD 8–14 / WIN 12–18 / MAJOR_UNLOCK 16–24; Reduced removes Spark/motion.
- Installed API from `PLUGIN_INTAKE_REPORT_V01.md` (SB-M43-C005F-001).

## Implementation

| File | Change |
|---|---|
| `scripts/ui/feel/feedback_adapter.gd` | **new** the one gateway: autoload lookup at call time (absent = no-op), DEFERRED plugin calls, allow-listed installed names only, per-tier FULL/REDUCED plans with Spark amount capped at the tier ceiling, optional one-shot keys, live Reduced toggle → `stop_all` + `clear`, test-only spy seam |
| `scripts/app/main.gd` | creates exactly one adapter bound to the canonical EffectsSettingsService; **no call site** (bindings wait for SB-M43-C005F-001) |
| `tests/m43_master_c005f_feel.gd` | **new** lane suite (f01–f07) |

Fail-open by construction: a missing plugin is a no-op; every plugin call is `call_deferred`, so the caller's control flow always completes before any plugin code runs and a plugin error cannot propagate into it. Reduced Effects maps every tier to no plugin motion and zero particles.

## Tests

`tests/m43_master_c005f_feel.gd` → **PASS 7/7**: f01 tier table inside the TASKS ceilings, Reduced = nothing, ladder order; f02 REWARD dispatch happens only after the caller finished its frame, GFF `ui_notification` + Spark `pickup` with amount 8; f03 one-shot key refused on repeat, new key plays, exactly two dispatches; f04 absent plugins = no-op, bad intent/target refused, cancel harmless; f05 live Reduced toggle → `stop_all` + `clear`, Reduced dispatches nothing, returning to FULL replays nothing; f06 allow-list excludes every DO-NOT-USE category; f07 plugin names appear only in the adapter and `main.gd` creates exactly one instance.

## Regression

App-root change only adds an object: `m43_c003_c001_acquisition` 34/34 and C005 lane 32/32 PASS; lane checkpoint root run follows with SB-M43-C005F-014.

## Runtime evidence

Not player-facing (no call site, no visible change).

## Blockers / gates

Shipping bindings (C005F-003..013) remain DEFERRED until the owner resolves the canonical intake (C005F-001).

READY_FOR_INDEPENDENT_AUDIT — SB-M43-C005F-002
