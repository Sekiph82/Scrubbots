# M26 Work Package 04 — Pause, Reset & Concurrency Hardening
Tasks: SB-M26-024..028

Required:
- pause blocks new scheduling only;
- resume restarts deterministically without duplicates;
- rapid placement/scheduler callbacks serialized;
- nested/re-entrant scheduler steps fail closed or deterministically defer;
- multiple same-color + different-color batches/in-flight agents;
- reset guard/generation invalidates stale callbacks;
- reset cleans M25 claims/committed work before dispatcher/M20 destroys reservation truth;
- then cancel/free dispatcher agents and clear scheduler ledger;
- zero orphan ScrubbotAgent nodes;
- cancelled work never decrements remaining;
- unrelated reservations untouched;
- repeated reset idempotent;
- adversarial reset during route/preclaimed-dispatch/clear notification;
- no double spawn, overcommit, duplicate target, duplicate claim.
