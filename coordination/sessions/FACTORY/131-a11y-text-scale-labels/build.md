STATUS: READY

# Build: SB-M50-012..017 + SB-M50-018 (text scale, focus, non-colour cues, Reduced ceremonies, ad path, a11y labels, motion/flash audit)

## Summary
Branch `factory/131-a11y-text-scale-labels`, 3 commits on bd84e13d:
- 3defb7ca: `docs/ACCESSIBILITY.md` (text size, screen reader / focus / back, non-colour cue table, rewarded-ad path, FULL vs REDUCED table for all 25 Reduced-aware scripts, WCAG 2.3.1 results), `tools/flash_audit.py` (general-flash counter for videos / PNG frame folders, 10-degree field, `--selftest`), `tools/flash_capture.gd` (windowed capture of the BoosterVfx effects and batch pops on real L1).
- cf4d5c81: UI fixes. Player buttons switched from `FOCUS_NONE` to `FOCUS_ACCESSIBILITY`, which only takes focus while a screen reader is active, so touch players see no change. Files: base_popup, home_screen, home_popup, settings_panel, gameplay_screen, acquisition_flow, results_screen, coachmark_layer, ui_shortcut_button. Icon-only and glyph buttons get `accessibility_name` through UiText in EN and TR: popup / Settings X, Settings ?, Home profile card, Gift Meter, the two + buttons, HUD Pause and 2x, the four boosters, Collection < and >, and the Tornado / Selector colour chips ("Color C05"). Locked Home tabs (Robots / Events / Ranks) now show an "LV N" pill (`NavLock_*`) instead of only a dimmed plate. Locked tabs, shortcuts and boosters carry "Unlocks at level N" as `accessibility_description`. 6 new `A11Y_*` keys in EN and TR. `tests/m50_accessibility_audit.gd` has new cases a09 / a10 / a11, and the CI guard goes from 8/8 to 11/11 in `.github/workflows/android-family-first10.yml`. New local suite `tests/m50_a11y_surfaces.gd`.
- 4f4a3def: TASKS.md queue rows DONE plus the M50-012..018 checklist items checked with their evidence.
- Not changed: gameplay, economy, art, Settings rows. No TEXT SIZE row was added, Reduced Effects is untouched and COLOR SYMBOLS stays default OFF.

## Acceptance criteria
1. [x] Text scale (012): Godot 4.7.2 has no OS font-scale API (probed: DisplayServer has only screen_get_scale; Android fontScale / Dynamic Type are not exposed), so this is documented and no Settings row was added. Evidence from `m50_a11y_surfaces` x02 on every surface at 1080x2400:
   - x1.15: 0 texts cut, ellipsized or losing lines (asserted).
   - x1.3: also 0 cut.
   - Overhang past the 1.0 layout is reported, not fixed: 8 controls at x1.15, 10 at x1.3 (Home captions, Home REWARDED ADS label, Profile caption, HUD booster price tags, Achievements badge at 1.3).
   - The m49 baseline at 1.0 passes (m49_touch_targets_text_stress 5/5, m49_surface_stress 4/4).
2. [x] Focus (013): x01 found 202 interactive buttons on all walked surfaces, all `FOCUS_ACCESSIBILITY`; a09 checks every Home button in EN and TR. Esc / back closes the top modal LIFO (m49_surface_stress v04 PASS; a10 back closes the ad screen). Keyboard / gamepad focus without a screen reader is not supported; this is documented.
3. [x] Non-colour cues (014 / M50-015 / 017): x03 asserts text cues on 8 surfaces:
   - robot LOCKED
   - YOUR RANK
   - all 4 rarity names
   - Rewarded Ads LOCKED / CLAIM
   - Daily CLAIM
   - Events CLAIM / Ends in / progress / First-Try run
   - Comeback catch-up texts

   Gap fixed: locked Home tabs were colour-only (dimmed); they now show "LV N" (a09 EN "LV 25/30/40", TR "BL 25/30/40").
4. [x] Reduced Effects ceremonies (015 / M50-013): reuses the a07 ledger (25 scripts, each with a suite that has a REDUCED arm, including m43_c005f_015). The FULL vs REDUCED table is in docs/ACCESSIBILITY.md and a11 checks it against the ledger. a11 also asserts:
   - The feel gateway allow-list is GFF punch_scale plus Spark spark / pickup / confetti only, so no flash, camera, shake or freeze is reachable.
   - Every REDUCED row is empty.
   - Every FULL intent ends in 1.3 s or less.
