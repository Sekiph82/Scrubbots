---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C004
version: 1
createdAt: 2026-09-05T21:45:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V01.md
triggerAudit: M13-C001/CHATGPT_AUDIT_V02.md
baselineCommit: 62cde92cdeb443f4f91b31b5c3152b5bab0d8813
---

# SCRUBBOTS — META-C004 Gameplay Rule Migration: ACTIVE/CLEARED + Reachable Targets V01

## FIRST ACTION — safe synchronization

Repository:

`C:\Users\sekip\Desktop\ScrubBots`

Canonical branch:

`main`

Before reading implementation sources or changing files:

1. `git fetch origin`;
2. record local branch, local HEAD, origin/main full SHA and full
   `git status --short`;
3. preserve every pre-existing tracked and untracked owner/local change;
4. safely fast-forward/synchronize local main only if owner work is preserved;
5. do not use `git restore`, reset, clean, rebase, force push, destructive
   checkout, checkout-from-origin or equivalent to erase local owner work;
6. do not stage unrelated owner/local files;
7. if an existing local owner modification blocks safe work, fail closed as
   `BLOCKED` rather than overwriting it;
8. no Desktop/local handoff log.

Known previously observed untracked paths may include:

- `docs/logs/`;
- a Claude scratch/temp path.

Preserve and classify them if still present.

## Read first

1. M13 final audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V02.md
2. This V01 prompt.
3. Matching criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_CRITERIA_V01.md
4. CLAUDE.md
5. tasks.md
6. README.md
7. docs/00_PROJECT_BRIEF.md
8. docs/01_GAMEPLAY_SPEC.md
9. docs/02_TECH_ARCHITECTURE.md
10. docs/03_LEVEL_DATA_SPEC.md
11. docs/04_ROADMAP.md
12. docs/05_TECH_DECISIONS.md
13. docs/06_TEST_STRATEGY.md
14. level_factory canonical docs
15. content_pipeline canonical docs
16. current BoardState, BoardRenderer, debug fixtures/tool, GameplaySession,
    M13 index and tests.
17. coordination/AUDIT_INDEX.md and VERSIONED_LOG_POLICY.md.

Create and maintain only:

`coordination/sessions/META-C004/CLAUDE_LOG_V01.md`

for durable Claude evidence.

## OWNER-LOCKED GAMEPLAY REVISION

This decision supersedes the old gameplay-semantic DIRTY/CLEAN visual model.

### 1. Board pixel lifecycle

Every logical artwork pixel starts:

`ACTIVE`

An ACTIVE cell:

- is still present on the board;
- displays its original source palette color, unmodified;
- is opaque;
- participates in color matching;
- occupies/blocks board space for access/path semantics.

When a Scrubbot successfully cleans its assigned target, that logical cell
becomes:

`CLEARED`

A CLEARED cell:

- is no longer visually present;
- renders with alpha = 0;
- reveals the gameplay background underneath;
- is no longer a color candidate;
- becomes open/free space for future access/path semantics.

There is no gameplay-semantic DIRTY state.
There is no gameplay-semantic CLEAN-colored state.
There is no grime transform.
There is no A/B/C dirty preset.
There is no hidden second artwork layer being revealed.

The pixel artwork itself is what is progressively cleared away.

### 2. Important reachability rule

A matching color alone does NOT make an ACTIVE cell a valid final target.

Example:

```
R R B G Y
B G R Y P
G R Y B P
```

If the center matching red cell is surrounded/blocked by other ACTIVE cells
such that no legal access path exists, a red Scrubbot must NOT be dispatched
to it.

Therefore distinguish these concepts:

### COLOR CANDIDATE

A raw color candidate is:

- valid cell index;
- ACTIVE;
- matching Scrubbot/palette color;
- not caller-excluded/reserved.

### TARGETABLE / REACHABLE TARGET

A final target must additionally be currently reachable under canonical
board-access semantics.

Locked semantic rule:

