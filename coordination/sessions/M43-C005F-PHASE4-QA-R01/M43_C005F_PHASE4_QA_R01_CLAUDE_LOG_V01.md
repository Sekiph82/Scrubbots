# M43-C005F-PHASE4-QA-R01 — Long-Session Baseline Hygiene + MetaRewardFeel Await Safety — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_AUDIT_CRITERIA_V01.md`
- Audit closed by this remediation: `coordination/sessions/M43-C005F-PHASE4/CHATGPT_INDEPENDENT_AUDIT_V01.md` §7
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `35a7b6f63d2f954e600d302d5d563e3222b3b5f6` (`origin/main`)
- Final SHA: the commit that adds this log. Code, tests and this log are in one commit; parity is reported in the hand-off.
- Phase 4 product (F010 / F012) is unchanged. Root `TASKS.md` was not edited.

## 0. Gate 0 — owner Desktop safety

| Item | Value |
|---|---|
| Desktop HEAD at start | `f44bb280` |
| `origin/main` after `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` | `35a7b6f6` |
| Ahead / behind | 0 / 4 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked files | 2616 |
| Stashes / worktrees | 2 stashes (untouched); 3 Codex worktrees + 1 older Claude scratch worktree (untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Reconcile:
- The 4 incoming commits touched only `TASKS.md`, the Phase 4 audit and the QA-R01 prompt/criteria. None overlapped a dirty file.
- `git merge --ff-only origin/main` → Desktop = `35a7b6f6`, **0/0**. Nothing was stashed, reset, cleaned, restored or forced. The `project.godot` hash was unchanged.

TEMP worktree:
- Created after Gate 0 with `git -C "<Desktop>" worktree add --detach "<TEMP>" origin/main`.
- Every command used an absolute `git -C "<TEMP>"` / `godot --path "<TEMP>"` path.
- `--import` rewrites the TEMP `project.godot`, so that copy was restored with `git -C "<TEMP>" checkout -- project.godot`. That command never ran against the Desktop.

## 1. Baseline defect evidence

### 1.1 M55 lap-1 "leak"

On untouched `bf4d6264` and on Phase 4 `f44bb280` (whose code is identical to `35a7b6f6`; that commit only adds docs), with the original test (Phase 4 log §4.2):
- `back at HOME the tree Node count returns exactly to baseline (219 -> 254)` → FAIL;
- `lap 1: Object count ... within 64 of the lap baseline (157)` → FAIL;
- lap 2 and every steady-state check → PASS.

**What the extra Nodes are.** I measured them; I did not assume. A one-off census probe (a temporary copy of the test, deleted afterwards) diffed the app-root Node multiset between the empty-Home baseline and the lap-1 end. **All 34 extra Nodes belong to one open popup: `ModalStack/ModalRoot/Popup_ceremony_gift_10`.**

| Nodes | Type |
|---|---|
| 6 | Label |
| 5 | VBoxContainer |
| 5 | TextureRect |
| 4 | Control |
| 3 | HBoxContainer |
| 3 | PanelContainer |
| 2 | CenterContainer |
| 2 | Button |
| 1 each | ColorRect, MarginContainer, Container, NinePatchRect |

How the popup gets there:
- Ten real wins push the Gift Meter past its 10 milestone.
- Back on Home, the canonical quiet-Home order presents that pending ceremony.
- The baseline is an empty Home that has never played, so it has no popup.

So the lap-1 comparison measures two different legitimate UI states. Lap 2 runs the same workload and ends with the same popup, so its Node count matches the lap-1 end exactly. The lap-1 Object delta is that popup plus first-load content: ten levels' data, textures and audio.

### 1.2 MetaRewardFeel await-after-free

Both of those runs print `Resumed function '_play()' after await, but class instance is gone. At script: res://scripts/ui/feel/meta_reward_feel.gd:148`.

A temporary print in the TEMP copy, reverted afterwards, located it in M55:
1. **frame 101:** the Gift-10 ceremony is shown on Home, and `_play` starts its settle wait on its `HeroArt`;
2. the rect is still moving, so the wait resumes and suspends again;
3. **frame 103:** the test frees the app root, and the MetaRewardFeel predelete runs;
4. the error prints.

Mechanism, confirmed by reproduction:
- When a GDScript instance is destroyed, Godot clears its pending await connections. Freeing the root *before* the wait first resumes is therefore silent; my first two test attempts did that and stayed green.
- The error appears when the teardown runs inside the same `process_frame` emission, **before** the wait's already-queued resume. That callback is in the emission snapshot, so it resumes on a dead instance.

The new suite (§3) reproduces exactly this condition. On the **unmodified** `meta_reward_feel.gd` it printed the exact warning (`ERROR: Resumed function '_play()' after await, but class instance is gone. At script: res://scripts/ui/feel/meta_reward_feel.gd:148`), and its static guard failed.

## 2. M55 test-model correction (`tests/m55_long_session.gd`)

Unchanged:
- `MAX_OBJECT_DRIFT = 64` and `MAX_STATIC_MEM_DRIFT = 4 MiB`;
- the transition-churn block and all of its exact post-warm-up checks;
- lap 1 and lap 2 as two full real Level 1..10 runs, with every gameplay, reward, idempotency, host, orphan, listener and persisted-save check;
- the final lap-2-vs-lap-1 steady-state assertions.

Changed:

| Area | Before | After |
|---|---|---|
| **Lap 1** Node / Object / static memory | Asserted against the empty-Home baseline | **Recorded** as `WARM-UP lap 1 first-use delta ...`, with the per-`/root`-branch Node delta (`_branches()`, evidence only). Still asserted every lap: no GameplayHost at Home, app-root child count unchanged, orphans not grown, authority listeners back to baseline. |
| **Lap 2** | Separate inline checks | One strict rule, `steady_state_violations(ref, cur)`, against the lap-1 end. Any violation fails: Node count `!=`, orphans `>`, `abs(objects drift) > 64`, `static_mem drift > 4 MiB`, hosts `!= 0`, root children / effects / route / settings listeners changed. |
| **Sensitivity** | none | New case `014_steady_state_sensitivity` (below). |
| **Lap-end HOME sample timing** | Taken 2 frames after RESULTS → HOME | Taken at **feel quiescence**. The test waits (bounded at 5 s) until `FeedbackAdapter.owned_count() == 0`, then 2 frames, then **asserts** quiescence was reached. A presentation burst (Results WIN confetti, the Home ceremony REWARD pickup) is a transient Node the adapter frees within its ceiling (≤ 1.3 s). One caught mid-flight is timing noise; a leaked emitter outlives adapter ownership and is still counted. Added after battery run 1 (§5.1). Measured wait ≈ 0.71 s. |

Case 014 builds synthetic samples from the **real** lap-1 end sample. It asserts the rule fails exactly once for each of:
- nodes +1;
- nodes −1;
- orphans +1;
- objects ±65;
- static memory +4 MiB+1 B;
- GameplayHost +1;
- route listener +1.

It also asserts the rule holds at exactly +64 objects / +4 MiB and for an identical sample. No current number (254 / 58) is hard-coded anywhere, nothing is skipped or excluded by name, and no warning is suppressed.

## 3. MetaRewardFeel lifecycle correction (`scripts/ui/feel/meta_reward_feel.gd`)

Pattern: Option A, a lifetime-safe static runner.

- `_play` keeps its guards. For an in-tree Control target it calls `static func _settle_then_request(weakref(self), child, intent, target, key)`; for any other target it calls `_request(...)` directly, as before.
- The static coroutine runs the **same** loop: at most `SETTLE_FRAMES` = 8 awaits on `tree.process_frame`, stopping when the rect stops moving, and aborting if the target is freed or leaves the tree.
- Afterwards it requests through the coordinator **only if `weakref.get_ref()` still returns it**.
- A static function has no instance, so a suspended wait can never resume "as" a freed coordinator. Nothing keeps the coordinator alive: no strong reference, no autoload, no helper node, no listener.
- `_request` is the former tail of `_play`, unchanged: `feel.play(intent, target, key)`, the log entry, and the FULL-only native settle on REWARD / MAJOR_REWARD.
- Trigger seams, intents, one-shot keys, target selection, settle-frame behaviour, Reduced policy, grants, save and navigation are all unchanged.

New permanent suite `tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd`. It runs the real app with the real F008 Gift-milestone ceremony seam:

| Case | Proves |
|---|---|
| l01 | Teardown happens with the popup kept moving for 2 frames, so the wait has resumed and suspended again, and then **inside the same `process_frame` emission, ahead of the queued resume**. Results: no crash; app root and MetaRewardFeel freed, not kept alive; zero plugin work; tree Node count back to the pre-boot value; no orphan Node; the reloaded save has identical reward / Gift / pack / collection truth; the milestone is still unclaimed. |
| l02 | The ceremony popup (the target) closes mid-settle while the coordinator lives: no request, the key is not consumed, zero plugin work, nothing owned, truth unchanged. |
| l03 | A live target keeps the shipping behaviour: exactly one `[F008, REWARD, c005f008:gift:gift_ms:c0:m10, HeroArt]`, one 8-particle pickup burst, no replay. |
| l04 | Static guard: every `await` in the file sits in a `static func`, and the coordinator is reached through `weakref(self)` / `.get_ref()`. |

Before / after:
- unmodified code: warning printed once, l04 FAIL;
- fixed code: **PASS 4/4, exact-warning count 0**.

## 4. M55 long-session stability (final test, 3 consecutive runs, no substitution)

Final `tests/m55_long_session.gd` (including the quiescence sampling), run three times in a row in TEMP:

| Run | Exit | Result | exact-warning | SCRIPT ERROR | Lap-1 WARM-UP delta (Nodes / Objects / static) | Lap 2 vs lap 1: Nodes / orphans / Objects / static |
|---|---|---|---|---|---|---|
| 1 | 0 | PASS | 0 | 0 | +34 { "AppRoot": 34 } / +147 / +57649087 B | +0 / +0 / +58 / +462764 B |
| 2 | 0 | PASS | 0 | 0 | +34 { "AppRoot": 34 } / +147 / +57649087 B | +0 / +0 / +58 / +462764 B |
| 3 | 0 | PASS | 0 | 0 | +34 { "AppRoot": 34 } / +147 / +57649087 B | +0 / +0 / +58 / +462764 B |

- Every run: case 014 sensitivity rows all `ok` (the rule fails on nodes ±1, orphans +1, objects ±65, static +4 MiB+1 B, host +1, listener +1, and holds at the bounds).
- The lap-end HOME sample waited ≈ 0.71 s for feel quiescence.
- The three runs are identical in every reported number.
- The same test in the final battery (§5) also PASSed, with identical steady-state numbers (+0 / +0 / +58 / +462764 B). Its recorded (not asserted) lap-1 warm-up Object delta was +151 instead of +147.

**Earlier sequence, disclosed.** Before the quiescence change, three consecutive runs of the then-current test PASSed: lap 2 vs lap 1 objects +62 / +59 / +58, static +3.6 MB / 0.47 MB / 0.46 MB. The first full battery's M55 run then FAILed (§5.1). Per the prompt, I fixed the test and **restarted** the 3-run sequence; the table above is that restarted sequence.

## 5. Final clean Phase 4 battery

### 5.1 First battery run (disclosed): FAIL

- All suites PASS except `m55_long_session`.
- Lap-1 end sample: `nodes +35 { "Spark": 1, "AppRoot": 34 }`. Lap 2 vs lap 1: nodes **+1**, so the exact-Node rule failed.
- The single extra Node was a **Spark burst emitter still in flight under the Spark autoload** when the sample was taken. The adapter frees it within its tier ceiling, so this was sampling-timing noise, not a leak. The Phase 4 / baseline count of 254 (219 + 35) likely contained the same transient.
- Fix: quiescent sampling (§2). Then the 3-run sequence was restarted (§4) and the whole battery rerun.
- Also in that run, the Phase 4 focused suite counted 5 injected `explode` errors instead of 4. All 5 came from the announced FaultySpark in t05: one more Spark burst fell inside its window. The suite PASSed, and the final run shows 4 again.

### 5.2 Final battery run: all PASS

TEMP worktree, Godot 4.7.2 headless. "serr" counts lines containing `SCRIPT ERROR`. Every non-zero count is a deliberate, announced spy-plugin fault injection, with the same injected counts as the Phase 4 log; the announcing line is counted too.

| Suite | Exit | serr | Result | Note |
|---|---|---|---|---|
| `m43_c005f_phase4_qa_r01_feel_lifecycle` | 0 | 0 | M43-C005F-PHASE4-QA-R01 feel lifecycle: PASS (4/4 cases, 0 fail) | NEW (QA-R01) |
| `m43_c005f_phase4_terminal_home_micro` | 0 | 5 | M43-C005F-PHASE4 terminal bridge + Home micro feel: PASS (19/19 cases, 0 fail) | serr: 4 announced injections + the announcing case title |
| `m43_c005f_phase3_meta_rewards_acquisition` | 0 | 2 | M43-C005F-PHASE3 meta rewards + acquisition feel: PASS (15/15 cases, 0 fail) | serr: 1 announced injection + announce line |
| `m43_c005f_phase2_r01_earned_pack_runtime` | 0 | 4 | M43-C005F-PHASE2-R01 earned pack runtime: PASS (22/22 cases, 0 fail) | serr: 3 announced injections + announce line (incl. R02 h* cases) |
| `m43_c005f_phase1_foundation` | 0 | 2 | M43-C005F-PHASE1 foundation: PASS (23/23 cases, 0 fail) | serr: 1 announced injection + announce line |
| `m43_c005f_phase2_results_pack_feel` | 0 | 7 | M43-C005F-PHASE2 results + pack feel: PASS (22/22 cases, 0 fail) | serr: 6 announced injections + announce line |
| `m43_master_c005f_feel` | 0 | 0 | M43 master C005F feel evidence: PASS (10/10 cases, 0 fail) |  |
| `m43_c001a_results_foundation` | 0 | 0 | M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail) |  |
| `m43_c001b_won_results_visual` | 0 | 0 | M43-C001B WON results visual evidence: PASS (11/11 cases, 0 fail) |  |
| `m43_c001r_c001_results_momentum` | 0 | 0 | M43-C001R-C001 results momentum evidence: PASS (40/40 cases, 0 fail) |  |
| `m43_c005_c006_standard_pack_presentation` | 0 | 0 | M43-C005-C006 V02 standard pack interactive opening evidence: PASS (21/21 cases, 0 fail) |  |
| `m43_c005_c007_premium_pack_presentation` | 0 | 0 | M43-C005-C007 premium pack presentation evidence: PASS (19/19 cases, 0 fail) |  |
| `m43_c005_c006_owner_review_harness` | 0 | 0 | M43-C005-C006 owner review harness smoke: PASS (14/14 cases, 0 fail) |  |
| `m43_c005_c007_premium_owner_review_harness` | 0 | 0 | M43-C005-C007 premium owner review harness smoke: PASS (11/11 cases, 0 fail) |  |
| `m43_c005_c008_pack_commit_transaction` | 0 | 0 | M43-C005-C008 pack commit transaction evidence: PASS (27/27 cases, 0 fail) |  |
| `m43_c005_c009_card_state_celebration` | 0 | 0 | M43-C005-C009 card state celebration evidence: PASS (25/25 cases, 0 fail) |  |
| `m43_master_c005_meta_ceremonies` | 0 | 0 | M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail) |  |
| `m43_master_c005r_gift_micro_progress` | 0 | 0 | M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail) |  |
| `m43_master_c007_collection` | 0 | 0 | M43 master C007 Collection evidence: PASS (13/13 cases, 0 fail) |  |
| `m43_master_c007r_pity` | 0 | 0 | M43 master C007R pity evidence: PASS (9/9 cases, 0 fail) |  |
| `m54_collection_set_master_exactly_once` | 0 | 0 | M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS |  |
| `m43_master_c009_daily` | 0 | 0 | M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail) |  |
| `m43_master_c010_meta` | 0 | 0 | M43 master C010 meta evidence: PASS (12/12 cases, 0 fail) |  |
| `m43_master_c011_c014` | 0 | 0 | M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail) |  |
| `m39_v02_atomicity` | 0 | 0 | M39 V02 atomicity/hardening evidence: PASS |  |
| `m39_v03_full_surface` | 0 | 0 | M39 V03 full-surface evidence: PASS |  |
| `m39_v04_integration` | 0 | 0 | M39 V04 integration evidence: PASS |  |
| `m39a_economy_core` | 0 | 0 | M39 Phase A evidence: PASS |  |
| `m39d_daily_collection` | 0 | 0 | M39 Phase D evidence: PASS |  |
| `m39e_full_matrix` | 0 | 0 | M39 Phase E evidence: PASS |  |
| `m40_save_system` | 0 | 0 | M40 save system evidence: PASS |  |
| `m40_v02_safety` | 0 | 0 | M40 V02 safety evidence: PASS |  |
| `m40_v03_canonical` | 0 | 0 | M40 V03 canonical evidence: PASS |  |
| `m40_v04_bootstrap` | 0 | 0 | M40 V04 bootstrap evidence: PASS |  |
| `m41_settings` | 0 | 0 | M41 V01 settings evidence: PASS |  |
| `m42_home` | 0 | 0 | M42 home evidence: PASS |  |
| `m42_navigation` | 0 | 0 | M42 navigation evidence: PASS |  |
| `m42_home_composition` | 0 | 0 | m42_home_composition: 9/9 cases, 0 failures |  |
| `m42_home_v04` | 0 | 0 | m42_home_v04: 18/18 cases, 0 failures |  |
| `m42_home_v05` | 0 | 0 | m42_home_v05: 13/13 cases, 0 failures |  |
| `m42_home_v06` | 0 | 0 | m42_home_v06: 13/13 cases, 0 failures |  |
| `m42_home_v07_safe_area` | 0 | 0 | m42_home_v07_safe_area: 9/9 cases, 0 failures |  |
| `m42_opening` | 0 | 0 | M42 opening evidence: PASS |  |
| `m42_assets` | 0 | 0 | M42 assets evidence: PASS |  |
| `m42_c002_scrubby_scale` | 0 | 0 | m42_c002_scrubby_scale: 7/7 cases, 0 failures |  |
| `m42_c003_scrubby_animation` | 0 | 0 | m42_c003_scrubby_animation: 18/18 cases, 0 failures |  |
| `m43_c002_c001_popup_modal_pause` | 0 | 0 | M43-C002-C001 popup / modal / Pause foundation evidence: PASS (23/23 cases, 0 fail) |  |
| `m43_c003_c001_acquisition` | 0 | 0 | M43-C003-C001 acquisition evidence: PASS (34/34 cases, 0 fail) |  |
| `m43_c004_c001_fail_need_a_hand` | 0 | 0 | M43-C004-C001 fail / need-a-hand evidence: PASS (40/40 cases, 0 fail) |  |
| `m30_completion_authority` | 0 | 0 | M30 completion authority: PASS |  |
| `m30_manual_playtest_smoke` | 0 | 0 | M30 manual playtest smoke: PASS |  |
| `m30_transaction_safe_retry` | 0 | 0 | M30 transaction-safe retry: PASS |  |
| `m43_r15_owner_remediation` | 0 | 0 | M43 owner R15 evidence: PASS (18/18 cases, 0 fail) |  |
| `m43_r15_001_r01_sequential_unlock` | 0 | 0 | SB-M43-R15-001-R01 sequential unlock: PASS (14/14 cases, 0 fail) |  |
| `m55_economy_release_regression` | 0 | 0 | M55 ECONOMY RELEASE REGRESSION: PASS |  |
| `m55_long_session` | 0 | 0 | M55 LONG SESSION: PASS | corrected warm-up model |
| `m55_core_chaos` | 0 | 0 | M55 CORE CHAOS: PASS |  |
| `m55_heart_900_authority` | 0 | 0 | M55 HEART 900 AUTHORITY: PASS |  |
| `m55_c002_timed_2x_anti_rollback` | 0 | 0 | M55-C002 TIMED 2X ANTI-ROLLBACK: PASS |  |
| `m43_master_c006_shop` | 0 | 0 | M43 master C006 Shop evidence: PASS (11/11 cases, 0 fail) |  |
| `m43_master_c008_robots` | 0 | 0 | M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail) |  |
| `cp04_remote_content_runtime` | 0 | 0 | CP04 remote content runtime evidence: PASS (28/28 cases, 0 fail) |  |
| `cp05_remote_content_cache` | 0 | 0 | CP05 remote content cache evidence: PASS (15/15 cases, 0 fail) |  |
| `run_tests` | 0 | 0 | RESULT: ALL PASS |  |
| headless import (`--import`) | 0 | – | clean | TEMP `project.godot` restored afterwards |
| headless boot (`--quit-after 120`) | 0 | – | clean | only the engine exit notice `resources still in use at exit` |
| `git diff --check` | 0 | – | clean | |

