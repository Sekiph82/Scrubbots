# M18-C001 — Strict Adversarial Validation / Correction (V02)

Status: **ISSUED — strict-v2 correction/validation**

Read first:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M18-C001/CHATGPT_STRICT_REAUDIT_V02.md
- coordination/sessions/M18-C001/CHATGPT_AUDIT_V01.md
- this prompt
- matching audit criteria V02

## Scope

Fix only the strict re-audit findings:

- F-M18-STRICT-001 lifecycle re-entry
- F-M18-STRICT-002 direct proof of multi-segment large-delta traversal
- F-M18-STRICT-003 isolated agent performance/pooling evidence

Do not implement M19 or M20.

## Required correction 1 — single-use lifecycle

ScrubbotAgent is single-use.

`assign()` may succeed only when state == UNASSIGNED.

A second assign attempt while:
- MOVING
- ARRIVED
- CANCELLED

must return false and preserve:
- state
- owner_id
- color_id
- target_index
- spawn_origin
- target_position
- route points
- movement progress
- current position
- completion-emitted truth

No second completion can become possible through reassignment.

Also make `cancel()` terminal-safe:
- cancelling a MOVING agent -> CANCELLED;
- repeated cancel -> no-op;
- cancelling an ARRIVED agent should not downgrade ARRIVED or alter completion truth.

Document the lifecycle policy in ADR-026 if needed.

## Required adversarial tests — lifecycle

Add direct tests proving:

1. valid first assign succeeds;
2. valid second assign while MOVING fails;
3. failed second assign while MOVING preserves all assignment/progress state;
4. complete agent, then valid second assign fails;
5. ARRIVED state/end position/completion count remain unchanged after reassign attempt;
6. cancel agent, then valid second assign fails;
7. CANCELLED state/position/identity remain unchanged;
8. cancel after ARRIVED is a no-op;
9. no scenario can emit a second completion via agent reuse.

Use a second valid route/target so the test proves real re-entry rejection, not failure from malformed data.

## Required correction 2 — observable multi-segment movement proof

Do not use only the existing S2 comparison.

Create a deterministic handcrafted successful route with known geometry, for example:

```text
(0,0) -> (1,0) -> (1,1) -> (3,1)
```

Use a known speed/delta that:
- crosses at least TWO segment boundaries;
- does not yet reach the final endpoint.

Assert:
- exercised route has the expected segment lengths;
- travelled distance is beyond the first two cumulative boundaries;
- exact expected position on the third segment;
- exact progress as appropriate;
- still MOVING.

Also test a huge delta that crosses all remaining segments and snaps exactly to the endpoint once.

The test must fail if movement implementation only advances within one segment.

## Required correction 3 — isolated performance evidence

Precompute all valid routes BEFORE timing agent lifecycle.

For 5, 10, 25 and 40 agents:

1. build/validate all RouteResults first;
2. start timer only after routes are ready;
3. inside timed region measure:
   - ScrubbotAgent allocation
   - signal hookup if used
   - assign
   - deterministic movement to completion
   - free/cleanup
4. report agent-lifecycle CPU timing separately.
5. If route-generation timing is also printed, label it separately.

Do not claim FPS/GPU/mobile frame performance.

Pooling:
- do not add pooling unless isolated lifecycle evidence clearly justifies it;
- otherwise keep pooling deferred and state that the evidence only shows no current justification under this headless lifecycle test.

## Required regression checks

Preserve all prior M18 invariants:
- no BoardState mutation
- no ReservationState mutation
- no target selection
- no route computation inside agent
- no return
- no carrying
- cancel-before-arrival blocks completion
- 59x59
- rectangular VH
- debug scene smoke
- no M19/M20 implementation

Run:
- godot --version
- full headless suite
- git diff --check
- debug scene smoke

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- any CHATGPT audit/re-audit file

Write:
`coordination/sessions/M18-C001/CLAUDE_LOG_V02.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then stop.
