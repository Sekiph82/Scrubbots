# SB-M43-C005F-003 — WON Results one-shot celebration + CLEAN NEXT emphasis — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE2 (child 1 of 3)
- Start SHA: `a6842fd274665a871d9921052768d3dd9a67e0e3` (`origin/main`)
- Final SHA: the Phase 2 implementation commit (see master log)
- Child state: **TECHNICALLY COMPLETE — AWAITING GPT AUDIT + OWNER VISUAL REVIEW**

## Exact files changed

- `scripts/ui/results_screen.gd`:
  - the `set_feedback` / `get_feedback` presentation setter;
  - the WIN celebration, the CLEAN NEXT emphasis, the native `_pop` / `_stop_feel`;
  - the `_feel_event` gate and the layout-settle wait (`_after_layout`).
- `scripts/app/main.gd`: `_results.set_feedback(feel)`, one line, right after the single adapter is created.
- `scripts/ui/feel/feedback_adapter.gd`: shared with F004/F005. Summary:
  - a Control target bursts at its global-rect centre (Spark's own `at()` would use the top-left corner);
  - spawned bursts move into the target's CanvasLayer, or into its SubViewport when that differs from Spark's;
  - `stop_all` on expiry runs only for Node2D/3D targets;
  - particle **radius** is ×2.5 for the 1080-wide UI canvas.

  Counts, durations, intents, allow-list and budgets are unchanged.
- Tests: `tests/m43_c005f_phase2_results_pack_feel.gd` (w01–w08).

## Authority seam

- ResultsScreen receives the app root's **one** `FeedbackAdapter` through `set_feedback()`. It is presentation-only: never in AppState, the model or the save.
- With no adapter, the screen is exactly the native Results.
- Plugins are reached only through the adapter. ResultsScreen code contains no plugin name (g02, Phase 1 a01).

## Event-key / idempotency contract

- Terminal identity is `results:<status>:a<attempt>:L<level>`. `attempt` is NavigationController's monotonic terminal id, which is unique per app session, the same lifetime as the ephemeral adapter's key set.
- WIN key: `<identity>:win`. It fires only when `status == WON`, once per identity:
  - show_model → wait until the robot's rect stops moving (max 8 frames) → `_feel_event("WIN", robot, key)`;
  - a stale identity (the model changed meanwhile) is ignored.
- CLEAN NEXT key: `<identity>:next` (intent MICRO; a Control gets no plugin motion). It fires only after:
  - the reveal is finished;
  - **no ceremony barrier is held**;
  - the button is visible and enabled.

  The check runs deferred, so a barrier the app root sets in the same frame is seen first.
- None of the following replay anything (w02):
  - a repeated show_model;
  - a viewport resize;
  - a barrier hold/release;
  - Continue latch + re-arm.
- A new attempt plays once (w03). LOST and ERROR get no event (w04).

## FULL / REDUCED behaviour

**FULL**
- 18-particle Spark confetti (adapter WIN budget, ≤1.1 s) centred on the victory robot.
- One native emblem pop, 1.0 → 1.12 → 1.0 over 0.36 s.
- CLEAN NEXT: one native pulse, 1.0 → 1.05 → 1.0 over 0.40 s.

**REDUCED**
- Keys are consumed but nothing plays: no Spark, no pop, no pulse. The approved static Results stays.
- A REDUCED model with a momentarily FULL adapter makes no call at all (`_feel_event` gate).
- Returning to FULL never replays (w06).

**Always**
- No flash, camera, freeze, time-scale or shake.
- No layout/hierarchy change: only Control `scale` with a centred pivot, restored to exactly 1; hiding Results settles it.
- Continue and Home are never disabled, delayed or latched by feel (w05, w08).

## Tests (`tests/m43_c005f_phase2_results_pack_feel.gd`)

| Case | What it checks |
|---|---|
| w01 | one WIN, keyed correctly; 18-particle confetti exactly at the robot centre; no GFF call (Controls) |
| w02 | re-show ×3, resize, barrier, Continue latch/re-arm: still one WIN, at most one CLEAN NEXT emphasis |
| w03 | attempt 2 plays once more |
| w04 | LOST / ERROR: zero events |
| w05 | barrier holds CLEAN NEXT exactly as before; no emphasis while held; one emphasis after release; Continue and Home fire immediately |
| w06 | Reduced: zero plugin calls, keys consumed, no motion, rows immediate; back to FULL there is no replay |
| w07 | no adapter = native; plugins absent = no-op; throwing plugin (deliberate, labelled `EXPECTED_FAULT_INJECTION`) leaves Results shown, rows intact and Continue firing |
| w08 | emblem peak ≤ 1.12 and CLEAN NEXT peak ≤ 1.05, both back to exactly 1; hide settles |

Result: **PASS** (whole suite 22/22).

## Runtime evidence

Captured with the real app, real plugins and real launch → WON commit → Results; see `evidence/`:
- `results_won_full_{1080x2160,1536x2048}_celebration.png`: confetti burst at the robot, row pickups;
- `results_won_full_*_settled.png`;
- `results_won_reduced_*_static.png` and `results_won_reduced_*_settled.png`.

## Blockers / deviations

- **Deviation (bounded):** the WIN waits for Results layout to settle. Without the wait, the first frame's robot rect was stale; the measured fix puts the confetti exactly on the robot.
- **Owner-tuning items** (visual gate, not technical blockers): confetti size and density, emblem pop amplitude, CLEAN NEXT pulse amplitude.
