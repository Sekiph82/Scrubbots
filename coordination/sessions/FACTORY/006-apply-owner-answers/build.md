STATUS: READY

# Build: Apply owner answers: worlds, Friends, unlock levels, ScrubBox bonus

## Summary
Only `TASKS.md` changed (one commit on factory/006-apply-owner-answers). Four inline OWNER DECISION notes appended to SB-M43-136 (20-world table, open detail: completion conditions), SB-M61-001, SB-M44-010 (open detail: booster-to-level and unnamed-feature unlocks), SB-M43-R09-006. Seven OWNER queue rows became READY in place (directly after READY SB-M43-081). The four question lines were removed; the Questions heading and comment are kept. CRLF line endings kept.

## Acceptance criteria
1. [x] Diff scope: `git diff --name-only origin/main...HEAD` prints only `TASKS.md`; `git diff --check origin/main...HEAD` is empty; `git status --porcelain` is empty.
2. [x] Checker: `python -I chk.py old.md TASKS.md` printed `open IDs: 357 queue lines: 108`, then `ANSWERS_CHECK PASS`.
3. [x] Faithfulness: names and ranges generated from the snapshot's 20-world table; nothing invented. Open details are recorded as notes, with no new question.
4. [x] First `^- READY ` in the first 80 lines of HEAD:TASKS.md is still `SB-M50-BOARD-001`.

## Validation
Checker above passed. No Godot or code involved.

## Log
### Round 1
Applied the edit with a one-off script that kept CRLF. Committed.