- non-target ACTIVE cells block access/traversal;
- CLEARED cells are open space;
- gameplay background/outside-board free space is open;
- the assigned ACTIVE target may be the route endpoint;
- a fully enclosed/blocked matching-color ACTIVE cell is not targetable until
  prior clears create legal access.

Do NOT invent the final neighborhood topology, collision radius, route shape,
smoothing, curve style or movement language in this migration. Those remain
M16/M17 work.

But all current docs/tasks must now state the semantic law above, and no
current system may call a raw color candidate "reachable" or "eligible final
target."

### 3. Dispatch rule

A Scrubbot may leave one of the five visible slots only after the system has
a target that is ALL of:

- ACTIVE;
- color-matching;
- valid;
- unreserved;
- reachable/targetable under the access rule.

If no such target exists, the Scrubbot does not leave the slot.

On arrival:

- target becomes CLEARED;
- renderer makes it transparent;
- background shows through;
- candidate/index truth updates;
- reservation clears;
- Scrubbot disappears;
- no return route;
- no resource/color carrying.

## ARCHITECTURAL MIGRATION

### A. BoardState

Migrate:

```
CellState.DIRTY   -> CellState.ACTIVE
CellState.CLEAN   -> CellState.CLEARED
```

Preserve numeric ordering where practical:

```
ACTIVE = 0
CLEARED = 1
```

Fresh BoardState initializes all cells ACTIVE.
Reset recreates all ACTIVE.
State mutation/count APIs remain narrow and deterministic.

Do not add RESERVED in this cycle. M02-017/M14 remain open.

### B. BoardRenderer

ACTIVE:

- render exact source palette color;
- opaque, subject only to existing 8-bit texture quantization.

CLEARED:

- render `Color(0,0,0,0)` / alpha 0;
- background underneath must be visible.

Delete the old dirty transform/preset dependency.

Remove obsolete:

- DirtyCleanPresets preload;
- preset state;
- set_dirty_preset/get_dirty_preset;
- any DIRTY transform code.

Preserve ADR-011's one Image/ImageTexture architecture, nearest-neighbor
filtering, rectangular geometry and partial update behavior.

### C. Delete obsolete dirty preset production module

Remove:

`scripts/gameplay/board/dirty_clean_presets.gd`

Do not leave a compatibility alias. The project is early; stale semantics are
more dangerous than a compatibility shim.

Historical logs/changelog entries may still reference the old module as past
history.

### D. Rename M13 subsystem to ColorCandidateIndex

The current name `EligibleTargetIndex` is semantically wrong under the new
blocked-target rule because M13 does NOT prove route reachability.

Move/rename:

`scripts/gameplay/routing/eligible_target_index.gd`

to:

`scripts/gameplay/targeting/color_candidate_index.gd`

Create `scripts/gameplay/targeting/` if needed.

Rename API and comments from final-eligibility language to raw-candidate
language, e.g.:

- EligibleTargetIndex -> ColorCandidateIndex
- get_eligible -> get_candidates
- count_eligible -> count_candidates
- has_work may become has_candidates or equivalent precise name.

The final API naming must not imply reachability.

Candidate contract:

`valid + ACTIVE + matching color + not caller-excluded`

M13 continues to:

- group by color;
- use cache/index rather than per-query full-board rescans;
- remove CLEARED cells;
- restore ACTIVE cells in tests/tooling if mutation is deliberately reversed;
- support caller exclusion seam;
- provide no-candidate/exhausted/last-candidate behavior;
- pass 59x59/3,481-cell correctness/performance tests.

M13 does NOT:

- decide reachability;
- choose a final target;
- generate a route;
- own reservations.

### E. TargetSelector / reachability / routing seam

Preserve WHAT/HOW separation.

Update canonical architecture/tasks to make this exact:

```
ColorCandidateIndex
    -> raw ACTIVE matching-color candidates

Reachability/access semantics
    -> filter candidates that are currently blocked/unreachable

TargetSelector
    -> choose WHAT target among targetable/reachable candidates

RoutingSystem
    -> decide HOW to travel to the already selected target
```

TargetSelector must never generate routes.

