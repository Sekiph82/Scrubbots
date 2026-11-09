STATUS: READY

# Build: SB-M50-004..007 + SB-M50-010..011 (accessibility: contrast, Reduced Effects, touch, readability, icon families, plain gameplay)

## Summary
Branch `factory/123-a11y-contrast-icons`, commits 19e86773 (suite + fixes) and 8a843db7 (TASKS.md). Not pushed; no rebase onto 9f1ada33.

- `tests/m50_contrast_surfaces.gd` (new, windowed, local only). It extends the factory 118 walk (`m49_surface_matrix.gd`) and runs at 1080x2400 on every M43/M44 surface: Home and every Home popup, Collection, Robots, ceremonies, packs, the gameplay HUD and its popups, Level Intro, and Results WON/LOST.
  - For each surface it renders the screen once with the text (A) and once with only the text colours hidden (B). Ink is every pixel where A differs from B.
  - Background is the pixel in B with the median luminance under the ink. Fill is the theme font colour times the modulate chain. When an outline is at least 2 px with alpha at least 0.5, the score is the better of fill vs outline and fill vs background.
  - Scroll lists are paged so rows below the fold are measured too.
  - Rule: >= 4.5:1 for normal text and >= 3:1 for large text. Large means >= 24 design px with a bold face (weight >= 700), or >= 32 design px.
  - Disabled buttons are exempt (WCAG inactive controls). Two fully transparent semantic button texts are skipped: the Pause and 2x button values, whose drawn glyph/labels are measured instead.
  - c02: every visible text must be at least the 18 px floor.
  - Under `--headless` it prints NOT_RUN and exits 1, because it needs pixel readback.
- `tests/m50_accessibility_audit.gd`: grows from 4 to 8 cases. The CI guard in `.github/workflows/android-family-first10.yml` is now 8/8.
  - a05: icon families at 48 px.
  - a06: font floor 18 design px, plus the fit_font finding.
  - a07: Reduced Effects wiring and the coverage ledger.
  - a08: a decoration-free level is WON.
- `tests/m49_surface_matrix.gd`: `_walk` now awaits `_scan`, so the subclass can render between captures. m49 behaviour is unchanged.
- Contrast fixes (UI colours only; no owner art or board palette touched):
  - `scripts/ui/daily/daily_screens.gd`, `scripts/ui/daily/rewarded_ads_screen.gd`: State green `Color(0.2,0.55,0.12)` -> `Color(0.12,0.40,0.07)`. It measured 3.95:1 and 3.46:1; it is now about 6.5:1 and 5.7:1.
  - `scripts/ui/profile/profile_screens.gd`: Ranks future-tier card fade `modulate.a` 0.6 -> 0.75. It measured 3.70:1 and is now about 5.6:1.

