# M43-C005 ceremonies: verify-close 068-071, build 072

> Feature: Tasks SB-M43-068 (Collection set 9/9 completion ceremony with exact per-set SB/Bot Part reward), 069 (Master Collection completion ceremony +2500 SB +20 Bot Parts exactly once), 070 (Robot Unlock ceremony: canonical robot art, name, personality/perk summary, remaining Bot Parts carryover), 071 (robot unlock ceremony lets the player equip the unlocked robot or keep the current one), 072 (feature-unlock ceremony/coachmark when a meta system unlocks via M44 pacing; data/config/feature_unlocks_v1.json).

## Context
Most of this is already on main (the "M43 master" work).

- `scripts/ui/ceremony/meta_ceremonies.gd` (MetaCeremonies): builders `set_complete` (068), `master_complete` (069), `robot_unlock` (070/071: canonical `RobotRoster` master art, name, role, perk name/text, "Bot Parts left", two CTAs `equip` / `keep`), `feature_unlock` (072 builder only), plus gift/world builders. Presentation only, Reduced Effects removes motion only.
- `scripts/economy/ceremony_events.gd` (CeremonyEvents): read-only derivation of committed events from services (`gift:`, `set:<n>`, `master`, `robot:<id>`), rewards read from the same config the grant used (`economy_rewards_v1.json`: `collection.set_rewards[]`, `all_sets_complete` = 2500 SB + 20 Bot Parts).
- `scripts/ui/ceremony/ceremony_presenter.gd` (CeremonyPresenter): `pending()` / `drain(source)`; CTA closes -> `MetaUiState.mark_seen(key)` + canonical save (exactly-once, no replay on reload); routes `equip` to the equip authority. Wired in `scripts/app/main.gd` (Home drain `_drain_home_ceremonies`, Results hand-off `_begin_results_ceremonies`).
- `tests/m43_master_c005_meta_ceremonies.gd` (32 cases): e03-e08 set 9/9, e11-e14 Master exactly once, e16-e22 robot unlock + equip/keep, e29-e32 feature builder and "no feature-unlock authority" (e30 asserts CeremonyEvents derives no `feature_unlock`).
- 072 gap: `FeatureUnlocks` / `AppState.feature_unlocked(id)` / `feature_unlock_level(id)` (`scripts/progression/feature_unlocks.gd`, `data/config/feature_unlocks_v1.json`, SB-M44-010/031) exist, and `HomeBadges.new_features` shows a NEW pill, but NOTHING emits a feature-unlock ceremony when a fresh profile's campaign frontier reaches a table level. The only user of `MetaCeremonies.feature_unlock` is the What's New path (`main.gd _open_whats_new`, `FtueDirector.whats_new_event`, key `whats_new_key`).
- Art: icons in `assets/ui/final/home/shortcuts/` (daily, tasks, shop, collection, gift_bar, cards_exchange, ...). No new art may be generated.

Job split: 068, 069, 070, 071 = VERIFY-CLOSE (re-run existing suite, tick TASKS.md; no code change expected). 072 = BUILD. 073/074/075/077 are not in this job and stay as they are in TASKS.md.

