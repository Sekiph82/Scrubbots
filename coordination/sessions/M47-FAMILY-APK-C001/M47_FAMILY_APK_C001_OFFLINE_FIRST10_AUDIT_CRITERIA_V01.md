# M47-FAMILY-APK-C001 — Independent Android First10 APK Audit Criteria

Repo: `Sekiph82/Scrubbots`. Scope: `SB-M47-001`/ `SB-M47-002` **early offline family-test slice only**, not completion of entire M47 or R2 OTA readiness.

## Critical
- Actual reproducible Android debug export produces a non-empty APK, verified by binary/package metadata and SHA-256. Source SHA and trusted action/build run are recorded. Downloadable artifact link/retention is genuine. No dummy renamed file and no claimed APK without export.
- Godot Android export setup, JDK/SDK/templates/CI evidence is truthful; no stealth installation of GB-class toolchains to owner PC; prefer remote CI if available and approved.
- Real built-in Levels 1–10 and actual app Home/Play/Results path are preserved, with appropriate focused content/gameplay/parse checks. No fixture-only substitute for app startup. Actual Android installation/touch/performance is separately labeled owner/device PENDING.
- CP04/CP05 and last-known-good path unchanged. No valid remote endpoint must result in offline built-in 1–10 gameplay, not crash or fabricated remote packs. No production R2 publication claimed. No publisher write credentials, signing keys or paid API secrets in repo/APK/log. Debug signing is appropriate.
- Correct portrait package metadata/app identity and version; robust failure logging. `git diff --check`/relevant tests, SHA, source preservation; no owner local data loss/reset/clean/force.
- Implementation/log published separately; local Desktop reconciliation remains non-destructive. ChatGPT sole root TASKS.md writer; Claude only implementation/builder log.
- **Excluded from first APK gate:** 150 real PNGs solved, Level Factory R05 strict full suite, production R2 manifest, remote 11–50, all M47 device stress, later visual polish and store release. They remain OPEN independently.
- Possible audit verdicts: `FIRST10_APK_TECHNICAL_PASS / FAMILY_DEVICE_INSTALL_PENDING`, `CHANGES_REQUIRED`, or precise `BLOCKED`. Never infer successful installation from a CI APK build.
