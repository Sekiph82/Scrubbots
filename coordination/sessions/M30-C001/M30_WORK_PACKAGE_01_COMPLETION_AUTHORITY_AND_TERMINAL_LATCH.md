# M30 Work Package 01 - Completion Authority & Terminal Latch

Tasks: SB-M30-001..004

- Implement the owner-locked WIN and LOSE rules from OWNER_WIN_LOSE_RETRY_DECISION_V01.
- Reuse M27 DeadlockClassifier exactly.
- Add one terminal authority: PLAYING / WON / LOST.
- Exact-once terminal event per attempt.
- Dirty/event-driven evaluation only. Do not run M27 proof every render frame.
- Fail closed on cross-engine inconsistency; do not call it LOSE.
