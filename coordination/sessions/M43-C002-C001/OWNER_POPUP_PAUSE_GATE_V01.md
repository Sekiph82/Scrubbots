# M43-C002-C001 — OWNER POPUP / PAUSE VISUAL GATE V01

Date: 2026-09-28
Status: OWNER APPROVED
Technical audit: `coordination/sessions/M43-C002-C001/CHATGPT_AUDIT_V01.md`
Review pack: `coordination/sessions/M43-C002-C001/OWNER_POPUP_PAUSE_REVIEW_V01.md`

The implementation is technically accepted.

Owner decision recorded 2026-09-28: **all current candidates approved as-is.**

## P1 — Popup frame mapping

Current:
- medium = neutral/Pause;
- warning = loss/error;
- reward = committed success;
- small = busy/loading;
- `popup_confirmation_frame.png` is not used because its baked ✓/✗ would become dead visual controls.

Decision: **P1-OK** — current mapping approved.

## P2 — Pause X button

Current Pause has:
- X close;
- RESUME;
- RESTART;
- HOME.

X behaves like Resume.

Decision: **P2-KEEP** — keep X; it resumes exactly like Resume/Back.

## P3 — Stacked popup scrim

Current every popup owns a 60% black scrim, so two stacked popups darken the gameplay twice.

Decision: **P3-STACKED** — keep current progressive darkening.

## P4 — Loss confirmation CTA hierarchy

Current:
- destructive action (RESTART / LEAVE) = green primary;
- KEEP PLAYING = cream secondary.

Decision: **P4-LOSS-PRIMARY** — keep current hierarchy.

## P6 — Loss copy

Current pre-action:
`You haven't made a move yet, so no Heart or Win Streak is lost.`

Current post-action:
`This counts as a loss:`
`-1 Heart (5 → 4)`
`Win Streak 3 resets to 0`

Decision: **P6-OK** — approve current copy.

P5 text size/density already passes technical responsive checks and is accepted with the rest of the current candidate family.

## Rewarded-video placement decision

Do **not** add a generic `WATCH / GET` CTA to the M43-C002 Pause, Restart/Home confirmation, reward, network/error, busy/loading, or generic insufficient-SB surfaces. Rewarded-video CTAs belong to acquisition-specific flows in M43-C003, where eligibility, reward semantics, exactly-once grants and ad-unavailable handling are defined. In particular, the existing M43-C003 plan already covers rewarded +1 Heart and rewarded one-use Booster acquisition.

Closure:
- M43-C002 visual row 028 is owner-approved and may close;
- M43-C003 Life / Booster Acquire / 2x Acquire is next;
- M28-C002 remains waiting for Booster/2x popup integration + final popup-inclusive evidence.
