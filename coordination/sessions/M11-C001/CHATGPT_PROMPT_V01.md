---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M11-C001
version: 1
createdAt: 2026-09-04T10:37:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
taskRefs:
  - SB-M11-001
  - SB-M11-002
  - SB-M11-003
  - SB-M11-004
  - SB-M11-005
  - SB-M11-006
  - SB-M11-007
  - SB-M11-008
  - SB-M11-009
  - SB-M11-010
  - SB-M11-011
  - SB-M11-012
baselineCommit: b13e58d33bc36f7e54547562c866051451e5fd31
---

# SCRUBBOTS - M11-C001 Gameplay Session Core

## Objective

Implement the headless-testable gameplay session lifecycle that composes the already-audited level-loading, BoardState, and BoardRenderer systems without inventing unresolved game design.

This cycle targets only `SB-M11-001..012`.

M09 is now independently audited complete. M08 still requires owner artwork. M10 final DIRTY/CLEAN approval remains owner-controlled. Neither gate prevents this technical session-core milestone from proceeding.

## Mandatory GitHub sources

Read these before changing code:

1. Agent governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical task truth:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Coordination protocol:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. Session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. Audit policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
7. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. M09-C002 final independent audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md
9. This cycle's audit criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V01.md
10. This active prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V01.md
11. Gameplay specification:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
12. Technical architecture:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
13. Level Data specification:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
14. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
15. Level loader:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/data/level_loader.gd
16. BoardState:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/board/board_state.gd
17. BoardRenderer:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/board/board_renderer.gd
18. Existing TEST/production-band fixtures:
    https://github.com/Sekiph82/Scrubbots/tree/main/data/levels

## Relevant audit learnings

At minimum apply and explicitly log relevant use of:

- `AL-001`: explicit preload convention for headless reliability;
- `AL-004`: variable/rectangular/max-size coverage;
- `AL-005`: task completion requires behavioral evidence;
- `AL-007`: do not resolve the M10 visual owner gate;
- `AL-009`: log every mandatory validation step individually.

M09 filesystem-importer learnings remain authoritative for M09 tooling but should not be copied into unrelated session logic unless genuinely relevant.

## Locked design boundaries

Do not invent or implement:

- final win-condition logic;
- lose conditions;
- timer;
- move limit;
- lives;
- blockers;
- boosters;
- hints;
- slot mechanics;
- target selection;
- routing;
- Scrubbot agents;
- economy/progression;
- final DIRTY/CLEAN preset;
- owner artwork.

The gameplay specification explicitly says win/lose details are still to be designed.

Therefore M11's completion transition must be an **explicit externally requested lifecycle transition**, not an automatic rule such as "all cells clean means win."

Do not add a LOSE state unless an existing authoritative project source already requires one. It currently does not.

## Architecture requirements

Implement a minimal session architecture with these responsibilities separated cleanly.

### Gameplay session truth

Create a headless-testable gameplay-session core under an appropriate path such as:

`scripts/gameplay/session/`

The exact class split is yours to choose, but the core must:

- own the lifecycle state;
- hold the successfully loaded immutable LevelData reference;
- own the current BoardState instance;
- expose read/query APIs for current session state;
- reject invalid lifecycle transitions without silently mutating state;
- not depend on UI Controls, labels, menus, slots, routing, or scene-specific hierarchy;
- be testable without the running main gameplay scene.

Prefer `RefCounted` for the pure core unless a Node is genuinely required.

Follow the explicit preload convention rather than relying on editor-built global `class_name` cache behavior.

### Presentation binding

M11 must connect the session's board to the already-implemented BoardRenderer, but presentation must not become gameplay truth.

Use either:

- a thin session controller/presenter around the pure core; or
- another minimal binding seam that keeps BoardRenderer optional for headless core tests.

Requirements:

- renderer receives the current BoardState and LevelData palette through its existing `configure()` contract;
- renderer does not own lifecycle state;
- renderer does not decide completion;
- renderer does not load levels;
- session does not read rendered pixels to determine gameplay truth;
- no per-cell Nodes are introduced.

