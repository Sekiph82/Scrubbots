# 167-l200-ci-fix decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Fixes GitHub CI run 44049002157 after job 164 (200 levels).

- Code commit bf9b39ef: difficulty_v1_identical_output campaign set = catalog L1..L30 with golden id-set equality (goldens unchanged, existing 9/9 guard); m54_world_regression r06 uses the shipped 200-level catalog (World 02 Bubble District at L151, old no-trigger rule kept via an injected 1..150 catalog), new r08 plays a real L150 win to the World 02 popup and Home label; guard 8/8. Tests and workflow only, no game code.
- Suites LOCAL_PASS: full CI list via run_suites.py 96/96 (2 shards); reviewer reran m54 8/8.
