# Codex task: gate the ScrubBots Factory Studio release pool on the game's real-play check

You are working in the **ScrubBots Factory Studio** project at:

`C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator/Release/ScrubBots Factory Studio`

Only edit files inside that Studio project. Everything you need about the game side is in this
prompt.

## a. Goal and rule

Today the Studio marks a candidate as release-pool ready ("ready", written to
`level_factory/output/studio-extensions/release-pool/<candidate>-pipeline-<run>-ready.json`)
when its acceptance record says `solver_status == "SOLVED"` (Studio ProofKernel-timing
solver) and `replay == "WIN"`. That is not enough. The ScrubBots game measured that 6 of 20
release-pool plans with SOLVED + replay WIN dead-end when played through the real game
runtime the way a human plays: the kernel settles each placement's dispatch cascade before
the next one, while the real runtime claims targets while earlier bots are still flying.

New rule: **ProofKernel `SOLVED` + replay `WIN` alone must no longer mark a candidate
ready/shippable.** A candidate becomes ready only when ALSO the game's real-play check
(model `real_play_v1`) returns verdict `WON_ROBUST` with exit code 0 for the exact level and
supply-plan files that would be imported. Keep the existing SOLVED + replay WIN check; the
real-play verdict is an additional, required gate.

## b. Where to call it

Hook the gate into the Studio's release-pool acceptance step: the single code path where a
candidate is promoted to release-pool / "ready" (the code that writes the `*-ready.json`
release-pool entry, schema `scrubbots-release-pool-entry/v1`, whose
`pipeline.primary.acceptance` holds `solver_status` / `replay`). Locate that function in the
Studio code yourself. In your final report name the file and function you hooked, and make
sure no other path can write a ready entry without passing the gate.

## c. The command

The game repo provides a headless Godot tool. Exact usage:

```
godot --headless --path <ScrubBots repo> -s res://tools/real_play_file.gd -- --level-file <abs level.json> --plan-file <abs plan.json> [--search] [--out <abs result.json>]
```

- Run it as a subprocess with an **argument list** (no shell string, no `shell=True`), e.g.
  `[godot_exe, "--headless", "--path", repo, "-s", "res://tools/real_play_file.gd", "--",
  "--level-file", level_abs, "--plan-file", plan_abs, "--out", result_abs]`, plus
  `"--search"` when you want the search (section f). The working directory does not matter.
- Every path must be an absolute filesystem path. `res://` / `user://` paths and relative
  paths are rejected (`INVALID_INPUT`). `--out` must lie OUTSIDE the game repo and its parent
  directory must exist.
- Timeout: default 900 s, configurable (setting `realPlayTimeoutSeconds`). One run without
  `--search` takes about 10 s; `--search` can take minutes (it is bounded by a node budget,
  not wall clock).
- Capture stdout and stderr separately. Godot prints a banner and other log lines to stdout,
  and may print exit warnings (for example `WARNING: ... ObjectDB instances were leaked`) to
  stderr after the result. Parse the **last stdout line that starts with
  `REAL_PLAY_RESULT `** (marker, then one space, then a single-line compact JSON object).
  When you passed `--out`, the same object is also written there pretty-printed; prefer the
  stdout line and, if both exist, they must be equal.
- Exit codes: `0` = `WON_ROBUST`; `1` = a valid input that did not produce a robust win
  (`WON_CANONICAL_ONLY`, `LOST`, `SEARCH_EXHAUSTED`, `SEARCH_BUDGET`); `2` = `INVALID_INPUT`.
  The JSON `exitCode` field equals the process exit code.
- The tool never writes anything inside the game repo (only `--out`), registers nothing in
  the game catalog and never edits the input files.

## d. Locating Godot and the game repo

Add two Studio settings (wherever the Studio keeps its configuration):

- `scrubbotsRepoPath`: the ScrubBots game repo. Fallback: env `SCRUBBOTS_REPO`. The owner's
  checkout is `C:/Users/sekip/Desktop/ScrubBots`.
