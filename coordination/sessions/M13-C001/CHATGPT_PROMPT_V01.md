---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: M13-C001
version: 1
createdAt: 2026-09-05T16:17:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M13
taskRefs:
  - SB-M13-001
  - SB-M13-002
  - SB-M13-003
  - SB-M13-004
  - SB-M13-005
  - SB-M13-006
  - SB-M13-007
  - SB-M13-008
  - SB-M13-009
  - SB-M13-010
baselineCommit: 01da05fe30a54c75179944c3b88c29c0cf7e152b
expectedClaudeLog: CLAUDE_LOG_V01.md
---

# SCRUBBOTS - M13-C001 Eligible Target Index V01

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Start on canonical:
`main`

Before reading implementation sources or changing files:

1. fetch origin;
2. safely synchronize local `main` with `origin/main`;
3. inspect and preserve all owner work;
4. do not use reset --hard, clean -fd, force push, rebase, destructive
   checkout, or any command that deletes/stages unrelated owner work;
5. do not create any Desktop/local handoff log.

All durable M13 evidence must exist only in:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md

Known repo-local untracked owner/temp paths from prior cycles must be preserved
unless their identity has changed. Unknown untracked paths fail closed:
preserve and record them.

## Objective

Implement M13 — Eligible Target Index, exactly SB-M13-001..010.

M13 is the efficient query/index layer that answers:

> Which currently eligible DIRTY cells exist for a palette/color?

It is **not** TargetSelector (M15) and it is **not** reservation ownership
(M14).

## Canonical sources

Read from current main:

1. https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
4. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
5. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
6. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
7. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_V01.md
8. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V02.md
9. https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
10. https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
11. https://github.com/Sekiph82/Scrubbots/blob/main/docs/04_ROADMAP.md
12. https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
13. https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/board/board_state.gd
14. https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/slots/slot_system.gd
15. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Apply at least AL-001, AL-003, AL-005, AL-009, AL-018, AL-019, AL-020,
AL-021 and AL-025 where relevant.

## Locked scope interpretation

Canonical M13 tasks:

- define eligible cell;
- group/query by color;
- efficient index/cache if measured useful;
- synchronize with BoardState;
- remove CLEAN cells;
- handle reservations;
- no-work query;
- exhausted-color test;
- last-target test;
- 3,481-cell benchmark.

### Eligibility definition for M13

Current implemented BoardState has:

- valid cell index;
- palette/color ID;
- DIRTY/CLEAN state.

It does **not** yet own a reservation state and it does not currently expose a
separate cell availability flag.

Therefore M13 eligibility is:

`valid index AND DIRTY AND matching palette/color AND not externally excluded as reserved`.

Do not invent additional blocker/accessibility/reachability rules.

Routing/path reachability is not M13 eligibility.

### Reservation boundary

SB-M13-006 means the eligible-query layer must be able to **exclude cells that
a future reservation system tells it are reserved**.

M13 must NOT:

- define reservation ownership;
- add RESERVED to BoardState.CellState;
- create persistent reservation state;
- atomically reserve;
- prevent double reservation by owning locks;
- release reservations;
- resolve arrival;
- implement concurrency semantics.

Those belong to M14.

A simple caller-supplied reservation/exclusion input to eligible queries is
the preferred boundary unless repository evidence requires an equally simple
alternative.

M02-017 and all M14 tasks remain open.

## Required architecture

Create a lightweight headless-testable eligible-target index/cache, following
the explicit preload convention.

Preferred location:

`scripts/gameplay/routing/eligible_target_index.gd`

The folder name does not authorize route generation. This class is targeting
data only.

The class should:

1. bind/configure against one BoardState;
2. build color-grouped candidate buckets from DIRTY cells;
3. provide color-based eligible queries without rescanning every board cell on
   every steady-state query;
4. provide a cheap no-work/has-work query by color;
5. synchronize a changed cell explicitly after BoardState mutation;
6. support full rebuild/rebind for a fresh/replaced BoardState;
7. remove CLEAN cells from eligible results;
8. restore a cell if it becomes DIRTY again and is synchronized;
9. return detached query results, not mutable internal bucket storage;
10. preserve deterministic row-major/index ordering unless there is a proven
    reason not to;
11. reject/handle invalid indices and invalid/unbound use deterministically;
12. accept a caller-supplied reserved/excluded index set for query filtering
    without storing/owning reservation state.

Do not expose mutable internal bucket references.

Do not duplicate BoardState's coordinate/indexing formula in production code.
Use BoardState's existing index/color/state APIs.

## TargetSelector / routing boundary

Do not implement:

- `TargetSelector`;
- a strategy that chooses the "best" or "first" cell for a Scrubbot;
- slot dispatch;
- route generation;
- pathfinding;
- movement;
- Scrubbot agent;
- reservation ownership.

M13 returns candidate/query truth only.

M15 will choose WHAT target.
M16+ will define HOW to route.

## Performance requirement

