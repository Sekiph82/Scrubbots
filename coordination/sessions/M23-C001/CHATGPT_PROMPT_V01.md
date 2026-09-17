# M23-C001 V01 — Batch Supply Engine

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Milestone: `M23 — Batch Supply Engine`
Handoff target: `AWAITING_AUDIT`

Implement M23 completely and only M23. This cycle builds the deterministic FIFO batch-supply data engine that future M24–M27 systems will consume.

Do not implement the five-slot batch lifecycle, batch target claims, auto dispatch or solver/deadlock logic in this cycle.

## 1. Mandatory reading order

Read before modifying anything:

1. `CLAUDE.md`
2. root `TASKS.md` — READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/AUDIT_INDEX.md`
5. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
6. `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
7. this prompt
8. relevant current gameplay/data code, especially:
   - `scripts/data/level_data.gd`
   - `scripts/data/level_loader.gd`
   - `scripts/gameplay/slots/slot_system.gd`
   - `scripts/gameplay/slots/slot_state.gd`
   - ColorCandidateIndex
   - ReservationState
   - TargetSelector
   - M22 production routing/access implementation
9. `data/levels/m21_level_001_hazard_bot.json`
10. `data/palettes/scrubbots_palette_v2.json`

Important precedence note:

The 2026-09-17 owner decision and current root `TASKS.md` batch sections supersede older direct-slot / "do not invent queue mechanics" wording in historical docs where they conflict. Do not treat the stale wording as a blocker to M23.

Do not perform a broad `CLAUDE.md` rewrite in this cycle.

## 2. Safe Git synchronization first

Work from the canonical local repo:

`C:\Users\sekip\Desktop\ScrubBots`

Before material work:

- confirm remote is `Sekiph82/Scrubbots`;
- confirm branch `main`;
- inspect `git status --short`, branch/upstream and remotes;
- fetch `origin`;
- safely fast-forward/synchronize to current `origin/main` if possible;
- preserve every pre-existing tracked/untracked owner file;
- never use `git reset --hard`;
- never use `git clean -fd`;
- never force-push;
- never discard local owner work just to make the tree clean.

If owner-local work blocks a safe sync, stop as `BLOCKED` and report it. Do not overwrite it.

Record the exact synchronized starting SHA in the final log.

## 3. Root TASKS.md is forbidden to Claude

You may read root `TASKS.md` but you must not edit it.

At the end:

- `git diff` / changed-file evidence must show root `TASKS.md` absent;
- ChatGPT will update task status after independent audit.

## 4. Scope: implement all M23 tasks

This V01 is intended to cover `SB-M23-001..SB-M23-030` if and only if the code and evidence satisfy the strict audit criteria.

The engine must provide:

- immutable-by-contract batch values;
- stable unique batch IDs;
- runtime color IDs compatible with current LevelData/BoardState gameplay IDs;
- positive integer quotas;
- 3/4/5 independent FIFO columns;
- configurable visible preview depth 3 or 4;
- V1 real-level path with preview depth 3;
- front-only selection;
- hidden future batches;
- transactional front consumption;
- deterministic seedable candidate generation;
- exact per-color quota conservation;
- reset;
- detached snapshots/queries;
- Hazard Bot evidence;
- rectangular and 59×59 tests.

## 5. Recommended module boundary

Prefer a narrow new gameplay-domain package, for example:

```text
scripts/gameplay/supply/
    color_batch.gd
    batch_supply_engine.gd
    batch_supply_generator.gd
    batch_supply_snapshot.gd          # only if useful
    batch_selection_transaction.gd    # only if useful
```

Names may differ. Do not create files merely to match this example.

The important boundary is behavioral:

- `RefCounted`/data-domain implementation is preferred;
- no dependency on Control/UI scenes;
- no direct SlotCell UI logic;
- no BoardRenderer dependency;
- no target/reservation/routing/dispatch/spawn/clear logic.

Follow the repository's explicit `preload()` convention rather than relying casually on global `class_name` resolution.

## 6. Runtime color identity

Do not create a new color authority.

Use the same integer LevelData/BoardState palette ID that existing gameplay systems use as `color_id`.

The current production LevelData local palette is canonical-palette validated and ordered. If you expose Cxx/debug metadata, derive it from canonical palette data, but do not use a guessed name, UI tile color or arbitrary hex lookup as gameplay matching truth.

A batch from one level/session need not pretend its local `color_id` is globally identical across unrelated LevelData instances.

## 7. ColorBatch contract

Implement a batch value/factory that fails closed on invalid construction.

At minimum the logical value contains:

```text
batch_id
color_id
robot_count
```

Requirements:

- `batch_id` stable for the lifetime of the candidate/session;
- no duplicate batch IDs in one supply layout;
- `color_id` real integer >= 0 and valid for the source LevelData palette;
- `robot_count` real integer > 0;
- reject bool/float/String/null/object values rather than coercing them;
- caller cannot mutate a live engine-owned batch by modifying an object/Array/Dictionary returned from a query.

