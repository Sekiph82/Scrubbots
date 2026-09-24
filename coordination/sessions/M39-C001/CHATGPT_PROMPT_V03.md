# M39-C001 V03 — Frozen-Finding Full Remediation

Read first:
- CHATGPT_AUDIT_V02.md
- CHATGPT_AUDIT_CRITERIA_V03.md
- OWNER_ECONOMY_REWARDS_V01.md
- M37 CLAUDE_LOG_V03.md after M37 V03 is pushed
- relevant M23..M30 accepted implementation/audit contracts
- AUDIT_INDEX.md

Close the complete frozen set F-M39-V02-001..016. Do not stop after the first green subsystem.

## Phase 1 — canonical economy/config/import hardening
Fix EconomyConfig, Wallet resource IDs, Reward/Gift/Booster snapshot validation, Heart/2x domains, Collection claimed-state coherence and Daily canonical state.
Add malformed/fractional/duplicate/unknown-key tests.

## Phase 2 — first-clear + restart transaction authority
Create one narrow progression/economy transaction coordinator or equivalent atomic seam.
A current-frontier M37 transition must authorize first-clear economy.
Stale/future/replay cannot grant.
Wire gameplay-start truth from the first accepted real player action.
Retry-after-action consumes one Heart + resets streak; pre-action Retry does neither.
Failed Retry changes neither.

## Phase 3 — real capacity 5/6 through M24/M26/UI/M27
Extend:
- FiveSlotStrip to render/bind current 5/6 capacity;
- SlotOriginProvider to use live strip/engine capacity and route slot 5;
- ProofKernel to reconstruct/read/iterate/originate using state.capacity;
- production host sync/layout to display six correctly.

Keep baseline five behavior intact.

## Phase 4 — booster solver + transaction repair
Random:
- deterministic bounded search;
- prove >=3 consecutive accepted safe choices before commit.

Selector:
- construct and solve the actual post-extraction/post-placement state.

Transaction runner:
- rollback the failing stage itself when it partially mutated.

Tornado:
- implement owner-required selected-color in-flight/claim/reservation/agent reconciliation.
- do not globally reset unrelated work.
- if current M25/M26/M19 APIs lack targeted cancel, add the smallest identity-safe targeted cancellation seam with preflight + rollback.
- fault-inject partial mutation inside stages.

+1 Slot:
- make economy reservation/capacity + engine grow atomic with refund/rollback.

## Phase 5 — Daily local-time law
Use injectable local-date provider + wall-clock provider so tests can cross local midnight and simulate rollback deterministically.
Persist last local date, last claim timestamp, highest-seen timestamp, task date and task completion.
Make login reward + streak/day mutation atomic.

## Phase 6 — real runtime action seams
Expose production host/controller action methods for all four boosters and paid/manual speed operations.
These are gameplay/economy action APIs, not final UI.
No UI direct wallet/state mutation.

## Evidence
Create task_logs_v03 for every affected task in the V02 coverage ledger, including at minimum:
SB-M39-001,002,005,006,007,008,019,020,022,023,029,030,031,032,033,035,036,037,039,040,041,042,043,044,045,047C,051,052.

Every log must cite which frozen finding(s) it closes.

Create:
`coordination/sessions/M39-C001/CLAUDE_LOG_V03.md`

The canonical log must include:
- F-M39-V02-001..016 closure table;
- implementation commit SHAs;
- exact tests and results;
- before/after fault evidence;
- remaining SB-M39-033 DEVICE_REQUIRED truth.

Do not edit TASKS.md.
Do not self-audit.
Push implementation by coherent phase, then logs.

Handoff:
`AWAITING_AUDIT / M39-C001 V03 / DEVICE_GATE_REMAINS / FULL_SURFACE_REAUDIT_REQUIRED`
