APPROVE

## Why
The single commit 16f07ba1 changes only root TASKS.md. It records both dashboard answers (AdMob + Play Billing/StoreKit; No Ads one-time $4.99) faithfully to the Turkish snapshot, removes the two answered questions, flips the six OWNER rows to READY in order and rewrites the three stale READY rows. All three factory reviewers (rules, code, tests; SKILL.md defines three, not four) say PASS. `git merge-tree` is clean (tree ccfd8ba0). The only departure from the spec is the "play" definition ("any finished level, win or loss"). The orchestrator states the owner gave it in chat on 2026-10-22, and the note labels that source separately, so the spec checker's single "lacks 'Open detail'" error is the expected one.

## Acceptance criteria
1. Diff scope: met. I checked it myself: the diff is TASKS.md only, `git diff --check` is empty and the worktree is clean.
2. Checker passes: met, with the sanctioned adaptation. Running the checker verbatim gives the one expected 'Open detail' error. The builder and reviewer-tests each ran an adapted checker and got ANSWERS_CHECK PASS (357 open IDs, 108 queue lines). I checked by hand: no queue row is over 200 characters, the order is right and the new rows sit between READY SB-M57-012 and OWNER SB-M43-136..141.
3. Faithfulness: met. I compared the diff line by line with answers-snapshot.md. AdMob single SDK, a rotating bottom banner in the ad band that never goes over the board, an interstitial every 5 plays between levels and never during gameplay, opt-in rewarded video, Play Billing + StoreKit, and No Ads at $4.99 one-time that removes the banner and interstitials while rewarded videos stay. Nothing is invented: no unit IDs, caps, mediation, consent SDK or product IDs. The §0D.5 live-release owner gate is kept.
4. Factory still reads the queue: met. I checked that the first `^- READY ` line in HEAD:TASKS.md is still SB-M50-BOARD-001.

## For the human
Nothing; this is approved.