RoutingSystem must never silently choose a different target if the assigned
one has no route.

Future implementation may use a narrow ReachabilityQuery/access-policy seam or
equivalent architecture, but do not implement M15/M16/M17 in this migration.

The task/docs contract must explicitly include the regression:

**a fully enclosed matching-color ACTIVE cell must not cause dispatch and must
not be treated as a targetable final target.**

### F. GameplaySession

Update reset/current-state terminology:

- all cells ACTIVE after load/reset;
- no dirty-count wording;
- do not introduce automatic completion logic unless already separately
  approved by the canonical win-condition tasks.

### G. Debug BoardRenderer tool

Migrate the existing:

`scenes/debug/board_renderer_debug.tscn`
`scripts/debug/board_renderer_debug.gd`
`scripts/debug/board_debug_fixtures.gd`

Remove preset A/B/C dropdown completely.

Replace state patterns with:

- All ACTIVE
- All CLEARED
- Half ACTIVE / half CLEARED
- Checker ACTIVE/CLEARED

Place a clearly visible debug background behind the board so alpha-0 CLEARED
cells visibly reveal that background.

The debug tool must still support:

- Easy/Medium/Hard/Very Hard boundary sizes;
- 59x59;
- rectangular boards;
- resizing.

This is a development visual tool, not production gameplay UI.

### H. Tests

Replace gameplay-semantic DIRTY/CLEAN tests with ACTIVE/CLEARED tests.

Required direct renderer proof:

- ACTIVE pixel readback matches source palette color within RGBA8 tolerance;
- ACTIVE alpha is opaque;
- CLEARED pixel alpha == 0 within appropriate tolerance;
- CLEARED does not substitute black/gray/another palette color;
- update_cells after ACTIVE->CLEARED produces transparent pixel;
- reset returns a fresh ACTIVE board and renderer follows the new BoardState;
- rectangular and 59x59 rendering remain correct.

Delete obsolete A/B/C transform tests.

Do not treat a lower aggregate check count as a regression merely because
obsolete dirty-preset tests were intentionally removed. Instead map old
behavioral coverage to new owner-approved requirements and report the final
test total truthfully.

M13 regression coverage must move to ColorCandidateIndex and preserve the
V02 full BoardState-traversal spy guarantee.

Add a terminology/architecture regression that current production code does
not expose `EligibleTargetIndex` or `get_eligible` as if raw color membership
were final reachability.

Do not implement actual routing solely to make a blocked-center test executable
in this cycle. Lock the blocked-target rule in docs/tasks/architecture and
future-test requirements.

### I. Canonical documentation migration

Update current/canonical documentation comprehensively:

- README.md
- CLAUDE.md
- docs/00_PROJECT_BRIEF.md
- docs/01_GAMEPLAY_SPEC.md
- docs/02_TECH_ARCHITECTURE.md
- docs/03_LEVEL_DATA_SPEC.md
- docs/04_ROADMAP.md
- docs/05_TECH_DECISIONS.md
- docs/06_TEST_STRATEGY.md
- relevant current UI docs if they contain gameplay-semantic DIRTY/CLEAN/reveal
- any other non-historical canonical file discovered by repository scan.

Project identity must change from "reveal artwork under grime" to:

**the visible pixel artwork is progressively cleared away by matching-color
Scrubbots, exposing the gameplay background through transparent CLEARED cells.**

Do not use "reveal" to imply a hidden clean artwork layer. It may only be used
where literally describing the background becoming visible through a cleared
transparent hole.

### J. ADR

Preserve ADR-011 renderer architecture.

Append a new ADR (next available number) recording:

- ACTIVE/CLEARED lifecycle;
- ACTIVE = source palette / opaque;
- CLEARED = transparent / background visible;
- no dirty/grime/preset layer;
- ACTIVE non-target cells block access;
- raw color candidate != reachable final target;
- M13 ColorCandidateIndex vs future reachability/TargetSelector/RoutingSystem
  separation.

If an old current paragraph conflicts, mark that consequence superseded by
the new ADR rather than erasing historical reasoning.

