# M40-C001 V01 — ChatGPT Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M40-C001 V01 / FINDING_SET_FROZEN**

Implementation: `c39c59c013b3c79dc9cdc0e5f4c598995ac171f6`
Claude log: `coordination/sessions/M40-C001/CLAUDE_LOG_V01.md`

M40 is critical/stateful. The following material findings are frozen for V02.

## F-M40-001 — safe write is not an atomic temp-file replacement
`save()` validates a temp file, but then writes the canonical primary again with `FileAccess.WRITE` instead of renaming/replacing the validated temp.

A process/power failure during that primary write can still leave the primary truncated.

A backup may help, but the implementation does not satisfy the promised temp->atomic replace lifecycle.

## F-M40-002 — last-known-good backup can be overwritten by an invalid primary
Before writing the new primary, `save()` reads the current primary and copies its text to `.bak` without first validating that primary.

If the current primary is already corrupt but the backup is the last-known-good copy, a subsequent save can overwrite the good backup with corrupt primary text before replacement.

The backup write result is also ignored.

V02 must never destroy the last-known-good backup with an unvalidated primary.

## F-M40-003 — future-schema handling is fail-open into a new profile
A future-version primary with no usable backup causes `load()` to return `{ok:true, source:"defaults"}`.

That allows the app to continue as a fresh profile and a later save can overwrite the future-version file. This is not a safe fail-closed unsupported-version policy.

Future schema must return an explicit unsupported/blocking result and preserve the file without allowing automatic overwrite unless an explicit recovery choice/policy exists.

## F-M40-004 — integer-only persisted state is not validated strictly
Save validation delegates to service imports that frequently accept floats and truncate them with `int()`.

This violates the audit criterion requiring rejection of non-integer balances/counts and can normalize malformed data silently.

Schema version itself also accepts TYPE_FLOAT and coerces.

## F-M40-005 — Daily task state/claims are not fully persisted
M40 snapshots the M39 DailyService, but that service only persists login day/streak. Current-day task completion state is absent.

This fails the explicit M40 requirement to persist Daily task state/claims.

## F-M40-006 — canonical save runtime lifecycle is not integrated into app/bootstrap
The M40 commit adds SaveService and tests but does not modify the application/production bootstrap to instantiate one canonical save service, load it before gameplay state consumption, and save at defined lifecycle boundaries.

A correct library that is never used is not yet the shipping save system.

## F-M40-007 — upstream M39 state is not closure-ready
M40 serializes the M39 service graph, but M39 still lacks live 5/6 slot/solver/booster/manual-2x/runtime integration. M40 final schema validation must be rerun after M39 V02 changes so newly authoritative state cannot be omitted.

## Strict-v2 requirement
Even after source fixes, M40 requires adversarial V02 validation for crash/recovery/migration/rollback and exact-state postconditions.

Verdict string:
`CHANGES_REQUIRED / M40-C001 V01 / FINDING_SET_FROZEN`