## Acceptance criteria
1. [x] Extended the accessibility audit with WCAG contrast for every visible Label/Button over its actual rendered background, on all M43/M44 surfaces at one phone size, with the rule stated. Evidence: `godot --path . -s res://tests/m50_contrast_surfaces.gd` (windowed) exit 0: "868 text controls measured (30 disabled exempt, 2 transparent semantic, 0 never scrolled into view): normal >= 4.5, large >= 3.0 []", `M50 contrast surfaces evidence: PASS (2/2 cases, 0 fail)`. The first run found 11 real fails on 3 label styles (Daily TODAY 3.95, Rewarded Ads state 3.46, Ranks future tiers 3.70); after the fixes it passes.
2. [x] Real contrast failures fixed with minimal UI colour changes (see Summary).
3. [x] Reduced Effects (SB-M50-005). a07 turns on REDUCED EFFECTS through the real Settings toggle and checks that every live consumer reports Reduced: service, feedback_adapter, meta_reward_feel, ceremonies, home_hero, coachmarks, results_model, cleaning_fx, gameplay_screen, level_intro. Turning it OFF applies live to the running level. A ledger maps 25 Reduced-aware UI/gameplay scripts to the suite holding their REDUCED arm (m43_c005f_015 and others), and any new Reduced-aware script missing from the ledger fails the test. No product gap was found, so no new effect code was added.
4. [x] Touch sizes (SB-M50-006): covered by `m49_touch_targets_text_stress` t01 and `m49_surface_matrix` v02; not duplicated. Both are LOCAL_PASS on this branch.
5. [x] Readability floor, with the fit_font check. The floor is 18 design px (about 6.9 dp on a 411 dp wide phone). Every visible English text is >= 18 px (c02: "smallest visible text 18 px"). The check showed that the fit_font 60% floor DOES go below it: a long locale can shrink the booster Price to 12 px, the HUD ProfileLevel to 13 px and REWARDED ADS to 14 px. I tried clamping fit_font at 18; m49_touch_targets_text_stress and m49_surface_stress then failed (REWARDED ADS text left its plate), so I reverted the clamp. a06 asserts the current values and prints this as a FINDING for an owner/localization decision (needs shorter copy or wider plates per locale).
6. [x] Icon families distinguishable at 48 px (a05). Rule: silhouette difference (1 - IoU of alpha masks) >= 0.15 OR mean-colour CIEDE2000 >= 10 under normal vision and every CVD simulation. Families: currencies (3), boosters (4), nav (5), reward rows (8, the MetaCeremonies.REWARD_ROWS icons) and Home shortcuts (9); all pass. Closest pair: Standard vs Premium pack, silhouette 0.07, colour dE00 11.4, so they are told apart by colour only.
7. [x] Essential gameplay without decoration (a08): real L1 with Reduced ON, the feel plugin backends absent (`set_backends_for_test(null, null)`) and colour symbols OFF. Board renders 400 opaque ACTIVE cells, the five-slot strip and supply (3 columns) are shown, and Scrubbot visuals are drawn on the agent layer. Result: WON in 616 ticks, with no particle work planned for any feel request.

## Validation
All results are LOCAL_PASS with Godot 4.7.2.
- `tools/run_suites.py`, 13 suites, aggregate=PASS 13/13: m50_accessibility_audit (8/8), m50_color_symbols (10/10), m43_personal_ranks, m43_master_c009_daily, m43_master_c011_c014, m43_r15_owner_remediation, m47_touch_r01_mobile_ux, m51_localization_readiness, m28_c002_c001_gameplay_v02, m43_c005_c074_c077_celebrations, sb_polish_002_gift_meter, m41_settings, m44_ftue.
- Direct headless runs, each exit 0 with 0 SCRIPT ERROR:
  - m49_surface_matrix 3/3
  - m49_touch_targets_text_stress 4/4
  - m49_surface_stress 4/4
  - m50_board_symbols 8/8 (b08 NOT_RUN headless, by design)
  - m22_029_texture_cold_warm
- Windowed m50_contrast_surfaces: PASS, exit 0. In one earlier windowed run the engine segfaulted at exit (139) after printing PASS; the next three windowed runs exited 0.
- m50_color_symbols failed once on its timing bound (300 rebinds in 3092 ms) while other Godot processes were loading the machine. It passed 10/10 on two quiet reruns; that suite was not touched.
- `git diff --check` is clean. Import churn (project.godot, .import, .uid, .translation) was restored or removed, and the tree is clean.

## Owner visual items
- The 3 colour changes need an owner look: the darker Daily/Rewarded Ads state green and the less-faded Ranks future tiers.
- Owner/localization decision: long-locale fit_font text at 12-14 px (booster Price, HUD level, REWARDED ADS) is below the 18 px floor.
- Standard vs Premium card pack icons share one silhouette and differ only by colour (passes the rule; worth a look).

## Log
### Round 1
- Built the rendered contrast suite on top of the factory 118 walk (`_scan` is now awaited).
- Fixed 3 contrast fails.
- Added audit cases a05 to a08 and raised the CI guard to 8/8.
- Tried and reverted a fit_font readability clamp (it broke the m49 long-locale stress); recorded it as a finding.