## Requirements
1. 068-071: run the existing suite on the job branch; if green, mark SB-M43-068/069/070/071 done in TASKS.md as verify-close (cite suite, e-case numbers, factory job 057). Do not rewrite their code. If a case fails, fix the smallest cause.
2. 072: for a NEW FTUE profile (`economy.ftue.is_new_profile()`), when `AppState.feature_unlocked(id)` becomes true for a feature whose table level is > 1, present ONE feature-unlock ceremony per feature, once, using `MetaCeremonies.feature_unlock` (reuse; no new popup type).
3. Event identity: key `unlock:<feature_id>` (distinct from What's New keys and from `feature_visited:` keys), kind `feature_unlock`, `name`/`body` via `UiText` keys (add them to `scripts/ui/ui_text.gd`, e.g. `FEATURE_<ID>_NAME/BODY`), `icon` from an existing promoted asset. Unlock level text, if shown, comes from `feature_unlock_level(id)`, never hard-coded.
4. Derivation is read-only and lives where AppState is available (extend `CeremonyPresenter.pending()` and its drain/ack path, or an optional AppState-based helper next to `CeremonyEvents`; do NOT change `CeremonyEvents.events(economy)` output so e30 stays true). Acknowledgement reuses `MetaUiState.mark_seen` + canonical save exactly like other ceremonies; reload never replays; a save failure keeps it pending (fail closed).
5. Grandfathered saves (not a new profile) get no feature ceremonies. Features with table level 1 (hearts, gift_bar) get none. A feature with no existing icon asset gets no ceremony and is documented as skipped (builder already returns null without a real icon; do not invent art). Order: ascending table level, after gift/set/master/robot events.
6. No grant, spend, save-mutation other than the seen mark, or unlock-state change from the ceremony. The ceremony only presents `feature_unlocked` truth. Reduced Effects: same labels, no motion (builder already does this; test it).
7. When the unlock happens at the end of a level, it rides the existing Results hand-off barrier (`_begin_results_ceremonies`) / Home drain; no new scheduling path.
8. Add `tests/m43_c005_c072_feature_unlock_ceremony.gd` and add it to the CI `for s in ...` list in `.github/workflows/android-family-first10.yml` (update the header comment count line like the M44 entries).
9. Docs: tick SB-M43-068..072 in `TASKS.md` with evidence (LOCAL_PASS lines, job 057); add a short note to the ceremony section of `docs/` that lists M43-C005 ceremonies (grep `docs/` for `feature_unlock` / `Feature Unlock` and update that doc; if `AGENTS.md` lists ceremony sources, add the new test).

## Acceptance criteria
GODOT = `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`; W = the job worktree.

1. 068-071 still hold: `"$GODOT" --headless --path W -s res://tests/m43_master_c005_meta_ceremonies.gd` prints `M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)` (case count may grow only if e-cases are added, never shrink).
2. New suite prints `M43 C005 feature unlock ceremony evidence: PASS (N/N cases, 0 fail)` via `"$GODOT" --headless --path W -s res://tests/m43_c005_c072_feature_unlock_ceremony.gd`, with cases that assert directly:
   a. fresh profile at frontier below `daily` level (4): no feature event; after progressing to level 4, exactly one `unlock:daily` pending with title "NEW FEATURE!", the `UiText` name, `got_it` as the only action, icon = existing shortcut asset.
   b. crossing several table levels at once yields one ceremony per presentable feature, ascending by table level, one at a time.
   c. CTA acknowledges once: second `pending()` omits it; export/import of the save does not replay it; economy snapshot (wallet, hearts, boosters, collection, robots) is byte-identical before and after presenting.
   d. grandfathered (non-new-profile) save: zero feature events; table level 1 features (hearts, gift_bar): zero events.
   e. a feature with no presentable icon produces no event and no error.
   f. Reduced Effects: identical label texts, no spin meta on `HeroGlow`.
   g. save failure on acknowledge keeps it pending (no loop within the session, as What's New does if reused).
   h. `unlock:` keys do not collide with `feature_visited:` or What's New keys (marking one does not mark another).
3. `grep -n "unlock:" scripts/ui/ceremony/ceremony_presenter.gd` (or the chosen helper) shows the derivation, and `grep -rn "scrub_bucks\|wallet\|grant" scripts/ui/ceremony/meta_ceremonies.gd` shows no new calls into economy mutators.
4. Regression, each prints its existing PASS/summary with 0 fail: `m43_master_c005_meta_ceremonies`, `m44_unlock_gate`, `m44_new_badge`, `m44_contextual_coach`, `m44_ftue` (`M44 FTUE evidence: PASS (23/23 cases, 0 fail)`), `m43_master_c008_robots`, `m43_master_c009_daily`, `m43_master_c011_c014`, `m43_r15_owner_remediation`, `m43_c005f_phase3_meta_rewards_acquisition`, `m43_c005f_phase4_qa_r01_feel_lifecycle`, `m43_c005f_phase4_terminal_home_micro`, `m43_c001a_results_foundation`, `m39d_daily_collection`, `m39_v04_integration`, `m55_economy_release_regression`, `m55_long_session`, `m40_save_system`, `m50_accessibility_audit`, `m51_localization_readiness`. All invoked as `"$GODOT" --headless --path W -s res://tests/<name>.gd`.
5. `git -C W diff --check` is clean; `grep -n "m43_c005_c072_feature_unlock_ceremony" .github/workflows/android-family-first10.yml` matches; TASKS.md shows 068-072 checked with evidence.

## Out of scope
- Any new reward grant, balance change, or edit to `economy_rewards_v1.json` / `feature_unlocks_v1.json` values.
- New art or image generation; new popup frames.
- World ceremony (073), Gift milestone (074), Daily/Tasks celebration (075), 077, and C005F game-feel plugin work.
- SB-M44-031 part 2 (per-booster lessons, Daily/Tasks coachmark moves) and other coachmark scheduling changes.
- Changing `CeremonyEvents.events()` output or the e30 assertion.
- Rewriting the existing 068-071 builders.

## Assumptions
- 068-071 are fully implemented and tested already (suite cases e03-e22); verify-close is correct. Reason: code and tests read in the worktree.
- The "ceremony/coachmark" for 072 is the existing Feature Unlock popup (owner-accepted master), not a pointer coachmark; pointer coachmarks stay with M44 CoachmarkLayer.
- Only new FTUE profiles get ceremonies (grandfather rule from `AppState.feature_unlocked`); established saves already have everything.
- Only features that already have a promoted icon get a ceremony; others degrade silently and are listed in the TASKS.md evidence note as follow-up art. Reason: no new art generation allowed.
- Boosters (plus_one_slot, random, selector, tornado) stay with SB-M44-031 part 2 lessons unless a presentable icon already exists; the builder may include them only if icon and copy exist.
