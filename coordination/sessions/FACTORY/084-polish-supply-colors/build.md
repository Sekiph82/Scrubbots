STATUS: READY

# Build: Supply preview rows show original batch colours

## Summary
`BatchSupplyPanel._bind_row` no longer dims preview rows: every row's panel `modulate` is `Color(1,1,1,1)`, so rows 1..3 show the exact canonical batch colour. The only front-row affordance is the existing cyan rim from `set_active(front)`. Nothing else was added. Preview rows still have no rim and still take no input (mouse IGNORE, no gui_input connections). I also fixed the stale "dimmed" and "presentation dim" comments.

Commits on `factory/084-polish-supply-colors`: `d9f05a8c` (code + tests), `e95490af` (TASKS.md).

Files changed:
- `scripts/ui/batch_supply_panel.gd`: dim removed, comments fixed.
- `tests/m28_c002_c004_tile_visual.gd`: c05 now asserts that front and preview differ by `is_preview()`/`is_active_style()` and that both modulates are white. It also has the new canonical-colour assertion for preview rows 1/2: face StyleBoxFlat `bg_color`, `get_face_color()` and panel modulate exactly white.
- `tests/m28_c002_c001_gameplay_v02.gd`: preview-rows check now requires modulate white, preview style and no rim. "Dimmed" wording removed.
- `tests/m28_c002_c002_r01_visual.gd`: not named in the spec, but it asserted the exact dim colour `Color(0.62,0.62,0.70,0.85)` and would fail without the change. It now asserts white.
- `tests/tools/m28_c004_tile_evidence.gd`: not named in the spec. This evidence tool copied the dim onto its preview sample. I removed those 2 lines so its output matches the runtime.
- `TASKS.md`: queue row moved to DONE, and the `- [x]` entry carries the evidence.

No doc says preview rows are dimmed. I grepped `docs/`, AGENTS.md and README for preview/row together with dim/desaturat and found nothing, so no doc edit was needed.

## Acceptance criteria
1. [x] `grep -n "0.62, 0.62, 0.70" scripts/ui/batch_supply_panel.gd` returns nothing. The pattern also no longer appears anywhere in scripts/ or tests/.
2. [x] `$GODOT --headless --path <wt> -s res://tests/m28_c002_c004_tile_visual.gd`: exit 0, `M28-C002-C004 color/batch tile visual: PASS (17/17 cases, 0 fail)`, 0 SCRIPT ERROR/Parse Error. This includes `ok: preview rows 1/2: face bg == canonical batch colour, panel modulate exactly white/opaque`.
3. [x] `$GODOT --headless --path <wt> -s res://tests/m28_c002_c001_gameplay_v02.gd`: exit 0, `PASS (14/14 cases, 0 fail)`. This includes `ok: only fronts receive input; preview rows IGNORE, unconnected, original colour (no dim, no rim)`.
4. [x] Revert check: I temporarily restored the dim line in `_bind_row` and reran c004. Result: exit 1, `FAIL (17/17 cases, 2 fail)`. Both the c05 front/preview modulate assert and the new preview canonical-colour assert failed. The file was then restored, and the grep count of the dim colour is 0.
5. [x] Capture: `evidence/supply_capture_level22_1080x2160.png` (1080x2160, Level 22 crab, fresh state). It was made with `evidence/supply_capture.gd`, a scratch script that copies the `gameplay_v02_final_snapshot.gd` pattern. It ran without `--headless` on a temp `user://` save via `boot_save_path_override`; the save was deleted afterwards and the real save was never used. It shows the owner's case: in column 2, the "8" orange (row 3, under the "14" white) has exactly the same orange as the "16" front tile in column 5. Only the front row has the cyan rim. Probe log from the run (face colour per row, modulate, rim):
   - col 1: `[000000 20 rim=true] [ff4500 23 rim=false] [000000 11 rim=false]`
   - col 2: `[000000 21 rim=true] [ffffff 14 rim=false] [ffa800 8 rim=false]`
   - col 5: `[ffa800 16 rim=true] [000000 16 rim=false] [ff4500 7 rim=false]`
   - every row: `mod=(1.0, 1.0, 1.0, 1.0)`; `SNAPSHOT ... size=(1080, 2160) err=0`.
6. [x] Other supply suites, all with exit 0 and 0 script errors:
   - `m28_c002_c002_static_shell`: PASS (16/16)
   - `m23_v01_batch_supply_evidence`: PASS
   - `m24_supply_handoff_evidence`: PASS
   - `m28_c002_c002_r01_visual`: PASS (10/10)
7. [x] `git diff --check HEAD~2..HEAD` is clean. The diff touches only the files listed above. The two extra test files are explained under Summary; the only reason for each change is the removed dim.

## Validation
- LOCAL_PASS with Godot 4.7.2 console:
  - m28_c002_c004_tile_visual: 17/17
  - m28_c002_c001_gameplay_v02: 14/14
  - m28_c002_c002_static_shell: 16/16
  - m28_c002_c002_r01_visual: 10/10
  - m23_v01_batch_supply_evidence: PASS
  - m24_supply_handoff_evidence: PASS
- Revert check: c004 fails as expected with the dim restored.
- `git diff --check`: clean.
- Not pushed.

## Log
### Round 1
- I removed the preview dim and updated the comments. I updated the two tests the spec names and added the canonical-colour assertion. Two more files asserted or copied the dim (`tests/m28_c002_c002_r01_visual.gd` and `tests/tools/m28_c004_tile_evidence.gd`), so I updated those as well.
- I captured Level 22 at 1080x2160 and closed SB-POLISH-001 in TASKS.md.
- The Godot runs rewrote `project.godot` in the worktree: they reordered keys and dropped the boot_splash show/stretch/filter settings and the `[audio]` bus layout. I restored the file with `git checkout -- project.godot`; it is not committed. Untracked `.import`/`.uid` churn from Godot is left uncommitted, as instructed.
