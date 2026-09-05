---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: M12-C001
version: 1
createdAt: 2026-09-05T09:44:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M12
taskRefs:
  - SB-M12-001
  - SB-M12-002
  - SB-M12-003
  - SB-M12-004
  - SB-M12-005
  - SB-M12-006
  - SB-M12-007
  - SB-M12-008
  - SB-M12-009
  - SB-M12-010
  - SB-M12-011
baselineCommit: 4d87040b90c96cebd9aeff9a8663f11f25580a71
expectedClaudeLog: CLAUDE_LOG_V01.md
---

# SCRUBBOTS - M12-C001 Five-Slot Logic V01

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Before reading implementation sources or changing files, safely synchronize
the local repository with `origin/main` while preserving all owner work.

- Inspect local changes before integrating remote changes.
- Do not use `reset --hard`, `clean -fd`, force push, or other destructive
  Git operations.
- Do not create or update any Desktop phase log, Desktop handoff log, or other
  local evidence file.
- All durable implementation/test/coordination evidence for this prompt must
  exist only in GitHub:
  `coordination/sessions/M12-C001/CLAUDE_LOG_V01.md`.

Only after synchronization is complete, read the sources below and implement.

## Objective

Implement the M12 Five-Slot Logic data/model foundation for exactly
SB-M12-001..011.

This milestone creates the reusable slot model only. It does not dispatch
Scrubbots, choose targets, route agents, define slot-pressure puzzle rules, or
build final slot UI.

## Canonical sources

Read all of these from GitHub:

1. Governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical tasks:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. Coordination protocol:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
4. Versioned log policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
5. Audit policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
6. Audit learnings:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
7. M11 final renderer/session audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V03.md
8. M11 final coordination audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md
9. M12 audit criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V01.md
10. Project brief:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/00_PROJECT_BRIEF.md
11. Gameplay specification:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
12. Technical architecture:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
13. Roadmap:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/04_ROADMAP.md
14. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
15. Active H!ve status:
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
16. H!ve tracking:
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ACTIVE_CYCLES.md
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ARTIFACT_MAP.md
    https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROGRESS_SNAPSHOT.md

Apply AL-001, AL-005, AL-009, AL-018 and AL-019.

## Authority and design boundary

Canonical `tasks.md` is finer-grained than the coarse roadmap and controls
this cycle.

M12 is **model/data only** even though the older coarse roadmap mentions a
basic UI representation.

Locked facts:

- There are exactly **5 gameplay slots**.
- Slots represent color/robot types.
- Target selection and routing are separate future systems.
- A Scrubbot may eventually leave only when valid work exists, but M12 must
  not implement or infer valid-work/target availability.
- Remaining slot mechanics are a `[DESIGN GATE]`.

Therefore:

- no slot UI scene/widget;
- no input handling;
- no dispatch;
- no TargetSelector;
- no RoutingSystem;
- no Scrubbot agent;
- no win/lose;
- no slot stack/queue/quantity mechanics;
- no blocker/lives/booster rules;
- no assumption that palette IDs across five slots must be unique;
- no automatic relation between slot availability and board target existence.

## Required architecture

### SlotState

Create a lightweight, headless-testable slot state model, preferably
`RefCounted` and following AL-001 explicit preload conventions.

It must represent at least:

- stable slot identity;
- assigned palette/color ID;
- availability state;
- activity state.

Identity must not silently change after configuration.

"Availability" in M12 means only the slot model's explicit available/unavailable
flag. It does **not** mean "TargetSelector found valid work".

"Activity" in M12 means only the slot model's explicit active/inactive state.
It does not spawn or dispatch anything and does not imply exclusivity unless a
future rule explicitly defines that.

### SlotSystem

Create a lightweight, headless-testable system that owns exactly five
SlotState instances.

Requirements:

1. Slot count is a locked constant/invariant of five.
2. Slot identities are deterministic and stable, e.g. IDs 0..4 or an
   equivalent documented five-ID scheme.
3. Configuration accepts exactly five palette assignments.
4. Palette IDs must be validated against an explicitly supplied palette size
   or equivalent authoritative palette boundary.
