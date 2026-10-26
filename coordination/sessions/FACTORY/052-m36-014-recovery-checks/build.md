STATUS: READY

# Build: Recovery component checks on v2 vectors (SB-M36-014)

## Summary
Branch `factory/052-m36-014-recovery-checks`, commits 9d1f9cb2 (code, suite, docs, evidence) and b34b80f2 (TASKS.md).

- `tools/difficulty_playtest.gd`: new pure `static func recovery_component_checks(levels, pairs) -> Array`. `run()` adds `recovery["componentChecks"]` (one entry per `recovery["guards"]` pair). Header comment has an SB-M36-014 paragraph. The function does not touch anomalies, stdout or `Tool.recovery_checks`.
- `tests/m36_recovery_component_checks.gd` (new suite): synthetic rule fixtures plus a check of the committed files. No `.uid` is committed because the repo does not track test `.uid` files (only 3 are tracked in tests/, and none for m36).
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md` section 13: new recovery-slot constraints paragraph.
- `AGENTS.md` (SB-M36-013 difficulty paragraph, the only place that lists M36 suites): mentions `recovery.componentChecks` and suite `m36_recovery_component_checks`.
- Evidence: `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json`, `playtest_v2_progression_v2.json` and `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json` each gain the `componentChecks` block. See criterion 4 for how they were produced.
- `TASKS.md`: SB-M36-014 is ticked with evidence, and its queue row is DONE.

## Acceptance criteria
1. [x] Suite exits 0, final line `M36_RECOVERY_COMPONENT_CHECKS PASS (26 cases, 0 fail)`, 0 SCRIPT ERROR/Parse Error. On any failure it prints `FAIL` lines and a final `... FAIL` line, and exits 1.
2. [x] The synthetic fixtures (peak L3 = 0.6 on A/B/U/SL, recovery L4 = 0.3 unless overridden) cover every case:
   - all lower gives pass;
   - A equal passes, A +0.001 fails only A and pass;
   - B equal passes, B +0.001 fails only B (U stays lower);
   - B/U: both above gives false; B above with U equal, B equal with U above, and both equal all give true; B above with U below gives true (with bNotAbovePeak false);
   - Session Load: below passes, equal fails, above fails;
   - A and B both above (the L8->L9 shape) fails pass;
   - the output is keyed by fromLevel/toLevel, and a reversed levels array gives an identical result.
3. [x] Suite s02 loads `playtest_v2.json` and `playtest_v2_progression_v2.json`. In each file it finds 3 entries (3->4, 5->6, 8->9), each with the 4 booleans plus `pass`. Every numeric and boolean field equals `recovery_component_checks` recomputed from the file's own `levels` and `recovery.guards`.
4. [x] The output is additive only, with one unavoidable JSON comma, explained below.
   - **Method:** I ran HEAD's tool (a temporary copy, `tools/_head_playtest.gd`, deleted afterwards) and the new tool back to back with `--committed-measure` in all three modes.
   - **Stdout:** in every mode it differs only in the solver wall-clock ms on the PLAYTESTED lines and in the table's solver-ms column. The table is otherwise identical.
   - **Anomaly counts are unchanged:** `--model v2` 11/11, `--model v2 --progression v2` 12/12, `--model v1` 15/15.
   - **JSON:** HEAD-tool output and new-tool output differ only in `"ms"` fields and the new block.
   - **Why the files are spliced:** the committed `playtest_v2.json` and `playtest_v1.json` were originally produced in `fresh` mode, and every run changes the ms timings. A plain regeneration would therefore rewrite measureMode/ms lines. To keep the diff additive, the committed files are HEAD content with the tool-generated `componentChecks` block (taken verbatim from the new run) inserted after `recovery.note`.
   - **Resulting `git diff`:** +55/-1 per file. The single "-" line is `recovery.note`, which gains a trailing comma because a key now follows it. No value changed or was removed. The suite (criterion 3) proves that each spliced block equals a recomputation from the file's levels.
5. [x] All three modes exit 0, print `DIFFICULTY_PLAYTEST OK`, and write JSON containing `recovery.componentChecks`:
   - `--model v2 --committed-measure`: `DIFFICULTY_PLAYTEST OK levels=10 anomalies=11`
   - `--model v2 --progression v2 --committed-measure`: `anomalies=12`
   - `--model v1 --committed-measure`: `anomalies=15`
6. [x] Informational results on the shipped L1..L10. These are reported only; nothing was tuned.
   - **v2 model, both progressions (identical, because the vectors do not depend on the lanes):**
     - 3->4 pass: A 0.492->0.108, B 0.047->0.000, U 0.513->0.471, SL 35.64->25.04.
     - 5->6 pass: A 0.109->0.044, B 0.057->0.008, U 0.492->0.436, SL 26.60->25.21.
     - 8->9 FAIL: A 0.141->0.408 (above), B 0.033->0.152 (above), U 0.467->0.530 so B and U are both above, SL 25.11->25.07 (below, passes). This is the inversion the proposal expects.
   - **v1 model:**
     - 3->4 pass.
     - 5->6 FAIL on A (0.687->0.706) and B (0.459->0.474).
     - 8->9 FAIL on A (0.613->0.695) and B (0.438->0.482). The B/U check passes because U is equal at 0.410, and SL passes.
7. [x] Regression suites, each exit 0 with 0 script errors:
   - m36_progression_v2_reader PASS (55 cases)
   - m36_anchor_calibration PASS (126 cases)
   - m36_difficulty_v2 PASS (38/38)
   - m36_difficulty_v1 PASS
   - m37_level_progression PASS
   - m53_first10_difficulty PASS
8. [x] `git diff --stat main -- data/config` is empty. `git diff --check main..HEAD` is clean. docs/10 section 13 now has the "Recovery-slot constraints (SB-M36-014 ...)" paragraph with bullets covering: recovery A <= peak A; B <= peak B; not above on both B and U; recovery Session Load < peak Session Load; scalar minimums governed by `recoveryGuards`; generator/CampaignBuilder constraints, not hidden per-player DDA; shipped L1..L10 informational. It cites the proposal doc and `recovery.componentChecks`.

## Validation
All runs used Godot 4.7.2 console `--headless` and recorded LOCAL_PASS:
- the three `difficulty_playtest.gd` modes with `--committed-measure`, each run with both the HEAD and the new tool: all exit 0;
- `tests/m36_recovery_component_checks.gd`: PASS;
- the six regression suites listed in criterion 7: all PASS;
- `git diff --check main..HEAD`: clean;
- `data/config` diff: empty.

Worktree note: `git status` still lists untracked/modified Godot `.import`/`.uid` artifacts. These were present when the job started (from the worktree import) and are not part of this job, so I did not stage or delete them.

## Log
### Round 0
- Implemented `recovery_component_checks` and wired it into `run()` as an additive key. The first patch attempt silently skipped two multi-line replacements because of CRLF; I caught this when the first regeneration lacked the block, then killed those runs and restored the evidence files.
- Wrote the suite and the docs/10 and AGENTS.md text.
- Ran the HEAD-vs-new comparison in 3 modes and spliced the generated blocks into the committed evidence files.
- Ran the 7 suites and updated TASKS.md.
