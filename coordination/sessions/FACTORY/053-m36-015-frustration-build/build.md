STATUS: READY

# Build: Frustration Risk inputs build (HUMAN_BR + Session Load budget)

## Summary
Branch `factory/053-m36-015-frustration-build`, commits `66d8e163` (implementation) and `cd7e64bb` (TASKS.md).

F is now computable offline, labelled `PROVISIONAL_SIMULATED_HUMAN`. The HUMAN_BR population uses three `PRIOR_UNCALIBRATED` profiles and runs through the real ProofKernel via the v2 `run_policy`. A new optional `chooser` Callable on `run_policy` defaults to off, so there is no copied kernel loop. session_overrun comes from a per-slot Session Load budget (`PROXY`), choice_opacity from the v2 proxy, and the F weights are read unchanged from `difficulty_score_model_v2.json`. `difficulty_playtest.gd` gains opt-in `--frustration [--runs N]`.

Files changed (`git diff --stat main...`, 10 files):
- `data/config/frustration_analysis_v1.json` (new)
- `scripts/difficulty/frustration_analyzer_v1.gd` (new)
- `scripts/difficulty/level_difficulty_analyzer_v2.gd` (the optional `chooser` parameter only)
- `tools/difficulty_playtest.gd` (`--frustration`, `--runs`, header usage; writes `frustration_v1.json` and `frustration_v1.md` beside `playtest_v2.json`)
- `tests/m36_frustration_v1.gd` (new). The repo does not track `.uid` files: every existing `tests/m36_*.gd.uid` is untracked, so none is committed.
- `docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md` (new section 8), `docs/09_...` section 7 and `docs/11_...` sections 7 and 8 (pointer lines), `AGENTS.md` (difficulty tools line), `TASKS.md`

Design notes:
- **Injected v2 analyzer.** The caller passes the v2 analyzer instance to `FrustrationAnalyzerV1.new(v2)`. Because the analyzer does not preload it, the existing v2 offline-boundary scans in `m36_difficulty_v2` s11 and `m53_first10_difficulty` stay green without editing those suites. The F weights are read from the score model that the analyzer's provenance names, which is `difficulty_score_model_v2.json`.
- **Corpus inputs for the suite.** Session Load and choice opacity for the corpus fixtures come from `v2.score()` on the committed M53-C002 corpus raw, instead of a fresh 7-policy measure. Each one is cross-checked: the committed ACCESS path equals a fresh ACCESS run.
- **L1 inputs for the suite.** L1 uses stipulated inputs: Session Load 7.5 (proposal 4.4) and opacity 0.2.

## Acceptance criteria
Suite: `"$GODOT" --headless --path $WT -s res://tests/m36_frustration_v1.gd`. Result: exit 0, no SCRIPT ERROR or Parse Error, last line `M36_FRUSTRATION_V1 PASS (62 cases, 0 fail)`, wall 365 s.

1. [x] **Determinism.**
   - compact_hard_20 NOVICE run 0, run twice: placement hash 1921229572 both times, identical columns.
   - Run indexes 0 and 1 have different seeds and diverge.
   - L1 1-run analyze, done twice: `to_json` byte-identical (3297 bytes).
2. [x] **Degenerate equivalence.** With tau=0 (argmax on [u, reachable], ties to the lowest column), epsilon=0 and mu=0, the column sequence equals `run_policy(...,"ACCESS")` on L1 (19 columns), compact_hard_20 (15), flow_stripes3_20 (14) and bottleneck_low_24 (21).
3. [x] **Skill monotonicity (FINDING on L1).** At 2 runs per profile, clearRate is 1.0/1.0/1.0 (ties) on all four corpus fixtures. L1 at 2 runs per profile gives NOVICE 0/2, CASUAL 1/2, SKILLED 0/2, which is a monotonicity miss. It is printed as FINDING and not tuned.
4. [x] **Discrimination (FINDING).** Both declared pairs pass only as ties: retryRisk(compact_hard_20)=0.0 >= retryRisk(flow_stripes3_20)=0.0, and retryRisk(bottleneck_high_24)=0.0 >= retryRisk(bottleneck_low_24)=0.0. No corpus fixture lost an attempt, so these pairs do not discriminate at this run count.
5. [x] **Aggregator units on crafted lists.**
   - Progress 0.70 is not late; 0.71 is late.
   - Near-miss: 0.90 counts, 0.89 does not.
   - INCONCLUSIVE runs are excluded from clearRate (1/5) and counted (1).
   - With no LOST runs: lateFailure 0, LOST count 0.
   - With only INCONCLUSIVE runs: clearRate null.
   - The Wilson interval stays within 0..1 and contains p for 0/20, 1/20, 7/20, 20/20 and 1/5.
