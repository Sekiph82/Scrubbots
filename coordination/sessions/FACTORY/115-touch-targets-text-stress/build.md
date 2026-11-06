STATUS: READY

# Build: SB-M49-020..022 touch targets >= 88 px + localization text-container stress

## Summary
New headless suite `tests/m49_touch_targets_text_stress.gd` boots the real app root (main.tscn, throw-away
`user://m49_tt_*` saves, `boot_save_path_override`) in sized SubViewports using the same stretch mapping as
`tests/m49_responsive_matrix.gd`, at 1080x2400, 1170x2532, 1536x2048 and compact 720x1280. It walks Home +
BottomNav, Tasks, Daily, Gift bar, Shop, Collection, Robots, Events, Ranks, Profile, Settings, Help, Life,
gameplay HUD (Pause, 2x, supply front HitAreas, boosters), the Pause popup and Results WON/LOST. Home and
gameplay are walked a second time on a save without `test_unlock_all`, so the real locked entries and the
locked booster "LV N" plates are measured too.
- t00 English baseline: no clipped, ellipsized or off-screen text. Text that overhangs its parent in English
  (corner badges, booster price tags, HeartsCount, the REWARDED ADS panel under Collection) is recorded per
  side as the approved design. Also asserts the new fit rule leaves the English font sizes unchanged.
- t01 every visible interactive control is >= 88x88 design px (scroll content measured at full size,
  everything else at its clip-visible size) and no two hit rects overlap (rects clipped by clip/scroll ancestors).
- t02 UiText pseudo-locale, now +40% (`PSEUDO_EXPANSION` 0.35 -> 0.40). t03 long Turkish sample (every key
  gets Turkish capitals and cedillas plus a +60% "LERİNİZDEN" suffix, placeholders kept), and the font used
  by every visible text control has İıŞşĞğÇçÖöÜü. In both: no clipped or ellipsized text, no lost wrapped
  lines, nothing leaves its clip ancestor or the screen, and nothing overhangs its parent further than the
  English design does. Each pass measures 1716 text controls; 1256 of them carry the stress copy.

Real failures found and fixed (UI only, no gameplay or economy change):
- Collection OPEN PACKS button was 80 px tall: now `UiTokens.TOUCH_MIN` (88).
- Booster Price tag, gameplay ProfileLevel ("LEVEL N") and Home REWARDED ADS (one line, no wrap) widened
  past their plates under longer copy. New `HomeStyle.fit_font(c, px, width)` shrinks the one-line font
  (floor 60%) until the text fits the plate width. It is applied at layout and when the text changes.
  English keeps 24 / 26 / 24 px (asserted).

Files: tests/m49_touch_targets_text_stress.gd (new), tests/m51_localization_readiness.gd (comment/message
~40%), scripts/ui/ui_text.gd, scripts/ui/home/home_style.gd, scripts/ui/home/home_screen.gd,
scripts/ui/gameplay_screen.gd, scripts/ui/collection/collection_screen.gd, TASKS.md.

Commits: c3183d11 (suite + fixes), e4ce0cdd (docs/tasks: queue row DONE, SB-M49-020 and -022 checked with evidence; SB-M49-021 popups-in-safe-area was already closed in the archive and has no live row). Not pushed.

## Acceptance criteria
1. [x] Headless suite boots the real app (throw-away saves) at 1080x2400, 1170x2532, 1536x2048 + compact
   720x1280: `tests/m49_touch_targets_text_stress.gd`, `M49 touch targets + text stress evidence: PASS (4/4 cases, 0 fail)`, exit 0, no SCRIPT ERROR / Parse Error.
2. [x] Every visible interactive hit rect >= 88x88 and non-overlapping on Home, BottomNav, gameplay HUD
   (Pause, 2x, supply HitAreas, boosters incl. locked plates: "4 locked booster plates shown at L1" on each
   size), Results, Shop, Daily, Settings, popups: t01 all `ok`. The first run found Collection
   `Action_packs [581,596 284x80]<88`, which is now fixed.
3. [x] Pseudo-localize all UiText at +40% and a long Turkish sample; labels don't overflow or clip: t02/t03
   all `ok`. Before the fix the suite flagged `Price leaves parent [255,2139 143x40] [248,2046 120x120]`,
   `ProfileLevel leaves parent [353,168 153x63] ...` and `RewardedAdsButton leaves parent [26,996 291x156] ...`. All three are fixed.
4. [x] Fix real failures minimally in UI code, with no gameplay/economy change: the 4 files above.
5. [x] Things needing an owner visual decision are listed below.

## Owner visual decisions (not blocking)
- The fit rule may shrink the booster price tag, gameplay "LEVEL N" and Home REWARDED ADS labels down to 60%
  of the design font in long locales. Whether that size is still readable on a phone is a visual call.
- English overhangs that t00 accepts as design: corner badges (RewardedAds and Daily badge), booster price tags
  below the plate, HeartsCount 4 px past its icon, and the REWARDED ADS panel placed below the Collection
  shortcut (outside its parent by construction).

## Validation
Godot 4.7.2 console, `--headless --path . -s res://tests/<suite>.gd`. Ran `--import` once, then restored
project.godot and the line-ending churn on .import files, and deleted the untracked .import/.uid/.translation files the import created (tree clean). All results LOCAL_PASS:
- m49_touch_targets_text_stress: PASS 4/4 (330 ok lines, ~7 min; not added to CI because of runtime)
- m51_localization_readiness: PASS 4/4
- m49_responsive_matrix: PASS 8/8
- m28_c002_c001_gameplay_v02: PASS 14/14
- m43_master_c007_collection: PASS 19/19
- m50_color_symbols: PASS 10/10
- m42_home_v04: 18/18, 0 failures
- m42_home: PASS
- m47_touch_r01_mobile_ux: PASS 14/14
- m39c_boosters: PASS
- m44_unlock_gate: PASS 6/6
(final rerun on the committed code: exit 0, 0 SCRIPT ERROR / Parse Error each)
- m28_c002_c002_static_shell: FAIL 4 (LockIcon texture allowlist + three +1 Slot shell asserts). This
  suite is not in CI. It fails the same way on the untouched HEAD files (verified by swapping the five
  HEAD versions in and running it), so the failures predate this job.
- `git diff --check`: clean.

## Log
### Round 1
Built the suite in stages. Each first-run false positive was caused by the suite itself and is now handled:
- scroll content outside the viewport: clipped for touch, horizontal-only bounds for text;
- negative rects from empty intersections;
- the Turkish swap breaking `%s` placeholders;
- auto-named node keys.
Added the English baseline (t00) so that approved overhangs are not counted as failures, and added a
stress-copy-reached-controls assertion so t02/t03 cannot pass vacuously. Fixed the four real failures
listed in the Summary.
