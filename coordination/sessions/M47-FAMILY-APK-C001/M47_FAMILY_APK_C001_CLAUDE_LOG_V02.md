# M47-FAMILY-APK-C001 — First 10 Levels Android Family Debug APK — CLAUDE_LOG_V02

- Prompt: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_OFFLINE_FIRST10_MASTER_PROMPT_V02.md`
- Criteria: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_OFFLINE_FIRST10_AUDIT_CRITERIA_V02.md`
- Hygiene authority: `coordination/sessions/M47-FAMILY-APK-C001/OWNER_EXPORT_HYGIENE_V01.md`
- Tasks: `SB-M47-001` / `SB-M47-002` (offline-first ten Family slice only)
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `21312a2fa8a8676b9e3e8e5ed4f4ab82bc717939`
- Implementation commits:
  - `f66c3021` — workflow + `.github/android/`
  - `857d9033` — pipeline fix after first-run failure (§7)
- **Built / tested source SHA: `857d90330247561bc4bfe8a548cca2f42e7eba55`**
- This log is pushed in a separate later commit.
- No production script, scene, data, asset, `project.godot` or `TASKS.md` change.

## Stop state: `APK_ARTIFACT_READY_FOR_INDEPENDENT_AUDIT`

| Item | Value |
|---|---|
| Workflow run | https://github.com/Sekiph82/Scrubbots/actions/runs/38040561355 (run #2, `workflow_dispatch`, both jobs green) |
| APK artifact | `ScrubBots-Family-First10-Android-Debug.apk`, artifact id `11666135912`: https://github.com/Sekiph82/Scrubbots/actions/runs/38040561355/artifacts/11666135912 |
| Artifact form | GitHub wraps the APK in a ZIP when you download it (wrapped size 507,859,999 bytes). Unzip it to get the `.apk`. |
| Retention | 30 days (GitHub expiry 2026-11-09T09:22Z) |
| APK SHA-256 | `496509477f38841879ea36e87a0ad5a5ac75f4615f70abc8fb96af288839c75d` |
| APK size | 513,559,541 bytes |
| Inspection PCK (same preset) | `ScrubBots-Family-First10-Android-Debug.pck`, 483,056,924 bytes, SHA-256 `06bef1abe872ff5c5e82541c15f24efe5a86d5e3a2c5fdf58e77eb42b8f5febf`, in artifact `ScrubBots-Family-First10-Android-Debug-inspection` (id `11666325754`, with all scan reports) |
| Validation logs | artifact `ScrubBots-Family-First10-Android-Debug-validation-logs` (id `11666455306`) |
| Forbidden packaged paths | **0** in the PCK and **0** in the APK |

**Real-device install is OWNER/DEVICE PENDING.** A CI build is not proof that the app works on a family device.

## 0. Gate 0 — persistent Desktop sync

