STATUS: READY

# Build: SB-UI-008 / SB-UI-013

## Blocked
Owner question: which is the canonical Scrubby master reference, "_owner_inbox/Game Screens/main screen.png" (in-context) or "_owner_inbox/Collection Cards/meet the scrubbots.jpeg" (isolated portraits)?
ASSET_GENERATION_MANIFEST.json (scrubby_master_reference, OWNER_SELECTION_REQUIRED) and assets/art/references/inventory.json (scrubby_master, OWNER_REQUIRED) list these two with no owner choice. assets/ui/final/characters/scrubby/scrubby_master.png exists (Phase 1 codex output) but was never owner-selected; the owner-approved Scrubby assets are home_pose/portrait/layers, not a master. Not picking.

## SB-UI-013 pre-check
python -I chk.py (job folder, not committed) over ASSET_GENERATION_MANIFEST.json, HOME_ASSET_MANIFEST.json, references/inventory.json: ids unique (21/122/60), all references resolve, all paths exist except 4 not-yet-generated target_paths (boosters/shuffle, pickup, flower; decorative/cleaning_props_gameplay). Nothing verifiably wrong, no manifest edits. Re-run after 008.

## Changes
TASKS.md lines 795-796 notes only; both items stay unticked, queue row left READY. git diff --check clean.

## Log
### Round 1
As above.

### Round 1 addendum
This is an escalation record, not a completion: no items ticked. Per coordinator, queue row moved to OWNER (after last READY row) and one question added under Questions for Sekip. The BLOCKED analysis above stands.
