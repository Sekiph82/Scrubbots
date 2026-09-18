# M27 Work Package 02 — Search, Memoization & Solution Trace
Tasks: SB-M27-013..015, SB-M27-019..020

Implement deterministic legal-choice search over front-batch selections.

Required:
- branch over selectable column fronts;
- deterministic action ordering;
- DFS/BFS/A* choice documented, but no heuristic may prune legal solutions unsafely;
- memoized canonical states;
- explicit max states/depth and deterministic test mode;
- bound exhaustion => UNKNOWN_BOUND;
- SOLVED only at exact canonical completion;
- deterministic replayable solution trace;
- trace hash/summary;
- fixtures where greedy-first fails but alternate legal choice solves, proving the search actually branches.
