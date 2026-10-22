VERDICT: CHANGES

## Findings
1. TASKS.md (Autonomous Queue, new line `- OWNER SB-M22-023 ...`, currently between `READY SB-M43-R10-001..003` and `READY SB-M43-R10-004..007`): the OWNER row sits in the middle of the READY block. It must go after the last READY row, next to the existing `- OWNER SB-UI-008..013` row (line ~126, after `READY SB-M44-031`). Move it there.

## Notes
Verified OK:
- SB-M22-025 tick is justified. `tests/m22_025_booster_texture_budget.gd` exists on origin/main, UI-ADR-007 is in docs/07, and the SB-M22-026 item exists (it appears in both the queue and the checklist).
- SB-M22-023 stays `[ ]`.
- The DONE row replaces the old READY 023/025 row. The 023 status moved to the OWNER row. Nothing was lost.
- Exactly one question line was added, and an owner can answer it.
- Only TASKS.md changed. `git diff --check` is clean.
