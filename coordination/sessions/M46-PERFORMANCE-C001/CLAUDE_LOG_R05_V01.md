# M46 R05 — Owner time budget for booster solver-safety proofs — CLAUDE LOG R05 V01

**Base and scope:**
- Base: `origin/main` `2c20c244` (R04).
- Owner instructions in chat, 2026-10-16:
  - Bound the quiet-moment booster solver proof and fail closed. Reproduce the slow case first, then measure how often Random / Selector are refused.
  - Owner rules (given in Turkish):
    - target 250 ms, or a measured safe upper limit;
    - on timeout, cancel the booster safely;
    - never spend SB or a booster charge;
    - valid moves must not be permanently blocked, and the player can retry;
    - test 59×59 with moving and stationary robots;
    - no GitHub Actions.
- Godot 4.7.2 headless, local desktop only. **No GitHub Actions** (CLOUD_CI_DEFERRED_COST_FREEZE), no phone and no GPU.

**Result: LOCAL_PASS for the owner rules.** **The budget value needs an owner decision** (§6). With 400 ms, Random at a still moment is refused on most production levels.

## 1. Reproduction (no budget, still moment = 0 robots in flight)

### 59×59 (p21 fixtures, 1080×2160 host)

| Proof | Time |
| --- | --- |
| Random legality | **3.8 s** (stripes), **24.5 s** (pocket) |
| Selector single-batch proof | 249–361 ms |
| Selector full list (popup) | about 25–30 s |

### Production levels 1–10 at a still level start
Unbudgeted, sized host, desktop CPU.

| Level | Size | Random | Selector full list |
| --- | --- | --- | --- |
| L1 hazard_bot | 20×20 | 182 ms | 870 ms |
| L2 apple | 32×32 | 4,598 ms (not safe) | 7,008 ms |
| L3 palm_tree | 38×38 | 132 ms | 12,118 ms |
| L4 orange_cat | 32×32 | 224 ms | 7,670 ms |
| L5 party_toucan | 33×33 | 913 ms | 6,734 ms |
| L6 chicken | 32×32 | 2,968 ms (not safe) | 7,500 ms |
| L7 pigeon | 32×32 | 902 ms | 7,452 ms |
| L8 butterfly | 32×32 | 900 ms | 5,771 ms |
| L9 frog | 32×32 | 1,874 ms | 8,580 ms |
| L10 ice_cube | 32×32 | 797 ms | 8,040 ms |

**Before R05, these were real gameplay-thread freezes** whenever a player opened Random / Selector before tapping anything. While robots move, the R04 shortcut keeps every proof at about 3–150 ms.

**250 ms is not realistic:** a single 59×59 Selector proof needs up to 361 ms. **400 ms is set** (`PROOF_BUDGET_MS`), the smallest limit that lets a still-moment Selector execute on the player's chosen batch pass.
- No responsive limit covers Random at still moments: it needs up to 4.6 s on 32×32 and up to 24.5 s on 59×59.

### Retraction of earlier R05-draft numbers
Earlier readings of "16 s / 20 s / more than 20 min completion freeze" are invalid.
- The probe host had no anchors, so the slot origins landed inside the board; play ran at about 440 ms per frame.
- With `PRESET_FULL_RECT` inside a 1080×2160 SubViewport, the numbers are those above.

## 2. Change
- **Solver** (`solvability_solver.gd`): optional `config.deadline_usec`, checked:
  - per node;
  - before each placement;
  - on the root quiesce.

  On expiry it returns `UNKNOWN_BOUND` / `time_budget_exhausted`. With no deadline (every other caller: completion / LOSE, generation, level factory, tools) the behaviour is unchanged.
