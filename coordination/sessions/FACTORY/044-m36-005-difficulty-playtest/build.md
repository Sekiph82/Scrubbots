STATUS: READY

# Build: Difficulty playtest report (simulated) and queue hygiene

## Summary
Branch `factory/044-m36-005-difficulty-playtest` adds a thin headless runner that runs, for every level in the production catalog, a fresh SolvabilitySolver solve, replays the fresh oracle trace through `LevelDifficultyAnalyzerV1.measure`, scores it with the v1 model and flags anomalies by fixed rules. It also adds the report and its JSON, files three follow-up tasks and updates the queue.

Commits: `b81aa5e3` (runner, JSON, report, docs/11 pointer) and `b89426a3` (TASKS.md).

Files changed (`git diff --name-only main`):
- `tools/difficulty_playtest.gd` (new; Godot made no .uid for it)
- `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json` (new, from the fully fresh run)
- `docs/DIFFICULTY_PLAYTEST_2026-10.md` (new; a scratch script generated it from the JSON and the runner's stdout table)
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md` (one line in section 16 pointing to the runner and report; AGENTS.md has no index of difficulty tools, so it was left alone)
- `TASKS.md`

Results: all 10 levels are SOLVED, with 0 route failures. Each fresh trace hash equals the committed M52 reference. There are 15 anomalies: LANE_MISS 10 (9 OUT_OF_HARD_LIMIT, plus L5 SOFT at -4.8), RECOVERY 3 (3->4, 5->6 and 8->9; 8->9 is inverted) and LONG_HIGH_FRICTION 2 (L5->L6 and L6->L7, a marginal pack-median signal). CADENCE, BOUNDARY, SOLVER and ROUTE found nothing. Measured D spans only 45.0..54.3, while the targets span 18..76. Filed: SB-M36-009 (lane calibration proposal), SB-M36-010 (recovery/sequencing proposal, which includes the L5..L7 run because it has the same cause) and SB-M36-011 (Frustration Risk inputs; the scalar is null and unsupported).

Note on the spec's expectations: it expected recovery guards 3->4 and 5->6 to fail, based on the M53 evidence. The fresh run also fails 8->9 (D 47.4 -> 50.8), and the report records that as found. New IDs start at 009 because `SB-M36-007` and `SB-M36-008` already exist in `docs/migration/legacy-task-trackers/scrubbots-pre-M21.md`.

## Acceptance criteria
1. [x] Runner exits 0, writes the JSON and prints the final line. Evidence: `"$GODOT" --headless --path <wt> -s res://tools/difficulty_playtest.gd` gave EXIT 0 in 13m42.8s, with last line `DIFFICULTY_PLAYTEST OK levels=10 anomalies=15` and 0 `SCRIPT ERROR`/`Parse Error`. A python check found 10 level records, each with every req-2 key: order, id, width/height, class, slot, challengeScore, vector, targetChallenge, signedDelta, acceptanceWindow, sessionLoad, frustrationRisk {status, scalar null}, solver {status, visited, ms}, dispatches, decisions, dispatchWaves, routeFailures and measureMs. Each record also has a `source` field, and the file has top-level provenance, recovery and anomalies. Runtime: the fully fresh run takes about 14 min, which is more than the spec's "a few minutes". The `-- --committed-measure` flag reuses the committed M53 raw replay only when its trace hash equals the fresh solver trace and the LevelData sha matches. The solver still runs fresh, and each level is labelled `committed_raw`. That mode took 3m56s and gave identical numbers and 15 anomalies. The committed JSON comes from the fully fresh run (`source: fresh` for all 10).
2. [x] D is finite and in 0..100, W..S are in 0..1, and D equals 100*(0.10W+0.15C+0.20A+0.20U+0.15B+0.10R+0.10S) within 1e-6. Evidence: python asserts over all 10 records passed.
3. [x] Solver status is SOLVED for all 10, from fresh `SolvabilitySolver.solve` runs. Raw statuses are mapped to docs/10 vocabulary: DEADLOCK = UNSOLVABLE, UNKNOWN_BOUND = INCONCLUSIVE. Visited counts were 20/37/59/40/46/41/40/38/40/47.
4. [x] targetChallenge = [20, 22, 40, 19, 58, 18, 21, 42, 19, 76] and class = [EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD]. Evidence: python printout.
5. [x] Every anomaly references an existing (order, id) and a rule from req 3. A python check asserted that each anomaly's id and its D to one decimal appear in the doc.
6. [x] The doc has a 10-row table, an Anomalies section grouped by all 7 rules, Provenance and versions, "What this does and does not prove", and Filed follow-up tasks. `grep -c "SB-M36-0" docs/DIFFICULTY_PLAYTEST_2026-10.md` = 5, against 3 filed items.
7. [x] `grep -n SB-M36-005 TASKS.md` shows the queue row `- DONE SB-M36-005` (line 33) and the checklist item `- [x] SB-M36-005` (line 968). The stale OWNER_REQUIRED note at line 962 was replaced. For each of SB-M36-009, 010 and 011, `grep -c "^- \[ \] ID "` = 1 and `grep -c "^- READY ID "` = 1. A plain `grep -c SB-M36-009` gives 5 because the range text "SB-M36-009..011" appears in the evidence notes.
8. [x] The `READY SB-M22-026` row (line 129) contains "VRAM compression", "owner visual sign-off", "before/after" and "atlasing". `grep -n "^- READY" TASKS.md | tail -1` puts it at line 129, after SB-M44-031 part 2 (line 128) and before the trailing DONE rows.
9. [x] `git diff --stat main -- data assets scripts tests level_factory` is empty. `git diff --name-only main` lists only the 5 files above, with no `data/config` change.
10. [x] `tests/m53_first10_difficulty.gd` exited 0 with last line `M53 FIRST10 DIFFICULTY: PASS`. `tests/m36_difficulty_v1.gd` exited 0 with last line `M36 difficulty V1 evidence: PASS`. Neither printed a SCRIPT ERROR or Parse Error. `git diff --check main` is clean.

## Validation
- `difficulty_playtest.gd` (fresh): LOCAL_PASS, exit 0, 13m42.8s.
- `difficulty_playtest.gd -- --committed-measure`: LOCAL_PASS, exit 0, 3m56s, same numbers.
- The python JSON/formula/doc cross-check passed.
- `tests/m53_first10_difficulty.gd`: LOCAL_PASS.
- `tests/m36_difficulty_v1.gd`: LOCAL_PASS.
- `git diff --check main` is clean, and `git status` shows no tracked modifications. The Godot import had rewritten tracked `.import` files with line-ending-only changes; I restored them with `git checkout --`. Untracked `.import`/`.uid` files from the worktree's Godot import remain. They are not committed and go away when the worktree is deleted.
- No new `tests/` suite was added: spec req 8 and AC9 forbid changes under `tests/`. The runner checks itself (it exits 1 on load, reference, measure or write failure), and the python asserts above cover AC1-5.

## Log
### Round 1
- Read the spec, AGENTS.md, docs/10 and docs/11 (sections 7-9, 11-13 and 16), both v1 configs, the analyzer, progression, solver and M53 tool. I wrote `tools/difficulty_playtest.gd`, which reuses `Tool.reference_inputs`, `Tool.recovery_checks` and `Tool._write`, plus `Analyzer.measure`/`score`/`WINDOW_*` and `DifficultyProgressionV1`. It adds no scoring.
- Rule (f) uses the pack median, because no config threshold exists: docs/11 section 8 only gives relative rules, and the doc cites this.
- Ran the runner fully fresh and committed its JSON, then generated the doc from that JSON. I added a one-line pointer in docs/11 section 16 and edited TASKS.md with a CRLF-preserving script: SB-M36-005 ticked, its queue row set to DONE, SB-M36-009..011 filed as items plus READY rows, and the SB-M22-026 row rewritten and moved after the last READY row.
