# OWNER DECISION — Current Playable App Entry

Date: 2026-09-17
Status: **OWNER-LOCKED**
Repository: `Sekiph82/Scrubbots`
Applies to: current development app bootstrap while M22 is the active playable milestone

## 1. Problem observed by owner

Running the project from the Godot editor with **Run Project / F5** opens the obsolete project-foundation bootstrap screen (`SCRUBBOTS / Project Foundation OK`) instead of the current M22 Railroad playable/demo experience.

The Railroad demo itself works when launched directly as:

`res://scenes/demo/m22_slot_demo.tscn`

This creates unnecessary ambiguity during owner acceptance and makes the normal editor Run Project path point at obsolete non-gameplay content.

## 2. Owner-locked current behavior

While M22 is the active playable milestone, **Run Project / F5 must open the current M22 playable Railroad experience**, not the old foundation diagnostics screen.

The canonical application entry path may remain:

`res://scenes/app/main.tscn`

Preferred implementation is for `main.tscn` to act as a thin app/bootstrap wrapper that instantiates or forwards into the current M22 playable scene:

`res://scenes/demo/m22_slot_demo.tscn`

This keeps the stable app entry path for future M23 replacement while removing the obsolete foundation-only user experience.

## 3. Required behavior

After the correction:

1. Opening the ScrubBots project in Godot and pressing **F5 / Run Project** opens the same current M22 Railroad playable experience used for owner acceptance.
2. The visible result contains the real Hazard Bot board, Railroad V1 and exactly five color slots.
3. The obsolete `SCRUBBOTS / Project Foundation OK` screen is no longer the normal Run Project result.
4. Direct launch of `res://scenes/demo/m22_slot_demo.tscn` continues to work.
5. Opening `m22_slot_demo.tscn` and pressing **F6 / Run Current Scene** continues to work.
6. Do not begin M23 gameplay-screen implementation as part of this correction.

## 4. Architecture boundary

This is a development/app-entry correction, not permission to collapse the M22 demo into final M23 UI architecture.

Prefer a thin wrapper/composition. Preserve the canonical app entry path so M23 can later replace the child/current playable scene without another project-level entry migration.

The old foundation diagnostics code may remain as historical/unreferenced code if deleting it is unnecessary; it must not be the normal owner-facing F5 path.

## 5. Validation

Automated/headless evidence must prove that running the project main scene reaches the M22 playable composition and exposes the expected Railroad demo content. Owner will repeat manual F5 acceptance after the V07 engineering audit.
