# Review round 1, job 129-release-hygiene

## Checks
- python -I tools/check_release_versioning.py: PASS (0 problems); --selftest PASS (all 19 mutations caught)
- yaml parse of android-family-first10.yml and ios-ipa.yml: OK
- git diff --check origin/main...HEAD: clean
- tests/m59_credits.gd: PASS 3/3
- tests/m51_localization_readiness.gd: PASS 8/8
- tools/validate_content.gd: CONTENT_VALIDATION PASS (30 entries, 0 problems)
- tests/m41_settings.gd: FAIL (1), "re-save differs only by color_symbols reset + color_symbols_optin marker" (_color_symbols_optin_migration, line 511). The diff touches no save/AppState/effects code and does not touch the test, so this looks pre-existing on main. I did not run it on main to confirm. Not blamed on this job. Settings layout assertions (Reduced Effects, CloseButton) did not fail.

## Debug path (highest risk) review
- android debug apk_only: validate and clean_clone both skipped (conditions need release for apk_only); export guard first clause (apk_only and not release) is true under always(), so it still skips validate. Unchanged.
- android debug build_apk: validate must pass as before. clean_clone now also runs but export does not require it for debug (extra runner time only, not a gate).
- android release: validate + clean_clone success required, also for apk_only.
- iOS debug: release_gate skipped, ipa guard `always() && (build_type != 'release' || gate success)` is true; APP_NAME Scrubbots basename unchanged.
- iOS release: ipa needs release_gate success.
- Filters: exclude `addons/godot_ai/*` and include `addons/game_feel_flow/LICENSE, addons/saltmire_spark/LICENSE.txt` are comma-separated, forward-slash, rooted-relative like the existing entries; the addon paths match the tracked files. godot_ai is untracked and editor-only, so no runtime resource is dropped. Include filter only adds non-resource files under all_resources.
- iOS release_gate content-validator step lost its line continuation but still parses as one valid `&&` command line.

## Credits / Settings
- Licence texts come from Engine.get_license_text()/get_copyright_info()/get_license_info() and the shipped LICENSE files read with FileAccess (not retyped). EN+TR title keys present. CREDITS sits beside CLOSE in one ActionRow (same panel height). Opens only from Home (main.open_credits guards route). Text volume rides one ScrollContainer of Labels: acceptable.
- clean_clone_check.py not run (per instructions); read, no owner-checkout writes seen in the workflows' use.

## Must-fix
None.

VERDICT: PASS
