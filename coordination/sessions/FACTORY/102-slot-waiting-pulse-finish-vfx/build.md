STATUS: READY

# Build: SB-M22-008 WAITING slot pulse + SB-POLISH-013 finished-batch pop speed presets

## Summary
Branch factory/102-slot-waiting-pulse-finish-vfx (not pushed), commits dc7f7832 (code + tests) and 5ceb3820 (TASKS.md).
- SB-M22-008: BatchSlotView pulses its tile alpha 1.0 -> 0.94 -> 1.0 (cosine, PULSE_PERIOD_S 1.8 s, PULSE_DEPTH 0.06), but only while its detached snapshot is occupied and in WAITING. ACTIVE, EMPTY, release and reuse end the pulse at once: alpha goes back to 1 and the phase resets. Colour, count, batch id and order do not change. FiveSlotStrip.set_waiting_pulse_allowed() passes the allowance to every slot, including a sixth slot added later. GameplayScreen turns the pulse off under Reduced Effects or pause (set_reduced_effects / set_paused -> _sync_slot_pulse). This is presentation only: no input, and no change to gameplay, the solver or the economy.
- SB-POLISH-013: the BoosterVfx pop now runs three phases in strict order. LIFT: the tile rises with ease-in-out until its bottom edge is POP_GAP 0.25 x slot height above the former slot top. BURST: the tile swells and fades into the burst art. STARS: 8 stars travel outward with ease-in-out. A pure helper, pop_frame(rect, t), is shared by drawing and tests. All timings live in one table, POP_PRESETS: A 0.95 s (0.38/0.20/0.37), B 1.25 s (0.50/0.25/0.50), C 1.60 s (0.64/0.32/0.64). set_pop_preset() switches between them, and the default is B until the owner picks. The pop starts from the slot TILE's own global rect, so there is no jump at t=0. At most 6 pops run at once (POP_MAX; the oldest gives way). Turning Reduced Effects on also clears pops that are already running (clear_pops). The slot is still released immediately.
- Files: scripts/ui/batch_slot_view.gd, scripts/ui/five_slot_strip.gd, scripts/ui/gameplay_screen.gd, scripts/ui/feel/booster_vfx.gd, tests/sb_m22_008_polish_013_slot_fx.gd (new), tests/sb_polish_003_booster_vfx.gd (the pop-end wait now uses pop_duration() + 300 ms; evidence t values updated), .github/workflows/android-family-first10.yml (new suite added to validate), TASKS.md.

## Acceptance criteria
1. [x] Only an occupied slot in authoritative WAITING pulses; ACTIVE / EMPTY never do: sb_m22_008 "5 slots: only the WAITING slot pulses", and in the real GameplayScreen "WAITING snapshot from the runtime sync pulses".
2. [x] Pulse is alpha, 1.6-2.0 s, amplitude <= 6-8 %, not strobing: "alpha dips to 0.940", "period 1.8 s, non-strobing (max 0.0017 alpha per frame)", "trough at half period".
3. [x] The pulse ends at once when the slot becomes reachable, and on release, reuse and retry (retry rebinds EMPTY): the "reachable (ACTIVE)", "release (EMPTY): phase reset", "reuse by a new ACTIVE batch: no pulse" and "reused batch WAITING: pulse starts from full alpha" checks.
4. [x] Reduced Effects and pause hold the slot static, and resume restarts the pulse. This was checked on the strip and on the real screen (set_paused, and the live app_state.set_reduced_effects setting).
5. [x] Works with 5 and 6 slots: a later sixth slot follows the current allowance.
6. [x] No input captured, and count and state stay the same while pulsing: "same count / state while pulsing; no input captured" (the view and tile both use MOUSE_FILTER_IGNORE).
7. [x] Pop order is LIFT -> BURST -> STARS -> DONE with no overlap, for A, B and C (sampled every 10 ms).
8. [x] Geometry: the lifted bottom edge ends 0.25 x slot height above the slot top for every preset ("35.0 px above the slot top (>= 35.0)" for a 140 px slot). At t=0 the tile sits exactly on the slot (no jump). The lift eases in and out.
9. [x] Durations are data-driven: one POP_PRESETS table, totals 0.95 / 1.25 / 1.60 s, default B, unknown id rejected. Pops are alive at 1.24 s and gone at 1.25 s (B).
10. [x] Overlapping pops are capped at 6 and create no nodes (the overlay has 1 child).
11. [x] Slot release is immediate: in the real screen, "slot released at once (EMPTY, no pulse) while the pop plays".
12. [x] Reduced Effects suppresses pops ("finished batch makes no pop") and removes a running pop when switched on mid-pop.
13. [x] No black flash and no clipping. In the recorded clips the mean luminance of the slot area stays between 75.2 and 78.5 across every frame of A, B and C. The lifted tile stays inside the gameplay shell, over the pipe above the slot (see the clips). See the note under Log about a capture-only black slot seen in an earlier recording.
14. [x] Owner review clips: three real gameplay recordings of the same finish event (A/B/C), a side-by-side, and a WAITING pulse clip, all listed below.

