# M43-C005F-PHASE5 — CleaningEffectsController Saltmire Spark A/B Gate — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_MASTER_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_AUDIT_CRITERIA_V01.md`
- Scope: `SB-M43-C005F-011` only. Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `600589cbab61857c3e9834bdd8826aa255995c65` (`origin/main`)
- Final SHA: the commit that adds this log. Harness, tests, evidence and log are in one commit; parity is reported in the hand-off.
- **Production source changed: none.** Shipping stays native-only arm A. Root `TASKS.md` was not edited.

## Technical recommendation (builder; the owner decides)

**`TECHNICAL_PASS / DO_NOT_USE_SPARK_PER_CELL`**

- **Technically, B is safe.** It is bounded and fail-open, and gameplay truth is identical (§4–§6). The extra cost is in the noise.
- **Visually, it adds little and what it adds is the wrong kind of accent (§7):**
  - At normal viewing scale B is barely distinguishable from A.
  - Where it is visible, it is a few plain white discs sitting on top of the arriving Scrubbot and the native blue M31 puff. They read as white smudges over the character, not as a sparkle.
  - On the dense 59×59 board each disc is about one cell, so it becomes a speck.
- **It cannot be tuned in scope.** Fewer particles, a smaller radius, colour or a sparkle shape would each need a FeedbackAdapter API change. The prompt says to STOP rather than change the adapter just for the comparison, so I did not.

The owner can overrule from the matched evidence. Shipping stays A unless a later owner-authorized enablement task says otherwise.

## 0. Gate 0 — persistent Desktop sync

