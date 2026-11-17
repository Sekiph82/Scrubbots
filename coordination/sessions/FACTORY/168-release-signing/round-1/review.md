VERDICT: PASS

## Checks
- git diff --check: pass
- Diff grep (password/BEGIN/base64 blobs/keystore files): no secret values, no keystore/key files committed; only env var names.
- tools/check_release_versioning.py: PASS (0 problems); --selftest: PASS (incl. "caught debug AAB").
- Run 44105591683 (validate, clean_clone, export all success): every GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD line is masked as ***; no ks-pass value appears in the log. Printed cert output is Owner/SHA256 only (public).
- aab_release refuses debug: the AAB step fails unless BUILD_TYPE = release, and the static check enforces this.
- apk_only/validation_only/build_apk: the export gate only adds aab_release to the build list; the rest is unchanged. PKG_EXT defaults to apk for those modes.
- Concurrency: group is per ref, cancel-in-progress false. Main runs still share one queued group, so they never cancel each other.
- No store upload step; the artifact is only uploaded to GitHub (30 days).

## Findings
None.

## Notes
- bundletool is passed `pass:$PASSWORD` on its command line. That is masked in logs and only visible to the runner process, so it is acceptable.
