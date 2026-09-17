# M23-C001 V01 — Strict Audit Criteria

Cycle: `M23-C001 V01`
Milestone: `M23 — Batch Supply Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementation/test runner)
Auditor: ChatGPT
Tracker authority: root `TASKS.md` (Claude read-only)
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

## 0. Audit verdict policy

This cycle is `AUDITED_PASS` only if the GitHub implementation, tests and evidence prove the M23 Batch Supply Engine contract itself. A passing implementer-written test suite is necessary but not sufficient.

Any violation of the protected subsystem boundaries, queue transaction semantics, conservation law, hidden-preview rule or deterministic-generation requirements is `CHANGES_REQUIRED`.

M24–M27 behavior must not be smuggled into M23.

## 1. Governance / repository integrity

The implementation must prove all of the following:

1. Work occurred only in `Sekiph82/Scrubbots` on `main`.
2. Claude read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, the active prompt, these criteria and `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`.
3. Safe synchronization only. No `reset --hard`, destructive restore, `clean -fd`, force push or deletion of owner-local work.
4. Root `TASKS.md` is absent from the implementation diff.
5. No M24, M25, M26 or M27 production implementation is introduced.
6. No image generation or Magnific/PixelLab credits are used.
7. Implementation commit is pushed before the evidence log commit.
8. `CLAUDE_LOG_V01.md` is a separate coordination/evidence commit and does not contain an implementer-authored audit verdict.

## 2. Architectural boundary

M23 is a gameplay-domain supply engine, not UI and not a partial replacement for existing core systems.

Required:

- no dependency on `Control`, presentation scenes, SlotCell UI, BoardRenderer UI or screen layout;
- no target selection;
- no ReservationState mutation;
- no routing calls;
- no Dispatcher/ScrubbotAgent spawn;
- no BoardState clearing;
- no Five-Slot Batch lifecycle implementation;
- no solver/deadlock proof.

Protected systems must remain behaviorally unchanged unless a minimal read-only seam is strictly necessary and explicitly justified:

- `scripts/gameplay/slots/slot_system.gd`
- `scripts/gameplay/slots/slot_state.gd`
- ColorCandidateIndex
- ReservationState
- TargetSelector
- ProductionTargetAccess
- ProductionRoutingSystem / Railroad V1
- Dispatcher
- ScrubbotAgent
- CompleteClearingLoop

A broad rewrite of any protected system fails this criterion.

## 3. ColorBatch value contract

The implementation must provide a gameplay-domain batch value or equivalent immutable-by-contract representation satisfying:

- stable unique `batch_id`;
- integer runtime `color_id` compatible with existing LevelData/BoardState/TargetSelector color IDs;
- strictly positive integer `robot_count` / quota;
- no presentation color name/hex guess as gameplay identity;
- no invalid negative color ID;
- no zero/negative/float/String/bool/null/object quota accepted through public construction/factory seams;
- external callers cannot mutate a live batch behind the engine's back through returned internal references.

Human-readable canonical Cxx/debug metadata may exist, but it must not become a second gameplay color authority.

## 4. Supply column configuration

Production configuration must support exactly 3, 4 or 5 independent FIFO columns.

Required failures:

- fewer than 3 columns rejected;
- more than 5 rejected;
- unsupported types rejected fail-closed;
- malformed initial queue content rejected without partially mutating prior valid engine state.

Preview depth:

- engine may support 3 or 4 visible rows;
- V1/Hazard Bot fixture must exercise 3 rows;
- invalid preview depth is rejected.

## 5. Front-only selection and preview secrecy

For every column:

- only front/index-0 batch is selectable;
- Row 2/Row 3 are preview-only in the V1 fixture;
- no public activation API can consume Row 2/Row 3 directly;
- deeper hidden batches cannot be selected by index through a gameplay API;
- read-only preview query returns no more than configured preview depth;
- hidden queue contents are not leaked through ordinary player-facing preview/front queries;
- read-only snapshots returned to callers must not expose mutable internal arrays/objects.

A debug/full snapshot may exist for tests/save/replay only if it is explicitly non-player-facing and detached from internal mutable storage.

## 6. Independent FIFO semantics

Committed consumption of one column must:

- remove exactly its current front batch;
- advance only that column;
- old Row 2 becomes new front;
- old Row 3 becomes Row 2;
- next hidden batch, if present, becomes Row 3;
- preserve exact order of every remaining item;
- leave every other column logically unchanged.

End-of-column behavior must be deterministic when 0, 1 or 2 preview entries remain.

End-of-supply behavior must be deterministic when every column is exhausted.

## 7. Transactional selection / future M24 handoff

A click/request must not irreversibly pop a batch before downstream acceptance.

The implementation must provide a two-phase or equivalent atomic transaction with these properties:

1. begin/request exposes exactly the current front batch plus a stable transaction identity/snapshot;
2. queue remains unchanged until commit/accept;
3. commit removes exactly the originally selected front from exactly the originating column;
4. cancel/reject leaves all columns unchanged;
5. double commit fails closed;
6. double cancel is harmless/fails closed;
7. stale transaction after reset fails closed;
8. transaction for column A cannot commit column B;
9. if the front changed before commit by another valid transaction, stale commit cannot remove the wrong batch;
10. malformed/forged transaction data cannot mutate supply state.

The audit will reject an implementation that relies on the future M24 Slot Engine to repair an already-destructive M23 pop.

## 8. Quota conservation

Given a valid LevelData source, the candidate generator must derive per-color logical-cell totals from `LevelData.cells` using existing runtime palette IDs.

For every color present:

`sum(robot_count of all generated batches with color_id C) == count(LevelData.cells == C)`

Required:

- no missing quota;
- no invented quota;
- no generated zero-size batch;
- no generated color absent from the LevelData palette/cells;
- no invalid palette ID;
- total quota across all batches equals LevelData cell count for the generated level state used by M23;
- conservation is tested independently per color, not only as one grand total.

M23 must not silently reinterpret blue/background-looking artwork pixels as empty. Hazard Bot LevelData is opaque source artwork; all listed logical cells count unless a separate owner decision changes level semantics.

## 9. Deterministic candidate generation

For identical validated LevelData + engine config + seed:

- same number of batches;
- same batch IDs or a documented deterministic equivalent;
- same color IDs;
- same counts;
- same per-column ordering;
- same hidden/preview ordering.

For a different seed, output may differ but must remain legal and conservation-correct.

Generation must be bounded and must not depend on wall-clock time, global random state or UI frame timing once a seed is supplied.

The seed must be reportable/persistable in engine snapshot/evidence.

## 10. Batch partition generation

The generator must partition every positive per-color total into positive integer batch sizes.

Audit requirements:

- no batch count <= 0;
- no overflow/coercion artifacts;
- no quota remainder discarded;
- no duplicate live `batch_id`;
- result can be distributed across each supported 3/4/5-column configuration;
- deterministic column distribution for a given seed;
- empty impossible/malformed source input fails closed rather than inventing a batch.

M23 does not need to optimize difficulty or prove solvability. It produces candidate layouts only.

## 11. Hazard Bot real-level evidence

The real file `data/levels/m21_level_001_hazard_bot.json` must be loaded through the real loader or an equivalent production read path.

Evidence must print/record:

- level ID and dimensions;
- palette size;
- exact per-color runtime palette-ID cell totals;
- generation seed;
- configured column count and preview depth;
- full generated batch list grouped by column for audit/debug evidence;
- per-color generated quota totals;
- explicit equality of source totals vs generated totals;
- front/preview state for each column;
- proof deeper-than-preview entries are hidden from the player-facing preview query when such entries exist.

Do not hard-code expected totals in production code. Test expectations may assert the real fixture's known counts after deriving them once from the checked-in fixture.

## 12. Rectangular and 59×59 evidence

At least one rectangular LevelData fixture and one 59×59 fixture must prove:

- generation completes;
- per-color conservation remains exact;
- 3/4/5-column configurations remain legal as exercised by the tests;
- no square-board assumption;
- no hard-coded 400-cell/Hazard-Bot assumption;
- runtime/memory behavior is sane for 3,481 cells.

A lightweight performance sanity timing/allocation note is sufficient; no arbitrary strict millisecond threshold is required.

## 13. Reset and snapshot behavior

Reset must restore the exact initial supply state for the active generated/configured candidate:

- original queue content/order;
- original fronts/previews;
- no stale transaction remains committable;
- same generation seed/reporting state;
- no cross-reset batch alias allowing external mutation.

Snapshot/query APIs must return detached/read-only-by-contract data. Mutating a returned Array/Dictionary/batch copy in a test must not mutate engine truth.

## 14. Invalid/adversarial input coverage

Tests must cover at least:

- bad column counts;
- bad preview depth;
- malformed batch IDs or duplicates;
- invalid color IDs;
- zero/negative/non-integer quota;
- null/malformed queue entries;
- stale/forged transaction;
- double commit;
- cancel then commit;
- reset with outstanding transaction;
- empty/exhausted column;
- fully exhausted supply;
- attempts to activate non-front preview/hidden entries through any public gameplay seam;
- returned snapshot mutation attempt;
- deterministic re-generation same seed;
- conservation across multiple colors.

## 15. Existing subsystem regression

The implementation must run the complete root suite and preserve accepted gameplay behavior.

Minimum required validation commands/evidence:

- `godot --version`
- `godot --headless --path . -s res://tests/run_tests.gd`
- the dedicated M23 V01 evidence/smoke script if one is added;
- M22 V06 real demo state evidence;
- M22 V05 final state evidence;
- M22 V04 final evidence;
- M22 V03 connector evidence;
- M21 real-art smoke;
- M21 V10 final reservation evidence;
- representative M20 lifecycle/queue-free regression evidence;
- `git diff --check`.

