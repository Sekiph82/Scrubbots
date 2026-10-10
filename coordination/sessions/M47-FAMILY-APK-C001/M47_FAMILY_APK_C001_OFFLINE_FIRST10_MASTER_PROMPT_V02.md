# M47-FAMILY-APK-C001 — First 10 Levels Android Family Development APK — MASTER PROMPT V02

Repository: `Sekiph82/Scrubbots`
Task IDs: `SB-M47-001` + `SB-M47-002` (targeted early family-test slice).
Implementer: CLAUDE. Audit authority: ChatGPT; root `TASKS.md` progress writes belong to ChatGPT alone.
Independent audit: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_OFFLINE_FIRST10_AUDIT_CRITERIA_V02.md`.
Owner export hygiene authority: `coordination/sessions/M47-FAMILY-APK-C001/OWNER_EXPORT_HYGIENE_V01.md`.

**V02 supersedes V01 for execution.**

## Goal / priority

Deliver an **installable Android debug/development APK** for family testing of the already accepted built-in ScrubBots Levels 1–10 as soon as possible.

Do not wait for Level Factory R05, 150-PNG batch solver verification, Cloudflare R2 publisher/prod manifest, M43 cosmetic work, M59 release polish, real 59×59 stress, or all M47 device/performance tasks.

The offline-first ten APK is a separate limited test variant. It is NOT proof that remote Level 11–50 updates work or that production release is ready.

A second equally important goal is **package hygiene**: the APK must not contain the repo's multi-GB coordination/evidence/source-art payload.

---

# STAGE 0 — SAFE SYNC

Non-destructively sync persistent Desktop:

`C:\Users\sekip\Desktop\ScrubBots`

to exact current `origin/main`.

Record:
- HEAD
- origin/main
- ahead/behind
- dirty tracked files
- untracked count
- stashes/worktrees
- SHA-256 of owner `project.godot`.

Preserve all owner-local work.

Never run against persistent Desktop:
- `git checkout -- <file>`
- `git restore <file>`
- `git reset --hard`
- `git clean`
- destructive stash/pop
- force checkout/rebase/push.

If implementation isolation is needed, use a bounded TEMP worktree only after Gate 0 and use absolute paths.

Do not edit root `TASKS.md` or any `CHATGPT_*AUDIT*` file.

---

# STAGE 1 — INSPECT EXPORT TOOLCHAIN

1. Inspect current Godot project/version, Android export template compatibility, Android SDK/JDK/adb availability, current workflows and any export preset.
2. At V02 authoring time there is no tracked `export_presets.cfg`; verify current tip rather than assuming.
3. Prefer GitHub Actions for APK assembly if local Android tooling is absent or would consume many GB of owner C: disk.
4. Reuse trusted existing workflow patterns where possible. New actions must be narrowly scoped, trusted/pinned, least privilege, with no metered external API and no hidden product secrets.
5. Debug signing only. Never commit production signing keys/passwords, App Store keys, R2 writer credentials, Android store credentials or other secrets.

---

# STAGE 2 — LOCKED EXPORT HYGIENE

Read:

`coordination/sessions/M47-FAMILY-APK-C001/OWNER_EXPORT_HYGIENE_V01.md`

before creating the export preset/workflow.

## 2.1 Mandatory excluded trees

The Family Android export MUST exclude the complete trees:

- `coordination/**`
- `docs/**`
- `tests/**`
- `tools/**`
- `level_factory/**`
- `content_pipeline/**`
- `assets/art/references/**`
- `assets/ui/candidates/**`
- `assets/ui/generated/**`

These paths remain in Git. This task does NOT delete them.

Current inventory baseline is ~1816 MiB / 3,941 tracked files, so this is a hard acceptance gate.

## 2.2 Production asset authority

Do NOT exclude or replace `assets/ui/final/**`.

The repo itself establishes:
- `assets/ui/generated/` = raw/generated working output;
- `assets/ui/final/` = production final;
- `assets/art/references/` = reference/source art.

Shipping Standard/Premium pack ceremonies load only:

- `res://assets/ui/final/rewards/pack_opening/standard/`
- `res://assets/ui/final/rewards/pack_opening/premium/`

and do not use `assets/ui/candidates/`.

Do not “optimize” by removing required built-in level art, shipping audio, fonts, final UI, scripts, scenes, data or runtime addons.

## 2.3 Export mechanism

Use a valid Godot 4.7.x Android export preset with an explicit export filter/exclusion policy.

Do not rely on assumptions such as “Godot probably ignores that folder”.

The preset/workflow must make the exclusion policy machine-readable and reviewable.

If Godot export-filter semantics do not reliably prevent all forbidden resources from entering the pack, use a **disposable CI export staging workspace** where those trees are absent before final import/export.

Deleting folders inside a disposable GitHub Actions workspace is allowed.

Deleting or cleaning them on the owner's Desktop is forbidden.

## 2.4 CI download/import optimization

Because `coordination/` contains roughly 1.68 GiB tracked content and ~999 PNG/WebP evidence images, do not force Godot to import that evidence merely to build a Family APK.

Preferred CI shape:

1. test/validation checkout as needed;
2. separate final export job or staging tree;
3. final export workspace contains runtime-required files but omits the nine mandatory dev-only trees.

A sparse checkout/staging approach is allowed if it is simpler and reproducible.

Do not exclude `tests/**` before running the tests that this prompt requires. Tests can run in the validation job and be absent from the final export job.

---

# STAGE 3 — OFFLINE FAMILY V0 BEHAVIOR

- Main scene boots through real Home/AppState -> LevelCatalog/LevelLoader -> supply/gameplay.
- Original built-in Levels 1–10 work through production logic.
- No fake test mode.
- CP04/M15 + CP05/M16 remote runtime remains intact.
- If no valid production manifest endpoint is configured, first launch must fail open to built-in content without crash, spinner, mandatory network or login.
- Do not fabricate R2 keys or claim remote packs exist.
- No R2 publisher write secret in APK.
- Portrait touch, Home/Play/Pause/Results and basic save/relaunch path structurally tested.
- Ads/billing/reward provider remains truthful if provider is absent.

---

# STAGE 4 — EXPORT PRESET + PACKAGE IDENTITY

Create/revise the Android debug preset for one portrait Family APK.

Required:
- debug/development identity;
- non-conflicting dev package id where appropriate;
- portrait only;
- reasonable architecture selection, preferably arm64 for family devices unless current project/device evidence requires more;
- approved app icon/splash from production assets;
- legal debug signing;
- no production store credentials.

Do not modify gameplay, LevelData, supply or accepted visual masters for export convenience.

---

# STAGE 5 — VALIDATION BEFORE BUILD

Run focused validation before final export.

At minimum:
- project import/parse;
- Level 1–10 built-in catalog/load;
- actual Home -> Play -> gameplay -> Results path where available in current automated fixtures;
- save/relaunch/offline fallback;
- root/release regression subset appropriate to the current project state;
- `git diff --check`.

Then validate export dependencies after exclusions.

A missing runtime resource caused by the exclusion policy is a BLOCKER, not permission to silently re-include entire dev trees.

If one specific resource from a dev tree is unexpectedly required by shipping, STOP and report the exact runtime dependency. Do not weaken all exclusions to hide the dependency.

---

# STAGE 6 — ACTUAL EXPORT + FORBIDDEN-PATH PROOF

Produce a real non-empty signed debug APK:

`ScrubBots-Family-First10-Android-Debug.apk`

Also produce, using the SAME export preset/filter, an inspection pack such as:

`ScrubBots-Family-First10-Android-Debug.pck`

or another equivalent artifact that allows deterministic listing of packaged `res://` contents.

## 6.1 Required package scan

Machine-scan the exported project pack and prove ZERO packaged paths under:

- `res://coordination/`
- `res://docs/`
- `res://tests/`
- `res://tools/`
- `res://level_factory/`
- `res://content_pipeline/`
- `res://assets/art/references/`
- `res://assets/ui/candidates/`
- `res://assets/ui/generated/`

Do not merely inspect the Git checkout.

The proof must inspect what the export preset actually packages.

A valid approach is an isolated tiny Godot probe project that:
1. loads the exported PCK with `ProjectSettings.load_resource_pack()`;
2. recursively enumerates mounted `res://`;
3. fails if any forbidden prefix exists.

An equivalent deterministic pack-listing method is acceptable.

The scan result must be saved as evidence/log output.

## 6.2 Required runtime presence proof

Also prove that exclusion did NOT remove the production authorities required for this slice.

At minimum verify availability/boot usage of:
- main app scene;
- production scripts;
- built-in Level 1–10 data/art;
- `assets/ui/final/**` assets reached by current Home/gameplay/results/pack flows;
- required runtime addons.

Do not require all 586 final assets to be loaded on one smoke test; prove the relevant production paths and clean boot/import/export.

## 6.3 Size report

Record:
- APK byte size;
- inspection PCK byte size;
- source SHA;
- excluded inventory baseline;
- count of forbidden paths found = **0**.

If practical, compare a deliberately unfiltered inspection export or estimate against the filtered result, but do not create a multi-GB artifact merely for comparison.

---

# STAGE 7 — APK BINARY / METADATA VERIFICATION

Verify actual artifact bytes.

Required:
- APK is not a renamed ZIP/fake placeholder;
- APK signature is valid for debug channel;
- Android package id;
- version name/code;
- architecture(s);
- portrait orientation;
- SHA-256;
- non-zero sensible APK size;
- source commit SHA.

Use available Android/Java tooling in CI.

No claim of real-device success until owner installs it.

---

# STAGE 8 — GITHUB ACTIONS / ARTIFACT DELIVERY

Prefer bounded GitHub Actions artifact delivery.

Artifact name:

`ScrubBots-Family-First10-Android-Debug.apk`

GitHub may wrap it in an artifact ZIP; document that truthfully.

Record:
- workflow run URL;
- artifact URL/name;
- retention period;
- APK SHA-256;
- tested source SHA;
- package/version.

Do not invent a sandbox download link for a GitHub artifact.

Do not upload coordination evidence into the APK.

Builder log stays in Git only and is not part of the exported app.

---

# STAGE 9 — SOURCE CONTROL

Implementation/build workflow first, builder evidence/log separately where practical.

Builder log:

`coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_CLAUDE_LOG_V02.md`

The log must include:
- Gate 0 state;
- exact export preset/filter;
- exact excluded prefixes;
- current excluded inventory size/count;
- package scan proving zero forbidden packaged paths;
- tests;
- workflow run;
- artifact;
- package metadata;
- SHA-256;
- APK/PCK sizes;
- risks/failures;
- final Desktop sync proof.

Do not mark M47-001/002 complete yourself.

After push:
- non-destructively sync persistent Desktop to final `origin/main`;
- HEAD == origin/main;
- ahead/behind 0/0;
- owner `project.godot` hash unchanged;
- preserve owner dirty/untracked/stashes.

---

# STOP STATES

Success only:

`APK_ARTIFACT_READY_FOR_INDEPENDENT_AUDIT`

with:
- real APK;
- real signature/metadata;
- real artifact URL;
- source SHA;
- package scan with zero forbidden prefixes.

Otherwise use a truthful state such as:
- `BLOCKED_ANDROID_EXPORT_TOOLCHAIN`
- `BLOCKED_SIGNING`
- `BLOCKED_CI_ACCESS`
- `BLOCKED_RUNTIME_DEPENDENCY_IN_EXCLUDED_TREE`
- `BLOCKED_EXPORT_FILTER_LEAK`

Do not let Level Factory R05, 150-PNG solve, production R2 or unrelated M43 work become a stop reason for this offline-first-ten APK.
