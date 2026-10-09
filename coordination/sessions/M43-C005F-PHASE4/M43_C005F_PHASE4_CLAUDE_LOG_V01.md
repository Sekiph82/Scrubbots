# M43-C005F-PHASE4 — Gameplay→Results + Home State-Change Micro Feel — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE4/M43_C005F_PHASE4_MASTER_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE4/M43_C005F_PHASE4_AUDIT_CRITERIA_V01.md`
- Scope: `SB-M43-C005F-010` and `SB-M43-C005F-012` only. F007, F011 and F015 were not executed.
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `bf4d6264c86191c5d22e4842be1bd9692247a0e8` (`origin/main`)
- Final SHA: the commit that adds this log. Implementation, tests, evidence and this log are in one commit; parity is reported in the hand-off.
- Root `TASKS.md`: not edited.

## 0. Gate 0 — persistent Desktop sync (before implementation)

| Item | Value |
|---|---|
| Desktop HEAD at session start | `cbb1592d` |
| `origin/main` after `git fetch --prune origin` | `bf4d6264` |
| Ahead / behind | 0 / 2 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked files | 2616 (owner `.mcp.json`, addon `.uid` / `.import` files, local art) |
| Stashes | 2 (untouched) |
| Worktrees | three Codex worktrees + one earlier Claude scratch worktree (untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Reconcile: the 2 incoming commits touched only `TASKS.md` and `coordination/sessions/M39-C003/CHATGPT_STRICT_AUDIT_V01.md`. Neither overlaps a dirty file. `git merge --ff-only origin/main` succeeded, with no stash, reset, clean, restore or force. Result: Desktop HEAD = `bf4d6264` = `origin/main`, **0/0**. All dirty and untracked owner files were retained.

Implementation and every Godot run used only a clean TEMP worktree, created after Gate 0 with `git -C "C:/Users/sekip/Desktop/ScrubBots" worktree add --detach "<TEMP>" origin/main`. Every TEMP command used an absolute `git -C "<TEMP>"` / `godot --path "<TEMP>"` path. `--import` rewrote the TEMP copy of `project.godot`, so that copy was restored with `git -C "<TEMP>" checkout -- project.godot`, after the absolute target path was printed. No such command ran against the Desktop. A second clean TEMP worktree at `bf4d6264` was created the same way for the baseline comparison in §4.2. Its own `project.godot` was restored the same way after `--import`, and the worktree was removed afterwards.

## 1. F010 — Gameplay-complete → Results bridge

Seam (unchanged authority): `ProductionGameplayHost.get_completion().terminal_reached` → `main.gd::_bind_terminal()` → `nav.on_gameplay_terminal(...)` → RESULTS route → ResultsScreen.

Change (`scripts/app/main.gd`):

```gdscript
completion.terminal_reached.connect(func(status, _detail):
	if host == _gameplay_host and nav.on_gameplay_terminal(nav.attempt_id(), status, int(host.progression_level)):
		_terminal_bridge(host, String(status)))
```

- **Navigation first, always.** `nav.on_gameplay_terminal(...)` is called exactly as before, with no await, timer or callback. The bridge runs only *after* nav has accepted the terminal and returned, so Results is already on screen. If nav refuses a duplicate, stale or late signal, there is no bridge either.
- **`_terminal_bridge`** makes one call: `feel.play("SMALL", <HUD robot portrait>, "c005f010:a<attempt>:L<level>")`. The adapter defers all plugin work, so a plugin failure cannot reach this frame. The one-shot key comes from the authoritative attempt id, so a re-show or refresh can never replay it.
- **Target:** the gameplay HUD's robot portrait (`GameplayScreen.get_profile_portrait()`, a new 2-line getter). It is an existing HUD node and stays visible under the Results dim. It sits top-left, away from the Results robot where F003 confetti plays. No overlay was created.
- **WON only.** F003 owns the Results WIN confetti, and the bridge is not a WIN. A LOST terminal gets no celebratory spark: LOST makes zero bridge requests, which satisfies "at most one". LOST still uses the same authority and navigation path.
- **Reduced:** the adapter maps SMALL to its REDUCED row, so the request is logged and the key consumed, with zero plugin work. Results stays immediate.

## 2. F012 — Home state-change micro feel

New `scripts/ui/feel/home_micro_feel.gd` (RefCounted, ephemeral, owned by HomeScreen). HomeScreen changed in three places: preload/var, a `set_feedback()`/`get_micro_feel()` pair, and one `observe` call at the end of `refresh()`. `main.gd` hands Home the same app adapter (`_home.set_feedback(feel)`).

- **Refresh is never a trigger.** `refresh()` passes the view model Home just built (`HomeViewModel.build`) to `observe()`, but only while Home is visible in the tree. A hidden refresh, for example during gameplay or Results, does not move the baseline.
- **Snapshot** (memory only, never saved): `completed_levels`, `robot_can_unlock`, `win_streak`. The first usable visible render becomes the baseline, with zero effect. A new HomeScreen (cold boot or reconstruction) starts a new baseline.
- **Deltas → existing targets**, in priority order:
  - frontier advanced → `HomeJourneyStrip` (`PlayButton` if the strip is hidden);
  - Bot Parts became unlockable (false→true) → `ProfileBotParts` meter;
  - Win Streak went up → the current Win Streak track gift `TrackGift<n>`.
- **Coalescing:** the dominant delta is answered at once. At most one more follows, serialized after the first bump ends (0.36 s), so there are never more than two events. A streak drop on a loss, or Bot Parts staying unlockable, triggers nothing.
- **Intent: MICRO only.** MICRO has a particle ceiling of 0, so there is no Spark, and GFF's punch never drives a Control. FULL adds one native sine scale bump 1.0 → 1.06 → 1.0 over 0.36 s on the target. A newer bump on the same target replaces the older one, and the bump always restores scale 1. There is no idle loop and no persistent node.
- **Deliberately not tracked:**
  - Heart count or regen clock, Scrub Bucks, badges, layout, modal state;
  - **Gift Meter progress and the claimable badge.** F008 owns Gift milestones and claims, and Results F004 owns the committed reward rows, so Home never re-celebrates them.
  - Remote content: an identical refresh leaves the three values unchanged, so it answers nothing.
- **Reduced:** values render normally. `feel.play` hits the REDUCED row, so there is zero plugin work, and no native bump runs.

Home hierarchy: the bump is a 6 % scale pulse on an existing element, once per real progression change. It adds no node, colour or layout change. See §5 for the owner-review assessment.

## 3. Files

| File | Change |
|---|---|
| `scripts/app/main.gd` | F010 bind (nav first, then `_terminal_bridge`); `_home.set_feedback(feel)` |
| `scripts/ui/gameplay_screen.gd` | `get_profile_portrait()` getter |
| `scripts/ui/home/home_screen.gd` | HomeMicroFeel var, `observe` in `refresh()`, `set_feedback` / `get_micro_feel` |
| `scripts/ui/feel/home_micro_feel.gd` | NEW — F012 coordinator |
| `tests/m43_c005f_phase4_terminal_home_micro.gd` | NEW — focused Phase 4 suite (19 cases) |
| `tests/tools/c005f_phase4_capture.gd` | NEW — runtime evidence tool (not shipping) |
| `coordination/sessions/M43-C005F-PHASE4/evidence/` | runtime captures + `.gdignore` |
| this log | NEW |

Not touched: `scripts/content_runtime/**`, RemoteContentManager, `data/config/**`, LevelData, supply, VOID, export, Level Factory, ResultsScreen, FeedbackAdapter, MetaRewardFeel, pack, Collection, Gift, Daily and acquisition code, root `TASKS.md`.

## 4. Validation

All runs used the TEMP worktree after `--import`, Godot 4.7.2 headless. The table below is the **final** run, made after the last code change (§4.3). "serr" counts lines containing `SCRIPT ERROR`. Every non-zero count is a deliberate, announced spy-plugin fault injection, which matches the Phase 3 QA-R01 baselines (3 / 6 / 1 / 1 injected errors).

### 4.1 Suites

| Suite | Exit | serr | Result | Note |
|---|---|---|---|---|
| `m43_c005f_phase4_terminal_home_micro` | 0 | 5 | M43-C005F-PHASE4 terminal bridge + Home micro feel: PASS (19/19 cases, 0 fail) | serr 4 announced fault injection (+1 = the announcing case title) |
| `m43_c005f_phase3_meta_rewards_acquisition` | 0 | 2 | M43-C005F-PHASE3 meta rewards + acquisition feel: PASS (15/15 cases, 0 fail) | serr 1 announced fault injection (+1 announce line) |
| `m43_c005f_phase2_r01_earned_pack_runtime` | 0 | 4 | M43-C005F-PHASE2-R01 earned pack runtime: PASS (22/22 cases, 0 fail) | serr 3 announced fault injection (+1 announce line) |
| `m43_c005f_phase1_foundation` | 0 | 2 | M43-C005F-PHASE1 foundation: PASS (23/23 cases, 0 fail) | serr 1 announced fault injection (+1 announce line) |
| `m43_c005f_phase2_results_pack_feel` | 0 | 7 | M43-C005F-PHASE2 results + pack feel: PASS (22/22 cases, 0 fail) | serr 6 announced fault injection (+1 announce line) |
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
| `m55_long_session` | 1 | 0 | M55 LONG SESSION: FAIL (2) | **PRE-EXISTING**: identical 2 FAILs on clean baseline `bf4d6264`, see §4.2 |
| `m55_core_chaos` | 0 | 0 | M55 CORE CHAOS: PASS |  |
| `m55_heart_900_authority` | 0 | 0 | M55 HEART 900 AUTHORITY: PASS |  |
| `m55_c002_timed_2x_anti_rollback` | 0 | 0 | M55-C002 TIMED 2X ANTI-ROLLBACK: PASS |  |
| `m43_master_c006_shop` | 0 | 0 | M43 master C006 Shop evidence: PASS (11/11 cases, 0 fail) |  |
| `m43_master_c008_robots` | 0 | 0 | M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail) |  |
| `cp04_remote_content_runtime` | 0 | 0 | CP04 remote content runtime evidence: PASS (28/28 cases, 0 fail) |  |
| `cp05_remote_content_cache` | 0 | 0 | CP05 remote content cache evidence: PASS (15/15 cases, 0 fail) |  |
| `run_tests` | 0 | 0 | RESULT: ALL PASS |  |
| headless boot (`--quit-after 120`) | 0 | 0 | clean | only the engine exit notice `resources still in use at exit` |
| `git diff --check` | 0 | – | clean | |

