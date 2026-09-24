# M37-C001 V02 — Strict-v2 Adversarial Validation Criteria

Validation-first. Production source must remain unchanged unless a test first demonstrates a concrete defect.

Required direct scenarios:
- same progression win twice;
- reentrant duplicate record_win;
- stale lower level completion after frontier advance;
- future level completion out of order;
- replay win and replay loss;
- import valid snapshot then replay a prior completion;
- malformed schema/current_level/completed types;
- fractional/non-finite numeric values must fail closed where integer state is required;
- duplicate completed IDs;
- 10->11, 20->21, 310->311;
- very large level numbers;
- failed import leaves exact pre-import state unchanged;
- catalog/content objects remain unchanged.

If any scenario fails, fix minimally and rerun all M35/M36/M37 regression.

SB-M37-006 owner gate is RESOLVED by `coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`: no shipping Level Select in V1; debug/test seam only. Audit must prove no player-facing level-select flow exists.

Handoff:
`AWAITING_AUDIT / M37-C001 V02 / STRICT_V2_VALIDATION_COMPLETE`