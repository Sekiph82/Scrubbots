STATUS: READY

# Build: SB-M52-005 validate rectangular production art (light path)

## Summary
No rectangular production art exists (all 10 owner images square, per docs/LEVEL_ART_TECHNICAL_AUDIT.md), so the item is not ticked. TASKS.md only (commit 42d4f01e): added 2026-10-22 note with pipeline rectangular-capability evidence, removed the READY queue row, added SB-M52-005 to the Not-queued comment as "(conditional: when rectangular production art is supplied)". No art or fixture added; the rectangular path is not broken.

## Acceptance criteria
1. [x] Existing rectangular tests run headless (exit 0, no SCRIPT/Parse Error), LOCAL_PASS:
   - m35_level_catalog: PASS (24x28 rect legal, rejected only by the S6-C square-shell gate, not exposed to production catalog)
   - m36_v02_migration: PASS (59x20 MEDIUM rectangular production-legal)
   - m32_c002_board_independent_size: PASS (86 checks, 0 failed; rectangles)
   - m25_scale_evidence: PASS
2. [x] No production art / no fixture in catalog: diff is TASKS.md only.
3. [x] TASKS.md note + conditional move + READY row removed (CRLF preserved).

## Validation
git diff --check clean; git status shows only pre-existing untracked Godot-import .uid files.

## Log
### Round 1
As above.