You may use detached copies/snapshots or immutable query methods. Choose the least complex approach that is robust in GDScript.

## 8. Supply engine configuration

Support exactly 3, 4 or 5 columns.

Reject any other count.

Support preview depth 3 or 4.

For current V1/Hazard Bot evidence, configure 3 visible rows.

Every column is an independent FIFO queue.

Player-facing/read-only query surface must expose:

- current front batch, if any;
- visible preview up to configured depth;
- exhausted/remaining state needed by later consumers.

Do not let ordinary player-facing queries reveal the deeper hidden queue.

A separate full debug/save snapshot is allowed if clearly named/scoped and detached from internal mutable storage.

## 9. Transactional front selection

This is critical.

A future M24 consumer must be able to request a front batch and then accept or reject it without corrupting the queue.

Implement a two-phase or equivalent safe flow.

Behavior must be equivalent to:

```text
selection = supply.begin_front_selection(column_id)

if downstream_can_accept:
    supply.commit(selection)
else:
    supply.cancel(selection)
```

Exact names are your choice.

Required semantics:

- begin does NOT pop the queue;
- selection identifies the exact originating column and exact front batch/version;
- commit removes exactly that selected front;
- only that column advances;
- cancel changes nothing;
- double commit fails closed;
- stale transaction fails closed;
- transaction created before reset cannot commit after reset;
- transaction for column A cannot mutate B;
- if another legal commit changes the front, an older stale token cannot pop the new front;
- malformed token/transaction cannot mutate state.

Avoid a race-prone API that asks future callers to separately compare and pop without a protected transaction identity.

## 10. FIFO and preview rules

After a successful commit:

```text
old Row 1 removed
old Row 2 -> new Row 1
old Row 3 -> new Row 2
next hidden -> new Row 3
```

Only the selected column changes.

Other columns must retain exact batch identities and order.

Handle deterministic edge cases:

- column contains 0 batches;
- 1 batch;
- 2 batches;
- exactly preview depth;
- more than preview depth;
- every column exhausted.

There is no wraparound.

## 11. Candidate generation from LevelData

Implement deterministic candidate-supply generation from valid LevelData.

The generator must:

1. derive exact per-color counts from `LevelData.cells`;
2. partition each positive color total into positive integer batch counts;
3. produce stable unique batch IDs;
4. distribute batches across the configured 3/4/5 columns;
5. preserve exact per-color totals;
6. use a supplied seed;
7. reproduce the same layout for the same LevelData + config + seed;
8. report/persist the seed in snapshot/evidence;
9. remain bounded;
10. generate no invalid/empty batch.

Do not use wall-clock time once a seed is supplied.

Do not use global random state in a way that lets unrelated game code change the result. Prefer a private deterministic RNG seeded explicitly.

Do not hard-code Hazard Bot's five colors or 400 cells into production code.

## 12. Partition strategy

Choose a simple deterministic strategy suitable for later solver filtering.

M23 does not yet know which layouts are solvable.

Therefore:

- do not claim generated candidate layouts are production-valid simply because totals match;
- do not implement solver search;
- do not inspect routing to shape batches;
- do not mutate board cells;
- do not introduce difficulty heuristics that belong to later generation/solver systems.

It is acceptable for M23 to produce a legal candidate that M27 will later reject as unsolvable.

The generator should still avoid structurally malformed output and pathological zero/negative partitions.

## 13. Conservation law

For every source runtime color ID C:

```text
source_total[C] = count of LevelData.cells == C
generated_total[C] = sum(batch.robot_count where batch.color_id == C)

assert generated_total[C] == source_total[C]
```

Also prove:

```text
sum(all generated robot_count) == LevelData.get_cell_count()
```

for the opaque production artwork used by M23.

Do not treat visually blue/background-looking cells as already empty. Hazard Bot is full opaque source artwork; its logical cells are real work under current LevelData rules.

## 14. Deterministic IDs

Batch IDs must be stable/reproducible for identical inputs + seed.

Do not use random UUIDs or current timestamps if that breaks deterministic replay.

A straightforward deterministic ID format derived from generation order/seed/context is acceptable if uniqueness is proven.

Do not encode mutable UI position as the only identity.

## 15. Reset

Reset must restore the exact initial state of the active candidate supply:

- original queues;
- original batch IDs/order;
- original fronts/previews;
- original seed/config metadata;
- no stale selection transaction from before reset remains valid.

Reset must not regenerate a different layout unless an explicit regeneration API is invoked with a different seed.

## 16. Snapshots / query safety

Expose enough read-only data for future:

- UI rendering;
- save/replay;
- test evidence;
- M24 handoff.

But do not expose mutable internal queue arrays by reference.

Write a test that intentionally mutates a returned snapshot/preview object and then proves engine truth is unchanged.

## 17. Real Hazard Bot fixture

Use the real checked-in level:

`data/levels/m21_level_001_hazard_bot.json`

Load it through the real LevelLoader/LevelData path.

