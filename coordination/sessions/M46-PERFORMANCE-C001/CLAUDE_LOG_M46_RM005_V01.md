# CLAUDE_LOG_M46_RM005_V01 — Completion / LOSE proof and WON terminal frame

**Child 1 of `CHATGPT_M46_MASTER_REMEDIATION_V03.md`** (prompt `CHATGPT_M46_RM005_COMPLETION_TERMINAL_FRAME_PROMPT_V01.md`, criteria `..._AUDIT_CRITERIA_V01.md`, frozen V3-F01 / V3-F02 / V3-F07).
Implementer evidence only (E1/E2). Not an audit verdict. Root `TASKS.md` and every `CHATGPT_*` file untouched.

## 0. Environment and provenance (read first)
- Ran in a **Claude Code cloud container (Linux, headless Godot 4.7.2 stable official `ed1daf0bf`)**, not on the owner's Windows checkout `C:\Users\sekip\Desktop\ScrubBots`, which this session cannot reach. All timings are this container's CPU; they are compared with the desktop numbers in the V03 audit by ratio, never presented as desktop or phone evidence. **OWNER_LOCAL_PROJECT_PARITY_OPEN** (the owner's dirty `project.godot` / `main.tscn` were not used or touched). Godot's import step rewrites `project.godot` here (feature-line order, `[audio]` bus line) — that rewrite was discarded with `git checkout -- project.godot` after every run and never committed.
- Branch: the harness requires pushing to `claude/practical-darwin-ndbmxa` (fast-forwarded from `origin/main` `9663c44c`); the prompt names `origin/main`. Merge to `main` is the owner's / ChatGPT's step.
- Zero GitHub Actions, no network, no clone / worktree / reset / clean / force. Scratch < 2 MiB.
- Source commit for this child: **`ce67212c`** (RM006 then built on it; the master log pins the final SHA).

## 1. Profiling before any edit (RM005-01, RM005-03)

### 1.1 Call graph actually traced
`ProductionRuntimeController.tick` → `CompletionController.on_tick` (dirty gate; proof only when dirty) → `CompletionEvaluator.evaluate` (ERROR / WON / in-flight / gated checks, then) → `DeadlockClassifier.classify_runtime` → `ProofState.from_runtime` → `classify`: `ProofKernel.quiesce(root)` → `SolvabilitySolver.search_progress(s1)` → `_search_bounded`: **a second `quiesce(root)`**, then DFS where each popped node expands **all** legal columns through `ProofKernel.apply_placement` (full live-engine rebuild + `_run_to_quiescence` to the end of the cascade) **before** the first child is examined. Each cascade wave calls `BatchTargetClaimEngine.claim_for_slot` → `TargetSelector.select_and_reserve` → `ProductionTargetAccess.is_targetable` (reach/touch mask rebuild per board revision) → `ProductionRoutingSystem.compute_route` (Dijkstra) → `RouteValidator`.
Sibling consumers of the same classifier: `ProductionBoosterAdapter` (`_is_safe`, `_is_safe_probe`, the R05 400 ms sync path and the R06 off-frame worker on a detached copy) and the Need-a-Hand next-start prover (unbudgeted adapter). Completion owns its own `DeadlockClassifier` instance (no object shared with the booster worker; the only shared state is the static mask cache, already locked in R06).

### 1.2 59x59 still-moment completion tick (V3-F01) — measured here, scratch harness reproducing the p21 shape
| Fixture | completion tick | classify | verdict | where the time went |
|---|---|---|---|---|
| stripes 59x59 | **1566.6 / 1710.5 ms** | 1700–1731 ms | STALLED, visited 2, frontier 4 | solver `_run_to_quiescence` 1624–1660 ms (4 child cascades of 30 clears: 262 / 449 / 463 / 486 ms), 5 rebuilds 41.5 ms, read-backs 15 ms, classifier root quiesce 11.5 + 4.4 ms, duplicate solver root quiesce |
| pocket 59x59 (VOID) | **1344.5 / 1390.8 ms** | 1339–1469 ms | STALLED, visited 2, frontier 5 | solver cascades 1266–1389 ms (150 / 351 / 320 / 420 / 25 ms), 6 rebuilds 49 ms |
Perf-probe counts for ONE stripes classification: **120** `target_selection` (1646 ms), **120** `compute_route` (1442 ms; Dijkstra 9.5 ms mean, 1145 ms total), **120** mask builds (153 ms), 120 route-source scans (179 ms). Desktop V03 numbers 2.93–3.30 s are the same work on a slower-per-thread / contended machine (ratio ~1.9–2.0x); this is counted algorithmic work, not GPU or scheduling.
**Root cause:** the progress search needs only *one* child that clears anything (it is popped next and returns PROGRESS_FOUND with visited 2), yet it fully cascaded every sibling, each to the end of its 30-clear cascade.

### 1.3 L1 WON terminal tick (V3-F02) — real booted app, handler-wrapped
Before (this container): cold 211–231 ms, warm 26–28 ms (desktop: 193.66 / 82.70). Per handler: host `_on_terminal_reached` (economy + receipt + save) 3.4–5.2 ms, audio 0.2, haptics 0.01, **`main.gd` route lambda 22 ms warm / 227 ms cold**. Inside the route lambda (temporary instrumentation, reverted): `_results_model` **15–19 ms on every terminal** (= `GameplayLaunchResolver.resolve` → `AppState.playable_catalog()` re-loading and re-validating all 10 builtin levels + supply plans), `ResultsScreen.show_model` cold **210 ms** (`load()` of the 1230x1278 victory pose **73 ms** + 1296x1213 emblem **71 ms**, both lossless `compress/mode=0`, plus reward-row icon loads ~59 ms) vs 2.2 ms warm. L3 (LOST here): cold 108 ms (pose 27 + emblem 37 ms), warm 31 ms. First Results render frame: 5.5–5.8 / 1.2–1.4 ms (L1), 2.5–2.8 / 1.5–1.7 ms (L3): the hitch is the synchronous terminal tick, not the first rendered frame.

### 1.4 Retry sibling (V3-F07)
30 retries on 59x59 stripes: mean 17–20 ms, worst 20–31 ms here (desktop p12 43.46 ms vs cap 50.1). Retry runs no classifier synchronously (it sets `dirty`; the next quiescent tick classifies). Not changed.

## 2. Changes (exact-output only)
1. `SolvabilitySolver` progress search (`GOAL_PROGRESS` only; `solve()` / generation untouched):
   - **deferred children**: a node pushes `{parent, actions, column}` entries in the same reversed order; a child is placed only when popped, so siblings behind a PROGRESS_FOUND are never built;
   - **first-clear probe**: `ProofKernel.apply_placement(state, col, progress_probe=true)` stops the cascade after the first wave that clears (`_run_to_quiescence(..., stop_on_clear)`). Such a child is below `root_active`, so it is popped as PROGRESS_FOUND before any expansion or memo comparison (its key can never be in `visited`), and the progress result carries no trace; 0-clear children are quiescent after the same single wave either way;
   - `search_progress(root, config, root_quiescent)`: the classifier passes its already-quiesced 0-clear root, so the duplicate root rebuild is skipped;
   - `full_progress_cascade` (default false): the pre-RM005 path, kept as the test oracle.
   Divergence analysis: identical `{status, reason, visited, memo_hits, frontier_peak, max_depth_reached, decisions, immediate_clears, root_active}` whenever every legal front placement is accepted by the real M24 transaction (every valid state). Only for a malformed / incoherent kernel (a placement the engine rejects after `legal_action_columns`, or `kernel_incoherent` after the first wave) can `frontier_peak` / a `max_visited` edge differ; the verdict order is unchanged and such a divergence can only turn a would-be DEADLOCK into STALLED/UNKNOWN, **never create a LOSE**.
2. `AppState.playable_catalog()`: the validated builtin `LevelCatalog` is loaded once per AppState (res:// is immutable at runtime; every read is a deep copy; the remote set is re-read on every call; an invalid manifest is not cached).
3. Not changed: completion gating, LOST rule, Need-a-Hand (unbudgeted), 400 ms / 5 s caps, boosters, speed, HUD / popup / Results visuals, audio, saves.

## 3. After (same harness and the new suite)
| Item | Before (here) | After (here) | Desktop V03 |
|---|---|---|---|
| 59x59 stripes still-moment completion tick | 1566–1711 ms | **29.6–54.8 ms** (final suite run 35.8) | 3293 ms |
| 59x59 pocket still-moment completion tick | 1345–1391 ms | **29.4–48.1 ms** (final 30.2) | 2931 ms |
| same-state classify, stripes / pocket | 1700 / 1340–1500 ms | 24–50 / 24–44 ms | |
| route probes / mask builds per classification | 120 / 120 | **1 / 1** | |
| L1 WON terminal tick warm | 26–28 ms | **9.5–17 ms** (`resolve` 15–19 → 0.09 ms) | 82.70 ms |
| L1 WON terminal tick cold | 211–231 ms | 199–211 ms standalone (95–107 ms inside the suite, art partly cached by earlier groups) | 193.66 ms |
| L3 terminal cold / warm | 108 / 31 ms | 88 / 17 ms | |
| 59x59 Retry x30 worst | 28.7–30.5 ms | 20.2–28.7 ms | 43.46 (cap 50.1) |
Remaining 59x59 still-tick cost: two full 3,481-cell live-engine rebuilds (~7 ms each) + one first wave (~11 ms route) + read-backs; further reuse of the classifier's live bundle was not done (identity of reservation / claim counters after a quiesce is not provably equal to a fresh rebuild).

### OWNER_DECISION_REQUIRED (cold first Results only; presented once)
The remaining cold L1 cost (~144 ms texture decode + ~59 ms row icons, first Results of an app session only) is decoding the owner's lossless 1.2k² Results art on first use. Exact options, none implemented:
- **A (keep, default):** one-off cold hitch per app session; warm 9.5–17 ms.
- **B prewarm:** `ResourceLoader.load_threaded_request` of the active robot's victory/help pose + both emblems + row icons at gameplay launch — removes the cold decode from the terminal tick, costs ~6.3 MB RAM per 1.2k² RGBA texture resident during play (~25 MB for both outcomes; ~12.6 MB if only the WON pair) on phones.
- **C re-import as VRAM-compressed / smaller:** changes approved owner art pixels — not allowed without explicit owner approval.

## 4. Test `tests/m46_rm005_terminal_frame_profile.gd` (5 groups, PASS)
Command: `godot --headless --path . -s res://tests/m46_rm005_terminal_frame_profile.gd` → `M46 RM005 TERMINAL FRAME: PASS (5/5 groups)`, exit 0, 110 s (final batch run on the final source).
- **T2 oracle equivalence** (RM005-02): an `OracleRecorder` replaces the classifier inside the real `CompletionEvaluator` and checks EVERY production M27 call against a fresh pre-RM005 oracle (`full_progress_cascade`) on the same reconstructed state, plus direct still-state sweeps: campaign L1 / L2 / L3 (33 evaluator calls, 0 mismatch; L3 reaches a real LOST), L2 with 6 slots, 3 / 4 / 5 supply columns, a searched DEADLOCK (visited 56, memo 50), a depth-5 STALLED through non-progress children, 6-slot STALLED, `max_visited` and `max_depth` UNKNOWN_BOUND, the 59x59 VOID-pocket LOSE state. **129 states, mismatches 0** (STALLED 61, PROGRESSABLE 64, DEADLOCK 2, UNKNOWN_BOUND 2), dict-equal incl. counters.
- **T3 terminal latch** (RM005-02/04): STALLED fixture stays PLAYING; LOSE fixture latches LOST exactly once (DEADLOCK == oracle); pause freezes the verdict; Retry re-arms exactly one more LOST; L1 WON exactly one event, one reward (SB 1000 → 1051), receipt stable after 120 more ticks.
- **T1 59x59 still moment** (RM005-01/03/04): stripes + pocket, p21 play shape, completion tick worst ≤ 400 ms (measured 30–36 ms), the still-moment production verdict == oracle on the same state (oracle 1.4–1.6 s), route probes 1 vs 120, an off-frame booster proof on a worker while the main thread classifies the same state (agree, worker settled).
- **T4 WON terminal tick** (RM005-05): booted app L1 cold + warm with per-handler attribution; cached builtin catalog == a fresh validated `LevelCatalog` load (ids / orders / paths / plans / difficulty / previews), new composite per call; `resolve` ≤ 5 ms (0.09); warm terminal tick ≤ 60 ms (9.5).
- **T5 Retry** (RM005-06): 30 retries on 59x59 worst ≤ 50.1 ms (20.15).

### Sensitivity (RM005-07) — each a temporary source edit, full suite run, restored byte-identical (`cmp`)
| Mutant | Edit | Caught by (exit 1) |
|---|---|---|
| N1 false LOSE | classifier maps PROGRESS_FOUND → DEADLOCK | T2 equivalence + depth-5/6-slot rows, T3 STALLED-PLAYING + L1 WON, T1 "not a LOSE" (8 rows) |
| N2 duplicate terminal receipt | `terminal_reached.emit` twice | T3 LOST-once, retry-once, L1 one event / one reward |
| N3 stale proof memo | classifier returns its first result for every state | T2 searched DEADLOCK / UNKNOWN / pocket / equivalence, T3, T1 |
| N4 +100 ms terminal handler | `OS.delay_msec(100)` in host `_on_terminal_reached` | T4 warm 111.6 ms > 60 |
| N5 wrong RM005 shortcut | deferred child returns PROGRESS_FOUND unplaced | T2 L1/L2/L3 recorder mismatches, DEADLOCK / UNKNOWN rows, T3 |

## 5. Focused regressions on `ce67212c` source (sequential, one Godot at a time, all exit 0)
m27_hazard_bot_solve, m27_generation_retry, m27_scale_59, m30_completion_authority, m30_transaction_safe_retry, m30_manual_playtest_smoke, m39c_boosters, m39_v02_capacity, m39_v03_integration, m39_v04_integration, m39_v04_tornado_inflight, m43_c001a (11/11), m43_c001b (11/11), m43_c001r (40/40), m43_c003 (34/34), m43_c004 (40/40), m44_ftue (23/23), m46_rm002 (8), m46_rm003 (4), m46_rm004 (6), m46_r07, m46_slot_rebuild, m55_core_chaos, cp04 (28/28), cp05 (15/15), cp05_r01 (6/6), cp06 (16/16), m53_first10_difficulty, run_tests (ALL PASS) — 29/29. The final-source re-run and the single full `m46_performance.gd` are in the master log (reserved until after RM006, as the prompt requires).

## 6. Criterion ledger
| Criterion | Status (implementer) | Evidence |
|---|---|---|
| RM005-01 | REPORTED | §1 call graph, counts (120 routes / masks / selections → 1), handler attribution |
| RM005-02 | PASS (E2) | T2 129 states dict-equal, T3 latches |
| RM005-03 | PASS (E2) for V3-F01; warm V3-F02 fixed; **cold Results decode OWNER_DECISION_REQUIRED** | §3 table, §3 options |
| RM005-04 | PASS (E2) | no new per-frame search (proof still gated by dirty + quiescence), oracle/state equality, T1 worker concurrency, T3 exact-once / speed untouched |
| RM005-05 | REPORTED | §1.3 terminal vs first frame vs texture decode; Results / FX / audio code untouched |
| RM005-06 | PASS (E2) | T5 20.15 ms; p12 itself in the master full run |
| RM005-07 | PASS (E2) | N1–N5 |
| RM005-08 | child part done | §5; full 22/22 in master |
| RM005-09 | gates preserved | no LOSE timeout / async terminal, Need-a-Hand untouched, F5 + phone GPU OPEN, zero Actions, TASKS untouched |

Status: **AWAITING_MASTER_RM006**
