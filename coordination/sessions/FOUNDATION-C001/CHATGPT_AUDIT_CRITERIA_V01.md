# FOUNDATION-C001 — BoardState Canonical State Audit Criteria V01

## Pre-fix sensitivity evidence
1. tests are added before any production BoardState fix;
2. valid-index state 2 is directly attempted;
3. valid-index state -1 is directly attempted;
4. valid-index state 255 is directly attempted;
5. valid-index state 3 is directly attempted;
6. valid-index state 99 is directly attempted;
7. Claude records pre-fix return/mutation/error behavior per invalid value;
8. invalid-state test cannot pass merely because the index is invalid.

## Canonical invalid-state contract
9. state 2 final behavior is false + no mutation;
10. state -1 final behavior is false + no mutation;
11. state 255 final behavior is false + no mutation;
12. state 3 final behavior is false + no mutation;
13. state 99 final behavior is false + no mutation;
14. invalid calls do not mutate sibling cells;
15. invalid calls do not change ACTIVE count;
16. invalid calls do not change CLEARED count;
17. invalid calls produce no SCRIPT/runtime error.

## Valid state regression
18. ACTIVE -> CLEARED succeeds;
19. CLEARED -> ACTIVE succeeds;
20. repeated canonical state assignment remains stable;
21. invalid index remains false/no mutation;
22. fresh board remains all ACTIVE;
23. get_cell_state exposes only ACTIVE/CLEARED after adversarial calls;
24. ACTIVE count + CLEARED count equals total cell count.

## Size / architecture
25. rectangular-board behavior remains correct;
26. canonical 59x59/max-board behavior remains correct;
27. CellState enum remains exactly ACTIVE=0/CLEARED=1;
28. no RESERVED or new state introduced;
29. flat PackedByteArray state storage preserved;
30. no unrelated BoardState redesign.

## Promotion/fix discipline
31. if pre-fix already rejects all values, production BoardState remains unchanged;
32. if any pre-fix case accepts/mutates/faults, log explicitly promotes FOUNDATION-STRICT-001 to M02/SB-M02-012 defect;
33. any required production fix is minimal and only guards canonical state before write;
34. Claude does not edit tasks.md.

## Downstream regression / governance
35. full Godot 4.7.1 root suite passes;
36. M13 candidate-index regressions remain green;
37. M14 reservation regressions remain green;
38. M15 target-selector regressions remain green;
39. M16/M17 routing regressions remain green;
40. M18/M19 root regressions remain green;
41. git diff --check clean;
42. governance untouched;
43. matching CLAUDE_LOG_V01 exists;
44. Claude does not self-audit;
45. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may mark FOUNDATION-STRICT-001 CLOSED.

If the pre-fix test confirms a production defect, ChatGPT will decide whether
SB-M02-012 needs a temporary audit reopen before final re-close.
