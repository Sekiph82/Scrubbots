# M46 — Booster-proof scratch slot rebuild fidelity — CLAUDE LOG SLOT_REBUILD V01

**Base and scope:**
- Base: `origin/main` `63a0c454` (R06).
- Owner request in chat, 2026-10-16: "Do this task here: Fix booster proof slot rebuild (remaining/WAITING)", after the R06 `CLAUDE_PEER_REVIEW` flagged MAJOR-2.
- Godot 4.7.2 headless, local only. **No GitHub Actions** (CLOUD_CI_DEFERRED_COST_FREEZE).

**Result: LOCAL_PASS.**

## 1. Defect (pre-existing since M39 V02/V03)
`ProductionBoosterAdapter._scratch_slots_from_live()` builds the scratch M24 slots that every Random / Selector proof reasons over. It rebuilt each occupied slot with `make_occupied(initial_count)`. That has three effects:
1. **remaining = initial:** robots already cleared were counted again (L1 still moment: live remaining 2, initial 15).
2. **State forced ACTIVE:** live WAITING slots became ACTIVE.
3. **Scratch `_next_sequence` stayed at 1:** a batch the proof places got sequence 1, before live sequences of up to 17. ProofKernel dispatches in ascending placement sequence (`proof_kernel.gd` `_eligible_slots`).

The kernel's own rebuild (`proof_kernel.gd` around lines 165–188) already does this correctly; the adapter did not.

**Impact (verified by a distinct `CLAUDE_PEER_REVIEW`):** today's booster gate is the first-progress `DeadlockClassifier`.
- PROGRESSABLE = quiesce clears something; STALLED = any reachable state with fewer ACTIVE cells.
- Before the first clear, `remaining` only matters as capacity > 0. Lane order does not decide whether some lane can claim, and WAITING is not a dispatch gate in the kernel.

**So the old mismatch could not change a verdict.** It is a **fidelity defect, not an observed soundness hole.** It would matter for any SOLVE / multi-clear gate built on the same scratch state.

## 2. Fix
`_scratch_slots_from_live()` now mirrors the kernel's rebuild:
- `make_occupied(remaining)` (initial == remaining; nothing reads `initial_count` for future behaviour);
- WAITING restored;
- the live `_next_sequence` copied;
- preload consts instead of `load()`.

A malformed live slot (remaining 0, not reachable from valid engine state) returns null, and every caller fails closed:
- the Random 3-step proof;
- the Selector single-batch proof;
- `detached_copy`, after which the R06 host falls back to the synchronous path, which also fails closed.

`FiveSlotEngineMaxCapacity()` was unused and is removed.

**Also fixed (peer-review MINOR, pre-existing since 657c5d99):** `FiveSlotBatchEngine.free_slot_if_idle` called a nonexistent `SlotBatchState.get_remaining()`; it now calls `get_remaining_to_clear()`. Its only caller (Selector rollback after placement) is not reached by today's single-stage booster transaction, but it would have raised a runtime error once reachable.

The adapter header text now describes the real gate (the classifier progress proof, three consecutive Random selections), not "SOLVED".

## 3. Evidence — new `tests/m46_slot_rebuild.gd`
A real L1 host, played with taps to still moments, at 5 and at 6 slots (+1 Slot).

**Before the fix:** FAIL (4) on exactness and sequence-after-live, at both 5 and 6 slots.

**After the fix:** PASS.
- At 3 still moments per run: `ProofState.from_runtime(live slots) == ProofState.from_runtime(scratch slots)` (remaining, WAITING, sequence, capacity), and scratch next sequence > every live sequence.
- Partly cleared slots (1 / 4) and WAITING slots (4 / 8) were present and asserted.
- Malformed slot: scratch rebuild null, and detached copy, Random and Selector (list and single batch) all fail closed.
- `free_slot_if_idle`: an untouched ACTIVE slot frees; partly cleared and WAITING slots are never freed.

## 4. Regressions (local)
**Adapter fix (before the `free_slot_if_idle` line change), all PASS:**

| Suite | Result |
| --- | --- |
| m46_slot_rebuild | PASS |
| m39c_boosters | PASS |
| m39e_full_matrix | PASS |
| m39_v02_atomicity | PASS |
| m39_v02_capacity | PASS |
| m39_v02_integration | PASS |
| m39_v03_full_surface | PASS |
| m39_v03_integration | PASS |
| m39_v04_integration | PASS |
| m39_v04_tornado_inflight | PASS |
| m39_c003_random_any_booster_rewards | PASS |
| m28_c002_c003_final_gate | 22/22 |
| m28_c002_c001_gameplay_v02 | 14/14 |
| m55_core_chaos | PASS |
| m43_c003_c001_acquisition | 34/34 |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c005f_phase3_meta_rewards_acquisition | 15/15 (announced spy-plugin fault lines) |
| m30_completion_authority | PASS |
| run_tests | ALL PASS |
| m46 `rs budget slice` | p20 + p21 + p22 PASS; only the subset-ledger line fails, by design. Includes detached == live on L1–L4 and L1 mid-play, and the HUD Random used once with 0 main-thread proofs |

**After the `free_slot_if_idle` fix and the final test edits:**
- m46_slot_rebuild PASS, with both runs asserted complete;
- run_tests ALL PASS;
- m39_v02_integration, m39_v04_tornado_inflight, m39e_full_matrix, m39c_boosters: PASS.

**Honest notes:**
- An earlier draft of the test aborted its 5-slot run on an empty supply column and still printed PASS. The test now asserts that both runs completed.
- The new `free_slot_if_idle` assertions were written after the engine fix, so they were not run against the pre-fix code. The pre-fix call targets a method `SlotBatchState` does not have.

## 5. Review
A distinct fresh-context **`CLAUDE_PEER_REVIEW`** (not ChatGPT, read-only) gave **PASS**:
- the fix is exact;
- null is unreachable from valid state;
- every caller fails closed;
- no side effects on the R06 verdict cache, Selector placement or the sixth slot.

**Applied from the review:**
- wording (fidelity, not soundness);
- WAITING assert;
- fail-closed null-path test;
- the `free_slot_if_idle` fix and test;
- adapter header text;
- `round` renamed.

**Not changed:** the m46 p20 / p22 diagnostic lines use the scratch result without a null guard. Null is unreachable there, and a crash would still fail the suite.

## Footprint
- `user://m46_slot_rebuild_*.save` is deleted by the test.
- No temporary scripts.
- No owner file was touched.
