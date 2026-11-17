# 175-ev02-ci-fix decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Fixes the intermittent m43_c001a failure in CI run 44099810993.

- Code commit 9c48fa0c: events service now() is read-only; _stamp() advances events_v02.hw only on receipt/join/claim; ev02_events_v02 asserts reads leave the save identical and receipts stamp hw. Root cause: every read advanced hw, so a second tick between two snapshots changed the save.
- Suites LOCAL_PASS: m43_c001a x4, ev02 x2, full CI list 98/98 (m46 timing passes alone); reviewer reran ev02 10/10 and m43_c001a 11/11.
