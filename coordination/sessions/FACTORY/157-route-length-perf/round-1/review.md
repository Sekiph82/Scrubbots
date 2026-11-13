VERDICT: PASS

## Checks
- git diff --check 8e8c6fc7..ec1e57a7: pass (no output)
- difficulty_v1_identical_output.gd: pass, "Difficulty V1 identical output: PASS (9/9 cases, 0 fail)"
- real_play_levels.gd: pass, "REAL PLAY LEVELS: PASS (4/4 cases, 0 fail)"
- Workflow guard: now `grep -qxF 'Difficulty V1 identical output: PASS (9/9 cases, 0 fail)'`, matches the test's final line.

## Findings
None.

## Notes
Line-by-line against the reference Dijkstra (same file, below the fast branch):
- Seeding: same `better` test (INF, eps, `_rank_lt`), same parent -1, same src_rp. Seed order is the same as the old scan order (BOTTOM, LEFT, RIGHT, TOP; corner duplicates kept).
- Pop order: the inlined heap compares (cost, side, seq, cell) exactly like `_PackedHeap._less`. The key is a strict total order, so deferring pushes to a pending queue flushed before each pop changes nothing. `su`/`qu` are read once per pop; `side_of[u]` and `seq_of[u]` cannot change while `u` is expanded.
- Neighbours: up, right, down, left, with the same bounds checks. `nlin != target_lin and st != CLEARED` is the same rule as the reference fast branch (the target is enterable only as the final cell). `ncost = dist[u] + interior_step_cost`, the same eps relax. The stale check and the target break are the same.
- Sources: the reference `_classify != BLOCKED` is `idx == target or state == CLEARED`. Outside cells are not sources in either version. The cached table has the same cost0 expression.
- Cache key `[start, w, h]` covers everything the table depends on (entry and connector_len derive from start; geom from w and h). The table holds no board state, and the board filter is applied per call. It is bounded at 16 entries and is per routing instance.
- Snapshot: `get_cell_states_copy()` is taken fresh in each `_railroad_route` call, so there is no stale state across clears in one tick. The reference fast branch also read `board.get_cell_state` with no reservation or occupancy term, so nothing is missed.
- Runtime reach: with the default step cost, `_railroad_layered` answers first. The new path runs in gameplay only on a layered null (the guard fallback), and in the analyzer and ProofKernel, which use the equal-weight step cost. The equivalence is by construction, and the new test case checks 772 routes.

Minor, non-blocking:
- The new test case compares the default-cost fast route against the generic one. That mostly exercises `_railroad_layered` against generic, not the new inlined path. The goldens (analyzer, equal-weight) cover the new path. A case with `interior_step_cost = TOTAL_TRAVEL_COST` on both sides would pin it directly.
- The guard comment at android-family-first10.yml:49 says real_play "exact 5/5" while the check is 4/4. This is pre-existing.
