# M35-C001 V02 — Catalog Hardening Audit Criteria

Close F-M35-001/003/004 and revalidate F-M35-002 after M36 V02.

PASS requires:
1. catalog consumers cannot mutate canonical internal entry objects;
2. every returned entry is immutable by ownership or a deep value copy;
3. get_entry_by_id cannot expose internal mutable identity;
4. order accepts exact integers only; fractional/NaN/INF values fail closed;
5. path duplicate detection canonicalizes equivalent res:// paths including dot-dot segments where legal;
6. escaped/out-of-root paths fail closed;
7. duplicate aliases remain detected after normalization;
8. after M36 V02, production catalog accepts class/dimension-independent valid entries such as 24x24 VERY_HARD and 38x38 EASY;
9. TEST remains rejected;
10. M21 production entry remains valid;
11. mutation/adversarial tests assert entry fields, not only Array container isolation.

Handoff:
`AWAITING_AUDIT / M35-C001 V02`