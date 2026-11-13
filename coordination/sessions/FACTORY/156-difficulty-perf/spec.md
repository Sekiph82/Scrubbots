# ScrubBots game — make Difficulty V1 analysis and the proof kernel faster, with identical output

Written 2026-11-13 by the Factory Claude for the Claude working in `C:\Users\sekip\Desktop\Scrubbots` (`Sekiph82/Scrubbots`). The owner explicitly asks for this game change, because the Level Factory has to produce many more levels per day. Follow the game repo's own CLAUDE.md, TASKS.md and test rules for everything not stated here.

## Why
The Level Factory solves every PixelLab PNG with the game's own code. It uses a copy of the game pinned at `dd54007a`: `ProofKernel`, `SolvabilitySolver` and `LevelDifficultyAnalyzerV1`. Today one level takes about 10-16 minutes. Most of that is a single call: `LevelDifficultyAnalyzerV1.measure()` (`scripts/difficulty/level_difficulty_analyzer_v1.gd`).

Measured on a typical 56x56 Factory level (91 solution steps, ~1300 artwork cells), one `measure()` took 382 s:

| Part | Time | Where |
|---|---|---|
| Per-step decision states | ~270 s (~3 s per step) | `_decision_state()` -> `_reach()` for every slot and front, scanning the board each step |
| Applying the 91 placements | ~74 s (~0.8 s per placement, max 5.7 s) | `ProofKernel.apply_placement()` (`kernelPlacementMeanMs` 818) |
| Wave analysis | ~35 s | `peel_waves()` |
| `score()` | 2 ms | |

Real Factory runs on the owner's laptop with 6 levels at once took 350-750 s per analysis. The same `ProofKernel.apply_placement()` cost also dominates the Factory's other steps: kernel replay of a plan, native search, and the real-play pre-check.

## Goal
Make `measure()` at least 2-3x faster on such levels, and make `ProofKernel.apply_placement()` faster if you can. Candidates, decided by your own profiling: incremental/cached `_reach()`; per-board precompute (routing, access, neighbours, colour indices); no Dictionary/Array allocation in hot loops (packed arrays); remove repeated `quiesce`/state copies where the result cannot change; single-BFS `peel_waves()`.

## Hard requirement: identical results
Output must stay byte-identical: every field `measure()` and `score()` return, every `ProofKernel` result (`clears`, `active_after`, `placed`), the trace hash, solver statuses/traces, and real-play outcomes.
- ~180 Factory levels and all campaign levels already carry Difficulty V1 scores.
- Prove it with a regression check that runs the old and new implementation on the same inputs and compares the full JSON output: the 30 campaign levels; the difficulty anchor fixtures; at least the Factory levels below.
- Watch it fail when you deliberately change one value.
- If an exact match is impossible somewhere, stop and report it to the owner; do not change scores silently.

## Real Factory inputs (read-only owner data; do not modify)
Folder: `C:\Users\sekip\Desktop\Scrubbots - Pixel Art Generator\data\Release Pool\Pending\Pipelines\Work\`
1. LF-000147: 89 steps, 1271 artwork cells, challengeScore 52.1888, HARD. `candidate-owner-3e3054a9b3ad260fc2df5807b2dabe54dad7340b1a2176fd\9a32f00dda745d2086f3\` — level `candidate-owner-3e30….json`; supply plan `…_supply_v1.json` (`intendedColumnClicks` = solution order); Factory result `…_supply_result.json` (`solver_metrics.official_difficulty_v1`, `solution_trace`).
2. LF-000148: 89 steps, 1322 artwork cells, challengeScore 43.8423, MEDIUM. `candidate-owner-746d44ed04341a8b20bd5fe042b917368c392ecb687b4c16\31c77e600be5bb42d56b\` (same file pattern).
Copy them into a scratch folder or test fixture; never write into these folders.

## Must not change
- Game rules, ProofKernel semantics, Difficulty V1 formulas, constants and anchors.
- Released or campaign level data.
- The real-play "refill slots at once" rule (owner 2026-10-31, confirmed 2026-11-13).

## Done when
- `measure()` on the two levels above is at least 2x faster. Report old/new seconds for each part (decision states, placements, peel) and the `apply_placement()` mean.
- The identical-output regression passes on campaign levels, anchors and these Factory levels.
- The full headless suite passes; exact counts including failures.
- One commit pushed to main; report the hash.
