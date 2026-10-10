# M47-FAMILY-APK-IOS-EXPORT-R02-PUBLISH-C001 — CLAUDE_PUBLISH_CLEANUP_LOG_V01

- Prompt: `coordination/sessions/M47-FAMILY-APK-IOS-EXPORT-R02/CHATGPT_PUBLISH_CLEANUP_PROMPT_V01.md`. This owner supersession authorizes publishing the R02 TEMP workflow change and removing the two R02 scratch worktrees.
- **No GitHub Actions dispatch, no IPA, no APK.** The latest runs are still iOS 38063217668 and Android 38063215568, unchanged.
- Root `TASKS.md` and ChatGPT audit files were not edited.

Status: **AWAITING_CHATGPT_INDEPENDENT_AUDIT**

## 1. Gate 0 (owner Desktop `C:\Users\sekip\Desktop\ScrubBots`)

| Item | Value |
|---|---|
| Desktop HEAD | `e8c9429e` |
| `origin/main` after fetch | `61827343` |
| Ahead / behind | 0 / 5 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` (4) |
| Untracked | 2616 |
| Stashes | 2 |
| Worktrees | 7 (Desktop, 3 Codex, older Claude `wt054`, R02 `wtI`, R02 `wtIx`) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Changes on `main` since `e8c9429e` (preserved exactly):
- `c45dcb39` audit amendment V03
- `48acb787`, `b31974af`, `61827343` TASKS
- `150d77b0` this prompt

`.github/workflows/ios-ipa.yml` was **unchanged** on `main` since `e8c9429e`, so no semantic reconciliation was needed.

## 2. Recovered original commit

- `1b56d17042bc6d2efdf31b12e689cc0fbc7102f7`: present and reachable as the detached HEAD of R02 `wtI`; parent `e8c9429ed2f84135b3865cc492840aa0ad7d8145`.
- `git show --stat --oneline 1b56d170`: `.github/workflows/ios-ipa.yml | 123 ++++…--` (1 file, +118 / −5).
- `git diff e8c9429e 1b56d170 --name-only` gives **only** `.github/workflows/ios-ipa.yml`.

## 3. Integration and publish

- In `wtI` (TEMP only): `git rebase origin/main` (1 commit, clean) → **`6edd173375ed72f428475e6aad8b70f076f90fd0`**, parent `61827343`. `git diff origin/main HEAD --name-only` = `.github/workflows/ios-ipa.yml` only.
- Pushed normally (no force): `61827343..6edd1733 HEAD -> main`.
- **Live check:**
  - after fetch, `HEAD == origin/main == 6edd1733`;
  - the GitHub contents API file `.github/workflows/ios-ipa.yml@main` is byte-identical to the pushed commit's file (`diff -q` = identical);
  - it contains `IMPORT_GATE PASS` (1×) and **zero** `--import || true`.
- `gh run list` after the push shows no new run. The workflow is still `workflow_dispatch`-only.

## 4. Final workflow (what the published change does)

Structural checks: `git diff --check` clean; YAML parse OK.

| Aspect | Value |
|---|---|
| Trigger | `workflow_dispatch` (unchanged) |
| Permissions | `contents: read` |
| Runner / steps | `macos-latest`, 11 steps |
| Import workspace | `actions/checkout@v4` with `filter: blob:none` and a non-cone sparse checkout `!/coordination/ !/docs/ !/tests/ !/tools/ !/level_factory/ !/content_pipeline/ !/assets/art/references/ !/assets/ui/candidates/ !/assets/ui/generated/ !/assets/ui/final/gameplay/buttons/icon_pause.png`. Absence is asserted in a step. |
| `icon_pause.png` | Excluded from the **temporary CI workspace only**. The repository file is untouched and still tracked. Reason (R02 findings): a truncated PNG since its only commit `fbda9e71` (its IDAT declares 32,768 B; the file is 7,531 B); owner M28-C002-C002 review S4 "`icon_pause.png` is a broken PNG", native glyph used; `VISUAL_ASSET_INDEX.md` LEGACY / EXTRA; zero runtime references. |
| Import gate | Fail-closed: `--import > out/import.log`. The run fails on a non-zero exit **or** any `Error loading` / `Error importing` / `ERR_FILE_CORRUPT` / `SCRIPT ERROR` / `Parse Error` / `Failed loading resource` / `Cannot open file` / `Resource file not found`. The full log is kept. The old `--import \|\| true` is gone. |
| Remaining `\|\| true` | All benign: (a) printing ERROR-prefixed lines after the gate passed; (b) an informational `icon_pause` count; (c) tolerating the headless boot's exit code, whose log is then strictly grepped for failures. |
| Package checks | The export log is also grepped for failed resources. The PCK **inside the built IPA** is scanned by the Family probe (`.github/android/pck_probe`): zero excluded developer paths, every runtime `res://` reference present, main scene. A headless `--main-pack` boot of that PCK runs. Inner IPA and PCK `shasum -a 256` are recorded. An inspection artifact (`Scrubbots-ipa-inspection`) is uploaded. |
| Signing | Unchanged: `CODE_SIGNING_ALLOWED=NO`, unsigned IPA, owner xtool signs at install. Artifact name `Scrubbots-ipa` unchanged. |