**64 / 64 suites PASS, zero failing suites.** Root `tests/run_tests.gd`: `RESULT: ALL PASS`. The M42 composition / V04–V07 safe-area / Scrubby suites print `N/N cases, 0 failures`; their logs were read.

**External log scan** over every final-battery log, the 3 M55 runs and the lifecycle suite:
- `Resumed function '_play()' after await, but class instance is gone`: **0 occurrences**;
- any `class instance is gone`: **0**.

### 5.3 Phase 4 product freeze (D)

Not touched:
- `main.gd` (nav-first F010, WON-only SMALL bridge, no LOST celebration);
- `home_micro_feel.gd` (tracked fields, MICRO-only, 6 % pulse, max two serialized, no Spark, Reduced).

`m43_c005f_phase4_terminal_home_micro` still passes 19/19.

### 5.4 Scope

Changed files:
- `tests/m55_long_session.gd`
- `scripts/ui/feel/meta_reward_feel.gd`
- `tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd` (NEW)
- this log

Zero diff in: Remote Content / R2, LevelData / supply / VOID, export, Level Factory, economy / reward values, Results / Home layout, packs, Gift / Daily, root `TASKS.md`.

All temporary probes are deleted, and none is committed:
- the M55 census copy;
- the MetaRewardFeel print instrumentation, reverted byte-identical before the fix;
- the lifecycle timing probes.

## 6. Owner Desktop final sync

- Pushed with a normal (non-force) push from the TEMP worktree to `main`.
- The Desktop is then synced non-destructively with `fetch` + `merge --ff-only`.
- The QA-created TEMP worktree is removed.
- HEAD == `origin/main`, 0/0, and the unchanged owner `project.godot` hash are reported in the hand-off message. This log is part of the commit, so it cannot contain its own final SHA.

Final state: `AWAITING_GPT_M43_C005F_PHASE4_QA_R01_REAUDIT`