- **Kernel** (`proof_kernel.gd`): `deadline_usec` is checked per clearing wave. `quiesce` and `apply_placement` return `time_budget_exhausted`. The solver and classifier reset the deadline to 0 after each search.
- **Classifier** (`deadlock_classifier.gd`): passes the deadline to its quiesce. A timeout is never PROGRESSABLE, STALLED or COMPLETED.
- **Adapter** (`production_booster_adapter.gd`):
  - A per-instance `budget_ms` (default `PROOF_BUDGET_MS` 400; 0 = unbudgeted).
  - Each player-facing question starts a fresh deadline, never nested, so an aborted call cannot leave a stale one.
  - Random returns `{"safe": false, "reason": "proof_timeout"}`.
  - The Selector list and `has_eligible_safe_batch` stop at the deadline and set `last_proof_timed_out()`. The next call resumes **after** the batch that ran out, so a slow batch can never pin every retry.
  - Unproven batches are left out (fail closed).
- **Need-a-Hand next-start prover** (`production_gameplay_host.gd`): `budget_ms = 0`. It keeps its pre-R05 deterministic, machine-speed-independent pick. Its Fail-screen freeze cost is an owner item (§6).
- **Service / host:** `booster_service.apply_random` and `apply_selector` and `booster_legality` surface `proof_timeout`, plus `partial` on a cut Selector list. **The charge / SB reservation happens only after a successful proof**, so a timeout spends nothing.
- **Popup** (`acquisition_flow.gd`, `ui_text.gd`):
  - On `proof_timeout` the safety line reads `BOOSTER_SAFETY_BUSY` ("The safety check ran out of time. Try again; nothing is spent.").
  - Random's Use / SB stay tappable, so the player can retry directly. Execute re-proves, and a failed execute spends nothing.
  - Selector chips show the proven (possibly partial) list; reopening continues the rotation.

## 3. Evidence — `tests/m46_performance.gd` p21 `p21_proof_budget` (59×59 stripes + pocket)

### Forced timeout (adapter budget 1 ms, deterministic on any machine), still moment
- Random and Selector both return `proof_timeout`, on the **SB buy-and-use path** (0 charges, SB ≥ price) and on the **owned-charge path**. Economy (wallet + boosters) and supply are unchanged on both.
- Selector list called three times, then has-any: offsets go **0 → 1 → 2 → 3 → 4** over 71 / 70 batches. Each retry moves past the batch that ran out.

### Real 400 ms budget
| Case | Random | Selector |
| --- | --- | --- |
| Moving robots, 6 samples per fixture (≥ 3 free slots) | 12/12 legal | 12/12 legal |
| Still (0 in flight) legality | 2/2 `proof_timeout`, nothing spent | stripes: `proof_timeout` (partial, empty); pocket: legal partial list; offset resumes |
| Still execute on the first supply batch | — | pocket OK (charged once, 365–373 ms); stripes `proof_timeout` at 412–414 ms, nothing spent |
| Retry after one tap (robots moving) | OK, charge used once, SB still 0 (2/2) | — |

- **Time bound:** every budgeted call took at most 420 ms (assert ≤ budget + 200 ms). Before R05 the same calls froze for 4–25 s.
- **Machine load note:** this run's still-moment completion tick worst was 2.96–3.31 s, against 1.06–1.16 s in an earlier R05 run. Another agent's headless Godot process was running throughout. The stripes Selector execute passed in the earlier run (129–200 ms) and timed out in this one. Desktop timings vary with load; a phone will be slower.

### Refusal rates

| Case | Before R05 | With the 400 ms budget |
| --- | --- | --- |
| Moving robots (all boosters) | 0% refused | 0% refused |
| Still moment, 59×59 | 4–25 s freezes | Random 100% `proof_timeout`; Selector list partial; Selector execute 1 of 2 fixtures OK |
| Still level start, production L1–L10 | Random ok on 8/10 | Random ok on L1, L3, L4 only (the 5 others that would prove safe are refused); Selector list partial on every level |
| m55 booster spam (level 2, after +1 Slot / Selector) | 30/30 Random committed | 0/30 committed (all `proof_timeout`, SB spent only on committed boosters) |

## 4. Regressions (local Godot 4.7.2 headless, final code, run alone)
**PASS:**

| Suite | Result |
| --- | --- |
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
| m55_core_chaos | PASS |
| m43_c003_c001_acquisition | 34/34 |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c005f_phase3_meta_rewards_acquisition | 15/15; its SCRIPT ERROR lines are the suite's announced spy-plugin fault |
| m30_completion_authority | PASS |
| m27_hazard_bot_solve | PASS |
| m46 `rs budget` (p20 + p21) | PASS; the ledger lists only the run groups |

