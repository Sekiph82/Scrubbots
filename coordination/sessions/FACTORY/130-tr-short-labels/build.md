STATUS: READY

# Build: TR short labels / real EN+TR font floor (SB-M50-007 follow-up)

## Summary
I measured the real labels before shortening any copy. The 12-14 px "long-locale shrink" that factory 123 reported does not come from the real strings. It comes from the old a06 probe, which fed `"W".repeat(80)` into a 50 px wide label. The real English and Turkish copy, on the real nodes at design scale and with worst-case 4-digit numbers, never drops below 18 px. So no Turkish string was shortened and `HomeStyle.fit_font` is unchanged. Its 60% minimum is still needed by the m49 pseudo-locale stress. The floor is now enforced by a test: a06 asserts it for EN and TR.

Measured design px (EN / TR):
- Home REWARDED ADS: "REWARDED ADS" 24 / "ÖDÜLLÜ VİDEO" 24
- HUD level (`RESULTS_LEVEL`, level 9999): "Level 9999" 20 / "Bölüm 9999" 18
- booster Price (`BOOSTER_PRICE_SB`, 9999): "9,999 SB" 19 / "9.999 SB" 19

Files changed:
- tests/m50_accessibility_audit.gd: a06 now boots the real app. For each of `en` and `tr` it runs the production fit_font call on the real RewardedAdsButton, ProfileLevel and booster Price nodes and asserts each result is >= 18. The synthetic 60% check is kept as a printed note. a07 copy-only exclusion now also lists `ui_text_tr.gd`. Before this, a07 failed on origin/main because the SB-M51 TR table contains the word "reduced".
- docs/LOCALIZATION.md: a Tests bullet with the measured sizes and the rule that a longer translation of these keys needs shorter copy, not a smaller font.
- TASKS.md: follow-up note on the SB-M50-004..007 queue row and on SB-M50-007.

## Acceptance criteria
1. [x] EN and TR booster Price / HUD level / REWARDED ADS >= 18 design px: m50 a06 `ok: en: ... { "REWARDED ADS": 24, "Level 9999": 20, "9,999 SB": 19 }` and `ok: tr: ... { "ÖDÜLLÜ VİDEO": 24, "Bölüm 9999": 18, "9.999 SB": 19 }`.
2. [x] Shorter TR copy where needed: none needed, because every real TR string fits at >= 18. No TR string changed.
3. [x] a06 is a passing assertion for EN and TR, and the pseudo/synthetic shrink is only recorded: the a06 note line.
4. [x] m49 stress suites still pass (no overflow): see Validation.
5. [x] m51 TR table/placeholder guards pass: see Validation.
6. [x] TR wording documented in docs/LOCALIZATION.md.

## Validation
Godot 4.7.2 headless, LOCAL_PASS. Each run exited 0 with no SCRIPT ERROR or Parse Error:
- m50_accessibility_audit: PASS (8/8 cases, 0 fail)
- m49_touch_targets_text_stress: PASS (5/5 cases, 0 fail)
- m49_surface_stress: PASS (4/4 cases, 0 fail)
- m51_localization_readiness: PASS (8/8 cases, 0 fail)
- git diff --check: clean. The import artefacts were removed and project.godot was not touched.

## Log
### Round 1
- Probed the real nodes in EN and TR. The finding was an artefact of the synthetic string, so no copy change was made.
- Rewrote a06 as a real EN/TR assertion on the production nodes. Fixed the pre-existing a07 ledger failure (`ui_text_tr.gd` is copy only).
- Commits: 66fd5c2f (test + docs), 9a725876 (TASKS.md). Not pushed.
