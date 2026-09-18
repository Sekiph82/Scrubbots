# M27 Work Package 03 — Generation Acceptance & Deterministic Retry
Tasks: SB-M27-016..018

Create generation-time orchestration around M23 candidate generation.

Required:
- solver gates production acceptance;
- SOLVED only accepted;
- DEADLOCK/UNKNOWN/malformed rejected;
- deterministic retry seeds/attempt index;
- configurable max attempts;
- exact per-color conservation preserved;
- reproducible acceptance/rejection sequence;
- fixture forcing at least one solver rejection before later accepted candidate;
- report base seed, effective seed, attempt, outcome, visited count, trace hash.
