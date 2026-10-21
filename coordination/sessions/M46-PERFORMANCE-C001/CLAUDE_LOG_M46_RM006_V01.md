# CLAUDE_LOG_M46_RM006_V01 — Booster proof diagnostic integrity, Selector availability, +1 receipt

**Child 2 of `CHATGPT_M46_MASTER_REMEDIATION_V03.md`** (prompt `CHATGPT_M46_RM006_PROOF_DIAGNOSTIC_SELECTOR_FAIRNESS_PROMPT_V01.md`, criteria `..._AUDIT_CRITERIA_V01.md`, frozen V3-F03 / F04 / F05, sibling V3-F06).
Implementer evidence only (E1/E2). Root `TASKS.md` and every `CHATGPT_*` file untouched. Environment caveats exactly as in `CLAUDE_LOG_M46_RM005_V01.md` §0 (Linux cloud container, headless Godot 4.7.2 `ed1daf0bf`, owner Windows checkout not reachable → **OWNER_LOCAL_PROJECT_PARITY_OPEN**, zero Actions, harness branch `claude/practical-darwin-ndbmxa`).
**Final source for both children: `b36d48fa37e73e37350bd9b0bd817901b24fcc2e`** (RM005 `ce67212c` + this child).

## 1. Source trace before edits (RM006-01)
- Producers: `ProductionBoosterAdapter.eligible_safe_batches` / `is_batch_eligible` / `has_eligible_safe_batch` / `propose_random_reorder` → `_selector_reorder_solvable` / `_prove_three_consecutive_safe` → `_is_safe_probe` → `DeadlockClassifier.classify` (full root cascade) ; `detached_copy()` → `run_offframe` on a `WorkerThreadPool` task → host `_process` settles into `put_verdict(kind, state_key, value)`; `cached_verdict` answers legality / execute / FTUE hint for exactly that state.
- Consumers (all read the same cached verdict or the same adapter; none changed except as listed in §2): host `booster_legality` / `booster_legality_offframe` / `needs_offframe_proof` / `execute_booster` / `request_booster`; `AcquisitionFlow` popup chips (cap `MAX_TARGET_CHIPS` 12, supply order) and pressed id → `execute_booster(SELECTOR, id)` → `BoosterService.apply_selector` → `is_batch_eligible` (cache first); M44 / RM003 FTUE coach hint `has_eligible_safe_batch`; R05 sync list rotation (`_list_offset`); Random HUD hold (R06); Need-a-Hand next-start prover (its own unbudgeted adapter); 5 / 6 capacity and WAITING are part of `state_key()` (slot snapshot) and of `_scratch_slots_from_live`.
- **Root of V3-F03:** one Selector batch proof at a 59x59 still moment cost 249–361 ms (adapter comment, R05) because `classify` ran the extracted batch's whole 30-clear root cascade only to learn "PROGRESSABLE"; the 5 s worker therefore covered ~29 of 118 batches, and `detached_copy()` always started at offset 0.
- **Root of V3-F04:** an erroring GDScript function returns a default value and its caller continues, so a script error deep in the worker proof became `{value: false/[], timed_out: false}` → labelled `completed`.
- **Root of V3-F05:** `activate_plus_one_slot()` returns only `bool`; the facade built `{"ok": false}` with no reason.

## 2. Changes
**S1 — algorithmic (preferred by the prompt) + fair cursor**
1. `DeadlockClassifier.classify(config.verdict_only)` → `ProofKernel.quiesce(state, stop_on_clear)`: the root cascade stops at its first clearing wave (any clear ⇒ PROGRESSABLE). Same `status` / `reason` for every state; `immediate_clears` / `root_active` then describe that first wave. Used **only** by the booster adapter (`_is_safe`, `_is_safe_probe`, which read nothing but `status`); completion (RM005) keeps the full root cascade.
2. Result: one 59x59 Selector batch proof **17–33 ms** (was 249–361 ms); the whole **118-batch list in 2.3–2.7 s inside the unchanged 5 s cap** (stripes and VOID-pocket, start and two evolved still states, all `completed`, none partial). The cap, the 400 ms sync budget, the cached same-state verdict and the 12-chip UI are unchanged.
3. Fair cursor for whatever still gets cut (bigger states / slow devices): `detached_copy()` copies the live `_list_offset`; when a Selector list settles **for the current state** the host writes the worker's resulting offset back. The cut state itself is never re-proved (its verdict is cached); the NEXT genuine state's worker resumes after the last cut. Full lists reset the cursor to 0 (existing rule). Every listed chip is still a batch proven on its own current state.

