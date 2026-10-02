# M43-C001R-C001 — Owner Visual Review V02

Date: 2026-10-02
Status: **OWNER_REVIEW_REQUIRED.** This is not self-approved.
Owner decision being answered: `OWNER_VISUAL_DECISION_V02.md`
Evidence: `coordination/sessions/M43-C001R-C001/evidence_v02/`. These are fresh real-app renders. The V01 set stays in `evidence/` for comparison.

Reproduce the evidence with:

```bash
godot --path . -s res://tests/tools/results_momentum_snapshot.gd -- coordination/sessions/M43-C001R-C001/evidence_v02
```

## 1. What changed (only what the owner asked for)

| Request | V01 | V02 |
|---|---|---|
| Home Journey larger | 560×58 strip; ordinary node 39 px | **720×84** strip (same position, directly above PLAY); ordinary node **47.5 px** |
| Results Journey | Strip 56 px tall; node 38 px | Strip **76 px** tall; ordinary node **42.5 px** (same position, between the rewards and Next Cleanup) |
| Mini-boss (slot 5) | Same size as ordinary nodes | Orange, **1.3×** ordinary (Home 61.8 px) |
| Boss (slot 10) | 1.22× ordinary | Red, **1.6×** ordinary (Home 76 px); always the largest |
| Current node | 1.12× | 1.12× (never larger than a beat) |
| L10 → missing L11 | The card said "Coming soon" and a duplicate note said "Level 11 is coming soon." | **Only** the Next Cleanup card says "Coming soon". The duplicate note is suppressed when the card shows that frontier. CLEAN NEXT stays disabled and Home stays usable. |
| CLEAN NEXT | — | Unchanged |
| Teaser crop | — | Unchanged (≈20%, 0.15..0.25, full preview never drawn) |

All nodes stay inside their strip and neighbours never overlap; this is asserted on Home frontiers 6 and 10 and on Results L9. Nothing else on Home moved; the five-viewport no-collision check passes.

## 2. Evidence index

| Surface | File |
|---|---|
| Home frontier 6, larger Journey (reference) | `home_frontier_6_mid_cycle_1080x2160.png` |
| Home frontier 10, red boss hierarchy (boss current) | `home_frontier_10_boss_current_1080x2160.png` |
| Results L4 → L5 orange mini-boss next | `results_L4_next_L5_mini_boss_1080x2160.png` |
| Results L5, orange mini-boss complete | `results_L5_mini_boss_complete_1080x2160.png` |
| Results L9 → L10, red boss next | `results_L9_next_L10_boss_1080x2160.png` |
| Results L10, 10/10, single Coming Soon | `results_L10_cycle_complete_L11_coming_soon_1080x2160.png`, `results_L10_short_phone_1080x1920.png` |
| Short phone / 1170 / 1290 / tablet | `results_L4_short_phone_1080x1920.png`, `results_L4_phone_1170_1170x2532.png`, `results_L4_phone_1290_1290x2796.png`, `results_L4_tablet_1536x2048.png`, `home_frontier_6_short_phone_1080x1920.png`, `home_frontier_6_phone_1170_1170x2532.png`, `home_frontier_6_phone_1290_1290x2796.png`, `home_frontier_6_tablet_1536x2048.png` |
| Reduced Effects | `results_L2_reduced_effects_1080x2160.png`, `home_frontier_6_reduced_effects_1080x2160.png` |
| Also refreshed | Results L2, barrier held/released, Home frontiers 1 and 11 |

## 3. Owner questions

1. Is the larger Home Journey (720×84 above PLAY) the right size, or should it go bigger or smaller?
2. Is the size hierarchy right: ordinary < orange mini-boss (1.3×) < red boss (1.6×)?
3. Is the single Coming Soon message (inside the Next Cleanup card) at Level 10 acceptable?
4. The teaser crop is unchanged. "Teaser crop" means the Next Cleanup image shows a fixed ~20% close-up window of the next level's real picture, never the whole picture, so the player sees a detail and is curious about the rest. Keep it, or ask for a different amount or style?