- `godotExe`: Godot 4.7.2 console executable. Fallback: env `GODOT`, then the known WinGet
  location
  `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`.

Preflight before the first gate run (cache per session is fine):

- `[godot_exe, "--version"]` must succeed and its stdout (stripped) must start with `4.7.2`.
- `scrubbotsRepoPath` must contain `project.godot` and `tools/real_play_file.gd`.

If any preflight check fails, the gate **fails closed**: the candidate is not ready, and the
UI/log shows a clear message (which setting is wrong, what was found). Never skip the gate
silently, never fall back to SOLVED + replay WIN alone.

## e. Which files to pass

Pass the candidate's level JSON and supply-plan JSON: the same two files the game's importer
(`tools/import_release_pool_levels.py` in the game repo) reads from a release-pool entry's
`files.level.path` and `files.supply_plan.path` (with their `sha256`) and copies into the
game's `data/levels/` and `data/levels/supply/`. Today these live under
`level_factory/output/studio-extensions/canonical-supply/<candidate>/<run>/<candidate>.json`
and `.../<candidate>_supply_v1.json`; confirm this in the Studio code. Pass their absolute
paths exactly as they would be imported (the Studio's own files, outside the game repo, no
conversion needed: the tool accepts Studio-format levels, version 1 or 2 with VOID cells, and
plans whose `levelId` equals the level `id`). The plan must carry a non-empty
`intendedColumnClicks` array of ints (1-based supply columns, the click order the real-play
check plays).

Write the result JSON (`--out`) into a Studio-owned folder beside the candidate's existing
evidence, e.g. `<same run folder>/real_play_result_v1.json`; never into the game repo.

Verified on the game side: the current Studio files of the crab candidate
(`candidate-owner-36ca9b4074ba991b52c6e5b5b89ee2acce581fa009fdf6c7`, run
`19f39c3646516d279c1c`) give exit 1, verdict `LOST` (stuck after click 27 at 1/60).

## f. Verdict handling

| Verdict | Exit | Studio action |
|---|---|---|
| `WON_ROBUST`, `searched: false` | 0 | accept: candidate may become ready (if SOLVED + replay WIN also hold) |
| `WON_ROBUST`, `searched: true` (only with `--search`) | 0 | the plan as written is NOT robust; `searchedClicks` is a click order that wins at every dt. Accept only after: rewrite the plan's `intendedColumnClicks` to `searchedClicks` (text splice of just that array or a JSON rewrite that keeps every other field and value unchanged); recompute and store the new plan sha256 (and update the release-pool entry's `files.supply_plan.sha256`); re-run the CLI WITHOUT `--search` on the rewritten plan and require exit 0 + `WON_ROBUST` before marking ready |
| `WON_CANONICAL_ONLY` | 1 | reject (not ready): wins at 1/60 only, not at 1/30 and 1/120 |
| `LOST` | 1 | reject: show the verdict and `perDt["1/60"].stuckClickIndex` (and the slot state) |
| `SEARCH_EXHAUSTED` | 1 | reject: no supply-column order wins under real play (only with `--search`) |
| `SEARCH_BUDGET` | 1 | reject: search budget hit without a win, inconclusive (only with `--search`) |
| `INVALID_INPUT` | 2 | reject as a Studio export bug; show `error` |
| anything else: other exit code, timeout, no `REAL_PLAY_RESULT ` line, unparsable JSON, `schema` not `scrubbots.real_play_file_result.v1`, `model` not `real_play_v1`, exit code != `exitCode`, `planSha256` != sha256 of the plan you passed | - | fail closed: reject, show what happened |

Suggested flow: run without `--search`; on exit 1 with `LOST` or `WON_CANONICAL_ONLY`, run
again with `--search` (it re-verifies the plan, then searches from its clicks) and apply the
row above. Running `--search` directly is also allowed.

## Result JSON (`scrubbots.real_play_file_result.v1`)

