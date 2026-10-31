STATUS: READY

# Build: Owner polish queue (owner playtest 2026-10-31)

## Spec (light path)
Owner playtested all 30 levels on the phone (all WON, "oyun akici"). Turn the feedback into TASKS.md work:
- 11 rows SB-POLISH-001..011 at the TOP of `## Autonomous Queue`, in the owner's order: 001-008, 010, 011 READY; 009 OWNER ("waits for bow/turn/full_turn videos").
- A matching `- [ ]` item for each in a new `## Owner Polish 2026-10-31` section.
- One line under `## Questions for Şekip`: Ranks unlocks at L40 but only 30 levels exist, move it to L30?
- TASKS.md only, CRLF kept, no other rows reordered or edited, `git diff --check` clean, commit, no push.

## Summary
Branch `factory/083-owner-polish-queue` commit be5b3f55 changes only `TASKS.md` (+26 lines, 0 removed).

## Acceptance criteria
1. [x] 11 SB-POLISH rows at the top of the queue, in order, with the right statuses: lines 9-19 of TASKS.md, directly after the queue comment; 009 is OWNER and the rest are READY.
2. [x] `## Owner Polish 2026-10-31` section with 11 `- [ ]` items: placed after `## Questions for Şekip`, before `## Project Status`.
3. [x] Ranks L40->L30 question added under `## Questions for Şekip`.
4. [x] CRLF kept: `file TASKS.md` still reports "with CRLF line terminators".
5. [x] No other rows changed: `git diff --stat` shows 26 insertions, 0 deletions.

## Validation
- `git diff --check`: clean (no output).
- `git status --porcelain` after the commit: empty.
- No code changed, so no Godot suites were run (light path).

## Log
### Round 1
Inserted the queue rows, section and question with a CRLF-preserving script. Committed be5b3f55. Not pushed.