### K. tasks.md — comprehensive migration

Update ALL current/future gameplay-semantic task wording that assumes
DIRTY/CLEAN or raw "eligible" == final target.

Do not blindly replace ordinary English uses such as:

- clean checkout;
- clean machine;
- clean schema error;
- clean silhouette.

Those are unrelated.

At minimum update these task areas:

#### M02
- SB-M02-004 -> ACTIVE state implemented.
- SB-M02-005 -> CLEARED state implemented.
- M02-017 reservation remains open.

#### M10
Rename milestone to something like:

`M10 — ACTIVE/CLEARED Board Visual Model [OWNER DECISION LOCKED] [MANUAL QA OPEN]`

Owner decision now resolves:
- ACTIVE appearance = original source palette color;
- CLEARED appearance = transparent;
- no grime/hidden artwork layer.

Remove A/B/C preset language.

SB-M10-001 may close because the owner explicitly chose the ACTIVE appearance.
SB-M10-002/003 remain complete but wording changes.
SB-M10-004 remains complete only if the new renderer mapping is implemented
and tested in this migration.
SB-M10-005..011 remain OPEN pending owner manual QA of the NEW transparent
model after this migration.
SB-M10-012 remains complete only after the debug tool is migrated and proven
to run.

#### M11
Reset/session wording -> all ACTIVE.
Renderer binding evidence -> ACTIVE/CLEARED transparency semantics.

#### M13
Rename milestone:

`Color Candidate Index [PERFORMANCE]`

Preserve SB-M13-001..010 IDs and completed truth only if migration tests pass.
Update language:
- active candidate;
- color query;
- CLEARED removal;
- caller exclusion/reservation seam;
- no-candidate;
- exhausted color;
- last candidate;
- 3,481 benchmark.

Explicitly state M13 does not prove reachability.

#### M14
Reservation semantics remain separate and must not mutate visual state names.
Do not implement M14.

#### M15
Update tasks so:
- match Scrubbot color;
- never target CLEARED;
- never target invalid;
- never target blocked/unreachable;
- respect reservations;
- return no-target cleanly;
- consume a narrow reachability/access truth without generating a route;
- fully enclosed matching-color target regression is required.

Prefer preserving existing task IDs by expanding precise wording rather than
adding IDs unless absolutely necessary. If a new ID is unavoidable, explain
why and recompute totals.

#### M16/M17
Update route contract/prototype tasks:
- ACTIVE non-target cells are blockers;
- CLEARED/background space is open;
- route ends at the assigned ACTIVE target;
- no route -> failure, never silent retarget;
- blocked interior and newly-opened-after-clear cases required;
- exact topology/path style remains implementation/design work.

#### M18/M19/M20
Update agent/dispatcher/vertical slice:
- work validation means reachable targetable work, not raw color candidates;
- no reachable target -> no spawn;
- arrival -> CLEARED -> transparent renderer -> candidate/access truth update;
- bot disappears, no return/carry.

#### M21 / UI
Replace "clean/reveal hidden art" semantic with clearing the visible pixel
artwork and showing background through transparent cells.
Update SB-UI-015 accordingly.

#### M40/M41/M48/M49
- Dirty count -> ACTIVE count.
- Clean count -> CLEARED count.
- Eligibility -> color-candidate + reachability/access where appropriate.
- QA/regression must include blocked matching-color target and transparent
  cleared-cell behavior.

Update any other task section found by semantic scan.

### L. Historical evidence rule

DO NOT rewrite historical coordination artifacts:

- prior CHATGPT_PROMPT/CRITERIA/AUDIT files;
- prior CLAUDE_LOG files;
- legacy phase logs.

They describe what was true at the time.

Do not rewrite old CHANGELOG history. Append a new migration entry explaining
that the old DIRTY/CLEAN prototype was superseded by the owner-approved
ACTIVE/CLEARED model.

Current canonical docs/tasks/code must be new-model truth.

### M. Level Factory

Update canonical Level Factory docs/contracts so future solving/generation
uses the new gameplay law:

