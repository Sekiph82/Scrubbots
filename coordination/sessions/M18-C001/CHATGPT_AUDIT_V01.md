# M18-C001 — ChatGPT Independent Audit V01

Decision: **AUDITED_PASS**

Policy basis:
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/README.md`

Audited against:
- `coordination/sessions/M18-C001/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M18-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- `coordination/sessions/M18-C001/CLAUDE_LOG_V01.md`
- implementation base `def36d03e019fb17c6d365ddc4d51ce6dc187df8`
- implementation commit `c7c11a79e46f548b5cc2d90fe9661122bb17aad4`
- actual diff/source/tests/docs/debug scene

## Evidence levels

### E1/E2 implementer evidence
Claude reports:
- Godot 4.7.1
- baseline 1412/1412
- post-M18 1483/1483 ALL PASS
- git diff --check clean
- 5/10/25/40-agent lifecycle stress
- debug scene smoke
- no leaked RID/ObjectDB warnings from M18 after cleanup fixes

### E3 independent evidence
ChatGPT independently inspected:
- exact V01 prompt/log/criteria match
- actual commit diff
- `scrubbot_agent.gd`
- debug controller + scene
- M18 test bodies in `tests/run_tests.gd`
- ADR-026
- M19/M20 non-scope
- governance diff

The ChatGPT audit environment does not provide a Godot executable, so the
1483/1483 suite was **not independently rerun**. It remains E2 implementer
evidence. Source, tests, false-positive risk and requirement mapping were
independently cross-checked.

## Requirement-level findings

1. **Lightweight agent core — PASS**
   One childless Node2D owns exactly one in-flight movement.

2. **Assigned color — PASS**
   Stored as identity/presentation metadata only.

3. **Assigned target — PASS**

4. **Assigned route — PASS**
   Route points come from detached RouteResult copies and are exposed copy-out.

5. **Spawn origin — PASS**

6. **No target selection — PASS**
   No TargetSelector dependency/API.

7. **No route computation — PASS**
   Agent consumes a finished RouteResult only.

8. **Board-local movement — PASS**
   Movement truth is in cell units; debug container alone maps to pixels.

9. **Small-delta movement — PASS**

10. **Large-delta multi-segment movement — PASS**
    Direct test compares one 0.5s advance with fifty 0.01s advances.

11. **Zero delta stable — PASS**

12. **Exact endpoint arrival — PASS**

13. **Completion once — PASS**
    `agent_completed` is guarded and repeated over-advance does not re-emit.

14. **Completion identity — PASS**
    owner/target/color are asserted.

15. **No BoardState mutation — PASS**

16. **No ReservationState mutation — PASS**

17. **No return-to-slot — PASS**
    Agent remains at endpoint and has no return API.

18. **No resource carrying — PASS**
    No payload/carry/deliver state/API exists.

19. **Cancel/reset stops movement — PASS**

20. **Cancel blocks delayed completion — PASS**

21. **Repeated cancel safe — PASS**

22. **No orphan nodes after cancel/free — PASS**
    Agent owns no child/tween/timer nodes.

23. **No orphan nodes after completion/free — PASS**

24. **5-agent concurrent test — PASS**

25. **10-agent concurrent test — PASS**

26. **25-agent concurrent test — PASS**

27. **Stress >25 — PASS**
    40-agent test exists.

28. **Deterministic repeated movement — PASS**

29. **59×59 route compatibility — PASS**

30. **Rectangular Very Hard compatibility — PASS**
    53×59 route used.

31. **Pooling decision — PASS**
    Pooling was not added; deferral is documented in ADR-026 and supported by
    lifecycle stress evidence. This is the correct outcome for SB-M18-015.

32. **ADR-025 intact — PASS**

33. **No M19 Dispatcher implementation — PASS**

34. **No M20 vertical-slice implementation — PASS**

35. **tasks.md untouched by Claude — PASS**

36. **H!veAI / SESSION_INDEX / AUDIT_INDEX untouched — PASS**

37. **Matching Claude log contains real evidence — PASS**

38. **No Claude self-audit — PASS**

39. **Independent rerun limitation disclosed — PASS**

## Audit nuance

SB-M18-009 “Despawn” is satisfied by the explicit completion seam plus
caller-owned free/despawn lifecycle rather than agent auto-`queue_free()`.
That is consistent with the prompt, which allowed either self-despawn or a
deterministic completion/despawn seam. The completion signal fires first, and
tests directly prove a completed agent can be freed with no orphan child/timer/
tween state. This keeps M19/M20 orchestration ownership clean.

## Final verdict

**AUDITED_PASS**

Eligible closures:
- SB-M18-001..015

M18 is complete. M19 — Scrubbot Dispatcher may now open.