M13 is marked `[PERFORMANCE]`.

The goal is to avoid a full 3,481-cell rescan for every repeated color query.

Required evidence:

- exercise a full 59×59 / 3,481-cell BoardState;
- record index build/rebuild timing;
- record repeated color-query timing;
- if useful, compare against a naive full-scan baseline in the **test/benchmark
  harness only**, not production code;
- do not claim FPS/GPU/rendered performance from headless CPU timing;
- do not use a brittle hardware-specific millisecond pass/fail threshold.

Behavioral correctness, not an arbitrary timing number, is the test gate.

SB-M13-003 may close if implementation/code evidence proves steady-state
queries use the color index/cache rather than a full board scan and the
benchmark records the measured result.

## Required behavioral tests

Add direct tests covering at least:

1. unbound index returns safe no-work/empty result;
2. initial build groups all DIRTY cells by color;
3. queries return only requested color;
4. query results contain only valid indices;
5. CLEAN cell + sync removes it;
6. DIRTY restoration + sync adds it back once, no duplicates;
7. mutation of one color does not corrupt another color bucket;
8. invalid sync index fails without corrupting state;
9. full rebuild after multiple BoardState changes exactly matches board truth;
10. rebind to a fresh BoardState discards stale old-board candidates;
11. no-work query false when a color has eligible cells;
12. no-work query true/empty when color is exhausted;
13. last-target case returns exactly one candidate;
14. cleaning last target + sync produces no-work;
15. caller-supplied reserved/excluded target is omitted;
16. reserving/excluding the only target produces no-work;
17. removing reservation/exclusion makes the unchanged DIRTY target visible
    again without reservation state being stored inside the index;
18. reservation filter does not mutate cached membership;
19. returned candidate collection cannot mutate internal index truth;
20. deterministic ordering remains stable after remove/re-add/rebuild;
21. 59×59 / 3,481-cell correctness case;
22. rectangular-board correctness case;
23. steady-state color queries do not rebuild/full-scan board as part of the
    query implementation;
24. prior M11/M12 and full regression suite remain green.

Tests must directly observe claimed behavior per AL-018.

## Mandatory validation

Record every item separately in CLAUDE_LOG_V01.md:

1. safe local main ↔ origin/main sync and starting SHA
2. full `git status --short` and untracked classification
3. `godot --version`
4. root project verification helper
5. root headless boot
6. full baseline regression suite before M13
7. M13 source files/architecture inspection
8. eligible definition proof
9. initial color grouping proof
10. requested-color isolation proof
11. CLEAN removal proof
12. DIRTY restoration proof
13. per-cell sync isolation proof
14. invalid sync atomicity proof
15. full rebuild exactness proof
16. fresh BoardState rebind stale-state proof
17. no-work query proof
18. exhausted-color proof
19. last-target proof
20. reservation/exclusion filter proof
21. only-target-reserved no-work proof
22. reservation removal re-exposes DIRTY target
23. reservation filter does not become owned reservation state
24. detached-result / no mutable bucket leak proof
25. deterministic ordering proof
26. rectangular-board proof
27. 59×59 / 3,481-cell correctness proof
28. 3,481-cell index build/rebuild benchmark
29. repeated color-query benchmark
30. confirm no hardware-specific timing threshold used
31. confirm no FPS/GPU claim from headless timing
32. confirm query path does not full-scan BoardState each steady-state query
33. confirm no TargetSelector implementation
34. confirm no RoutingSystem/path generation
35. confirm no dispatch/Scrubbot-agent implementation
36. confirm no reservation ownership/RESERVED/atomic reserve/release
37. confirm M02-017 and M14 remain open
38. confirm M10/Scrubby owner gates unchanged
39. full post-implementation regression suite
40. `git diff --check`
41. final scope/temp/binary inspection
42. recalculate canonical task progress from unique SB IDs
43. update only validated M13 task truth
44. update SESSION_INDEX
45. update H!ve ACTIVE_CYCLES / ARTIFACT_MAP / PROGRESS_SNAPSHOT
46. update PROJECT_DASHBOARD
47. `git status --short` before commit
48. focused M13-C001 implementation commit
49. safe non-force push to origin/main
50. verify implementation commit and CLAUDE_LOG_V01.md on GitHub
51. final `git status --short`

Claude-run tests/benchmarks are E1/E2 evidence only.

## Logging

Create and maintain only:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md

Do not create/update any Desktop/local handoff log.

Do not create `CLAUDE_IMPLEMENTATION_LOG.md`.

## Handoff

After all validated work:

- close only proven SB-M13-001..010;
- recalculate progress from canonical unique task IDs;
- set M13-C001 to `AWAITING_AUDIT`;
- update H!ve/coordination truth;
- commit/push safely to main;
- verify GitHub visibility;
- stop.

Do not start M14, M15, M16, LF00, CP00 or later work.
Do not create or modify CHATGPT_AUDIT files.
Do not generate Magnific assets.
