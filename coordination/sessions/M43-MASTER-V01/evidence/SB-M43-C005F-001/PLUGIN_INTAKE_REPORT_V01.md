# SB-M43-C005F-001 — Plugin intake / API / license report V01

Scope: verify the owner's local GameFeelFlow and Saltmire Spark installation against the TASKS planning assumptions
**before** any shipping call site exists. Read-only inspection of the owner-local, untracked `addons/` tree and
the owner-local (dirty) `project.godot`. Nothing was copied, committed, edited or removed.

## 1. Canonical repository state (origin/main)

- `addons/` is **not tracked**: no `addons/game_feel_flow/`, no `addons/saltmire_spark/` in git.
- Tracked `project.godot` has **no** `[autoload]` and **no** `[editor_plugins]` section.
- A clean clone therefore has neither plugin. No tracked SCRUBBOTS script references `GameFeelFlow` or `Spark`
  (the suites run in the owner working tree, where the autoloads boot but are never called).

## 2. Owner-local installation (working tree only)

| Item | Game Feel Flow | Saltmire Spark |
|---|---|---|
| `plugin.cfg` name / version | "Game Feel Flow" 1.0.0 | "Saltmire Spark" 1.0.0 |
| License | `addons/game_feel_flow/LICENSE` — MIT, © 2024 Game Feel Flow | `addons/saltmire_spark/LICENSE.txt` — MIT |
| Autoload (owner-local `project.godot`) | `GameFeelFlow="*uid://ckhnfaf1odnpl"` → `res://addons/game_feel_flow/core/game_feel_flow.gd` | `Spark="*uid://508k7axnakhr"` → `res://addons/saltmire_spark/spark.gd` |
| Registered by | `plugin.gd` `add_autoload_singleton` on enable | `plugin.gd` (guarded: only if absent) |
| Size | ~864 KB, 63 `class_name` scripts across both addons | ~24 KB, single `spark.gd` |
| Paid / Pro dependency | none found | none found |
| GdUnit / test dependency | none found | none |
| Demo / test material | `editor/test_scene_2d.gd` + `.tscn` (not referenced by any runtime script) | none |

The owner-local `project.godot` ALSO contains unrelated owner edits that are not plugin intake:
`_mcp_game_helper` autoload (`addons/godot_ai`, editor MCP tooling), `godot_ai` in `[editor_plugins]`, a removed
`[audio] buses/default_bus_layout` entry and a reordered `config/features` line.

## 3. Public API actually installed

**GameFeelFlow** (`core/game_feel_flow.gd`): `play(effect, target, params)`, `play_combo(combo, target, params)`,
`play_global`, `stop(target)`, `stop_all(node)`, `get_effect_names()`, `get_combo_names()`, `emit/listen/unlisten`,
`set_debug`; signals `effect_started`, `effect_finished`.
Registered names include: `punch_scale`, `punch_position`, `punch_rotation`, `scale`, `alpha`, `color`, `flash`,
`elastic`, `shake*`, `camera_shake`, `camera_flash`, `camera_zoom`, `camera_offset`, `camera_fov`, `freeze_frame`,
`time_scale`, `impulse`, `velocity`, `particles`, `gpu_particles`, `sound`, `audio_volume`, curved/tween/method/signal
helpers. Combos: `hit_*`, `death*`, `pickup*`, `explosion*`, `ui_button_press`, `ui_notification`.

**Planning mismatch:** the TASKS row expected `spring_scale` and `squash_stretch`; **neither exists** in the
installed 1.0.0. The closest installed effects are `punch_scale` and `elastic`. Any binding must use installed names.

**Spark** (`spark.gd`): `burst(global_position, opts)`, `at(node, opts)`, `clear()`; presets `spark`, `hit`,
`explode`, `pickup`, `dust`, `confetti`.

Prohibited categories present in the install (must stay unused per SB-M43-C005F-014): `camera_shake`,
`camera_flash`, `camera_*`, `freeze_frame`, `time_scale`, `impulse`, `velocity`, screen-wide flash.

## 4. Why intake cannot be completed by Claude in this run

Canonical intake requires committing the two addon trees AND autoload/plugin registration in the tracked
`project.godot`. The tracked `project.godot` is an owner-local file the master prompt requires to be preserved
and never committed. It is currently dirty with unrelated owner edits listed in §2. Committing plugin
registration would change a file the owner has modified locally, and committing `addons/` would collide with the
owner's untracked copies; a later `git pull` on the owner machine would be refused until the owner stashes
or moves those files. That reconciliation of owner-local files is an owner decision.

## 5. Owner decision needed

One of:
1. **Owner commits** `addons/game_feel_flow/` (optionally without `editor/test_scene_2d.*`), `addons/saltmire_spark/`
   and the two autoload + editor-plugin lines (without `godot_ai`); or
2. **Owner authorizes Claude** to commit exactly those paths plus a `project.godot` containing only the plugin lines
   on top of origin, and accepts stashing the local `project.godot` before the next pull.

Until then, the fail-open adapter (SB-M43-C005F-002) and the DO-NOT-USE boundary guard (SB-M43-C005F-014) are
the only C005F work that is safe: they run with the plugins absent and add no shipping call site.
