STATUS: READY

# Build: Real-play file CLI (SB-STUDIO-REAL-PLAY-GATE, game side)

## Summary
New headless tool `tools/real_play_file.gd` runs the real-play check (`real_play_v1`) on a level JSON + supply-plan JSON outside the repo, at 1/30, 1/60 and 1/120, with optional `--search`. It writes a `scrubbots.real_play_file_result.v1` result to `--out` and always prints it as the last stdout line `REAL_PLAY_RESULT <json>`. Exit codes: 0 WON_ROBUST, 1 other verdicts, 2 INVALID_INPUT. `RealPlayDriver.play_level/verify/search` now take a `source`, which is either a catalog entry id (behaviour unchanged) or a file source `{level_path, supply_plan_path}`. A file source builds the host through its no-AppState path. Everything from `build()` on is the same code path, and nothing is registered in the catalog. `play_on_host` now also returns per-slot `slots` state at the stop.

Commits on `factory/081-real-play-file-cli`: `1d93aa05` (code, suite, CI, docs) and `adaa14d1` (TASKS.md).

Files changed:
- `scripts/gameplay/solver/real_play_driver.gd`
- `tools/real_play_file.gd` (new)
- `tests/real_play_file_cli.gd` (new)
- `.github/workflows/android-family-first10.yml` (suite added, 64 total, exact 6/6 guard)
- `AGENTS.md` (l.18)
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md` (section 24, File mode / Studio gate)
- `TASKS.md` (queue row only)
- Job folder (main checkout, not committed): `CODEX_PROMPT_STUDIO_REAL_PLAY_GATE.md`

## Acceptance criteria
1. [x] Suite PASS: `"$GODOT" --headless --path <worktree> -s res://tests/real_play_file_cli.gd` printed `REAL PLAY FILE CLI: PASS (6/6 cases, 0 fail)` and exited 0. That is 6 == `EXPECTED_CASES`, with an exact-count guard. Wall time was 133 s and the log had no SCRIPT ERROR or Parse Error.
2. [x] valid: L22 copies under globalized `user://real_play_file_cli` (outside the repo), run as a subprocess, gave exit 0 and `WON_ROBUST`. `perDt` has 1/30, 1/60 and 1/120, all `won:true`. The `--out` file equals the stdout JSON. `planSha256` and `levelSha256` equal `plan_sha256` of the copies. Model, schema and levelId are correct, `gameCommit` is a 40-character sha, and no `N.0` ints appear in the line.
3. [x] lost: with OLD_L22 clicks and no `--search`, the run gave exit 1 and `LOST`. 1/60 `stuckClickIndex` is 27 (out of 43), `slots` has 5 entries, and `searchedClicks`/`search` are null.
4. [x] search: with `--search`, the run gave exit 0, `WON_ROBUST` and `searched:true`. `searchedClicks` are non-empty ints, `search` is SOLVED and robust in 32 nodes, and `nodeBudget` is 400. Splicing those clicks into a plan copy and re-running without `--search` gave exit 0 `WON_ROBUST`.
5. [x] invalid: each of these gave exit 2, `INVALID_INPUT`, a non-empty `error`, and no SCRIPT ERROR, Parse Error or crash text in the output: malformed level JSON, plan levelId mismatch (SupplyPlanLoader text), plan without `intendedColumnClicks`, empty clicks, relative path, `res://` path, nonexistent file, unknown arg (`--regen`), and `--out` inside the repo. Separately, `--bogus` prints the exact `Usage: ...` line and the result line.
6. [x] no_repo_writes: `git status --porcelain` was identical before and after every run, and the in-repo `--out` target was never created. Fixtures live under `user://` and are removed at the end.
7. [x] catalog_regression: catalog `play_level(get_root(), "level_022_crab", current_clicks)` was WON at 1/60 in 8202 frames. An in-process file-source play of the same clicks matched it (same frames, same `cleared_sequence`). `LevelCatalog` count stayed 30 before and after.
8. [x] Regression: `tests/real_play_levels.gd` printed `REAL PLAY LEVELS: PASS (5/5 cases, 0 fail)`, exit 0, 0 SCRIPT ERROR/Parse Error, wall 292 s.
9. [x] `git diff --check` is clean on every changed file. `grep -n "real_play_file.gd" AGENTS.md` finds l.18, which has the exact usage string, `WON_ROBUST` and the exit-code text. `grep -n real_play_file docs/10_...md` finds l.724 and l.735.
10. [x] The Codex prompt exists. It has sections `## a.` through `## i.` (1 each), the literal usage string (1), `REAL_PLAY_RESULT ` (5) and `scrubbots.real_play_file_result.v1` (5). Verdict name counts: WON_ROBUST 11, WON_CANONICAL_ONLY 5, LOST 9, SEARCH_EXHAUSTED 4, SEARCH_BUDGET 4, INVALID_INPUT 9. It also has the result-schema table, a JSON example with real L22 values, an exact INVALID_INPUT line, settings/preflight, verdict table, evidence binding, fake-CLI and integration tests, and a do-not-touch list.
11. [x] The suite is in CI because it took 133 s (under 180 s): `grep -n real_play_file_cli .github/workflows/android-family-first10.yml` finds l.49 (comment, 64 total), l.133 (suite loop) and l.274 (exact `REAL PLAY FILE CLI: PASS (6/6 cases, 0 fail)` guard). AGENTS.md records "LOCAL 133 s".

Extra check: I ran the tool on the Studio's own L22 crab files, unchanged and read-only (`canonical-supply/candidate-owner-36ca.../19f39c3646516d279c1c/*.json`, level version 2). It gave exit 1 `LOST`, stuck at click 27 at 1/60. So Studio-format files work as-is, and the result matches the 080 finding.

## Validation
- `$GODOT --headless --path <wt> -s res://tests/real_play_file_cli.gd`: LOCAL_PASS (6/6, 133 s)
- `$GODOT --headless --path <wt> -s res://tests/real_play_levels.gd`: LOCAL_PASS (5/5, 292 s)
- Manual tool runs: L22 current gave exit 0, OLD_L22 gave exit 1 LOST, raw Studio files gave exit 1 LOST, `--bogus` gave exit 2 with the usage line.
- `git diff --check` on the changed files: clean.
- CI run: none yet (branch not pushed, as instructed).

## Notes
- After printing the result, Godot writes `WARNING: ... ObjectDB instances were leaked` and `ERROR: 1 resources still in use at exit` to stderr. CI's DIAG regex does not match these. The Codex prompt tells the Studio to capture stdout separately and parse the last stdout line that starts with the marker.
- In this sandbox, `ProjectSettings.globalize_path("res://")` resolves to a virtualized `...\Packages\Claude_...\LocalCache\...` path. The inside-repo `--out` check compares against that path, and the suite builds the in-repo target the same way. On a normal machine both are the real path.
- The worktree's untracked/modified Godot import artifacts (`.import`, `.uid`, `project.godot`) were left in place and not committed, so `git status --porcelain` is not empty. That is expected per the job prompt.

## Log
### Round 1
Built everything listed above. The driver change is the minimal `source` generalisation plus `slots` in the play result. Catalog behaviour is unchanged, which `real_play_levels` 5/5 and the catalog-vs-file identity check confirm. I wrote the Codex handoff prompt from verified outputs (real LOST JSON values, exact usage and INVALID_INPUT line).
