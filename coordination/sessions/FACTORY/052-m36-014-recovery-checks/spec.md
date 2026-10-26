# Recovery component checks on v2 vectors (SB-M36-014)

> Feature: SB-M36-014 recovery component checks on v2 vectors (recovery not above peak on A or B, not above on both B and U, Session Load below peak) in tools/difficulty_playtest.gd recovery output + docs/10 section 13 CampaignBuilder constraints. Works under --progression v1|v2; default output unchanged except additive fields.

## Context
- `tools/difficulty_playtest.gd` `run()` builds `recovery` via `Tool.recovery_checks(for_guards, prog)` (`tools/analyze_m53_first10.gd:454`; shared with `calibrate_difficulty_v2.gd`, do NOT change it). `recovery["guards"]` has one entry per `prog.recovery_guards()` pair with `toSlot` (3->4, 5->6, 8->9 in both `level_progression_v1.json` and `level_progression_v2.json`). The 10->next guard has no `toSlot` and is skipped.
- Each level record (`level_record` for model v1, `level_record_v2`) already carries `vector` {W,C,A,U,B,R,S} (actual, normalised 0..1) and scalar `sessionLoad`.
- Rules come from `docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md` section 4 rules 2-3 / section 6 step 3 (owner pre-approved). Rule 1 (scalar drop) is the existing guard and stays as is.
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md` section 13 "Challenge-profile diversity" holds the CampaignBuilder constraint list.
- Shipped L1..L10 were made ad hoc and are NOT calibration references: results on them are informational only.

## Requirements
1. Add `static func recovery_component_checks(levels: Array, pairs: Array) -> Array` to `tools/difficulty_playtest.gd`. `levels`: dicts with `order`, `vector` (uses A, B, U), `sessionLoad` (float). `pairs`: dicts with `fromLevel`, `toLevel` (the `recovery["guards"]` entries qualify). Pure, no I/O, no tolerance/epsilon. Per pair it returns a dict with `fromLevel`, `toLevel`, `peakA`/`recoveryA`, `peakB`/`recoveryB`, `peakU`/`recoveryU`, `peakSessionLoad`/`recoverySessionLoad`, and booleans `aNotAbovePeak` (recovery A <= peak A), `bNotAbovePeak` (recovery B <= peak B), `notAboveOnBothBAndU` (NOT(recovery B > peak B AND recovery U > peak U)), `sessionLoadBelowPeak` (recovery SL < peak SL, strict), and `pass` (all four).
2. In `run()` add `recovery["componentChecks"] = recovery_component_checks(levels, recovery["guards"])` (additive key; existing `guards`, `boss`, `note`, `anomalies`, `levels`, stdout table and the `DIFFICULTY_PLAYTEST OK ...` line are unchanged). Works for `--model v1`, `--model v2` and `--progression v2` (pairs come from whichever config is loaded).
3. Component failures are reported only in `recovery.componentChecks`; they do NOT add entries to `anomalies`. Failures on shipped L1..L10 are reported, not fixed; no level, catalog, config or threshold change. No new config is needed (rules are pure comparisons).
4. New suite `tests/m36_recovery_component_checks.gd` (plus `.uid` as the repo does for other tests) with synthetic fixtures (see criteria) and a file-level check.
5. docs/10 section 13: add CampaignBuilder recovery-slot constraints: measured on actual v2 D/vectors; recovery A <= peak A; recovery B <= peak B; not above peak on both B and U; recovery Session Load < peak; scalar guard minimums stay governed by `recoveryGuards`; these are generator/CampaignBuilder constraints, not hidden per-player DDA; evaluating them on shipped L1..L10 is informational. Cite the proposal doc and `recovery.componentChecks`.
6. Mention the new output key in the header comment of `tools/difficulty_playtest.gd` (as SB-M36-014); add the new suite wherever AGENTS.md / docs list the M36 suites, if such a list exists. Update the SB-M36-014 entry/queue row in TASKS.md with LOCAL_PASS evidence.
7. `data/config/*` byte-identical (CLAUDE.md 11.3).

## Acceptance criteria
GODOT = C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe

1. `"$GODOT" --headless --path <worktree> -s res://tests/m36_recovery_component_checks.gd` exits 0 and prints a final `M36_RECOVERY_COMPONENT_CHECKS PASS` line (prints `FAIL ...` and exits non-zero on any failed assertion).
2. Synthetic fixtures asserted per rule (peak = level 3, recovery = level 4, other components fixed):
   - all four pass, clearly lower: `pass` true.
   - A: recovery A == peak A passes (boundary); recovery A = peak A + 0.001 fails `aNotAbovePeak` and `pass`, other flags unaffected.
   - B: same boundary pair for `bNotAbovePeak` (U lower so the B/U rule does not mask it).
   - B/U rule: B above AND U above -> `notAboveOnBothBAndU` false; B above, U equal -> true; B equal, U above -> true; both equal -> true; B above, U below -> true (B alone is caught by `bNotAbovePeak`).
   - Session Load: recovery < peak passes; equal fails (strict); above fails.
   - Recovery above on A and B (the shipped L8->L9 shape) fails `pass`.
   - Result is keyed by `fromLevel/toLevel`; the levels array may be shuffled with the same result.
3. After the commands in 5, the suite (or builder, documented in build.md) loads `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json` and `playtest_v2_progression_v2.json` and asserts `recovery.componentChecks` has 3 entries (3->4, 5->6, 8->9), each with the four booleans plus `pass`, equal to `recovery_component_checks` recomputed from the file's own `levels`.
4. Additive-only default output: the regenerated `playtest_v2.json` (default `--model v2 --progression v1`) differs from HEAD only by the added `componentChecks` block (`git diff`: no existing line changed or removed). Stdout is unchanged and `DIFFICULTY_PLAYTEST OK levels=10 anomalies=N` has the same N as at HEAD.
5. Each of these exits 0, prints `DIFFICULTY_PLAYTEST OK`, and writes JSON with `recovery.componentChecks`:
   - `"$GODOT" --headless --path <worktree> -s res://tools/difficulty_playtest.gd -- --model v2 --committed-measure`
   - `... -s res://tools/difficulty_playtest.gd -- --model v2 --progression v2 --committed-measure`
   - `... -s res://tools/difficulty_playtest.gd -- --model v1 --committed-measure` (any committed playtest_v1.json regeneration must be additive-only)
6. Informational: build.md records the actual componentChecks results on shipped L1..L10 per progression (the proposal expects 8->9 to fail A/B). Nothing is tuned to them.
7. Regression, each exits 0 with its usual PASS line: `-s res://tests/m36_progression_v2_reader.gd`, `m36_anchor_calibration.gd`, `m36_difficulty_v2.gd`, `m36_difficulty_v1.gd`, `m37_level_progression.gd`, `m53_first10_difficulty.gd`.
8. `git -C <worktree> diff --stat main -- data/config` is empty; `git diff --check` clean; docs/10 section 13 contains the new recovery-slot bullets (grep `Session Load` and `recovery` within that section).

## Out of scope
- Changing `Tool.recovery_checks` in analyze_m53_first10.gd, scalar guard values, lane targets, coefficients, v1/v2 configs, level/catalog data, or reordering/replacing L1..L10.
- New anomaly rules, thresholds, epsilons, a new config, or tuning anything to shipped L1..L10.
- Guard rescale (SB-M36-013), ensemble-vs-oracle peak selection (proposal rule 4), the 10->next-cycle guard, CampaignBuilder code, any per-player/dynamic difficulty.

## Assumptions
- "Not above on both B and U" means NOT(recovery B > peak B AND recovery U > peak U), strict, following the proposal wording "exceed"; equal values are not "above". (TASKS.md wording ">=" is shorthand; strict is the conservative reading of the proposal.)
- A and B "not above" use <=; Session Load "below" is strict <.
- Reported in `recovery.componentChecks`, not as anomalies, so anomaly counts and stdout stay unchanged.
- Pairs are the config `recoveryGuards` pairs (3->4, 5->6, 8->9): identical in both progression configs and the peak->recovery pairs the proposal names.
- No tolerance: analyzer floats are deterministic, exact comparisons keep boundary tests unambiguous.