**PRIOR local evidence (R02 session, 2026-10-10; NOT CI proof):**
- an import of the identical sparse workspace exited 0 with **zero** `ERROR` lines;
- an iOS-preset pack scanned `files=1981 forbidden=0 required=663 missing=0 main_scene=true verdict=PASS`, with `icon_pause` absent and `touch_scroll.gd` present;
- `m47_touch_r01_mobile_ux` 14/14, `m43_c002_c001_popup_modal_pause` 23/23, `m28_c002_c002_static_shell` 16/16, `m28_c002_c003_final_gate` 22/22 and root `run_tests` ALL PASS.

No new 483 MB PCK was regenerated for this publish step. The first real CI execution of this workflow will be the owner's next iOS dispatch.

## 5. Scoped cleanup (only after §3 verification)

`git worktree list --porcelain` resolved both R02 worktrees under this session's scratchpad:
`C:\Users\sekip\AppData\Local\Temp\claude\C--Users-sekip-Desktop-ScrubBots\b6966355-d22b-4cc1-8033-eeec327dab7f\scratchpad\wtI` and `…\wtIx`.

Checks before removal:
- PowerShell `Get-Item`: `Attributes=Directory`, no `LinkType` / `Target`, so **not** a junction, symlink or reparse point.
- Both are R02 worktrees: detached at the R02 commit / its parent.
- Unpushed commits: 0 in each.
- No non-generated untracked files.
- `wtIx`'s only tracked change was Godot's import rewrite of its own TEMP `project.godot`.

| Worktree | Size before | Result |
|---|---|---|
| `wtIx` (R02 import / export probe; `.godot` cache, `build/ios/Scrubbots-inspection.pck`, generated `.import` / `.uid`) | 1,560 MiB | `git worktree remove --force` (the force covers only its generated R02 probe outputs) → path absent, no worktree entry. C: free 174,246 → 175,805 MiB (**+1,559 MiB**). |
| `wtI` (R02 implementation; `.godot` cache + generated files; holds this log until pushed) | 1,105 MiB | Removed **after** this log commit is pushed and verified. The result (path absence, `git worktree list`, free space) is reported in the hand-off, because this log cannot record its own aftermath. |

Not touched:
- other worktrees: the 3 Codex worktrees and the older Claude `wt054`;
- build caches outside these two paths;
- the Desktop's 2616 untracked files, its 4 modified tracked files and its 2 stashes.

No `git clean`, `reset --hard` or broad `Remove-Item` was used.

## 6. Desktop sync

The Desktop is fast-forwarded with `fetch` + `merge --ff-only` to the final `origin/main` after this log is pushed. Parity (HEAD == `origin/main`, 0/0), the 4 dirty files, 2616 untracked files, 2 stashes and the unchanged `project.godot` hash are reported in the hand-off.

Final state: `AWAITING_CHATGPT_INDEPENDENT_AUDIT`