Do not redesign BoardRenderer unless a narrowly necessary integration fix is proven.

## Lifecycle contract

Implement and document an explicit transition table.

At minimum support these technical states:

- `UNINITIALIZED`
- `READY`
- `ACTIVE`
- `PAUSED`
- `COMPLETED`

Equivalent names are acceptable if semantics remain clear and deterministic.

### UNINITIALIZED

Initial state.

No valid LevelData or BoardState is active.

### Load / initialize

Loading a valid Level Data V1 file must:

1. use existing `LevelLoader`;
2. reject invalid/missing/malformed data with actionable error/result information;
3. create a fresh BoardState using `BoardState.from_level_data()`;
4. preserve LevelData as immutable source truth;
5. enter `READY`;
6. optionally configure a bound renderer only after successful initialization.

A failed load must not leave a half-initialized level/board behind.

If loading a new valid level while another session exists is supported, define the behavior explicitly and test it. A safe default is to replace the prior session only after the new level is fully validated and its fresh BoardState is ready.

### READY

A level is loaded and BoardState exists, but gameplay has not been activated.

### ACTIVE

Provide an explicit start/activate transition from READY.

Do not auto-dispatch anything.

### PAUSED

Provide explicit pause and resume lifecycle operations.

Pause must change session lifecycle truth only. Do not invent timer or agent semantics that belong to future systems.

Recommended transition:

- ACTIVE -> PAUSED
- PAUSED -> ACTIVE

Reject nonsensical pause/resume calls from other states without changing state.

### RESET

Reset must recreate runtime board state from the immutable loaded LevelData rather than trying to manually reverse every prior cell mutation.

A deterministic technical contract for this cycle is:

- reset from any initialized non-UNINITIALIZED state returns the session to `READY`;
- a fresh BoardState is created;
- all cells return to DIRTY;
- palette IDs/dimensions remain those of the LevelData;
- any bound renderer is refreshed/reconfigured to the fresh BoardState.

If you choose a different reset contract, it must be simpler, explicit, design-neutral, documented, and justified.

### COMPLETED

Provide an explicit method such as `mark_completed()` / `complete_session()`.

This is only a lifecycle transition.

Do **not** infer completion from:

- dirty-cell count;
- full-board clear;
- timer;
- moves;
- score;
- slots;
- future goal rules.

The eventual win-condition system may call this method later.

Completion should be stable/idempotent or cleanly reject repeated completion without corrupting state.

## Error/result behavior

Do not use silent booleans where callers need actionable failure reasons.

Lifecycle methods may return a small result object, enum/error code + message, or another simple deterministic form.

At minimum, tests/callers must be able to distinguish:

- successful operation;
- invalid transition;
- level load/validation failure.

Do not throw/crash on normal invalid lifecycle usage.

## Renderer integration

Test at least one real BoardRenderer integration path where practical in headless Godot.

Verify:

- successful load + renderer bind/configure produces correct board dimensions;
- reset points renderer at the fresh BoardState rather than stale runtime state;
- rectangular dimensions remain rectangular;
- 59x59 remains one BoardRenderer/TextureRect, not thousands of Nodes.

Do not decide or change the final DIRTY preset. Whatever BoardRenderer's current default/prototype behavior is remains provisional under M10.

## Required automated test matrix

Extend the existing headless suite.

At minimum cover:

### Initialization and loading

1. New session starts UNINITIALIZED.
2. Valid TEST 3x2 level loads to READY.
3. Valid rectangular production-band fixture loads to READY.
4. 59x59 fixture loads to READY.
5. Missing level path fails cleanly and remains UNINITIALIZED when no prior valid session exists.
6. Malformed/invalid Level Data fails cleanly.
7. Failed replacement load does not destroy an already-valid current session.

### BoardState creation and isolation

8. Successful load creates a BoardState with matching width/height/cell count.
9. LevelData remains unchanged after BoardState mutation.
10. Reset creates a fresh BoardState object.
11. Reset restores all cells DIRTY.
12. Reset preserves dimensions/color IDs.
13. Two independent sessions loaded from the same level do not share mutable BoardState.

### Lifecycle

