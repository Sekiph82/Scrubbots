# Review round 2: 117-release-export-versioning

## Checks
- python -I tools/check_release_versioning.py: pass (0 problems); --selftest: pass
- Android workflow and preset diff 0419f569..HEAD: empty, so the Android debug path is unchanged from round 1.

## Round-1 finding 1: fixed
- ios-ipa.yml env sets APP_NAME: Scrubbots. The preset export_path, the Godot --export-release path, the Xcode build outputs (`.ipa` from archive export or Payload zip) all use ${OUT_DIR}/${APP_NAME}.ipa in both debug and release, so Xcode project, scheme, binary and pck names are back to Scrubbots.
- `test -s "${APP_NAME}.ipa"` runs first; the `mv` to ${ARTIFACT}.ipa is the last line, after the build and the non-empty check.
- Inventory, summary and upload steps read ${OUT_DIR}/${ARTIFACT}.ipa.
- Docs and check script were updated to match.

## Must-fix
None.

VERDICT: PASS
