STATUS: READY

# Build: Apply owner answers: ad/IAP provider and No Ads

## Summary
Branch `factory/005-apply-owner-answers`, commit `16f07ba1`. Only root `TASKS.md` changed (11 insertions, 13 deletions; CRLF kept):
- inline `**[OWNER DECISION 2026-10-22, owner via factory dashboard: ...]**` notes appended to `- [ ] SB-M57-001` (AdMob single SDK, bottom banner in ad band never over board, interstitial every 5 plays between levels never during gameplay, opt-in rewarded video, Google Play Billing + Apple StoreKit) and `- [ ] SB-M57-013` (one-time $4.99, removes bottom banner + every-5-plays interstitials, rewarded videos stay);
- the two answered `## Questions for Şekip` lines removed, no new question added;
- six OWNER rows (SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029, SB-M57-013, SB-M43-081) replaced by READY rows directly after `READY SB-M57-012` and before `OWNER SB-M43-136..141`;
- READY rows SB-M57-022, SB-M43-153..160, SB-M57-012 rewritten in place to drop the SB-M57-001 / "undecided" dependency and name AdMob / Play Billing / StoreKit.

Deviation from spec, per orchestrator instruction: the owner resolved the "play" definition in chat on 2026-10-22 ("5 oynama" = every finished level, win or lose). So the SB-M57-001 note says "What counts as a play (owner in chat 2026-10-22): any finished level, win or loss." and the SB-M57-001..011 row says "any finished level counts as a play". There is no "Open detail" text.

## Acceptance criteria
1. [x] Diff scope: `git diff --name-only origin/main...HEAD` prints `TASKS.md`. `git diff --check origin/main...HEAD` prints nothing. `git status --short` is clean.
2. [x] Checker: I ran the spec's checker verbatim with `python -I check_answers.py old.md TASKS.md` (old.md = `git show origin/main:TASKS.md`). It prints `open IDs: 357 queue lines: 108` and one error, `- [ ] SB-M57-001 note lacks 'Open detail'`. That error is expected: the open detail was resolved, as explained above. I also ran an adapted copy that differs in one line: `"Open detail", "counts as"` became `"counts as", "any finished level, win or loss"`. It prints `open IDs: 357 queue lines: 108` / `ANSWERS_CHECK PASS`. All other checks pass under both versions (rows at most 200 chars, order, coverage, rewrites). Neither checker is committed.
3. [x] Faithfulness: the notes and rows match answers-snapshot.md plus the owner's chat definition of a play. Nothing else was added: no ad unit IDs, caps, mediation, consent SDK, product ID or regional prices.
4. [x] `git show HEAD:TASKS.md | head -80`: the first `^- READY ` line is `- READY SB-M50-BOARD-001 — run Android ...`.

## Validation
- Spec checker (verbatim): one expected failure ('Open detail'; the detail was resolved by the owner).
- Adapted checker (resolved play definition): ANSWERS_CHECK PASS.
- `git diff --check origin/main...HEAD`: clean.
- No Godot/tests: change is TASKS.md-only.

## Log
### Round 1
Applied both dashboard answers and the owner's chat clarification of "play" to TASKS.md in a single commit, `16f07ba1`. I trimmed the SB-M57-001..011 row to 200 characters by dropping "only" from "AdMob only".