Keys are sorted; ints are JSON integers. Fields:

| Field | Type | Meaning |
|---|---|---|
| `schema` | string | `scrubbots.real_play_file_result.v1` |
| `model` | string | `real_play_v1` |
| `verdict` | string | one of `WON_ROBUST`, `WON_CANONICAL_ONLY`, `LOST`, `SEARCH_EXHAUSTED`, `SEARCH_BUDGET`, `INVALID_INPUT` |
| `exitCode` | int | 0, 1 or 2 (== process exit code) |
| `searched` | bool | true when `--search` ran the search |
| `levelFile`, `planFile` | string or null | the paths as passed |
| `levelId` | string or null | the plan's `levelId` (set once the plan validated) |
| `planSha256`, `levelSha256` | string or null | sha256 hex of the file text with CRLF normalised to LF, then UTF-8 (set once the file was readable) |
| `gameCommit` | string | `git rev-parse HEAD` of the game repo, or `unknown` |
| `planClicks` | int[] | the plan's `intendedColumnClicks` as played |
| `perDt` | object | keys `1/30`, `1/60`, `1/120` (empty for `INVALID_INPUT`); each: `won` bool, `frames` int, `clicksPlaced` int, `stuck` bool, `stuckClickIndex` (1-based index of the last click placed before it got stuck; null when won), `final` {`active` int, `supplyExhausted` bool, `slotsEmpty` bool, `terminal` string}, `slots` (null when won, else one object per slot: `index`, `occupied`, `state`, `batchId`, `colorId` (level-local palette index), `remaining`, `committed`), `rejected` (null, or {`click`, `column`, `error`, `driver_bug`} when a click was refused) |
| `search` | object or null | with `--search`: `status` (`SOLVED`, `EXHAUSTED`, `UNWINNABLE_WITHIN_BUDGET`), `nodes`, `nodeBudget`, `robust`, `robustRejects` |
| `searchedClicks` | int[] or null | the click order found by the search (when `search.status == "SOLVED"`) |
| `error` | string or null | the reason for `INVALID_INPUT` |

Example (pre-fix crab plan with `--search`; abbreviated: `perDt` shows one dt, `slots` two
of five, click arrays shortened):

```json
{
	"error": null,
	"exitCode": 0,
	"gameCommit": "be9d7ec708f06fee70586f6a17da370f1fa6851a",
	"levelFile": "C:/Studio/run/level.json",
	"levelId": "level_022_crab",
	"levelSha256": "26c872a5b708a8f0af97b337be11164c427fc6c0f66b845fbbf537cd0bb3bfee",
	"model": "real_play_v1",
	"perDt": {
		"1/60": {
			"clicksPlaced": 27,
			"final": {"active": 273, "slotsEmpty": false, "supplyExhausted": false, "terminal": "LOST"},
			"frames": 6906,
			"rejected": null,
			"slots": [
				{"batchId": "L022-K2-05", "colorId": 1, "committed": 0, "index": 0, "occupied": true, "remaining": 9, "state": "WAITING"},
				{"batchId": "L022-K5-01", "colorId": 1, "committed": 0, "index": 1, "occupied": true, "remaining": 15, "state": "WAITING"}
			],
			"stuck": true,
			"stuckClickIndex": 27,
			"won": false
		}
	},
	"planClicks": [1, 1, 1, 1, 1, 2, 2, 2],
	"planFile": "C:/Studio/run/plan.json",
	"planSha256": "d4e09f7baf813f1167bdf4c8e0f66ab50bfcbd0f4b80dac59f406049374fb9c1",
	"schema": "scrubbots.real_play_file_result.v1",
	"search": {"nodeBudget": 400, "nodes": 32, "robust": true, "robustRejects": 0, "status": "SOLVED"},
	"searched": true,
	"searchedClicks": [1, 1, 1, 1, 1, 2, 2, 2],
	"verdict": "WON_ROBUST"
}
```

