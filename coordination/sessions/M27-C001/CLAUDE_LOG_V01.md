# M27-C001 V01 — CLAUDE IMPLEMENTATION LOG

Repository: `Sekiph82/Scrubbots`
Branch: `claude/m27-c001-v01-solvability-9jvis8` (fresh branch off `origin/main`; the prior M26 branch was audited PASS and merged)
Milestone: `M27 — Solvability / Deadlock Engine`
Cycle: `M27-C001 V01` (full continuous milestone)
Engine: Godot **4.7.2** (`4.7.2.stable.official.ed1daf0bf`), GDScript
Status: **AWAITING_AUDIT**

Start SHA (pre-work `origin/main`): `27dbf063e1430cb96e6a3355114ae2293ad0ac75`
Implementation SHA: `3e803d37fea64c99aed527d057b0fb47dd15ebfd`
Log commit SHA: `(this commit)` (separate final commit)

## 0. Governance / scope confirmation

- Repo/branch verified; synchronized with `origin/main` (no `reset --hard`/`clean`/force; no destructive cleanup). The M26-C001 V02 branch was audited PASS and merged, so M27 was started as a fresh change on a new branch off the latest default branch.
- Root `TASKS.md` modified by Claude: **NO** (absent from every commit).
- M28 gameplay screen/layout or lose-screen UI implemented: **NO**.
- Image-generation credits spent: **0** (no image tool invoked).
- M23/M24/M25/M26 authorities weakened: **NO** — zero existing production files modified; M27 only ADDS `scripts/gameplay/solver/*` and reuses the accepted engines unchanged.
- Solution trace / hidden supply queues exposed to player-facing UI: **NO**.
- Implementation commit precedes this separate `CLAUDE_LOG_V01.md` commit.

## 1. Architecture — a proof engine, not a second gameplay engine

M27 answers two questions deterministically without inventing any simplified reachability/
slot/claim/supply rule (master prompt "core architectural rule", audit §B):

```
ProofState (detached canonical data)
  -> ProofKernel  (reconstructs ISOLATED real M24/M25/TargetSelector/Reservation/
                   ColorCandidateIndex/ProductionRoutingSystem/ProductionAccessQuery/
                   RouteValidator/ProductionTargetAccess and drives them)
  -> SolvabilitySolver (deterministic DFS over legal front-batch selections + memo + bounds)
  -> GenerationGate (solver-gated M23 acceptance + deterministic retry)
  -> DeadlockClassifier (read-only runtime classification)
```

The kernel's serial clear schedule (one legal M25 claim -> exact route -> authenticated-
equivalent clear at a time, to quiescence) is a valid legal execution schedule, so a schedule
that completes the board proves solvability. Player placement is the ONLY search choice point
(same-color arbitration, target selection and clearing are all forced/deterministic inside the
real engines), and clearing is monotonic, so branching over which column front to place next is
a complete legal-schedule search.

## 2. Changed files (implementation commit `3e803d3`)

Production (all NEW, `scripts/gameplay/solver/`):
- `proof_state.gd` — detached canonical proof state + deterministic `canonical_key()`.
- `proof_kernel.gd` — legal transition kernel over the reused real engines.
- `solvability_solver.gd` — deterministic DFS search, bounds, trace, replay, greedy driver.
- `generation_gate.gd` — solver-gated generation acceptance + deterministic retry.
- `deadlock_classifier.gd` — read-only runtime classifier.

Tests / evidence (all NEW except the run_tests.gd additions):
- `tests/run_tests.gd` — `_run_m27_solver_tests()` (+59 direct M27 checks).
- `tests/m27_hazard_bot_solve.gd` — real Hazard Bot solvability + trace + replay + hidden-hiding.
- `tests/m27_scale_59.gd` — 59x59 solvable-within-bound + deliberately bounded UNKNOWN stress.
- `tests/m27_generation_retry.gd` — deterministic reject-then-accept report.
- `coordination/sessions/M27-C001/evidence/hazard_bot_solution_trace.json` — committed
  deterministic Hazard Bot solution trace evidence.

## 3. Literal commands + results (this machine, Godot 4.7.2)

```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m27_hazard_bot_solve.gd
godot --headless --path . -s res://tests/m27_scale_59.gd
godot --headless --path . -s res://tests/m27_generation_retry.gd
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd
git diff --check
```

