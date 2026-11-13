# ScrubBots Events | Visual Reference Intake (2026-11-13)

## What is actually available in origin/main
These two files already exist and may be inspected in the checkout:
- `assets/ui/generated/masters/scrubbots_events_master_v01.png` (LEGACY design reference, OWNER-REJECTED robot anatomy)
- `assets/ui/final/events/event_weekly_hero.png` (LEGACY Weekly design reference, OWNER-REJECTED robot anatomy)
- `assets/ui/final/characters/scrubby/scrubby_master.png` (begin canonical robot identity audit here)
- All other FINAL/APPROVED ScrubBots robot PNGs must be enumerated and verified within the repository, not imagined.

**Critical truth:** A ChatGPT-produced, optional ZIP named `scrubbots_events_master_references.zip` was produced in conversation, but as of this instruction it has NOT been added to this GitHub repo. Do not confuse the PNG files in the ZIP with the two legacy images listed above. Do not claim they are uploaded. The ZIP's robot figures are NOT canonical, and neither draft is approved final art. If the archive is absent, proceed from V02 text, original repo art, and documented geometry.

## Optional ChatGPT reference ZIP and exact intake paths
Local package name: `scrubbots_events_master_references.zip`.
Contains:
- `events_master_layout_reference_1170x2532_NOT_FINAL.png` — portrait layout composition only.
- `weekly_cleaning_hero_reference_1024x1024_NOT_FINAL.png` — square composition only.
- `README.txt`.

If the user has copied this archive into `C:\Users\sekip\Desktop\Scrubbots\_incoming\scrubbots_events_master_references.zip`, extract into:
`assets/ui/generated/references/events_v02_owner_chat/`

Powershell example (only if the ZIP exists; never download a speculative file or block):
```powershell
$root = 'C:\Users\sekip\Desktop\Scrubbots'
$archive = Join-Path $root '_incoming\scrubbots_events_master_references.zip'
$dest = Join-Path $root 'assets\ui\generated\references\events_v02_owner_chat'
if (Test-Path $archive) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Expand-Archive -LiteralPath $archive -DestinationPath $dest -Force
  Get-ChildItem -Recurse -File $dest | Select-Object FullName, Length
} else {
  Write-Host 'Optional ChatGPT reference ZIP unavailable; continue with GitHub V02 plan and canonical robots.'
}
```
These files are optional visual references and should remain labeled NOT_FINAL. Their absence must never block data-model, service, UI, test, or canonical-robot composition work.

## Actual owner-required deliverables and precise locations
- `assets/ui/generated/masters/scrubbots_events_master_v02.png`: FINAL portrait Events screen design master, target 1170×2532. Create **new** independent output from existing approved robots; actual app Godot layout should be native/reusable controls.
- `assets/ui/final/events/heroes/weekly_cleanup_challenge.png`: FINAL separate Weekly Cleanup Challenge Hero, target 1024×1024.
- Remaining 23 heroes: `assets/ui/final/events/heroes/<id>.png` at 1024×1024.
- 24 unique icons: `assets/ui/final/events/icons/<id>.png`.
- 7 separate shared backgrounds / decorations under `assets/ui/final/events/backgrounds/` and `assets/ui/final/events/decorations/`.

**Graphic rules:** no printed event index numbers, atlas, grids or collages. 24 heroes must be independently composed/produced files, NOT crops from a big grid. Only canonically verified robot PNGs may depict robots. Two hands and two arms on each robot. Never render a synthetic replacement robot. Keep text legible and English names exact; dynamic progress numbers belong in live UI, not the art. No extra gameplay.

## Suggested vertical Events screen layout (1170×2532)
- Safe header: ScrubBots logo + existing account/currency HUD; do not invent currencies or replace canonical HUD.
- EVENTS title and short rule blurb.
- A scroll container of 3–5 currently active event cards: separate artwork, title, countdown, progress and rewards using actual service data; upcoming state below. Active cards must be dynamically configured.
- Safe bottom navigation aligned to actual production navigation, not a manually painted substitute.
- Mobile breakpoints must be verified at 720×1520 and 1170×2532, including safe insets, readable text, and touch hitboxes.
- Events tab remains locked before Level 30. Test Level 29 locked, Level 30 enabled.

## UI implementation notes
`scripts/ui/components/ui_event_card.gd` currently hard-codes `HERO = res://assets/ui/final/events/event_weekly_hero.png` and the weekly title. Make the card event-id-driven. Do not add 24 preloads that load all art simultaneously. Resource load only 3–5 visible active cards and selected details, then release unused textures when UI closes. For legacy scenes that require Weekly while migrations occur, retain a transparent fallback, with QA indicating fallback state.

## Acceptance
Inspect native PNGs and record pixel dimensions, hash, robot reference hashes, and visual screenshots from actual running Godot app. All shipped hero assets, their paths and exact IDs must resolve in the app and in GitHub. Don't mark unverified art final.