- board cells start ACTIVE;
- a legal cleaning move clears one ACTIVE matching-color target;
- CLEARED cells open access;
- ACTIVE non-target cells block access;
- fully enclosed matching-color cells are not currently targetable;
- the solver must consume/shared-adapt canonical gameplay reachability
  semantics rather than invent a different Colony Flow rule.

Do not implement LF00 or generator/solver code in this cycle.

### N. Content Pipeline

Inspect canonical Content Pipeline docs.

LevelData remains declarative source artwork/color data.
Runtime ACTIVE/CLEARED state must not be baked into published level source
unless a later save/runtime contract explicitly requires it.

If Content Pipeline docs do not contain stale gameplay-state assumptions,
record "inspected, no semantic edit required" rather than making churn.

Do not implement CP00.

## Repository-wide semantic scan

Before implementation, generate an inventory of all current non-historical
files containing gameplay-semantic occurrences of:

- DIRTY
- CLEAN
- DirtyCleanPresets
- dirty_clean
- EligibleTargetIndex
- get_eligible
- count_eligible
- "reveal artwork"
- grime
- eligibility language that incorrectly implies reachability.

Classify every hit as:

1. must migrate;
2. historical evidence — preserve;
3. unrelated ordinary English "clean" — preserve;
4. false positive.

Include the classification summary in CLAUDE_LOG_V01.md.

After implementation, repeat the scan.

Final current/canonical production/docs/tasks must have no stale
gameplay-semantic DIRTY/CLEAN/preset/EligibleTargetIndex language.

Historical artifacts are allowed to retain it.

## Required implementation scope

Production changes are expected in at least:

- scripts/gameplay/board/board_state.gd
- scripts/gameplay/board/board_renderer.gd
- remove scripts/gameplay/board/dirty_clean_presets.gd
- move/rename scripts/gameplay/routing/eligible_target_index.gd
  -> scripts/gameplay/targeting/color_candidate_index.gd
- scripts/gameplay/session/gameplay_session.gd
- scripts/debug/board_debug_fixtures.gd
- scripts/debug/board_renderer_debug.gd
- tests/run_tests.gd
- tests/support/board_state_scan_spy.gd if terminology/contracts require it.

Also canonical docs/tasks/coordination/Level Factory files from the scan.

Do not add actual M14 reservation ownership, M15 selector implementation,
M16 routing implementation, M17 route prototypes, Scrubbot agents or
production gameplay UI in this cycle.

## Mandatory validation — log every item individually

