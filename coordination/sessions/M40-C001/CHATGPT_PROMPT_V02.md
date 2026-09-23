# M40-C001 V02 — Save-System Safety & Runtime Integration Remediation

Read V01 audit + V02 criteria and wait until M39 V02 is pushed before final M40 validation.

## Fix frozen findings
1. Replace direct-primary rewrite with validated-temp atomic/near-atomic rename/replace flow.
2. Rotate backup only from a validated primary; never poison last-known-good backup.
3. Check all I/O operation results.
4. Future schema with no compatible backup returns explicit unsupported failure and cannot be auto-overwritten.
5. Enforce exact integer schema/state types after M39 hardening.
6. Persist Daily current-day task state.
7. Integrate one SaveService into the real application/bootstrap and define load/save lifecycle seams.
8. Re-audit persisted field coverage after M39 V02.

## Adversarial tests
Use injected test paths and fault injection at every write/rotation stage.
Add a test where primary is corrupt, backup valid, then save is attempted and a failure occurs: valid backup must survive.
Add future-schema + subsequent save protection.
Add fractional numeric rejection.
Add runtime bootstrap ordering proof.

Do not overwrite V01 logs.
Create task_logs_v02 for affected M40 tasks, at minimum 001,005,006,008,009,010,011,012,013.
Create CLAUDE_LOG_V02.md with F-M40-001..007 closure table.

Commit implementation/tests, then logs, push.
No TASKS edit, no M41 work, no self-audit.

Handoff:
`AWAITING_AUDIT / M40-C001 V02 / STRICT_V2_REAUDIT_REQUIRED`