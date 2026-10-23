STATUS: READY

# Build: apply owner answers (SB-UI-008/013, SB-M22-023)

## Summary
Spec: apply two owner answers (2026-10-23) faithfully. Scrubby master = assets/ui/final/characters/scrubby/scrubby_master.png recorded in ASSET_GENERATION_MANIFEST.json (scrubby_master_reference OWNER_SELECTED; reference scrubby_master selected, supplementary refs kept), assets/art/references/inventory.json (OWNER_RESOLVED), README "Still awaiting" entry removed. booster_tutorial_pointer retired in assets/ui/VISUAL_ASSET_INDEX.md (PNG kept). TASKS.md: SB-UI-008, SB-UI-013, SB-M22-023 ticked; two Questions lines removed; queue rows now DONE. No PNG changes.

## Acceptance criteria
1. [x] SB-UI-008 recorded: manifests + README edited, both JSONs parse (python -I json.load OK); scrubby_master.png exists.
2. [x] SB-UI-013: validate_manifests.py (job folder, not committed) run with python -I: ASSET_GENERATION_MANIFEST 21 ids, HOME_ASSET_MANIFEST 122, inventory 60; no duplicate ids, no unresolved references. Only missing paths = the 4 known not-yet-generated target_paths, files still absent: assets/ui/final/boosters/flower.png, pickup.png, shuffle.png, assets/ui/final/decorative/cleaning_props_gameplay.png (note: booster icons were later bound under other names, so the three booster entries look stale; not in scope).
3. [x] SB-M22-023: no new coachmark; grep scripts shows coachmark_layer.gd binds res://assets/ui/final/gameplay/tutorial/tutorial_pointer.png; booster_tutorial_pointer has no runtime reference; index marks it retired; PNG untouched.
4. [x] TASKS.md Questions lines removed, queue rows DONE; git diff --check clean; status clean.

## Validation
git diff --check: clean. No Godot code changed, no suites run.

## Log
### Round 1
Applied via a stdlib script preserving CRLF in TASKS.md; committed on factory/041-apply-owner-answers.