6. [x] **session_overrun.** Budgets for slots 1..10 are [26,26,36,22,40,22,26,36,22,48]. For every slot the overrun is 0 at and below budget, 0.5 at 1.5x, and 1 at 2x and 3x. A missing Session Load or slot gives null.
7. [x] **F.** Weights read from `difficulty_score_model_v2.json` are 0.35/0.30/0.20/0.15. F is finite and in 0..100 on the four fixtures (1.03, 0.0, 0.0, 2.04) and on L1 (29.25). The F formula is checked exactly. F is null and names the missing input when each of the four inputs is removed (4 cases).
8. [x] **Provenance.** The LF-normalised sha256 of all six configs equals the `git show main:` sha256 (hashes embedded in the suite). The output carries the analyzer version `m36-frustration-analyzer/v1`, config version 1 and a per-attempt seed that equals `seed_for(...)`.
9. [x] **Boundary.** Scanning every `.tscn` under res:// plus every `.gd` under `res://scripts` outside `scripts/difficulty/` finds no reference to `frustration_analyzer_v1`. The analyzer source has no `user://`.
10. [x] **Smoke.** On L1 at 2 runs per profile through the analyzer API, every requirement-2 field is present (result, per-profile, population and inputs). `Playtest.frustration_table_md` renders the L1 row.
    - Code inspection: without `--frustration`, `_frustration` stays null. `run()` then skips `write_frustration`, `level_record_v2` skips `frustration_level`, and no other code path changes.
11. [x] **Regression.** Each suite exits 0 with no SCRIPT ERROR:
    - m36_recovery_component_checks: `M36_RECOVERY_COMPONENT_CHECKS PASS (26 cases, 0 fail)`
    - m36_progression_v2_reader: `M36 progression v2 reader: PASS (55 cases, 0 fail)`
    - m36_anchor_calibration: `M36 anchor calibration: PASS (126 cases, 0 fail)`
    - m36_difficulty_v2: `M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)`
    - m36_difficulty_v1: `M36 difficulty V1 evidence: PASS`
    - m37_level_progression: `M37 level progression evidence: PASS`
    - m53_first10_difficulty: `M53 FIRST10 DIFFICULTY: PASS`
    - Also m53_c002_difficulty_calibration: `M53-C002 DIFFICULTY CALIBRATION: PASS`
12. [x] **Diff hygiene.** `git diff --check main...HEAD` is clean (exit 0). `git diff --stat main...` shows only the files listed in the Summary.
13. [x] **Byte check.** `git diff --quiet main -- <six configs>` exits 0.

## Validation
- `$GODOT --headless --path $WT -s res://tests/m36_frustration_v1.gd`: PASS (62 cases), LOCAL_PASS, 365 s.
- The 7 regression suites above plus m53_c002_difficulty_calibration: all PASS, LOCAL_PASS.
- `git diff --check` (staged and `main...HEAD`): clean.
- The six-config `git diff --quiet main`: exit 0.
- The optional full 10-level `--frustration` run was not done. It is out of scope and about 5.6 h, and running the tool also rewrites the committed `playtest_v2.json`. The measured cost of one HUMAN_BR attempt is about 5-11 s on 20x20/24x24 boards.
- Worktree note: `git status` still lists Godot import artefacts (untracked `*.uid` and `*.import`, modified `*.png.import`). They were already present when the job started, and I did not create or stage them. Every task file is committed.

## Log
### Round 0
- Implemented the config, analyzer, run_policy chooser hook, playtest `--frustration`/`--runs`, suite, docs and TASKS.md (SB-M36-015 ticked, queue row DONE).
- First suite run (4 runs per profile, fresh v2 measure per fixture) passed but took 919 s. I cut it to 365 s by switching to 2 runs per profile (inside the spec's 2-4 range) and taking corpus Session Load and opacity from the committed M53-C002 raw, cross-checked against a fresh ACCESS run.
- Findings, reported and not tuned:
  - Corpus fixtures never lose at this run count, so the discrimination pairs are ties.
  - L1 clear rates are not monotonic at 2 runs per profile.
