STATUS: READY

# Build: Profile screen rebuild to master v01 (SB-M43-125-REBUILD)

## Summary
`ProfileScreens.open_profile` is now built from native Controls inside the same `BasePopup` large frame, laid out like `scrubbots_profile_master_v01.png`:
- `ProfileHero`: the active robot portrait inside the round HUD frame, the robot name (`ActiveRobot`, now just the name, e.g. "Scrubby"), the rank badge showing the campaign level (`HeroLevel`), and the `ProfileBotParts` bar.
- `ProfileStats`: a 2-column grid with 6 tiles (`Level`, `Cleared`, `Collection`, `Robots`, `AchievementSummary`, `LoginDays`). Each tile has an `Icon`, a `Caption` and a `Value`.
- `ProfileBests`: a blue `BestsTitle` header, Current / Best column headers, and 3 rows (`BestStreak`, `BestFirstTry`, `BestBoosterless`). Each row has an icon, a label, `Current` and `Best`.
- Below that: the `BoosterlessTotal` line (kept, because it fits without scrolling), the `SelfOnly` note, and the ACHIEVEMENTS (primary), NOTIFICATIONS and CLOSE actions. Their re-arm wiring is unchanged.

The bar shows exactly what the Home top HUD shows: `e.robots.next_robot_progress()` parts/cost (Bot Parts toward the next 250-part robot), gold when a robot can be unlocked. It is not an XP system. The badge shows `app.progression.current_level()`, the same source as Home `ProfileLevel`.

The self-ghost ProgressBar is removed because the master has none. Current/Best now carry that comparison. The sets count is dropped from the Collection value, which is now `n/135` as in the master. The floating `set_hero` portrait above the frame is no longer used; the portrait sits inside the hero card.

Icons reused from `assets/ui/final`:
- profile_rank_badge, profile_avatar_frame
- daily_task_check (Levels Cleared; no flag art exists)
- icon_shortcut_collection
- icon_nav_robots
- daily_login_calendar
- daily_streak_flame
- victory_emblem (star)

Two icons were cropped from the master: a no-booster sign and a gold trophy. They are saved under `assets/ui/generated/profile/*_crop_v01.png`, promoted to `assets/ui/final/profile/` (128x128, transparent) with `.import` files, and have provenance entries in `ASSET_GENERATION_MANIFEST.json` labelled "approved by Claude under owner-delegated authority 2026-10-31, not owner visual review". The trophy is a crop because the only trophy in final art is `icon_nav_leaderboard.png`. That icon belongs to the Ranks screen, and its path trips the m09 "no social / remote comparison" source guard.

UiText changes:
- PROFILE_LEVEL, PROFILE_COLLECTION, PROFILE_ROBOTS, PROFILE_ACHIEVEMENTS, PROFILE_BESTS, PROFILE_SELF_ONLY and BEST_* now hold the master's captions.
- Added PROFILE_LEVELS_CLEARED, PROFILE_LOGIN_DAYS, BEST_CURRENT, BEST_BEST.
- Removed PROFILE_ROBOT and BEST_ROW, which nothing uses any more.
- PROFILE_CLEARED is unchanged because the Ranks screen still uses it.

Files changed:
- scripts/ui/profile/profile_screens.gd
- scripts/ui/ui_text.gd
- tests/m43_master_c010_meta.gd
- tests/m22_026_texture_budget.gd
- ASSET_GENERATION_MANIFEST.json
- assets/ui/final/profile/{profile_no_booster_icon,profile_trophy_icon}.png(+.import)
- assets/ui/generated/profile/{profile_no_booster_icon_crop_v01,profile_trophy_icon_crop_v01}.png(+.import)
- TASKS.md

Commits: 8d8e73bb (code/assets/tests), 0db21be1 (TASKS.md).

## Acceptance criteria
1. [x] `m43_master_c010_meta` passes with the new assertions: exit 0, 0 SCRIPT ERROR/Parse Error, 0 FAIL. Last line: `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`. New lines:
   - `ok: profile hero: portrait, robot name, level badge 4, Bot Parts bar 0/250`
   - `ok: profile stats: 2 columns, exactly 6 tiles with icon + caption + live value { "Level": "4", "Cleared": "0", "Collection": "0/135", "Robots": "1/10", "AchievementSummary": "0/8", "LoginDays": "0" }`
   - `ok: profile bests: 3 rows with Current / Best from streak + records`
   - `ok: profile action buttons >= 88 px tall`
   - m09: `ok: self-comparison: current 0 against own best 2`. This replaces the Ghost-bar check.
