# SB-M43-C005F-001 — Canonical plugin intake / API / license gate — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE1 (child 1 of 4)
- Starting SHA: `593f0f6d4216889f52d40ab410f54b56c232e616` (`origin/main`)
- Final SHA: the Phase 1 implementation commit (see master log)
- Final child state: **COMPLETE — AWAITING AUDIT**. Licenses are MIT, so there is no `BLOCKED_LICENSE_AUTHORITY`.

## Owner-local sync evidence

- Owner-local `C:/Users/sekip/Desktop/ScrubBots` (`main`) was 5 behind `origin/main`. I fast-forwarded it with `git merge --ff-only` to `593f0f6d`.
- Preserved owner-local state (untouched):
  - modified `project.godot`, `scenes/app/main.tscn` and the two owner-review `.tscn` files;
  - untracked `addons/` (including `godot_ai`), `.mcp.json`, art and `.uid`/`.import` files;
  - the pre-existing `stash@{0}`;
  - three Codex worktrees.
- `project.godot` overlaps owner-local edits, so I followed the safe rule: all canonical work was done in a clean TEMP worktree at exact `origin/main`, with the owner-local addon trees used only as **read-only** source.

## Actual installed plugins (owner-local source of truth)

| | GameFeelFlow | Saltmire Spark |
|---|---|---|
| Folder | `addons/game_feel_flow/` | `addons/saltmire_spark/` |
| `plugin.cfg` | name "Game Feel Flow", version **1.0.0**, `script="plugin.gd"` | name "Saltmire Spark", version **1.0.0**, `script="plugin.gd"` |
| Autoload | `GameFeelFlow` → `res://addons/game_feel_flow/core/game_feel_flow.gd`, registered by `plugin.gd::_enter_tree` via `add_autoload_singleton` | `Spark` → `res://addons/saltmire_spark/spark.gd`, registered by `plugin.gd`, **guarded** with `if not ProjectSettings.has_setting(...)` |
| License | `LICENSE`: MIT, Copyright (c) 2024 Game Feel Flow | `LICENSE.txt`: MIT, Copyright (c) 2026 Saltmire |
| Paid / Pro | `plugin.gd` and core only probe `res://addons/game_feel_flow_pro/...` behind `FileAccess.file_exists` (optional, absent) | README *mentions* the paid Impact layer; there is no code dependency |
| GdUnit / tests / demo | there is no `examples/` or `tests/` in the install. The only demo-like files are `editor/test_scene_2d.gd/.tscn`, which nothing references (grep). | there is no `demo/` in the install, even though the README mentions one |

**Public runtime API actually present**
- **GameFeelFlow:** `play(effect, target, params)` and `play_combo(combo, target, params)` (both coroutines); `play_global`, `stop(target)`, `stop_all(node=null)`, `register_*`, `get_effect`, `get_combo`, `resolve_combo`, `get_effect_names()`, `get_combo_names()`, `emit/listen/unlisten`, `set_debug`; signals `effect_started` and `effect_finished`.
  - 31 registered effects, including `punch_scale/position/rotation`, `shake*`, `curved_*`, `flash`, `color`, `alpha`, `camera_shake/zoom/fov/flash`, `sound`, `audio_volume`, `freeze_frame`, `time_scale`, `particles`, `gpu_particles`, `impulse`, `velocity`, `tween`, `animator`, `event`, `signal`, `method`, and the aliases `shake` and `punch`.
  - 15 combos: `hit_*`, `death*`, `pickup*`, `explosion*`, `ui_button_press`, `ui_notification`.
- **Spark:** `burst(global_position, opts)`, `at(node, opts)`, `clear()`; the `base` and `presets` dicts (`spark`, `hit`, `explode`, `pickup`, `dust`, `confetti`). All bursts are children of the internal Node2D `SaltmireSparkPool` and free themselves.

**Findings that differ from the TASKS planning assumptions and the previous M43-master adapter**

