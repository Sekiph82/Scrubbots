# M40-C001 V03 — ChatGPT Full-Surface Re-Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M40-C001 V03 / FINDING_SET_FROZEN**

Implementation: `9665662`
Claude log: `coordination/sessions/M40-C001/CLAUDE_LOG_V03.md`

V03 materially improves the persistence architecture, but the actual shipping bootstrap/lifecycle is not yet canonical.

## Accepted V03 repairs

Independent source review accepts:
- AppState as a reusable single-graph composition object;
- canonical save path constant `user://scrubbots_save.dat`;
- explicit future-schema block state;
- raw version validation before migration;
- strict canonical haptics validation;
- post-M39 hardened nested import validation where M39 V03 is complete;
- service-level safe-write/recovery retained from V02.

## F-M40-V03-001 — AppState is still not the actual application bootstrap

`project.godot` still launches:
`res://scenes/app/main.tscn`

and `scripts/app/main.gd` remains the old board-core/debug screen.

It does not:
- instantiate AppState;
- inject AppState into ProductionGameplayHost;
- react to `AppState.is_blocked`;
- own app background/quit persistence.

The V03 tests instantiate AppState directly, so they prove the reusable object, not the real application entry path.

Required fix:
make the real app bootstrap own exactly one AppState and pass it into the shipping runtime/navigation flow.

## F-M40-V03-002 — loaded progression frontier is not mapped to canonical level content

When AppState is injected, host sets:
`progression_level = app_state.progression.current_level()`

but `level_path` remains the independent exported/default Hazard Bot path.

There is no LevelCatalog lookup proving that frontier N loads the catalog entry for N.

Therefore level 3 can still run level-1/Hazard-Bot content while rewards/difficulty/2x identify it as progression level 3.

This directly fails V03 criterion D.

Required fix:
resolve current frontier through LevelCatalog/canonical content mapping before gameplay build.
If content does not exist, fail with explicit CONTENT_MISSING/NOT_AVAILABLE rather than running stale content.

## F-M40-V03-003 — durable mutation save boundaries are a caller convention, not an application-owned lifecycle

V03 adds `AppState.request_save()` and host `request_save()`, and +1 Slot calls it.

But no authoritative production action layer currently guarantees save requests after:
- Daily/Gift/Collection claims;
- Cards Exchange;
- robot unlock;
- Heart/2x purchases;
- settings changes.

There is also no real app background/focus-loss/quit flush because the real bootstrap has not been wired.

The V03 criteria explicitly require those boundaries.

Required fix:
the app/action layer must own mutation + save request, and the real application root must flush dirty state on supported background/quit lifecycle events. No per-frame writes.

## F-M40-V03-004 — Daily canonical persistence is still blocked by unresolved production local-day wiring

M40 persists the new Daily fields, but M39 V03 still does not inject a real local-calendar provider in production.

Therefore M40 cannot claim final wall-clock/Daily persistence correctness until F-M39-V03-002 is closed and the end-to-end save/relaunch path is retested.

## Evidence/test gap

`m40_v03_canonical.gd::_progression_frontier_binds_host()` does not actually build a ProductionGameplayHost or resolve content. It only verifies the restored integer and comments that the host “would read” it.

The V03 direct-integration criterion required the actual composition/content path.

## Remaining task surface

Still open after V03 audit:
- SB-M40-002
- SB-M40-003
- SB-M40-005
- SB-M40-010
- SB-M40-013

Frozen finding set: **F-M40-V03-001..004**.

Verdict string:
`CHANGES_REQUIRED / M40-C001 V03 / F-M40-V03-001..004`
