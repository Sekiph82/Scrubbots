# M23-C001 V01 — ChatGPT Strict Audit

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Auditor: ChatGPT
Implementation SHA: `a19e2de18cc0e4ec0a4bfe2c83fd367aea26bf4d`
Evidence log SHA: `a357bb5e6eeaf743048c2ef83093fdf0125cc6db`
Verdict: **CHANGES_REQUIRED**

## Executive result

The V01 implementation is well-scoped and gets most of the M23 Batch Supply Engine architecture right: 3/4/5 FIFO columns, preview secrecy, two-phase consumption shape, deterministic seeded generation, per-color conservation, resettable queues, detached snapshots, Hazard Bot evidence, and protected M22/M21/M20 subsystem preservation are all substantially present.

However, the strict M23 contract cannot pass because the public transaction boundary is forgeable, malformed `ColorBatch` instances can be admitted by `load_columns()`, and reset does not own/restore the candidate's full seed/reporting state. These are production API defects, not merely missing test labels.

M24 must not start until these are corrected.

## Verified clean areas

- Start SHA `2cbae3b1f7bc671478becc3b684b3660f1eee3dd` -> implementation SHA is exactly one implementation commit.
- Implementation diff is narrow: four new `scripts/gameplay/supply/` files plus M23 tests/evidence only.
- Root `TASKS.md` is absent from the implementation diff.
- No M24-M27 production code was introduced.
- No routing, TargetSelector, ReservationState, Dispatcher, ScrubbotAgent, CompleteClearingLoop or SlotSystem production file changed.
- `ColorBatch.make()` rejects ordinary invalid factory inputs.
- 3/4/5-column configuration and preview-depth validation are present.
- Player-facing preview is capped and deeper batch contents are not exposed by ordinary front/preview APIs.
- FIFO commit behavior advances only the originating column in the normal path.
- Generator uses a private seeded RNG, deterministic color ordering, deterministic IDs and exact positive integer partition sums.
- Hazard Bot source totals and generated totals match per color.
- Generator intentionally does not claim solvability; M27 boundary is preserved.
- The reported root suite and required historical regressions are green in Claude's log.

## F-M23-V01-STRICT-001 — Forgeable transaction identity

**Severity: BLOCKING**

`BatchSelectionTransaction` has a public constructor accepting a caller-supplied token ID. `BatchSupplyEngine.commit()` and `cancel()` validate only:

1. object category `tx is BatchSelectionTransaction`, and
2. whether `tx.get_token_id()` exists in `_open_tokens`.

The engine does **not** prove that the submitted object is the exact transaction instance originally minted by `begin_front_selection()`.

Therefore a caller can:

1. create/open a legitimate transaction B,
2. learn or predict its monotonic token ID,
3. construct a new `BatchSelectionTransaction` using that live ID,
4. pass the forged object to `commit()` or `cancel()`,
5. mutate supply state for the legitimate open transaction.

This violates V01 audit criteria §7.8-§7.10 and §14 (`cross-column`, `forged transaction`, malformed transaction cannot mutate state). The existing test only proves that a forged **Dictionary** fails. It does not test a forged real `BatchSelectionTransaction` object carrying another open token ID.

### Required correction

Bind each open transaction to an unforgeable runtime identity, for example exact RefCounted instance identity / `get_instance_id()` stored by the engine. `commit`, `cancel`, and `has_open_transaction` must require both the expected token record and the exact minted object identity. A newly constructed same-class object with a valid live token ID must fail closed with zero queue mutation.

Also prove that mutating public-ish fields on the original token cannot redirect it to another transaction/column.

## F-M23-V01-STRICT-002 — `load_columns()` accepts malformed `ColorBatch` instances

**Severity: BLOCKING**

`load_columns()` currently checks that an entry:

- `is ColorBatch`,
- has a non-empty unique `batch_id`.

It does not revalidate `color_id >= 0`, `robot_count > 0`, or palette bounds where palette truth is known.

GDScript underscore fields are conventionally private, not language-enforced private. A caller can instantiate or mutate a `ColorBatch` into an invalid state and still pass the `is ColorBatch` gate. `duplicate_batch()` then copies that invalid state into engine-owned truth.

This violates audit criteria §3, §4, §10 and §14 requiring malformed queue content, invalid color IDs and zero/negative quota to fail closed.

### Required correction

At the `load_columns()` trust boundary, validate the observable batch value again. At minimum require:

- non-empty String batch ID,
- integer `color_id >= 0`,
- strictly positive integer quota,
- unique ID,
- `color_id < palette_size` whenever the candidate is bound to a known palette size.

A directly-instantiated/mutated invalid `ColorBatch` must not enter engine-owned state.

## F-M23-V01-STRICT-003 — Reset does not restore full initial candidate metadata

**Severity: BLOCKING**

Owner decision §12 and audit criteria §13 require reset to restore the exact initial queue/seed state and preserve the original generation seed/reporting state.

The current engine snapshots only `_columns` into `_initial`. `_seed` and `_palette_size` are mutable through public setters and are not part of the reset snapshot. Thus after a generated candidate is created, a caller can change reporting metadata with `set_seed()` / `set_palette_size()` and `reset()` will restore the queue while leaving the changed metadata in place.

### Required correction

Make candidate metadata part of the committed initial candidate state. Prefer one atomic candidate-load/configuration seam or an equivalent sealed initialization path that records:

- seed,
- palette size,
- column content/order.

`reset()` must restore all of them. If public metadata setters remain, tests must prove reset restores the original values; otherwise remove/restrict the mutable seam from the gameplay API.

## F-M23-V01-STRICT-004 — Malformed LevelData coherence is not fail-closed enough

**Severity: REQUIRED HARDENING**

`BatchSupplyGenerator.color_totals(level)` directly accesses `level.cells` and `level.palette` after only checking `level != null`. It also does not require `cells.size() == level.get_cell_count()`.

The strict criteria require malformed source input to fail closed and require generated total quota to equal the LevelData logical cell count. A malformed/foreign object, or a malformed LevelData object whose cell array length disagrees with width*height, must not become a supply candidate.

### Required correction

Use the real `LevelData` type/category (or an equally strict production-safe contract) and validate:

- valid LevelData category,
- positive dimensions / valid palette,
- `cells` has the expected type,
- `cells.size() == level.get_cell_count()`,
- every cell palette ID is in range.

Malformed/foreign source objects must return `{}` / `null` without inventing quota or continuing generation.

## F-M23-V01-STRICT-005 — Missing direct 59x59 per-color assertion

**Severity: EVIDENCE GAP**

The 59x59 test directly asserts only the grand total `3481` plus determinism. Audit criteria §12 explicitly asks for per-color conservation on the 59x59 fixture as well.

The generator algorithm appears conservation-correct, but V02 must add direct per-color assertions for the 59x59 fixture so this criterion is proven rather than inferred.

## V02 scope

V02 is a narrow hardening cycle. Do not redesign the generator or alter M22 behavior. Preserve all V01 features that already pass.

Required V02 themes:

1. unforgeable exact transaction-instance ownership;
2. load-boundary batch-value validation;
3. exact reset of queue + seed + palette metadata;
4. malformed LevelData/category/cell-count fail-closed validation;
5. direct 59x59 per-color conservation evidence;
6. full V01 + historical regression rerun.

## Closure state

- `SB-M23-001..SB-M23-030`: **remain open**.
- M23-C001 V01: **CHANGES_REQUIRED**.
- Next cycle: **M23-C001 V02**.
- M24: **must not start**.
