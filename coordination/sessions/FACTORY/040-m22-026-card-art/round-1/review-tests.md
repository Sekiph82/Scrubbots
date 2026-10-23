VERDICT: PASS

## Findings
None.

## Notes
Reproduced (worktree, Godot 4.7.2 headless):
- tests/m22_026_texture_budget.gd: exit 0, no SCRIPT ERROR. Last line: `M22-026 TEXTURE BUDGET: PASS`. The `[card art step 3]` block shows 135 arts, 400.45 MiB against the 440 budget, each <= 1080 px with alpha. Run twice.
- tests/m43_master_c007_collection.gd, 3 runs, each exit 0 with no SCRIPT ERROR or Parse Error. Last line each time: `M43 master C007 Collection evidence: PASS (13/13 cases, 0 fail)`.
  - Set-detail build times (pass 1 / pass 2): 235/225 ms, 311/239 ms, 308/248 ms. Peak nodes 111 (< 400).
  - Each run also printed an `at: clear (core/io/resource.cpp:822)` trace line. It does not fail the run.
- I did not rerun the other suites build.md lists (pity, booster budget, responsive matrix, color symbols, touch_r01).

The 150 -> 500 ms loosening in m43 `_k10`: judged NOT a weakening of the claimed property.
- The old 150 ms gate only held because of the static texture cache. It measured the second pass, with textures already cached.
- The spec (and the new budget test) deliberately remove the cache, so a 150 ms gate on repeat opens would now be unreachable. Every open decodes its 9 cards again, and I measured about 225-250 ms on pass 2.
- The check still gates what the test is for. It covers the worst of both passes, which now include the card-art loads. The old cold pass was only printed, never asserted. The peak-node bound (< 400) is unchanged.
- The 500 ms bound is about 2x the observed values and catches a runaway. The builder saw one noisy run at ~420 ms, so there is little headroom on a slow CI runner and some flake risk.
- The change is honest. The comment and the ADR record the cost.
- The product tradeoff is a repeat set-detail open going from about 85 ms to about 230 ms on this PC, and it will be slower on a phone. Consider a follow-up task: a scoped cache or threaded loading for the open path, if it feels hitchy on device.

Budget-test regression check: the builder's claim that the test fails against the old collection_screen.gd (FAIL (2)) is plausible. The `"_tex_cache" in CollectionScreen` check and the `ResourceLoader.has_cached` release check are direct assertions.
