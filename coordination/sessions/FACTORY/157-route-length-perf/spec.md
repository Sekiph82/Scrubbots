# 157-route-length-perf (SB-PERF-ROUTE-2026-11-13)

Source: Factory Claude spec, 2026-11-13, owner-requested. Continues job 156 (6534537c).

## Goal
Make the Difficulty V1 route-length measurement faster: the analyzer observer computes a full route
per robot claim (~80% of measure() time after 156). If the same code serves ProofKernel, speed it there too.
Candidates: compute only the length the metrics need; reuse routes when the board around them is
unchanged; per-level routing precompute; one flood per source; packed arrays, no hot-loop allocation.

Target: measure() on LF-000147 and LF-000148 at least 2x faster than on 6534537c (70.5 s / 80.3 s),
plus a faster apply_placement() if the same code is involved.

## Hard requirement
Byte-identical: every measure()/score() field, every ProofKernel result (clears, active_after, placed),
trace hash, solver status, real-play outcomes. Reuse and extend tests/difficulty_v1_identical_output.gd
(30 campaign, anchors, LF-000147/148; goldens made on 5d19621c). Watch it fail on a deliberate change.
If an exact match is impossible somewhere, drop that speed-up and report; never change a score.

## Inputs
factory/jobs/157-route-length-perf/inputs/LF-000147 and LF-000148 (copies; originals read-only in
the Pixel Art Generator folder).

## Must not change
Game rules, ProofKernel semantics, Difficulty V1 formulas/constants/anchors, released or campaign level
data, the real-play refill-at-once rule, the slot pop hold (628ab240).

## Done when
- Old (6534537c) and new seconds per part, route-length part separate, apply_placement() mean.
- Identical-output regression passes on campaign, anchors, Factory levels.
- Full headless suite passes, exact counts.
- One code commit; orchestrator pushes, runs CI, reports the hash.
