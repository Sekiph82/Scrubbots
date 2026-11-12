STATUS: READY

# Build: SB-PHONE-2026-11-12-C owner phone test copy/state (hearts full, collection TR, Scrubby copy, one login streak)

## Summary
Branch `factory/150-phone-copy-state`, commits 4e49bcd3, a97a2e8e, 597498cb, e0d69271 (no spec.md in the job folder; the coordinator prompt is the spec).

1. Hearts full: the Home HUD pill reads `LIFE_REFILL_FULL` (EN "FULL" / TR "DOLU", existing keys) at max and the regen countdown only below max. The Life popup hides `TimerPill` at max ("Canlar dolu!" title stays). Files: `scripts/ui/home/home_screen.gd`, `scripts/ui/popup/acquisition_flow.gd`.
2. Collection: album set row titles now use `UiText.data("SET_NAME_n")`; all 15 TR names already existed and the set detail and set-complete ceremony already used them. The rarity burden uses the new `RARITY_SHORT_*` keys (EN C/R/E/L, TR S/N/E/EF, matching the existing TR full words SIRADAN/NADİR/EPİK/EFSANEVİ). The card exchange already printed the localized `RARITY_*` words. Card names are unchanged. Files: `scripts/ui/collection/collection_screen.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`.
3. Robots: Scrubby's perk is now "Team Leader: Scrubby gives no bonus; he leads the whole team." / "Takım Lideri: Scrubby bonus vermez; tüm takımı yönetir." `perk_modifiers` is still empty. Developer wording was also removed from Scrubby's role ("face of the franchise") and Atlas's role ("endgame", "endüstriyel"). The other perks were already player-facing. Files: `data/config/robot_roster_v1.json`, `scripts/ui/ui_text_tr.gd`, and `coordination/OWNER_ROBOT_ROSTER_V01.md`. The perk name in that owner table had to change because `m43_master_c005_meta_ceremonies` e15 requires the roster perk names to match it.
4. Login streak: the new `DailyService.display_streak()` is the single player-facing value. It returns the committed streak once today is claimed. Otherwise it returns the streak that today's claim will make: +1 if the last claim was yesterday, else 1. A missed day therefore reads 1 before the claim. `next_claim_cycle_day()` now derives from it. Daily header, claim popup, Profile "Login Days" tile, Home daily popup/view model all read it. Stored `_streak` / `claim_login()` / save shape unchanged. Welcome Back shows no streak number (only "daily ready"), so it needed nothing. Files: `scripts/economy/daily_service.gd`, `scripts/ui/daily/daily_screens.gd`, `scripts/ui/profile/profile_screens.gd`, `scripts/ui/home/home_view_model.gd`, `scripts/ui/home/home_screen.gd`.
- Tests: new `tests/sb_phone_2026_11_12_c_copy_state.gd` (8 cases) has been added to the CI loop with an exact 8/8 guard. Updated assertions in `m42_home_v06`, `m43_c003_c001_acquisition`, `m55_heart_900_authority` (old static 15:00 full state), `m43_master_c009_daily` (a fresh profile now reads 1, the day being claimed) and `m43_master_c010_meta` (the LoginDays tile reads `display_streak()`). The old full-hearts 15:00 lines in `coordination/OWNER_M42_HOME_POLISH_V06.md` and `OWNER_HEART_REGEN_INTERVAL_V01.md` are now marked as superseded. `base_popup.gd` was not touched.

