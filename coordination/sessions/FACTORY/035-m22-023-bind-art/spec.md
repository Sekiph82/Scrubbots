# Bind remaining booster state art (SB-M22-023)

> Feature: Task SB-M22-023 "Bind approved booster/decorative art to reusable components" — remaining: 4 approved state arts under assets/ui/final/boosters/states/ are not referenced anywhere: booster_free_badge_frame, booster_reward_glow, booster_activated_burst, booster_tutorial_pointer.

## Context
- Booster button is built in `scripts/ui/gameplay_screen.gd` `_make_booster()` (line ~441): Button with children Icon, SelectedRing, UnavailableOverlay, Badge (Label, charge count, green box), Price. Art constants `BOOSTER_SELECTED_ART` / `BOOSTER_UNAVAILABLE_ART` (lines 74-75); decorative TextureRects come from `HomeStyle.art(name)` + `_frac(...)`. State is applied in `_apply_booster_visual(id)` (~817) and fed by `set_booster_states(states)` (~808) from `production_gameplay_host.gd` `_refresh_hud()` (~893).
- Booster activation succeeds in `production_gameplay_host.gd` `execute_booster()` (~1090; `r["ok"]`) and `on_booster_committed()` (~1618).
- Docs: `docs/MASTER_UI_SYSTEM.md` section 12 (quantity/price/state badges are live overlays, never baked into icon art; Gift Bar/Daily grant free charges). `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_MASTER_LIST.md` P2-043..046 declare purposes: reward glow = "Reward presentation"; activated burst = "Activation feedback"; tutorial pointer = "Tutorial cue"; free/ad badge frame = "Frame only; no FREE/ad copy baked".
- The FTUE coachmark (`scripts/ui/tutorial/coachmark_layer.gd`) already binds its OWN pointer, `res://assets/ui/final/gameplay/tutorial/tutorial_pointer.png`, for every step including booster steps. `states/booster_tutorial_pointer.png` would duplicate it; no distinct booster-only coachmark hook exists.
- Budget test `tests/m22_025_booster_texture_budget.gd` already counts all 10 booster PNGs (12 MiB, 512 px cap, EXPECTED_COUNT 10); binding adds no new files so it must stay green. Its `_referenced_paths()` lists referenced art constants.

## Requirements
1. Free badge frame: add const `BOOSTER_FREE_BADGE_ART` (path of `booster_free_badge_frame.png`) and a `BadgeFrame` TextureRect (via `HomeStyle.art`, `_frac` around the Badge rect, added to the button BEFORE the Badge label so the count draws on top). Visible exactly when the Badge is visible (charges > 0, i.e. the existing owned-charge state). No text baked/added beyond the existing count.
2. Reward glow: add const `BOOSTER_REWARD_GLOW_ART` and a `RewardGlow` TextureRect on each booster button (hidden by default, behind Icon). In `set_booster_states`, when a booster's charges increase versus its previously stored value (a grant, e.g. Gift Bar/Daily/reward), show the glow via a short tween that fades it out and hides it. No glow on first population or on decrease.
3. Activated burst: add const `BOOSTER_ACTIVATED_BURST_ART` and an `ActivatedBurst` TextureRect (hidden by default, above Icon). Add public `play_booster_activated(id: String)` on gameplay_screen that shows it with a short fade-out tween. Call it from `production_gameplay_host.gd` `execute_booster()` only when `r.get("ok", false)` and `_screen` is valid.
4. Tweens must be killed/freed when the node exits (bind to the button node with `create_tween()` on that node) and use a short duration (<= 0.6 s); end state hidden. No per-cell nodes; only 3 extra TextureRects per each of the 4 booster buttons.
5. `booster_tutorial_pointer.png`: NOT BOUND. The coachmark already uses the gameplay/tutorial pointer; there is no booster-specific coach hook. Do not reference it, do not delete it. Document in TASKS.md that it is "not bound — needs owner/feature (booster-specific coachmark)".
6. Add the three new art constants to `_referenced_paths()` in `tests/m22_025_booster_texture_budget.gd`.
7. Docs: update the SB-M22-023 entry in `TASKS.md` (bound list now includes free badge frame, reward glow, activated burst; the pointer left open, item stays `[ ]` with that single remainder) and the `## Autonomous Queue` line 31 accordingly; add one line to `assets/ui/VISUAL_ASSET_INDEX.md` or AGENTS.md only if they already list binding status of these assets.

## Acceptance criteria
1. New suite `tests/m22_023_booster_state_art.gd` (SceneTree script, instantiates `gameplay_screen.gd` like other UI suites do, no `main.tscn`) asserts, via node state:
   - every booster button has `BadgeFrame`, `RewardGlow`, `ActivatedBurst` TextureRects with non-null textures whose `resource_path` ends with the three expected filenames;
   - `set_booster_states` with charges 0 -> `BadgeFrame.visible == false`; with charges 2 -> `BadgeFrame.visible == true` and equals `Badge.visible`;
   - first population does not show `RewardGlow`; a later call raising charges 0->1 makes `RewardGlow.visible == true` right after; a call lowering charges leaves it unchanged/hidden;
   - `play_booster_activated("tornado")` makes that button's `ActivatedBurst.visible == true` and others stay hidden;
   - the number of booster buttons is still 4 and no node in the board path is added (child count of `BoosterRow` == 4).
   Command: `"$GODOT" --headless --path C:/Users/sekip/Desktop/ScrubBots-factory/035-m22-023-bind-art -s res://tests/m22_023_booster_state_art.gd` prints a PASS line (suite's final line, same style as `m22_025_booster_texture_budget.gd`) and exits 0.
2. `m22_025_booster_texture_budget.gd` still prints its PASS line (10 PNGs, <= 12 MiB, all referenced paths load including the 3 new ones).
3. Host hook verified: grep `play_booster_activated` in `scripts/gameplay/runtime/production_gameplay_host.gd` shows it called only inside the `r.get("ok", false)` path of `execute_booster`.
4. Existing booster/gameplay-screen suites still PASS: `tests/m39c_boosters.gd`, `tests/m39_c003_random_any_booster_rewards.gd`, plus any suite whose grep matches `gameplay_screen` or `Booster_` under `tests/` (builder lists which ran).
5. `grep -rn booster_tutorial_pointer scripts scenes tests` returns nothing; TASKS.md SB-M22-023 text states the pointer is not bound and why.
6. `git diff --check` clean.

## Out of scope
- Binding the booster pointer art or adding any FTUE/coachmark flow; SB-M44-031 unlock gating; new mechanics, new popups, new booster states, new currencies.
- Editing, regenerating, resizing or re-importing the PNGs; changing the 512 px / 12 MiB budget.
- Changes to acquisition_flow.gd popups or reward ceremony screens.

## Assumptions
- "Free badge" = the existing owned-charge (CHARGE_AVAILABLE) badge; no distinct "free/ad" state exists, so the frame wraps the existing count badge.
- "Reward grant" = observed charge increase in `set_booster_states`; no separate booster-grant ceremony hook exists and this is the least invasive existing event.
- Pointer left unbound: its purpose duplicates the already-bound coachmark pointer; inventing a booster-only coach flow would be a new UI flow.
- Reduced-effects setting does not exist in gameplay_screen; the tweens are short fades, so no extra gating.
