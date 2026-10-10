# M47-FAMILY-APK-C001 — First 10 Levels Android Family Development APK

Repository: `Sekiph82/Scrubbots`
Task IDs: `SB-M47-001` + `SB-M47-002` (targeted early family-test slice).
Implementer: CLAUDE. Audit authority: ChatGPT; root `TASKS.md` progress writes belong to ChatGPT alone.
Independent audit: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_OFFLINE_FIRST10_AUDIT_CRITERIA_V01.md`.

## Goal / priority
Deliver an **installable Android debug/development APK** for family testing of the already accepted built-in ScrubBots Levels 1–10 as soon as possible. **Do not wait for** Level Factory R05, 150-PNG batch solver verification, Cloudflare R2 publisher/prod manifest, M43 cosmetic work, M59 release polish, real 59×59 stress, or all of M47 device/performance tasks. The offline-first ten APK is a separate, deliberately limited test variant; it is **NOT** proof that remote Level 11–50 updates work or that the production app is ready.

## Stage 0 safe sync
Non-destructively sync Desktop `C:\Users\sekip\Desktop\ScrubBots` with exact `origin/main`; preserve all owner-local edits/assets and other worktree changes. If dirty, make an isolated small TEMP worktree and preserve Desktop. Never reset/clean/stash-drop/force-push. Record HEAD SHA and source paths; avoid multi-GB duplicate project clones. No changes outside this repository. Do not edit root `TASKS.md` or `coordination/**/CHATGPT_*AUDIT*`.

## Stage 1 locate available export tools (without large local installs)
1. Inspect current Godot version/project (currently declared 4.7; owner runtime mentions 4.7.2), Android export template compatibility, Android SDK/JDK/adb availability, `export_presets.cfg` if any, existing actions and artifacts. Do not assume installed build tools or claim APK exists before inspecting.
2. **Prefer remote GitHub Actions for APK assembly** if the local toolchain is missing or would consume many GB of owner C: disk. Reuse trusted/existing project workflow if available. A new narrow action is allowed, pinned to authorized trusted actions, least-privilege repository permissions, no external metered API and no hidden secrets. Keep artifacts bounded, don't cache multi-GB test trees on owner disk. If action minutes or artifact sizes imply unusual cost, report and stop before costly execution.
3. Configure the Android **debug** export for a single portrait-oriented APK suitable for direct sideload to consenting family devices. Set unique non-conflicting dev package/app label where feasible, landscape disabled, reasonable architecture support (e.g. arm64), launch icon/splash consistent with existing approved project assets. Do not alter gameplay/canonical LevelData/supply or accepted visual masters for export convenience.
4. Debug signing must be legal and reproducible for this test channel. Never commit signing private keys, keystore passwords, write credentials, Android access tokens, or R2 secrets. Do not require production Play Store publishing credentials. If signing cannot be achieved safely, report explicit blocked gate instead of a misleading finished APK.

## Stage 2 offline-only Family v0 behavior
- Main scene boots and original first ten campaign levels work through the **real** Home/AppState -> LevelCatalog/LevelLoader -> supply/gameplay pipeline; no fake/test mode that bypasses production logic.
- Existing CP04/M15 + CP05/M16 remote runtime remains intact. When a valid production manifest endpoint is not configured, offline first-launch must fail open to built-in content, **without runtime crash/spinner/mandatory network/login**. Do not fabricate or silently hard-code an R2 manifest key or assume the bucket contains production packs. Do not ship any R2 publisher write secret.
- Portrait touch input, navigable Home/Play/Pause/Results and basic save/relaunch offline path must be structurally tested. Android-specific smoke/device acceptance can remain OPEN until family actually installs.
- Keep ad/provider/payments functionality truthfully disabled/placeholder if provider not configured; no accidental paid billing or reward grants.

## Stage 3 bounded validation/build
- Use small focused Godot import/parse, relevant Level 1–10 gameplay fixture regression, Android export preflight and an actual export producing a real non-empty `.apk` file. Check the binary signature and package metadata using available local/CI tools, plus SHA-256 and actual artifact bytes. No pretend APK or zip renamed APK.
- Output a named artifact `ScrubBots-Family-First10-Android-Debug.apk` as a GitHub Actions artifact, release asset or bounded owner-accessible build artifact with actual downloadable browser link and SHA-256. GitHub Actions artifact download may arrive as a ZIP containing the APK; document that precisely. Include tested source SHA and Android app id/version code. For CI artifacts, give a direct run/artifact URL and retention period; do not invent a sandbox link.
- Do NOT require real Cloudflare R2 publish or 150 PNG full solve in this FIRST-TEN build gate.
- Preserve exact-current gameplay integrity; root regression where practical, report deviations. Keep all new test scratch scoped to unique owned paths and clean normally permitted disposable output after completion. Never bypass previously denied filesystem deletion; if local scratch cleanup is impossible, prefer isolated remote CI workspace rather than another endless disk-accounting forensics task.

## Stage 4 delivery
- First commit implementation/build workflow then builder evidence and log separately; normal safe fast-forward push. Do not mark M47-001 or M47-002 completed yourself.
- Create a builder log in this folder `M47_FAMILY_APK_C001_CLAUDE_LOG.md` containing exact commands, tests, source SHA, build run link, artifact link, package metadata, APK SHA-256, and risks/failure state. Do not alter GitHub R2 or product manifest.
- Return **only the GitHub URL of the builder log** to the owner for independent ChatGPT audit; the owner should then receive the APK artifact link.

Stop states: `APK_ARTIFACT_READY_FOR_INDEPENDENT_AUDIT` only with a real exported signed debug APK and evidence. Otherwise `BLOCKED_ANDROID_EXPORT_TOOLCHAIN`, `BLOCKED_SIGNING`, `BLOCKED_CI_ACCESS` or specific truthful gate and the exact next necessary action. Do not let Level Factory R05 or unrelated M43 work become a stop reason.
