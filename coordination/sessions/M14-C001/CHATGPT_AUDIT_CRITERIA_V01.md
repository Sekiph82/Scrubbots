# M14-C001 — ChatGPT Audit Criteria V01

Decision can be AUDITED_PASS only if all required evidence below is satisfied.

## Architecture
1. Reservation ownership is explicitly defined.
2. Reservation state is separate from BoardState.
3. BoardState.CellState remains exactly ACTIVE/CLEARED; no RESERVED state is added.
4. ADR is recorded using the next valid ADR number.
5. Reservation layer owns temporary target assignment metadata only.
6. Future owner token is defined as a unique dispatch/agent assignment ID, not slot/color/cell identity.

## Reservation behavior
7. Valid ACTIVE target can be reserved.
8. Invalid/CLEARED targets cannot be reserved.
9. Invalid owner IDs cannot reserve.
10. Same target cannot be reserved twice.
11. One owner cannot hold two targets.
12. Different owners can reserve different targets.
13. reserve is synchronous check-and-set without await/deferred gap.
14. wrong-owner release fails without mutation.
15. correct release succeeds.
16. released target is reservable again.
17. simulated dispatch-failure lifecycle releases correctly.
18. reset clears all reservations.
19. rebind clears old-board reservations.
20. resolve_arrival validates ownership and resolves exactly once.
21. resolve_arrival does not mutate BoardState ACTIVE/CLEARED state.

## Integration / determinism
22. ReservationState exposes detached deterministic reserved indices.
23. ColorCandidateIndex excludes reserved targets only via caller-supplied exclusions.
24. ColorCandidateIndex still owns no reservation state.
25. release makes the ACTIVE candidate visible again.
26. no mutable internal reservation collections leak.
27. normal reservation lookup/reserve/release avoids full-board scans.

## Tests / performance
28. competing same-target calls prove exactly one reservation succeeds.
29. 59×59 / 3481-cell sanity/performance evidence exists.
30. full Godot 4.7.1 regression suite passes.
31. no parse/runtime errors.

## Scope
32. M15 TargetSelector is not implemented.
33. M16+ routing/agent/dispatcher/vertical-slice work is untouched.
34. palette, BG01, difficulty bands, slots and BoardRenderer contracts are unchanged.
35. source content/artwork is untouched.
36. tasks.md is untouched by Claude.
37. H!veAI tracker/dashboard files are untouched by Claude.
38. coordination/SESSION_INDEX.md is untouched by Claude.
39. matching CLAUDE_LOG_V01.md contains real implementation/test/push evidence.
40. Claude does not self-audit.

## Task closure eligibility after PASS

If all criteria pass, ChatGPT may close:
- SB-M02-017
- SB-M14-001
- SB-M14-002
- SB-M14-003
- SB-M14-004
- SB-M14-005
- SB-M14-006
- SB-M14-007
- SB-M14-008
- SB-M14-009

Expected progress after all ten closures:
- ecosystem: 224 / 943
- main game + SB-UI: 224 / 719
