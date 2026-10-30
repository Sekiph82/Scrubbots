STATUS: READY

# Build: Achievements screen rebuild to master v01 (SB-M43-127-REBUILD)

## Summary
`ProfileScreens.open_achievements` is now built from native Controls inside the same `BasePopup` large frame, laid out like `scrubbots_achievements_master_v01.png`:
- `AchSummary`: a cream banner with the trophy icon, `Text` "N / 8 completed" (new `ACH_SUMMARY` key with args) and a green `Bar` (value N, max = list size).
- `AchievementList`: the same touch-scrollable `ScrollContainer` (900 px min height, `TouchScroll.enable`) holding 8 `Ach_<id>` cards (meta `done` kept). Each card has a round blue-ringed `Badge` (a native StyleBoxFlat circle) around the icon, `Title` (name), `Desc` (description), and on the right either a green pill with a check and `State` = COMPLETED (done; no ProgressBar), or a green `Progress` bar with `State` "n / m" (`TASK_PROGRESS`).
- `Policy` (no-reward note), then BACK (secondary, closes) and a new CLOSE (secondary, closes).

The data source is still `Achievements.evaluate(app)`. Nothing is granted, and Achievements logic and JSON are unchanged.

Badge icons reuse existing final art:
- victory_emblem (star)
- profile_rank_badge with the target "10" drawn on it via the existing `_badge` helper (Tidy Ten)
- fx_clean_sparkle
- icon_shortcut_collection (cards)
- scrubby_portrait
- daily_streak_flame
- profile_no_booster_icon
- profile_trophy_icon (summary)

The only crop is the crown, because no final crown art exists. It is a 128x128 circular-masked crop of the master, saved at `assets/ui/generated/profile/achievement_crown_icon_crop_v01.png` and promoted to `assets/ui/final/profile/achievement_crown_icon.png`, with `.import` files and an `ASSET_GENERATION_MANIFEST.json` entry labelled "approved by Claude under owner-delegated authority 2026-10-31, not owner visual review".

UiText: each `ACH_<ID>` is now the name only, and a new `ACH_<ID>_DESC` holds the sentence-case description. The " · " form is gone. `ACH_SUMMARY` was added.

`tests/tools/meta_snapshot.gd` now captures `2_achievements` at all 5 sizes, not only 1080x2160, as AC5 requires. This changes the existing tool; no new tool was added.

Files changed:
- scripts/ui/profile/profile_screens.gd
- scripts/ui/ui_text.gd
- tests/m43_master_c010_meta.gd
- tests/tools/meta_snapshot.gd
- ASSET_GENERATION_MANIFEST.json
- assets/ui/final/profile/achievement_crown_icon.png(+.import)
- assets/ui/generated/profile/achievement_crown_icon_crop_v01.png(+.import)
- TASKS.md

Commits: c3af8b23 (code/assets/tests), e972a55b (TASKS.md).

## Acceptance criteria
1. [x] `m43_master_c010_meta`: exit 0, 0 SCRIPT ERROR/Parse Error, 0 FAIL lines. Last line: `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`. The new _m04 lines are present:
   - `ok: summary banner: 2 / 8 completed text + bar`
   - `ok: every card: round badge + distinct non-empty Title and Desc`
   - `ok: done card: COMPLETED pill, no Progress bar`
   - `ok: not-done card: Progress 10/50 + n/m text`
   - `ok: achievements BACK and CLOSE >= 88 px tall`
   - `ok: CLOSE pops Achievements`
