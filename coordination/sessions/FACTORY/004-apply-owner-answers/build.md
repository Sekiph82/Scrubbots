STATUS: READY

# Build: Apply owner answers: cloud-save sign-in and Scrub Bucks packs

## Summary
Applied the two owner answers from answers-snapshot.md (2026-10-22, owner via factory dashboard) to root `TASKS.md` on branch `factory/004-apply-owner-answers`, commit `685a8403`. Only `TASKS.md` changed (CRLF line endings kept).
- Added an inline `**[OWNER DECISION 2026-10-22, owner via factory dashboard: ...]**` note to `SB-M43-153` (Android Google Play Games Saved Games; iOS Game Center + iCloud; both free; no own server; no separate account or e-mail login) and to `SB-M57-012` (the five pairs $0.99→100, $4.99→550, $9.99→1200, $19.99→2600, $49.99→7000; IDs scrubbucks_100, scrubbucks_550, …; amounts may be adjusted after the M56 economy simulation). These are faithful translations of the Turkish answers and add nothing else.
- Removed the two answered lines from `## Questions for Şekip`. The other 6 lines are unchanged.
- Removed the OWNER rows SB-M43-153..160, SB-M49-030, SB-M54-031 and SB-M57-012. Added READY rows in that order directly after `READY SB-M56-011` and before `OWNER SB-M43-136..141`, using the spec's example rows. The SB-M43-153..160 row keeps the SB-M43-158 restore dependency on SB-M57-001. The SB-M57-012 row says store wiring waits on SB-M57-001 and live publishing needs the owner (§0D.5).
- No checkboxes were ticked, and the ad/IAP and No Ads questions were not touched.

## Acceptance criteria
1. [x] Diff scope: `git diff --name-only origin/main...HEAD` printed `TASKS.md`. `git diff --check origin/main...HEAD` printed nothing. `git status --short` is clean. origin/main = f609a5be.
2. [x] Checker: `python -I check_answers.py old.md TASKS.md` printed `open IDs: 357 queue lines: 108` / `ANSWERS_CHECK PASS`. As a control, running it with the unchanged origin/main file as both inputs printed 7 errors, which matches the spec.
3. [x] Faithful decisions: the note text is a literal translation of the snapshot ("kendi sunucumuz gerekmez" is rendered as "no own server needed"). There is no conflict policy, Firebase, bonus label, regional price or SDK choice. The SB-M57-001.. and SB-M57-013 questions and rows are unchanged.
4. [x] Factory still reads the queue: `git show HEAD:TASKS.md | head -80 | grep -m1 "^- READY "` gives `- READY SB-M50-BOARD-001 — ...`.

## Validation
- Spec checker script (saved in the scratchpad, not committed): PASS.
- `git diff --check`: clean.
- No Godot suites were run because this job changes only TASKS.md and touches no code.

## Log
### Round 1
Made the edits with a small Python script that preserves CRLF. Ran the checker both ways and verified criteria 1 to 4. Made one commit, `685a8403`.