**S2 — typed worker outcomes** (`run_offframe` writes `{value, timed_out, error, offset}`)
- `error` = first source-detected failure: `preflight_failed` (detached copy not buildable), `malformed_proof_state` (`ProofState.from_runtime` null mid-proof), `malformed_proof_result` (classifier result without a known StringName status — `_checked_status`), `script_error` (**any script / engine error logged on this worker thread during the proof**, via an engine `Logger` registered once with `OS.add_logger`, counting errors per watched worker thread id, warnings ignored).
- Host `last_proof_diagnostic.outcome`: `completed` | `deadline_timeout` | `worker_error` (no result written) | **`worker_internal_error`** (+ `error` code) | `cancelled`; `stale` unchanged. Every non-completed outcome is cached for that state as the existing fail-closed timeout (`proof_timeout` to the player, nothing spent, no restart on the same state); a result with an error never authorizes a chip (its ids are dropped).
- **NOT_VERIFIED_ENGINE_LIMITATION (narrow):** detection of arbitrary interpreter errors relies on the engine reporting them to `Logger`. Verified here in the editor/debug binary (Godot 4.7.2 headless). In **release export templates** many GDScript runtime checks are compiled out, so a deep error may go unreported and the defaulted value is what the proof sees; the preflight / state / verdict-shape checks still apply there, and every such path observed fails closed (defaults are `false` / `[]` / `{}` → not safe). Not verified on a release template or phone.

