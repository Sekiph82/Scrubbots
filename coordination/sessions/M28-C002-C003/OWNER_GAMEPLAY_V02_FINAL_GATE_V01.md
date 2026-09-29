# M28-C002-C003 — OWNER GAMEPLAY V02 FINAL GATE V01

Date: 2026-09-29
Status: **TECHNICAL REMEDIATION AUDITED PASS / OWNER FINAL REPLAY REQUIRED**

Initial technical audit:
`coordination/sessions/M28-C002-C003/CHATGPT_AUDIT_V01.md`

Final five-finding remediation audit:
`coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_V02.md`

Owner review checklist:
`coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`

Technical state:
- SB-M28-C002-012 PASS;
- SB-M28-C002-013 PASS;
- SB-M28-C002-019 PASS;
- M28-C002-C003-R01 V02 five-finding remediation: **AUDITED_PASS**;
- SB-M28-C002-020 remains OPEN only for owner final replay / visual acceptance.

## Historical owner playtest failure

The prior final hands-on playtest found that timed 2x remained entitled/counting after a level transition but live gameplay reverted to 1x.

That failure triggered M28-C002-C003-R01.

The owner then expanded the remediation to five findings:

1. active timed 2x must auto-start every new gameplay/level while time remains;
2. remove visible WAITING / ACTIVE slot words;
3. railway-first Scrubbot travel;
4. dynamic logical-pixel grid + subtle bevel;
5. exact selected Home background.

## V02 technical result

Implementation:
`041729c92b57517e2c203306b0666f341c75eee5`

Independent verdict:
`AUDITED_PASS / OWNER FINAL REPLAY REQUIRED`

Current railway-first route-choice authority:
`coordination/OWNER_SCRUBBOT_RAILWAY_FIRST_ROUTING_V02.md`

## Owner final replay

No final owner acceptance yet.

Owner must replay/inspect all five:

1. Buy timed 2x, finish a level, Continue: next level starts live 2x; repeat after app close/relaunch while time remains.
2. Five-slot and temporary sixth-slot row contain no visible WAITING / ACTIVE words.
3. Scrubbots remain on the perimeter railway and leave near the assigned target, with no long cross-board shortcut.
4. Grid/bevel is visually readable on small, medium and dense boards.
5. Home uses the selected `assets/ui/final/home/background/home_background.png`; review Scrubby placement and short/wide/tablet side-band seam.

SB-M28-C002-020 and M28-C002 remain open until the owner explicitly accepts this replay.
