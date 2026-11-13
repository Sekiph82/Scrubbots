# 156-difficulty-perf decision

APPROVE (2026-11-13). CLAUDE_PEER_REVIEW round 1: PASS, no findings (round-1/review.md).

- Code commit 6534537c: opt-in `verdict_only` reach-mask answer in ProductionTargetAccess (default off; runtime dispatch unchanged), used by ProofKernel lanes and LevelDifficultyAnalyzerV1 `_reach`/`peel_waves`.
- Byte-identical: campaign 30 + anchors 24 (58/58), Factory LF-000147/LF-000148 (5/5), verdict vs full probe 20096 cells 0 mismatches; goldens proven from base 5d19621c by reviewer; mutation ORIGIN_BELOW 4->5 fails.
- measure(): LF-000147 440.2 s -> 70.5 s; LF-000148 950.1 s -> 80.3 s. apply_placement mean 764 -> 100 ms / 861 -> 105 ms.
- Suites LOCAL_PASS: CI list 94/94, extra solver/difficulty 19/19.
- Follow-up (not done): observer route per claim is ~80% of the remaining measure() time.