| Item | Value |
|---|---|
| Desktop HEAD at start | `8018d3d7` |
| `origin/main` after `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` | `600589cb` |
| Ahead / behind | 0 / 5 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked / stashes / worktrees | 2616 / 2 (untouched) / 5 incl. Desktop (untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Reconcile:
- The 5 incoming commits touched only `TASKS.md`, the QA-R01 re-audit and the Phase 5 prompt/criteria. None overlapped a dirty file.
- `git merge --ff-only` → `600589cb`, **0/0**. Nothing was stashed, reset, cleaned, restored or forced. The hash was unchanged.

TEMP worktree:
- Created after Gate 0 with `git -C "<Desktop>" worktree add --detach "<TEMP>" origin/main`.
- Every command used an absolute `git -C "<TEMP>"` / `godot --path "<TEMP>"` path.
- `--import` rewrites the TEMP `project.godot`, so that copy was restored with `git -C "<TEMP>" checkout -- project.godot`. That command never ran against the Desktop.

## 1. Arm definitions (no production change)

**Arm A** is the untouched production M31 wiring: `CompleteClearingLoop.authenticated_clear → CleaningEffectsController._on_authenticated_clear`. That means the native puff plus sparkle sprite, cap 24 / Reduced 8, and lifetime 0.30 / 0.18 s.

**Arm B** (`tests/support/cleaning_spark_ab_arm.gd`) is evidence-only. It sits under `tests/`, and no production script references it (static check s01).
- **Attach.** On one live host, it disconnects only the controller's `authenticated_clear` connection and connects one wrapper to the same signal. `detach()` restores the exact A wiring.
- **Native first.** The wrapper calls the **real** `request_effect(target)`.
- **At most one accent.** Only if that native cue was **accepted** and is not Reduced does it make **one** `FeedbackAdapter.play("SMALL", <that cue's own container Node2D>)` request. That container sits at the cell centre `(x+0.5, y+0.5)` in the CleaningFxLayer and is freed with the cue, so no extra anchor node exists.
- **Nothing else gets an accent.** A suppressed, invalid, unbound or disabled native cue gets no accent. A rejected or non-committed clear never reaches the wrapper, because `authenticated_clear` is its only source.
- **Adapter.** A dedicated FeedbackAdapter bound to the app's canonical effects service. Its backends are set through the adapter's **existing** test seam to GameFeelFlow = **absent** and Spark = **the installed Saltmire Spark autoload**.
- **No direct plugin calls.** No new code calls `Spark.burst/at/clear`, and the adapter API is unchanged.
- **Budget.** SMALL is the adapter's smallest particle tier: preset `spark`, **4 particles**, lifetime capped inside the 0.5 s SMALL ceiling, no GFF. MICRO has 0 particles, and 2 particles would need an adapter API change, which was not made.
- **Retry.** The host's own Retry restore (`_on_retry_restored → reset_for_new_attempt`) frees the native cues. `on_attempt_reset()` then cancels the adapter-owned Spark work (`FeedbackAdapter.cancel_all()`, targeted, never a plugin-global clear). This is the B equivalent of the host's presentation reset.

## 2. Harness and evidence tools

| File | Role |
|---|---|
| `tests/support/cleaning_spark_ab_arm.gd` | Evidence-only B arm (above) |
| `tests/m43_c005f_phase5_cleaning_spark_ab.gd` | Permanent focused suite, 13 cases (§5) |
| `tests/tools/m43_c005f_phase5_cleaning_spark_ab.gd` | Rendering A/B capture + numbers tool (§7), not shipping |
| `coordination/sessions/M43-C005F-PHASE5/evidence/` | Captures + `.gdignore` |

Real stacks used:
- **Production Level 1** through `main.tscn`: ProductionGameplayHost, BoardState, CompleteClearingLoop, CleaningEffectsController, CleaningFxLayer, FeedbackAdapter, installed Saltmire Spark.
- **59×59 dense board:** the M29-C002 s8 harness, i.e. a real laid-out ProductionGameplayHost on a 59×59 6-colour stripe TEST fixture at 1080×2160.

Gameplay clock:
- The driver is the only gameplay clock: one `tick(1/60)` per frame, 2x through the runtime speed authority, and greedy front activation as in `m55_long_session`.
- The runtime's own real-time `_process` is stopped **before any frame passes**, followed by `reset_runtime()`, as in M29.
- **Disclosed first-run issue (harness, not production).** In my first version the runtime was stopped only after 4 frames. Those launch frames advanced gameplay by wall-clock delta.
  - A probe showed **arm A alone** shifting its first clear from tick 84 to 81 when every frame was artificially slowed by 3 ms. Targets, order and final truth stayed the same.
  - B's +1-tick differences were that artefact.
  - After the fix, A == A+3 ms stall == B-missing exactly, and every A/B comparison below is exact.

## 3. Baseline protection (A unchanged)

- `git diff origin/main` touches **no** file under `scripts/`, `scenes/`, `data/`, `assets/` or `addons/`.
- Static check s01 asserts:
  - `cleaning_effects_controller.gd`, `production_gameplay_host.gd` and `board_presentation.gd` contain no Spark, FeedbackAdapter or B-arm reference;
  - M31 `MAX_ACTIVE_EFFECTS := 24`, `REDUCED_MAX_ACTIVE := 8`, `NORMAL_LIFETIME := 0.30` and `REDUCED_LIFETIME := 0.18` are unchanged;
  - no production script references the B arm.
- `m31_cleaning_effects_evidence` and `m31_scale_59_effects` pass unchanged (§8).

## 4. Automated proof (focused suite `tests/m43_c005f_phase5_cleaning_spark_ab.gd`, 13/13 PASS)

| Case | Prompt items | Result |
|---|---|---|
| u01 | 1, 2 | Level 1, real host + real Spark: one direct request → 1 native cue + exactly 1 SMALL accent on that cue at the exact cell centre; the plugin spawned exactly 1 burst. Real play, 900 ticks: **77 authenticated clears → 77 native requests → 77 accepted → 77 Spark requests**; peak native 10 (≤ 24); peak adapter-owned 24. |
| u02 | 3 | Out-of-range or −1 index → 0 native, 0 Spark. |
| u03 | 4 | 30 requests in one frame: native cap holds at 24, 6 suppressed, **Spark requests = 24** (suppressed → 0 Spark). |
| u04 | 5 | The arm's only connections are `authenticated_clear` (B wrapper / A restore); there is no dispatch, reservation or claim event path. |
| r01 | 6, 7 | Reduced (canonical setting): the native cue is the single puff sprite; real play gives 53 native cues, **0 Spark requests, 0 bursts**, 0 owned; Reduced native peak 6 (≤ 8). |
| t01 | 8–11 | Before Retry: 10 native cues, 10 owned accents, 10 live emitters. After Retry: **0 / 0 / 0**. The new attempt works again (21 accents); no stale emitter or ownership afterwards. |
| f01 | 12 | Spark missing: same clear sequence (incl. tick), truth and native cue count as A. |
| f02 | 13 | Spark throws (announced injection, exactly one SCRIPT ERROR): same as A. |
| f03 | 14 | Arm detached mid-run ("adapter disabled"): same as A; adapter drained to 0. |
| i01 | 15 | **Level 1 to its real WON, A vs B:** identical 400-clear authenticated sequence including tick timing, identical 3503 ticks to terminal, identical BoardState / slots / supply / terminal / progression / economy. B made 400 Spark requests for 400 accepted native cues (0 suppressed). |
| i02 | 15 | Play 600 ticks → Retry → play 600 ticks: identical pre- and post-Retry clear sequences and final truth. |
| l01 | 16–20 | 59×59 real host, 1x and 2x, 360-tick dense window (below): native ≤ 24 in A and B; identical clear sequence and truth; Spark requests = accepted native cues; emitters ≤ owned ≤ requests; B drains to 0 owned / 0 emitters; tree Node count returns to the pre-run value; no orphan growth. |
| s01 | 21–23 | Adapter-only Spark; the B arm has no `Spark.`, `.burst(`, `.at(`, `.clear()`, `GameFeelFlow`, camera, flash, freeze or time_scale; no shipping wiring (§3). |

## 5. Performance / budget packet

Headless real-host numbers from the focused suite in the **final regression run** (59×59, 360-tick window). Peak owned / emitter counts vary slightly between runs, because the adapter's ownership ceilings are real-time while gameplay is tick-driven. An earlier run gave 2x: 23 / 19.

| Load | Arm | Authenticated clears | Native accepted / suppressed | Native peak | Spark req | Peak owned | Peak emitters | ms/frame (whole loop) | Drain to 0 |
|---|---|---|---|---|---|---|---|---|---|
| 59×59 1x | A | 24 | 24 / 0 | 9 | – | – | – | 6.899 | – |
| 59×59 1x | B | 24 | 24 / 0 | 9 | 24 | 11 | 10 | 6.902 | 488 ms |
| 59×59 2x | A | 81 | 81 / 0 | 18 | – | – | – | 6.986 | – |
| 59×59 2x | B | 81 | 81 / 0 | 18 | 81 | 26 | 22 | 6.937 | 476 ms |
| Level 1 full | A / B | 400 | 400 / 0 | – | 0 / 400 | – | – | – | – |

- Post-drain orphan Nodes: no growth. Tree Node count returns exactly to the pre-run value (l01).
- **Peak extra Nodes in B vs A** equals the peak live emitters: **≤ 22 at 59×59 2x**, all freed within ≤ 0.5 s.
- Loop cost difference: **+0.003 / −0.05 ms per frame** (an earlier run: −0.12 / +0.30), i.e. noise.
- Compared with the existing M31 stress evidence (`M31_PERF` lines in §8), B's synchronous extra work per accepted cue is one `FeedbackAdapter.play()`, which defers its plugin call.
- None of the prompt's hard-safety triggers fired: native ≤ 24 / Reduced ≤ 8, Spark ≤ accepted native, no Spark survives Retry, adapter drains to zero, no orphan growth, gameplay truth identical, no unbounded emitter growth.

Rendering 60 FPS paced A/B numbers (capture tool, real GPU, both sizes; full table in §7): average frame 16.41–16.88 ms for both arms. The frame time is the 60 FPS cap, so there is no measurable B regression.

## 6. Reduced

- A Reduced and B Reduced both keep the native reduced puff (single sprite, cap 8).
- B Reduced performs **zero** Saltmire Spark work: r01 gives 0 requests and 0 bursts, and the capture tool gives Spark req 0, peak owned 0, peak emitters 0.
- The reduced zoom crops (`*_level1_reduced_1x_cue_zoom3x.jpg`) are identical between the two arms.

## 7. Visual A/B evidence

Tool: `godot --path . -s res://tests/tools/m43_c005f_phase5_cleaning_spark_ab.gd` (rendering driver, `Engine.max_fps = 60`).

Each pair uses the **same deterministic gameplay**:
- same level and the same greedy activation;
- one gameplay tick per real-time frame;
- captured at the **same gameplay tick**;
- every pair's whole-run authenticated clear sequence is verified identical.

Files (in `evidence/`):

| File | Content |
|---|---|
| `<size>_<scenario>_A.jpg` / `_B.jpg` | Full frame at the capture tick |
| `<size>_<scenario>_board_strip.jpg` | Board crop over 4 consecutive moments (every 3rd frame ≈ 50 ms apart). **Top row A, bottom row B.** This is the "short clip" form. |
| `<size>_<scenario>_cue_zoom3x.jpg` | 3× nearest-neighbour crop of the cue region from the first two strip frames (**top A, bottom B**), derived from the strip by PIL |

- Scenarios: `level1_1x`, `level1_2x`, `level1_reduced_1x`, `dense59_2x`.
- Sizes: 1080×2160 and 1536×2048.
- 24 tool images plus 6 zoom crops.

Tool numbers (final run):

| Size / scenario | Clears (identical A/B) | Native accepted A / B | Spark req (B) | Peak owned / emitters (B) | Frame ms A / B |
|---|---|---|---|---|---|
| 1080 level1_1x | 35 ✓ | 35 / 35 | 35 | 6 / 5 | 16.43 / 16.66 |
| 1080 level1_2x | 53 ✓ | 53 / 53 | 53 | 10 / 9 | 16.65 / 16.44 |
| 1080 level1_reduced_1x | 35 ✓ | 35 / 35 | **0** | 0 / 0 | 16.42 / 16.41 |
| 1080 dense59_2x | 43 ✓ | 43 / 43 | 43 | 13 / 12 | 16.46 / 16.45 |
| 1536 level1_1x | 35 ✓ | 35 / 35 | 35 | 6 / 5 | 16.41 / 16.42 |
| 1536 level1_2x | 53 ✓ | 53 / 53 | 53 | 10 / 9 | 16.41 / 16.42 |
| 1536 level1_reduced_1x | 35 ✓ | 35 / 35 | **0** | 0 / 0 | 16.65 / 16.88 |
| 1536 dense59_2x | 43 ✓ | 43 / 43 | 43 | 13 / 12 | 16.45 / 16.46 |

**Disclosed:**
- **Stalled first capture run.** The first capture run's 1536×2048 dense59 B pass stalled at ~7 s per frame, and its sequence diverged. That pass was the only affected one; it looked like a windowed-renderer or environment stall. I deleted all captures and reran the whole tool; every pair is matched, as above.
- **Report fix.** The first run's report also compared whole-run Spark requests against clears counted only up to the capture tick (35 vs 33). It now compares whole-run figures (35 = 35).

What the evidence shows (builder reading; the aesthetic call is the owner's):
1. **Normal play scale** (`*_board_strip.jpg`, Level 1, 1x / 2x): A and B are hard to tell apart. In most frames there is no visible difference; in some, a small white blob appears where the Scrubbot finishes.
2. **3× zoom** (`*_level1_1x_cue_zoom3x.jpg`): the B accent is 4 plain white discs, the `spark` preset fading white to transparent. They overlap the arriving Scrubbot and the native blue M31 splash, so the robot is partly covered by white. That reads as white smudge, not sparkle.
3. **Dense 59×59 2x:** cells are about 14 px, so each disc is roughly one cell. It shows as a white speck at the board edge next to the bots and adds no readable information.
4. **Reduced:** A and B are identical.

## 8. Regression

Final battery: TEMP worktree, after all changes, Godot 4.7.2 headless. "serr" counts lines containing `SCRIPT ERROR`. Every non-zero count is an announced, deliberate spy-plugin fault injection.

| Suite | Exit | serr | Result | Note |
|---|---|---|---|---|
| `m43_c005f_phase5_cleaning_spark_ab` | 0 | 2 | M43-C005F-PHASE5 cleaning Spark A/B: PASS (13/13 cases, 0 fail) | NEW. serr: 1 announced injection (f02) + its announce line |
| `m31_cleaning_effects_evidence` | 0 | 0 | M31 cleaning-effects evidence: PASS |  |
| `m31_scale_59_effects` | 0 | 0 | M31 59x59 effects stress: PASS |  |
| `m29_c002_tempo_retune` | 0 | 0 | M29-C002 TEMPO RETUNE: PASS | includes the real-host 59x59 dense window (s8) |
| `m29_presentation_identity_evidence` | 0 | 0 | M29 presentation identity evidence: PASS |  |
| `m29_speed_authority_evidence` | 0 | 0 | M29 speed authority evidence: PASS |  |
| `m29_realtime_movement_smoke` | 0 | 0 | M29 realtime movement smoke: PASS |  |
| `m29_hazard_bot_runtime_smoke` | 0 | 0 | M29 Hazard Bot runtime smoke: PASS |  |
| `m29_exact_slot_origin_evidence` | 0 | 0 | M29 exact slot-origin evidence: PASS |  |
| `m29_input_gate_evidence` | 0 | 0 | M29 input gate evidence: PASS |  |
| `m29_slot_display_sync_evidence` | 0 | 0 | M29 slot display + live sync evidence: PASS |  |
| `m30_completion_authority` | 0 | 0 | M30 completion authority: PASS |  |
| `m30_manual_playtest_smoke` | 0 | 0 | M30 manual playtest smoke: PASS |  |
| `m30_transaction_safe_retry` | 0 | 0 | M30 transaction-safe retry: PASS |  |
| `m43_c005f_phase1_foundation` | 0 | 2 | M43-C005F-PHASE1 foundation: PASS (23/23 cases, 0 fail) | serr: 1 announced injection + announce line |
| `m43_c005f_phase4_terminal_home_micro` | 0 | 5 | M43-C005F-PHASE4 terminal bridge + Home micro feel: PASS (19/19 cases, 0 fail) | serr: 4 announced injections + announcing case title |
| `m43_c005f_phase4_qa_r01_feel_lifecycle` | 0 | 0 | M43-C005F-PHASE4-QA-R01 feel lifecycle: PASS (4/4 cases, 0 fail) |  |
| `m55_long_session` | 0 | 0 | M55 LONG SESSION: PASS |  |
| `m55_core_chaos` | 0 | 0 | M55 CORE CHAOS: PASS |  |
| `run_tests` | 0 | 0 | RESULT: ALL PASS |  |
| headless import (`--import`) | 0 | – | clean | TEMP `project.godot` restored afterwards |
| headless boot (`--quit-after 120`) | 0 | – | clean | only the engine exit notice `resources still in use at exit` |
| `git diff --check` (incl. new files) | 0 | – | clean | |

**20 / 20 suites PASS, zero failing.** Root `tests/run_tests.gd`: `RESULT: ALL PASS`.

M31 baseline stress in the same run (the production controller, unchanged):
- `M31_PERF 1x: 59x59 frames=240 req=9600 cap=24 peak=24 suppressed=9264 spawn+age=20.87 ms (0.0870 ms/frame)`
- `M31_PERF 2x: 59x59 frames=240 req=9600 cap=24 peak=24 suppressed=9432 spawn+age=20.73 ms (0.0864 ms/frame)`

First-run failures, disclosed:
1. **Focused suite run 1: 5 FAIL.** i01 / f01–f03 had ±1-tick clear-timing differences. The cause was the harness launch window described in §2, where gameplay advanced on wall-clock delta, so this was not B. Fixed in the harness, then proven: A == A+3 ms stall == B-missing.
2. **Run 2: 1 FAIL (f03).** The split drive restarted its tick counter at 0. This was a test bug, fixed with an offset.
3. **Run 3:** 13/13 PASS.
4. **Capture tool:** see §7 (stalled first run, report comparison fixed).

## 9. Publication / Desktop

- Pushed with a normal (non-force) push from the TEMP worktree to `main`.
- The Desktop is then synced with `fetch` + `merge --ff-only`.
- The Phase 5 TEMP worktree is removed.
- HEAD == `origin/main`, 0/0, and the unchanged owner `project.godot` hash are reported in the hand-off. This log is part of the commit, so it cannot contain its own final SHA.

Final status: `AWAITING_GPT_M43_C005F_PHASE5_AB_AUDIT_AND_OWNER_DECISION`
