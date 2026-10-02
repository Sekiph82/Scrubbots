# Real Web export

- Templates: `%APPDATA%/Godot/export_templates/4.7.2.stable` (version.txt `4.7.2.stable`; official `Godot_v4.7.2-stable_export_templates.tpz`, web templates only extracted).
- Preset: local gitignored `export_presets.cfg`, preset `Web` (export_filter all_resources; exclude_filter coordination/*, tests/*, tools/*, docs/*, level_factory/*, content_pipeline/*, assets/ui/generated/*, assets/art/references/*; thread support off). Not committed.
- Strict source gate immediately before: `strict_pre_export_gate.md` (m42_assets + maintenance suite, exit 0).
- Command: `godot --headless --path . --export-release "Web" "<scratch>/web_export_c001/index.html"`
- Start/end (UTC): 2026-10-02T09:43:43Z / 2026-10-02T09:43:52Z, exit 0.
- Output (scratch directory outside the repo, not committed): index.html, index.js, index.wasm (39514754 B), index.pck (398053860 B, sha256 `58b350b3234d0f8af81e5d0ade14e688ac9428c2fd647d243b42dac423342bfd`), audio worklets, icons.
- The pack contains imported textures + remaps, not raw source PNGs: the exported runtime reports `raw_source_png_present: false` for `assets/ui/final/characters/scrubby/scrubby_home_pose.png`.
- Diagnostic enablement (test harness only, scratch output): the exported `index.html` start arguments were changed from `"args":[]` to `"args":["--","--home-asset-diagnostics"]`, which makes HomeScreen print one `HOME_ASSET_DIAG` JSON line. Without that argument the seam is inert.
