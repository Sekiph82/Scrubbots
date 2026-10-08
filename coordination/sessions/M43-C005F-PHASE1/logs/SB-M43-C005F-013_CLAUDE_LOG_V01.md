# SB-M43-C005F-013 — Canonical FULL / REDUCED matrix + live cancellation — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE1 (child 3 of 4)
- Starting SHA: `593f0f6d4216889f52d40ab410f54b56c232e616`
- Final SHA: the Phase 1 implementation commit (see master log)
- Final child state: **COMPLETE — AWAITING AUDIT**. The owner accessibility visual gate in TASKS is not claimed here.
- Sync: see the F001 log.

## Authority reused (no second setting)

- The canonical `EffectsSettingsService` (`app_state.effects`, persisted by the M40 SaveService as `settings.effects.reduced`) is the only Reduced Effects source.
- The adapter reads `is_reduced()` and subscribes to `changed`.
- It owns no ConfigFile, no `user://` file, and never calls `set_reduced` (test r06).

## Deterministic matrix

| Tier | FULL | REDUCED |
|---|---|---|
| MICRO | GFF `punch_scale` 0.08 on Node2D/3D; no particles | none |
| SMALL | punch 0.12 + Spark `spark` ×4 | none |
| REWARD | punch 0.16 + Spark `pickup` ×8 | none |
| MAJOR_REWARD | punch 0.20 + Spark `confetti` ×14 | none |
| WIN | punch 0.22 + Spark `confetti` ×18 | none |
| MAJOR_UNLOCK | punch 0.24 + Spark `confetti` ×24 | none |

- **REDUCED** means: no particles or confetti, no motion and therefore no looping, no flash, no camera or screen work. Static native UI, art, text and reward truth are left entirely to the caller, which is unchanged.
- **FULL** never uses flash, loops, camera or screen effects either; those are prohibited by F014 in both modes.
- REDUCED requests are still accepted and logged, and they consume their one-shot key, but they start no plugin work at all.

## Live cancellation

- FULL→REDUCED triggers `EffectsSettingsService.changed(true)`, which calls `cancel_all()`. Each adapter-owned dispatch is released:
  - the Spark bursts it spawned are `queue_free`d;
  - a targeted `GameFeelFlow.stop_all(target)` restores the punched node to scale 1;
  - a dispatch still deferred is dropped before it starts.
- There is **no** global `Spark.clear()` and **no** `stop_all(null)`. Test r03 shows that a foreign Spark burst, standing in for non-adapter state, survives the toggle.
- REDUCED→FULL replays nothing, because consumed keys stay consumed and there is no queue.

## Tests

`tests/m43_c005f_phase1_foundation.gd`:

| Case | What it checks |
|---|---|
| r01 | FULL and REDUCED rows per tier; an unknown intent has no row |
| r02 | **real plugins:** FULL gives 6 owned dispatches, 5 bursts and 68 particles (4 + 8 + 14 + 18 + 24); REDUCED gives 6 logged requests, 0 dispatches, 0 particles and a target that never moves. REDUCED is structurally and materially cheaper. |
| r03 | **real plugins**, live toggle mid-MAJOR_UNLOCK: nothing is left owned, the punched target is restored, and only the adapter's burst is freed |
| r04 | a key consumed under REDUCED is refused after returning to FULL; nothing plays retroactively |
| r05 | missing plugins are safe in both modes, including toggle and cancel |
| r06 | the real app root's adapter follows `app_state.effects` |

**Legacy lane suite.** `tests/m43_master_c005f_feel.gd` was updated to the canonical contract:
- f02 now expects GFF `punch_scale` on a Node2D target. It checks only the first call, because a headless frame hitch can legitimately fire the bounded expiry inside one frame.
- f05 now expects a targeted `stop_all(target)` and no global `clear`.
- f09 now expects two connects: the settings signal and the adapter's own expiry timer.

The result is 10/10 PASS.

**Runtime visual evidence** (real plugins, rendering): `coordination/sessions/M43-C005F-PHASE1/evidence/tiers_full.png` and `tiers_reduced.png`. FULL shows Spark bursts scaling with the tier and punched badges; REDUCED shows the identical static badges with no particles.

## Blockers / deviations

None.