5. Duplicate palette IDs are allowed. Do not invent a uniqueness rule.
6. Wrong assignment count, negative palette IDs, out-of-range palette IDs,
   invalid slot IDs and invalid state mutations fail deterministically.
7. Failed configuration/mutation must not partially corrupt previously valid
   slot state.
8. Availability and activity can be queried and changed independently.
9. Mutating one slot must not silently alter another.
10. Do not expose structural mutation that can change the system away from
    exactly five slots.
11. Provide a clear query API for slot count, slot identity, palette ID,
    availability and activity. A palette-based lookup/filter may be added if
    useful, but must not invent dispatch/target semantics.
12. Keep all model truth independent from UI/scene nodes.

The exact method names and result type are Claude's implementation choice.
Normal invalid usage must return deterministic/actionable failure rather than
crashing.

## Integration boundary

Do not add SlotSystem ownership to GameplaySession in this cycle unless an
existing authoritative source explicitly requires it. M12 tasks only require
the slot foundation itself.

Do not make BoardState, BoardRenderer, LevelLoader or LevelData depend on the
slot system.

M12 may use palette-size information in tests/configuration, but slots do not
own or mutate the level palette.

## Required tests

Add direct behavioral tests covering at least:

1. constructing/configuring exactly five slots;
2. deterministic stable slot IDs;
3. valid palette assignment for all five slots;
4. five slots with a palette smaller than five using duplicate valid palette
   IDs, proving duplicate colors are not incorrectly rejected;
5. availability query/change on one slot without changing others;
6. activity query/change on one slot without changing others;
7. availability and activity remain independent;
8. wrong number of palette assignments is rejected;
9. negative palette ID is rejected;
10. palette ID equal to/outside palette size is rejected;
11. negative slot ID is rejected;
12. slot ID >= 5 is rejected;
13. failed reconfiguration preserves the prior valid five-slot state;
14. invalid mutation preserves prior state;
15. query API does not permit structural count mutation;
16. model uses no UI/scene hierarchy as gameplay truth;
17. no dispatch/target/routing/agent behavior is introduced;
18. full prior regression suite remains green.

Tests must inspect the exact property they claim to verify per AL-018.

## Mandatory validation

Record every item separately in:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md

1. safe local ↔ origin/main synchronization and starting commit
2. `godot --version`
3. root project verification helper
4. root headless boot
5. full baseline tests before M12 implementation
6. exact five-slot construction/configuration proof
7. stable identity proof
8. valid palette/color assignment proof
9. duplicate valid palette assignment proof
10. availability independence proof
11. activity independence proof
12. availability-vs-activity independence proof
13. wrong assignment-count negative test
14. negative palette-ID test
15. out-of-range palette-ID test
16. invalid slot-ID boundary tests
17. failed-reconfiguration atomicity proof
18. invalid-mutation state-preservation proof
19. UI separation / no Node dependency check
20. confirm no dispatch/TargetSelector/Routing/Scrubbot implementation
21. confirm M10 owner gate unchanged
22. full post-implementation test suite
23. `git diff --check`
24. final scope/temp/binary inspection
25. recalculate canonical progress directly from `tasks.md`
26. update `tasks.md` only for validated M12 truth
27. update `coordination/SESSION_INDEX.md`
28. update H!ve ACTIVE_CYCLES / ARTIFACT_MAP / PROGRESS_SNAPSHOT
29. update PROJECT_DASHBOARD
30. `git status --short` before commit
31. focused M12-C001 commit
32. safe non-force push to `origin/main`
33. verify `CLAUDE_LOG_V01.md` and implementation commit are visible on GitHub
34. final `git status --short`

Claude-run test totals are implementation evidence only, not an audit verdict.

## Logging

Create the matching GitHub log at the start of work:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md

Do not create or update:

- `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M12_LOG.md`;
- any other Desktop/local handoff log;
- `CLAUDE_IMPLEMENTATION_LOG.md`;
- any `CHATGPT_AUDIT_*.md` file.

All durable work evidence is GitHub-only.

## Handoff

When all validated M12 work is complete:

- mark only actually proven SB-M12 tasks complete;
- set M12-C001 to `AWAITING_AUDIT`;
- update all required H!ve tracking files;
- commit and push safely;
- verify GitHub visibility;
- stop.

Do not start M13, LF00, CP00 or any later milestone.
