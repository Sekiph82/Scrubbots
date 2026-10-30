STATUS: READY

# Build: Profile, Achievements, Events visual masters + SB-M34-006 owner answer

## Summary
The branch commits the three ChatGPT-generated masters under `assets/ui/generated/masters/`. These ship nowhere: the export preset already excludes `assets/ui/generated/*`. Both manifests now register the masters, with honest wording that Claude approved them under authority the owner delegated, not owner visual review. TASKS.md closes SB-M43-125/127/130, adds three READY REBUILD rows, and closes SB-M34-006 as OWNER_ACCEPTED, stating plainly that no device capture was made.

Commits: `bcefca76` (PNGs + manifests), `1870aca9` (TASKS.md), `9826afd4` (TASKS.md: follow-up row SB-CAMPAIGN-L11-L30-FIX). Base `366e785d` (= main).

Files changed:
- `assets/ui/generated/masters/scrubbots_profile_master_v01.png` (added, unchanged bytes, 1917876 B)
- `assets/ui/generated/masters/scrubbots_achievements_master_v01.png` (added, 1895432 B)
- `assets/ui/generated/masters/scrubbots_events_master_v01.png` (added, 2252462 B)
- `ASSET_GENERATION_MANIFEST.json`: canonical_references `profile_master_v01`, `achievements_master_v01`, `events_master_v01`. Each has status `MASTER_APPROVED_BY_CLAUDE_DELEGATED`, provider `chatgpt_image_generation`, date `2026-10-31`, the owner_decision text from the spec, an `approval_label` saying "approved by Claude under owner-delegated authority", and `ships: false` with a note on the export exclusion. The events entry also has a `notes` field describing the event card family.
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`: adds `profile_master`, `achievements_master`, `events_master` to canonical_references. `profile`, `achievements`, `events_main` and `event_detail` are now `MASTER_OWNER_APPROVED`, each with a new `master` path. Their `gap` now reads "master exists (path, approved by Claude under owner-delegated authority 2026-10-31, not owner visual review); remaining: rebuild the screen to match it (SB-M43-1xx-REBUILD)". `recorded_by` repeats the delegated label.
- `TASKS.md`: only the lines for this task (CRLF preserved).

## Acceptance criteria
1. [x] Three PNGs tracked, none under final/: `git ls-files assets/ui/generated/masters` lists `scrubbots_{achievements,events,profile}_master_v01.png`. Nothing was added under `assets/ui/final/`; the diff stat 366e785d..HEAD shows only the 6 files.
2. [x] Both manifests parse: `json.load` on both files printed `ok`, exit 0.
3. [x] Statuses: a Python check printed `profile/achievements/events_main/event_detail MASTER_OWNER_APPROVED True` (True means the master path exists). `grep -c MASTER_REQUIRED` gives 35 on main and 31 on the branch (down exactly 4). All three new `repository_path` values are the same committed PNGs.
4. [x] Honest label: "owner-delegated" appears in both manifests (approval_label, gap, recorded_by). Every "owner visual review" occurrence reads "not owner visual review". The only `OWNER_ACCEPTED` in the manifests is the existing lifecycle enum entry (line 24). No entry claims owner review or acceptance.
5. [x] TASKS.md queue lines 60-62 are `DONE SB-M43-125/127/130` with the delegated-authority note, path, and "factory 075 (bcefca76)". Lines 63-65 are `READY SB-M43-125-REBUILD / -127-REBUILD / -130-REBUILD`. No REBUILD or other rebuild id existed before (grep). Long-form lines 1212/1214/1217 are `[x]` with the same note.
6. [x] Queue line 45 is `DONE SB-M34-006 — ... OWNER_ACCEPTED 2026-10-31T00:44 ("all is ok"); no device capture was made, the A10 was not reachable by adb afterwards, and the A10 still runs the pre-VIBRATE build until the next save-preserving reinstall`, with the earlier history kept. Long-form line 961 is `[x]` with the same note. `## Questions for Şekip` now holds only the comment line. `grep -n "Questions SB-M34-006" TASKS.md` returns nothing. Rows 46-48 stay OWNER and now read "(waits for the Galaxy A10 to be plugged in)".
7. [x] Result unchanged vs main, but that result is FAIL (2 failures that were already there). `$GODOT --headless --path <wt> -s res://tests/m43_c001b_won_results_visual.gd` exits 1 with `M43-C001B WON results visual evidence: FAIL (11/11 cases, 2 fail)`. The failing checks are "Level 10: Victory layout, Continue disabled, readable coming-soon card" and "disabled Continue: no mutation, no transition". I detached the worktree at base 366e785d (= main) and re-ran: same exit 1, and the PASS/FAIL lines are identical (`diff` empty). No SCRIPT ERROR or Parse Error. All 4 `[art / manifest governance]` checks pass on the branch, including "victory_results status MASTER_OWNER_APPROVED is backed by owner authority". So the manifest edits cause no regression. The failure is in the Level 10 Continue-disabled path and is out of scope (no code changes allowed). Flagged for a follow-up.
8. [x] `git diff --check` is clean, both staged and on TASKS.md. Branch diff vs main has only the 2 manifests, TASKS.md and the 3 PNGs. The existing `.import`/`.uid`/`project.godot` noise was not staged.

## Validation
- `python -c "import json;..."` on both manifests: PASS.
- `git diff --check` / `git diff --cached --check`: PASS.
- `m43_c001b_won_results_visual.gd`: FAIL 2 of its checks, the same on the branch and on main 366e785d. This was already failing; the governance checks this change could affect pass.
- No code, scene or test changes (spec requirement 5), so no new tests.

## Log
### Round 1
- Committed the three masters and the manifest edits (bcefca76) and the TASKS.md updates (1870aca9). On the first try a slice left a stray `,` on its own line in both JSON files. I fixed it before committing; the files parse and the diff is tidy.
- Grepped for an existing rebuild id first. None existed, so I added the three REBUILD rows.
- Left the historical line 957 ("SB-M34-006 remains DEVICE/OWNER_REQUIRED", V02 audit note) as it is, since it is history.
- Did not edit factory/answers.md, the export presets or CI. Did not push.
- The regression suite was already failing on main (Level 10 Continue-disabled, 2 checks). Recorded honestly above, not fixed (out of scope).
- Coordinator accepted that the failure is older than this job: it dates from factory 071, after which L10 is no longer the last builtin level (there are now 30). As instructed, I added one READY queue row, `SB-CAMPAIGN-L11-L30-FIX`, directly after the three REBUILD rows (TASKS.md line 66, commit `9826afd4`). It says to move the end-of-content case to Level 30. The test itself is not changed here.