5. [x] Flash frequency (WCAG 2.3.1, FULL too), measured with `tools/flash_audit.py` (selftest PASS):

   | Source | Flashes per second | Peak field share changing |
   |---|---|---|
   | All 16 .ogv videos | 0, except result_scrubby_win at 2 | 4-44% |
   | BoosterVfx tornado / +1 slot / random / selector, 5 simultaneous batch pops (rendered windowed at 60 fps on L1) | 0 | 0-10% |

   Every source is within the limit of 3 per second.
6. [x] Accessible ad path (016 / M50-014), a10 with tests/support/rewarded_provider_double:
   - Opening the screen makes no provider request (no auto-play).
   - Every slot shows its reward, state and button as text.
   - Reward 1 is free with no video; the video starts only on WATCH AD.
   - A cancelled video grants nothing and shows "No reward: the video was closed."
   - If the provider never answers, the UI timeout frees the popup (shipping wait is 30 s; back is held only until then).
   - CLOSE and back decline.
   - The screen has no AudioStreamPlayer.
   - A Heart can also be bought for SB (`buy_heart` ok).
7. [x] a11y labels (017 / M50-016): Godot 4.7 has `Control.accessibility_name` / `accessibility_description` (AccessKit). A button counts as named if it has an accessibility_name or its own text has 2 or more letters. Results:
   - x01 walk: 202 buttons, 0 unnamed.
   - a09: EN and TR names checked on a fresh L1 profile.
   - Every `A11Y_*` key has a TR entry with the same placeholders (a09).
   - m51_localization_readiness 8/8.
8. [x] 018 table: docs/ACCESSIBILITY.md "Reduced Effects: FULL vs REDUCED per effect" and "Flashing".
9. [x] Pending owner / device checks (recorded in TASKS and docs): TalkBack / VoiceOver on a phone, and the FULL / REDUCED side-by-side phone review.

## Validation
- `m50_accessibility_audit` (headless): PASS 11/11, 0 SCRIPT ERROR. The only extra output is the usual exit "resources still in use" engine message, which is not a DIAG line.
- `m50_a11y_surfaces` (headless, local, about 4 min): PASS 3/3, 0 SCRIPT ERROR.
- `python tools/run_suites.py` on 24 related CI suites: aggregate PASS, exit 0, 0 SCRIPT ERROR. The run_suites console log was lost from the shared scratchpad, so each result was re-read from the worktree `validate_logs/*.log`:
  - m42_navigation, m42_home, m41_settings: PASS
  - m44_ftue 23/23, m44_contextual_coach 7/7, m44_unlock_gate 6/6, m44_new_badge 7/7, m44_pending_packs_gate 6/6
  - m44_meta_l1_unlock_ftue 6/6, m44_meta_verify_achievements_gift 4/4
  - m43_r15_owner_remediation 18/18, m43_r15_001_r01_sequential_unlock 14/14
  - m43_c003_c001_acquisition 34/34, m43_master_c007_collection 19/19, m43_master_c007r_pity 11/11, m43_personal_ranks 8/8
  - m49_responsive_matrix 8/8, m50_accessibility_audit 11/11, m50_color_symbols 10/10, m51_localization_readiness 8/8
  - m28_c002_c004_tile_visual 17/17, m28_c002_c001_gameplay_v02 14/14
  - m47_touch_r01_mobile_ux 14/14, sb_polish_003_booster_vfx PASS
- Local suites run directly: m42_home_v04 18/18, m43_c002_c001_popup_modal_pause 23/23, m49_touch_targets_text_stress 5/5, m49_surface_stress 4/4. All PASS with 0 SCRIPT ERROR.
- `python tools/flash_audit.py --selftest <16 videos>` and `--fps 60 <5 captured effects>`: PASS (worst 2 flashes per second).
- `git diff --check`: clean. The committed blobs have unchanged (LF) line endings.
- Tree: clean except one untracked `tools/__pycache__/`, which Python created while I ran the flash audit. My delete command was denied by the permission classifier. It is untracked, never staged, and the next job's worktree removal discards it.

## Log
### Round 1
First build. Probed the Godot 4.7.2 API: `accessibility_name`, `accessibility_description` and `FOCUS_ACCESSIBILITY` (= 3) exist; there is no font-scale query. A recon walk found that every player button was `FOCUS_NONE` and 13 icon-only or glyph buttons had no name. Fixed both, plus the colour-only locked Home tabs. Measured flashes in all videos and the native booster effects. Added the docs table and tests. Avoided analytics call sites, notification code and ceremony video code; the only CI file change is the m50 guard count (8/8 to 11/11). Not pushed.
