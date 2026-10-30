APPROVE

## Why
All three round-1 reviews are PASS, and their notes describe no real problem. The Home "1" vs Profile "4" mismatch comes from the capture fixture, not the app. `git merge-tree` reports no conflicts. I looked at the 1080x1920 capture myself: it shows the hero card, the 2x3 tiles, the Personal Bests table, the note and the three buttons. It fits without clipping. Visual approval is by Claude under the owner-delegated authority of 2026-10-31.

## Acceptance criteria
1. m43_master_c010_meta passes with the new hero, 6-tile and bests assertions: met. build.md shows 12/12, and review-tests re-ran it independently.
2. m43_personal_ranks still passes: met. 8/8, re-run by review-tests.
3. Other tests that reference the profile node names, and the texture budget, pass: met. m22_026 passes with the budget raised from 21 to 32 MiB under the file's own "measured + ~10%" rule, and m49 passes 8/8.
4. Capture at 1080x1920 shows the required structure, and the other sizes are clean: met. I viewed the 1080x1920 PNG. build.md reports `META_EVIDENCE CLEAN` for all 5 sizes and says the comparison with the master was by eye.
5. Action buttons are at least 88 px tall, asserted in the suite: met, per build.md and review-tests.
6. `git diff --check` is clean and there are no parse errors: met, per build.md.
7. New assets and manifest provenance: met. The diff has two PNGs with `.import` files under `assets/ui/final/profile/`, and the manifest has +26 lines.
8. TASKS.md shows SB-M43-125-REBUILD done: met. The queue row at line 63 starts with DONE.
