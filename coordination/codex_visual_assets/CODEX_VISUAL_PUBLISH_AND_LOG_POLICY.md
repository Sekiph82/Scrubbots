# SCRUBBOTS — CODEX VISUAL PUBLISH & LOG POLICY

Status: MANDATORY
Branch: `codex/visual-assets-production`

This policy applies to all current and future Codex visual-asset work.

## 1. Canonical repository

Repository:

`Sekiph82/Scrubbots`

Dedicated visual branch:

`codex/visual-assets-production`

Claude may be working concurrently on `main`.

Codex MUST NOT modify, merge, rebase, reset, force-update, or push to `main`.

## 2. Local worktree is NOT the final destination

Codex may work from a local visual worktree such as:

`C:\Users\sekip\Desktop\ScrubBots-phase2-visuals`

Local files are temporary working state.

A task is NOT complete merely because:
- the PNG exists locally;
- the log exists locally;
- a local commit exists.

A visual task is complete only after the correct files are present on:

`origin/codex/visual-assets-production`

## 3. Canonical image destinations

Every generated/derived visual MUST be copied or moved into the exact canonical target path defined by the active master list before commit.

Current Phase 2 authority:

`coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_MASTER_LIST.md`

Final production images go to their exact listed paths under:

`assets/ui/final/**`

Raw/working selected outputs may additionally be stored under:

`assets/ui/generated/project_wide_phase2/**`

Do not leave a required project asset only in:
- `$CODEX_HOME/generated_images/**`;
- Desktop/temp folders;
- Downloads;
- arbitrary local output folders.

## 4. Canonical log destinations

Official GitHub logs are:

Phase 1:
`coordination/codex_visual_assets/CODEX_VISUAL_ASSET_LOG.md`

Phase 2:
`coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_LOG.md`

Cross-phase summary:
`coordination/codex_visual_assets/CODEX_VISUAL_PRODUCTION_MASTER_LOG.md`

If a local log exists, such as:

`C:\Users\sekip\Desktop\ScrubBots-phase2-visuals\coordination\codex_visual_assets\CODEX_PROJECT_VISUALS_PHASE2_LOG.md`

then BEFORE declaring completion:
1. read the local log;
2. merge/append its missing factual entries into the repository copy of the Phase 2 log;
3. append a concise batch summary to the master visual production log;
4. commit those repository log updates;
5. push them to `origin/codex/visual-assets-production`.

Do not merely report a Windows local log path to the owner.

## 5. Mandatory publish sequence

At the end of EVERY meaningful visual batch:

1. Confirm current branch/worktree:
   `git status --short`
   `git branch --show-current`

2. Fetch the remote visual branch:
   `git fetch origin codex/visual-assets-production`

3. If remote visual branch contains new commits that are descendants of your current branch, fast-forward safely.
   Do not touch `main`.

4. Verify all completed image outputs are at their exact canonical paths.

5. Update the official repository Phase 2 log.

6. Append a summary to:
   `coordination/codex_visual_assets/CODEX_VISUAL_PRODUCTION_MASTER_LOG.md`

7. Stage ONLY:
   - exact authorized visual image files;
   - Phase 2 task/log files when allowed;
   - master visual production log.

8. Never use:
   `git add .`
   `git add -A`

9. Commit with a visual-only message.

10. Push ONLY:
    `git push origin codex/visual-assets-production`

11. Verify remote publication:
    `git fetch origin codex/visual-assets-production`
    `git log origin/codex/visual-assets-production --oneline -n 12`

12. Verify required paths remotely/local remote-tracking tree:
    `git ls-tree -r --name-only origin/codex/visual-assets-production -- assets/ui/final coordination/codex_visual_assets`

13. Only after verification may you report the batch as complete.

## 6. Push rejection handling

If push is rejected because the visual branch moved:

- do NOT push to main;
- do NOT force-push;
- do NOT reset;
- do NOT delete another contributor's commits.

Fetch the visual branch and safely integrate ONLY the visual branch history.

Preserve all existing remote commits.

If there is a conflict in:
- image files,
- Codex visual logs,
- Codex visual task files,

resolve carefully without dropping either completed asset work or newer owner/ChatGPT coordination changes.

If a conflict involves any forbidden non-visual project file, preserve the remote version and do not introduce a Codex change there.

## 7. Forbidden writes

Do not modify:
- root `TASKS.md`;
- Claude prompts/logs/sessions;
- gameplay code;
- Godot scenes/scripts;
- tests;
- manifests;
- configs;
- workflows;
- project settings;
- docs outside authorized Codex visual coordination;
- `main`.

## 8. Required final report

Every Codex visual completion response must include:
- remote branch name;
- remote branch HEAD SHA;
- commit SHA(s) created;
- number of canonical targets present / expected;
- exact missing targets, if any;
- confirmation that official GitHub logs were updated;
- confirmation that `main` was untouched.

Never present a local filesystem path as the authoritative completion evidence.
