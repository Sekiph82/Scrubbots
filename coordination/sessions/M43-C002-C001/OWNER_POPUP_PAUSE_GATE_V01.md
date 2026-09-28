# M43-C002-C001 — OWNER POPUP / PAUSE VISUAL GATE V01

Date: 2026-09-28
Status: OWNER INPUT REQUIRED
Technical audit: `coordination/sessions/M43-C002-C001/CHATGPT_AUDIT_V01.md`
Review pack: `coordination/sessions/M43-C002-C001/OWNER_POPUP_PAUSE_REVIEW_V01.md`

The implementation is technically accepted.

Please resolve these five visual choices.

## P1 — Popup frame mapping

Current:
- medium = neutral/Pause;
- warning = loss/error;
- reward = committed success;
- small = busy/loading;
- `popup_confirmation_frame.png` is not used because its baked ✓/✗ would become dead visual controls.

Choose:
- **P1-OK** current mapping approved.
- **P1-CHANGE** specify alternative.

## P2 — Pause X button

Current Pause has:
- X close;
- RESUME;
- RESTART;
- HOME.

X behaves like Resume.

Choose:
- **P2-KEEP** keep X.
- **P2-REMOVE** remove X and use Resume / Back only.

## P3 — Stacked popup scrim

Current every popup owns a 60% black scrim, so two stacked popups darken the gameplay twice.

Choose:
- **P3-STACKED** keep current progressive darkening.
- **P3-SINGLE** only one effective 60% scrim regardless of stack depth.

## P4 — Loss confirmation CTA hierarchy

Current:
- destructive action (RESTART / LEAVE) = green primary;
- KEEP PLAYING = cream secondary.

Choose:
- **P4-LOSS-PRIMARY** keep current hierarchy.
- **P4-KEEP-PRIMARY** make KEEP PLAYING green primary; destructive action secondary.

## P6 — Loss copy

Current pre-action:
`You haven't made a move yet, so no Heart or Win Streak is lost.`

Current post-action:
`This counts as a loss:`
`-1 Heart (5 → 4)`
`Win Streak 3 resets to 0`

Choose:
- **P6-OK** approve current copy.
- **P6-CHANGE** provide replacement wording.

P5 text size/density already passes technical responsive checks and needs no separate decision unless the owner dislikes it visually.

After owner acceptance:
- M43-C002 visual row 028 can close;
- M43-C003 Life / Booster Acquire / 2x Acquire becomes next;
- M28-C002 remains waiting for Booster/2x popup integration + final popup-inclusive evidence.
