# M44-C001 R01 — ONE CONTINUOUS MASTER VERIFICATION / INDEPENDENT AUDIT REMEDIATION
Date: 2026-10-14 | Implementer: Claude Code | independent auditor and root TASKS.md writer: ChatGPT

**Read:** `CHATGPT_INDEPENDENT_AUDIT_V01.md`, `CHATGPT_M44_AUDIT_CRITERIA_V01.md`, original `CHATGPT_M44_MASTER_PROMPT_V01.md`, `OWNER_M44_FIRST3_STARTER_AND_CLAIM_DECISION_V03.md`, `CLAUDE.md §0A`, root `TASKS.md`. This is still **the SAME M44 24-child milestone**; do not start M45 or split into micro-prompts.

## WHY THIS CYCLE EXISTS
The genuine existing GitHub run **38626611950** is **PASS (17/17 suites, M44 21/21, CP06 16/16, no APK)**, but the original M44 audit G4 required real specialized M39/Settings/Daily regressions. Claude disclosed these were NOT run, so ChatGPT's independent audit is `FOCUSED_TECHNICAL_PASS / REQUIRED_REGRESSION_GAP / NOT_FULLY_CLOSED`. The user is NOT asking for a new release. **Only ONE last authorized validation_only Actions run remains** (the first M44 run 38625474342 failed; the second 38626611950 succeeded). Do not exceed the 3-run limit without owner permission.

## THE ONE R01 MASTER WORK PACKAGE
### R01-A: PRECHECK, NO LOCAL TEST WORKSPACE
1. Use only original `C:\Users\sekip\Desktop\ScrubBots`; read branch/status/owner-dirty paths and stash count, preserve tracked/untracked art, local project.godot SHA, and safely sync to latest origin/main fast-forward ONLY if owner files don't conflict. Do not create second clone/worktree, reset/clean/stash, or local Godot `user://` fixtures/cache. Heavy work remains remote GitHub. New incidental laptop TEMP <20MiB at once, minimal, exact task-owned cleanup and before/after observability per latest owner's `CLAUDE.md §0A`. Do not touch original UI/levels/art without a proven specialized test failure.
2. Inspect **actual** existing workflow `.github/workflows/android-family-first10.yml`: existing 17 suites, required CP06 16/16 AND M44 21/21 exact summaries, fail-closed script diagnostics, `workflow_dispatch` choice default validation_only, export job level `if: inputs.mode == 'build_apk'`, no other triggers. Keep every current test and guard unchanged.

### R01-B: EXPAND THE **SAME EXISTING** VALIDATE MATRIX
3. Add the following previously omitted **17** specialized focused test scripts (each exists on main) as additional validation_only suite entries, in logical grouped order without removing the existing 17:
   - `m39a_economy_core`
   - `m39b_hearts_speed`
   - `m39c_boosters`
   - `m39d_daily_collection`
   - `m39e_full_matrix`
   - `m39_v02_atomicity`
   - `m39_v02_capacity`
   - `m39_v02_integration`
   - `m39_v03_full_surface`
   - `m39_v03_integration`
   - `m39_v04_integration`
   - `m39_v04_tornado_inflight`
   - `m39_c003_random_any_booster_rewards`
   - `m41_settings`
   - `m43_master_c009_daily`
   - `m43_r15_owner_remediation`
   - `m43_r15_001_r01_sequential_unlock`.
4. Before dispatch, **read each relevant test's assumptions** and validate missing resources in the workflow sparse checkout (no `coordination/sessions` on CI); scripts may carry legacy expectations. Do NOT secretly exclude any just because a test might fail. Do NOT weaken tests or auto-allowlist failures. Each suite must produce an individually visible `exit=0 script_diag=0 status=PASS`, and the aggregate must fail if even one fails. Preserve the one precise preexisting m43_c005f intentional script error allowlist and nothing broader. Imported Godot 4.7.2 parser errors remain fail-closed. Focused loop with 34 total suite entries (17 old + 17 new) and one 120-min validate job; if static review proves one script depends on impossible excluded owner-private inputs, STOP before dispatch and report that bounded blocker instead of guessing.
5. Commit/push ONLY the narrowly changed existing Android YAML safely. Read back YAML on live GitHub main **before** dispatch, verify exact job-level export guard, required mode=validation_only default, no push trigger and all 34 test names present. Do NOT create a new workflow or dispatch any build workflow.

### R01-C: ONE REMAINING OWNER-AUTHORIZED RUN, THEN STOP IF FAIL
6. Dispatch **ONLY `mode=validation_only`** on live `main` using existing GitHub Actions. This is **M44 RUN 3/3**. **NEVER** select build_apk or run iOS/IPA. No R2/LF/cloud publishing. GitHub-hosted transient files don't occupy user's laptop; do not fetch/downsample CI artifacts onto laptop.
7. Inspect real run URL/head SHA/logs/jobs/artifacts, verify `validate=success`, `export=skipped`, no APK/PCK/IPA, all 34 focused suites `PASS` with exact genuine M44 `PASS (21/21)`/CP06 `PASS (16/16)`. Document first-failure evidence if any. **NO FOURTH CI RUN.** If any specialized test fails, don't downgrade assertions or self-declare technical PASS. Report `BLOCKED_R01_CI_FAIL_LIMIT_3_OF_3` with exact failing suite/trace and propose narrowly scoped source or test remediation for independent review; *do not run it again without explicit owner approval*.
8. If all pass, mark status `READY_FOR_CHATGPT_R01_REAUDIT_AND_OWNER_VISUAL`. Do NOT claim full M44 passed: M44-018/020 require owner real phone UX approval; 005 actual wait-trigger differs from historic row, 010/013/022/023 may remain owner/M43-gated. No first-ten level/R2 publication or APK is authorized by this milestone.

### R01-D: ONE LOG, FINAL HANDOFF
9. Append to the **same** `coordination/sessions/M44-TUTORIAL-FTUE-C001/CLAUDE_LOG_V01.md` (R01 section), include branch SHAs, workflow diff, exact 34-suite results, real run/job/artifact URLs, CP06+M44 verdict, evidence no export and owner disk/TEMP footprint, and per-ID 24 row disposition. Do not create parallel statuses/dashboards or edit root TASKS.md; ChatGPT alone writes TASKS and performs independent audit.
10. End with **only one log link + exact result**. Await ChatGPT audit, which will open owner visual/mobile gate with existing workflow/build approval separately.

## NON-NEGOTIABLE OWNER PRODUCT LOCKS
- Newly created profiles: 2 real charges of EACH FOUR canonical boosters, one-time, durable.
- FIRST Home: DAILY 100 SB + separate TASKS Welcome 100 SB claims ready, no auto-claims, exactly three daily tasks, later ordinary 75/100/125 tiers, old profiles untouched.
- Mandatory learning only Home+real L1/L2/L3; absolutely no scheduled mandatory tutorial L4+; no fake results, user economy grants except authorized starter, illegal solver mutation or paid 2x; Home four panels and opening cinematic unskippable.
- This R01 is a verification continuation, **NOT** authorization for new product features or broad refactoring.
