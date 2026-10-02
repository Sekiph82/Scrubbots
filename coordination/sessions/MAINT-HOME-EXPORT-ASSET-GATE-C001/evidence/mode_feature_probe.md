# Mode / feature-tag probe

`HomeArtBinder.default_mode()` = `PACKAGED_RUNTIME if OS.has_feature("template") else SOURCE_TREE_STRICT`.

| Execution | Godot | template | editor | debug | web | Selected mode | Source |
|---|---|---|---|---|---|---|---|
| Local editor binary, headless (`godot --headless --path . -s res://tests/maint_home_export_asset_gate_c001.gd`) | 4.7.2-stable (official) | false | true | true | false | SOURCE_TREE_STRICT | `[automatic mode selector]` case in `strict_pre_export_gate.md` |
| Real Web export (release template 4.7.2.stable) in headless Chrome | 4.7.2.stable.official.ed1daf0bf | true | false | false | true | PACKAGED_RUNTIME | `exported_runtime/home_asset_diag.json` / `console.log` |

`template` is the documented feature present only in export templates, so the editor/source run can never select packaged mode and an exported build can never select strict mode.
