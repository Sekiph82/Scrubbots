STATUS: READY

# Build: add m46_performance to validation_only CI

## Spec
Add tests/m46_performance.gd to the focused suite list in android-family-first10.yml, add an exact-summary guard, bump the header count. No threshold changes.

## Summary
Commit b8157471, only .github/workflows/android-family-first10.yml: suite appended to the loop list, header comment "M46: ... (44 total, exact 22/22 guard)", new guard block before the aggregate line (same pattern as M50/M51).

## Acceptance criteria
1. [x] Suite in list: "m46_performance" appended to the for-loop (diff).
2. [x] Exact string verified in source (tests/m46_performance.gd:2218 format, EXPECTED_CASES has 22 ids p01..p22): "M46 performance evidence: PASS (22/22 cases, 0 fail)".
3. [x] Header count updated (43 -> 44).
4. [x] git diff --check clean; tree clean after commit.

## Runner variance (report)
- The test does NOT scale or relax thresholds for CI/headless. Budgets are fixed constants (FRAME_STEADY_MS 4.0, FRAME_SPIKE_MS 16.7, PARSE_59 60, RENDER_CONFIGURE 40, INDEX_BIND 20, SELECT/ROUTE mean 2.0, etc.); retry() worst is gated at FRAME_SPIKE_MS*3 = 50.1 ms (line 557). _calib() is only a printed diagnostic, never used to scale.
- Header says "LOCAL ONLY" and "desktop CPU wall time"; it was never run on a GitHub runner.
- Flake risk on ubuntu-latest (2-vCPU shared): MEDIUM-HIGH for the wall-clock assertions (retry worst 50.1 ms, frame p99, parse 60 ms, atlas 250 ms). Memory/Object-count/determinism cases are stable. If the first CI run fails on timing only, it is runner variance, not a regression; the fix would be a separate, deliberate threshold decision (not done here). The shell timeout is 1500 s per suite; suite runtime on CI is unknown.
- Not run locally here (YAML-only change).

## Validation
git diff --check: clean. No Godot run (workflow-only change).

## Log
### Round 1
Implemented as above.