| Item | Value |
|---|---|
| Desktop HEAD at start | `3e7c4655` |
| `origin/main` after `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` | `21312a2f` |
| Ahead / behind | 0 / 4 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked / stashes / worktrees | 2616 / 2 (untouched) / 5 incl. Desktop (untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Reconcile:
- The incoming commits were TASKS / M47 docs only. `git merge --ff-only` → `21312a2f`, **0/0**.
- Nothing was stashed, reset, cleaned, restored or forced, and the hash was unchanged.

Work worktrees (all under the session scratchpad, all created after Gate 0, all removed at the end):
1. **Implementation / validation:** a sparse worktree without `coordination/sessions/`, `assets/art/references/`, `assets/ui/candidates/` or `assets/ui/generated/`.
2. **Local export dry run:** a sparse worktree with all 9 excluded trees absent.
3. **Log only:** a minimal sparse worktree containing just this session folder.

Every command used an absolute `git -C` / `godot --path` path.
- `--import` rewrote the TEMP `project.godot`, so that copy was restored with `git -C "<TEMP>" checkout -- project.godot`. That command never ran against the Desktop.
- **Disclosed tool issue.** Git Bash (MSYS) rewrote `!/coordination/` into `!C:/Program Files/Git/coordination/` in my first `sparse-checkout set`, so the trees were still present. I caught it with an explicit presence check and reapplied with `MSYS_NO_PATHCONV=1`. In CI the patterns come from YAML and are not rewritten.
- **Disclosed process slip.** My first attempt to commit this log ran inside worktree 1, whose sparse definition excludes `coordination/sessions/`, so `git add` refused the file. The chained cleanup then force-removed that worktree and the uncommitted log with it. I recreated the log verbatim in worktree 3 and committed it from there. No pushed or owner content was affected; the Desktop was already synced at that point.

## 1. Toolchain

- **Local:** Godot 4.7.2 and Windows export templates are present; there is **no Java and no Android SDK / adb**. Per the prompt I installed nothing on the owner PC. The APK is assembled by GitHub Actions.
- **Before this task:** there was no tracked `export_presets.cfg`; it is gitignored, as is `export/`. The only workflow was `ios-ipa.yml`, which generates its preset in CI. I reused its Godot download / template install pattern.
- **New workflow** `.github/workflows/android-family-first10.yml`:
  - `workflow_dispatch` only; `permissions: contents: read`; concurrency group;
  - actions pinned to commit SHAs: `actions/checkout` v4 `11d5960a…`, `actions/setup-java` v4 `cf277c60…`, `actions/upload-artifact` v4 `ea165f8d…`;
  - **no secrets**, no metered API, no R2 credential;
  - Godot 4.7.2 Linux editor + official 4.7.2 export templates (GitHub release URLs);
  - Temurin JDK 17; the runner's preinstalled Android SDK (`$ANDROID_HOME`, latest build-tools for `apksigner` / `aapt2`).
- **Signing:** **debug only.** A fresh RSA-2048 debug keystore is generated by `keytool` inside the job, with the standard debug alias / password `androiddebugkey` / `android`. It is never committed and never uploaded.
  - **Consequence:** every workflow run signs with a different debug certificate. To replace an installed Family build with a newer run's APK, **uninstall the old one first**.

## 2. Export preset and filter (exact)

Tracked template `.github/android/export_presets_family_first10.cfg`, copied to `export_presets.cfg` by the job. `@VERSION_CODE@` = `github.run_number` and `@VERSION_NAME@` = `0.1.<run>-family-first10-dev`.
- `export_filter="all_resources"`
- `exclude_filter="coordination/*, docs/*, tests/*, tools/*, level_factory/*, content_pipeline/*, assets/art/references/*, assets/ui/candidates/*, assets/ui/generated/*, .github/*"`
- `package/unique_name="com.sekiph82.scrubbots.familydev"` (dev id, cannot collide with a production id); `package/name="ScrubBots Family Dev"`
- `architectures/arm64-v8a=true`; armeabi-v7a, x86 and x86_64 all `false`
- `gradle_build/use_gradle_build=false` (standard template APK); `package/signed=true`; `permissions/internet=false` (offline; see §4)
- Launcher icons from production branding:
  - `launcher_icons/main_192x192` → `res://assets/ui/final/branding/app_icon_master.png`
  - adaptive foreground / background → `res://assets/ui/final/branding/app_icon_android_foreground.png` / `app_icon_android_background.png`
- Orientation comes from the unchanged `project.godot` setting `window/handheld/orientation=1` (portrait). The APK manifest shows `screenOrientation=1`.

### Exact excluded prefixes and the mechanism

`.github/android/family_first10_export_exclusions.txt` is the machine-readable list, used verbatim by the workflow:

```
coordination
docs
tests
tools
level_factory
content_pipeline
assets/art/references
assets/ui/candidates
assets/ui/generated
```

Three independent layers:
1. **Disposable export workspace.** The export job's `actions/checkout` uses `filter: blob:none` and a non-cone sparse checkout with `!/<tree>/` for all nine. A step then **asserts each tree is absent** (log: `absent: coordination` … `absent: assets/ui/generated`). Godot never imports any of them, and the 1.68 GiB of evidence is not even downloaded.
2. **Preset `exclude_filter`** with the same prefixes (defence in depth).
3. **Scans of the actual exported artifacts** (§3).

`.github/android/` carries a `.gdignore`, so the probe and template are never imported or packaged.

### Excluded inventory now (tracked files at `21312a2f`)

| Tree | Files | MiB |
|---|---|---|
| `coordination/` | 3,217 | 1,681.03 |
| `docs/` | 28 | 0.42 |
| `tests/` | 326 | 3.88 |
| `tools/` | 26 | 0.23 |
| `level_factory/` | 18 | 0.03 |
| `content_pipeline/` | 19 | 0.02 |
| `assets/art/references/` | 61 | 29.72 |
| `assets/ui/candidates/` | 27 | 38.76 |
| `assets/ui/generated/` | 222 | 63.10 |
| **Total** | **3,944** | **~1,817.19** |

The decision-time baseline was 3,941 files / 1,816.43 MiB; the drift comes from new coordination docs.

## 3. Package scans of what was ACTUALLY exported

### 3.1 PCK

The probe is `.github/android/pck_probe/`: a separate tiny Godot project, not the game.
- `ProjectSettings.load_resource_pack(<exported .pck>)` mounts the pack.
- `res://` is walked recursively, including hidden `.godot/`.
- Excluded prefixes come from the list file.
- It fails if any packaged path is under an excluded prefix, if the walk does not see the pack (`res://project.binary` must be present), if the main scene is absent, or if any required runtime path is missing.

The **required list** is generated in the job: every `res://<file>.<ext>` literal in shipping `scripts/`, `scenes/`, `data/`, `addons/`, `project.godot` and `default_bus_layout.tres` that exists as a file in the export source tree. That gives 663 paths. Each must be in the pack as the file itself or its exported `.import` / `.remap` entry.

The only exclusion is editor-only `addons/*/plugin.cfg`, named solely by `project.godot [editor_plugins]`. The runtime autoloads are the `.gd` scripts, which are present.

**CI result (run 38040561355):** `PCK_SCAN mounted=true sees_pack=true files=1980 forbidden=0 required=663 missing=0 main_scene=true verdict=PASS`

### 3.2 APK

`unzip -Z1` of the signed APK gives 1,980 `assets/` entries (the same 1,980 project files) and no embedded `.pck`.
- `apk entries under <prefix>/` = **0** for each of the 9 prefixes.
- `APK_SCAN forbidden_total=0`.

### 3.3 Runtime presence

- **663/663** runtime-referenced files are present, including the main scene, every shipping script, the built-in Level 1–10 JSON + art, `assets/ui/final/**` paths reached by Home / gameplay / Results / pack / collection flows, and the `game_feel_flow` / `saltmire_spark` runtime scripts.
- **Shipping pack frames:**
  - they stay under `res://assets/ui/final/rewards/pack_opening/standard|premium/`, and nothing was redirected to candidates or generated;
  - static check: the only runtime-side file that names an excluded tree is `data/config/level_difficulty_analysis_v2_candidate.json`. Its `"derivedFrom": "res://tests/fixtures/difficulty_calibration/corpus_manifest_v1.json"` is provenance text. It is read only by `scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd`, which no shipping script or scene references. **Not a runtime dependency.**
- **Headless boot of the exported pack** (`godot --headless --main-pack <pck> --quit-after 600` from an empty directory, no project, no endpoint):
  - clean in CI and in a local dry run;
  - output is only Game Feel Flow init plus the standard engine exit notices (`59 ObjectDB instances leaked at exit`, `29 resources still in use at exit`, identical to every dev run);
  - zero `SCRIPT ERROR`, `Parse Error`, `Failed loading resource`, `Cannot open file` or `Resource file not found`.
  - The local dry-run boot wrote only Godot's `logs` folder in the user-data directory. No game save was created or modified.

### 3.4 Size report and why 460 MiB is legitimate

| Measure | Value |
|---|---|
| APK | 513,559,541 B (~489.8 MiB) |
| Inspection PCK | 483,056,924 B (~460.7 MiB) |
| Packaged files | 1,980 |
| `.godot/imported/` | 677 files, **~443.5 MiB** (imported textures / audio) |
| `assets/` raw (opening video etc.) | ~15.5 MiB; largest single file `res://assets/brand/opening/scrubbots_opening_720p30.ogv` 15.3 MiB |
| `scripts/` / `data/` / `addons/` | ~1.0 / 0.3 / 0.2 MiB |
| Shipping source art `assets/ui/final/**` | 586 tracked files, **601.39 MiB** |
| `assets/brand/` | 39.37 MiB |

- The pack is smaller than its shipping source art.
- The largest entries are approved production art imported with Godot's default lossless compression: the 1080×2160 world background (3.5 MiB), the six gameplay shells, the 1254² collection cards, and the robot / help / victory atlases.
- None of it comes from an excluded tree.
- Shrinking further would require lossy / VRAM import settings, i.e. a visual-quality decision for the owner, so it is **not done here**.
- No unfiltered export was produced for comparison. It would have been multi-GB, and the prompt says not to create one just to compare.
- APK vs PCK: the APK also carries `libgodot_android.so` (arm64), dex, manifest / resources and signature blocks.

## 4. Offline Family v0 behaviour

- `data/config/remote_content_runtime_v1.json` at the built SHA has `"enabled": false`, `"manifest_url": ""`, `"object_base_url": ""`. There is **no production endpoint**, so CP04 `_start_remote_content()` creates no transport and the app runs on built-in content.
- The APK has **no INTERNET permission**. No R2 key, no manifest, no publisher or writer secret.
- No fake test mode: the APK's main scene is the production `res://scenes/app/main.tscn` (Home → AppState → LevelCatalog / LevelLoader → supply → gameplay).
- CP04 / CP05 semantics are unchanged; both suites pass (§5).
- Ads / billing / reward providers are untouched; the existing truthful provider-absent behaviour ships as-is.

## 5. Validation

### 5.1 CI validate job (run 38040561355, job `114179793146`, 6 m 39 s)

Real Godot 4.7.2 headless on a checkout without `coordination/sessions/` and the three dev-art trees:

| Suite | Result |
|---|---|
| `m35_level_catalog` | PASS (built-in catalog / Levels 1–10 load) |
| `m37_level_progression` | PASS |
| `m55_long_session` | PASS (Levels 1–10 back-to-back through Home → Gameplay → Results → Continue, ×2 laps) |
| `m43_c005f_phase4_terminal_home_micro` | PASS 19/19 (Level 1 played to a real WON through Home → Play → Results → Home) |
| `m43_c001a_results_foundation` | PASS 11/11 |
| `m42_navigation` / `m42_home` | PASS / PASS |
| `m40_save_system` / `m40_v04_bootstrap` | PASS / PASS (save, relaunch / bootstrap) |
| `cp04_remote_content_runtime` / `cp05_remote_content_cache` | PASS 28/28 / PASS 15/15 (offline fallback, no endpoint) |
| `m55_economy_release_regression` | PASS |
| `run_tests` (root) | RESULT: ALL PASS |

Run 1 (38040015089) validate also passed all 13.

### 5.2 Local (same 13 suites, sparse TEMP worktree)

- **12/13 PASS.**
- `git diff --check` is clean on both implementation commits.

**Disclosed: local `m55_long_session` FAIL (2), 3 out of 3 local runs.**
- Each time the failing check was my QA-R01 assertion `feel quiescent at the HOME sample`.
  - The quiescence wait saw 0 adapter-owned decorations after ~15–24 ms, so it stopped.
  - The Home ceremony's REWARD burst then started during the next 2 settle frames. MetaRewardFeel requests only after its own layout-settle wait (≤ 8 frames), which is not adapter-owned yet. The one-off 35th Node in the warm-up sample is that burst's emitter.
- The steady-state rule still held: lap 2 vs lap 1 nodes +0, orphans +0, objects +54.
- The same test **PASSED in both CI runs** and passed 3/3 + battery in QA-R01 and in the Phase 5 battery.
- No runtime code or test changed between Phase 5 and this build (`git log 6279ed2f..21312a2f` shows docs / iOS-workflow commits only).
- So this is a **timing-dependent race in the QA-R01 quiescence condition**, not an M47 effect.
  - Robust fix: require `owned_count() == 0` for more than `SETTLE_FRAMES` consecutive frames before sampling.
  - That is a test-only change to an audited QA-R01 file, so it is proposed as a separate follow-up, not changed under M47.

## 6. APK binary / metadata (from the CI job)

- `file`: `Android package (APK), with classes.dex`. `unzip -t`: `No errors detected`.
- `apksigner verify --verbose --print-certs`: **Verifies**; v2 = true, v3 = true; 1 signer (the CI-generated debug key, `CN=ScrubBots Family Debug`).
- `aapt2 dump badging`:
  - `package: name='com.sekiph82.scrubbots.familydev' versionCode='2' versionName='0.1.2-family-first10-dev'`;
  - compile / target SDK 36;
  - `application-label:'ScrubBots Family Dev'`;
  - `native-code: 'arm64-v8a'`.
- Manifest: `screenOrientation=1` (portrait), `debuggable=true`.
- ABIs packaged: `arm64-v8a` only.
- Icon: production `assets/ui/final/branding/*`.
- **Splash:** `project.godot` defines only `boot_splash/bg_color`, with no splash image. I did **not** change `project.godot`: the owner Desktop has local uncommitted edits to it, and a pushed change would block the non-destructive fast-forward. So the APK uses the project's existing splash configuration. An approved splash image is an owner follow-up if wanted.

## 7. Failures and risks (disclosed)

1. **CI run 1 (38040015089) failed** at the PCK-scan step.
   - The required-list shell pipeline ended in `[ -f … ] && echo`, which returns 1 for the last non-file literal and aborted under `bash -e -o pipefail`.
   - It was a script bug, not a scan finding: that run had already exported both artifacts and passed validation.
   - Fixed in `857d9033` with an explicit `if`. Run 2 is green.
2. **Local `m55_long_session` quiescence race** (§5.2): pre-existing QA-R01 test-timing issue, follow-up proposed.
3. **Pre-existing asset defect, not a runtime dependency.** `assets/ui/final/gameplay/buttons/icon_pause.png` fails to import (`ERR_FILE_CORRUPT`) locally and in CI. No shipping script, scene or data references it (the pause glyph is drawn natively), and it is absent from the 663 required paths. It is simply not exported. Worth an owner / art follow-up.
4. **Size ~490 MiB.** Fully explained by approved production art (§3.4). It is fine for sideloading but large for store distribution, where texture compression would be an owner decision.
5. **Per-run debug certificates** (§1): uninstall the previous Family build before installing a newer run's APK.
6. **Deprecation notes from GitHub:**
   - actions running on Node 20 are being forced to Node 24;
   - `setup-java@v4` is deprecated in favour of v5;
   - `ubuntu-latest` migrates to Ubuntu 26 on 2026-10-19.

   None affected this run, but these are maintenance follow-ups.
7. **Real-device install, touch feel, performance and storage on family phones are UNVERIFIED** until the owner installs.

## 8. Source control and Desktop sync

- `f66c3021` and `857d9033` touch only:
  - `.github/workflows/android-family-first10.yml`
  - `.github/android/{.gdignore, family_first10_export_exclusions.txt, export_presets_family_first10.cfg, pck_probe/project.godot, pck_probe/pck_scan.gd}`
- This log follows in a separate commit.
- The final Desktop sync proof (HEAD == `origin/main`, 0/0, owner `project.godot` hash unchanged, owner files preserved) is in the hand-off message, because this log cannot contain its own commit.
- I did not mark M47-001 / 002 complete.

Final state: `APK_ARTIFACT_READY_FOR_INDEPENDENT_AUDIT`
