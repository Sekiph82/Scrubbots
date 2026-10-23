VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (clean)
python -I tools/m22_026_apply_caps.py <measure_merged.json> (dry run): pass, ends "would cap 0 texture(s)"
Godot suites: not run (reviewer-tests owns them)

## Findings
None.

## Notes
- Measure scenarios: each boots through `_boot`, which uses a unique throw-away `user://` save path via `boot_save_path_override`. `_shutdown` runs between scenarios and `_cleanup` removes the `.save/.bak/.tmp` files at the end. A crash mid-run would leave them behind, which matches step 2.
- `_popup` closes every popup it walks, and a push refusal frees the popup. `_note` appends reasons, so the skipped list stays readable. Ranks, opening and robot_detail (scrubby unlocked) are recorded with reasons.
- The merge is a per-path max of `max_side_px` across scenarios, which is correct. The step 2 merge via the python script was checked by the builder (144 keys all >=).
- Budget additions: 7 new groups; MEASURED has the 45 new caps plus the 2 raised to 1024. Shop/Collection 39.98/41 is a tight budget (about 2.5% headroom) but deterministic, so it is fine.
- Header doc comment of the measure tool has one over-long line (cosmetic).
