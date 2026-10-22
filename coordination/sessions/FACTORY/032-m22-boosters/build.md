STATUS: READY

# Build: SB-M22-015 verify-close, SB-M22-008 conditional

## Summary
TASKS.md only. SB-M22-015 ticked; SB-M22-008 left unticked and moved to the Not-queued standing-rules comment as conditional. Queue row replaced with a DONE line.

## Acceptance criteria
1. [x] Assets exist: four PNGs in assets/ui/final/boosters/.
2. [x] Provenance: listed in assets/ui/VISUAL_ASSET_INDEX.md (canonical four, line 733); extra_slot in ASSET_GENERATION_MANIFEST.json.
3. [x] Bound: scripts/ui/gameplay_screen.gd:60-63, scripts/ui/popup/acquisition_flow.gd:45-48.
4. [x] Import: mipmaps/generate=false on all four .import files.
5. [x] CI: gh run 39828088266 conclusion success (head b815747).
6. [x] SB-M22-008: no approved no-work slot state spec found (only a difficulty metric no_work_slot_fraction); not invented.

## Validation
git diff --check clean; git status clean after commit.

## Log
### Round 1
Edited TASKS.md only and committed.
