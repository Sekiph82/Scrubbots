# ScrubBots game — solver-proven orders deadlock in real 60 Hz play (all five slots WAITING)
Written 2026-11-12 by the Factory Claude for the Claude working in `C:\Users\sekip\Desktop\Scrubbots` (`Sekiph82/Scrubbots`). Investigation only until the owner approves a fix. Follow the game repo's CLAUDE.md, TASKS.md and test rules.

## Symptom
For some Factory levels the game's own solver (`SolvabilitySolver` / `ProofKernel`) proves a winning column order: replay is ok, finalActive 0, divergedAt -1. When the game's real-play tool (tools/real_play_file.gd, canonical 1/60) plays exactly that order on the production host, the run gets stuck after a few dozen clicks:
* all five slots are occupied and `WAITING`;
* `activeRobots` is 0;
* the result is `LOST`.

The Factory then starts real-play `--search`, which does not finish within 900 s, so the level is discarded.
This is not caused by a version difference. The same result happens on a clean clone at `dd54007a` (fresh `--import`, no script errors) and on the older checkout `9f1ada33`, at the same click and frame.

## Reproduction (read-only inputs, owner data; do not modify them)
Case 1 — LF-000009, 3 columns, 93 clicks. Gets stuck at click 27, frame 8635.
Folder: `C:\Users\sekip\Desktop\Scrubbots - Pixel Art Generator\data\Release Pool\Pending\Pipelines\Work\candidate-owner-f39da1cd9a02633ae360028f196ea6d5c902d7ba01e0a770\7d50ef2df6beef1b6849\`
* Level file: `candidate-owner-f39da1cd9a02633ae360028f196ea6d5c902d7ba01e0a770.json`
* Plan file: `candidate-owner-f39da1cd9a02633ae360028f196ea6d5c902d7ba01e0a770_supply_v1.json`
* Solver result: `..._supply_result.json`. It contains the 93-step proof trace, which equals `intendedColumnClicks` (verified). Steps 25-28: clears 26 active 925; clears 0 active 925; clears 14 active 911; clears 17 active 894.

Case 2 — LF-000037, 76 clicks. Gets stuck at click 26, frame 10849, residue 754, all five slots WAITING.
Folder: `...\Work\candidate-owner-d3cd5ac6adca713129048fc01872667bae4e69368ffc32dd\2035ddd2d6364c62b3b8\` (same file pattern as case 1).

Command, after copying the two input files to a scratch folder:
```
godot --headless --path <game> -s res://tools/real_play_file.gd -- --level-file <level.json> --plan-file <supply_v1.json> --out <scratch>/result.json --canonical-only
```
About 11 s. Expected `WON_CANONICAL`. Actual `LOST` with `stuck: true`.

## What to find
1. Compare the proof kernel state and the production host state click by click up to the stuck click. Suspects: which batch is in which slot; when a slot changes WAITING<->ACTIVE; batch claim and dispatch order; the rightmost-slot origin rule; revival of a WAITING slot.
2. Decide which side is wrong. If the production host is the truth, the kernel must model it. If the kernel is the truth, the host must follow it.
3. Fix it in one place, with a regression test that plays one of these two orders through both the proof kernel and the production host. Watch it fail first.
4. Report: root cause; commit hash; test counts; whether the 30 campaign levels are unchanged (they must stay unchanged).

## Must not change
* The 30 campaign levels.
* The Difficulty V1 analyzer outputs for already released levels, unless the owner approves.
* The real-play 1/60 canonical timing.

## Factory side (not your job)
After the fix lands on main, the Factory re-pins its runtime to that commit, as it did for `dd54007a`, and moves its real-play host to the same commit.
