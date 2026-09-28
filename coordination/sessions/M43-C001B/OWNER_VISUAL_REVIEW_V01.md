# M43-C001B — OWNER VISUAL REVIEW V01

Date: 2026-09-28
Status: **CANDIDATE — awaiting owner visual acceptance.** This is not an owner approval. `victory_results` remains `MASTER_REQUIRED`.
Owner decisions applied: `coordination/OWNER_RESULTS_VISUAL_REPLAY_V01.md` (no Replay; Scrubby over frame; small emblem; green Continue; LOST excluded).

## How these images were made

`tests/tools/results_snapshot.gd` renders the real app root (`scenes/app/main.tscn`) on an isolated temporary save. It then:
- plays the real frontier level with the owner-approved click plan;
- lets the production host commit the rewards;
- captures the real Results screen over the real (fully cleared) board.

Every WON image is a genuine WON: the completion authority reports WON and 0 ACTIVE cells remain. Pre-seeded state exists only in the temporary save, to show representative rewards:
- the Win Streak is advanced;
- the frontier is set to 3 or 10.

Re-create them yourself (needs a display, not `--headless`):

```bash
godot --path . -s res://tests/tools/results_snapshot.gd -- coordination/sessions/M43-C001B/evidence
```

## Screens to inspect

| # | File | State shown | Viewport |
|---|---|---|---|
| 1 | `coordination/sessions/M43-C001B/evidence/won_L3_typical_1080x1920.png` | Level 3 WON (MEDIUM): first clear +75 SB, Win Streak 3 · +10 SB, +1 Bot Parts, Gift Meter 16/1000, "Gift ready!". Continue enabled → Level 4 | 1080×1920 |
| 2 | `coordination/sessions/M43-C001B/evidence/won_L3_typical_1080x2160.png` | same WON, reference aspect | 1080×2160 |
| 3 | `coordination/sessions/M43-C001B/evidence/won_L3_typical_1080x2400.png` | same WON, tall phone | 1080×2400 |
| 4 | `coordination/sessions/M43-C001B/evidence/won_L10_no_next_content_1080x1920.png` | Level 10 WON (VERY_HARD): +150 SB, Win Streak 5 · +100 SB, +2 Bot Parts, Gift Meter 141/1000, "Gift ready!", note "Level 11 is coming soon.", Continue **disabled** (frontier 11 = CONTENT_MISSING) | 1080×1920 |
| 5 | `coordination/sessions/M43-C001B/evidence/won_L3_reduced_effects_static_1080x2160.png` | Reduced Effects ON: every committed row is visible at once with no reveal sequence. It is intentionally pixel-identical in content to #2, because Reduced Effects shows the final state immediately. | 1080×2160 |
| 6 | `coordination/sessions/M43-C001B/evidence/lost_L1_technical_fallback_1080x2160.png` | Level 1 LOST: technical fallback. No robot, no emblem, no reward rows, no textures. RETRY + HOME. Final LOST UI is M43-C004. | 1080×2160 |

You can also play it live: win any level in the app; Results appears automatically.

## What to look at

1. Scrubby above the frame. His feet overlap the frame edge and the top of the blue header ribbon (#1–#5). Is this amount of overlap right?
2. Victory emblem size and position (96 px, left of "LEVEL COMPLETE"). Small and secondary, not the focal point?
3. Does the frame read as the Life/Help family? It uses a cream panel, a thick royal-blue rim and a blue header ribbon.
4. Reward rows:
   - Are the numbers readable?
   - Do the icons support the numbers rather than dominate them?
   - Row order is locked: first-clear → streak → Bot Parts → Gift Meter → gift-ready.
5. The green Continue is clearly primary; Home is clearly secondary (#1). Disabled Continue on Level 10 (#4) is muted green with the "coming soon" note above it.
6. No Replay anywhere.
7. LOST (#6) carries no Victory decoration.

## Genuinely unresolved visual-only items (owner choice; no engine or economy impact)

1. **Reveal timing.** The current candidate fades each row in over 0.16 s, in order, with no sound or haptic. This timing is a placeholder until you approve one. With Reduced Effects on, everything appears instantly.
2. **Robot overlap depth.** 96 px overlap; the robot's feet touch the header ribbon. Say if you want the robot higher, i.e. clear of the ribbon.
3. **Title and rim treatment.** "LEVEL COMPLETE" uses the Home font: the project default emboldened, with a navy outline. The panel rim is a single flat royal blue with no bolts or leaf accents. The Life/Help references have bolts, leaves and a footer plaque, and no chrome asset for those exists in the repo. Accept the flat native version, or request a chrome kit (SB-M43-028)?
4. **Disabled Continue look (#4).** Muted green with light text. Would you prefer the button hidden, or a different "coming soon" treatment?
5. **Row copy.** The texts are the existing technical strings, e.g. "First clear +75 SB" and "Gift ready! Claim it in Gifts." The owner ruling says copy may be polished later without changing economy truth.
