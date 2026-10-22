VERDICT: PASS

## Findings
None.

## Notes
Reviewed commit a8a3d518 (`factory/001-refresh-queue`), judging only the committed diff as instructed. This is a CLAUDE_PEER_REVIEW of game rules.

- Scope: only `TASKS.md` changed. The two hunks (`@@ -7 +7,107`, `@@ -10,0 +117,10`) sit above `## Project Status`. `git diff --check` is clean. No checkbox, Project Status bullet or milestone text was touched, and both block headers and their HTML comments are unchanged. This meets CLAUDE.md §0D.4 (the factory loop may edit TASKS.md).
- I re-ran the spec checker on the worktree's TASKS.md. It printed `open IDs: 357 rows: 106 excluded tokens: 12` and then `QUEUE_CHECK PASS`. In the first 80 lines, line 7 is DONE REFRESH-QUEUE, line 8 is the first READY row (SB-M50-BOARD-001), and there are no OWNER rows. The SB-M50-BOARD-001 row says it needs the `validation_only` CI run and then the item is closed. That matches §0C priority and §0D.2.
- Exclusions: I read all 31 excluded IDs in TASKS.md (SB-M08-011..012, SB-M22-016..019/021, SB-UI-020..030/032, SB-M43-135/142/152, SB-M48-001, SB-M50-008..009, SB-M57-017..021, SB-M61-008). Each is a pure keep/never/do-not/preserve constraint, with nothing to build or verify on its own.
- OWNER rows and questions: the nine required decisions are OWNER. Every extra OWNER row waits on one of those decisions (Ranks, world ranges, account provider, ad/IAP provider, No Ads, Friends, pacing table). SB-M43-R09-006's text itself requires owner approval. No OWNER row is blocked only by a visual, F5, phone, ChatGPT or Actions gate. The questions add no currency, timer, energy, ad or IAP mechanic. They only ask about choices that TASKS.md already marks as undecided (§0D.5, §15, economy V1).
- READY verify-close rows match their evidence. For example, SB-M43-R15-001 is "OPEN only for owner visual acceptance", which §0D.1 now gives, and SB-M46-003/008/015 only have the phone/GPU owner gate left.
- Non-blocking: some READY rows depend in part on an OWNER decision:
  - SB-M57-022 needs a sandbox ad/IAP provider.
  - SB-M60-003/004/005 need the pacing table, the provider choice or feature-disable, and the Events/Ranks policy.

  The spec allows this, and those jobs will escalate through the normal loop if the decision is still open. SB-M57-022's row already says so. The M60 row does not, but it is last in the queue.
- Non-blocking: the SB-M22-008..015 row says "slot no-work state" and drops the source qualifier "if approved". Under §0D.1 that approval counts as given, so READY is fine. The SB-M22-008 job should still check that a no-work state is actually specified in the M22 references, and not invent one (§3.2, §10).
- Non-blocking: TASKS.md says the SB-M43-R09-006 question applies only after the M56 simulation. Asking it now is harmless, but the owner may want the M56-017..020 results first.
