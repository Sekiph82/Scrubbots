# M46 R06 — Off-frame booster safety proof with a "Checking..." state — CLAUDE LOG R06 V01

**Base and scope:**
- Base: `origin/main` `900e1d73` (R06 plan).
- Owner decisions in chat, 2026-10-16:
  - "Keep 400 ms for now, and plan a time-sliced off-frame booster proof with a checking state as the next M46 step";
  - then "Start R06 with the proposed defaults":
    - O1: text only;
    - O2: 5 s total cap;
    - O3: HUD Random hold.
- Godot 4.7.2 headless, local desktop only. **No GitHub Actions** (CLOUD_CI_DEFERRED_COST_FREEZE), no phone and no GPU.

**Result: LOCAL_PASS.** Owner visual F5 sign-off of the "Checking..." popup and the HUD hold is still open.

## 1. Step 1 measurement changed the design
p22 `_granularity` mirrors the solver's DFS on the main thread and measures the largest atomic units.

| Where | `apply_placement` (one dispatch-to-quiescence cascade) | one DFS node | root quiesce | ProofState build |
| --- | --- | --- | --- | --- |
| 59×59 still (stripes / pocket) | p99 160 / 452 ms | 0.7 / 1.5–1.7 s | 10–12 ms | 2–3 ms |
| L1–L10 start | 87–246 ms | 0.17–0.67 s | 1–8 ms | 0.3–1.9 ms |

A 4 ms per-frame cooperative slice (plan V01 §3.1) would need the kernel cascade split mid-wave, which means deep proof-internals changes with correctness risk.

**Implemented instead (plan §0 amendment):** the *unchanged* proof code runs on a **WorkerThreadPool task** over `ProductionBoosterAdapter.detached_copy()`. The copy holds a frozen board snapshot, copied supply and slots, and no scheduler. The owner gates O1–O3 are unchanged.

## 2. Change
- **`production_booster_adapter.gd`:**
  - `FrozenBoard` (cell states + revision captured on the main thread);
  - `detached_copy()` (budget `PROOF_TOTAL_MS` = 5,000) and `run_offframe()` (the worker entry);
  - `cancel_proof()`;
  - `state_key()`: board instance + monotonic revision, full supply snapshot, slot snapshots, compared as an **Array with `==`** (no hash collisions);
  - a verdict cache (`put_verdict` / `cached_verdict`, still moments only). Random is true / false / "timeout"; Selector is `{ids, partial}`;
  - Random / Selector list / single batch / has-any answer from the cache without a proof;
  - `live_proof_count` diagnostic.
- **Kernel / solver / classifier:** a sticky `cancelled` flag, read like an expired deadline (`_out_of_time()`), plus `cancel()`. Behaviour without a cancel is unchanged.
- **`production_target_access.gd`:** the static single-slot mask cache is read and published under a `Mutex`, because the worker uses it too. The flood itself runs unlocked, and the main-thread `mask_build_count` semantics are unchanged (m25_c003 PASS). **`runtime_perf_probe.gd`:** `add()` records on the main thread only.
- **`production_gameplay_host.gd`:**
  - `booster_legality_offframe` / `needs_offframe_proof` start one worker job and return reason `checking`;
  - `_process` polls; the verdict is stored only if the state key is unchanged. A worker that ends without a result counts as the cap running out (fail closed, no restart loop);
  - `booster_proof_settled(id)` signal;
  - `cancel_booster_proof` on modal close (gameplay resumes), retry and exit; an internal `_stop_proof` without the signal is used inside `_start_proof`, so no re-entrant second task;
  - HUD owned Random at a still moment opens the popup with auto-use (O3; the popup pauses play like any modal).
- **Popup (`acquisition_flow.gd`, `ui_text.gd`):**
  - "Checking..." with Use / SB blocked until proven;
  - refresh on the settle signal;
  - auto-use of the owned charge once proven;
  - `proof_timeout` = the 5 s proof ran out on this exact state. That is cached, so a re-tap answers at once with no freeze. Use / SB stay blocked, and the text says "Nothing is spent; try again after your next move."
- **Unchanged:**
  - the R05 400 ms synchronous budget remains for any proof without a cached verdict (e.g. FTUE copy, rewarded-grant completion; §6);
  - moving-robot proofs keep the R04 shortcut (about 3 ms);
  - Need-a-Hand stays unbudgeted and deterministic.

## 3. Evidence — `tests/m46_performance.gd` p22 `p22_offframe_proof`

### Equivalence (detached copy vs live adapter, both unbudgeted)
Random and Selector-list verdicts are identical on L1–L4 starts, and on an L1 mid-play still moment with 4 occupied slots.