**62 / 63 suites PASS. `m55_long_session` FAILs, and that failure is pre-existing (§4.2).** Root `tests/run_tests.gd`: `RESULT: ALL PASS`. The M42 Home composition, V04–V07 safe-area and Scrubby suites print `N/N cases, 0 failures` instead of a PASS word. Their logs were read: every one has 0 failures.

### 4.2 Disclosed: the `m55_long_session` FAIL is pre-existing (not Phase 4)

`m55_long_session` was not in the Phase 3 / QA-R01 closure list. I therefore ran it on a **clean baseline worktree at `bf4d6264`**, properly `--import`ed, with its `project.godot` restored in that worktree only:

| Check | Baseline `bf4d6264` | Phase 4 |
|---|---|---|
| HOME Node count after lap 1 | 219 → 254 **FAIL** | 219 → 254 **FAIL** (identical) |
| lap-1 Object drift (limit 64) | 157 **FAIL** | 162 / 162 / 166 over three runs **FAIL** |
| lap-2 Object drift | 58 ok | 58 ok (identical) |
| steady state: lap-2 Home Node / orphan == lap 1 | 254/0 ok | 254/0 ok |
| steady state: lap-2 Object / static memory | 58 / ~462 KB ok | 58 / ~462 KB ok |
| `Resumed function '_play()' after await, but class instance is gone` (`meta_reward_feel.gd:148`) | present | present |

