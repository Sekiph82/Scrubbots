# Exported-runtime proof

Runner: `tools/web_export_runtime_probe.py` — real headless Chrome (`--headless=new`, SwiftShader WebGL2) via the DevTools protocol, 430x860 CSS px at DPR 2, loading the export served from `http://127.0.0.1:8061/` (local only). Files in `exported_runtime/`.

From the exported runtime itself (`home_asset_diag.json`, also the `HOME_ASSET_DIAG` line in `console.log`):

| Fact | Value |
|---|---|
| Engine | Godot 4.7.2.stable.official, Emscripten 4.0.20, WebGL 2.0, Compatibility renderer |
| Feature tags | template=true, editor=false, debug=false, web=true |
| Binder mode | PACKAGED_RUNTIME |
| Raw HOME-026 source PNG in the pack | false |
| Strict source gate would pass inside the pack | false (the original blank-Home failure condition) |
| Manifest valid in packaged mode | true (no MANIFEST_INVALID) |
| Mapped Home nodes with approved art | 24 / 24, unbound [] |
| WorldBackground (Home background) | bound |
| Art_scrubby (HOME-026) | bound |
| ShortcutIcon_shop / collection / tasks / daily, NavIcon_*, chips, Gift, track | bound |
| HomeScrubbyHero.has_frames() | true |
| Animation counts | wave 14, bow 15, turn 17, full_turn 17 |

`home_screenshot.png` is the headless-Chrome capture after the opening video (`[OPENING_METRICS] ... completed:finished`) of the exported Home: background, Scrubby, all four shortcut icons, HUD/Gift/track/nav art present. Console: no errors or exceptions.
