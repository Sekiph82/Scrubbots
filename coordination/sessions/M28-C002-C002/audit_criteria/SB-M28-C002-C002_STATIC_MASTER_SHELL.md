# SB-M28-C002-C002 — CHATGPT AUDIT CRITERIA

## Owner authority

`coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`

## PASS requirements

1. All six exact owner masters (5-slot 3/4/5 + 6-slot 3/4/5) are committed byte-preserving with locked SHA-256 hashes; no substitutes.
2. Runtime selects shell by authoritative supply column count AND authoritative slot capacity (5/6).
3. Shell is uniformly transformed; no non-uniform distortion.
4. All live overlays/hitboxes use the same master-reference transform.
5. No duplicate visible rail, slot frames/connectors, profile chrome or supply chrome; selected shell itself supplies five or six slot/connectors.
6. BoardRenderer remains real runtime board truth.
7. Scrubbot runtime movement aligns to baked rail while routing truth remains unchanged.
8. Live slot contents align to all baked slot frames in both five-slot and six-slot masters.
9. +1 Slot switches to the matching six-slot master; reset/retry switches back to the matching five-slot master. No dynamically redrawn sixth slot/connector.
10. 3/4/5 supply live colors/counts and front-only hitboxes align to baked cells.
11. Profile overlays only authoritative Level/Bot Parts/robot data.
12. Pause/2x overlay matches baked control boxes and preserves economy/runtime truth.
13. Exactly four boosters; bottom ad region is layout-only, no unauthorized ad integration.
14. Obsolete baked speech instruction is not visible; no invented tutorial copy.
15. Required responsive matrix and safe areas pass.
16. Relevant regressions remain green; historical M21 baseline issues unchanged/documented.
17. 5->6->5 shell switching preserves live gameplay state and does not leak nodes/signals.
18. TASKS.md untouched by implementer.

Verdict:
`AUDITED_PASS / M28-C002-C002 / STATIC MASTER SHELL / OWNER VISUAL REVIEW REQUIRED`

Otherwise:
`CHANGES_REQUIRED / M28-C002-C002 / <finding>`
