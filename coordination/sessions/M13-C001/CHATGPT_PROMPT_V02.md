---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: M13-C001
version: 2
createdAt: 2026-09-05T20:12:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M13
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
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
---

# SCRUBBOTS - M13-C001 Complete Remaining M13 + Audit Corrections V02

## FIRST ACTION — synchronize safely before all other work

Repository:

`C:\Users\sekip\Desktop\ScrubBots`

Canonical branch:

`main`

Before reading implementation sources or changing files:

1. fetch origin;
2. inspect local branch, local HEAD, origin/main and full `git status --short`;
3. preserve every pre-existing tracked and untracked owner/local change;
4. safely synchronize local main with origin/main only if that can be done
   without overwriting local owner work;
5. **do not use git restore, checkout-from-origin, reset, clean, force push,
   rebase or destructive checkout to erase pre-existing local changes**;
6. do not stage unrelated owner/local files;
7. if a pre-existing local modification/deletion blocks safe synchronization,
   record the exact blocker and stop as `BLOCKED` rather than erasing it;
8. do not create any Desktop/local handoff log.

All durable V02 evidence belongs only in:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V02.md

## Read first

1. Independent audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V01.md
2. Active V02 criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V02.md
3. V01 Claude log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md
4. V01 prompt:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V01.md
5. CLAUDE.md
6. tasks.md
7. coordination/AUDIT_INDEX.md
8. coordination/VERSIONED_LOG_POLICY.md
9. scripts/gameplay/board/board_state.gd
10. scripts/gameplay/routing/eligible_target_index.gd
11. tests/support/board_state_scan_spy.gd
12. tests/run_tests.gd

Apply AL-001, AL-003, AL-005, AL-009, AL-018, AL-019, AL-020,
AL-021, AL-025 and AL-026.

## Why this V02 exists

The owner intended the first M13 batch to cover SB-M13-001..005.

The V01 ChatGPT prompt accidentally over-scoped Claude to SB-M13-001..010.
Claude correctly followed the written prompt.

Therefore:

### Accepted V01 baseline — preserve, do not redesign

- SB-M13-001 Define eligible cell
- SB-M13-002 Group/query by color
- SB-M13-004 Synchronize with BoardState
- SB-M13-005 Remove CLEAN cells

### Open V02 work

- SB-M13-003 Efficient index/cache — production code looks correct, but the
  no-rescan regression spy is incomplete and must be strengthened.
- SB-M13-006 Handle reservations — provisional V01 code exists; formally
  validate it in intended scope.
- SB-M13-007 No-work query — provisional V01 code exists; formally validate.
- SB-M13-008 Exhausted-color test — provisional test exists; formally validate.
- SB-M13-009 Last-target test — provisional test exists; formally validate.
- SB-M13-010 3,481-cell benchmark — provisional benchmark exists; formally
  validate.

Reuse correct V01 implementation. Do not rewrite working code just to create
diff volume.

The goal is to finish **all SB-M13-001..010 in this one V02 pass**.

## Core M13 contract

Eligible target truth:

`valid BoardState index + DIRTY + matching palette/color + not caller-excluded`

M13 is an indexed query/cache layer.

It must not become:

- TargetSelector;
- reservation owner;
- RoutingSystem;
- pathfinding;
- dispatch;
- Scrubbot agent;
- gameplay orchestration.

## F-M13-001 correction — strengthen no-rescan observability

Current test spy counts only `get_cell_state()`.

That is insufficient.

Upgrade the test instrumentation so it can detect steady-state board traversal
through all relevant BoardState APIs used by EligibleTargetIndex or by a
plausible regression, including at minimum:

- `get_cell_count()`;
- `is_valid_index()`;
- `get_color_id()`;
- `get_cell_state()`.

Prefer explicit per-method counters plus an aggregate traversal/API counter.

The spy may internally call another spy method, but counters must be designed
so the test can unambiguously compare a snapshot immediately after build with
a snapshot after queries.

### Required direct proof

After bind/build has completed:

Run repeated:

- `get_eligible(color)`;
- `has_work(color)`;
- `count_eligible(color)`;

for present, absent and exclusion-filtered colors.

Assert **zero delta** for every relevant BoardState traversal counter.

The proof must catch a future implementation that performs:

`for i in board.get_cell_count(): board.get_color_id(i) ...`

even if it never calls `get_cell_state()`.

Also keep direct source inspection showing steady-state query methods read
cached buckets rather than BoardState.

Only then may SB-M13-003 close.

## SB-M13-006 — reservations / exclusions

Formally validate the existing seam.

M13 reservation handling means only:

- caller supplies excluded/reserved indices per query;
- excluded DIRTY candidates are hidden for that call;
- removing the exclusion makes the unchanged DIRTY candidate visible again.

M13 must store **no persistent reservation state**.

Must not add:

- RESERVED to BoardState;
- reservation owner;
- reserve()/release();
- atomic reservation;
- double-reservation lock;
- concurrency ownership;
- arrival resolution.

Those remain M14.

Add/retain direct coverage for:

1. one excluded candidate;
2. multiple excluded candidates;
3. duplicate excluded indices;
4. invalid negative/out-of-range excluded indices;
5. all candidates excluded;
6. some candidates excluded;
7. exclusion removal re-exposes candidate;
8. exclusion query does not mutate cache;
9. exclusion for another color/index cannot corrupt requested color;
10. Array/Dictionary-like caller set if the existing API supports both without
    adding unnecessary abstraction.

Invalid exclusion entries should simply have no effect on valid membership;
they must not corrupt or mutate cached truth.

## SB-M13-007 — no-work query

Directly prove:

- color has work;
- absent color has no work;
- exhausted color has no work;
- all candidates excluded means no work for that call;
- partial exclusion still has work when one valid candidate remains;
- unbound index safely reports no work.

Keep it cheap: do not materialize/scan the whole BoardState per query.

## SB-M13-008 — exhausted-color behavior

Directly prove both paths:

### Incremental sync path

- color starts with one or more DIRTY cells;
- final DIRTY cell becomes CLEAN;
- `sync_cell()`;
- bucket/candidate disappears;
- `has_work()` false;
- `get_eligible()` empty;
- color key is absent if that is the index invariant.

### Full rebuild path

After BoardState mutation without per-cell sync:

- `rebuild()`;
- exhausted color exactly matches BoardState truth;
- no stale candidate/key remains.

## SB-M13-009 — last-target behavior

Directly prove:

- exactly one candidate exists;
- query returns exactly that index;
- has_work true;
- excluding that only target makes per-query has_work false;
- dropping exclusion re-exposes it;
- cleaning + sync removes it;
- afterward has_work false and candidate list empty.

No target-selection strategy may be introduced.

## SB-M13-010 — 59x59 / 3,481-cell correctness + benchmark

Exercise real maximum production workload:

`59 * 59 = 3,481`

Required correctness:

- every DIRTY cell indexed exactly once;
- per-color counts match independently computed board truth;
- deterministic ordering;
- CLEAN sync removal at scale;
- exhausted color behavior at scale;
- other colors remain intact;
- exclusion filtering works at scale without mutating cached membership.

Required measurement:

- initial bind/build timing;
- rebuild timing;
- repeated indexed color-query timing;
- optional naive full-scan baseline only in test/benchmark code.

Required discipline:

- no hardware-specific millisecond pass/fail threshold;
- no FPS claim;
- no GPU/rendering claim;
- timing informational only;
- correctness is the pass gate;
- indexed and naive result sinks/membership must agree.

## Revalidate accepted SB-M13-001/002/004/005

Do not redesign them.

Run direct regression proof that:

### SB-M13-001
Eligibility remains exactly valid + DIRTY + matching color + not excluded.

### SB-M13-002
Color grouping remains exact and isolated.

### SB-M13-004
Per-cell sync, rebuild and fresh-board rebind match BoardState truth and never
leak stale old-board candidates.

### SB-M13-005
CLEAN synchronized cells leave the index immediately; DIRTY restore returns
them exactly once.

## API/encapsulation requirements

Keep:

- detached candidate arrays;
- no mutable bucket leakage;
- deterministic row-major ordering;
- safe unbound/invalid sync behavior;
- BoardState-owned indexing formula.

Also verify mutating any returned collection from:

- `get_eligible()`;
- `get_color_ids()`;

cannot mutate internal index truth.

## Scope gates

Explicitly prove no implementation of:

- M14 reservation ownership;
- M15 TargetSelector;
- M16+ routing/pathfinding;
- slot dispatch;
- ScrubbotAgent target searching;
- M02-017 reservation completion;
- M10/Scrubby owner decisions;
- LF00;
- CP00;
- Magnific generation.

M02-017 and all M14 tasks remain open after V02.

## Owner/local work safety correction

At V02 start, distinguish:

1. tracked task changes created during V02;
2. pre-existing tracked owner/local modifications or deletions;
3. pre-existing untracked owner files;
4. tool scratch/temp paths.

Never make category 2 disappear with `git restore`, checkout, reset or
overwrite.

Never stage category 2 or 3 unless the active prompt explicitly owns that file.

If a local owner change overlaps a required M13 file and prevents safe work,
stop `BLOCKED` and record the path instead of erasing it.

## Mandatory validation — record every item separately in CLAUDE_LOG_V02.md

