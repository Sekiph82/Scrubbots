# M50 Accessibility — CLAUDE milestone master plan V01 (autonomous V02)

Date 2026-10-15 · Claude-authored. Scope: the rows `SB-M50-001..018`. **No art, colour, palette or gameplay change**: colour identity is the core mechanic, and any colour-blind assist (glyphs / patterns on tiles and board) is an owner product + visual decision.

## Deliverables
- `tools/accessibility_audit.gd`: a developer tool (`tools/` is excluded from exports). Pure WCAG contrast, CIE76 ΔE, and Machado-2009 CVD simulation (protan / deutan / tritan, severity 1.0, linear sRGB).
- `tests/m50_accessibility_audit.gd` (4 cases), added to the existing `validation_only` workflow (exact 4/4 guard):
  - a01: reference values (contrast 21 / 1, Lab white, identity, grey invariance, protan reduces red / green);
  - a02: WCAG AA ≥ 4.5 for production text colour constants. The PLAY label is reported: white fill on green is below AA and the navy outline carries legibility;
  - a03: per production level, the closest colour pair under normal and each CVD vision (report, owner evidence);
  - a04: live non-colour cues on the real gameplay screen (supply counts as text, booster icons).

## Pre-computed findings (local Python, same formulas; CI will reproduce)
- Normal vision: every level's closest pair ΔE ≥ 14.3 (L7 / L9 / L10: #D4D7D9 vs #FFFFFF).
- Protanopia: C01 Orange Red #FF4500 vs #9C6926 → ΔE ≈ 9.6 on L1, L2, L5–L8. L10 #00CCC0 vs #D4D7D9 → 8.3.
- Deuteranopia: #FFA800 vs #FFD635 → ≈ 10.2 (L5, L6, L8, L10).
- Tritanopia: L3 #00CC78 vs #00CCC0 → **6.0** (lowest); L9 #FFF8B8 vs #FFFFFF → 8.3.
- WCAG: popup INK on cream 10.8; white on card 6.9; white on royal 6.1; white on navy 16.5; subtitle on panel 9.95; INK on gold 8.3. **White on PLAY green 2.25** (navy outline 7.9).

## Row plan
| Rows | Disposition |
|---|---|
| 001, 003, 004 | evidence via the suite |
| 002 | OWNER_DECISION (colour-blind assist) |
| 005, 013 | existing Reduced Effects coverage (M41 / M43 suites) + M44 coachmarks |
| 006 | M49 matrix |
| 007 | tokens + contrast evidence |
| 008, 009, 011 | partial: counts / icons are live text / art; colour identity is not |
| 010 | icon distinguishability needs owner visual review |
| 012, 015, 017 | partial / OPEN |
| 014 | M57-gated |
| 016 | strategy doc OPEN (Godot screen-reader / AccessKit evaluation) |
| 018 | M43-C005F audits partially cover |

## CI
One planned run + at most one remedial.
