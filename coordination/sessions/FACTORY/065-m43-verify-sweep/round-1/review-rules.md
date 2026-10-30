VERDICT: CHANGES

## Findings
1. TASKS.md SB-M43-R10-002 is over-claimed. The row requires that "replay farming, ad watching and spending do not become the fastest event path". c010 m06 asserts only that two first clears advance the weekly event across a 3-day gap and that a loss adds nothing. No case replays an already-cleared level against the weekly event, and none checks ad or spend input. The only replay statement is a code comment in `scripts/economy/event_service.gd:169`, and the only replay assertion is the First-Try one in m08, which is a different feature. Fix: add a small m06 assertion (win a level, re-win the same level, progress stays 2), or reopen R10-002 with a gap note. The ad/spend clause can be covered by a source-scan assertion like m09's, or named in the gap note.
2. TASKS.md SB-M43-163 is over-claimed. The row says "Master/Music/SFX/Haptics settings immediately". c011 a02 toggles only SFX, Haptics and Reduced Effects. It never toggles Master or Music, and the title mentions Master but the body never exercises it. The last assertion only checks that the voice is on the SFX or Master bus. Fix: add Master-off and Music assertions to a02, or reopen 163 with a gap note. If Music has no meta-UI path, say so in the evidence text and assert it in the suite.

## Notes
Non-blocking items. The assertions exist but the row text claims a little more than they pin down. Tighten them or reword the evidence.
- R10-005: the suite asserts only the normal Heart cost on a loss, the campaign level kept, and a second attempt not extending the run. "No paid continue" is not asserted.
- R10-007: the ghost marker is asserted. "Never changes difficulty or rewards" is covered only by the no-friend/leaderboard/http source scan.
- 124: m03 asserts robot, level, Collection, robots and the achievement summary. The "key lifetime stats" line (Cleared and the Bests) is not asserted in m03. It is partly covered by m09 (BestFirstTry).
- R09-004 cites t01 and t04, but the grind bound, no losing for credit and finishability are in t11 (max 3 wins) and t03 (a LOST terminal counts nothing). The assertions exist; fix the citation.
- 151 "disabled permissions" is the in-app global toggle (n02), not an OS permission. This is consistent with 146 being kept open.
- R12-004: n02 shows Hearts, Daily and Gift collapsing to one message. Event-ending priority is not in that collapse assertion; it is covered separately by m07's positive control. R12-006 and R12-002 lean on source-string scans (n03, c04). They are weak but backed by behavioural assertions.

Checked and fine:
- The other closed rows are backed by the cited cases: R09-001, 002, 003, 005; 123, 126, 128, 129; R10-001, 003, 004, 006; 144, 145, 147, 148, 149, 151; R12-002, 004, 006; 164.
- The 15 open rows have honest `[OPEN ... factory 065 audit gap]` notes.
- Queue: one DONE row plus 16 READY rows (15 SB-M43 IDs plus C005F-015). I compared the removed ranges against the new rows. Every ID from the old ranges is either DONE or has its own READY row, so none was lost. R09-006 and 131..133 are untouched.
- Diff scope is the CI workflow, two test files and TASKS.md only. No economy, config or production change, and no OS notification permission wiring (146 stays open).
- CI stays on `ubuntu-latest`, with exact `grep -qxF` guards for 12/12 and 28/28.
