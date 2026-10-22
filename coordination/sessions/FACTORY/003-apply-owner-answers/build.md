STATUS: READY

# Build: Apply owner answers: launch languages and RANKS policy

## Summary
Branch `factory/003-apply-owner-answers`, commit `a8efa8ab`. Only root `TASKS.md` changed (CRLF line endings kept):
- SB-M51-005 item gets an appended note: OWNER DECISION 2026-10-22, owner via factory dashboard, launch languages English and Turkish.
- SB-M43-131 item gets an appended note with the RANKS policy: two tables; all-time = highest campaign level reached; weekly = levels completed that week, reset Monday 00:00 UTC; nothing purchasable with money or boosters counts. This is a translation of the owner's Turkish answer and adds nothing to it.
- The two answered lines are removed from `## Questions for Şekip`. The other 8 stay as they were.
- The OWNER rows SB-M51-005, SB-M43-131..133 and SB-M56-011 are now READY rows with the decision in each row. They sit in the same place: right after `READY SB-M60-001..006` and before the first remaining OWNER row, with SB-M56-011 after SB-M43-131..133.
- No checkbox was ticked.

## Acceptance criteria
1. [x] Diff scope: `git diff --name-only origin/main...HEAD` printed `TASKS.md`, `git diff --check origin/main...HEAD` printed nothing, and `git status --short` was empty after the commit.
2. [x] Checker: I extracted the spec's script to the scratchpad as `check_answers.py`, ran `git show origin/main:TASKS.md > old.md`, then ran `python -I check_answers.py old.md TASKS.md`. Output: `open IDs: 357 queue lines: 108` then `ANSWERS_CHECK PASS`.
3. [x] Faithful decisions: the SB-M43-131 note and the SB-M43-131..133 row state only the two tables, all-time highest campaign level, weekly levels completed with a Monday 00:00 UTC reset, and no money or booster purchases. They add no reward, season length, tie-break or backend. The SB-M51-005 note and row name only English and Turkish.
4. [x] Factory still reads the queue: the first `^- READY ` line in `git show HEAD:TASKS.md | head -80` is `- READY SB-M50-BOARD-001 — ...`.

## Validation
- I ran the spec checker script (above): it printed PASS.
- `git diff --check`: clean.
- I did not run Godot or the game suites, because this job changes no code (TASKS.md only).

## Log
### Round 1
I applied both owner answers from answers-snapshot.md to TASKS.md with a Python split/join on CRLF, so the line endings stay intact. The three OWNER rows were next to each other directly after the last READY row, so I replaced them in place. That puts the new READY rows in the required position. I left factory/answers.md alone, because the orchestrator updates it after merge.
