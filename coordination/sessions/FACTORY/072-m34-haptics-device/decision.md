APPROVE

## Why
The branch ships the code-side fix: the Android preset now declares VIBRATE (the installed APK had no permissions, so every haptic call was dropped), and family APKs are signed with the owner-approved stable debug key from GitHub Secrets. All three round-1 reviews are PASS, merge-tree reports no conflicts, and the diff leaks no secrets. SB-M34-006 stays open and is not marked done, so TASKS.md does not claim more than was proven. The caller redefined the deliverable to this code-side fix.

## Acceptance criteria
1. ON/OFF captures in the doc: NOT MET. The phone was unplugged. The doc has the exact commands and the task stays open. This is the accepted deviation.
2. Doc states the APK source and the Owner note: met. It names run 41116404350 (no permissions) and runs 41127683939, 41129466216 and 41129478628 (VIBRATE declared, checked with aapt2).
3. SB-M34-006 done with DEVICE_AUTOMATED_PASS: NOT MET, deliberately. It stays open, which is honest.
4. SB-CAMPAIGN-L11-L30 row: met per build.md. It contains 06fbfbad and the owner-skip wording, and the "m55_long_session FAIL" clause is gone.
5. Regression: met. No GDScript changed, and build.md records both m34 suites as LOCAL_PASS.
6. `git diff --check` clean and changed files limited to scope: met. The changed files are the doc, TASKS.md, the preset, the workflow and one docs/12 line. The workflow change is the owner-approved signing key. Secrets are referenced only through `secrets.*`.

Spot-check: I read the workflow and preset diff myself. The keystore comes from a secret, with a generated fallback, and the password is not echoed.

## For the human
Not an escalation. Follow-up for SB-M34-006: plug in the phone. Reinstall once with the versionCode-45 APK, keeping the save as build.md describes. Then run the ON/OFF commands in `docs/M34_HAPTICS_DEVICE_VALIDATION.md`. Separately, m55_long_session fails on main in build_apk mode.
