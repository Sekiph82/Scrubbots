# 157-route-length-perf decision

APPROVE (2026-11-13). CLAUDE_PEER_REVIEW round 1: PASS, no blocking findings (round-1/review.md).

- Code commit ec1e57a7: same Dijkstra (seeding, eps relax, pop order, neighbour order) over a fresh cell-state snapshot with inline heap, plus a per-[start,w,h] rail entry cache, only behind the existing exact ProductionAccessQuery fast gate. Runtime default step cost still answers via _railroad_layered first.
- Byte-identical: campaign+anchors 58/58, Factory 5/5, CI subset 9/9 (fast path vs reference 772 routes, 0 mismatch); mutation (tie-break swap) fails 4/9.
- measure(): LF-000147 70.5 -> 27.1 s, LF-000148 80.3 -> 29.6 s; route-length part 54.4 -> 15.7 / 63.5 -> 18.0 s. apply_placement unaffected (kernel builds no routes since 156).
- Suites LOCAL_PASS: CI list 94/94, extra 19/19; reviewer reran identical 9/9 and real_play_levels 4/4.
- Non-blocking: route-equality case runs at default step cost; a TOTAL_TRAVEL_COST case would pin the fast path directly (goldens and mutation already cover it).