- Both FAIL lines and the MetaRewardFeel await warning exist on clean `origin/main`.
- Phase 4 adds no node and no per-cycle growth: lap 2 and the steady-state checks are identical to baseline.
- The lap-1 one-time Object warm-up varies run to run (162–166 against 157). It includes the new HomeMicroFeel instance and first-use objects such as the first SMALL `spark` burst, and it does not grow on lap 2.
- I did not repair the baseline failure here, because it is outside F010/F012 scope.

### 4.3 First-run failures (disclosed)

1. **Focused suite, first runs** — the test had problems, the production code did not. All were fixed in the test only:
   - two GDScript type-inference parse errors in the new test;
   - the economy snapshot comparison included the per-save pack RNG seed, which is drawn when a save is created, differs on every boot and is not terminal truth;
   - the static check forbade `nav.`, but the bridge legitimately reads `nav.attempt_id()`; it now forbids `nav.go` / `on_gameplay_terminal`;
   - the Gift case assumed one milestone, but 50 SB reaches the 10 and 50 milestones; it now walks both F008 ceremonies.
2. **First full regression** — `m55_long_session` FAIL, investigated in §4.2 and pre-existing.
   - That investigation found that HomeMicroFeel kept references to finished native Tweens (at most one per target). It now drops each Tween when the bump ends.
   - After this fix I reran the focused suite, `m55_long_session`, `m42_home`, `m42_navigation`, Phase 1 and root `run_tests`, then the entire list above as the final run.
3. **Evidence tool, first two captures**
   - The level drive was synchronous, so the first frame after the terminal carried a multi-second delta. The ≤0.32 s SMALL sparks, and even the Results WIN confetti, expired before they were drawn.
   - A runtime probe confirmed four live `spark` emitters at the HUD portrait centre (131,114), z 100, in the app viewport.
   - The tool now yields a frame every 40 ticks and shoots 2 frames after the terminal. All captures were regenerated.

