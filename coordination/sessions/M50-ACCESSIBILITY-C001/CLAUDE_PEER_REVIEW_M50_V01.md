# M50 Accessibility — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`** (fresh-context Claude subagent, read-only, 2026-10-15). Not a ChatGPT independent audit. Findings condensed; **[builder]** = disposition.

## Verdict (reviewer): PASS_WITH_DEFECTS — math correct, framing needs a caveat
- WCAG luminance / contrast, sRGB transfer, CIE76 Lab (D65): correct.
- Machado 2009 severity-1.0 matrices: all 27 coefficients match the published tables; applied in linear RGB with gamut clipping (as DaltonLens).
- `palette_report` pair search: correct. All reported numbers reproduced independently.
- CI 38748970964 verified (validate success, export skipped, logs only, 37/37, M50 4/4).
- `tools/` is export-excluded (exclusion list + preset filter); nothing in `scripts/`, `scenes/` or `project.godot` references it.
- Production risk: none.

## Defects → disposition
1. **MEDIUM — CIE76 understates the CVD findings.**
   - Finding: with CIEDE2000, protan #FF4500 / #9C6926 is **3.3** (not 9.6), tritan L3 is 3.8 (not 6.0), deutan #FFA800 / #FFD635 is 6.7, protan L10 is 5.7. The protan C01 / brown pair is the true worst, not tritan L3. Severity 1.0 = full dichromacy.
   - **[builder]** `ciede2000()` added to the tool and validated in-suite against 4 published Sharma test pairs (also checked locally in Python: 2.0425 / 2.3669 / 27.1492 / 1.0000). a03 now prints both metrics. The log and owner request were corrected.
2. **LOW — miscount.**
   - Finding: protan 9.6 appears in 6 levels (L1, L2, L5–L8), not 7.
   - **[builder]** Corrected in the log.
3. **LOW — a04 could pass vacuously.**
   - **[builder]** Now asserts at least one front was checked.
4. **LOW — weak references; builder thresholds not labelled.**
   - **[builder]** Added the sRGB red Lab reference (53.24, 80.09, 67.20) and the CIEDE2000 reference pairs. The ΔE ≥ 10 floor is labelled a builder sanity floor. Ignoring PANEL alpha 0.94 is noted as a known simplification.
5. **LOW — overclaimed rows.**
   - **[builder]** 004 and 007 → PARTIAL.

## NOT_RUN (reviewer)
- No local Godot.
- No colour-science library cross-check.
- Rows 005 / 013 / 006 not re-inspected.
- No visual / icon review (010).
