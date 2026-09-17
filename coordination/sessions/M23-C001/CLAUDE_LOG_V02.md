# M23-C001 V02 — Batch Supply Engine Hardening — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Auditor prior verdict: `CHANGES_REQUIRED` (`CHATGPT_AUDIT_V01.md`)
Handoff state: `AWAITING_AUDIT`

## 1. Commit identities

- **Safe-sync start `origin/main` SHA:** `027b116` (fast-forward `a357bb5..027b116`;
  owner-local `project.godot` + untracked `.import`/`.uid` sidecars preserved,
  left unstaged; no `reset --hard` / `clean -fd` / destructive restore / force push).
- **Implementation SHA (pushed first):** `e849290fb604317b5839c01af99e6bb55ca177b8`
  (`fix(M23-C001 V02): harden batch supply transaction and reset boundaries`).
- **This log** is a separate evidence commit pushed after the implementation SHA.

## 2. Changed files (implementation commit e849290)

- `scripts/gameplay/supply/batch_supply_engine.gd` — instance-identity transaction
  binding; load-boundary batch revalidation; atomic `load_candidate` seam;
  seed+palette reset restoration; `get_palette_size()` accessor.
- `scripts/gameplay/supply/batch_supply_generator.gd` — strict `LevelData` source
  validation; atomic candidate commit.
- `tests/run_tests.gd` — `_run_m23_v02_hardening_tests()` (F-001..004 adversarial),
  direct 59x59 per-color assertion (F-005). `+36` checks (4885 → 4921).
- `tests/m23_v02_hardening_evidence.gd` — new dedicated V02 evidence script.

Owner-local `project.godot` NOT staged. Root `TASKS.md` absent. No
routing/target/reservation/dispatcher/agent/clearing/SlotSystem file changed.

## 3. Finding closure — code + direct test evidence

### F-M23-V01-STRICT-001 — forgeable transaction identity → CLOSED

Code (`batch_supply_engine.gd`): `begin_front_selection()` records the EXACT minted
instance in `_open_tokens[tid]["object"]`. `_authentic_record(tx)` requires
`rec["object"] != tx` to fail closed — exact RefCounted reference identity, which a
caller cannot forge. `commit()`, `cancel()`, `has_open_transaction()` all route
through `_authentic_record()`. A newly constructed same-class object carrying a live
token id resolves to a record whose stored object is a *different* instance; a token
whose `_token_id`/`_column` fields are mutated to another live id also mismatches.

Direct test evidence (`m23_v02_hardening_evidence.gd` F-001, mirrored in run_tests):
```
F001 A.token=1 B.token=2 forged.token=1 (same as A)
  ok: forged same-class object with A's live id cannot commit
  ok: forged object cannot cancel A
  ok: forged object not reported as owning A
  ok: legitimate A still open
  ok: no column mutated by forged commit/cancel
  ok: field-mutated A cannot redirect to B (identity mismatch)
  ok: redirect attempt changed nothing
  ok: original B still commits after all attacks
F001 after B commit: col1 front=B1 col0 front=A0
  ok: B advanced one; column 0 untouched
```
Double-commit / cancel-then-commit / stale-front / post-reset / forged-Dictionary /
null all remain fail-closed (V01 coverage retained in run_tests).

### F-M23-V01-STRICT-002 — malformed ColorBatch load → CLOSED

Code: `_build_columns(cols, palette_size)` revalidates each entry's observable value
via getters — `is ColorBatch` AND non-empty unique String id AND `color_id` int >= 0
AND `robot_count` int > 0 AND (`palette_size >= 0` ⇒ `color_id < palette_size`).
Builds into a temp; the caller commits engine state only on a non-null return, so any
failure leaves the prior candidate untouched (no partial mutation).

Direct test evidence (F-002):
```
  ok: blank directly-instantiated ColorBatch rejected
  ok: post-hoc negative color_id rejected
  ok: post-hoc zero robot_count rejected
  ok: post-hoc empty batch_id rejected
  ok: color_id >= known palette size rejected
  ok: prior candidate preserved after every failed load
```
Real `ColorBatch` objects were corrupted after construction (`_color_id=-7`,
`_robot_count=0`, `_batch_id=""`) and a directly `ColorBatch.new()`-instantiated blank
— each rejected; prior committed snapshot preserved byte-for-byte.

