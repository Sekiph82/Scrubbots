# M26 Work Package 05 — 59x59, Hazard Bot & Milestone Closure
Tasks: SB-M26-029..030 plus final closure of SB-M26-001..030

Required:
- deterministic 59x59 high-density sanity run with timing/allocation observations;
- no avoidable O(board) work each scheduler tick;
- real Hazard Bot end-to-end auto-dispatch integration using real BoardState, M24, M25, routing, dispatcher, ScrubbotAgent and M20;
- real laid-out SlotCell start anchors mapped through BoardPresentation;
- no ghost agents;
- no duplicate target reservations;
- quota conservation;
- same-color multi-batch behavior;
- WAITING -> opened corridor -> wake;
- completion/free-slot cycle;
- reset leaves zero scheduler claims/agents/reservations;
- run the full master audit regression floor;
- produce task-by-task SB-M26-001..030 evidence table in CLAUDE_LOG_V01.md.
