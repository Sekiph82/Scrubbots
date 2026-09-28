# M43-C003-C001 — OWNER ACQUISITION GATE V01

Date: 2026-09-28
Status: OWNER APPROVED
Technical audit: `coordination/sessions/M43-C003-C001/CHATGPT_AUDIT_V01.md`
Review pack: `coordination/sessions/M43-C003-C001/OWNER_ACQUISITION_REVIEW_V01.md`

Technical audit PASS. Owner decisions recorded 2026-09-28.

## A1 — Life frame / close X

Current candidate stays in the already-approved popup family:
- cream/cyan medium frame;
- royal X.

Decision: **A1-KEEP** — keep current family frame + royal X.

## B1 — Selector / Tornado target picker

Current:
- target selection stays inside Booster Acquire;
- Selector exposes solver-safe batch chips;
- Tornado exposes colors present on the board;
- Selector target display is currently capped at 12 chips for fit.

Decision: **B1-POPUP** — popup target picking approved for V1. Current 12-chip display cap is accepted for this cycle.

## C1 — Rewarded grant while booster is currently illegal

Current:
- if provider allows the rewarded placement, FREE can still grant one charge;
- immediate illegal execution is not attempted/consumed;
- the earned charge remains owned for later.

Decision: **C1-KEEP** — keep saved-charge behavior.

## D1 — 2x Acquire layout

Current:
- 2×2 offer grid;
- current level / 15m / 30m / 60m;
- active timed entitlement labels timed purchases as `+15 MIN`, `+30 MIN`, `+60 MIN` to communicate extension.

Decision: **D1-OK** — current 2×2 layout and extension copy approved.

## E1 — temporary Shop handoff

Current M43-C003 placeholder:
- explicit “Shop coming soon” message;
- states that nothing was charged;
- shows the pending item;
- BACK returns without mutation.

Decision: **E1-OK** — keep current placeholder until M43-C006 replaces it.

## F1 — Pause → Restart with the last Heart

Current:
- when Restart would consume the last Heart and leave 0, Restart is not committed;
- canonical Life popup opens;
- current attempt remains intact and no Heart/streak consequence is applied yet.

Decision: **F1-GATE** — keep the last-Heart restart gate.

Closure:
- all owner choices approved;
- no remediation required;
- SB-M43-049 closes;
- M43-C003 closes;
- sequencing returns to M28-C002 popup-inclusive final evidence/playtest per the owner lock.