### F-M23-V01-STRICT-003 — reset queue + seed + palette → CLOSED

Code: atomic `load_candidate(cols, seed, palette_size)` validates and snapshots
`_columns` + `_seed`/`_initial_seed` + `_palette_size`/`_initial_palette_size`
together. `reset()` restores all three and clears open tokens. `set_seed()` /
`set_palette_size()` remain but are overridden by reset truth. Generator now commits
through `load_candidate`.

Direct test evidence (F-003):
```
F003 committed seed=7 palette=5
F003 after mutate+commit seed=999999 palette=2
F003 after reset seed=7 palette=5
  ok: reset restores exact queue + seed + palette snapshot
  ok: reset restored original metadata
  ok: pre-reset transaction invalid after reset
```
Also (run_tests): a failed `load_candidate` after a good candidate leaves queue +
seed + palette untouched (no partial candidate change).

### F-M23-V01-STRICT-004 — strict LevelData validation → CLOSED

Code (`batch_supply_generator.gd`): `color_totals()` now requires `level is LevelData`
before touching any field, positive `width`/`height`, `PackedStringArray` non-empty
palette, `PackedInt32Array` cells, `cells.size() == level.get_cell_count()`, and every
cell id in range; returns `{}` otherwise. `generate()` returns null when totals empty.
Foreign objects never raise an uncaught script error (type gate precedes field access).

Direct test evidence (F-004):
```
  ok: null -> {}
  ok: foreign RefCounted -> {}
  ok: foreign source generate -> null
  ok: empty palette -> {}
  ok: out-of-range cell id -> {}
  ok: cells.size != get_cell_count() -> {}
  ok: cell-count mismatch generate -> null
  ok: zero dimensions -> {}
  ok: valid rectangular LevelData still generates
```
No second color authority added; valid input still conserves exactly.

### F-M23-V01-STRICT-005 — direct 59x59 per-color → CLOSED

Code: run_tests 59x59 block + evidence script compare `color_totals(blvl)` against
generated per-color totals for every color (not only grand total 3481).

Direct test evidence (F-005):
```
M23_59x59_SOURCE { 0: 1161, 1: 1160, 2: 1160 }
M23_59x59_GENERATED { 0: 1161, 1: 1160, 2: 1160 }
  color 0: source=1161 generated=1161 ok
  color 1: source=1160 generated=1160 ok
  color 2: source=1160 generated=1160 ok
  ok: each 59x59 source color total equals generated quota
  ok: same seed reproduces identical 59x59 layout
M23_PERF 59x59 x2 generate = 0 ms
```

## 4. Preserved V01 passing behavior

3/4/5 FIFO columns, preview depth 3/4 (V1 depth 3), front-only selection, hidden
content secrecy, independent-column advance, deterministic seeded generation, positive
integer partitions, exact per-color quota conservation, unique batch IDs, detached
snapshots, exact queue reset, Hazard Bot real-level evidence, candidate-only (no
solvability claim). All retained V01 checks still green.

## 5. Validation commands / results / exits

Run from `C:\Users\sekip\Desktop\ScrubBots`.

| # | Command | Result | Exit |
|---|---------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4921, Failures: 0, RESULT: ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m23_v02_hardening_evidence.gd` | `M23 V02 hardening evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m23_v01_batch_supply_evidence.gd` | PASS | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 8 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 9 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | PASS (full 400-cell clear) | 0 |
| 10 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 13 | `git diff --check` | clean (only informational LF→CRLF notices) | 0 |

## 6. Statements

- `root TASKS.md modified = NO` (absent from the implementation diff).
- `M24-M27 implementation = NO` (no five-slot batch engine, target claim, auto
  dispatch, or solvability/deadlock logic).
- `image-generation credits spent = 0`.
- No protected system (TargetSelector / ReservationState / Railroad V1 routing /
  Dispatcher / ScrubbotAgent / CompleteClearingLoop / SlotSystem) modified; all
  M22/M21/M20 regressions green.
- No solver/deadlock claim added; candidates remain candidates only (M27 scope).
- No audit verdict authored. `AWAITING_AUDIT`.
