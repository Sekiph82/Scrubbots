# M47-FAMILY-APK-C001 — ChatGPT Independent Audit V01
Date: 2026-10-10
Repo: Sekiph82/Scrubbots
Scope: SB-M47-001 / SB-M47-002, **limited offline built-in Levels 1–10 Android debug APK only**.
Result: **FIRST10_APK_TECHNICAL_PASS / FAMILY_DEVICE_INSTALL_PENDING**.

## Authority and reviewed evidence
- `CLAUDE.md`, `TASKS.md`, `coordination/AUDIT_POLICY.md`.
- Owner decision: `OWNER_EXPORT_HYGIENE_V01.md`.
- Implementation prompt + strict criteria: `M47_FAMILY_APK_C001_OFFLINE_FIRST10_MASTER_PROMPT_V02.md`, `M47_FAMILY_APK_C001_OFFLINE_FIRST10_AUDIT_CRITERIA_V02.md`.
- Implementer evidence: `M47_FAMILY_APK_C001_CLAUDE_LOG_V02.md`.
- GitHub compare `21312a2fa8a8676b9e3e8e5ed4f4ab82bc717939...857d90330247561bc4bfe8a548cca2f42e7eba55`: exactly two build-implementation commits; six new files, limited to `.github/android/**` and `.github/workflows/android-family-first10.yml`. No gameplay, scenes, assets, remote runtime, root `TASKS.md` or existing project settings modified by the two commits.
- Direct GitHub Actions API inspection of run **38040561355**: validate job **114179793146 = success**, export job **114180934094 = success**. Read both job logs, not merely implementer prose.
- Direct GitHub Actions artifact listing: APK artifact **11666135912**, inspection artifact **11666325754**, validation logs artifact **11666455306**. All reported unexpired as of audit; expiry **2026-11-09**.
- Build source SHA: **857d90330247561bc4bfe8a548cca2f42e7eba55**. Builder log committed later at `0692b463`, as distinct evidence.

## Independent static and CI-log cross-checks
1. **Real signed debug APK exists in GitHub Actions.** CI log records `file` identifying an Android APK with `classes.dex`, `unzip -tq` clean, `apksigner verify` = Verifies, `aapt2` dev package/version/arm64/portrait properties. APK **513,559,541 bytes**; log SHA-256 **496509477f38841879ea36e87a0ad5a5ac75f4615f70abc8fb96af288839c75d**. This SHA is independently cross-checked against the CI job log, **not independently recomputed from downloaded APK bytes**.
2. **Pack inspection:** direct export-job logs: `PCK_SCAN mounted=true sees_pack=true files=1980 forbidden=0 required=663 missing=0 main_scene=true verdict=PASS`; `APK_SCAN forbidden_total=0`. Same-preset PCK **483,056,924 bytes**, logged SHA-256 **06bef1abe872ff5c5e82541c15f24efe5a86d5e3a2c5fdf58e77eb42b8f5febf**. All nine owner-forbidden trees absent from the disposable export sparse checkout, redundantly listed in the preset and inspected by the machine probe. `assets/ui/final/**` retained; no source trees deleted.
3. **Validation:** direct validate-job logs confirm `m55_long_session` passed in CI; Phase4 Home/Results 19/19, CP04 28/28, CP05 15/15 and root `run_tests` ALL PASS; all 13 CI commands returned exit 0. Local developer validation disclosed a **3/3 failing race in M55 HOME feel-quiescence sampling**; CI passing does not invalidate the local failures. This is separated into a narrowly scoped follow-up; no game production changes were made for it.
4. **Offline scope:** tracked config and export preset show no configured remote manifest, no INTERNET permission, and no writer secrets. This APK deliberately cannot download R2 level updates; it is **not** the later online family-update APK. Built-in Levels 1–10 only.
5. **Size:** 490 MiB APK / 461 MiB PCK is large but attributable to retained owner-approved production art (~443 MiB imported) and opening video; the ~1.8 GiB of excluded developer evidence/source material is not in the pack. No lossy re-import authorized.
6. **Safety:** builder log records Desktop fast-forward to GitHub at 0/0, preserving four dirty tracked files, 2,616 untracked files and two stashes. `project.godot` owner-local SHA unchanged; no local Java/Android SDK install. Desktop safety is log-backed **E2**, not independently accessible to this audit.

## Known limits / follow-ups (not permission to alter production scope)
- **Real-device installation, touch, portrait/safe-area, performance, save/relaunch on device:** not performed. SB-M47-003+ remain open. Family download: https://github.com/Sekiph82/Scrubbots/actions/runs/38040561355/artifacts/11666135912 (GitHub wraps the APK in ZIP; extract APK first).
- Each run creates a new debug signing certificate. An older `com.sekiph82.scrubbots.familydev` build signed by another run must be uninstalled before upgrading (device-local save data can be lost on uninstall; treat as a test-only package).
- The project has **no configured custom splash image**; current colored default was used. This is disclosed, not represented as approved splash artwork.
- `assets/ui/final/gameplay/buttons/icon_pause.png` is reportedly corrupt but unreferenced, not exported, and is a separate art-maintenance candidate, **not authorization for cleanup now**.
- Current CI's `--import ... || true` and headless-boot `timeout ... || true` mask their exit status. Focused suites and missing-resource scan remain separate gates. For a later CI hardening task, preserve and check boot/import exit status explicitly; do not block the current offline APK solely on this design debt.
- **Independent E3 scope:** inspected GitHub source/compare/CI job logs and live artifact metadata. Did not fetch ~500 MB artifact, run Android emulator, recompute binary hashes, or perform device install. No claim of end-to-end Android user experience or remote R2.

## Disposition
- SB-M47-001 Android export setup: **PASS / CLOSED for offline-first10 development slice**.
- SB-M47-002 development APK: **PASS / CLOSED for offline-first10 development slice**, artifact obtainable until 2026-11-09.
- **SB-M47-003 / FAMILY_DEVICE_INSTALL_PENDING.** Owner to install and test a real compatible arm64 Android device; do not merge this limited offline result with production online family readiness.
- Independently register M55 feel-quiescence follow-up as **OPEN / CLAUDE IMPLEMENTATION**. Keep previously audited Phase4 product F010/F012 closed; do not weaken M55 strict leak rules.
- Primary R2 publish → live endpoint binding → full online Family update chain remains OPEN and unchanged by this audit.
