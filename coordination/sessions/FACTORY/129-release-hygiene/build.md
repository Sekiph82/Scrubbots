STATUS: READY

# Build: 129-release-hygiene (SB-M59-006..010 + credits/licences screen)

## Summary
Branch `factory/129-release-hygiene` (3 commits on 3d37ae9d: 78f70ede, f91a0f5c, ca32f96a). Not pushed. No workflow dispatched, no APK/IPA built.

- Release gate (006/007/009): Android `validate` now also runs for `build_type=release` with `apk_only`, and it runs the new content validator `tools/validate_content.gd` (LevelCatalog.load_manifest + validate_all, fail closed, `CONTENT_VALIDATION PASS|FAIL`). There is a new `clean_clone` job (`tools/clean_clone_check.py`). `export` needs `[validate, clean_clone]`: a release export (build_apk or apk_only) needs both green, debug build_apk needs validate as before, and debug apk_only stays the owner's untested quick path. iOS has a new `release_gate` job (ubuntu, release only): clean-clone check, versioning check, content validator, then every Android validate suite through `tools/run_suites.py`. `ipa` needs it for release; debug runs unchanged.
- 008: the release Android path is documented and gated and keeps the 117 naming/versioning (OUT_DIR/ARTIFACT unchanged, still checked).
- 009: `tools/clean_clone_check.py` (stdlib, `python -I`) runs `git clone --depth 1` of the committed HEAD into a temp dir (validate tree set), imports headless (exit 0 and 0 script diagnostics required), restores project.godot, runs the smoke suites through the clone's own run_suites.py, then deletes the temp dir. The source checkout is only read by `git clone`.
- 010: `addons/godot_ai` is added to the export exclusions list, to both presets' `exclude_filter` and to both export sparse checkouts. The addon LICENSE files ship through `include_filter`. `check_release_versioning.py` asserts the exclusions, the licences (present, MIT, included, shown by credits), each autoload exactly once, and no godot_ai in project.godot. The addons' `editor/` subtrees are kept: they are editor-only and harmless at runtime, and excluding them has unverified class-cache risk.
- Credits: Settings has a CREDITS button (`CreditsButton`) sharing the CLOSE row. It closes Settings and pushes a read-only `credits` BasePopup (large frame, touch scroll, one CLOSE) on the app ModalStack. The popup shows the Godot licence from `Engine.get_license_text()`, the engine third-party components and licences from `get_copyright_info()`/`get_license_info()` (these include its default font; the game bundles no fonts), and the Game Feel Flow and Saltmire Spark LICENSE files verbatim. Keys go through UiText, EN + TR.

Files: .github/workflows/android-family-first10.yml, .github/workflows/ios-ipa.yml, .github/android/export_presets_family_first10.cfg, .github/android/family_first10_export_exclusions.txt, tools/check_release_versioning.py, tools/validate_content.gd (new), tools/clean_clone_check.py (new), scripts/ui/credits_screen.gd (new), scripts/ui/settings_panel.gd, scripts/app/main.gd, scripts/ui/ui_text.gd, scripts/ui/ui_text_tr.gd, tests/m59_credits.gd (new), docs/RELEASE_BUILDS.md, docs/PRIVACY_DATA_INVENTORY.md, TASKS.md.

## Acceptance criteria
1. [x] 006/007: release paths run the full validate and the content validator first and refuse to export on failure; debug apk_only is the documented exception. Evidence: the `export`/`ipa` `if:` + `needs:` rules, checked by `python -I tools/check_release_versioning.py` (PASS) and `--selftest` (PASS; it catches validate skipped for release apk_only, the old export guard, a missing clean_clone need, a dropped content validator, a dropped clean_clone job, iOS release without the gate, and an iOS gate without the suites). PyYAML parse of both workflows: jobs/needs/if as intended. `tools/validate_content.gd` locally prints `CONTENT_VALIDATION PASS (30 entries, 0 problems)` with exit 0. With a corrupted level_013 it printed `CONTENT_VALIDATION FAIL (29 entries, 1 problems)` with exit 1 (file restored).
2. [x] 008: the release Android build is documented (docs/RELEASE_BUILDS.md "Release gate" table) and gated, and uses the 117 naming/versioning (the existing checks still pass). The build was not executed (no dispatch, per the job brief).
3. [x] 009: the CI `clean_clone` job plus local `tools/clean_clone_check.py`. Local run on f91a0f5c: import exit=0 script_diag=0; m59_app_version 4/4, m43_c001a_results_foundation 11/11, m43_c005f_phase6_unlock_feel 8/8; `CLEAN_CLONE_CHECK PASS` (7m15s). The temp dir is removed afterwards.
4. [x] 010: godot_ai and tests/tools are excluded in both presets and both export checkouts. Licences are present in-repo and included. Autoloads are registered once, and project.godot does not reference godot_ai. Evidence: the static check and selftest (catches a missing godot_ai exclude, tools in the iOS workspace, a licence not shipped, a duplicate autoload, godot_ai loaded, credits lacking a licence). m58 is still 7/7.
5. [x] Credits screen: `tests/m59_credits.gd` PASS 3/3. It checks the row is keyed, 88 px tall and inside the frame; that the Vibration/Reduced Effects/Color Symbols/Language order is unchanged; that the Settings frame is 1818 px and fits 1920; that Settings closes and the credits popup is the one top modal; that the Godot text == Engine.get_license_text(); that both addon texts == their LICENSE files; that the components and 21 licence texts are present; that the list scrolls; that CLOSE empties the stack; and the Turkish title. It is added to the CI suite list (on the m41_settings line, not the last line) with the exact guard `SB-M59 credits evidence: PASS (3/3 cases, 0 fail)`.

## Validation
All LOCAL_PASS with Godot 4.7.2 via `python tools/run_suites.py` (CI rule: exit 0, no diagnostics, last line PASS, exact guard):
- m41_settings PASS (after the layout fix, see the Log), m51_localization_readiness 8/8, m58_privacy_inventory 7/7, m59_app_version 4/4, m59_credits 3/3, m49_responsive_matrix 8/8, m42_navigation PASS, m44_ftue 23/23, m50_accessibility_audit 4/4, m56_analytics_taxonomy 21/21, m54_regression_pack_028_036 12/12, m43_master_c011_c014 29/29.
- `python -I tools/check_release_versioning.py`: PASS (0 problems). `--selftest`: PASS (19 cases).
- `python tools/run_suites.py --selftest`: PASS. `--list` includes m59_credits (77 suites).
- `python -I tools/clean_clone_check.py`: CLEAN_CLONE_CHECK PASS.
- `git diff --check` clean. One `--import` run in the worktree; project.godot, .import eol churn and generated .uid/.translation files were restored or removed, and the tree is clean.
- No CI run: the first run of the new clean_clone / release_gate jobs is pending.

## Log
### Round 1
- Implemented everything above.
- First test run: m41_settings failed at 1080x1920 and 1440x1920, because the extra CREDITS row made the panel 1922 px, over the 1888 limit. Fixed by putting CREDITS beside CLOSE in one `ActionRow`, which keeps the panel height at 1818. m41 and the rest now pass.
- Notes for review:
  - The credits popup holds about 80 KB of engine licence text (one Label per licence). Headless open + 4 frames takes about 540-716 ms. That is acceptable for a rarely opened screen; if phones feel slow, the fix is lazy per-section expansion.
  - Commit 78f70ede alone fails check_release_versioning, because credits_screen.gd only arrives in f91a0f5c. Branch tip is green.
  - `open_credits` closes Settings first and is Home-only, mirroring Help. No analytics event was added, because "credits" is not in the screen enum.