1. safe fetch/sync and starting SHA evidence
2. full pre-work git status
3. classify all pre-existing local owner/tool paths
4. prove no owner work restored/reset/overwritten/staged
5. baseline `godot --version`
6. baseline root headless boot
7. baseline full regression suite on exact starting HEAD
8. pre-migration semantic inventory
9. historical-vs-current classification
10. BoardState enum ACTIVE/CLEARED only
11. fresh board all ACTIVE
12. single ACTIVE->CLEARED mutation isolation
13. independent BoardState instances remain independent
14. reset creates fresh all-ACTIVE board
15. ACTIVE count/CLEARED count behavior
16. invalid state mutation behavior unchanged/safe
17. renderer ACTIVE source-color readback
18. renderer ACTIVE alpha opaque
19. renderer CLEARED alpha zero
20. CLEARED readback is not substituted black/gray/palette color
21. update_cells ACTIVE->CLEARED transparency
22. renderer never mutates BoardState
23. renderer follows fresh reset BoardState not stale old one
24. 20x20 renderer geometry
25. rectangular renderer geometry
26. 59x59 renderer geometry
27. one Image/ImageTexture architecture preserved
28. nearest-neighbor filtering preserved
29. DirtyCleanPresets production file removed
30. no preset API/dependency remains in production
31. debug tool has no A/B/C dropdown
32. debug tool All ACTIVE
33. debug tool All CLEARED
34. debug tool Half ACTIVE/CLEARED
35. debug tool Checker ACTIVE/CLEARED
36. debug background visibly exists behind transparent board
37. debug scene headless-load/boot proof
38. ColorCandidateIndex file/path/class/API rename
39. old EligibleTargetIndex production file absent
40. candidate contract = valid+ACTIVE+color+excluded seam
41. CLEARED removal from candidate index
42. ACTIVE restoration test/tooling path no duplicates
43. per-cell sync isolation
44. rebuild truth
45. rebind stale-state proof
46. no-candidate query
47. exhausted-color candidate test
48. last-candidate test
49. reservation exclusion seam remains caller-owned only
50. no RESERVED state
51. M13 zero steady-state BoardState traversal proof preserved
52. M13 traversal-spy sensitivity proof preserved
53. 59x59 candidate correctness
54. 59x59 candidate benchmark CPU/index only
55. no TargetSelector implementation
56. no routing/pathfinding implementation
57. no reservation ownership implementation
58. no dispatch/agent implementation
59. canonical README migrated
60. CLAUDE.md locked rules migrated
61. project brief migrated
62. gameplay spec migrated
63. tech architecture migrated
64. level data spec migrated
65. roadmap migrated
66. ADR appended / old conflicting current consequence superseded
67. test strategy migrated
68. tasks M02 migrated
69. tasks M10 migrated with owner decision and new manual-QA gates
70. tasks M11 migrated
71. tasks M13 renamed/reworded without losing audited behavior
72. tasks M15 reachability/blocked rule
73. tasks M16/M17 blocker/open-space routing semantics
74. tasks M18/M19/M20 clearing sequence
75. tasks M21/UI clearing/background semantics
76. tasks M40/M41/M48/M49 terminology/QA semantics
77. Level Factory canonical docs migrated
78. Content Pipeline inspected and edits justified or explicitly unnecessary
79. CHANGELOG append-only migration entry
80. AUDIT_INDEX AL-007 supersession + new owner-rule learnings
81. post-migration semantic scan
82. prove no stale current gameplay-semantic DIRTY/CLEAN/preset identifiers
83. prove no stale current EligibleTargetIndex/get_eligible identifiers
84. prove ordinary unrelated "clean checkout/machine/schema/silhouette" was not
    corrupted by blind replacement
85. full post-migration regression suite
86. `git diff --check`
87. source/temp/binary/scope inspection
88. recompute unique canonical task IDs
89. recompute completion from tasks.md, never hardcode
90. if no task IDs are added and only owner-approved SB-M10-001 newly closes,
    expected ecosystem completion is 207/943; verify rather than assume
91. keep M10-005..011 open pending NEW-model owner manual QA
92. keep M02-017 and all M14 tasks open
93. keep M15/M16/M17 implementation tasks open
94. update SESSION_INDEX
95. update H!ve ACTIVE_CYCLES
96. update H!ve ARTIFACT_MAP
97. update H!ve PROGRESS_SNAPSHOT
98. update PROJECT_DASHBOARD
99. full git status before staging
100. verify unrelated owner/local paths not staged
101. focused META-C004 implementation commit
102. safe non-force push to origin/main
103. verify exact commit + CLAUDE_LOG_V01.md visible on GitHub
104. final git status
105. set META-C004 AWAITING_AUDIT and stop

## Manual QA gate after Claude

Do NOT claim M10-005..011 from automated tests.

After ChatGPT independently audits this migration, the owner will manually run
the migrated BoardRenderer debug scene and visually verify transparent
CLEARED holes/background behavior at:

- Easy;
- Medium;
- Hard;
- Very Hard;
- 59x59;
- rectangular board;
- narrow/tall window.

That owner observation is a later E4/manual-QA gate.

## Stop

When all implementation/validation is complete:

- update canonical truth;
- create one focused META-C004 commit;
- push safely;
- verify GitHub visibility;
- set META-C004 = AWAITING_AUDIT;
- stop.

Do not start M14.
Do not start M15/M16/M17.
Do not start LF00/CP00.
Do not generate Magnific assets.
Do not create/modify any CHATGPT_AUDIT file.
