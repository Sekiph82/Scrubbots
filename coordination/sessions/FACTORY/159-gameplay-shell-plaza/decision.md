# 159-gameplay-shell-plaza decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner asked in chat 2026-11-16 for the 6 versions from the owner image.

- Code commit f20c827e: six v03 plaza masters (852x1846) derived only from the owner image (5slot_4col byte-identical), gameplay_shell_geometry.gd fully re-measured, gameplay_screen.gd overlay positions re-measured, owner-lock doc §10 amendment; v02 masters unchanged, unused.
- Test changes: m28_c002_c001 cell floor 80 -> 76 px (narrower canvas; 88 px touch hitbox still guarded), m28_c002_c004 baseline re-pinned to the new geometry.
- Suites LOCAL_PASS (builder): 14 affected suites; reviewer reran static_shell 16/16 and m49_responsive_matrix 8/8. GitHub CI run follows.
- Captures: real L4/L11/L12 in all 6 shells after the level intro video finished.
