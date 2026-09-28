# M43-C001 — OWNER RESULTS GATE V01

Date: 2026-09-28
Status: OWNER INPUT REQUIRED
Basis: `coordination/sessions/M43-C001A/CHATGPT_AUDIT_V01.md`

The Results foundation is technically accepted. The following decisions are still required before final Victory/Results production UI.

## A. Replay gate

### A1 — Shipping Replay button

Choose one:

- **A1-NO:** No Replay button on Results in V1.
- **A1-YES:** Allow a Replay button on a WON Results screen for the level just completed.

Existing owner rules already lock:
- Replay gives no first-clear progression economy.
- Replay does not advance Win Streak.
- No shipping Level Select exists.

If **A1-NO**, the remaining Replay sub-decisions are unnecessary and SB-M43-006/011 can be resolved as no-shipping-Replay.

If **A1-YES**, owner must additionally decide:
- replay post-action loss/restart Heart cost;
- whether replay loss resets the active progression Win Streak or is fully streak-neutral;
- whether replay may consume booster charges / paid 2x;
- after replay WON, the zero-progression-reward Results path returns to the real current frontier;
- launch is limited to the just-completed level, not a Level Select.

## B. Victory / Results visual master

Owner program already requires Results to be consistent with the Life/Help popup family.

Decide the remaining composition choices:

### B1 — Top composition

- **B1-A:** celebrating robot above/overlapping the popup frame + small Victory emblem in the header.
- **B1-B:** Victory emblem as the top crest + robot pose inside the body.
- **B1-C:** celebrating robot only; no Victory emblem.

Until equipped-robot selection exists, Scrubby is the safe runtime default. Later the approved per-robot victory pose can follow equipped-robot authority.

### B2 — Continue CTA

- **B2-A:** green/yellow Life/Help-family button style.
- **B2-B:** existing cyan arrow `continue_button_frame.png`.

### B3 — LOST routing

- **B3-A:** LOST does not use the Victory Results master; route loss to the dedicated M43-C004 Fail/Retry popup family.
- **B3-B:** create both WON and LOST variants of the Results master.

## C. Already-cleared / no-next-content copy

Current technical text is:
- replay/already-cleared: no progression reward;
- unavailable next content: `Level N is coming soon.`

Owner may approve these semantics now or request different player-facing wording during visual-master production.

## D. Celebration motion

The data order is already fixed:
1. first-clear SB;
2. Win Streak SB;
3. Bot Parts;
4. Gift Meter;
5. cards if actually committed.

Exact timing/animation/SFX/haptics and Reduced Effects presentation remain part of the visual master / final C001 implementation after owner approval.
