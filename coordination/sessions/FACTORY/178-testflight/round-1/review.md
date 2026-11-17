VERDICT: PASS

1. Gating: upload step `if: inputs.build_type == 'release' && inputs.testflight_upload`; an early step fails if testflight_upload is true without release. Default false. Other modes unchanged (only the plist key, which applies to all IPAs by design).
2. Secrets: p8 comes from a secret env var, written to a 600 file under ~/.appstoreconnect, removed right after altool (also on failure, via set +e). Never echoed. Log of run 44195307315: ASC_* values masked as ***, no key material (only the script text mentions AuthKey_). Run succeeded, UPLOAD SUCCEEDED. Note: ephemeral GitHub runner, so residual risk is minimal.
3. ITSAppUsesNonExemptEncryption=false: correct for HTTPS/OS-only crypto (exempt). The step also verifies it in the built IPA plist.
4. check_release_versioning.py: allows only one upload step guarded exactly by TESTFLIGHT_IF, only for the iOS workflow (Android still rejects uploads). Selftest proves 3 negatives (missing release guard, release-only guard, upload outside the step). `python -I tools/check_release_versioning.py` PASS; `--selftest` PASS.
5. m58 privacy inventory text, RELEASE_BUILDS.md, RELEASE_GATES.md/.json and m60 test string are consistent. The 587 to 708 strings change is a regenerated count and is harmless.
6. No App Review submission, external testing or release: altool --upload-app only; docs state the owner keeps those.

Non-blocking: `grep -c` of the plist uses `out/ipa_entries.txt` from an earlier step (worked in run). Minor wrapped doc line in PRIVACY_DATA_INVENTORY.md.
