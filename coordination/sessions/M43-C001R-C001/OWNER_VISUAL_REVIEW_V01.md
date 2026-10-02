# M43-C001R-C001 — Owner Visual Review V01

Date: 2026-10-02
Status: **OWNER_REVIEW_REQUIRED.** This is not self-approved. SB-M43-R01-001..008 close only after the ChatGPT technical audit and an owner decision.
Evidence: `coordination/sessions/M43-C001R-C001/evidence/`. These are real app renders: `main.tscn`, real catalog levels and previews, and a real terminal WON committed by the host before Results.

Reproduce the evidence with:

```bash
godot --path . -s res://tests/tools/results_momentum_snapshot.gd -- coordination/sessions/M43-C001R-C001/evidence
```

## 1. Evidence index

| Surface | File(s) |
|---|---|
| WON Results with Journey + Next Cleanup (reference 1080×2160) | `results_L2_won_journey_next_cleanup_1080x2160.png` |
| Results L4 → teaser L5 (mini-boss next) | `results_L4_next_L5_mini_boss_1080x2160.png` |
| Results L9 → teaser L10 (boss next) | `results_L9_next_L10_boss_1080x2160.png` |
| Results L10 → 10/10 + honest Level 11 coming soon, no art | `results_L10_cycle_complete_L11_coming_soon_1080x2160.png`, `results_L10_short_phone_1080x1920.png` |
| Results viewport matrix | `results_L4_short_phone_1080x1920.png`, `results_L4_phone_1170_1170x2532.png`, `results_L4_phone_1290_1290x2796.png`, `results_L4_tablet_1536x2048.png` |
| Reduced Effects | `results_L2_reduced_effects_1080x2160.png`, `home_frontier_6_reduced_effects_1080x2160.png` |
| Ceremony barrier held / released (future C005 seam) | `results_L2_ceremony_barrier_held_1080x2160.png`, `results_L2_ceremony_barrier_released_1080x2160.png` |
| Home mid-cycle (frontier 6) | `home_frontier_6_mid_cycle_1080x2160.png` |
| Home new player / boss current | `home_frontier_1_new_player_1080x2160.png`, `home_frontier_10_boss_current_1080x2160.png` |
| Home new cycle (frontier 11): the real production state, with the honest coming-soon pill | `home_frontier_11_new_cycle_1080x2160.png` |
| Home viewport matrix | `home_frontier_6_short_phone_1080x1920.png`, `home_frontier_6_phone_1170_1170x2532.png`, `home_frontier_6_phone_1290_1290x2796.png`, `home_frontier_6_tablet_1536x2048.png` |

## 2. Decisions requested

1. **Teaser crop composition and amount.**
   - The V1 crop is about 20% of the real preview: 14×14 of 32×32, shown pixel-sharp in a 132 px frame.
   - The window is picked deterministically among the most detailed windows, so it is never plain background.
   - Is this the right amount and composition? Alternatives: a smaller fraction within 0.15..0.25, or a silhouette / limited-palette treatment instead of a crop.
2. **Journey placement and node hierarchy.**
   - Results: `CLEANING JOURNEY · n/10` caption and the strip, between the reward rows and Next Cleanup.
   - Home: a 560 px strip on a translucent plate directly above PLAY, over the plaza floor. It takes no layout slot, so nothing in the accepted Home composition moves.
   - Node states: complete = green check, current = gold (Home), next = white (Results), future = dim navy with the level number.
3. **Mini-boss / boss nodes.** Slot 5 is a diamond with an orange rim; slot 10 is a larger diamond with a crimson rim. Neither carries any reward icon or promise. Accept, or request distinct art?
4. **CLEAN NEXT wording and hierarchy.** The green primary now reads `CLEAN NEXT` (it was `CONTINUE`); `HOME` stays secondary. At Level 10 it is disabled while Level 11 has no content.
5. **Results density.**
   - Momentum adds roughly 280 px to the WON panel. It fits all five viewports (t33), but the panel is taller.
   - The Level-10 card says "Coming soon" and the existing C001A/B note also says "Level 11 is coming soon." Keep both, or drop one?
6. **Home density / placement.** The strip sits on the plaza floor between Scrubby's feet and PLAY. On frontier 11, the existing coming-soon pill stacks above it. Accept this placement?

## 3. Out of scope / unchanged

- Rewards, Gift Meter, Hearts, Win Streak, boosters, ads, cadence and difficulty are unchanged.
- There is no Level Select, no tappable node, no World Diorama and no new destination.
- No art was generated: the teaser shows only each level's own committed preview, cropped at runtime with no derived image files.
- The M43-C004 Fail / Need a Hand surfaces are untouched. The momentum section is WON-only.
- SB-M43-013 (C005 ceremonies) is not implemented; only the barrier seam exists.