Clips (not committed), in C:/Users/sekip/Desktop/ScrubBots/factory/jobs/102-slot-waiting-pulse-finish-vfx/evidence/:
- finish_pop_preset_A_0.95s_60fps.mp4, finish_pop_preset_B_1.25s_60fps.mp4, finish_pop_preset_C_1.60s_60fps.mp4: full 1080x2160 gameplay scaled to 540x1080, labelled with preset, duration and FPS; 0.2 s hold, the pop, then a 0.3 s tail.
- finish_pop_side_by_side_A_B_C_60fps.mp4: the slot area of all three, starting together.
- waiting_pulse_real_1.8s_60fps.mp4: 3.6 s of three real WAITING slots (no reachable target right after the first placements on L1).

How they were recorded: a throw-away rendering driver (scratchpad, not committed) with a save override and a windowed Compatibility renderer. It boots main.tscn and launches L1. It uses Random, Selector and Tornado x2 (real boosters), places the supply fronts, and lets the runtime play until a slot batch really finishes (rect (751,1323) 103x96, colour C brown). It then replays that same pop for A, B and C, stepped at exactly 1/60 s per frame. Frames were joined with ffmpeg (libx264).

## Validation
All runs are Godot 4.7.2 headless, LOCAL_PASS. Every suite exited 0 with 0 SCRIPT ERROR / Parse Error unless noted.
- tests/sb_m22_008_polish_013_slot_fx.gd: PASS (13 pulse + 21 pop + 10 real-screen checks).
- sb_polish_003_booster_vfx: PASS (includes the real-play pop case).
- m28_c002_c001_gameplay_v02: PASS 14/14.
- m28_c002_c004_tile_visual: PASS 17/17.
- m50_accessibility_audit: PASS 4/4.
- m29_slot_display_sync_evidence: PASS.
- m46_performance: timing-only failures that depend on machine load. Run 1 (with this branch's code, while windowed capture runs were also going): every frame-budget case passed (whole-level mean 3.012 ms, maze mean 3.717 / p99 13.871 ms, FULL/REDUCED effect budgets ok). Only "retry() on 59x59 worst 51.70 ms (<= 50.1)" failed. Run 2 overlapped another job's Godot suites (m43_master_c011_c014 was running at the same time): 4 timing fails, all in solver/route-heavy paths this change does not touch (maze target_selection mean 10.7 ms per probe). It could not be measured on a quiet machine during this job, so it is recorded as an environment timing failure, not LOCAL_PASS. Re-run it in CI or on an idle machine.
- m46_slot_rebuild (not in CI): FAIL(1), "+1 Slot -> 6 slots". This is not caused by this change. plus_one_slot() returns {"ok": false, "reason": "locked"} because of the SB-M44-032 L21 booster gate on a fresh L1 save, and the suite never unlocks it. No gameplay or economy file is touched here.
- git diff --check on the staged files: clean. project.godot and the tracked .import churn were restored. Only untracked Godot import byproducts (*.import, *.uid, docs/*.translation) remain in the job worktree, which is deleted with the job.
- No CI run and no phone build, as instructed.

## Log
### Round 1
- Built both tasks as described above, plus a new permanent suite, which was also added to the CI validate list.
- Clip recording: on L1, placing the three supply fronts straight away leaves every slot WAITING (no reachable target), so no batch ever finishes. That state was used for the real WAITING pulse clip. The finish clips use the sb_polish_003 sequence instead (boosters first), which reaches a real finish within about 0.1 s.
- Capture note: the first recording showed the just-finished slot's interior opaque black for about the first second after the finish. That black was drawn above the overlay and also appeared with no pop running. Headless and windowed probes of the same moment never reproduced it: the real screen shows the shell's navy, or the pop tile. Re-recording with RenderingServer.force_draw for each frame, plus a 2 s settle, gave clean frames throughout. So the black looks like a windowed-capture artefact (the window could not present, and frame_post_draw stalled in the same session), not a game draw. It is worth a glance on a phone.
- The pop snapshot is the batch colour drawn as a rounded tile, with no count or symbol: a finished batch's count is 0.
