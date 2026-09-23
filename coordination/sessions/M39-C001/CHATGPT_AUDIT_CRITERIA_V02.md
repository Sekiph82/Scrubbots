# M39-C001 V02 — Full Integration & Atomicity Remediation Criteria

Authority: V01 audit frozen findings F-M39-001..010 plus original V01 criteria.
M39 remains CRITICAL/STATEFUL.

## 1. Real M24 capacity integration
- FiveSlotBatchEngine/runtime slot state must consume one authoritative 5/6 capacity.
- baseline attempt = 5;
- +1 Slot => 6 exactly once per attempt;
- new attempt => 5;
- never 7+;
- all placement/full/rightmost-empty queries honor current capacity;
- existing five-slot regressions remain unchanged when capacity=5.

## 2. Real M27 solver integration
- active capacity is part of proof state/canonical key/equality/hash or equivalent authoritative solver state;
- 5-slot and 6-slot states with otherwise equal data must not canonicalize as the same state;
- deadlock/solvability logic operates correctly at both capacities.

## 3. Real production booster adapter
Implement a concrete production adapter wired to actual M23/M24/M25/M26/M27/BoardState systems.
Random, Selector and Tornado must no longer be fake-adapter-only.

Random:
- reorders only remaining unselected authoritative batches;
- preserves IDs/colors/counts/conservation;
- solver proves >=3 consecutive legal non-deadlocking front selections before commit;
- failure consumes nothing.

Selector:
- solver-safe eligible choices only;
- arbitrary remaining authoritative batch extraction;
- standard rightmost EMPTY placement at capacity 5/6;
- no duplicate/lost batch;
- failure consumes nothing.

Tornado:
- one present color;
- atomically reconciles BoardState ACTIVE cells, supply, slots, claims/reservations, in-flight agents/quotas and solver;
- fault injection at every stage;
- rollback restores exact full pre-state and refunds charge/SB;
- no ghost/double-clear/orphan agent.

## 4. Manual 2x shipping gate
Production manual 2x request path must consult SpeedEntitlementService.
No entitlement => no manual 2x.
Valid current-level/timed entitlement => manual switch allowed.
Free M23-exhausted automatic 2x bypasses entitlement and remains free.
No pitch/gameplay-law changes.

## 5. EconomyServices import atomicity
Aggregate import must stage/validate every section before mutating live state OR capture/rollback internally.
Direct calls to EconomyServices.import_snapshot must be all-or-nothing independent of SaveService.

## 6. Exact integer-domain validation
All integer-only economy state rejects fractional floats, NaN/INF and non-integer numeric representations instead of truncating:
wallet, Bot Parts, Hearts, timestamps where integer, booster counts, card counts, set IDs, transaction collections, Daily state, entitlement level IDs, etc.

## 7. Cards Exchange atomicity
SB credit and card removal form one transaction.
Inject failure after either side and prove exact rollback.
Ignore-no-return patterns are not acceptable.

## 8. Daily persistence
Snapshot/import must preserve current-day task completion and claim-relevant state required for relaunch continuity, while RewardGrantService tx IDs still prevent double grant.
Clock rollback remains non-duplicating.

## 9. Collection import canonical validation
Reject unknown card IDs, invalid set IDs, fractional/negative counts, inconsistent claimed-set/master state where applicable.
Do not silently store noncanonical keys.

## 10. Production runtime economy wiring
Wire the canonical service graph into real runtime/application composition.
Authoritative production events must drive:
- first-clear reward;
- streak win/loss/restart semantics;
- Heart loss/restart semantics;
- current-level entitlement completion clear;
- manual speed entitlement gate;
- booster actions.
No UI direct mutation.

## 11. Strict adversarial validation
Use real engine integrations, not only fakes, for closure-critical booster/capacity/speed scenarios.
Exact pre/post snapshots required for rejected/rollback cases.

## 12. Device gate
SB-M39-033 sixth-slot mobile safe-area/touch remains DEVICE/OWNER_REQUIRED after live sixth-slot integration. Provide a real production playtest scene/harness, do not fabricate device PASS.

## Regression floor
M23-M30 relevant suites, M37/M38 V02, all M39 phase tests, root suite, 5/6 solver/slot production tests, production booster integration tests, git diff --check.

Handoff:
`AWAITING_AUDIT / M39-C001 V02 / DEVICE_GATE_REMAINS / STRICT_V2_REAUDIT_REQUIRED`