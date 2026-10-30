# Profile, Achievements, Events visual masters + SB-M34-006 owner answer

> Feature: SB-M43-125, SB-M43-127, SB-M43-130 Profile, Achievements and Events visual masters (data/docs only), plus apply the factory/answers.md owner answer for SB-M34-006.

## Context
- Three masters were generated 2026-10-31 in the owner's ChatGPT Plus account (provider `chatgpt_image_generation`, conversation "Create Profile UI Mockup", style refs: owner phone screenshots of Home and Collection). They sit untracked in the worktree: `assets/ui/generated/masters/scrubbots_{profile,achievements,events}_master_v01.png` (~1.9-2.3 MB each).
- Owner chose "Yeni master tasarla" (2026-10-31) and then delegated full authority ("ben sana tam yetki veriyorum"). The orchestrator selected them. Honest label: **approved by Claude under owner-delegated authority 2026-10-31**, NOT owner visual review.
- Shipping: `.github/android/export_presets_family_first10.cfg` `exclude_filter` already contains `assets/ui/generated/*`, so the PNGs under `assets/ui/generated/` do not ship. Keep them there (do NOT put them under `assets/ui/final/`). No preset change needed.
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`: surfaces `profile` (line ~415), `achievements` (~430), `events_main` (~445), `event_detail` (~460) are `"status": "MASTER_REQUIRED"` with `implementation.gap` text "owner visual master (SB-M43-125/127/130)". Lifecycle already includes `MASTER_OWNER_APPROVED`. Top-level `canonical_references` is a plain id -> path map.
- `ASSET_GENERATION_MANIFEST.json` `canonical_references` is id -> object with `repository_path`, `status`, optional `owner_decision`.
- Only test touching the manifest: `tests/m43_c001b_won_results_visual.gd:327-335`, which reads a results surface and accepts `MASTER_REQUIRED` or `MASTER_OWNER_APPROVED` (with owner_ok). It does not read profile/achievements/events; confirm it still passes, no edit expected. `tests/m55_heart_900_authority.gd` only lists a doc path.
- `TASKS.md` (never read whole): queue rows at lines ~60-62 (`READY SB-M43-125/127/130`), long-form entries at ~1210/1212/1215 (`- [ ] ... [OPEN ...]`), SB-M34-006 at queue line 45 (`OWNER`), dependent OWNER rows 46-48 mention "see Questions SB-M34-006", `## Questions for Şekip` line ~141, long-form ~959.
- `factory/answers.md` lives in the main checkout (`C:/Users/sekip/Desktop/ScrubBots/factory/answers.md`), not the worktree; its last entry is the SB-M34-006 answer "all is ok" (2026-10-31T00:44). Do not edit it.

## Requirements
1. Commit the three PNGs unchanged at `assets/ui/generated/masters/`.
2. `ASSET_GENERATION_MANIFEST.json` canonical_references: add `profile_master_v01`, `achievements_master_v01`, `events_master_v01` objects: `repository_path`, `status` `"MASTER_APPROVED_BY_CLAUDE_DELEGATED"`, `provider` `chatgpt_image_generation`, `date` `2026-10-31`, `owner_decision` text "owner chose new master 2026-10-31, delegated selection to Claude; not owner visual review", `ships` false (excluded via `assets/ui/generated/*`). Events entry notes it includes the reusable event card family (active card with timer/progress/milestones, collapsed upcoming "Starts in 2d" card).
3. `PLAYER_EXPERIENCE_ASSET_MANIFEST.json`: add `profile_master`, `achievements_master`, `events_master` to `canonical_references` (same paths). Set `profile`, `achievements`, `events_main`, `event_detail` status to `MASTER_OWNER_APPROVED`, and update each `implementation.gap` to say the master exists (approved by Claude under owner-delegated authority 2026-10-31) and the remaining gap is rebuilding the screen to match it (name the REBUILD task id). Add a `master` field with the repo path to each of those four surfaces. JSON must stay valid. Keep the delegated-approval wording explicit in `recorded_by`/gap so it is not read as owner review.
4. `TASKS.md`:
   a. Queue rows 125/127/130 -> `DONE`, with evidence "master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); path; factory 075". Mark the long-form `- [ ]` entries at ~1210/1212/1215 `[x]` with the same note.
   b. Directly after the three, add three READY rows: `SB-M43-125-REBUILD` (rebuild Profile to match its master), `SB-M43-127-REBUILD` (Achievements), `SB-M43-130-REBUILD` (Events + reusable event card/detail family). First grep that no existing id already covers implementation; if one does, reuse it instead of adding.
   c. SB-M34-006: queue row 45 -> `DONE` as OWNER_ACCEPTED ("all is ok", 2026-10-31T00:44), stating honestly no device capture was made, A10 not reachable by adb afterwards, and the A10 still runs the pre-VIBRATE build until the next save-preserving reinstall. Flip long-form ~959 to `[x]` with same note. Remove the SB-M34-006 line from `## Questions for Şekip` (leave the comment line). Rows 46-48 (SB-M42-032, SB-M47-*) say "see Questions SB-M34-006": reword to "waits for the Galaxy A10 to be plugged in" without pointing at the removed question; keep them OWNER.
5. No code, scene, or test changes. No new tests.

## Acceptance criteria
1. `git -C <worktree> ls-files assets/ui/generated/masters` lists the three `scrubbots_*_master_v01.png` files; none under `assets/ui/final/`.
2. `python -c "import json;json.load(open('ASSET_GENERATION_MANIFEST.json'));json.load(open('assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json'))"` exits 0 (run in worktree).
3. In the player manifest, `profile`, `achievements`, `events_main`, `event_detail` all have status `MASTER_OWNER_APPROVED`; `grep -c MASTER_REQUIRED` decreases by exactly 4 versus main; every `master` path and every new `repository_path` exists on disk.
4. `grep -n "owner-delegated" assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json ASSET_GENERATION_MANIFEST.json` shows the honest label; no entry claims owner visual review or `OWNER_ACCEPTED`.
5. `grep -n "SB-M43-125\|SB-M43-127\|SB-M43-130" TASKS.md` queue rows are DONE and three REBUILD rows are READY immediately after them.
6. `grep -n "SB-M34-006" TASKS.md` shows the queue row as DONE/OWNER_ACCEPTED, and no line under `## Questions for Şekip` mentions it; `grep -n "Questions SB-M34-006" TASKS.md` returns nothing.
7. `"$GODOT" --headless --path <worktree> -s res://tests/m43_c001b_won_results_visual.gd` still prints its PASS line (unchanged result vs main).
8. `git diff --check` clean; `git diff --stat` shows only the two manifests, TASKS.md, and three added PNGs (ignore pre-existing `.import`/uid noise, do not stage it).

## Out of scope
- Rebuilding any screen, scene, or GDScript; slicing assets; moving masters to `final/`.
- Claiming owner visual review/acceptance; setting statuses past `MASTER_OWNER_APPROVED`.
- Editing `factory/answers.md`, export presets, or CI workflows.
- Any device capture or claiming haptics were measured.
- Staging unrelated `.import`/`.uid` changes.

## Assumptions
- `MASTER_OWNER_APPROVED` is the only lifecycle value fitting "master approved"; the delegated-by-Claude caveat is carried in text fields and the distinct `MASTER_APPROVED_BY_CLAUDE_DELEGATED` status in the generation manifest, since no test blocks it and honesty matters.
- Masters stay in `assets/ui/generated/masters/` because that path is already export-excluded; no extra size mitigation required.
- Dependent device rows (SB-M42-032, SB-M47-*) stay OWNER because only haptics was accepted.
