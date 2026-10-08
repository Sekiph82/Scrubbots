# SB-M43-C005F-014 — Explicit DO-NOT-USE plugin boundary — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE1 (child 4 of 4)
- Starting SHA: `593f0f6d4216889f52d40ab410f54b56c232e616`
- Final SHA: the Phase 1 implementation commit (see master log)
- Final child state: **COMPLETE — AWAITING AUDIT**
- Sync: see the F001 log.

## Red lines encoded

**Reachability.**
- Only the GFF effect `punch_scale` and the Spark presets `spark`, `pickup` and `confetti` can be reached, and only through `scripts/ui/feel/feedback_adapter.gd`.
- The installed plugin *does* contain the prohibited effects. Test b02 proves that `camera_shake`, `camera_flash`, `freeze_frame`, `time_scale`, `impulse` and `velocity` exist in the install, so it is the allow-list, not their absence, that blocks them.
- Not reachable in V1 (FULL and REDUCED):
  - `camera_*`, `flash`, `freeze_frame`, `time_scale`, `pause`;
  - `impulse`, `velocity`, physics bodies;
  - `particles`, `gpu_particles`, `sound`, `audio_volume`, `method`, `signal`, `event`, `animator`, `tween`;
  - `shake*`;
  - every hit/death/explosion combo and the flashing `ui_*` combos.
- The installed `punch_scale` is confirmed to be an element-local scale target with `loop_count` 0 and `restore_after_play`.

**Authority.** GameFeelFlow and Spark own none of the following:
- SafeAreaRoot;
- NavigationController;
- ModalStack, BasePopup or pending tokens;
- BoardState, candidates, reservations, TargetSelector, routing, supply, slots, solver, collision or terminal truth;
- economy, rewards, save, progression, Hearts or timers;
- the Home Scrubby frame animation;
- audio or haptics;
- rewarded-ad or IAP callbacks.

**Success truth.**
- The adapter never reads a plugin return value or plugin signal.
- `play()`'s boolean depends only on intent, target and key, so Spark/GFF can never decide hit, clear, reward or success.

## Enforcement (tests/m43_c005f_phase1_foundation.gd)

- **b01 (static boundary):** 60+ authority scripts are scanned for any plugin word, `FeedbackAdapter`, `feedback_adapter` or `.feel`. The scan covers:
  - `scripts/economy`, `gameplay`, `save`, `progression`, `collection`, `settings`, `audio`, `haptics`, `difficulty`, `content_runtime` and `data`;
  - NavigationController, AppState, ModalStack, BasePopup, SafeAreaRoot and HomeScrubbyHero.

  The scan comes back clean. Test a01 additionally proves that no shipping script outside the adapter names either plugin.
- **b02 (reachability):** allow-list ∩ prohibited = ∅. The installed `punch_scale` is a scale target with no loop and restores after play.
- **b03 (adapter code red lines):** the adapter's code, with comments stripped, contains none of:
  - `Engine.time_scale`, `time_scale`, `freeze_frame`, `camera_`, `.paused`, Camera2D/3D, RigidBody, CharacterBody, `apply_impulse`, `velocity`, `change_scene`, `play_global`;
  - a global `Spark.clear`/`spark.clear`/`stop_all(null)`/`stop_all()`;
  - plugin signals, `listen`, `request_save`, `grant(`, `navigate`, `_modals`, `set_reduced`.

  It has exactly two connects (the settings signal and its own expiry timer). It never assigns or awaits a plugin result. Its only `queue_free` is on bursts it spawned.
- **b04 (plugin removal):** with both autoloads removed, the real app boots to HOME, launches the frontier level, commits WON with first-clear and a save, and routes to RESULTS. Adapter calls remain harmless no-ops.
- **a04 (fault injection):** a plugin that throws never reaches the caller.
- The legacy lane suite `tests/m43_master_c005f_feel.gd` f07–f10 keeps the earlier static and removal guards: 10/10 PASS.

## Files changed

There is no production code beyond the adapter (F002). The guards live in `tests/m43_c005f_phase1_foundation.gd`.

## Blockers / deviations

- The DO-NOT-USE list is enforced as an allow-list plus a static scan. It is not enforced by removing prohibited effect files from the third-party addon. The addon stays byte-identical to the MIT upstream install, which keeps license and attribution clean and leaves future upgrades diffable.
