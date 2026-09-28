# M43-C003-C001 — OWNER ACQUISITION GATE V01

Date: 2026-09-28
Status: OWNER INPUT REQUIRED
Technical audit: `coordination/sessions/M43-C003-C001/CHATGPT_AUDIT_V01.md`
Review pack: `coordination/sessions/M43-C003-C001/OWNER_ACQUISITION_REVIEW_V01.md`

Technical audit PASS. Please resolve the following owner choices.

## A1 — Life frame / close X

Current candidate stays in the already-approved popup family:
- cream/cyan medium frame;
- royal X.

Choose:
- **A1-KEEP** — keep current family frame + royal X.
- **A1-REFERENCE** — later create an approved Life-specific blue-frame/red-X variant.

## B1 — Selector / Tornado target picker

Current:
- target selection stays inside Booster Acquire;
- Selector exposes solver-safe batch chips;
- Tornado exposes colors present on the board;
- Selector target display is currently capped at 12 chips for fit.

Choose:
- **B1-POPUP** — approve popup target picking for V1.
- **B1-BOARD** — move target selection to an in-board interaction in a later remediation.

If B1-POPUP is selected, owner may also specify whether the current 12-chip cap is acceptable.

## C1 — Rewarded grant while booster is currently illegal

Current:
- if provider allows the rewarded placement, FREE can still grant one charge;
- immediate illegal execution is not attempted/consumed;
- the earned charge remains owned for later.

Choose:
- **C1-KEEP** — keep the saved-charge behavior.
- **C1-HIDE** — hide/disable FREE while immediate booster use is illegal.

## D1 — 2x Acquire layout

Current:
- 2×2 offer grid;
- current level / 15m / 30m / 60m;
- active timed entitlement labels timed purchases as `+15 MIN`, `+30 MIN`, `+60 MIN` to communicate extension.

Choose:
- **D1-OK** current layout/copy.
- **D1-CHANGE** specify desired change.

## E1 — temporary Shop handoff

Current M43-C003 placeholder:
- explicit “Shop coming soon” message;
- states that nothing was charged;
- shows the pending item;
- BACK returns without mutation.

Choose:
- **E1-OK** keep until M43-C006 replaces it.
- **E1-CHANGE** specify temporary wording change.

## F1 — Pause → Restart with the last Heart

Current:
- when Restart would consume the last Heart and leave 0, Restart is not committed;
- canonical Life popup opens;
- current attempt remains intact and no Heart/streak consequence is applied yet.

Choose:
- **F1-GATE** keep this behavior.
- **F1-ALLOW-LAST** allow Restart to consume the last Heart and start the new attempt at 0 Hearts.

After owner decisions:
- ChatGPT records them;
- any required remediation is issued if necessary;
- otherwise SB-M43-049 closes and M43-C003 closes;
- sequencing returns to M28-C002 popup-inclusive final evidence/playtest per the current owner lock.