### 4.4 Scope isolation

Changed: only the files in §3. Zero diff under:
- `scripts/content_runtime/`, `data/`, LevelData, supply, VOID, export, `level_factory/`;
- ResultsScreen, FeedbackAdapter, MetaRewardFeel;
- pack, Collection, Gift, Daily and acquisition code;
- root `TASKS.md`.

## 5. Runtime evidence (real shipping paths, real plugins)

Tool: `godot --path . -s res://tests/tools/c005f_phase4_capture.gd` (needs a rendering driver). Real app (`main.tscn`) at 1080×2160 and 1536×2048, FULL and REDUCED:
1. cold-boot Home (baseline);
2. PLAY;
3. Level 1 driven to its **real** WON: supply-plan clicks plus runtime ticks until CompletionController latches it;
4. Results (F010);
5. Results HOME → Home (F012);
6. 10 refreshes;
7. a LOST through the real completion signal → Fail Results.

Feel log printed by the tool (identical at both sizes):

| Mode | F010 bridge (WON) | F010 (LOST) | F012 Home micro log |
|---|---|---|---|
| FULL | `[SMALL, c005f010:a1:L1]` | none | `[frontier, HomeJourneyStrip]`, `[win_streak, TrackGift1]` |
| REDUCED | `[SMALL, c005f010:a1:L1]` (REDUCED row, zero plugin work) | none | same two deltas observed; no plugin work, no native bump |

What the captures show:
- **WON (01):** FULL shows four small white sparks on the dimmed HUD robot portrait (top-left), with Results opening over it unchanged. REDUCED shows the same frame with no sparks.
- **Home after the change (04 / 04b):** the accepted Home layout with the new frontier on the Journey strip and the streak marker on track gift 1. The 6 % bump is not visible as a layout change in a still frame.
- **After 10 refreshes (05):** same Home state; the feel log is unchanged, so nothing replayed.

Files (24 JPEGs, ~16 MB, `.gdignore`):
- `1080x2160_full_01_won_terminal_results.jpg`
- `1080x2160_full_02_lost_terminal_results.jpg`
- `1080x2160_full_03_home_before_progression.jpg`
- `1080x2160_full_04_home_after_frontier_change.jpg`
- `1080x2160_full_04b_home_after_streak_marker.jpg`
- `1080x2160_full_05_home_same_state_after_10_refreshes.jpg`
- `1080x2160_reduced_01_won_terminal_results.jpg`
- `1080x2160_reduced_02_lost_terminal_results.jpg`
- `1080x2160_reduced_03_home_before_progression.jpg`
- `1080x2160_reduced_04_home_after_frontier_change.jpg`
- `1080x2160_reduced_04b_home_after_streak_marker.jpg`
- `1080x2160_reduced_05_home_same_state_after_10_refreshes.jpg`
- `1536x2048_full_01_won_terminal_results.jpg`
- `1536x2048_full_02_lost_terminal_results.jpg`
- `1536x2048_full_03_home_before_progression.jpg`
- `1536x2048_full_04_home_after_frontier_change.jpg`
- `1536x2048_full_04b_home_after_streak_marker.jpg`
- `1536x2048_full_05_home_same_state_after_10_refreshes.jpg`
- `1536x2048_reduced_01_won_terminal_results.jpg`
- `1536x2048_reduced_02_lost_terminal_results.jpg`
- `1536x2048_reduced_03_home_before_progression.jpg`
- `1536x2048_reduced_04_home_after_frontier_change.jpg`
- `1536x2048_reduced_04b_home_after_streak_marker.jpg`
- `1536x2048_reduced_05_home_same_state_after_10_refreshes.jpg`

Owner-review assessment:
- **F010** is clearly subordinate to the accepted Results: four fading specks on the HUD, under the dim. The prompt gives F010 no separate owner gate.
- **F012** is a 6 % / 0.36 s scale pulse on existing elements, once per real progression change, with no colour, node or layout change. I consider it below "visibly changes the approved Home hierarchy". The final call belongs to the auditor/owner.

## 6. Publication / Desktop

- One commit on `main` holds the implementation, tests, evidence tool, captures and this log. It was pushed with a normal (non-force) push from the TEMP worktree.
- The Desktop post-push sync (0/0 parity, owner `project.godot` hash) is reported in the hand-off. This log is part of the commit, so it cannot contain its own final SHA.

Final state: `AWAITING_GPT_M43_C005F_PHASE4_STRICT_AUDIT`
