STATUS: READY

# Build: SB-M36-010 recovery/sequencing proposal + SB-M36-013 decision record (light path)

## Spec (light path)
1. Write docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md on v2 data. It must cover which recovery guards (3->4, 5->6, 8->9) fail and why, and three options: (A) a scripted reorder within the exact cadence, (B) Level Factory recovery constraints, (C) treating it as a model limitation until SB-M36-013. It recommends one. Tick SB-M36-010 and mark its queue row DONE.
2. Original plan for SB-M36-013: make it OWNER and add a Questions line. This was superseded by an owner instruction relayed by the coordinator on 2026-10-26: "eğer benim verdiğim puanları kural olarak alıyorsa almasın. kendi bulduklarını ben okeyliyorum şimdiden." Under that instruction the owner ratings are not used as a criterion, the owner pre-approves the factory's recommendations, SB-M36-013 stays READY with the quote and the recommended option recorded, and no Questions line is added. Any required work is filed as READY.
3. No data/config changes. The only files changed are the new doc and TASKS.md. `git diff --check` must be clean.

## Summary
Branch commits:
- 8b237736 adds docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md.
- 37870155 updates TASKS.md.

Findings from the doc:
- Under v2 all three guards fail. The drops are 13.98 (minimum 15), 5.80 (minimum 20) and -8.45 (minimum 15). The doc breaks each drop down by component.
- 5->6 and most of 3->4 fail on scale: the guard minimums are in lane points, and the whole v2 pack spans only 24.6 D.
- 8->9 is a content inversion: L9 measures harder than L8 on A, B, U, R and S.
- An exhaustive reorder search within the exact cadence (1440 orders) passes at most 1 of 3 guards, and the doc includes an analytic proof of that cap. Diagnostic searches that break the cadence are reported too: 3.6M orders reach 3/3 only by putting the boss in the HARD slot, and with L1 and L10 pinned the best is 2/3.
- Recommendation, approved by the owner's pre-approval: C+B. Keep the shipped order. Rescale `recoveryGuards` together with the lanes in a versioned level_progression_v2.json (SB-M36-013). Add component recovery checks (new SB-M36-014).

For SB-M36-013, the factory recommends the versioned rescale over keeping 20/40/58/76, because no v2 level or corpus fixture reaches 58 or 76 (maximums 46.7 and 36.5).

## Acceptance criteria
1. [x] Proposal doc covers which guards fail and why, plus options A/B/C with a recommendation. Evidence: the doc's sections 1-6. The values match playtest_v2.json `recovery`: drops 13.98, 5.80, -8.45.
2. [x] Option A is scripted and the best order reported. Evidence: a Python exhaustive search over the playtest_v2.json D values (script inlined in the doc appendix) ran in about 5 s. A1 searched 1440 orders: histogram {0: 960, 1: 480}, best order 1,7,8,2,5,4,9,3,6,10, 1/3 guards. A2 (L1 pinned) also capped at 1/3. A3 searched 3,628,800 orders: 480 pass 3/3, all of them breaking the cadence. A4 (L1 and L10 pinned): best 2/3.
3. [x] Owner ratings are not used as a criterion (owner instruction 2026-10-26). They appear only in the quoted instruction.
4. [x] SB-M36-010 is ticked and its queue row is DONE, with SHA 8b237736.
5. [x] SB-M36-013 stays READY, with the owner quote and the recommended option (versioned rescale plus guard rescale) in both the queue row and the item. No Questions line was added.
6. [x] The implementation work is filed as READY SB-M36-014, in both the queue row and the item.
7. [x] No data/config change, and `git diff --check main..HEAD` is clean. Changed files: TASKS.md and the new doc. TASKS.md keeps CRLF on all 1984 lines.

## Validation
- `python recovery_perms.py .../playtest_v2.json` (scratchpad copy of the appendix script): ran, output as above.
- `git diff --check main..HEAD`: clean.
- `git status --porcelain`: empty.
- No Godot suites were run. No code changed (docs and tracker only).

## Log
### Round 1
- Wrote the proposal from the v2 and v1 playtest JSON files, the calibration docs and progression_v1 `recoveryGuards`.
- Partway through, the coordinator relayed the owner instruction above. I removed the perception-based section and arguments and rebased the analysis on measured data only. SB-M36-013 became a pre-approved READY item instead of OWNER + Question, and SB-M36-014 was filed.
- The quote is recorded in the doc status line, in SB-M36-010, and in SB-M36-013 (queue row and item).
