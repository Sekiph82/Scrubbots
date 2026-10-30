# Achievements screen rebuild to master v01 (SB-M43-127-REBUILD)

> Feature: SB-M43-127-REBUILD rebuild the Achievements screen (scripts/ui/profile/profile_screens.gd open_achievements) to match assets/ui/generated/masters/scrubbots_achievements_master_v01.png.

## Context
- `ProfileScreens.open_achievements(stack, app)` in `scripts/ui/profile/profile_screens.gd` (~lines 238-282) builds `BasePopup("achievements")`, `set_frame("large")`, a 900 px `ScrollContainer` `AchievementList` (TouchScroll enabled) of `PanelContainer` cards `Ach_<id>` (meta `done`; children `Title`, `Progress` ProgressBar, `State`), a `Policy` line and a `back` action. Data: `Achievements.evaluate(app)` (`scripts/progression/achievements.gd`) returns `[{id, metric, target, value, done}]`; 8 defs in the achievements JSON (clean_start, tidy_ten, spotless_fifty, first_set, robot_crew, hot_streak, bare_hands, first_try_five).
- Strings in `scripts/ui/ui_text.gd` ~396-405: `ACH_<ID>` = "Name · description" (single string), `ACH_DONE` = "COMPLETED", `ACH_NO_REWARD`.
- Master (view the PNG): title ACHIEVEMENTS + X; cream summary banner (trophy, "4 / 8 completed", green progress bar); 8 cream cards, each with a round blue-ringed badge icon (star, "10" laurel, sparkles, cards, robot head, flame, crossed-out booster, crown), bold name, small description, and on the right either a green COMPLETED pill with check or a progress bar with "n/m" under it; small no-reward note; cream BACK and CLOSE buttons.
- Precedent: factory 076 (`coordination/sessions/FACTORY/076-m43-profile-rebuild/spec.md`, `build.md`) rebuilt Profile in the same file with native Controls in `BasePopup`, `HomeStyle.box/pad`, `UiProgressMeter` (`scripts/ui/components/ui_progress_meter.gd`) and promoted `assets/ui/final/profile/profile_trophy_icon.png` and `profile_no_booster_icon.png` (reuse both: summary trophy, Bare Hands badge). Look at how 076 built its tile/icon helpers in `profile_screens.gd` and reuse them.
- Other badge art: builder greps `assets/ui/final` for a star, cards/collection (`collection/master_collection_emblem.png`), robot portrait (`characters/scrubby/...`), flame (`home`/`daily/daily_streak_flame.png`), crown, sparkles, "10" badge (`home/top_hud/profile_rank_badge.png` may fit). Only for icons with no fit: crop from the master to `assets/ui/generated/`, promote to `assets/ui/final/profile/` with `.import` and an `ASSET_GENERATION_MANIFEST.json` entry (label: approved by Claude under owner-delegated authority 2026-10-31, not owner visual review). A round blue ring may be drawn natively (StyleBox circle) around a plain icon.
- Tests touching this screen: `tests/m43_master_c010_meta.gd` `_m04` (~lines 128-150; uses `Ach_tidy_ten` meta `done`), `tests/m47_touch_r01_mobile_ux.gd` ~454 (`AchievementList` must remain a touch-scrollable ScrollContainer or the test is updated consistently). Capture tool: `tests/tools/meta_snapshot.gd` (5 sizes, needs a rendering driver, not `--headless`). Texture budget: `tests/m22_026_texture_budget.gd` (+ `tests/tools/m22_026_texture_measure.gd`).