1. `spring_scale`, `squash_stretch` **and `elastic` do not exist** in GFF 1.0.0. The old adapter allow-listed `elastic`, so a WIN or MAJOR_UNLOCK request would have triggered a GFF "Effect not found" warning.
2. `GFFScaleTarget` drives **only Node2D/Node3D**. On a `Control` (all ScrubBots UI), `punch_scale` is a silent no-op; I measured this headless.
3. The `ui_button_press` / `ui_notification` combos run outside GFF's effect stack, so `stop_all(target)` cannot cancel them. They also embed an element `flash`.
4. `Spark.clear()` is **global**: it would kill every burst, not just the adapter's.
5. Measured `punch_scale` peak scale is about 1 + 0.51 × intensity. The elastic punch overshoots strongly, so intensities must stay small.

These findings drive the adapter design in F002/F013.

## Canonicalized into Git

- `addons/game_feel_flow/` is the complete runtime/editor plugin: `plugin.cfg`, `plugin.gd`, `core/`, `effects/`, `editor/`, `icons/*.svg`, `presets/`, `shaders/`, `LICENSE`, `README.md`.
  - **Excluded:** `editor/test_scene_2d.gd` and `.tscn` (unreferenced editor demo).
  - **Excluded:** all `*.uid` and `*.import` files. The repo does not track them, the addon's `.tscn`/`.tres` files reference scripts by `res://` path, and Godot regenerates them.
- `addons/saltmire_spark/`: `plugin.cfg`, `plugin.gd`, `spark.gd`, `LICENSE.txt`, `README.md`.
- 148 files in total. Each is byte-identical to the owner-local copy (verified with `diff -rq`, excluding `.uid`/`.import`/the test scene).
- Not copied: `addons/godot_ai/`, which is the owner's editor MCP tool, not shipping.
- Canonical `project.godot` adds **only** the following. Autoloads use `res://` paths, not the owner-local `uid://` form, so a clean clone resolves them.
  ```
  [autoload]
  GameFeelFlow="*res://addons/game_feel_flow/core/game_feel_flow.gd"
  Spark="*res://addons/saltmire_spark/spark.gd"

  [editor_plugins]
  enabled=PackedStringArray("res://addons/game_feel_flow/plugin.cfg", "res://addons/saltmire_spark/plugin.cfg")
  ```
- I kept the existing `[audio] buses/default_bus_layout` line and the `config/features` order. The editor/import step rewrites both on every run, which is the same drift seen in the owner-local file; I committed the minimal hand edit, not the editor rewrite.

## Owner-local follow-up (not done by Claude, documented)

The owner-local checkout cannot fast-forward past this commit while it holds untracked copies of the two addons and a modified `project.godot`. Git correctly refuses to overwrite them. A non-destructive owner sync is:
1. move or rename the local `addons/game_feel_flow` and `addons/saltmire_spark` (identical content);
2. set aside the local `project.godot` edits;
3. `git merge --ff-only origin/main`;
4. re-add the owner-only `godot_ai` autoload/plugin lines locally.

## Verification

Tests (`tests/m43_c005f_phase1_foundation.gd`):

| Case | What it checks |
|---|---|
| i01 | `plugin.cfg` name/version/script equal the audited constants, and `plugin.gd` registers the audited paths |
| i02 | the project autoloads resolve to the audited scripts (accepts `res://` or `uid://`); there is exactly one live instance of each singleton; each `editor_plugins` entry appears exactly once; Spark re-enable is guarded |
| i03 | MIT `LICENSE` texts and README attribution are present |
| i04 | there are no examples/demo/test/GdUnit files; no Pro/Impact/GdUnit addon; no unguarded Pro or demo reference |
| i05 | a harmless capability query through the adapter returns the real API and mutates nothing |
| i06 | an impostor or partially initialized autoload is treated as absent |

Project boot:
- Clean TEMP import: `godot --headless --path . --import` exits 0, prints "Game Feel Flow: Registered 31 effects", and builds the class cache (86 GFF entries).
- Headless boot: `godot --headless --path . --quit-after 600` exits 0 with "Game Feel Flow: Ready (31 effects, 15 combos)" and no script or parse errors.
- Plugin-absent boot (controlled seam b04): Home → gameplay → WON → Results → save all work.

## Blockers / deviations

None.

Import-time `ERROR` lines for `coordination/.../*.webp` evidence captures and `assets/ui/final/gameplay/buttons/icon_pause.png` are pre-existing asset-import issues. They are unrelated to this change and appear on any clean import.
