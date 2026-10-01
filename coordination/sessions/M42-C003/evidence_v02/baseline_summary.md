# M42-C003 V02 baseline

Repository: `Sekiph82/Scrubbots`, `origin/main` commit `fd232935b6fbd86a049dd5196a1f53c1cb8fdf29`.

Godot: `4.7.2.stable.official.ed1daf0bf`, Windows, headless. The clean worktree first needed a one-time asset import (`godot_console.exe --headless --editor --path . --quit`). The initial C002 probe before import could not load PNG import resources; it was rerun after import.

All commands used `godot_console.exe --headless --path . -s res://<test>` and exited 0 after import.

| Baseline script | Result |
|---|---:|
| `tests/m42_c002_scrubby_scale.gd` | 7/7 |
| `tests/m42_home.gd` | 19/19 |
| `tests/m42_home_composition.gd` | 9/9 |
| `tests/m42_home_v04.gd` | 18/18 |
| `tests/m42_home_v05.gd` | 13/13 |
| `tests/m42_home_v06.gd` | 13/13 |
| `tests/m42_home_v07_safe_area.gd` | 9/9 |
| `tests/m42_navigation.gd` | 12/12 |
| `tests/m42_opening.gd` | 8/8 |
| `tests/m42_assets.gd` | 4/4 |
| **Total** | **112/112** |

Raw command output is retained beside this summary in `baseline/`.