Results:
- `tests/run_tests.gd`: **5312 checks / 2 failures**. The +59 new M27 checks all PASS, and all
  prior M23/M24/M25/M26/M22/M20/M19/M21 checks PASS. The **only** 2 failures are pre-existing and
  environment-only — the level-importer "distinct dot-segment output path" checks — identical on
  the clean start SHA (stash/branch-verified earlier this program at 5193 and 5253 with the same 2
  failures) and unrelated to M27. M27 introduces **zero** new failures.
- `tests/m27_hazard_bot_solve.gd`: **PASS** — real 20x20 Hazard Bot proven SOLVED; trace persisted
  + replays to completion; hidden batches kept hidden.
- `tests/m27_scale_59.gd`: **PASS** — 59x59 solvable within bound + bounded UNKNOWN stress.
- `tests/m27_generation_retry.gd`: **PASS** — deterministic reject-then-accept.
- `tests/m26_hazard_bot_integration.gd`: **PASS** (regression). `tests/m26_scale_59_sanity.gd`: **PASS** (regression).
- `git diff --check`: clean.

### Hazard Bot proof (SB-M27-021/022, audit §K)

- Real level `res://data/levels/m21_level_001_hazard_bot.json`, 20x20, exact per-color totals
  `{0:30, 1:5, 2:298, 3:11, 4:56}`.
- Deterministic generated candidate (gen_seed=1, columns=3, preview=3), conservation-exact (19 batches).
- `status=SOLVED decisions=19 visited=20 memo_hits=0 frontier_peak=21 max_depth=19 elapsed≈11.5s trace_hash=1618197986`.
- Solution consumed every batch via legal FRONT selections only (19 decisions == 19 batches; no preview/hidden-row selection).
- Trace replays to full completion (`final_active=0`); re-solve reproduces identical trace hash + visited.
- Hidden future batches remain hidden through the player-facing M23 surface (`get_preview` ≤ depth, `player_snapshot` count-only) while the solver internally used the full queue.
- Trace persisted at `coordination/sessions/M27-C001/evidence/hazard_bot_solution_trace.json`.

### 59x59 scale (SB-M27-024/034, audit §M/§O)

- Solvable: 59x59 board (3481 cells), a real 7x7 ring-enclosure region (active=49) proven
  `SOLVED decisions=2 visited=3 memo_hits=0 frontier_peak=2 key_bytes=3508`; replays to completion.
  Canonical key ≈ cell-count bytes (no rendered-pixel/scene snapshot in the key).
- Deliberately bounded stress: 11x11 ring region (active=121), `max_visited=3` ->
  `UNKNOWN_BOUND visited=3` (never DEADLOCK; no unbounded search).

### Generation retry (SB-M27-016..018, audit §G/§N)

- Ring 5x5 level, base_seed=101, deterministic proof budget `max_depth=8`, max_attempts=6:
  - attempt 0: effective_seed=101 -> `UNKNOWN_BOUND` (visited 184) — REJECTED;
  - attempt 1: effective_seed=2654435862 -> `SOLVED` (visited 7, decisions 6, trace_hash=2586980231) — ACCEPTED.
- Only the first SOLVED candidate accepted; every candidate conservation-exact; identical inputs
  reproduce the identical accept/reject sequence, accepted attempt and trace hash.
- A genuinely unsolvable supply (enclosed interior, no gate batch) is proven `DEADLOCK` (rejected).

## 4. Task-by-task mapping (SB-M27-001..034)

Code = `scripts/gameplay/solver/`; Unit = `_run_m27_*` in `tests/run_tests.gd`; scripts as named.