**S3 — +1 refusal reason**: host `last_plus_one_refusal` (`plus_one_used` for "already six slots / used this attempt" incl. the service's `already_max_or_used`; `economy_unavailable`; a BoosterService reservation reason; `activation_failed`); the facade puts it in the refusal dict, so `last_booster_request.reason` / `action_refused` carry it. Price, debit, refund, capacity and the seventh-slot clamp untouched. **No owner-visible text change:** the popup maps unknown reasons to the existing `ACQ_REASON_FAILED` / `BOOSTER_NOT_USED` copy exactly as it did for the blank reason, and the +1 popup's SB button is already disabled at six slots (unchanged).

**Test seams (disclosed, inert in production):** new stages of the pre-existing `set_fault_injector` seam (`preflight`, `proof_probe`, `offframe_result`; `_fault` is `Callable()` in production and is now copied into detached copies), and RM005's `SolvabilitySolver.full_progress_cascade` oracle switch (default false).

## 3. Test `tests/m46_rm006_selector_proof_integrity.gd` (5 groups) — PASS, exit 0, 21 s on the final source
- **S1a** (RM006-02): 59x59 stripes, 118 batches, real 5 s cap, Selector popup in USE mode: worker 2430 ms `completed`, **118/118 proven**, not partial; chips == first 12 proven ids in supply order; every chip and the **deepest batch `R4B0114`** re-proven by an independent unbudgeted adapter; unknown id refused with nothing spent; the deepest batch used: charge 1 → 0 once, SB unchanged, rest of the supply order untouched.
- **S1b** (RM006-03): forced 600 ms cap, four states linked by genuine player taps. RM006: lists start at positions **0 → 25 → 51 → 82** (deepest 23 → 49 → 80 → 111, 106 distinct batches proven); built-in control with the old reset-to-0 cursor: **0 → 0 → 0 → 0** (31 distinct). Every partial list non-empty, smaller than the supply, every chip re-proven; repeating the same state answers from the cache — **no second worker**, no settle, identical targets.
- **S2** (RM006-04): completed safe (L1 Random), completed refusal (core fixture, Random `not_solver_safe`, nothing spent), Selector proven-only (13 ring batches listed == exactly the safe ones, every enclosed core batch excluded), deadline (`deadline_timeout`), no result (`worker_error`), preflight / one injected real script error on the worker thread / invalid state mid-proof / malformed verdicts (`worker_internal_error` with `preflight_failed` / `script_error` / `malformed_proof_state` / `malformed_proof_result`), cancelled, stale. Each failure: external `proof_timeout`, ledger unchanged, no restart on the same state.
- **S3** (RM006-05): 0 SB → `insufficient_sb`; first +1 one debit, 5 → 6; second via SB, via owned charge and via the HUD request → `plus_one_used`, ledger (SB, charges, slots, supply, board) unchanged; popup SB button disabled (no execution, unchanged UI); no seventh slot.
- **S4** (RM006-06): a second request joins the running worker (same task); Retry mid-proof cancels it, no verdict kept; a 6-slot state never reuses a 5-slot verdict; host freed mid-proof (worker cancelled + joined, no crash).

### Sensitivity (RM006-07) — temporary edits, full suite, restored byte-identical (`cmp`)
| Mutant | Edit | Result |
|---|---|---|
| M1 unproven chip | list every batch (`if proven.has(bid)` → `if true`) | caught: S1b partial-size / fairness, S2 proven-only |
| M2 same-state rerun | `needs_offframe_proof` ignores the cache | caught: S1a, S1b no-rerun, S2 failure rows |
| M3 fair-cursor reset | `detached_copy` sets `_list_offset = 0` | caught: S1b fair cursor (starts 0,0,0,0) |
| M4 missing result as completed | host maps `res == null` → `completed` | caught: S2 no-result |
| M5 error swallowed | host ignores `error` | caught: S2 preflight + script error |
| M6 blank +1 reason | facade drops the reason | caught: S3 three rows |
| M7 second +1 debit | host guard + service guard + refund removed | caught: S3 three rows (ledger) |
| M7a host guard only | host `can_grow_to_sixth` guard removed | **not caught — masked by defense in depth**: BoosterService `can_activate_plus_one` still refuses (mapped to `plus_one_used`), nothing spent. Not a test false-negative (same as RM004 N2) |

## 4. Regressions (final source content, sequential, one Godot at a time) — 45/45 exit 0
m46_rm006, m46_rm005 (5/5), m46_rm004 (6, G4 now forces a 700 ms cap to keep testing partial chips — the full list no longer gets cut at 5 s), m46_rm003 (4), m46_rm002 (8), m46_r07, m46_slot_rebuild, m27_hazard_bot_solve, m27_generation_retry, m27_scale_59, m30_completion_authority, m30_transaction_safe_retry, m30_manual_playtest_smoke, m39a, m39b, m39c, m39e_full_matrix, m39_v02_atomicity / capacity / integration, m39_v03_full_surface / integration, m39_v04_integration / tornado_inflight, m39_c003_random_any_booster_rewards, m28_c002_c001_gameplay_v02, m28_c002_c003_final_gate, m43_c001a / c001b / c001r / c002 popup modal pause / c003 acquisition / c004 fail + Need a Hand, m44_ftue, m55_core_chaos / economy_release_regression / heart_900_authority / c002_timed_2x_anti_rollback / long_session, cp04, cp05, cp05_r01, cp06, m53_first10_difficulty, run_tests. Full `m46_performance.gd` p01–p22: master log.

## 5. Criterion ledger
| Criterion | Status (implementer) | Evidence |
|---|---|---|
| RM006-01 | REPORTED | §1 producer / consumer trace; changed consumers: none beyond §2 |
| RM006-02 | PASS (E2) | S1a 118/118 in 2.4 s, chips proven-only, deepest batch usable once |
| RM006-03 | PASS (E2) | S1b resume 0→25→51→82 vs control 0→0→0→0; no same-state rerun |
| RM006-04 | PASS (E2) for every source-detectable case; **NOT_VERIFIED_ENGINE_LIMITATION** for undetected interpreter errors on release templates | S2 |
| RM006-05 | PASS (E2) | S3 |
| RM006-06 | PASS (E2) | S4, S1b, S2 cancel / stale |
| RM006-07 | PASS (E2) | M1–M7 caught, M7a masked (defense in depth) |
| RM006-08 | see master log | 45/45 above; full 22/22 on `b36d48fa` |
| RM006-09 | gates preserved | no new text / popup / More UX, Need-a-Hand untouched, no Actions / clone / owner file edits, F5 + phone GPU OPEN, TASKS untouched |

No OWNER_PRODUCT_DECISION_REQUIRED was needed for S1: the full list fits the existing 5 s cap at 59x59 here; the resuming cursor covers longer lists without new UX.
Observation (no code change after pinning): the `PROOF_BUDGET_MS` comment in `production_booster_adapter.gd` still quotes the pre-RM006 249–361 ms single-batch figure; it now measures 17–33 ms here. Budget value unchanged.

Status: child complete → master verification (`CLAUDE_LOG_M46_MASTER_V03.md`).
