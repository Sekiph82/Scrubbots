# M42-C003 V03 lifecycle stability (20x)

| Cycle | Home visible -> hidden -> visible | Nodes | effects.changed connections | Started gestures (cumulative) |
|---:|---|---:|---:|---|
| 1 | ok | 131 | 1 | { "bow": 1, "full_turn": 1 } |
| 2 | ok | 131 | 1 | { "bow": 1, "full_turn": 1, "turn": 1 } |
| 3 | ok | 131 | 1 | { "bow": 1, "full_turn": 1, "turn": 1, "wave": 1 } |
| 4 | ok | 131 | 1 | { "bow": 2, "full_turn": 1, "turn": 1, "wave": 1 } |
| 5 | ok | 131 | 1 | { "bow": 2, "full_turn": 1, "turn": 2, "wave": 1 } |
| 6 | ok | 131 | 1 | { "bow": 2, "full_turn": 1, "turn": 2, "wave": 2 } |
| 7 | ok | 131 | 1 | { "bow": 3, "full_turn": 1, "turn": 2, "wave": 2 } |
| 8 | ok | 131 | 1 | { "bow": 3, "full_turn": 1, "turn": 3, "wave": 2 } |
| 9 | ok | 131 | 1 | { "bow": 4, "full_turn": 1, "turn": 3, "wave": 2 } |
| 10 | ok | 131 | 1 | { "bow": 4, "full_turn": 1, "turn": 4, "wave": 2 } |
| 11 | ok | 131 | 1 | { "bow": 4, "full_turn": 1, "turn": 4, "wave": 3 } |
| 12 | ok | 131 | 1 | { "bow": 4, "full_turn": 1, "turn": 5, "wave": 3 } |
| 13 | ok | 131 | 1 | { "bow": 4, "full_turn": 1, "turn": 5, "wave": 4 } |
| 14 | ok | 131 | 1 | { "bow": 5, "full_turn": 1, "turn": 5, "wave": 4 } |
| 15 | ok | 131 | 1 | { "bow": 5, "full_turn": 1, "turn": 6, "wave": 4 } |
| 16 | ok | 131 | 1 | { "bow": 5, "full_turn": 2, "turn": 6, "wave": 4 } |
| 17 | ok | 131 | 1 | { "bow": 6, "full_turn": 2, "turn": 6, "wave": 4 } |
| 18 | ok | 131 | 1 | { "bow": 6, "full_turn": 2, "turn": 6, "wave": 5 } |
| 19 | ok | 131 | 1 | { "bow": 7, "full_turn": 2, "turn": 6, "wave": 5 } |
| 20 | ok | 131 | 1 | { "bow": 7, "full_turn": 3, "turn": 6, "wave": 5 } |

Baseline nodes 131, connections 1 -> after 20 cycles 131 / 1.
20x Home instantiate/bind/free with the same AppState: effects.changed connections 0 -> 0; object count delta 0.

No Timer, Tween or per-cycle signal is created by HomeScrubbyHero (it is driven by _process/step only).
