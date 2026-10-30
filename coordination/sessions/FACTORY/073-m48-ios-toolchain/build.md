STATUS: READY

# Build: iOS toolchain documentation and config verification (SB-M48-002..003) plus Android-device queue rows

## Summary
Docs + TASKS.md only (commit `0614ccd7` on `factory/073-m48-ios-toolchain`). No workflow or code change: reading the inline iOS preset in `ios-ipa.yml` against the Godot 4.7 iOS export options turned up no defect.
- `docs/IOS_TOOLCHAIN.md` (new): macos-latest runner, preinstalled Xcode/xcodebuild, Godot 4.7.2 macOS + same-version export templates, inline preset table, config-review result, unsigned-IPA policy, xtool install via `Iphone_Yukle_Guncel.bat` (Apple Devices app, WSL bridge 127.0.0.1:27015, NOPAUSE=1), credentials policy, run-ID evidence + `gh run list --workflow ios-ipa.yml`.
- `docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md`: the "iOS readiness (SB-M42-033)" section now says the CI preset exists, the IPA builds unsigned and its pack scans and boots headless. It adds a "Pack boot" row and keeps physical iPhone playback as IOS_DEVICE_LATER (not verified).
- `AGENTS.md`: one pointer line to `docs/IOS_TOOLCHAIN.md` (next to the TESTING_CONVENTIONS reference).
- `TASKS.md`: SB-M48-002, SB-M48-003, SB-M42-033 body lines `[x]` with evidence. The SB-M48-002..003 queue row is removed. SB-M42-032..033 is split into an OWNER SB-M42-032 row. SB-M47-005..010 and SB-M47-011..015 are set to OWNER with the A10 suffix. CRLF is kept.

## Acceptance criteria
1. [x] IOS_TOOLCHAIN.md content: `grep -c` gives macos-latest 1, 4.7.2 3, "export templates" 1, xtool 2, Iphone_Yukle_Guncel.bat 1, 41114924279 2, "Signing happens at install time" 1, "no iOS signing secrets" 1.
2. [x] `grep -n "SB-M48-002\|SB-M48-003\|SB-M42-033" TASKS.md`: lines 1077, 1526, 1527 are `[x]` with evidence (doc path, run IDs, labels DOC_DONE / CONFIG_REVIEWED / STATIC_READINESS_DONE, factory 073). The only other hits are the historical audit-path line 1055 and no queue row.
3. [x] Queue block: three `OWNER` rows (SB-M42-032, SB-M47-005..010, SB-M47-011..015), each ending "(waits for the Galaxy A10 to be plugged in; see Questions SB-M34-006)". No `READY SB-M47-0` / `READY SB-M42-03` rows remain.
4. [x] `git diff -U0 TASKS.md | grep '^+' | grep -c "Questions for"` = 0. The diff touches only the 4 queue lines and 3 body lines; Questions section unchanged.
5. [x] The OPENING doc no longer states the missing preset as fact (the Export preset row now describes the inline CI preset). It still says physical cinematic playback on the iPhone has **not** been verified (IOS_DEVICE_LATER).
6. [x] `gh run view 41114924279 --json conclusion -q .conclusion` = `success` (also 41080595559 and 41070827156 = success). The workflow was not edited, so no new run is needed.
7. [x] `git diff --check` / `git diff --cached --check` are clean. No code or test changes.

## Validation
- `git diff --check` on the changed files: clean.
- `gh run view` on the three cited runs: success. `gh run list --workflow ios-ipa.yml` lists them plus 38063217668 and 38050197093 (success).
- No Godot suites run: no code or config touched.
- Note: the worktree still has untracked/modified `.import` / `.uid` / `project.godot` churn left by the import step. It was deliberately not committed (per instructions), so `git status --porcelain` is not empty for those paths only.

## Log
### Round 1
- Read the spec, `ios-ipa.yml`, the OPENING doc, AGENTS.md and the TASKS.md queue and rows. Checked the run conclusions with gh and grepped the 41114924279 log for signing and icon warnings: none relevant ("Ignoring --strip-bitcode because --sign was not passed" is expected for an unsigned build).
- Config review: the required `icons/icon_1024x1024`, bundle id and export_project_only are set. The legacy per-size icon keys are ignored by Godot 4.3+, so they are harmless and left as is. The placeholder team id is benign. No defect, workflow unchanged.
- Wrote the docs and TASKS edits, committed `0614ccd7`. CLAUDE_PEER_REVIEW not claimed (pending factory review).
