# M27 Work Package 04 — Runtime Deadlock Classifier
Tasks: SB-M27-025..033

Implement read-only runtime classification without UI coupling.

Required statuses:
- COMPLETED/SOLVED as appropriate;
- PROGRESSABLE or equivalent;
- WAITING/STALLED;
- DEADLOCK;
- UNKNOWN_BOUND.

Required logic:
- live M26 in-flight progress => never DEADLOCK;
- immediate claimable work => never DEADLOCK;
- legal selectable front + empty slot leading to progress => never DEADLOCK;
- waiting target that can open from legal scheduled progress => never DEADLOCK;
- true DEADLOCK only after no legal future progress sequence is proven;
- canonical five-WAITING/full-slots/no-inflight/no-unlock deadlock fixture;
- false-positive revival fixture;
- deterministic reason codes/debug evidence;
- reset/replay identical classification.
