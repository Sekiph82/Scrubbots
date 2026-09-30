# M39-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-30
Auditor: ChatGPT
Task: `SB-M39-053`

Expected verdict if clean:

`AUDITED_PASS / M39-C002 CLOSED`

## A. Test-only scope — BLOCKING

PASS requires the fix to be test-fixture/evidence only.

FAIL if production behavior is changed in:
- HeartService;
- SpeedEntitlementService;
- EconomyServices;
- AppState;
- ProductionGameplayHost;
- +1 Slot transaction code.

## B. Correct root-cause treatment — BLOCKING

The fix must eliminate the moving OS wall clock from the exact rollback test.

Preferred:
- existing AppState clock injection;
- fixed deterministic wall clock;
- deterministic local-day provider;
- host consumes that injected graph.

FAIL for timestamp masking/normalization/tolerance.

## C. Strong exact rollback assertion preserved — BLOCKING

The assertion equivalent to:

`econ.snapshot() == pre_econ`

must remain.

No ignored fields.

No special-case removal of:
- `hearts.anchor`;
- `speed.clock_high_water`.

Engine/strip and charge/SB rollback cases must remain fully exercised.

## D. Fixed-clock evidence

PASS requires evidence that representative pre/post snapshots show:

- same deterministic `hearts.anchor`;
- same deterministic `speed.clock_high_water`;
- exact whole snapshot equality after forced rollback.

The fixed timestamp must be positive and deterministic.

## E. Temp-save hygiene

If AppState/temp save is used:

- unique test path;
- no canonical save touched;
- cleanup after run;
- no leftover file after the stability batch.

## F. Stability gate — BLOCKING

Final `m39_v04_integration.gd`:

- 10 consecutive isolated runs;
- 10/10 exit 0;
- zero rollback-equality failures.

9/10 is FAIL.

## G. Existing behavior preserved

The clean +1 Slot commit after forced failures still succeeds.

All prior Phase C checks remain present and pass:
- M24 back to 5;
- slot snapshot exact;
- strip capacity 5;
- capacity authority reset;
- exact economy rollback;
- sixth origin unroutable;
- can grow again;
- correct charge refund;
- clean grow to six.

## H. Wall-clock semantics still tested

PASS requires production clock behavior suites to remain PASS, including:

- hearts real/offline clock semantics;
- timed 2x wall-clock/anti-rollback;
- 900-second Heart authority.

The deterministic fixture must not accidentally remove clock behavior coverage project-wide.

## I. Regression / governance

Required:
- root 5323+ current checks PASS;
- relevant M39 suites PASS;
- M40 save PASS;
- M43 acquisition/economy PASS;
- M55 clock/economy PASS;
- git diff check clean.

FAIL if Claude edits `TASKS.md`.

Only documented historical M21 baseline signatures may remain in a broad parallel run.

## J. Closure

No owner visual/manual gate is required.

If A-I PASS:

`AUDITED_PASS / M39-C002 CLOSED`

Then move to:
`SB-M42-034 — Home Scrubby Hero Scale + Placement Lock`.
