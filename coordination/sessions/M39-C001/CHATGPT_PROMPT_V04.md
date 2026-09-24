# M39-C001 V04 — Targeted Final Economy Remediation

Read:
- CHATGPT_AUDIT_V03.md
- CHATGPT_AUDIT_CRITERIA_V04.md
- OWNER_ECONOMY_REWARDS_V01.md
- accepted M19/M25/M26 reset/cancellation authority
- M37 V03 audit

Close only F-M39-V03-001..005. Preserve all accepted V03 work.

## Phase A — targeted Tornado cancellation seam
Add the smallest audited API needed to cancel one color's live M26 assignments without touching unrelated colors.

Design rule:
- read-only preflight first;
- prove scheduler assignment -> M25 claim -> reservation -> M24 committed work -> dispatcher agent identity;
- then targeted commit;
- rollback exact state on failure.

Do not call global reset().
Do not weaken no-ghost/no-double-clear laws.

Integrate Tornado with this seam and add same-color-in-flight success tests plus partial-failure rollback tests.

## Phase B — production local day
Extend EconomyServices/AppState construction to inject a real local-calendar ordinal provider.
Keep injectable providers for tests.
Test local midnight, month/year boundary and rollback.

## Phase C — +1 Slot rollback
Make engine + strip + economy/capacity one reversible transition.
Force the strip failure path in a test and prove exact 5-slot restoration.

## Phase D — atomic first-clear coordinator
Add a narrow transaction coordinator or snapshot/rollback boundary for progression + first-clear + streak/Gift + entitlement.
Fault-inject every downstream stage.

## Phase E — canonical action API
Create one production action facade/controller for all four boosters and durable Economy V1 actions listed in criteria.
No UI.
Return explicit committed action results/signals so M40 V04 can save only successful mutations.

Evidence:
- task_logs_v04 for SB-M39-005,006,030,033,035,036,037,039,040,044,052 and any accepted lower-layer task touched;
- CLAUDE_LOG_V04.md with F-M39-V03-001..005 closure table and exact test mapping.

Do not edit TASKS.md.
Do not self-audit.
Push implementation/tests, then logs.

Handoff:
`AWAITING_AUDIT / M39-C001 V04 / DEVICE_GATE_REMAINS`
