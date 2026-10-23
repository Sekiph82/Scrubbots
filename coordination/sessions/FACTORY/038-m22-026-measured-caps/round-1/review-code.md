VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass
git diff --stat scope (no PNG, only .import under assets/ui/final, tool, script, test, docs, TASKS.md, measure_merged.json): pass
python -I tools/m22_026_apply_caps.py measure_merged.json (dry run on the post-cap tree): pass, "would cap 0 texture(s)" (idempotent; every row is keep/skip)
Godot suites: not run (reviewer-tests)

## Findings
None.

## Notes
- Measure tool: scale math matches m49 `_logical` (phys.x / logical.x), uses boot_save_path_override per boot, resets it in _shutdown, removes .save/.bak/.tmp in _cleanup. TextureButton covers normal/pressed/hover/disabled/focused, AtlasTexture unwrapped, size-0 nodes kept as "loaded, size 0", nodes found via get_children(true) from the SubViewport so popups are covered.
- Control.get_global_rect ignores node/ancestor scale, so textures drawn under a pop/settle tween (results rows, base_popup chrome scale, home micro-feel, up to a few percent) are measured slightly small. The 2x factor and the 512 floor absorb this; no action.
- For an AtlasTexture the node size is the region size but the cap applies to the whole atlas file, which would under-measure. Only results_screen builds AtlasTexture (next-puzzle preview, not a res://assets/ui/final path), so it has no effect today.
- apply_caps keeps any existing nonzero limit even when it is larger than the new computed one (heart_large 1024 vs 512). This is conservative and documented in the docstring. The decision text "UI-ADR-007 / step 1" is also printed for step-2 caps on a re-run; cosmetic.
- Budget test: added shell/popup-frame/reward_glow/bot_parts paths because the measurement showed them, with a comment saying so; MEASURED list has 45 entries equal to the new .import files; step-1 checks kept.
