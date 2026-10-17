# CLAUDE LOG — M46-RM-004 whole-milestone residual evidence + joint V02 handoff (V01)

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM004_WHOLE_EVIDENCE_CLOSURE_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM004_WHOLE_EVIDENCE_CLOSURE_AUDIT_CRITERIA_V01.md
- Master: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V02.md and criteria https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V02_AUDIT_CRITERIA.md
- Audit-spec clarification honoured: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM002_AUDIT_CRITERIA_CLARIFICATION_V02.md
- Sibling child log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_M46_RM003_V01.md (RM003 source `19c3240a`)
- Earlier evidence: `CLAUDE_LOG_M46_RM001_V01.md`, `CLAUDE_LOG_M46_RM002_V01.md` (same folder).
- **Final pinned source/test SHA: `e26f8205ab81896c4234e8b09fc7f6e9cfca5b8e`** (https://github.com/Sekiph82/Scrubbots/commit/e26f8205ab81896c4234e8b09fc7f6e9cfca5b8e; contains RM003 `19c3240a` and RM004 `e26f8205`).
- Evidence class: Claude-run local Godot 4.7.2 on the owner's Windows desktop (E1/E2). Not a ChatGPT audit, not E3. **ZERO GitHub Actions** (no dispatch / validation_only / rerun; both workflow job guards still `if: ${{ false }}`). Root `TASKS.md` not edited; no audit file written.
- Status: **AWAITING_CHATGPT_FULL_M46_REAUDIT**.

## 1. Production change in RM004 (V2-P3 diagnostic only)

`production_gameplay_host.gd` (+9 lines): `last_proof_diagnostic` = `{"id", "kind", "outcome", "stale"}` written when an off-frame proof ends:
- `_process`: `outcome` = `worker_error` (no result written), `deadline_timeout` (`res.timed_out`), `completed`; `stale` = the state key changed while the worker ran (result dropped, nothing cached).
- `_stop_proof`: `outcome` = `cancelled`.

Nothing else changed: the cached verdict, the `proof_timeout` user verdict for both a crash and the deadline, the same-state no-restart rule, 400 ms / 5 s caps, strings, economy. No logging, no network, no new allocation on the frame path besides one small Dictionary per settled proof.

## 2. Test: `tests/m46_rm004_residual_adversarial.gd` (6 groups)

Command: `godot --headless --path . -s res://tests/m46_rm004_residual_adversarial.gd` → `M46 RM004 RESIDUAL: PASS (6 case groups)`, exit 0, 156 s. The suite counts groups and fails if any group did not finish; each group asserts every branch it needs was reached (`seen` maps, row counts).

### G1 four-booster ledger, real 59x59 VOID-pocket host (RM004-01/02; RM002-01 PARTIAL)
Ledger per row = SB, charges snapshot, slot capacity, supply FIFO ids, slots snapshot, live reservations, board bytes; receipt = `last_booster_request`.

| Booster | Case | Result | Ledger change |
|---|---|---|---|
| +1 Slot | illegal: 0 charges, 0 SB | `insufficient_sb` | none |
| Tornado | illegal: colour not present | `color_not_present` | none |
| Selector | illegal: unknown batch | `not_eligible` | none |
| Selector | illegal: no target | `target_required` | none |
| Selector | illegal: 5 slots full | `not_eligible` | none |
| Random | illegal: 5 slots full (still, 400 ms) | `proof_timeout` | none |
| +1 Slot | legal: SB buy 5 → 6 | ok | SB 100000 → 99500 (price once), cap 5 → 6, FIFO / board / reservations unchanged |
| +1 Slot | illegal: second +1 this attempt | refused (empty reason string, see §6) | none |
| Random | rollback: commit fault | `commit_failed` | none (refunded) |
| Random | legal: SB buy, robots in flight, ≥ 3 empty | ok | SB −350 once, FIFO reordered (same multiset), slots / board unchanged |
| Selector | rollback: extract fault | `extract_failed` | none |
| Selector | legal: SB buy, deepest proven batch | ok | SB −500 once, exactly that id left the FIFO (others in order), now in a slot |
| Tornado | rollback: fault at `tornado_supply` after guard → cancel_one → claims → board → slots applied | `rolled_back` | none (board, slots, supply, 72 reservations restored) |
| Tornado | legal: SB buy | ok | SB −750 once, colour gone from board and supply, reservations 72 → 12 |

Popup: Tornado acquire popup opened, closed, reopened; `request_booster` while it is open → `modal_open` refusal receipt; ledger unchanged, nothing spent.
LOSE (genuine, valid fixture, no rule change): five P1 pocket batches tapped from column 4 fill the five slots (1 WAITING, 4 ACTIVE with no reachable target); with no empty slot no stripe can ever be placed → completion `LOST`. WON: L1 played to `WON`. On both terminals all four boosters refuse in `execute_booster`, `request_booster` and `booster_legality` (`terminal`) with charges and SB present; ledger unchanged. 17/17 rows.

### G2 fallback, malformed inputs, UNKNOWN_BOUND, independent classifier (RM004-03/04; RM002-02 PARTIAL)
- Malformed live slot (remaining 0, test-only corruption of a real L1 host) → `detached_copy() == null`; `booster_legality_offframe` starts no worker and runs the R05 synchronous fallback exactly once: Random 1.05 ms → `not_solver_safe`, Selector 6.54 ms → `not_eligible` (bound 550 ms = 400 ms + one classifier step); `execute_booster` refuses; ledger unchanged.
- Board / LevelData cell-count mismatch (24x24 board under the L1 level): no ProofState; Random unsafe, list empty, has-any false. Wrong-class supply (`RefCounted`): `_proof_state_buildable` false, `ProofState.from_runtime` null, `_is_safe_probe` false.
- UNKNOWN_BOUND (1 ms budget): `is_batch_eligible` false with `last_proof_timed_out`, Random `proof_timeout`, `execute_booster(selector)` → `proof_timeout`, nothing spent.
- Positive proofs vs an independent fresh `DeadlockClassifier` (test's own reorder + placement + `ProofState.from_runtime` + `classify`, unbudgeted): L1 19/19, L2 36/36, L3 51/51 supply ids agree with the Selector list at a still moment; L1 with robots moving 16/16 agree with the classifier at that in-flight count.
- Per the V02 clarification, a timeout is "not proven", not "proven unsafe"; no iff-under-timeout claim is made.

### G3 provenance, worker error vs deadline (RM004-05; V2-P3)
| Case | Provenance | External verdict |
|---|---|---|
| L1 Random proof finishes | `completed`, bool cached | proven |
| Selector proof cancelled | `cancelled`, nothing cached | — |
| 59x59 Random, cap 50 ms | `deadline_timeout` | `{legal false, proof_timeout}`, no restart |
| real `run_offframe` whose own result write hits a script error (read-only out array) | `worker_error` (`out[0]` stays null) | `{legal false, proof_timeout}` — identical, no restart |
| state changes (a tap) while the worker runs | `stale: true`, nothing cached | — |

**Observation (NOT_VERIFIED sub-class, for the auditor):** a script error *deeper inside the proof* (test: detached supply nulled) does not end `run_offframe`: Godot returns a default to the caller and execution continues, so the worker writes an ordinary refusal `{value false, timed_out false}`; provenance reads `completed` and the cached verdict is a refusal for that state. Fail-closed (never an authorization, never a spend), but such an internal error is indistinguishable from a genuine refusal without adding error trapping inside the proof code, which RM004 does not authorize. Only a missing result (error in `run_offframe` itself) is distinguishable.

### G4 partial Selector chips at 59x59, real 5 s cap (RM004-06; RM002-05 PARTIAL)
Standalone 59x59 host (its own ModalStack + AcquisitionFlow), still moment, one Selector charge: popup shows "Checking...", no chips, Use blocked; worker ran 5013 ms → partial list, 29 of 118 batches proven. The 12 chips (cap) equal the first 12 proven ids in order, compared id by id; each chip re-proven by an independent unbudgeted detached adapter (12/12). An unlisted supply batch (`R4B0026`) → `execute_booster` refuses `proof_timeout`, ledger unchanged. Pressing chip `R4B0000` then Use: charge 1 → 0 once, SB unchanged, the batch is in a slot, the rest of the FIFO in order.
Observation (also in RM003 log): each worker uses a fresh detached adapter whose list offset is 0, so at 59x59 the partial list is always the first ~30 ids in column-major order; the live adapter's resume offset only applies to the synchronous fallback. Fail-closed, inside the accepted partial-list semantics.

### G5 lifecycle (RM004-07)
- Real app L1: rewarded Random ad completed while the popup proof runs (charge 1, auto-use armed) → `host.retry()`: one receipt, the earned charge used exactly once on the new attempt, no worker left.
- Owned charge, HUD hold ("checking", worker running) → route Home → next level: old worker joined, new host idle, charge kept, SB unchanged.
- 59x59 host freed with a worker running: joined in 10.4 ms, exactly one settle (from `_exit_tree`), none after free.
(Retry / cancel matrix, duplicate settle, late close, route-to-Home remain covered by `m46_rm002_adversarial` T03/T06, re-run below.)

### G6 cold Results and retry profile (RM004-08; V2-P5)
- Real app L1 played to WON twice (second via `retry_from_results`). The terminal tick itself (synchronous win latch + terminal handlers + Results route, measured around the tick that turned terminal): **cold 193.66 ms, warm 82.70 ms**; first Results frame 8.09 ms cold / 1.90 ms warm; following frames mean 0.85 / 0.38 ms. This one-off terminal hitch is attributed here and not optimized (prompt: no invented optimization); not a per-frame budget item.
- 59x59 stripes host, p12-style: 2 × 30 mid-level retries: worst 42.43 / 45.95 ms, mean ~40 ms (≤ 50.1, bound unchanged). Earlier full-suite p12 worst 48.51 / 49.00 ms; p16 max outliers are reported from the final full run (§3).

### Negative controls (RM004-10), each a temporary edit, full suite run, restored byte-identical
Each mutant was applied to the source, the whole RM004 suite was run, and the three touched files were restored from a scratch backup (`cmp` identical before the commit).

| Mutant | Edit (test-only, reverted) | Caught by |
|---|---|---|
| N1 unproven chips | Selector list includes every batch (`if proven.has(bid)` → `if true`) | G2 independent equivalence (malformed fallback lists a batch; count-mismatch adapter lists ids) and G4 chip check |
| N2 single +1 guard removed | BoosterService `can_activate_plus_one` check → `if false` | **not caught**: second +1 still refused by the host `can_grow_to_sixth` guard and `capacity.activate_plus_one` (which refunds). Defense in depth, not a test gap |
| N2b +1 guards + refund removed | host `can_grow_to_sixth` guard, service guard and the activate-failure refund all removed | G1 "second +1" row: SB 99500 → 99000 charged for a refused +1 |
| N3 timeout reused as proven | cached `"timeout"` counts as proven in `propose_random_reorder` | G3 `same_external` (the deadline state becomes legal) |
| N4 no refund after refusal | Random commit-failure refund removed | G1 Random rollback row: SB 99500 → 99150 |
| N5 null worker result positive | host caches `true` for a null result | G3 `same_external` |
| N6 provenance collapsed | `worker_error` reported as `deadline_timeout` | G3 `worker_error` |
| N7 retry 15 ms slower | `OS.delay_msec(15)` in `retry()` | G6 retry worst 83.64 ms > 50.1 |

## 3. Final pinned-source runs (RM004-11; MV2-05)
All at HEAD `e26f8205ab81896c4234e8b09fc7f6e9cfca5b8e`, one sequential batch 2026-10-18 00:58:43 → 01:22:41 (+03:00). Contention: no other Godot **engine** process ran (process command lines checked; only 7 `godot-ai.exe attach` MCP helper processes, not engines). Desktop only; no phone / GPU claim.

**Full `tests/m46_performance.gd`: PASS (22/22 cases, 0 fail), exit 0, 472 s** (previous full baseline 22/22 at `0fa6ee24`, 487 s). The only full run in this cycle.

| Item | Final value | Budget / note |
|---|---|---|
| SB-M46-013 full 59x59 level | mean 2.397 / p95 6.707 / p99 8.316 / max 47.770 ms | mean ≤ 4, p99 ≤ 16.7 (unchanged) |
| p16 pocket (v2 VOID, 12 colours) | mean 1.968 / p99 7.933 / **max 52.974 ms**, peak agents 117 | earlier ~614 ms one-off max not reproduced; max reported, not a budget |
| p17 6 slots + Tornado | mean 2.507 / p99 8.715 / max 60.011 ms; Tornado 50.34 ms | report |
| p18 maze | mean 3.378 / p99 11.219 / max 49.621 ms | |
| p20 Random + Selector | mean 2.258 / p99 8.145 ms | |
| p21 400 ms budget | worst call 421 ms | ≤ budget + 200 |
| SB-M46-012 30 retries | worst **43.46 ms**, nodes 292 → 292 | ≤ 50.1 (unchanged); earlier 48.51 / 49.00 |
| SB-M46-014 density | peak 114 agents (114 nodes, 114 reserved) | floor 90 |
| SB-M46-011 | identical rebinds 0 allocations, idle +0 objects | |
| p22 59x59 popup / HUD hold | settled 4933–4936 ms, worst frame 1.2–1.3 ms; settle + auto-use frame 44–46 ms (report) | |

Sequential suites on the same SHA (all exit 0):

| Suite | Result | s |
|---|---|---|
| m46_rm003_ftue_coach_performance | PASS 4/4 groups | 52 |
| m46_rm004_residual_adversarial | PASS 6/6 groups | 157 |
| m46_rm002_adversarial | PASS 8/8 groups | 37 |
| m46_r07_ui_legality | PASS | 60 |
| m46_slot_rebuild | PASS | 10 |
| m44_ftue | PASS 23/23 | 61 |
| m39c_boosters | PASS | 1 |
| m39_v03_integration | PASS | 11 |
| m39_v04_integration | PASS | 17 |
| m39_v04_tornado_inflight | PASS | 9 |
| m28_c002_c003_final_gate | PASS 22/22 | 96 |
| m28_c002_c001_gameplay_v02 | PASS 14/14 | 25 |
| m43_c003_c001_acquisition | PASS 34/34 | 94 |
| m43_c004_c001_fail_need_a_hand | PASS 40/40 | 216 |
| m55_core_chaos | PASS | 53 |
| run_tests | ALL PASS | 63 |

Not run in this cycle (unchanged areas, not affected by RM003/RM004 diffs): the remaining M43 ceremony/shop/collection suites, M55 economy/heart/long-session suites, M50 board-symbol suites. Cloud CI: **CLOUD_CI_DEFERRED_COST_FREEZE**.

## 4. Owner-local provenance (RM004-09; V2-P4)
Read-only `git diff` of the owner's dirty files (not modified, not copied, no clone/worktree):
- `project.godot`: extra autoload `_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"` (prints `[godot_ai game_helper] registered mcp capture` at each run; registers a logger/capture hook), GameFeelFlow autoload by UID (`uid://ckhnfaf1odnpl`) instead of path, `[audio] buses/default_bus_layout` removed (default layout used), `godot_ai` editor plugin enabled; `config/features` line reordered.
- `scenes/app/main.tscn`: editor re-save (ordering/metadata), no node or property change (RM002 finding R2-F3).
Effective config for every run in this cycle = that owner-local file. Clean GitHub-main runtime parity: **OWNER_LOCAL_PROJECT_PARITY_OPEN**.

## 5. Criterion dispositions

### RM004
| Criterion | Status | Evidence |
|---|---|---|
| RM004-01 | PASS (E2) | G1 14 booster rows incl. 3 rollback faults, 5 → 6 slots, 59x59 pocket |
| RM004-02 | PASS (E2) | G1 genuine LOST + WON, modal-open refusal, popup close/reopen, Tornado partial-mutation rollback |
| RM004-03 | PASS (E2) | G2 null detached copy → bounded fallback, malformed board/supply/slot |
| RM004-04 | PASS (E2) | G2 independent classifier L1–L3 still + moving; UNKNOWN_BOUND refuses |
| RM004-05 | PASS for missing-result crash vs deadline (E2); NOT_VERIFIED for errors swallowed inside the proof | G3 |
| RM004-06 | PASS (E2) | G4 chip-by-chip, independent re-proof, unlisted refused, one use |
| RM004-07 | PASS (E2) | G5 + m46_rm002 T03/T06 |
| RM004-08 | REPORTED | G6 cold/warm terminal tick + Results frames; retry profile; p16 from §3 |
| RM004-09 | OPEN (accurately) | §4 |
| RM004-10 | PASS (E2) | §2 negative controls |
| RM004-11 | PASS (E2) | §3: full 22/22 exit 0 at `e26f8205`, 16 suites, budgets unchanged, p12 43.46 ms |
| RM004-12 | gates preserved | Need-a-Hand untouched; F5 / phone-GPU / cloud CI OPEN; no Actions; owner files untouched |

### Original RM002 PARTIAL rows (MV2-03)
| RM002 | Now |
|---|---|
| 01 four boosters 59x59 | G1 legal + illegal + rollback + ledger + LOSE/WON |
| 02 classification / null | G2 + G3; spec read per V02 clarification (positive proof only; unknown/timeout/crash fail closed) |
| 05 budgets + Selector UI | G4 chip-by-chip under the real 5 s cap |
| 10 owner files | §4, parity OPEN |
| 11 CPU / UI attribution | RM003 (FTUE copy fixed and measured) + G6 (terminal / Results) |

### Joint V2-P1..P6 reconciliation
| Finding | Disposition |
|---|---|
| V2-P1 FTUE moving Selector 23–28 ms | Fixed in RM003 (`19c3240a`): L2 copy 1.2–1.8 ms, 59x59 hint 3.5 ms; sibling Tornado scan also removed; popup/purchase unchanged; mutants M1–M4 caught |
| V2-P2 RM002 evidence gaps | G1, G2, G4, G5, G6 |
| V2-P3 spec + diagnostic | `last_proof_diagnostic`; external behaviour identical; deep-error sub-class NOT_VERIFIED (§2 G3) |
| V2-P4 owner-local runtime | documented, OPEN |
| V2-P5 p12 / p16 / cold | reported (§2 G6, §3), no threshold change |
| V2-P6 governance | TASKS.md untouched, no audit file, stop at AWAITING |

## 6. Observations for the auditor (no production change made)
1. Terminal tick on L1 WON costs 194 ms cold / 83 ms warm on this desktop (G6). One-off per attempt; candidate for a future profiled task only if the auditor/owner wants it.
2. Deep script errors inside a proof surface as refusals, not as `worker_error` (G3).
3. Off-frame Selector partial lists always start at offset 0 (G4).
4. A second +1 Slot in the same attempt is refused with an empty `reason` string in the receipt (G1); behaviour is correct (no spend), only the reason text is blank.
5. Previously disclosed, not in the V02 frozen list, auditor attention: p21 at a still 59x59 moment logs a completion tick worst of **3293 ms (stripes) / 2931 ms (pocket)** — the quiescent-state completion/LOSE evaluation on the main thread. The same 2.96–3.31 s figure was disclosed in `CLAUDE_LOG_R05_V01.md` (machine-load note); it predates RM003/RM004 and was not touched here. Whether it needs its own remediation is the auditor's/owner's decision.
6. No new production defect outside the frozen V2-P1..P6 roots was found by RM003/RM004 work, so no STOP was needed.

No fresh-context peer review was run in this cycle; this log is implementer evidence only.
