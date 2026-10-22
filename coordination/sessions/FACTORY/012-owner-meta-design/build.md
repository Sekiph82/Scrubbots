STATUS: READY

# Build: OWNER-DESIGN — Card Packs, Robots, Gift Bar, Achievements meta progression

## Spec (light path)
Record the owner's 2026-10-22 chat decision (`owner-input.md`) as `coordination/OWNER_META_PROGRESSION_DESIGN_V01.md` (header, verbatim owner text, English summary of binding decisions, open details not invented). In TASKS.md replace the SB-M44-010 open detail with the four unlock levels + doc pointer, add job-sized implementation items with fresh IDs and matching READY queue rows after the existing READY rows. Docs + tracker only; no game code/data.

## Summary
Commit `e61eb1e0` on `factory/012-owner-meta-design`. Files changed:
- `coordination/OWNER_META_PROGRESSION_DESIGN_V01.md` (new): header "Owner decision 2026-10-22 (owner in chat)", owner text verbatim (owner-input.md minus its provenance line, in a `text` fence so the tab tables survive), binding-decisions table, open-details list.
- `TASKS.md`: SB-M44-010 open detail replaced with "Gift Bar 1, Card Packs 20 (with Collection), Robots 25, Achievements screen 35 (stats from L1)" + doc pointer + SB-M44-025..030; new subsection "M44 Meta Progression Design" under M44 (feature-unlock pacing milestone) with SB-M44-025..030; six READY rows appended after the last existing READY row (SB-M43-R09-006).

IDs: SB-M44-024 was skipped because it is already used historically (legacy tracker and the M44 ChatGPT audit reference it); 025..030 appear nowhere else in the repo.

## Acceptance criteria
1. [x] New doc with header, verbatim text, summary table: unlock levels L1/L20/L25/L35, stats from L1, pending-pack inventory, Featured Card model B with all 15 set ranges, Set 01 schedule, +0..+90 offsets, Scrubby at L20, unowned Set 01 card at L30/L40, robots 250 Bot Parts with non-binding targets, 5-stage assembly 50..250 visual only, Gift Bar 10/50/250/500/1000 unchanged, 32 achievements (existing 8 kept; first-time levels only), cosmetic rewards Alternative A only.
2. [x] Open details recorded without inventing: cosmetic items, id/name mapping of existing 8 (6 match by name; `robot_crew`/`first_try_five` match Robot Trio/First Try Hero by metric+target only), L30/L40 reward delivery details, non-Moppy assembly art, Gift Hunter/Gift Master metric mapping.
3. [x] SB-M44-010 open detail replaced with pointer + four unlock levels.
4. [x] Six new items SB-M44-025 (pending packs), 026 (Featured Card schedule + guarantees), 027 (robot assembly + L25), 028 (achievements 32 + stats L1 + L35 screen), 029 (cosmetic rewards), 030 (Gift Bar from first Home, verify + regression test).
5. [x] Six READY rows after the existing READY rows, each cites the doc, none > 200 chars (awk length check: 0 over).

## Validation
- `git diff --stat HEAD~1`: only `TASKS.md` (+16/-1) and the new doc. PASS.
- `git diff --cached --check`: clean. PASS.
- ID uniqueness: for 025..030, `grep -c "^- \[ \] SB-M44-0NN "` = 1 and `grep -c "^- READY SB-M44-0NN "` = 1 each. PASS.
- First READY row still `SB-M50-BOARD-001`. PASS.
- Open items `grep -c "^- \[ \]"`: 357 before, 363 after (+6 = new items). PASS.
- Line endings: TASKS.md diff touches only the 17 intended lines (no whole-file churn). `git status --porcelain` empty after commit.
- No Godot suites: docs/tracker-only change.

## Log
### Round 1
Wrote the design doc and tracker updates above in one commit (`e61eb1e0`). Left the existing SB-M44-010 queue row unchanged (not requested; its item text now carries the new levels).
