---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit
cycleId: M13-C001
version: 1
createdAt: 2026-09-05T20:12:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M13
auditedImplementationHead: 8d81484514215521425ba68e30f1a96ca094c2b2
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

# SCRUBBOTS - M13-C001 ChatGPT Independent Audit V01

## Decision

`CHANGES_REQUIRED`

The production EligibleTargetIndex design is largely sound. Four tasks are
accepted now, one task needs a stronger performance-regression proof, and five
tasks were implemented early because the issued V01 prompt accidentally
over-scoped the owner's intended first M13 batch.

Claude followed the written V01 prompt correctly. The scope mismatch is a
ChatGPT prompt-authoring error, not a Claude implementation violation.

ChatGPT independently inspected the actual implementation commit
`8d81484514215521425ba68e30f1a96ca094c2b2`, production source,
BoardState, the test spy, M13 tests, benchmark, tasks.md and coordination/H!ve
state.

ChatGPT did not execute the owner's local Godot binary. Claude's
`729/729 ALL PASS` result remains E1/E2 implementation evidence.

## Accepted task baseline

The following V01 work is independently accepted and stays complete:

- **SB-M13-001 Define eligible cell**
- **SB-M13-002 Group/query by color**
- **SB-M13-004 Synchronize with BoardState**
- **SB-M13-005 Remove CLEAN cells**

Accepted implementation properties:

- eligibility is valid + DIRTY + requested color + not caller-excluded;
- buckets are color-grouped and deterministic;
- CLEAN + explicit sync removes a cell;
- DIRTY + explicit sync restores it once;
- rebuild/rebind follows BoardState truth and drops stale old-board state;
- query results are detached from mutable internal bucket storage;
- BoardState still owns coordinate/index formulas;
- no TargetSelector, routing, dispatch, Scrubbot agent or reservation ownership
  was introduced.

## Finding F-M13-001 — MEDIUM — no-full-scan regression spy is incomplete

M13-23 claims to directly prove that steady-state queries do not scan
BoardState.

However, `board_state_scan_spy.gd` increments `scan_count` only inside
`get_cell_state()`.

A future regression could scan all 3,481 cells through another BoardState API,
for example:

- `get_color_id()`;
- `get_cell_count()`;
- repeated `is_valid_index()`;

and the current M13-23 assertion could remain green if it never calls
`get_cell_state()`.

The current production implementation does not perform such a scan; direct
source inspection shows `get_eligible()` and `has_work()` read only cached
buckets. The problem is regression-test observability under AL-018.

### Required correction

Strengthen the test spy / direct observability so steady-state query tests
observe **all BoardState API access relevant to a possible full-board scan**,
not only state reads.

At minimum, after build:

- repeated `get_eligible()`;
- repeated `has_work()`;
- `count_eligible()`;

must add zero BoardState API reads/calls used for cell traversal.

The corrected regression must fail if a future query implementation loops over
the board via `get_color_id()` or another counted BoardState traversal API.

Until this proof exists, **SB-M13-003 is reopened**.

## Finding F-M13-002 — PROCESS/SCOPE — SB-M13-006..010 were implemented before their intended batch

The owner intended M13-C001's first batch to cover:

- SB-M13-001..005.

The V01 ChatGPT prompt accidentally instructed Claude to implement
SB-M13-001..010. Claude complied with that written instruction.

The existing 006..010 implementation/tests are useful provisional work and
must be preserved. They are not to be deleted or rewritten merely because
they arrived early.

However, per owner instruction, they must now be treated as the explicit
remaining M13 batch and receive one deliberate V02 implementation/validation
pass before canonical task truth closes them.

Therefore reopen for V02:

- SB-M13-006 Handle reservations
- SB-M13-007 No-work query
- SB-M13-008 Exhausted-color test
- SB-M13-009 Last-target test
- SB-M13-010 3,481-cell benchmark

V02 should reuse accepted provisional code when correct and add/fix only what
the explicit V02 criteria require.

## Finding F-M13-003 — MEDIUM — tracked owner/local changes must not be erased to make the tree clean

CLAUDE_LOG_V01 says session start contained a tracked working-tree deletion of:

`assets/art/references/_owner_inbox/Game Screens/scrubbots main screen 001.jpeg`

and that Claude used `git restore` to restore it before work.

The GitHub repository did not lose the asset, but this workflow can overwrite
an intentional local owner edit/deletion. "Preserve owner work" means a
pre-existing tracked modification/deletion is not automatically disposable
because origin contains a different version.

### Required correction to workflow

For V02 and future work:

- never use `git restore`, checkout-from-origin, reset, or equivalent to
  erase a pre-existing tracked owner/local modification merely to obtain a
  clean tree;
- record pre-existing tracked changes separately from task edits;
- do not stage them;
- if they block safe synchronization or implementation, fail closed as
  `BLOCKED` rather than overwriting them.

## Provisional V01 work to preserve

The following early implementation is structurally compatible with the M13/M14
boundary and should be reused if it passes V02:

- caller-supplied exclusion/reservation filter only;
- no stored reservation ownership;
- no RESERVED BoardState state;
- has-work/no-work query;
- exhausted-color tests;
- last-target tests;
- 59x59 / 3,481-cell correctness and CPU/index benchmark;
- no hardware-specific timing threshold;
- no FPS/GPU claim.

## Canonical task truth after this audit

Accepted complete:

- SB-M13-001
- SB-M13-002
- SB-M13-004
- SB-M13-005

Open for V02:

- SB-M13-003
- SB-M13-006
- SB-M13-007
- SB-M13-008
- SB-M13-009
- SB-M13-010

Canonical progress after reopening six tasks:

- ecosystem: **200 / 943 = 21.21%**
- main game + SB-UI: **200 / 719 = 27.82%**
- Level Factory: **0 / 112**
- Content Pipeline: **0 / 112**

## Next action

Run one M13-C001 V02 pass that:

1. fixes F-M13-001 and F-M13-003;
2. formally completes/validates SB-M13-003 and SB-M13-006..010;
3. re-runs regression coverage for accepted 001/002/004/005;
4. closes all M13 tasks only if the direct evidence passes.

Do not start M14/M15/M16.
