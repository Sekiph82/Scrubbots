# M40-C001 V02 — Save-System Remediation & Strict Validation Criteria

Authority: frozen F-M40-001..007 plus original M40 criteria and post-M39-V02 state.

## 1. True safe replacement lifecycle
Validated temp data must become canonical through an atomic/near-atomic rename/replace strategy appropriate to Godot/platform APIs, not a second direct truncating write of the primary.
Document platform semantics honestly.

## 2. Protect last-known-good backup
Only a fully validated existing primary may rotate into backup.
Never overwrite a valid backup with an invalid/unvalidated primary.
Check every backup/rename/write result.
Fault injection must cover:
- temp write
- temp validation
- backup creation/rotation
- primary rename/replace
- restore after replace failure

## 3. Future schema is explicit unsupported state
Future-version save with no compatible backup must return a non-success unsupported/future-schema result.
Do not silently start a fresh profile that can later autosave over the future save.
Preserve original file.

## 4. Strict schema types
Schema version must be exact integer.
All integer-only persisted fields reject fractional/NaN/INF values through service imports.
No silent truncation.

## 5. Daily task persistence
Round-trip current-day task completion/claim-relevant state after M39 V02.

## 6. Production bootstrap/lifecycle
One canonical SaveService must be instantiated by the real application/runtime bootstrap.
Load must occur before persisted progression/economy/settings are consumed.
Define safe save boundaries (explicit lifecycle/event seams) without per-frame writes.
No competing save authority.

## 7. Post-M39 schema completeness
After M39 V02, re-enumerate every authoritative state field and prove SaveService includes required durable state.
Transient attempt-only +1 Slot active capacity must not accidentally persist as permanent base capacity, unless owner contract explicitly requires current-attempt restoration.

## 8. Atomic live apply
Candidate validation on scratch + live apply must leave exact prior live state on any failure.
Direct EconomyServices import atomicity from M39 V02 is part of this proof.

## 9. Migration/corruption adversarial matrix
Direct tests:
- corrupt primary + valid backup
- invalid primary must not poison valid backup on next save
- corrupt both
- old schema
- missing fields
- future schema
- fractional state
- unknown card/robot IDs
- stale tx replay
- Daily state
- Heart/timed 2x rollback/forward clock
- failure at every write/rotate stage
- repeated load/save
- app-bootstrap load ordering

## 10. Strict-v2
M40 cannot close on V02 implementation tests alone unless the V02 suite is explicitly adversarial and the later ChatGPT re-audit finds no material gap.

Handoff:
`AWAITING_AUDIT / M40-C001 V02 / STRICT_V2_REAUDIT_REQUIRED`