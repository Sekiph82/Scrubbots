# M38-C001 V02 — Strict-v2 Win-Streak Validation Criteria

Validation-first, critical/stateful.

Required adversarial scenarios:
- duplicate and reentrant first-clear callbacks;
- duplicate WON ordering around first-clear;
- stale prior-level callback;
- replay win/loss isolation;
- progression loss/reset/restart-after-action/pre-action-exit matrix;
- 4->5, 5->6, 9->10 exact wallet/Bot Part/Gift state;
- reward grant failure before any mutation;
- Gift Meter rejection/failure exact postcondition;
- snapshot/import then replay same tx;
- failed import leaves exact state unchanged;
- malformed/fractional/non-finite integer state fails closed;
- very large but valid streak boundary;
- all rejected operations preserve exact wallet/streak/gift/parts state.

Production source changes only after a failing pre-fix scenario.

Handoff:
`AWAITING_AUDIT / M38-C001 V02 / STRICT_V2_VALIDATION_COMPLETE`