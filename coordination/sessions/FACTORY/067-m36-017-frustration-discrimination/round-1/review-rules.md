VERDICT: PASS

## Findings
None.

## Notes
- data/config is not in the branch diff. Only tools/difficulty_playtest.gd, tests/m36_frustration_fixtures.gd, the doc, AGENTS.md, TASKS.md and 11 evidence JSONs changed. No versioned model was edited (CLAUDE.md 11).
- The new path is opt-in. The only change to existing behaviour is the guard that makes `--fixtures` without `--frustration` exit 1. No default output changed.
- L1 is labelled "sanity only, never a calibration reference" in the doc, and TASKS.md says "L1..L10 informational only". No lane or model was tuned from it.
- Disclosures are honest. Ties are stated: all 10 anchors cleared 32/32 and all 45 anchor pairs tie at retryRisk 0. The L1 miss (C 3/32 > S 2/32) is reported with the Wilson overlap. The 26-41 min run time, over the ~20 min guide, is disclosed. The doc's "35% + 20%" of F weight matches the v2 weights (retryRisk 0.35, lateFailure 0.20).
- TASKS.md edits are limited to the SB-M36-017 queue row and checklist line, and match the evidence. The doc's "9 of 10 anchors fall NOVICE to SKILLED" is consistent with its table, where `hard_rings10h_26` is flat.
- Nit: the 32-run evidence is not re-runnable in review (41 min). I only inspected the committed tables against the doc.