If filenames changed, Claude must use the current repository equivalents and state that explicitly.

No previously green test may be deleted merely because M23 introduces a new production interaction model. Historical M21/M22 direct-slot tests remain valid historical/regression evidence unless a test is explicitly production-UI-only and the prompt authorizes its migration. This V01 prompt does not authorize broad historical test deletion.

## 16. No stale operating-manual ambiguity in implementation decisions

`CLAUDE.md` contains older direct-slot/"do not invent queue mechanics" wording from before the 2026-09-17 owner decision.

For M23–M27, the newer owner decision and root `TASKS.md` batch rules supersede only those conflicting historical statements.

Claude must not use stale wording as a reason to omit M23.

Conversely, this does not authorize unrelated edits to `CLAUDE.md` during M23 unless a tiny documentation correction is required by the prompt and listed separately. Core implementation should not expand into a documentation rewrite.

## 17. Changed-file discipline

Expected new production area is preferably a narrow gameplay-domain module such as `scripts/gameplay/supply/` plus tests/fixtures/evidence.

Alternative placement is acceptable if consistent with current architecture, but the diff must remain narrow and explain why.

Red flags requiring audit scrutiny:

- modified routing/targeting/dispatcher/agent code;
- modified root `TASKS.md`;
- scene/UI changes;
- asset changes;
- difficulty/progression changes;
- Level Factory sidecar changes;
- M24–M27 implementation files.

## 18. Required implementation log

`coordination/sessions/M23-C001/CLAUDE_LOG_V01.md` must include:

- starting `origin/main` SHA after safe sync;
- implementation commit SHA;
- separate log commit statement;
- complete changed-file list;
- architecture summary;
- exact public API summary;
- transaction semantics;
- deterministic generation algorithm summary;
- same-seed evidence;
- Hazard Bot per-color source totals and generated totals;
- rectangular/59×59 evidence;
- exact test commands, check counts, failures and exit codes;
- explicit statement `root TASKS.md modified = NO`;
- explicit statement `M24–M27 implementation = NO`;
- explicit statement `image-generation credits spent = 0`;
- any warning, limitation or unresolved issue;
- final handoff state `AWAITING_AUDIT`.

## 19. Audit closure mapping

If all criteria pass, ChatGPT may close `SB-M23-001..SB-M23-030` in root `TASKS.md` and move the tracker to M24.

If any material criterion fails, ChatGPT records `CHANGES_REQUIRED` and opens a targeted V02 correction cycle. M24 does not start early.