**Earlier in R05 (solver-path change unchanged since), all PASS:**
- m27_scale_59, m27_generation_retry, void_cells_c001;
- m52_owner_supply_plans (688 s), maint_supply_columns_c001;
- m53_first10_difficulty, m53_c002_difficulty_calibration;
- m28_c002_c001_gameplay_v02, m52_r01_parallel_runtime, run_tests.

**Test oracles updated** (each keeps its no-spend check):
- `m39_v04_integration`: Random refusal may be `proof_timeout`; new assert that no charge / SB is spent.
- `m55_core_chaos`: a refused Random may be `proof_timeout`; the SB == committed-prices assert is unchanged.
- `m28_c002_c003_final_gate`: chips are compared with the legality the popup itself showed. Their keys must be within the full **unbudgeted** solver-safe proof.

## 5. Separate finding (not changed — win/lose is owner-locked)
At a still moment on 59×59, the completion LOSE proof takes **about 1.1–3.3 s per tick**, depending on machine load. It runs unbudgeted on the gameplay thread. Bounding it would change the owner-locked lose semantics, so it is reported only.

## 6. Owner decisions
**Owner decision (chat, 2026-10-16) on item 1:** "Keep 400 ms for now, and plan a time-sliced off-frame booster proof with a checking state as the next M46 step." Plan: `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_M46_R06_OFFFRAME_PROOF_PLAN_V01.md`. Items 2 and 3 stay open.

1. **Budget value / approach.** 400 ms meets the owner rules: bounded, no spend, retry possible after a tap or reopen. But Random at a still moment is refused on most production levels, and a phone will refuse more. Choices:
   - keep 400 ms;
   - raise it, for example to 1,000 ms (covers Random on 7 of the 8 safe L1–L10 starts on desktop; still a visible pause);
   - move proofs off the frame: time-sliced across frames with a "checking…" state. This removes freezes without refusals, but is a UX change.
2. **Need-a-Hand next-start proofs** are left unbudgeted (deterministic). They are the same proofs, so the Fail screen can pause for seconds on large boards; m43_c004 passes with the third-failure terminal under 1,500 ms on L1–L10 headless.
3. **Completion LOSE-proof freeze** (§5).

## 7. Corrections to R03 / R04 logs
The "owner's Godot editor" CPU-contention attribution was not verified by command line and may have been an orphaned test process. Both logs and the `TASKS.md` R03 line now say so. Processes are now identified by command line only. Another agent's headless `tests/m17_difficulty_validation_probe.gd` runs on this machine; it was not touched.

## 8. Review
A distinct fresh-context **`CLAUDE_PEER_REVIEW`** (not ChatGPT, read-only source review) found **0 BLOCKER**. It confirmed:
- fail-closed;
- no spend before a successful proof;
- no stale kernel deadline reaching completion, LOSE, generation or replay proofs.

**Fixed after the review:**
- MAJOR-1: one slow batch pinned the Selector list → resume after it.
- MAJOR-3: has-any had no rotation → shares the offset.
- MAJOR-2: Need-a-Hand had silently become budgeted → explicitly unbudgeted, owner item.
- MAJOR-4: p21 could pass with no timeout → forced 1 ms cases.
- MINOR-5: SB path was untested → covered.
- MINOR-6: weak resume check → exact offset sequence.
- MINOR-7: a leaked deadline could block forever → fresh deadline per question.
- MINOR-8: no retry message → BUSY text plus a tappable Random.
- NIT-11: re-entrancy removed.

**Still open:** MINOR-9 (owner decision, §6.1); NIT-12 (pre-existing unused `_is_safe`).

## Footprint
- Temporary diagnostics (`tests/_m46_diag_tmp.gd`, diagnostic lines in `m39_v04_integration.gd`, a one-run `budget_ms := 0` baseline edit) were removed and verified by grep.
- The diagnostic `user://m46diag_*.save` and `user://m46_*.json` files were deleted: 0 remain.
- Background output files were deleted by exact path.
- No owner file was touched.
