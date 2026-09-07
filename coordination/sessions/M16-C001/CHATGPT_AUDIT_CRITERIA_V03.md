# M16-C001 — Strict Audit Criteria V03

Final strict closure requires:

1. malformed non-null request rejected before field access;
2. malformed non-null board rejected before method use;
3. partial-board API object fails closed;
4. malformed request through validate_route makes zero access calls;
5. malformed board through validate_route makes zero access calls;
6. malformed request through validate_failure_result fails stably;
7. no runtime exception is needed to achieve rejection;
8. V02 finite-coordinate guards remain;
9. V02 finite-middle-point guards remain;
10. V02 success/failure metadata coherence remains;
11. V02 non-bool access verdict rejection remains;
12. normal bool access semantics remain;
13. detached points remain;
14. no retarget remains;
15. no BoardState/ReservationState mutation;
16. swappable contract remains;
17. board-local coordinate contract remains;
18. 59x59 coverage remains;
19. 53x59 coverage remains;
20. no M17 implementation leakage;
21. full Godot suite passes;
22. git diff --check clean;
23. governance untouched;
24. matching CLAUDE_LOG_V03 exists;
25. Claude does not self-audit;
26. ChatGPT discloses independent runtime rerun availability.

If all pass, ChatGPT may re-close SB-M16-002/003/010/011 and advance M17-C002 V02 to READY.
