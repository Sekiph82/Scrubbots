# M47-FAMILY-APK-C001 — Independent Android First10 APK Audit Criteria V02

Repo: `Sekiph82/Scrubbots`
Scope: `SB-M47-001` / `SB-M47-002` early offline Family debug APK slice only.

**V02 supersedes V01.**

Owner export hygiene authority:
`coordination/sessions/M47-FAMILY-APK-C001/OWNER_EXPORT_HYGIENE_V01.md`

## 1. Real APK

PASS only if:
- actual reproducible Android debug export produces a non-empty APK;
- APK signature/package metadata/SHA-256 are verified;
- source SHA and trusted build run are recorded;
- artifact URL is genuine;
- no renamed placeholder.

Real-device install remains owner/device PENDING until actually installed.

## 2. Safe Desktop / CI

- owner Desktop non-destructively synced before/after;
- no reset/clean/restore/checkout destruction;
- owner project.godot hash unchanged;
- no stealth multi-GB Android installs on owner PC;
- GitHub Actions preferred when appropriate;
- no secrets in repo/APK/log.

## 3. Mandatory export exclusions

The final packaged project MUST contain zero paths under:

- `coordination/**`
- `docs/**`
- `tests/**`
- `tools/**`
- `level_factory/**`
- `content_pipeline/**`
- `assets/art/references/**`
- `assets/ui/candidates/**`
- `assets/ui/generated/**`

Current decision-time inventory is ~1816.43 MiB / 3,941 tracked files.

The audit must inspect the actual export/PCK contents, not just export preset text.

Any forbidden packaged path = **FAIL / EXPORT_FILTER_LEAK**.

## 4. Candidate/generated authority

PASS only if:
- `assets/ui/final/**` remains production authority;
- Standard/Premium shipping pack frame paths remain under `assets/ui/final/rewards/pack_opening/**`;
- no shipping dependency is silently redirected to candidates/generated;
- exclusions do not break production runtime.

The root manifest's raw_generated / production_final distinction must remain intact.

## 5. Runtime content preserved

PASS requires:
- built-in Levels 1–10 still load via production catalog/loader;
- Home/Play/Results production path preserved;
- required final UI, gameplay art, data, audio/fonts/branding/runtime addons remain;
- no fixture-only substitute;
- no broad dev-tree re-inclusion to hide one missing dependency.

If a shipping dependency actually points into an excluded tree, verdict is `CHANGES_REQUIRED` or precise blocked state until corrected.

## 6. Offline behavior

- CP04/CP05 semantics unchanged;
- no valid remote endpoint => built-in 1–10 boots/plays;
- no mandatory network/login;
- no fabricated R2 manifest/packs;
- no R2 writer secret.

## 7. Package size/evidence

Builder log must state:
- APK size;
- inspection PCK/equivalent size;
- forbidden packaged path count = 0;
- source SHA;
- export preset/filter;
- artifact SHA-256.

The audit should reject an unexpectedly huge APK until contents are explained.

## 8. Android metadata

Verify:
- debug signing;
- dev package id;
- version code/name;
- portrait;
- architecture(s);
- icon/splash source;
- APK binary validity.

## 9. Regression

Required appropriate checks:
- import/parse;
- Levels 1–10;
- app Home->Play->Results smoke/fixture;
- offline/save relevant checks;
- current root/release subset;
- `git diff --check`.

First-run failures disclosed.

## 10. Scope

Excluded from this first APK gate:
- 150 real PNG full solve;
- LF R05 strict closure;
- production R2 publish;
- remote Levels 11–50 acceptance;
- all later M47 device/perf rows;
- store release.

Possible verdicts:
- `FIRST10_APK_TECHNICAL_PASS / FAMILY_DEVICE_INSTALL_PENDING`
- `CHANGES_REQUIRED`
- precise `BLOCKED_*`.

Never infer successful family installation from CI build alone.
