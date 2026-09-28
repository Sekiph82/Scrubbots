# M43-C002-C001 — OWNER POPUP / PAUSE VISUAL REVIEW V01

Date: 2026-09-28
Status: PENDING OWNER REVIEW (the technical audit happens first)

All screenshots are in `evidence/` and come from the real app root on Level 2. Each popup uses existing promoted frames only, and nothing was generated. Every title, value and button label is live Godot text.

## What to look at

| # | Topic | Current candidate | Evidence |
|---|---|---|---|
| P1 | **Popup frame family** | Promoted `popup_*_frame.png` frames, scaled uniformly so corners and emblems never distort. Medium is used for neutral popups, warning for loss or error, reward for success, and small for busy. `popup_confirmation_frame` is **not used** because its baked ✓/✗ would look like dead buttons. | all |
| P2 | **Pause hierarchy** | Royal `PAUSED` pill, then live `Level N`, then a green **RESUME** as primary, then cream **RESTART** and **HOME** as secondary. There is an X close control, and it also resumes. | `pause_gameplay_v02_*`, `pause_short_phone_*`, `pause_tablet_*` |
| P3 | **Scrim opacity** | Black at 60%, the same as the accepted Results scrim. Stacked popups darken further because each popup keeps its own scrim. | `stacked_modals_*` |
| P4 | **CTA hierarchy** | Green Life/Help-family primary (the same style as the accepted Results Continue), with cream secondaries in INK text. On loss confirms, the primary is the loss action (RESTART or LEAVE) and the secondary is **KEEP PLAYING**. | `*_confirm_*` |
| P5 | **Text density / readability** | Body is 30 px INK, and loss lines are 30 px dark red. Titles are 44 px. At 1080×1920 the loss confirm shows 4 lines plus 2 CTAs with no clipping. | `home_confirm_post_action_short_phone_*` |
| P6 | **Loss wording** | Before the first action: "You haven't made a move yet, so no Heart or Win Streak is lost." After it: "This counts as a loss:" / "-1 Heart (5 → 4)" / "Win Streak 3 resets to 0". | `restart_confirm_pre_action_*`, `restart_confirm_post_action_*` |

## Owner choices requested

- **P1:** accept this frame mapping, or choose a different frame for Pause (for example `large`).
- **P2:** keep the X on Pause, or remove it (Back and RESUME would still resume).
- **P3:** keep 60%, or use a single scrim for stacked popups.
- **P4:** keep the loss action as the green primary, or make **KEEP PLAYING** the primary and the loss action secondary.
- **P6:** approve the copy as-is, or provide replacement wording. Only the copy would change; the values would stay the same.

These popups were not changed: the accepted Results screen, the Gameplay V02 static shell, the pause glyph (S4-A) and the 2x overlay.