Add deterministic evidence that records:

- level ID;
- `20x20` dimensions;
- palette size;
- exact source cell total for each runtime color ID;
- seed;
- column count;
- preview depth;
- generated queues/batches;
- generated per-color quota totals;
- source vs generated equality;
- current front and visible preview for every column;
- hidden-depth proof if generated queue depth exceeds preview.

Use at least one fixed seed so the evidence is stable.

The evidence may print a compact structured trace instead of hundreds of noisy lines.

## 18. Rectangular and 59x59 fixtures

Add tests for:

- a rectangular LevelData fixture;
- a 59x59 = 3,481-cell fixture.

The tests must prove:

- no square assumption;
- exact conservation;
- deterministic generation;
- supported column configurations;
- sane performance/memory behavior.

Do not impose an arbitrary hard millisecond threshold unless the repository already has a justified convention. Record a sanity measurement instead.

## 19. Adversarial tests

At minimum test all of these:

- 2 columns rejected;
- 6 columns rejected;
- invalid preview depth rejected;
- duplicate batch ID rejected;
- invalid negative/out-of-range color ID rejected;
- zero quota rejected;
- negative quota rejected;
- float quota rejected;
- bool quota rejected;
- String quota rejected;
- null/malformed queue entry rejected;
- front selection on empty column fails cleanly;
- preview row cannot be selected directly;
- hidden row cannot be selected directly;
- begin then cancel leaves queue identical;
- begin then commit advances exactly one column;
- double commit fails;
- cancel then commit fails;
- stale token after another commit fails;
- token from before reset fails;
- forged/cross-column token fails;
- snapshot mutation does not mutate engine;
- same seed = same full layout;
- different seed still conserves all colors;
- all columns exhausted state;
- reset restores original exact state.

## 20. Protect M22 routing and existing gameplay

M23 must not change accepted routing semantics.

Do not modify behavior of:

- TargetSelector bottom-most/left-most WHAT policy;
- ReservationState;
- Railroad V1 geometry;
- legal ingress;
- post-rail orthogonal interior turns;
- Dispatcher;
- ScrubbotAgent;
- CompleteClearingLoop.

Fresh Hazard Bot C08 routing/targeting evidence should remain green.

If any protected production script unexpectedly needs modification, stop and justify it before proceeding. Prefer solving M23 without touching it.

## 21. SlotSystem boundary

The current `SlotSystem` is historical five-color-slot infrastructure and remains regression evidence.

Do not mutate it into the M24 batch-slot engine during M23.

M23 may expose a transaction/handoff API that M24 will consume later, but there must be no partial batch occupancy truth split between new supply code and old SlotSystem.

## 22. Tests and validation

Before major implementation, run the current root suite if practical and record the baseline.

After implementation run at minimum:

```powershell
godot --version
godot --headless --path . -s res://tests/run_tests.gd
```

Add and run a focused M23 evidence/smoke script if useful, for example:

```powershell
godot --headless --path . -s res://tests/m23_v01_batch_supply_evidence.gd
```

Also run the current equivalents of:

```powershell
godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd
godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd
godot --headless --path . -s res://tests/m22_v04_final_evidence.gd
godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd
godot --headless --path . -s res://tests/m21_real_art_smoke.gd
godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd
```

Run representative M20 lifecycle/queue-free smoke tests present in the current repo.

Finally:

```powershell
git diff --check
```

Record exact commands, totals, failures and exit codes.

Do not delete old green tests to make M23 pass.

## 23. Implementation commit discipline

Before commit:

- inspect `git status --short`;
- inspect `git diff`;
- confirm root `TASKS.md` is unchanged;
- confirm no owner-local file was staged accidentally;
- confirm no asset/image changes;
- confirm no M24–M27 production implementation.

Commit implementation with a focused message, for example:

`feat(M23-C001 V01): deterministic batch supply engine`

Push it to `origin/main`.

Record the exact implementation SHA.

## 24. Separate Claude log commit

After the implementation commit is already pushed, create:

`coordination/sessions/M23-C001/CLAUDE_LOG_V01.md`

The log must contain everything required by `CHATGPT_AUDIT_CRITERIA_V01.md`, including:

- synchronized starting SHA;
- implementation SHA;
- changed files;
- public API summary;
- transaction design;
- generator/partition design;
- same-seed determinism evidence;
- Hazard Bot source and generated per-color totals;
- rectangular/59x59 evidence;
- test command table with exit codes;
- root TASKS.md modified = NO;
- M24–M27 implementation = NO;
- image-generation credits spent = 0;
- warnings/limitations;
- `AWAITING_AUDIT`.

Commit and push the log separately, for example:

`docs(M23-C001 V01): batch supply evidence log`

Do not create `CHATGPT_AUDIT_V01.md` yourself.

## 25. Final response to owner

Return only a compact handoff:

```text
AWAITING_AUDIT
Implementation: <SHA>
Log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M23-C001/CLAUDE_LOG_V01.md
```

Do not self-declare PASS.
