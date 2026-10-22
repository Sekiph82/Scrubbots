APPROVE

## Why
Commit 685a8403 changes only root TASKS.md. It records the owner's two dashboard answers, cloud-save sign-in and the Scrub Bucks pack ladder, as faithful translations of the Turkish text. It also removes the two answered questions and flips the four matching OWNER rows to READY in the required place and order. The open ad/IAP and No Ads questions are not touched, the pack row still leaves live store publishing to the owner (§0D.5), and nothing here needs an owner action. All three factory reviews (rules, code, tests; SKILL.md defines three, not four) are PASS with no real-problem notes, and `git merge-tree --write-tree origin/main factory/004-apply-owner-answers` is clean (exit 0).

## Acceptance criteria
1. Diff scope: met. I checked it myself: the diff stat shows only TASKS.md (+6/-8), the worktree is clean, and both build.md and reviews report that `git diff --check` is clean.
2. Checker passes: met. build.md reports `ANSWERS_CHECK PASS` (357 open IDs, 108 queue lines) plus the 7-error control, and reviewer-tests re-ran it independently with the same result. I also read the full `-U0` diff by hand. It has exactly 4 READY rows after SB-M56-011 and before OWNER SB-M43-136..141, the 4 OWNER rows removed, 2 question lines removed, and 2 notes appended with the original item text unchanged.
3. Faithful decisions: met. I compared the notes with answers-snapshot.md myself:
   - Sign-in: Android uses Google Play Games Saved Games; iOS uses Game Center + iCloud; both free; no own server; no separate account or e-mail login.
   - Packs: the five pairs exactly; the scrubbucks_100 / scrubbucks_550 / … ID pattern; amounts adjustable after the M56 simulation.
   - Nothing was added to either answer. The SB-M57-001 store-wiring dependency and owner-only live publishing are stated in the rows and were not invented as answers.
4. Factory still reads the queue: met. I checked it myself: the first `^- READY ` line in the first 80 lines of HEAD:TASKS.md is `- READY SB-M50-BOARD-001 — ...`.