### L1 HUD Random (deterministic, still start)
- Checking hold, then the owned charge is used **exactly once**, SB unchanged.
- **0 main-thread proofs** during settle and use (`live_proof_count`).

### 59×59 still (stripes + pocket)
- **Selector popup:**
  - opens in "Checking..." with Use / SB blocked;
  - R06 main-thread start cost 0.9–1.4 ms (state key 0.1–0.2 ms);
  - worst frame **0.6–1.4 ms** while the worker proves (budget 16.7 ms);
  - settles at the 5 s cap with a legal partial list of 21–48 chips;
  - nothing spent.
- **Cancel:** closing mid-check stops the worker in **2.2–2.6 ms**; nothing spent, no verdict stored.
- **Stale:** state changed mid-check → the verdict is dropped.
- **HUD owned Random:**
  - hold with play paused;
  - settled after 1.05–1.32 s with worst frame 0.6–0.7 ms;
  - **used** once;
  - 0 main-thread proofs.
  - The settle + auto-use frame is 18–22 ms standalone, 44–46 ms under load (the Random commit + UI refresh, a one-off player action; report-only, like the p17 Tornado execute).
- **Popup UI build:** 44–63 ms. This is pre-existing and report-only; it is not the proof (before R06 the same open also ran the up-to-400 ms proof).

## 4. Regressions (local, final code, run alone, sequential)
**PASS:**

| Suite | Result |
| --- | --- |
| m25_c003_exact_prefilter | PASS |
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
| m27_scale_59 | PASS |
| m52_r01_parallel_runtime | PASS |
| run_tests | ALL PASS |
| m46 `rs budget slice` (p20 + p21 + p22) | PASS; only the subset-ledger line fails, by design for a partial group run |

**m46 load note:** in this batch run the HUD settle + auto-use frame was 44–46 ms and the hold settled after 2.2–2.5 s, against 18–22 ms / 1.05–1.32 s in a standalone run. Other projects' headless Godot processes were running at the same time.

**Test oracles updated for the new behaviour:**
- `m28_c002_c003_final_gate`: wait for the off-frame proof before counting chips. It now shows 12 Selector chips; R05's synchronous 400 ms showed 3.
- `m28_c002_c001_gameplay_v02`: the owned Random HUD tap at a still moment is a "Checking..." hold. The test waits for it, then checks used-once vs refused-and-popup-open, with SB untouched. Before this fix the open hold blocked the next case's speed popup.
- **m28_c002_c001_gameplay_v02 rerun:** PASS 14/14. The HUD Random was held, then refused: nothing spent, SB untouched.

"N resources still in use at exit" lines are economy scripts held by the tests' own economy objects. They appear in m39 too and are not R06 objects.

## 5. Review
A distinct fresh-context **`CLAUDE_PEER_REVIEW`** (not ChatGPT; read-only source review) gave **CONDITIONAL**. It confirmed:
- **thread safety:** the worker reaches only the detached copy's objects plus the two gated statics;
- **exactness;**
- **economy:** nothing spent on checking / timeout / cancel / stale;
- **lifecycle.**

**Fixed after the review:**
- MAJOR-1: timeouts now cached (Random "timeout", Selector partial proven set), so there is no 400 ms re-proof on the same state and no misleading retry.
- MAJOR-3: deterministic L1 HUD auto-use case + `live_proof_count` asserts on every HUD case.
- MINOR-1: Array keys, no hash.
- MINOR-2: Mutex-shared masks instead of a per-lane flood on the worker.
- MINOR-3: a null worker result counts as a timeout.
- MINOR-4: cancel emits settled (re-entrancy-safe split).
- MINOR-5: mid-play equivalence, stronger stale and cancel checks.
- NIT-3: text.

**Separate (done as its own cycle):** MAJOR-2, a pre-existing M39 defect in `_scratch_slots_from_live` (remaining / WAITING / sequence), now cached by R06. See `CLAUDE_LOG_SLOT_REBUILD_V01.md`.

## 6. Open
- **Owner F5 visual sign-off:** the "Checking..." line (text-only, O1) and the HUD hold popup.
- **Remaining synchronous still-moment legality calls,** each up to 400 ms (R05 cap):
  - the rewarded-grant completion check (`acquisition_flow` `booster_model` after a rewarded ad);
  - FTUE `step_copy` → `booster_legality`.

  Both are accepted as bounded for now, and can be routed through the cache later.
- **At 59×59 still moments the Selector list hits the 5 s cap** (partial list, still legal), because one full list needs about 25–30 s.
- **Phone / GPU, ChatGPT audit, cloud CI:** open.

## Footprint
- No temporary files.
- `user://m46_*` fixtures and `user://m46_slice_l*.save` are deleted by the suite.
- Background output files were deleted by exact path.
- No owner file was touched.
