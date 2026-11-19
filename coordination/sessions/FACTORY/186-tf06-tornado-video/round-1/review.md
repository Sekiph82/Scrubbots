VERDICT: REWORK

## Suite results (re-run by reviewer, headless, sequential)
- sb_tf06_tornado_video: PASS 12/12 (PERF avg=0.306 max=1.284 ms)
- sb_polish_003_booster_vfx: PASS
- sb_tf04_gameplay_layout: PASS 7/7
- sb_tf05_reward_reveal: PASS 16/16
- sb_phone_2026_11_12_f_slot_pop_hold: PASS 100/100
- m39c_boosters: PASS
- m22_025 / m43_c005f_phase3: not re-run, builder shows identical failure on main (note only).
- git diff --check clean. Diff touches no scripts/gameplay, scripts/economy, data; no mp4, no .import, no project.godot committed. CI guard present (workflow lines 91, 212, 486). .ogv 149,835 B.

## Findings
1. scripts/ui/feel/booster_vfx.gd:348-353 (_tick_tornado) - ORCHESTRATOR VISUAL FINDING CONFIRMED in the strip. The ghost is pulled with u = ease_in(t / _clip) over the whole clip, toward tornado_pos(), which at the start is at the button. So at t=0.24-0.70 s the orange cells already stream down-right toward the tiny tornado near the button (frames 2-4), and by t=0.92 s, when the tornado is over the board, the board is empty of orange (frame 5). Intent is the opposite: the tornado grows onto the board and sucks cells in. Fix: start the ghost pull late and finish at clip end, for example u = ease_in(clampf((_t / _clip - 0.45) / 0.55, 0, 1)) (tune against the strip), and pull toward the tornado's position while it is over or near the board. Fade (modulate.a = 1 - u*u) and shrink then also begin only then. Likewise delay the <= 48 samples and tiles in _draw_tornado (s - delay) so they do not leave before the tornado has covered most of its travel, or at least make them target the tornado only once it is near the board. Re-capture the strip and check that frames at ~0.6-1.0 s show cells still on the board and spiralling into the funnel, not streaming to the button. The test 9 pivot/position assertions need to follow the new timing.

## Judgement on builder deviations
- Mapping (deviation 1): acceptable. Spec Req 4 and its 1.25 ratio bound are mutually contradictory (the clip path is ~125 px x / 740 px y, the layout needs a much wider ratio). Clamped sx plus a progress-following x drift hits both endpoints exactly at 8 viewports with ratio 1.25 and no rotation. Code is small and readable.
- Trim 7..38, crop threshold 12, const DURATION nominal with _dur set at play(), queue_free in _free_video: all acceptable (clip 1.333 s within 1.3-2.2). Video player is freed at burst and in stop(); Reduced path creates nothing (capture returns {}); fallback path returns code-only before adding a child (remove_child + free on failed start).
- Provenance/manifest sha pinned and test-checked (case 2).

## Notes
- flow_videos doc and UI_VIS_006 skips are justified.
- Exit-time ObjectDB leak warning from the broken-stream injection mirrors the precedent; non-blocking.
