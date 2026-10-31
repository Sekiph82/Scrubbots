VERDICT: PASS

## Findings
None.

## Notes
- Diff is a presentation-only change: `batch_supply_panel._bind_row` now sets modulate white on every row. No gameplay, economy, palette, slot, TargetSelector/Routing or save-data surface is touched. The cyan front rim is unchanged, preview rows stay mouse IGNORE, and the colour-symbol overlay is untouched.
- No other `modulate` assignment is left in `batch_supply_panel.gd` or `color_batch_tile.gd`, so no hidden dimming remains.
- The TASKS.md edit is limited to SB-POLISH-001 (queue row moved to DONE, polish checkbox ticked) and lists the evidence.
- The evidence PNG is under `factory/jobs/084-polish-supply-colors/evidence/`. I did not open it.
- I did not re-run the suites. Their results are taken from TASKS.md and build.md.
