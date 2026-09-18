# SCRUBBOTS UI Asset Library

This directory separates raw generated candidates from owner-approved production art.

## Provider policy

- Primary generation workflow: ChatGPT image generation.
- Approved fallback/alternate: Magnific MCP.
- Generation is development-time only. The shipping game has no image-generation runtime dependency.
- Owner-approved originals/references remain under `assets/art/references/` and are never overwritten.
- Raw generated output is never automatically production-final.

## Canonical roots

```text
assets/ui/
├── generated/
│   ├── home/
│   ├── characters/
│   ├── rewards/
│   └── misc/
└── final/
    ├── common/{icons,currencies,badges,frames,navigation,effects}/
    ├── characters/{scrubby,helper_bots}/
    ├── home/{background,environment,platform,area_banner,top_hud,event_progress,shortcuts,play_cta,reward_track,bottom_nav}/
    ├── boosters/
    ├── rewards/
    ├── difficulty/
    ├── decorative/
    ├── popups/
    ├── collection/
    ├── shop/
    └── events/
```

## Home screen

The exhaustive Home preproduction inventory is `HOME_ASSET_MANIFEST.json`.

The Home background stays layered rather than flattened:

```text
sky → far city → mid city → street foreground
→ central platform / characters / props → UI
```

Normal UI copy, values, timers, prices and counters remain live Godot text. Generated art contains no baked dynamic text.
