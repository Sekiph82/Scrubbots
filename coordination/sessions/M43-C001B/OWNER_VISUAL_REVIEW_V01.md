# M43-C001B — OWNER VISUAL REVIEW V01

Date: 2026-09-28
Status: **OWNER VISUAL ACCEPTED / FINAL PASS.** Canonical acceptance: `coordination/sessions/M43-C001B/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`. `victory_results` is promoted to `MASTER_OWNER_APPROVED`.
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

## Owner-accepted visual choices

1. **Reveal timing accepted.** 0.16 s per row, ordered; Reduced Effects shows everything instantly.
2. **Robot overlap accepted.** 96 px overlap; Scrubby's feet may touch the header ribbon.
3. **Title/rim accepted.** Current Home-font title and flat royal-blue native rim are approved for Results; no extra chrome kit is required for this surface.
4. **Disabled Continue accepted.** Muted green + current coming-soon treatment.
5. **Row copy accepted.** Current live Results wording is approved; later localization/copy polish may occur without changing reward truth.
