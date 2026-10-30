# M43 verify sweep (R09, 122-130/134, R10, 143-151, R12, 163-170, C005F-015)

> Feature: Audit job over READY queue rows SB-M43-R09-001..005, 122..126, 127..130, 134, R10-001..007, 143..148, 149..151, R12-001..006, 163..168, 169..170, C005F-015: find implementing code and covering suites, run each once headless, classify VERIFY-CLOSE / PARTIAL / BUILD, add VERIFY-CLOSE suites to the CI validate loop with exact-summary guards, tick rows with honest LOCAL_PASS evidence.

## Context
- CI: `.github/workflows/android-family-first10.yml`, validate loop at ~lines 110-123 (56 suites; header comments lines 31-41; exact-summary guards at ~189-229, pattern: `if grep -qxF '<line>' validate_logs/<suite>.log 2>/dev/null; then`). Copy that pattern.
- All suites ran in the job worktree with Godot 4.7.2 console, exit 0. Godot dirtied only untracked `.uid`/`.import` files; tracked tree was clean after `git checkout -- .`.
- Implementation: `scripts/economy/{daily_orders,event_service,player_records,return_service,notification_policy}.gd`, `scripts/progression/achievements.gd`, `scripts/ui/profile/profile_screens.gd`, `scripts/ui/home/home_badges.gd`, `scripts/ui/feel/meta_feedback.gd`, `data/config/{daily_scrub_orders_v1,events_v1,achievements_v1,comeback_v1}.json`.
- Not in CI today: `m43_master_c010_meta`, `m43_master_c011_c014`. Already in CI: `m43_master_c009_daily` (guarded 12/12), `m44_new_badge`.

## Suite results (each run once, LOCAL_PASS)
- S1 `m43_master_c009_daily`: `M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)`
- S2 `m43_master_c010_meta`: `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)` (m01..m12)
- S3 `m43_master_c011_c014`: `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)` (w01-04, c01-04, n01-05, s01-07, a01-08)
- S4 `m44_new_badge`: `M44 new badge evidence: PASS (6/6 cases, 0 fail)`
- S5 `m43_master_c005f_feel`: `M43 master C005F feel evidence: PASS (10/10 cases, 0 fail)`
- S6 `m43_c005f_phase3_meta_rewards_acquisition`: `M43-C005F-PHASE3 meta rewards + acquisition feel: PASS (15/15 cases, 0 fail)`
- S7 `m43_c005f_phase5_cleaning_spark_ab`: `M43-C005F-PHASE5 cleaning Spark A/B: PASS (13/13 cases, 0 fail)`

