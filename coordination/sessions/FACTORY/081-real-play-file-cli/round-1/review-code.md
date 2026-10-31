VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (clean)
Godot suites: not run (reviewer-tests owns them); build.md reports real_play_file_cli 6/6 and real_play_levels 5/5.

## Findings
None.

## Notes
- `tools/real_play_file.gd` input validation matches the spec. It rejects missing, duplicate and unknown args and values that start with `--`. It rejects `res://`, `user://` and relative paths, and missing or unreadable files. The level goes through `LevelLoader` and the plan through `SupplyPlanLoader.load_engine`. Empty or non-int clicks are rejected. `--out` is rejected when it is inside the repo (normalised, case-folded) or its parent directory is missing. Every failure path returns text into one place, so the result line is printed and the exit is 2. An unwritable `--out` also exits 2 after the line is printed. Exit codes come from the `EXIT` table: 0 for WON_ROBUST, 1 for the other verdicts, 2 for INVALID_INPUT.
- The only file the tool writes is `--out`. Nothing is written to the repo, the catalog is never touched, and the inputs are never edited.
- The driver change keeps the catalog branch intact. `source is Dictionary` selects `app_state = null` plus the file paths. Everything from `build()` on is shared. The catalog `launch_entry_id` check and the temp-save cleanup are guarded by `path.is_empty()`, so they run only for the catalog. The not-in-catalog early return now frees the host it created, and no leak is introduced. `tools/real_play_verify.gd` and `tests/real_play_levels.gd` still pass an entry id string, which is unchanged. The suite's catalog_regression case compares the catalog path with the file path frame by frame.
- Small hardening, optional: `--out` equal to `--level-file` or `--plan-file` would overwrite an input, which breaks the "never edits inputs" statement. A one-line equality check in `_out_error` would close it. It is a caller bug and not a spec-listed case.
- `_norm` lowercases paths, so a case-sensitive Linux filesystem could in theory reject an `--out` that differs from the repo path only by case. That would be a safe false positive.
- The CI wiring is consistent. The suite is added to the loop, a new exact 6/6 guard is added, and the comment says 64 total. The run time of 133 s is under the 180 s bar.
- TASKS.md row status was changed READY to OWNER, which is appropriate while the Codex prompt waits for the owner.