- SB-M27-001 solver on gameplay-domain state, not UI Nodes — `proof_state.gd` / `proof_kernel.gd`; Unit `_m27_canonical_key_and_determinism`.
- SB-M27-002 real reachability, not a simplified notion — `proof_kernel.gd` (reuses ProductionTargetAccess/Routing); Unit `_m27_kernel_reachability_equivalence`.
- SB-M27-003 3/4/5 FIFO columns — `proof_state.gd`/`proof_kernel.gd`; Unit `_m27_columns_and_arbitration`.
- SB-M27-004 visible-front-only legal action — `ProofState.legal_action_columns`; Unit `_m27_hidden_supply_not_leaked`.
- SB-M27-005 no early Row2/Row3/hidden selection — `proof_kernel.apply_placement` (front only); Unit `_m27_hidden_supply_not_leaked`.
- SB-M27-006 rightmost-empty placement — reuses `FiveSlotBatchEngine.select_front_batch`; Unit `_m27_kernel_placement_and_quota`.
- SB-M27-007 full-slot rejection, no supply consume — Unit `_m27_kernel_placement_and_quota`.
- SB-M27-008 remaining/committed/WAITING lifecycle — reuses M24; Unit `_m27_kernel_placement_and_quota`.
- SB-M27-009 same-color oldest-placement arbitration — reuses M25 `oldest_capacity_slot`; Unit `_m27_columns_and_arbitration`.
- SB-M27-010 targetability via ProductionTargetAccess/Routing + Railroad — `proof_kernel._attempt_claim`; Unit `_m27_kernel_reachability_equivalence`.
- SB-M27-011 ACTIVE→CLEARED evolution — `proof_kernel._apply_clear`; Unit `_m27_kernel_reachability_equivalence`.
- SB-M27-012 WAITING revival on newly opened corridors — `proof_kernel._run_to_quiescence` (wake); Unit `_m27_kernel_reachability_equivalence` + `_m27_classifier_statuses` (revival).
- SB-M27-013 search legal front choices, not fixed greedy — `solvability_solver._search`; Unit `_m27_search_branch_order_dependence` (greedy fails, search solves).
- SB-M27-014 find a complete clearing/quota sequence — `solvability_solver.solve` SOLVED; Unit `_m27_search_branch_order_dependence`.
- SB-M27-015 deterministic trace, never player UI — `solvability_solver` trace + `_trace_summary`; Unit `_m27_trace_and_bounds` + `_m27_hidden_supply_not_leaked`.
- SB-M27-016 accept generated supply only if SOLVED — `generation_gate.generate_accepted`; Unit `_m27_generation_acceptance_retry`; `m27_generation_retry.gd`.
- SB-M27-017 unsolvable fed back for deterministic retry — `generation_gate` retry loop; Unit `_m27_generation_acceptance_retry`.
- SB-M27-018 preserve seed + outcome, reproducible — `generation_gate.derive_seed` + report; Unit + `m27_generation_retry.gd`.
- SB-M27-019 canonicalize/memoize equivalent states — `proof_state.canonical_key`, solver `visited`/`memo_hits`; Unit `_m27_canonical_key_and_determinism`.
- SB-M27-020 explicit bounds, fail closed → UNKNOWN_BOUND — `solvability_solver` bounds; Unit `_m27_trace_and_bounds`.
- SB-M27-021 real 20x20 Hazard Bot solvable — `m27_hazard_bot_solve.gd`.
- SB-M27-022 persist Hazard trace, hidden batches stay hidden — `m27_hazard_bot_solve.gd` + `evidence/hazard_bot_solution_trace.json`.
- SB-M27-023 rectangular fixtures — Unit `_m27_rectangular_fixtures` (4x6 solvable, 6x4 deadlock).
- SB-M27-024 59x59 solver/perf sanity — `m27_scale_59.gd`.
- SB-M27-025 STALLED/WAITING separate from DEADLOCK — `deadlock_classifier` statuses; Unit `_m27_classifier_statuses`.
- SB-M27-026 never DEADLOCK with in-flight — `deadlock_classifier.classify` (inflight gate); Unit `_m27_classifier_statuses`.
- SB-M27-027 never DEADLOCK with empty slot + selectable front — Unit `_m27_classifier_statuses` (STALLED / immediate PROGRESSABLE).
- SB-M27-028 never DEADLOCK if scheduled clearing opens waiting targets — `_run_to_quiescence` revival + progress search; Unit `_m27_classifier_statuses` (revival).
- SB-M27-029 DEADLOCK only after proof of no future progress — `search_progress` exhaustion; Unit `_m27_classifier_statuses`.
- SB-M27-030 canonical true-deadlock fixture — Unit `_m27_classifier_statuses` (five-WAITING/full-slots/supply-empty).
- SB-M27-031 false-positive revival guard — Unit `_m27_classifier_statuses` (revived batch → PROGRESSABLE).
- SB-M27-032 deterministic reason codes, no UI coupling — `deadlock_classifier` reason strings; Unit `_m27_classifier_statuses`.
- SB-M27-033 reset/replay identical classification — Unit `_m27_classifier_statuses` + `_m27_canonical_key_and_determinism`.
- SB-M27-034 performance/memory profiling before closure — `m27_scale_59.gd` (visited/memo/frontier/elapsed/key bytes) + Hazard/gen reports.

## 5. Handoff

`AWAITING_AUDIT`. Every `SB-M27-001..034` maps to code + direct evidence above. Root `TASKS.md`
left for ChatGPT to update after independent audit. Root TASKS modified = NO; M28 UI = NO; image
credits = 0.
