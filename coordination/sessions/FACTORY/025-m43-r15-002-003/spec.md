# Verify-close Settings popup visual family and Daily Rewards containment

> Feature: SB-M43-R15-002..003 — Settings popup visual-family remediation and Daily Rewards containment fix at 683x1366 + responsive matrix

## Context
Both items are already implemented (code commit 24828bb, logs in `coordination/sessions/M43-OWNER-R15/SB-M43-R15-002_CLAUDE_LOG_V01.md` and `...-003_...`) and technically audited PASS (`CHATGPT_AUDIT_V01.md` §2-3). Only the owner visual acceptance was open, and CLAUDE.md §0D.1 gives it. TASKS.md still shows the rows as `- [ ]` (lines ~1310-1311) and the queue row as `READY` (line 25).

- Settings: `scripts/ui/settings_panel.gd` uses the shared `BasePopup.FrameBox` large frame, royal SETTINGS plaque, X + CLOSE, cream `BasePopup.ROW` cards, navy labels and themed toggles/sliders. State handlers still go only through the AppState setters (no second authority).
- Daily: `scripts/ui/daily/daily_screens.gd` has no floating hero. It uses a contained calendar icon, a flame + streak pair, and fixed 210x280 day cards (3 x 210 + 2 x 8 = 646 px, which fits the 652 px body).
- Tests: `tests/m43_r15_owner_remediation.gd` (cases g01-g03 and d01-d03 cover the 683x1366, 720x1280, 1080x1920, 1080x2160, 1170x2532, 1290x2796 and 1536x2048 matrix), plus `tests/m41_settings.gd`, `tests/m43_master_c009_daily.gd`, `tests/m39d_daily_collection.gd`, `tests/m49_responsive_matrix.gd`. These suites are in `.github/workflows/android-family-first10.yml`.
- Later commits touched `settings_panel.gd` (M50 colour-symbol toggle, M51 localization keys). The spec writer ran three of the suites in the worktree and all pass (below), so no regression is known.

## Requirements
1. Make no gameplay, economy or Daily-truth change. Change code only if a suite below fails on the job branch; in that case fix the layout minimally and keep Settings semantics and the Daily claim authority unchanged.
2. Re-verify the layout and containment of both screens with the existing tests; do not add art or mechanics.
3. In `TASKS.md`, tick `SB-M43-R15-002` and `SB-M43-R15-003` (`- [x]`) with a short "CLOSED [2026-10-22]" note. The note cites the passing suites, the technical audit file, and that owner visual acceptance is given under CLAUDE.md §0D.1. Change the queue row `READY SB-M43-R15-002..003` (line ~25) to `DONE`, following the wording of the neighbouring DONE rows.
4. Do not touch other tasks, `project.godot`, or shipping code unless requirement 1 applies.

## Acceptance criteria
Let `GODOT` be the local 4.7.2 console binary from AGENTS.md. Run `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd` for each suite.
1. `m43_r15_owner_remediation` prints `M43 owner R15 evidence: PASS (18/18 cases, 0 fail)`. This covers Settings frame, behaviour and containment (g01-g03) and Daily containment at 683x1366 plus the six other viewports (d01-d03).
2. `m41_settings` prints `M41 V01 settings evidence: PASS`.
3. `m43_master_c009_daily` prints `M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)`.
4. `m39d_daily_collection` and `m49_responsive_matrix` end in their PASS line with no FAIL line.
5. `m43_r15_001_r01_sequential_unlock` prints its PASS line (14/14).
6. `grep -n "SB-M43-R15-00[23]" TASKS.md` shows both item rows as `- [x]` with a CLOSED note, and the queue row no longer says `READY`.
7. `git diff --stat main` lists only `TASKS.md` and files under `factory/` (or a minimal layout fix plus its test, if requirement 1 triggered).

## Out of scope
New art generation, new settings or Daily mechanics, changing reward values or the streak, the Rewarded Ads surface (R15-001), edits to the M50 symbol toggle behaviour, running GitHub Actions manually.

## Assumptions
- Owner visual sign-off is given (CLAUDE.md §0D.1), so acceptance is technical. The existing 7-viewport containment tests are the accepted evidence.
- The work is a verify-close because the code already exists on main. If a suite fails after the M50/M51 changes, fixing it is in scope, since the items' requirements (containment, no clipping) would be violated.
