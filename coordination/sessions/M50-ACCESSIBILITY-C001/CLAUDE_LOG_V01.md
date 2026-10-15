# M50 Accessibility — CLAUDE_LOG_V01 (autonomous V02)

Plan: `CLAUDE_M50_MASTER_PLAN_V01.md` · 2026-10-15 · Builder: Claude Code.
**Status: `IMPLEMENTED_CI_PASS (4/4) / OWNER_DECISIONS_NEEDED / AWAITING_PEER_REVIEW`.** No production code, art or colour changed.

## Built
- `tools/accessibility_audit.gd` (developer tool, export-excluded `tools/`): WCAG contrast ratio, CIE76 ΔE*ab, Machado-2009 CVD simulation (protan / deutan / tritan, severity 1.0, linear sRGB), `palette_report()`.
- `tests/m50_accessibility_audit.gd`: 4 cases. Workflow: 37 suites, exact `M50 accessibility audit evidence: PASS (4/4 cases, 0 fail)` guard.

## CI — run [38748970964](https://github.com/Sekiph82/Scrubbots/actions/runs/38748970964) on `bf333df4` (first planned run, green)
- validate = success ([job 116470014421](https://github.com/Sekiph82/Scrubbots/actions/runs/38748970964/job/116470014421)); export = skipped ([job 116476151361](https://github.com/Sekiph82/Scrubbots/actions/runs/38748970964/job/116476151361)).
- Artifact `11981271009`: 39 log files, no apk / pck / ipa. `import script_diag=0`.
- **37/37 PASS**: CP06 16/16, M44 23/23, M45 8/8, M49 8/8, **M50 4/4**, `aggregate=PASS`.

## Evidence from the log (CI-computed, identical to the pre-computed local values)
- Contrast (WCAG AA 4.5 PASS):
  - popup INK on cream 10.78;
  - white on royal 6.07;
  - white on card 6.93;
  - white on navy 16.54;
  - subtitle on panel 9.95;
  - INK on gold 8.28.
- **FINDING 1 (owner visual):** the PLAY label's white fill on GREEN is **2.25:1**; legibility relies on the 7.90:1 navy outline.
- Closest colour pair per level:

| Level | normal | protan | deutan | tritan |
|---|---|---|---|---|
| L1 Hazard Bot | 53.1 | **9.6** (#FF4500 / #9C6926) | 25.8 | 37.7 |
| L2 Apple | 54.1 | **9.6** | 25.8 | 45.4 |
| L3 Palm Tree | 40.2 | 30.3 | 27.5 | **6.0** (#00CC78 / #00CCC0) |
| L4 Orange Cat | 35.4 | 21.1 | 26.9 | 12.9 |
| L5 Party Toucan | 25.5 | **9.6** | 10.2 | 16.1 |
| L6 Chicken | 25.5 | **9.6** | 10.2 | 20.9 |
| L7 Pigeon | 14.3 | **9.6** | 14.3 | 14.3 |
| L8 Butterfly | 25.5 | **9.6** | 10.2 | 24.1 |
| L9 Frog | 14.3 | 10.7 | 14.3 | **8.3** |
| L10 Ice Cube | 14.3 | **8.3** | 10.2 | 11.7 |

- **FINDING 2 (owner decision, SB-M50-002/003):** colour identity on tiles and board has no non-colour cue.
  - Under simulated protanopia, C01 Orange Red vs the brown #9C6926 falls to ΔE ≈ 9.6 in 7 of 10 levels.
  - Under tritanopia, L3's two greens fall to 6.0.
  - Quantities ARE non-colour (live count text, a04), and boosters are identified by icon art (a04).

## Row disposition (requested tracker update for ChatGPT; local TASKS.md write is denied)
| Rows | Status |
|---|---|
| 001 | done |
| 003 | done (simulation-based) |
| 004 | done (text constants) |
| 006 | via M49 |
| 007 | done (tokens) |
| 009 | partial (counts live) |
| 002 | **OWNER_DECISION**: colour-blind assist (e.g. a per-C-ID glyph on tiles; new art / visual approval) |
| 008 / 011 | partial (colour identity) |
| 010 | owner visual |
| 005 / 013 | existing Reduced Effects coverage, not re-audited here |
| 012 / 015 / 016 / 017 / 018 | OPEN |
| 014 | M57-gated |

## Owner decision requests (concise)
1. Colour-blind assist: add a non-colour cue per colour (glyph / pattern) to slot / supply tiles (and optionally the board)? This needs new art and owner visual approval.
2. The PLAY label: keep outline-only legibility, or adjust the text or button colour?

## Next
- A fresh `CLAUDE_PEER_REVIEW` of M50.
- The M49 strengthened m06 / m07 test changes ride the next planned run.
