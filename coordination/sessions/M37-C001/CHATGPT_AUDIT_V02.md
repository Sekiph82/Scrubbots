# M37-C001 V02 — ChatGPT Full-Surface Re-Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M37-C001 V02 / FINDING_SET_FROZEN**

Implementation: `bec7957`
Claude log: `coordination/sessions/M37-C001/CLAUDE_LOG_V02.md`

Owner decision:
`coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`
Shipping flow is forward-only. No player-facing Level Select. Debug seam only.

## Pass A — implementation/state sweep

### F-M37-V02-001 — future out-of-order wins are incorrectly accepted as canonical first-clears
`LevelProgressionService.record_win()` accepts any not-yet-completed positive level number.

The V02 strict test explicitly expects:
`record_win(99) == true`
while the frontier is level 4, then marks level 99 completed.

That is incompatible with the owner-locked forward-only shipping model. Without a shipping Level Select/replay path, canonical progression first-clear authority must not let an arbitrary future level become completed out of order.

This can also pollute persisted completion identity and later economy/idempotency state.

### Required law
For normal progression:
- only the current frontier level may produce a new first-clear;
- stale lower levels fail;
- future levels fail;
- replay remains non-advancing;
- debug frontier jump may exist only through the explicitly non-shipping debug seam.

## Pass B — evidence/test sweep
The V02 adversarial suite is load-bearing in the wrong direction: it codifies the future-level acceptance as expected behavior. This is a test-spec/product-law mismatch, not evidence of correctness.

## Coverage ledger
- SB-M37-001 cadence: PROVEN.
- SB-M37-002 current level: PROVEN.
- SB-M37-003 completion tracking: **DEFECT** (future completion accepted).
- SB-M37-004 replay: PROVEN.
- SB-M37-005 target curve: PROVEN.
- SB-M37-006 Level Select if approved: RESOLVED by owner as **NO SHIPPING LEVEL SELECT / DEBUG ONLY**.
- SB-M37-007 service implementation: **DEFECT** through record_win boundary.
- SB-M37-008 tests: **DEFECT** because V02 expects wrong future-level law.

### F-M37-V02-002 — imported completed-set truth is not coherent with a forward-only frontier
`import_snapshot()` validates element types and duplicates, but does not enforce campaign coherence.

Examples currently accepted:
- current_level=2 with completed=[99];
- current_level=10 with completed=[1,3,9];
- current_level=1 with non-empty completed set.

Under the owner-locked no-Level-Select forward-only model, canonical shipping progression produced by normal play is contiguous:
- current_level N;
- completed first-clears are exactly levels 1..N-1.

A malformed/gapped/future completed set must fail closed on import.

The non-shipping debug frontier seam may still create synthetic states in debug/tests, but those synthetic states must not redefine the canonical persisted shipping contract.

Frozen finding set: **F-M37-V02-001..002**.

Verdict string:
`CHANGES_REQUIRED / M37-C001 V02 / F-M37-V02-001..002`
