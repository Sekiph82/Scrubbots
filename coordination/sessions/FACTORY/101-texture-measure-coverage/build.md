STATUS: READY

# Build: SB-M22-029 measure the remaining screens and states, safe caps, tests

## Summary
The real texture-measure tool now covers 28 scenarios at 1080x2400, 1170x2532 and 1536x2048 (84 runs,
173 final/ textures measured). Every final/ PNG is classified as measured or not observed, with a
reason. The rule is size_limit >= 2x the largest drawn size. Under that rule the branch adds 5 caps,
corrects 3 existing limits that were under 2x at 1170x2532 (2 raised, 1 removed), and adds a
cold/warm loaded-texture test. No PNG changed, nothing deleted, no atlas.

Commits on factory/101-texture-measure-coverage:
- d5e80505 tools/tests: measure tool scenarios + apply_caps --coverage / under-2x flag
- 071b4f60 assets: size_limit changes (8 .import files, 5 newly tracked)
- bb66d807 tests: budget test update + new m22_029_texture_cold_warm
- 53b95386 docs/tasks: TASKS.md (queue row DONE, checklist [x]), docs/M22_029_TEXTURE_COVERAGE.md, UI-ADR-008 step 5

Files: tests/tools/m22_026_texture_measure.gd, tools/m22_026_apply_caps.py, tests/m22_026_texture_budget.gd,
tests/m22_029_texture_cold_warm.gd (new), assets/ui/final/{common/icons/icon_lock, home/shortcuts/icon_shortcut_gift_bar,
icon_shortcut_win_streak, icon_shortcut_collection, daily/daily_day_reward_frame, daily_day5_reward_frame,
daily_login_calendar, collection/collection_complete_emblem}.png.import, docs/M22_029_TEXTURE_COVERAGE.md (new),
docs/07_UI_ASSET_PIPELINE_DECISIONS.md, TASKS.md.

## Acceptance criteria
1. [x] Measure the listed screens and states at 1080x2400, 1170x2532 and 1536x2048 with throw-away saves: `godot --headless -s res://tests/tools/m22_026_texture_measure.gd` gave "M22-026 MEASURE: DONE (84 scenarios, 173 textures)", with no SCRIPT ERROR or Failed loading. Scenarios cover Daily/tasks/calendar, Events, Achievements, Settings, profile and ranks (RANKS is served now), locked boosters (fresh save) and unlocked boosters (L30 profile walked with record_win), collection album/sets/cards/exchange and the pack reveal, the set/master/gift/robot/feature/world ceremonies, win/lose Results and variants, Need a Hand, FTUE coachmarks, the shop and its confirm, the Scrub Bucks popup (the billing surface), 5/6 slots and the Level Intro. The walker now also sizes Button icons, StyleBoxTexture panels and theme icons. Saves are user:// temp files that get deleted. main.tscn always boots with boot_save_path_override.
2. [x] Classify observed vs not observed: `apply_caps.py --coverage` gives 173 measured (144 ACTIVE_RUNTIME, 28 DYNAMIC_REF, 1 not in inventory) and 397 not observed (239 ACTIVE_RUNTIME, 16 DYNAMIC_REF, 141 FUTURE_NEEDED, 1). docs/M22_029_TEXTURE_COVERAGE.md gives the reasons. Nothing deleted.
3. [x] Not-measured states with reasons: the opening video; the Home frame gestures (Home plays Flow video now, and the tool logs "gesture full_turn did not start"); FX drawn by _draw/particles (fx_clean_sparkle/puff, rails, BoosterVfx); marketing art and app icons; RANKS on Home (unlocks at L40, but the catalog ends at L30).
4. [x] Safe caps (>= 2x drawn px, source unchanged, alpha kept, lossless): icon_lock, gift_bar, win_streak 512; the two day-card frames 1024 (-21.33 MiB). Corrected limits that were under 2x at 1170x2532: collection_complete_emblem and icon_shortcut_collection 512 -> 1024, daily_login_calendar 1024 -> none (+7.21 MiB). Net -14.12 MiB. I did not cap fx_clean_sparkle, because its gameplay and particle uses can't be measured. Card art stays at 1080, which is 1.85x at 1170x2532 and still above the drawn size; SB-M22-028 owns card memory.
5. [x] A budget test fails when a cap is reverted: m22_026_texture_budget PASS. With icon_lock set back to 0 and the project re-imported, it printed "FAIL: common/icons/icon_lock.png 1254x1254 <= 512" and exited 1. I then restored the cap.
6. [x] Cold/warm loaded-texture count: new m22_029_texture_cold_warm PASS. Cold Home has 93 textures / 133.50 MiB, the peak is 145.91 MiB, and warm Home after each of two visits is 93 / 133.50 MiB. Card art is resident while open (1) and gone after close (0). All 570 final imports are lossless with no mipmaps.
7. [x] TASKS.md: the SB-M22-029 queue row is DONE and the checklist row is [x], with evidence.

## Validation (LOCAL_PASS, Godot 4.7.2 headless; every run exit 0, 0 SCRIPT ERROR / Parse Error, last line PASS)
- m22_026_texture_budget PASS; m22_029_texture_cold_warm PASS; m22_025_booster_texture_budget PASS
- m21_real_art_smoke PASS; m42_home PASS; m28_c002_c001_gameplay_v02 14/14; m39d_daily_collection PASS
- m43_master_c007_collection 19/19; m43_master_c009_daily 12/12; m43_master_c010_meta 12/12; m44_unlock_gate 6/6
- `git diff --check` clean on the changed files. No CI run, no phone build, nothing pushed.

Working tree: the untracked Godot import artefacts (.import/.uid/.translation) are removed and project.godot is restored. `git status` still lists 252 tracked .import files as M, but `git diff` and `git diff --ignore-cr-at-eol` are both empty for them. This comes from autocrlf=true with LF working files written by `--import`; the owner checkout shows the same set. No content change.

## Log
### Round 1
Extended the measure tool: third size 1170x2532, Level Intro, RANKS, the SB popup, the L30 profile, and Button icon / StyleBoxTexture / theme-icon sizing, plus a --only filter. apply_caps.py gained --coverage and an under-2x flag for existing limits. The flag found that 1080-tuned limits fall under 2x on the 1170 phone. I fixed three of them and left card art for SB-M22-028 (documented). Applied 5 new caps, re-imported and re-measured (dry run after: only fx_clean_sparkle is proposed, excluded on purpose). Raised three per-screen budgets: Shop/Collection 47, Daily/Tasks 40 (day frames now listed), Profile 35. Added the cold/warm test.
