# M39-C001 V03 — Final Full-Integration Remediation Criteria

Authority:
- CHATGPT_AUDIT_V02.md frozen F-M39-V02-001..016
- OWNER_ECONOMY_REWARDS_V01.md
- M37 V03 forward-only progression contract
- M23..M30 accepted gameplay authority

M39 remains CRITICAL/STATEFUL.

## A. Economy config and canonical domains

A1. EconomyConfig must validate exact schema type before coercion.
A2. Every required owner-locked section/value must have explicit type/domain validation.
A3. Negative/fractional/non-finite/stringified numeric values fail closed where integers/numbers are required.
A4. Missing/extra contradictory core structures fail closed.
A5. Owner-locked exact values remain unchanged.

Wallet:
- only canonical SCRUB_BUCKS and BOT_PARTS resource IDs may exist;
- unknown/removed resources such as stars/event_points/profile_xp cannot be credited/debited/stored.

Reward/Gift/Booster persisted state:
- applied transaction IDs are non-empty strings, unique and canonical;
- Gift Bar queue entries have canonical id/cycle/milestone/claimed shape;
- milestone belongs to {10,50,250,500,1000};
- duplicate occurrence IDs fail;
- queue/applied state cannot contain malformed scalar entries;
- Gift Meter total/cycle counters are internally coherent;
- BoosterInventory rejects unknown fifth/extra booster keys, while allowing only documented metadata key(s).

Heart/2x:
- Heart anchor is canonical non-negative timestamp;
- entitled_level is exactly -1 or >=1;
- noncanonical sentinel/timestamp state fails closed.

Robot IDs:
- reject empty/malformed IDs;
- Scrubby remains initial unlocked robot;
- do NOT invent a closed-world robot roster until owner locks one.

Collection:
- claimed set implies that set is actually 9/9 complete;
- master_claimed implies all 15 sets complete;
- inconsistent claimed metadata fails closed.

## B. Forward-only progression + economy transaction authority

On WON:
- M37 current-frontier truth gates whether this is a NEW progression first-clear.
- no economy reward may be granted for a stale/future/replay/rejected progression win.
- first-clear SB/Bot Part + Win Streak + progression advance are one coordinated transaction.
- any failure leaves exact progression + wallet + streak + Gift Meter + Bot Part state unchanged.

Do not rely on "grant first, progression later".

## C. Restart/loss semantics

The first accepted real gameplay action arms attempt gameplay-start truth.
Successful Retry after real gameplay:
- consumes exactly one Heart;
- resets Win Streak to 0;
- preserves current-level 2x entitlement;
- resets attempt +1 Slot to baseline 5.

Pre-action Retry/exit:
- consumes no Heart;
- does not reset streak.

Failed Retry teardown:
- consumes no Heart/streak and does not mutate economy.

## D. Real 5/6 slot end-to-end support

FiveSlotBatchEngine, presentation, origin provider and solver must share the same active 5/6 capacity.

Required:
- baseline 5 visible/routeable/provable slots;
- +1 Slot -> exactly 6;
- slot index 5 renders and has a valid production routing origin;
- reset/new attempt -> 5;
- never 7+;
- FiveSlotStrip must not truncate a six-slot snapshot;
- SlotOriginProvider must not reject index 5 when capacity=6;
- capacity=5 behavior unchanged.

ProofKernel:
- reconstructs 5 or 6 according to ProofState.capacity;
- iterates actual active capacity;
- reads back slot 5;
- origin lane math uses active capacity;
- otherwise-identical 5/6 states produce different canonical proof behavior where appropriate.

## E. +1 Slot transaction atomicity

Economy reserve/capacity authority and M24 engine grow are one transaction.
Inject engine grow failure after economy reservation:
- no SB/charge loss;
- capacity authority returns to 5;
- M24 remains 5;
- no seventh state.

## F. Random booster owner-law proof

A proposed reorder may commit only if a deterministic solver simulation proves at least THREE consecutive legal accepted supply-front choices, with the resulting state remaining non-DEADLOCK through all three.

One current-state classifier call is insufficient.

If no qualifying reorder exists within deterministic bounds:
- no reorder;
- no charge/SB consumed.

## G. Selector proof and atomicity

Eligibility must be proven on the POST-EXTRACTION/POST-PLACEMENT state:
- selected arbitrary remaining batch removed exactly once;
- placed into current rightmost EMPTY slot, including slot 5 when capacity=6;
- solver-safe after placement;
- no duplicate/lost batch;
- failure anywhere restores exact supply + slots + economy.

## H. Transaction runner rollback

If a stage mutates partially and then returns failure, that same failing stage must be rolled back before earlier stages unwind.

Fault-inject:
- before stage;
- after first mutation inside multi-mutation stage;
- after later mutation inside stage.

Exact full pre-state must be restored.

## I. Tornado owner law

Do NOT replace owner law with a quiescence-only restriction.

For one selected present color, atomically:
- clear all remaining ACTIVE cells of that color;
- remove/reconcile remaining supply quota of that color;
- reconcile/free its slot batches;
- cancel/reconcile selected-color committed/in-flight assignments;
- cancel/reconcile selected-color agents;
- release selected-color claims/reservations exactly;
- preserve unrelated colors/agents/claims/reservations;
- recompute solver/deadlock truth.

If safe atomic reconciliation cannot be completed, consume nothing and restore exact pre-state.

Targeted cancellation may require a new narrow M25/M26/M19 API. It must preserve unrelated work and reuse existing identity/rollback laws.

## J. Daily local-calendar/rollback law

Use a canonical LOCAL calendar-date key, not unix_seconds/86400 UTC day arithmetic.

Persist at minimum:
- last claimed local-date key;
- last claim timestamp;
- highest-seen trusted/system timestamp;
- visible streak/cycle state;
- task-progress local-date key;
- current task completion state.

Clock rollback:
- cannot create duplicate claims;
- fails closed while time is behind trusted history until a new valid day is reached.

Daily tasks:
- prior-day completed tasks cannot be claimed on a later day;
- task state resets/binds by local day even when login reward was not claimed first.

Login claim is atomic with its reward:
- reward failure cannot advance last-claim/streak/cycle state.

## K. Production/runtime action integration

Production composition must expose canonical action seams for all four boosters and manual 2x/economy operations without UI directly mutating internals.

M39 does not need final visual UI, but the runtime action path must exist and be testable on the real host/service graph.

## L. Sixth-slot device gate

After code integration:
SB-M39-033 remains DEVICE/OWNER_REQUIRED for real mobile safe-area/touch/readability.
Desktop/headless code tests cannot close the device gate.

## Required adversarial suite

Must directly cover every frozen F-M39-V02-001..016 with finding-ID mapping in CLAUDE_LOG_V03.

Also rerun:
- M23..M30 relevant tests
- M37 V03
- M38 V02
- M39 V01/V02 suites
- root suite
- git diff --check

Handoff:
`AWAITING_AUDIT / M39-C001 V03 / DEVICE_GATE_REMAINS / FULL_SURFACE_REAUDIT_REQUIRED`
