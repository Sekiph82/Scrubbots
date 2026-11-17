VERDICT: PASS

- Manifest sha256 for bow, full_turn and sweep match the .ogv files (sha256sum).
- The set holds 5 gestures: wave, turn, bow, full_turn, sweep. The diff only adds files, the manifest and the test.
- No runtime code changed (no .gd outside tests). Nothing deleted. git diff --check is clean.
- Test change is sound: KEYED_GESTURES extended, plus a loop asserting sha256 == bytes, the _keyed.ogv name and a VideoStreamTheora stream per gesture.
- m42_home_v04 after --import: 18/18 cases, 0 failures (the ObjectDB leak warnings are the usual exit noise).
- home_captures_new3_sheet.png: no visible magenta halos at sheet scale.
