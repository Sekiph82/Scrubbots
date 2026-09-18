# M29 Work Package 01 — Front Input & Transaction Gate
Tasks: SB-M29-001..003

- Make only M28 supply front row interactive.
- Keep preview rows and five slots non-interactive.
- Emit column identity only; UI owns no engine truth.
- Production controller validates M23 has exactly 3/4/5 columns.
- Route activation through M24.select_front_batch(real M23,column).
- Refresh detached M23/M24 snapshots only after authoritative result.
- Full-slot rejection consumes nothing.
- Support mouse and touch without synthesized double-fire.
- Serialize reentrant activation.