14. READY -> ACTIVE succeeds.
15. ACTIVE -> PAUSED succeeds.
16. PAUSED -> ACTIVE resume succeeds.
17. Invalid start/pause/resume transitions fail without state mutation.
18. Reset from READY/ACTIVE/PAUSED/COMPLETED follows the documented contract.
19. Explicit completion transition succeeds from the documented allowed state(s).
20. Repeated completion is deterministic and non-corrupting.
21. Completion does not automatically occur merely because cells are manually marked CLEAN.

### Renderer seam

22. Bind/configure renderer only after valid session initialization.
23. Renderer sees the same BoardState session currently owns.
24. Reset updates renderer to the new BoardState.
25. Rectangular board geometry remains correct.
26. 59x59 renderer remains a single renderer node/object model.

### Scope and regression

27. No slot/target/routing/agent system is created.
28. No win/lose/timer/move-limit rule is introduced.
29. All previous 447 checks remain green.

## State-transition specificity

Tests must assert both:

- operation result;
- resulting lifecycle state.

For invalid transitions, assert the previous lifecycle state is unchanged.

For failed load, assert level/board ownership is unchanged according to the documented replacement contract.

## Performance sanity

This milestone is not a heavy performance feature, but initialize/reset at least the 59x59 fixture and record a simple CPU-only sanity measurement if useful.

Do not create a hard timing gate.

Do not call headless CPU timing an FPS/GPU result.

## Documentation

Update durable docs to reflect actual implementation:

- `docs/02_TECH_ARCHITECTURE.md`;
- `docs/06_TEST_STRATEGY.md`;
- `CHANGELOG.md`;
- `docs/01_GAMEPLAY_SPEC.md` only if a clarification is needed and does not invent design;
- `docs/05_TECH_DECISIONS.md` only if a genuinely durable architecture decision deserves an ADR.

Document the lifecycle transition table and explicit non-goals.

## tasks.md truth

Only mark `SB-M11-001..012` complete after corresponding implementation and validation evidence exists.

Do not modify owner-dependent M07/M08/M10 completion truth.

Do not mark M12 or later work complete.

## Logging

Maintain the local phase log:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M11_LOG.md`

It stays local-only and must not be committed.

Create/update the GitHub implementation log:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md

Claude implements/tests/logs only. Claude must not create audit or self-audit files.

Before ending, update:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md

https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

Set M11-C001 to `AWAITING_AUDIT` only when implementation, tests, docs, task truth and implementation logging are ready for independent ChatGPT review.

## Mandatory final validation

Record every item separately in `CLAUDE_IMPLEMENTATION_LOG.md` with expected outcome, explicit fail condition, actual result, and `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL` / `NOT_RUN` / `BLOCKED`.

1. `godot --version`
2. `powershell -File tools\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. Real session load of valid TEST 3x2 -> READY.
6. Real session load of rectangular legal production fixture -> READY.
7. Real session load/reset of 59x59.
8. Missing-path load failure with state-preservation proof.
9. Malformed/invalid-level load failure with state-preservation proof.
10. READY -> ACTIVE -> PAUSED -> ACTIVE lifecycle proof.
11. Invalid-transition state-preservation proof.
12. Reset proof: fresh BoardState + all DIRTY + same dimensions/colors.
13. Explicit completion proof.
14. Prove manually-cleaned board does not auto-complete.
15. Renderer bind/configure proof.
16. Renderer reset/fresh-board proof.
17. Confirm no M12 slot, target, routing, agent, timer, move-limit, lose-condition, economy or owner-art implementation was introduced.
18. Confirm M10 final visual preset was not selected/changed.
19. `git diff --check`
20. Inspect final diff for scope integrity and accidental binaries/cache/temp files.
21. `git status --short` before commit.
22. Commit with a precise M11-C001 message.
23. Push to `origin/main` without force.
24. Final `git status --short` with commit/push evidence.

Do not replace named checks with only an aggregate test total.

## Stop condition

After M11-C001 is implemented, validated, logged, pushed, and set to `AWAITING_AUDIT`, stop.

Do not start M12 or any later milestone.