An `INVALID_INPUT` result (exact output for an unknown argument):

```
REAL_PLAY_RESULT {"error":"usage: unknown argument --bogus","exitCode":2,"gameCommit":"be9d7ec708f06fee70586f6a17da370f1fa6851a","levelFile":null,"levelId":null,"levelSha256":null,"model":"real_play_v1","perDt":{},"planClicks":[],"planFile":null,"planSha256":null,"schema":"scrubbots.real_play_file_result.v1","search":null,"searched":false,"searchedClicks":null,"verdict":"INVALID_INPUT"}
```

## g. Evidence

- Store the full result JSON (the `--out` file) as release-pool evidence next to the existing
  "SOLVED + replay WIN" record, and record in the release-pool entry (or its acceptance
  record) at least: `verdict`, `model`, `planSha256`, `levelSha256`, `gameCommit`, the result
  file path and its sha256.
- The evidence is bound to the bytes: whenever the plan or level file changes (its sha256 no
  longer equals the stored `planSha256` / `levelSha256`, computed the same way: CRLF -> LF,
  UTF-8, sha256 hex), the real-play evidence is invalid and the candidate is not ready until
  the gate passes again.

## h. Tests (Studio side)

1. A fake-CLI test: a stub executable/script standing in for Godot (configured through
   `godotExe`; it must answer `--version` with `4.7.2.stable...` and otherwise print a
   canned banner, a canned `REAL_PLAY_RESULT ` line and exit with a canned code). Cover:
   - `WON_ROBUST` exit 0 -> accepted (ready);
   - `WON_ROBUST` with `searched: true` + `searchedClicks` -> plan rewritten (only
     `intendedColumnClicks` changes, every other field equal), new hash stored, re-run without
     `--search` required; accepted only when the re-run gives exit 0 `WON_ROBUST`, rejected
     when it does not;
   - `WON_CANONICAL_ONLY`, `LOST`, `SEARCH_EXHAUSTED`, `SEARCH_BUDGET` exit 1 -> rejected,
     verdict (and stuck click for `LOST`) shown;
   - `INVALID_INPUT` exit 2 -> rejected as an export bug with `error` shown;
   - fail closed: unexpected exit code (e.g. 3), timeout, no `REAL_PLAY_RESULT ` line,
     malformed JSON, wrong `schema` / `model`, `exitCode` != process exit code,
     `planSha256` mismatch, `--version` not starting with `4.7.2`, repo path without
     `project.godot` or `tools/real_play_file.gd` -> rejected, never ready;
   - a candidate whose plan bytes change after a pass loses its ready state.
   - SOLVED + replay WIN evidence is still required and still recorded.
2. An optional integration test against the real CLI (skipped with a clear message when
   Godot 4.7.2 or the game repo is not available): copy the crab candidate's level and plan
   (section e) to a temp dir and set the plan's `intendedColumnClicks` to the pre-fix order
   `[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 3, 3, 5, 5, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5]`
   (if it is not already that order). Expect exit 1, `LOST`. Then with `--search` expect
   exit 0, `WON_ROBUST`, `searched: true`, non-empty int `searchedClicks`; rewrite the copy's
   clicks to them and re-run without `--search`: exit 0 `WON_ROBUST`.

Run the Studio's existing test suites as well and report results honestly.

## i. Do not touch

- Do not edit anything in the ScrubBots game repo (`C:/Users/sekip/Desktop/ScrubBots`); it is
  read and executed only.
- Do not change or re-implement `real_play_v1` semantics, the human policy, the sensitivity
  dts (1/30, 1/60, 1/120) or the search budget; the game tool is the only authority.
- Do not drop or weaken the existing SOLVED + replay WIN evidence and check; the real-play
  verdict is in addition to it.
- Do not mark any candidate ready when the gate could not run.

## Final report

List the files changed, the function you hooked (section b), the setting names and where they
live, the evidence fields you added, and the test results (fake-CLI test and, if run, the
integration test).
