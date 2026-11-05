# Review round 1, job 102 (single reviewer)

Checks: sb_m22_008_polish_013_slot_fx PASS; sb_polish_003_booster_vfx PASS; git diff --check clean.

Findings:
- Pulse: tile modulate alpha only; is_pulsing() requires pulse_allowed + occupied + WAITING; _sync_pulse on every refresh resets alpha/phase and stops process; Reduced/pause via strip (covers later sixth slot). No input (mouse ignore), no per-frame allocation. OK.
- Pop: pure pop_frame, lift -> burst -> stars strictly ordered, rise = h*(1+0.25) so gap >= 0.25 h; POP_MAX 6 with pop_front; Reduced suppresses and clear_pops; data-driven POP_PRESETS, default B; no nodes. Slot release unchanged (immediate). OK.
- Black slot: no snapshot/ColorRect/clear-color draw anywhere in the diff; the burst/tile draws are coloured and fade out; the tile alpha dip only shows the shell behind. Nothing in code can paint the slot black; builder's explanation (capture artefact) is plausible. Worth a phone glance, not blocking.
- CI: suite added to the validate list with the exact guard unaffected (list-based). Consistent.
- sb_polish_003: timeout widened and expected window tied to pop_duration()+300 ms; assertions not weakened.

Minor (non-blocking): set_pop_preset mid-pop changes timing of running pops.

Must-fix: none.

VERDICT: PASS
