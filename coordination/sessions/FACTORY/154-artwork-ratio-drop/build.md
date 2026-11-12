STATUS: READY

# Build: drop the 25%-of-board artwork ratio (ADR-030 D2), keep the 200-cell floor

## Summary
Branch `factory/154-artwork-ratio-drop`, commit `dd54007a` (one commit: code, docs and tests together).
A production level now needs >= 200 non-VOID cells. The >= 25% of W*H condition is gone.
The 20..59 envelope, VOID semantics, analyzer, solver and campaign data are unchanged.

Files changed:
- `scripts/data/production_level_validator.gd`: removed `MIN_ARTWORK_FRACTION_NUM/DEN`; the check is now `artwork < MIN_ARTWORK_CELLS`; new message "production artwork needs >= %d non-VOID cells; got %d of %d"; doc comments updated.
- `tools/audit_level_art.py`: removed `MIN_ARTWORK_FRACTION`; the D2 check is now `void and nonvoid_cells < MIN_ARTWORK_CELLS`.
- `tests/void_cells_c001.gd`: header comment; the 40x40/399 case now expects acceptance; new 56x56/700 (accepted) and 56x56/199 (rejected) cases. The 20x20/199 rejected case is kept.
- `docs/05_TECH_DECISIONS.md` (ADR-030 D2 rule plus a dated "2026-11-12 owner amendment" line), `docs/03_LEVEL_DATA_SPEC.md` (both rule lines), `docs/LEVEL_ART_TECHNICAL_AUDIT.md` (audit-rule description), `CLAUDE.md` §7 ("Production needs >= 200 non-VOID cells (D2, owner amendment 2026-11-12).").

Searched for other places that enforce the rule: `scrubpack_v1.gd`, `level_importer.gd`, `production_art_level_builder.gd`, `level_validator.gd`, `level_factory/` and `content_pipeline/` had no ratio check. They all go through `ProductionLevelValidator`. After the change, `git grep "MIN_ARTWORK_FRACTION|of the board;|>= 25% of"` finds no enforcement. The only remaining hits are the two amendment notes, an unrelated accessibility line and one text string, covered next.

I left one stale description alone on purpose: `data/art_manifests/world10_sunken_harbor_v1.json:57` has a `voidRule` text string that still says "and >= 25% of W*H". It is free text in a campaign art manifest, not enforcement, and the spec says not to change campaign data. Correcting the string needs a follow-up.

TASKS.md was not edited (the orchestrator said not to).

## Acceptance criteria
1. [x] The validator rule is ">= 200 non-VOID cells" with no ratio: see the diff in `production_level_validator.gd`. `void_cells_c001` passes "40x40 with 399 artwork (< 25%) accepted" and "56x56 with 700 artwork (< 25%) accepted".
2. [x] Levels below 200 are still rejected: "20x20 with 199 artwork cells rejected (< 200)" and "56x56 with 199 artwork cells rejected (< 200)" both ok.
3. [x] The regression case failed on the old code first. With the new tests and the unchanged validator, `void_cells_c001` exited 1 with `FAIL: 40x40 with 399 artwork (< 25%) accepted`, `FAIL: 56x56 with 700 artwork (< 25%) accepted`, `VOID-CELLS-C001: FAIL (2)`. After the code change it exits 0: `VOID-CELLS-C001: PASS`, 207 ok, 0 FAIL, 0 SCRIPT ERROR/Parse Error.
4. [x] The audit tool no longer applies the ratio: the constant and the check were removed. `python -I tools/audit_level_art.py --self-test` prints PASS.
5. [x] The 30 campaign levels still pass and did not change. `python -I tools/audit_level_art.py assets/art/levels/previews/*.png` gives "SUMMARY: 30 images, 30 PASS, 0 FAIL", byte-identical to the output of the old (HEAD~) tool. The default source set gives "10 images, 10 PASS, 0 FAIL", also identical to the old tool. The commit touches no files under `data/levels` or `assets/art`.
6. [x] Docs updated: ADR-030 D2 (with the amendment line), LEVEL_DATA_SPEC lines 72 and 103, CLAUDE.md §7, and LEVEL_ART_TECHNICAL_AUDIT.
7. [x] The full headless suite passes (LOCAL_PASS): see Validation.

## Validation
- `python -I tools/run_suites.py` over all 92 CI-listed suites, run as 4 parallel shards: 90 PASS on the first pass. 2 failed only on timing thresholds while 4 shards and other agents' Godot jobs ran at the same time:
  - `m50_color_symbols`: "300 rebinds in 3928.3 ms"
  - `m46_performance`: "retry() on 59x59 worst 63.79 ms"; "frame mean 4.463 ms, p99 17.314 ms"

  Rerun alone, both pass: `m50_color_symbols status=PASS (10/10 cases, 0 fail)`, `m46_performance status=PASS (22/22 cases, 0 fail)`. Final result: 92/92 PASS. Neither suite touches the validator.
- Suites that use ProductionLevelValidator: `run_tests` (RESULT: ALL PASS), `cp04_remote_content_runtime` PASS (28/28), `campaign_l11_l30` PASS (5/5). `m36_v02_migration` is not in CI; I ran it separately and it printed "M36 V02 migration evidence: PASS" (exit 0, 0 diag).
- `tests/void_cells_c001.gd` (not in the CI list): PASS, 207 ok, exit 0, 0 diag. No CI exact-count guard exists for it, so the workflow needs no change.
- `python -I tools/audit_level_art.py`: PASS (10/10) and `--self-test` PASS. The 30 campaign previews pass 30/30, identical before and after.
- `python -I tools/validate_world_art_manifest.py` (it imports the audit tool): `--self-test` PASS, and the manifest check prints "world10_sunken_harbor_v1.json: PASS".
- `git diff --check` on the changed files: clean.
- I ran a one-off `--import` in the worktree first. It rewrote tracked `.import` files (line endings only) and `project.godot`. I restored those in the worktree, and the tracked tree is clean. The untracked import-generated `.uid`/`.import`/`.translation` files are left in place as instructed.

## Log
### Round 1
- Wrote the 56x56 regression cases and flipped the 40x40/399 case first. Ran them against the unchanged validator and got FAIL (2), as expected.
- Removed the ratio from ProductionLevelValidator and audit_level_art.py, then updated ADR-030, LEVEL_DATA_SPEC, LEVEL_ART_TECHNICAL_AUDIT and CLAUDE.md §7.
- Ran the full CI suite list, the void-cells suite, m36_v02_migration, the audit tool on the campaign art (old and new), and the world-art manifest validator. All pass; details above.
- Commit `dd54007a` on the job branch, not pushed.