## Requirements
1. `open_achievements` is rebuilt as native Controls inside the existing `BasePopup` large frame; no master image used as a runtime texture. Same live data (`Achievements.evaluate`), same definitions, nothing granted, same `back` action behavior, plus a `close` action (CLOSE) next to BACK.
2. Summary banner (`PanelContainer` named `AchSummary`): trophy icon, label "N / 8 completed" (N = count of `done`, 8 = list size, via a new `UiText` key with args), and a progress bar (value N, max total).
3. Cards keep names `Ach_<id>` with meta `done`. Each card: round badge icon, `Title` label (name only), `Desc` label (description only), and right side either a green COMPLETED pill with check (`State` label text `ACH_DONE`) when done, or a `Progress` ProgressBar + `State` label "n/m" (`TASK_PROGRESS`) when not done. Done cards need no ProgressBar.
4. Split `ACH_<ID>` strings into name + description keys (e.g. `ACH_<ID>` = name, `ACH_<ID>_DESC` = description, description text as in the master, sentence case). Remove the " · " form; grep that no code/test still expects it. Update any localization table/test that enumerates `ACH_` keys.
5. Keep the `AchievementList` ScrollContainer (TouchScroll) wrapping the 8 cards so smaller frames scroll instead of clip; sized so at 1080x1920 all 8 cards plus note and buttons are visible without clipping or overlap where the frame allows (shrink spacing rather than overflow).
6. No-reward note (`Policy`, `ACH_NO_REWARD`) below the list; BACK (secondary) and CLOSE (secondary) buttons with `custom_minimum_size.y` or size.y >= 88.
7. Icons: existing final art first; crops/promotions per Context. Update `tests/m22_026_texture_budget.gd` only if the budget check fails because of added textures.
8. Tests: extend `_m04` in `tests/m43_master_c010_meta.gd` (no new suite): `AchSummary` exists and its text/bar match N/total; every card has a `Title` and `Desc` that are non-empty and distinct; a done card has COMPLETED state and no `Progress`, a not-done card has `Progress` value/max equal to `value`/`target` and "n/m" text; BACK and CLOSE >= 88 px; CLOSE pops the screen.
9. Docs: `TASKS.md` mark SB-M43-127-REBUILD DONE with evidence (queue line ~64 and the task's own entry if any; honest labels: CLAUDE self/peer review; visual approval by Claude under delegated authority, not owner review); asset provenance in `ASSET_GENERATION_MANIFEST.json` if any asset added; update `AGENTS.md`/docs only if they describe the old Achievements layout (grep `Achievements` in AGENTS.md and docs/).

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c010_meta.gd` ends with its normal all-pass line, zero FAIL lines, and includes the new `_m04` assertion texts (grep output for them).
2. `"$GODOT" --headless --path <worktree> -s res://tests/m47_touch_r01_mobile_ux.gd` passes (AchievementList still handled).
3. `"$GODOT" --headless --path <worktree> -s res://tests/m22_026_texture_budget.gd` passes.
4. `grep -rn "ACH_" scripts tests | grep -c "·"` is 0 and `grep -n '"ACH_' scripts/ui/ui_text.gd` shows a name key and a `_DESC` key for each of the 8 ids.
5. Rendered captures via `tests/tools/meta_snapshot.gd` (rendering driver) at all 5 sizes are saved in `factory/jobs/077-m43-achievements-rebuild/evidence/`; the 1080x1920 PNG visibly shows summary banner with trophy/"n / 8 completed"/bar, 8 cards with round badges, names, descriptions and COMPLETED pill or bar + n/m, note, BACK and CLOSE; run prints `META_EVIDENCE CLEAN` (no clipping). Report states honestly the comparison with the master was by eye.
6. `git -C <worktree> diff --check` clean; `"$GODOT" --headless --path <worktree> --quit` prints no parse/script errors.
7. Any new asset exists under `assets/ui/final/profile/` with `.import` and a manifest entry (`grep -n profile ASSET_GENERATION_MANIFEST.json`).
8. `grep -n "SB-M43-127-REBUILD" TASKS.md` shows it DONE with evidence.
9. Other suites that reference Profile/Achievements still pass (`grep -rln "Ach_\|AchievementList\|ACH_" tests` each run headless).

## Out of scope
- No new achievements, metrics, rewards, XP, economy or save-format changes; no change to `Achievements` logic or its JSON.
- No changes to Profile, Notifications, Events or Ranks screens, or `BasePopup` (beyond nothing; prefer none).
- No new test suite, no regenerating/overwriting owner-approved art, no master PNG as a runtime texture.
- No new capture tooling beyond `meta_snapshot.gd`.

## Assumptions
- Description text follows the master (sentence case: "Clear your first level"), derived from the existing strings; the final cap/wording of each is the builder's reading of the master.
- Header X in the master is the existing BasePopup close affordance; the explicit CLOSE button is added per the task.
- The viewport matrix is the SIZES list in `tests/tools/meta_snapshot.gd`.
- Visual approval is Claude's under owner-delegated authority 2026-10-31, labelled as such.