2. [x] `m43_personal_ranks`: `M43 personal ranks evidence: PASS (8/8 cases, 0 fail)`, exit 0. The Ranks `Cleared` line is untouched.
3. [x] Of the files the grep returns, only `tests/m43_master_c010_meta.gd` references these node names, and it passes (AC1). `m22_026_texture_budget`: `M22-026 TEXTURE BUDGET: PASS`, exit 0. The 10 Profile textures were added to `PROFILE_EVENTS` honestly, re-measured at 28.78 MiB, and the budget was set to 32 MiB (measured + ~10%, the file's own rule; it was 21 MiB). Extra check: `m49_responsive_matrix` (opens Profile across viewports) passes 8/8.
4. [x] Captures from `tests/tools/meta_snapshot.gd`, run with the rendering driver (no `--headless`), are in `factory/jobs/076-m43-profile-rebuild/evidence/1_profile_{1080x1920,1080x2160,1170x2532,1290x2796,1536x2048}.png`. The run printed `META_EVIDENCE CLEAN (0 rejected)`, so all 5 sizes, including 1080x2160 and 1536x2048, have the frame inside the viewport and pass `text_fits()`. Everything fits at 1080x1920 without TouchScroll.

   I compared the 1080x1920 capture and the master side by side, by eye. Same structure and order:
   - title pill + X
   - blue hero with the robot in the round ring, name, winged level badge overlapping a dark bar with a centred N/250
   - 2x3 cream tiles, each icon + caption + big value
   - "Personal Bests" blue header with Current/Best columns and 3 icon rows
   - "Only you can see this"
   - green ACHIEVEMENTS, cream NOTIFICATIONS, cream CLOSE

   Differences:
   - Levels Cleared uses a blue check, not the master's flag.
   - The Robots and Login Days icons are the existing nav-robot and calendar art.
   - Current/Best appear as a single header row, not repeated in each row.
   - The extra small "Levels cleared without boosters" line remains.
   - Fonts are the project's emboldened default.
   - The hero portrait is a bit smaller than in the master.

   Overall it is close in structure and palette, though not pixel-identical.
5. [x] The m03 assertion `profile action buttons >= 88 px tall` covers achievements/notifications/close using `max(custom_minimum_size.y, size.y) >= 88`. Primary is 112 and secondary is TOUCH_MIN 88.
6. [x] `git diff --check` was clean on the changed files, and `git diff --cached --check` was clean before the commit. `"$GODOT" --headless --path <worktree> --quit` exits 0 with no parse/script errors. The only output is the usual `resources still in use at exit` notice.
7. [x] `assets/ui/final/profile/profile_no_booster_icon.png(.import)` and `profile_trophy_icon.png(.import)` exist. `grep profile ASSET_GENERATION_MANIFEST.json` shows the `profile_no_booster_icon` and `profile_trophy_icon` entries: source master, raw crop path, target path, delegated-approval label.
8. [x] `grep -n "SB-M43-125-REBUILD" TASKS.md`: the queue row now reads `- DONE SB-M43-125-REBUILD — ... (factory 076, 8d8e73bb) ... LOCAL_PASS ...`, and the SB-M43-125 entry gained a DONE note. Peer review is labelled pending, and visual approval is "by Claude under owner-delegated authority".

## Validation
All runs used Godot 4.7.2 (`$GODOT` from the prompt) in the worktree:
- `--headless -s res://tests/m43_master_c010_meta.gd`: LOCAL_PASS (12/12, 0 fail)
- `--headless -s res://tests/m43_personal_ranks.gd`: LOCAL_PASS (8/8)
- `--headless -s res://tests/m22_026_texture_budget.gd`: LOCAL_PASS
- `--headless -s res://tests/m49_responsive_matrix.gd`: LOCAL_PASS (8/8). This one is outside the spec's list; I ran it as a regression check because it opens Profile.
- `--path . -s res://tests/tools/meta_snapshot.gd -- <dir>` with a rendering driver: META_EVIDENCE CLEAN
- `--headless --quit`: no parse errors
- `git diff --check`: clean

## Notes
- **Worktree not clean:** `git status --porcelain` is not empty. Godot import/run churn is still there: `project.godot`, LF/CRLF-only `.import` changes under `assets/ui/final` (these were present before this build), and untracked addon `.uid`/`.import` files. None of it is committed. My restore/clean command was denied by the permission system, so it was left in place. It goes away when the worktree is deleted after merge.
- The first two meta_snapshot runs in `C:/Users/sekip/AppData/Local/ScrubBotsFactoryWT/snap076/` sit outside the repo (scratch output).

## Log
### Round 1
- Rebuilt `open_profile` to master v01, following the orchestrator's answers:
  - The bar uses the Home HUD Bot Parts source.
  - BoosterlessTotal is kept because it fits.
  - No TouchScroll is needed.
- Cropped 2 missing icons from the master, with provenance.
- Updated the m03/m09 assertions, the texture budget list and the TASKS.md rows.
- Problem found and fixed: using `icon_nav_leaderboard.png` failed the m09 no-social guard (its source text contains "leaderboard"). I replaced it with a cropped trophy.
