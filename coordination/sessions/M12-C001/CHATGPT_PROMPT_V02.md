---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: M12-C001
version: 2
createdAt: 2026-09-05T10:57:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M12
taskRefs:
  - SB-M12-003
  - SB-M12-005
  - SB-M12-009
  - SB-M12-010
  - SB-M12-011
baselineCommit: 49bcabe4b55fe53a2757c414f11c0dcb7fd44cfd
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
---

# SCRUBBOTS - M12-C001 Slot Encapsulation Correction V02

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Before reading implementation sources or changing files, safely synchronize
the local repository with `origin/main` while preserving all owner work.

Do not use destructive Git operations.

Do not create or update Desktop phase logs, Desktop handoff logs, or any other
local evidence file.

All durable V02 evidence must be stored only in:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V02.md

## Read first

1. Independent audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md
2. Active V02 criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V02.md
3. V01 implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md
4. Governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
5. Canonical tasks:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
6. Audit learnings:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
7. Versioned log policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
8. SlotState:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/slots/slot_state.gd
9. SlotSystem:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/slots/slot_system.gd
10. Tests:
    https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd

Apply AL-001, AL-005, AL-009, AL-018, AL-019 and AL-020.

## Objective

Close only F-M12-001.

Preserve the accepted M12 five-slot model. Do not redesign slot mechanics.

## Required correction

The public SlotSystem API must not expose a mutable internally owned SlotState
that allows callers to bypass SlotSystem palette validation.

Currently:

`get_slot(slot_id)`

returns the internal object, whose public `set_palette_id()` can write any
integer.

Replace this leakage with the simplest clean query design.

Requirements:

- SlotSystem remains owner of its internal five SlotState instances.
- External callers can still query slot identity, palette ID, availability and
  activity.
- External callers cannot mutate an internal slot palette outside a validated
  SlotSystem-owned path.
- Prefer scalar getters or a detached snapshot/value representation over
  exposing mutable internal references.
- Do not add complex abstraction or reflection tricks.
- Duplicate valid palette IDs remain allowed.
- Existing availability/activity mutation methods may remain if their current
  semantics stay valid.
- Do not introduce new gameplay semantics.

If `SlotState.set_palette_id()` remains callable on independently created
SlotState objects, that is acceptable only if SlotSystem never leaks its own
internally owned objects. The invariant being protected is SlotSystem-owned
truth.

## Direct regression test

Add a test that fails against the current V01 API.

It must prove that public SlotSystem query access cannot be used to obtain the
internally owned SlotState and write an invalid palette ID such as 999.

Also verify:

- valid palette queries still work;
- stable slot identity remains queryable;
- five slots remain exactly five;
- duplicate palette IDs remain legal;
- failed configure remains atomic;
- availability/activity remain independent.

Do not claim encapsulation merely because intended setters validate. Test the
old bypass path itself.

## Mandatory validation

Record every item separately in CLAUDE_LOG_V02.md:

1. safe local ↔ origin/main sync and starting commit
2. `godot --version`
3. root verification helper
4. root headless boot
5. baseline full suite
6. demonstrate/document the pre-fix bypass condition from inspected V01 code
7. implement no-mutable-internal-reference query correction
8. direct old-bypass regression test
9. identity query proof
10. palette query proof
11. exact five-slot invariant proof
12. duplicate valid palette proof
13. availability/activity regression proof
14. failed configure atomicity regression
15. invalid slot/palette negative regression
16. no UI/dispatch/target/routing/agent/GameplaySession ownership
17. M10 owner gate unchanged
18. full post-fix suite
19. `git diff --check`
20. final scope/temp/binary inspection
21. recalculate progress from canonical tasks.md
22. update reopened task truth only after proof passes
23. update SESSION_INDEX
24. update H!ve ACTIVE_CYCLES / ARTIFACT_MAP / PROGRESS_SNAPSHOT
25. update PROJECT_DASHBOARD
26. git status before commit
27. focused M12-C001 V02 commit
28. safe non-force push
29. verify implementation commit and CLAUDE_LOG_V02.md on GitHub
30. final git status

Claude-run test results are implementation evidence, not audit verdicts.

## Stop

Set M12-C001 to AWAITING_AUDIT only after validation and GitHub visibility.

Do not create or modify CHATGPT_AUDIT files.
Do not create any Desktop log.
Do not start M13, LF00, CP00 or later work.