1. safe fetch/sync attempt + starting local HEAD + origin/main SHA
2. full pre-work `git status --short`
3. classify every pre-existing tracked/untracked local change
4. confirm no pre-existing owner change was restored/reset/overwritten/staged
5. `godot --version`
6. root verification helper
7. root headless boot
8. full baseline regression suite before V02 changes
9. inspect V01 EligibleTargetIndex production source
10. inspect V01 scan spy and reproduce/document F-M13-001 observability gap
11. accepted SB-M13-001 eligibility regression
12. accepted SB-M13-002 color-group regression
13. accepted SB-M13-004 sync/rebuild/rebind regression
14. accepted SB-M13-005 CLEAN-removal/DIRTY-restore regression
15. upgrade full BoardState traversal/API observability counters
16. prove post-build repeated get_eligible adds zero relevant BoardState calls
17. prove post-build repeated has_work adds zero relevant BoardState calls
18. prove post-build repeated count_eligible adds zero relevant BoardState calls
19. prove absent-color query adds zero BoardState traversal
20. prove exclusion-filtered query adds zero BoardState traversal
21. explain why new spy catches a future get_color_id-based full-board scan
22. source-inspect steady-state query path for cache-only behavior
23. SB-M13-003 efficient index/cache proof
24. one-target reservation/exclusion proof
25. multi-target reservation/exclusion proof
26. duplicate exclusion proof
27. invalid negative/out-of-range exclusion proof
28. all-excluded no-work proof
29. partially-excluded still-has-work proof
30. exclusion removal re-exposes unchanged DIRTY target
31. exclusion does not mutate internal cache
32. cross-color exclusion isolation
33. confirm no persistent reservation state
34. confirm no RESERVED BoardState state
35. confirm no atomic reserve/release/double-reservation/concurrency ownership
36. SB-M13-006 formal validation
37. unbound/absent/present no-work query proof
38. exhausted no-work query proof
39. SB-M13-007 formal validation
40. incremental final-CLEAN exhausted-color proof
41. full-rebuild exhausted-color proof
42. stale exhausted color key/candidate absence proof
43. SB-M13-008 formal validation
44. exactly-one last-target query proof
45. only-target exclusion proof
46. exclusion removal last-target proof
47. clean-last-target + sync -> no-work proof
48. SB-M13-009 formal validation
49. rectangular-board correctness regression
50. 59x59 / 3,481-cell exact total/per-color correctness
51. 3,481-cell deterministic ordering proof
52. 3,481-cell CLEAN sync isolation/exhaustion proof
53. 3,481-cell exclusion-filter correctness/non-mutation proof
54. 3,481-cell build timing
55. 3,481-cell rebuild timing
56. repeated indexed-query timing
57. naive test-harness comparison result
58. indexed vs naive result agreement
59. confirm no hardware-specific timing threshold
60. confirm no FPS/GPU/render claim
61. SB-M13-010 formal validation
62. detached get_eligible result proof
63. detached get_color_ids result proof
64. invalid sync atomicity
65. no duplicate membership after repeated sync
66. M02-017 remains open
67. all M14 tasks remain open
68. no TargetSelector implementation
69. no RoutingSystem/pathfinding implementation
70. no dispatch/Scrubbot agent implementation
71. M10/Scrubby owner gates unchanged
72. no LF00/CP00/Magnific work
73. full post-V02 regression suite
74. `git diff --check`
75. final source/scope/temp/binary inspection
76. recalculate unique canonical SB task IDs
77. close only V02-proven SB-M13 tasks
78. expected all-pass task truth = SB-M13-001..010 complete
79. expected all-pass ecosystem progress = 206/943 = 21.85%
80. expected all-pass main+UI progress = 206/719 = 28.65%
81. update SESSION_INDEX
82. update H!ve ACTIVE_CYCLES
83. update H!ve ARTIFACT_MAP
84. update H!ve PROGRESS_SNAPSHOT
85. update PROJECT_DASHBOARD
86. full `git status --short` before staging
87. verify unrelated owner/local files are not staged
88. focused M13-C001 V02 commit
89. safe non-force push to origin/main
90. independently query/verify GitHub main contains V02 commit + CLAUDE_LOG_V02
91. final `git status --short`
92. set M13-C001 to AWAITING_AUDIT and stop

Claude-run tests/benchmarks are E1/E2 evidence, not ChatGPT audit verdicts.

## Task truth rules

Before implementation, this audit reopens:

- SB-M13-003
- SB-M13-006
- SB-M13-007
- SB-M13-008
- SB-M13-009
- SB-M13-010

Keep accepted:

- SB-M13-001
- SB-M13-002
- SB-M13-004
- SB-M13-005

After V02, if and only if every matching requirement passes, M13 should become:

- SB-M13-001..010 = complete;
- ecosystem = 206/943;
- main+UI = 206/719.

If any task fails its proof, keep that task open and report exact failure.

## Handoff

After all work:

- write only CLAUDE_LOG_V02.md;
- update task/coordination/H!ve truth;
- create focused V02 commit;
- push safely;
- verify GitHub visibility;
- set M13-C001 = AWAITING_AUDIT;
- stop.

Do not start M14, M15, M16, LF00, CP00 or later work.
Do not generate Magnific assets.
Do not create or modify CHATGPT_AUDIT files.
