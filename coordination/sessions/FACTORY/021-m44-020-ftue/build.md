STATUS: READY

# Build: SB-M44-020 first-session funnel verify-close + repo hygiene + queue bookkeeping

## Spec (from orchestrator prompt, no spec.md)
- A. SB-M44-020: owner playtest gate given (CLAUDE.md §0D.1). Run the existing fresh-save first-session funnel suites headless, walk the funnel source (opening -> Home -> L1..L3 -> first rewards/unlocks, against the SB-M44-010 2026-10-22 unlock table), log friction. Suites pass and no blocking friction -> tick SB-M44-020 and set its queue row DONE; real friction -> new job-sized open item + READY row (next free SB-M44 ID). No code fixes.
- B. `git rm -r` coordination/sessions/FACTORY/017-color-assist-optin/captures/ (48 files); add empty `coordination/.gdignore` and `factory/.gdignore` after confirming no res:// code depends on Godot importing anything there.
- C. Add DONE queue rows FACTORY-002/007/009/010/020 after the existing DONE rows.
- `git diff --check` clean; commit; list changed files.

## Summary
Branch `factory/021-m44-020-ftue`, commits `91e498f6` (hygiene) and `01b0a201` (TASKS.md).
Files changed vs main (51):
- deleted: 48 files under `coordination/sessions/FACTORY/017-color-assist-optin/captures/` (24 images + 24 `.import`)
- added: `coordination/.gdignore`, `factory/.gdignore` (empty)
- modified: `TASKS.md` (SB-M44-020 ticked, SB-M44-031 filed, queue rows)

## Acceptance criteria
1. [x] Funnel suites run headless (Godot 4.7.2, fresh-save overrides in the suites themselves), all exit 0, no SCRIPT ERROR/Parse Error, LOCAL_PASS:
   - `m44_ftue`: `M44 FTUE evidence: PASS (23/23 cases, 0 fail)` (run before and after the .gdignore commit)
   - `m42_opening`: `M42 opening evidence: PASS`
   - `m42_navigation`: `M42 navigation evidence: PASS`
   - `m42_home`: `M42 home evidence: PASS` (run before and after the .gdignore commit; it reads `res://coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md` via FileAccess, still found)
   - `m46_rm003_ftue_coach_performance`: `M46 RM003 FTUE COACH: PASS (4 case groups)`
2. [x] Funnel source walked (`data/config/ftue_onboarding_v1.json`, `scripts/app/ftue_config.gd`, `scripts/app/app_state.gd` starter grant, `data/config/player_experience_plan_v1.json`). The shipped funnel hangs together; no blocking friction. The friction is the gap to the owner's 2026-10-22 unlock table (SB-M44-010):
   - L1 Home lesson `home_welcome` coachmarks Daily (`shortcut:daily`) and Tasks (`shortcut:tasks`), but Daily unlocks at L4 and Tasks at L12.
   - L2 lesson `l2_boosters` teaches all four boosters, and the starter grant gives 2 charges of each at L1, but boosters unlock at 6/11/16/21.
   - `first_day_welcome_task` (100 SB via Tasks) fires on day 1 while Tasks unlocks at L12.
   - `feature_discovery.policy = soft_no_hard_locks` with everything `available_from_first_home`, enforced by `ftue_config.gd`; `player_experience_plan_v1.json` `feature_unlock_levels` still says `OWNER_TUNING_REQUIRED`. The latter belongs to SB-M44-010 itself.
   Filed as one job-sized item **SB-M44-031** (open item under the M44 Meta Progression block + READY queue row after SB-M44-030). The ID was checked as free across TASKS.md, the archive, the repo and factory/jobs. It depends on SB-M44-010. No code changed.
3. [x] SB-M44-020 ticked with a 2026-10-22 note (suites, §0D.1, friction -> SB-M44-031); its queue row is now `DONE`.
4. [x] Job 017 captures removed: `git ls-files .../captures | wc -l` = 48 before; `git rm -r` -> commit `91e498f6` (50 files changed, 960 deletions incl. the 2 .gdignore adds).
5. [x] Checked that nothing needs Godot to import anything under coordination/ or factory/. No `.gd/.tscn/.tres/.res/.gdshader` is tracked there, so no class_name or scene is lost. Every `res://coordination/...` reference in scripts/scenes/tests/tools (m28 layout smoke, m42_c003, m42_home, m43_*, m52, m53, run_tests v03 tmp, tests/tools capture scripts) goes through FileAccess/DirAccess/globalize_path or JSON reads, never `load()`/ResourceLoader. Nothing references `res://factory`. `.gdignore` only stops editor scanning and importing, so these filesystem reads keep working. m42_home confirmed it after the change.
6. [x] Queue rows `DONE FACTORY-002/007/009/010/020` added right after the existing DONE rows (just before the SB-M44-020 row, now DONE).
7. [x] `git diff --check` clean; TASKS.md stays CRLF (1972 CRLF / 1972 LF); diff = +9/-2 lines.

## Validation
- 5 funnel suites above: LOCAL_PASS (exit 0, no script/parse errors, last line PASS).
- `git diff --check`: clean.
- `git status --porcelain` tracked files: clean. Untracked: about 2,600 `.uid`/`.import` files that the pre-job Godot import generated in the worktree (the owner's main checkout carries the same untracked `.uid` files). Not committed or deleted by this job. The worktree is disposable.

## Log
### Round 1
- Confirmed branch `factory/021-m44-020-ftue`.
- Ran the five funnel suites, walked the FTUE config/source against the SB-M44-010 owner unlock table, filed the friction as SB-M44-031 and ticked SB-M44-020 (Part A).
- Removed the job 017 captures and added `.gdignore` for coordination/ and factory/ after the reference audit (Part B). Re-ran m42_home and m44_ftue after the change: PASS.
- Added the FACTORY DONE rows (Part C).
