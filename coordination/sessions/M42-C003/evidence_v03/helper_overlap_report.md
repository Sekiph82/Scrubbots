# M42-C003 V03 helper overlap / z-order report

The left/right helper bots are baked into the Home background (HOME-121). `Layer_characters` (shade, Art_scrubby, HomeScrubbyHero/Art_scrubby_gesture) is a later child of `Background`, so Scrubby always draws IN FRONT of both helpers; no helper fade/hide is needed or implemented. Owner V03: helper overlap is warning-only. Counts = opaque gesture texels inside the helper's mapped catalog rect.

| Viewport | Gesture | Frames overlapping left helper | Max texels | Frames overlapping right helper | Max texels |
|---|---|---:|---:|---:|---:|
| 1080x2160 | wave | 14 | 630 | 0 | 0 |
| 1080x2160 | bow | 15 | 503 | 0 | 0 |
| 1080x2160 | turn | 13 | 696 | 4 | 4509 |
| 1080x2160 | full_turn | 4 | 481 | 10 | 4299 |
| 1080x1920 | wave | 14 | 630 | 0 | 0 |
| 1080x1920 | bow | 15 | 503 | 0 | 0 |
| 1080x1920 | turn | 13 | 696 | 4 | 4509 |
| 1080x1920 | full_turn | 4 | 481 | 10 | 4299 |
| 1290x2796 | wave | 14 | 630 | 0 | 0 |
| 1290x2796 | bow | 15 | 503 | 0 | 0 |
| 1290x2796 | turn | 13 | 696 | 4 | 4509 |
| 1290x2796 | full_turn | 4 | 481 | 10 | 4299 |
| 1536x2048 | wave | 14 | 630 | 0 | 0 |
| 1536x2048 | bow | 15 | 503 | 0 | 0 |
| 1536x2048 | turn | 13 | 696 | 4 | 4509 |
| 1536x2048 | full_turn | 4 | 481 | 10 | 4299 |