## Row table
| ID | Class | Suite : cases |
|---|---|---|
| R09-001 | VERIFY-CLOSE | S1 t01, t10 (pool, strict import, exactly 3) |
| R09-002 | VERIFY-CLOSE | S1 t03 (progress from real wins only), t11 (no paid path) |
| R09-003 | VERIFY-CLOSE | S1 t02 (deterministic, no reroll), t09 (frontier/content eligibility) |
| R09-004 | VERIFY-CLOSE | S1 t01, t04 (tiers, claim) |
| R09-005 | VERIFY-CLOSE | S1 t05 (ScrubBox once), t11 (no paid reroll). R09-006 stays READY (M56 gate) |
| 122 | VERIFY-CLOSE | S2 m01 (events/robots live, RANKS honest-disabled) |
| 123 | VERIFY-CLOSE | S2 m02 |
| 124 | VERIFY-CLOSE | S2 m03 |
| 125 | BUILD | manifest `profile` MASTER_REQUIRED, no visual master artifact |
| 126 | VERIFY-CLOSE | S2 m04 |
| 127 | BUILD | manifest `achievements` MASTER_REQUIRED |
| 128 | VERIFY-CLOSE | S2 m05 (no event points/currency) |
| 129 | VERIFY-CLOSE | S2 m05-m07 (empty, countdown, progress, claim, ended, unavailable) |
| 130 | BUILD | `events_main`/`event_detail` MASTER_REQUIRED; no reusable card-family master |
| 134 | VERIFY-CLOSE | S2 m10 + S4 |
| R10-001 | VERIFY-CLOSE | S2 m06 |
| R10-002 | VERIFY-CLOSE | S2 m06 (loss adds nothing; first clears only) |
| R10-003 | VERIFY-CLOSE | S2 m06, m07 (no reset, forfeit / claim_after_end, no policy -> invalid) |
| R10-004 | VERIFY-CLOSE | S2 m08 |
| R10-005 | VERIFY-CLOSE | S2 m08 (only normal Heart, retry cannot extend, reward fixed) |
| R10-006 | VERIFY-CLOSE | S2 m09 |
| R10-007 | VERIFY-CLOSE | S2 m09 (self-ghost, no social) |
| 143 | VERIFY-CLOSE | S3 c01, c02 |
| 144 | VERIFY-CLOSE | S3 c02 ("nothing granted, Daily untouched") |
| 145 | VERIFY-CLOSE | S3 n01 |
| 146 | BUILD | no OS permission wiring exists (manifest `notification_education_settings`: platform permission plugin). Do NOT wire a real OS prompt without the owner |
| 147 | VERIFY-CLOSE | S3 n01, n02, n05 |
| 148 | VERIFY-CLOSE | S3 n03 |
| 149 | VERIFY-CLOSE | S3 n02, n04 |
| 150 | BUILD | manifest `comeback_summary` gap "illustration SB-M43-150" |
| 151 | PARTIAL | S3 n03/n04/n05/c01 cover stale links, rollback, timezone, missed days. Missing unless already asserted: "notifications disabled / permission denied -> nothing scheduled" and "expired event suppressed" |
| R12-001 | PARTIAL | S3 c03/c04 pass with injected config; shipped `comeback_v1.json` has no steps ("track not offered"). Needs owner-set rewards; stays READY |
| R12-002 | VERIFY-CLOSE | S3 c04 |
| R12-003 | VERIFY-CLOSE | S3 c01, c04 |
| R12-004 | VERIFY-CLOSE | S3 n02 |
| R12-006 | VERIFY-CLOSE | S3 n03 (stale suppression); spot-check the factual-copy claim in n03/a04, add one assertion only if absent |
| 163 | VERIFY-CLOSE | S3 a02 |
| 164 | VERIFY-CLOSE | S3 a01 |
| 165 | VERIFY-CLOSE | S3 a04 |
| 166 | VERIFY-CLOSE | S3 a04, S2 m05 |
| 168 | BUILD | cross-screen sound/haptic feel acceptance; a03/a05 only cover fatigue and mapping |
| 169 | PARTIAL | manifest exists (39 surfaces); no test asserts it covers every surface id in `data/config/ui_surface_registry_v1.json`. Add that one assertion, then close |
| 170 | BUILD | closure gate: many surfaces MASTER_REQUIRED, `ranks`/`level_intro` not live |
| C005F-015 | PARTIAL | S5/S6/S7 pass for pieces; no single representative-path end-to-end suite; owner visual gate. Stays READY |

## Requirements
1. Add `m43_master_c010_meta` and `m43_master_c011_c014` to the validate loop (56 -> 58); update the header comment with the new total and row IDs.
2. Add exact `grep -qxF` guards for the S2 and S3 lines above, same style as existing guards.
3. Add only the named PARTIAL assertions (151, 169, R12-006 copy if absent); if they become new cases, update `EXPECTED_CASES`, the count, and the guard line to match.
4. In TASKS.md tick the individual `- [ ] SB-M43-NNN` checklist lines of VERIFY-CLOSE rows (PARTIAL ones only after the assertion passes) with `LOCAL_PASS`, suite and exact summary line; label review honestly. Leave BUILD rows (125, 127, 130, 146, 150, 168, 170), R12-001 and C005F-015 unticked, adding a one-line gap note; trim the READY queue rows to the remaining IDs.
5. No real OS notification permission prompt; no new mechanics; no invented config values.
6. Restore tracked files Godot rewrites (`git checkout -- <paths>`); never commit `.uid`/`.import` noise.

## Acceptance criteria
1. `"$GODOT" --headless --path <wt> -s res://tests/m43_master_c010_meta.gd` prints `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)` (or the new count, matching its guard).
2. `m43_master_c011_c014.gd` prints `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)` (or the new count, matching its guard).
3. The workflow loop lists 58 suites; both guards present with `grep -qxF`.
4. `git diff --check` clean; no tracked `.import` changes in `git status --short`.
5. Ticked TASKS rows cite suite plus exact summary; BUILD rows remain unticked.

## Out of scope
Visual master production, OS notification plugin/permission, comeback reward values, RANKS, Level Intro, R09-006 ScrubBox bonus slot, adding S5-S7 to CI, gameplay/economy code changes.

## Assumptions
- Visual-master and owner-feel rows stay READY: no master artifact exists (manifest MASTER_REQUIRED), and ticking would claim unperformed work despite the §0D approvals.
- 146 stays READY: policy exists but no contextual OS prompt/plugin; avoids wiring a real OS prompt.
- Case-to-row mappings come from case names and ok-lines in the run logs; the builder must spot-check 151 and R12-006 in the suite source before ticking.