## Acceptance criteria
1. [x] Full hearts: no timer, HUD shows DOLU/FULL, popup hides the pill, and the timer shows only below max. Evidence: new suite h01/h02 ("en full: HUD pill 'FULL'", "tr full: HUD pill 'DOLU'", "full + 600 s: still DOLU", "below max ... 15:00", "13:59", "TR popup full: 'Canlar dolu!', timer pill hidden", "EN popup below max: pill visible, 15:00"). The m42_home_v06 and m43_c003 full-state cases also pass.
2. [x] Collection set names and rarity are localized in TR and unchanged in EN. Evidence: c01 "EN title 'Set 1 · Meet the Scrubbots'", "EN burden 'C 0/4 · R 0/2 · E 0/2 · L 0/1'", "TR: all 15 set titles translated []", "TR burden 'S 0/4 · N 0/2 · E 0/2 · EF 0/1'"; c02 "TR set detail title 'Set 2 · Temizlik Ekibi'". m51 localization: every EN key has a TR key, 8/8.
3. [x] Scrubby copy is player-facing (EN+TR) and the no-modifier rule still holds. Evidence: r01 checks the exact EN/TR lines, finds no dev words (modifier/reference/neutral/economy/franchise/endgame and the TR equivalents) in any robot's role or perk, and confirms Scrubby's `perk_modifiers` is still empty.
4. [x] One streak truth, and a missed day resets before display. Evidence: d01 "missed days: stored 3, displayed 1 = today's D1", "Daily header 1 while D1 is TODAY (was 3)", "Profile Login Days 1 before the claim". d02 checks that the claim popup, the Profile tile and the Home view model all read 1. d03 checks that the next day shows header 2 with D2 TODAY.
5. [x] Tests with direct assertions for each item, and the CI guard updated. The new suite is in the CI loop with exact guard `SB-PHONE-2026-11-12-C copy/state evidence: PASS (8/8 cases, 0 fail)`. No existing CI suite's case count changed.

## Validation
Local Godot 4.7.2 headless on the worktree, after a one-off `--import`. The import-generated `.import`/`.uid`/`project.godot` noise was reverted and was not committed. LOCAL_PASS (exit 0, 0 script diagnostics, last line PASS):
- sb_phone_2026_11_12_c_copy_state 8/8
- m42_home PASS; m42_home_v04 18/18; m42_home_v05 13/13; m42_home_v06 13/13 (rerun after adding the missing UiText preload)
- m43_c003_c001_acquisition 34/34
- m43_master_c007_collection 19/19
- m43_master_c008_robots 10/10
- m43_master_c009_daily 12/12
- m43_master_c010_meta 12/12
- m51_localization_readiness 8/8
- m43_master_c005_meta_ceremonies 33/33 (rerun after the owner-table perk-name sync)
- m54_regression_pack_022_027 12/12
- m54_regression_pack_028_036 12/12
- sb_polish_004_006_ui_batch 10/10
- m39d_daily_collection PASS; m39_v03_full_surface PASS; m39b_hearts_speed PASS
- m55_heart_900_authority PASS (rerun after the full-state assertion update)
- m43_c005_c074_c077_celebrations 6/6
- m50_a11y_surfaces 3/3; m50_accessibility_audit 11/11
- m43_master_c006_shop 15/15
- m40_save_system PASS
- m54_collection_set_master_exactly_once PASS
- m43_master_c011_c014 29/29
- m44_ftue 23/23
- m43_r15_owner_remediation 18/18

m55_player_chaos printed PASS. Its 3 `SCRIPT ERROR` lines are the suite's own documented EXPECTED_FAULT_INJECTION. It is not in the CI loop.

`git diff --check` is clean and `git status --porcelain` is empty. TASKS.md was not edited (per coordinator).

## Log
### Round 1
Implemented the 4 owner phone-test fixes and the new suite listed above.

The first batch had 3 test failures, all from my own changes, and all were fixed and rerun:
- m42_home_v06 was missing the UiText preload, which caused a parse error.
- m55_heart_900_authority still expected the old 15:00 full state.
- m43_master_c005 e15 ties roster perk names to the owner roster table, so the Scrubby row there was updated to "Team Leader".

The hearts commit 4e49bcd3 also carries the one-line streak reader change in `home_screen.gd`, because both edits are in the same file.

Choices made without a human: the TR rarity abbreviations S/N/E/EF follow the existing TR rarity words (SIRADAN, not "Yaygın"). The HUD at max reuses the existing `LIFE_REFILL_FULL` key (FULL/DOLU), not a new key.
