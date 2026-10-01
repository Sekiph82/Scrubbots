# OWNER_UNCAPPED_BATCH_ROBOT_COUNT_DECISION_V01

Status: OWNER APPROVED
Date: 2026-10-01

## Decision

The former global `MAX_ROBOTS_PER_BATCH = 30` rule is retired.

Canonical rule:
- `robot_count` / supply-plan `robots` must be a positive integer;
- there is no fixed global maximum robots-per-batch limit;
- exact per-color conservation remains mandatory;
- exact grand-total conservation remains mandatory;
- FIFO order, three shipping columns and visible preview depth remain unchanged;
- existing plans remain valid;
- a plan's `maxRobotsPerBatch` may remain as declarative per-plan metadata equal to or above the largest batch in that plan, but it is not a global gameplay cap.

## Required runtime compatibility

`ColorBatch.make` and `BatchSupplyEngine` already accept positive integer counts without a global maximum and must remain that way.

`SupplyPlanLoader` must stop rejecting a plan solely because a valid positive batch count exceeds 30.

Any test or documentation asserting `<=30` as a gameplay rule must be updated.

## Level Factory dependency

This owner decision is required for the approved primary supply pipeline in:
`Sekiph82/ScrubBots-Level-Factory/docs/decisions/OWNER_PRIMARY_SUPPLY_PIPELINE_V01.md`.

A >30 batch must be proven loadable and solver-valid before the Level Factory integration is considered production-ready.