2. [x] `m47_touch_r01_mobile_ux`: `PASS (14/14 cases, 0 fail)`, exit 0. `AchievementList` is still listed and touch-scrollable, with no STOP control.
3. [x] `m22_026_texture_budget`: `M22-026 TEXTURE BUDGET: PASS`, exit 0. The budget was not changed.
4. [x] `grep -rn "ACH_" scripts tests | grep -c "·"` returns 0. `grep -n '"ACH_' scripts/ui/ui_text.gd` shows a name key and a `_DESC` key for all 8 ids (lines 396-411), plus ACH_DONE, ACH_SUMMARY and ACH_NO_REWARD. No other file references the ACH_ keys (grep across the repo, excluding coordination/factory).
5. [x] `meta_snapshot.gd` was run with the rendering driver (no `--headless`). It printed `META_EVIDENCE CLEAN (0 rejected)`.
   - The captures are in `factory/jobs/077-m43-achievements-rebuild/evidence/2_achievements_{1080x1920,1080x2160,1170x2532,1290x2796,1536x2048}.png`; the Profile/Events/etc. captures from the same run are also there.
   - The 1080x1920 capture shows: title + X, the banner with trophy, "1 / 8 completed" and a green bar, 8 cream cards with round blue-ringed badges, names and descriptions, a COMPLETED pill on Clean Start and a bar + n / m on the others, the note, and BACK and CLOSE. Nothing is clipped, and all 8 cards fit without scrolling.
   - I compared it with the master by eye. Differences:
     - The pill's check is the existing blue `icon_check` badge, not the master's white tick.
     - The Tidy Ten badge is the winged rank badge with "10", not the laurel.
     - Spotless Fifty uses the single cyan sparkle, not two gold stars.
     - The Robot Crew icon is the full Scrubby portrait, so it looks smaller than the master's head.
     - Hot Streak uses the wide flame art.
     - "n / m" has spaces (the existing `TASK_PROGRESS` format).
     - Bare Hands and First-Try Five descriptions wrap to 2 lines, where the master fits Bare Hands on one.
     - The fonts are the project's emboldened default.
     - The capture fixture has 3 wins, so it shows 1/8, not the master's 4/8.

     Structure, order and palette match.
6. [x] `git diff --check` was clean on the changed files, and `git diff --cached --check` was clean before each commit. `"$GODOT" --headless --path <worktree> --quit` printed no parse/script errors; the only output is the usual `30 resources still in use at exit` notice.
7. [x] `assets/ui/final/profile/achievement_crown_icon.png` and its `.import` exist. The manifest entry is `achievement_crown_icon`, with the master source, the raw crop path, the target path and the delegated-approval label.
8. [x] `grep -n "SB-M43-127-REBUILD" TASKS.md`: line 64 now reads `- DONE SB-M43-127-REBUILD — ... (factory 077, c3af8b23) ... LOCAL_PASS ...`, and the SB-M43-127 entry (line 1215) gained a DONE note. Peer review is labelled pending; the visual match is "by Claude under owner-delegated authority, not owner visual review".
9. [x] `grep -rln "Ach_\|AchievementList\|ACH_" tests` returns `m43_master_c010_meta.gd`, `m47_touch_r01_mobile_ux.gd` and `m46_rm003_ftue_coach_performance.gd`. The last one matches only on "COACH_" in a filename comment; it was run anyway and printed `M46 RM003 FTUE COACH: PASS (4 case groups)`, exit 0.

## Validation
All runs used Godot 4.7.2 (`$GODOT` from the prompt) in the worktree:
- `--headless -s res://tests/m43_master_c010_meta.gd`: LOCAL_PASS (12/12, 0 fail)
- `--headless -s res://tests/m47_touch_r01_mobile_ux.gd`: LOCAL_PASS (14/14)
- `--headless -s res://tests/m22_026_texture_budget.gd`: LOCAL_PASS
- `--headless -s res://tests/m46_rm003_ftue_coach_performance.gd`: LOCAL_PASS
- `-s res://tests/tools/meta_snapshot.gd -- <job>/evidence` (rendering): META_EVIDENCE CLEAN (0 rejected)
- `--headless --quit`: no parse/script errors
- `git diff --check`: clean

The pre-existing `.import`/project churn in the worktree was left uncommitted, as instructed. AGENTS.md and docs/ do not describe the old Achievements layout (docs/16 mentions only the unlock level), so neither was changed.

## Log
### Round 1
- Rebuilt `open_achievements` (summary banner, `_ach_card`, `_bar` helpers) to match the master, reusing the Profile helpers `_text` and `_badge`.
- Split the ACH strings into name and `_DESC` keys.
- Cropped and promoted the crown icon with manifest provenance.
- Extended `_m04`.
- Made `meta_snapshot.gd` capture Achievements at all 5 sizes.
- Tuned the badge size, description font and list spacing over two capture passes so that all 8 cards fit at 1080x1920.
- Ran the named suites and updated TASKS.md.
