# M46 R06 — Time-sliced off-frame booster safety proof with a "Checking…" state — CLAUDE PLAN V01

**Status:** PLAN ONLY. Not implemented. Claude-authored under autonomous mode §0B; this is not a ChatGPT prompt.

**Owner decision (chat, 2026-10-16):** "Keep 400 ms for now, and plan a time-sliced off-frame booster proof with a checking state as the next M46 step."

**Base:** `origin/main` `f96e7cd3` (R05: 400 ms synchronous budget, fail closed, nothing spent). R05 stays the shipped behaviour until R06 is implemented, reviewed and owner-accepted.

## 0. AMENDMENT (implementation, 2026-10-16): worker thread instead of cooperative slicing
Owner chose the defaults (chat: "Start R06 with the proposed defaults"):
- O1: text "Checking…";
- O2: 5 s total cap;
- O3: HUD hold.

**Step 1 measured the slice granularity** (p22, desktop):

| Where | One atomic `apply_placement` (a dispatch-to-quiescence cascade) | One DFS node |
| --- | --- | --- |
| 59×59 still | 160–456 ms | 0.7–1.7 s |
| L1–L10 | 87–246 ms | 0.2–0.7 s |

A 4 ms per-frame slice would need the kernel cascade split mid-wave. That is a deep change to proof internals, with correctness risk.

**Design changed** (same behaviour and owner gates, simpler and exact). The existing proof code runs unchanged on a **WorkerThreadPool task** over `ProductionBoosterAdapter.detached_copy()`:
- a frozen board snapshot;
- copied supply and slots;
- no scheduler.

The §2 fact 3 race is removed at its source: `ProductionTargetAccess` uses its static mask cache only on the main thread, and a worker builds private masks with the same values. `RuntimePerfProbe` records the main thread only.

The verdict is cached on the live adapter for exactly the proven state (`state_key`), so legality and execute answer without re-proving. Cancel uses a sticky kernel flag. §3.1's resumable solver object is therefore not needed.

## 1. Problem (measured in R05, desktop CPU)
At a still moment (0 robots in flight), the booster safety proof is long.

| Where | Random | Selector full list |
| --- | --- | --- |
| Production L1–L10 start | 0.13–4.6 s | 0.9–12 s |
| 59×59 | 3.8–24.5 s | about 25–30 s |

R05 caps every call at about 400 ms on the gameplay thread. That trades the freezes for refusals: Random is refused at still moments on most levels, and the Selector list is partial. R06 removes both the freeze and most refusals. The proof runs in small per-frame slices while the UI stays responsive and shows "Checking…".

## 2. Facts the design relies on (verified in source at `f96e7cd3`)
1. **The search is already iterative.** `SolvabilitySolver._search_bounded` uses an explicit DFS stack plus a `visited` dictionary, so it can be suspended between nodes without recursion unwinding.
2. **Proof objects are plain `RefCounted`, detached from the live engines:**
   - `ProofState`, `ProofKernel`, `DeadlockClassifier`;
   - `ProofState.from_runtime` deep-copies board, supply and slots.
3. **A background thread is NOT chosen for V1.** `ProductionTargetAccess` (used by the kernel) keeps a `static` single-slot reachability mask cache, which the live dispatch on the main thread also writes. A worker thread would race on it. Cooperative slicing keeps one thread, the same code and determinism.
4. **Popups already pause gameplay.** The modal hold sets the runtime user pause (`_paused_by_modal`), so while the Booster popup is open the proven state cannot change.
5. **Owned Random has no popup.** `request_booster` → `_actions.random()` runs from the HUD tap with gameplay running, so it needs its own short hold (§4.3).
6. **Slice granularity is not yet measured.** One `apply_placement` runs a dispatch-to-quiescence cascade, and its single-call cost at 59×59 is unknown. The kernel loop `_run_to_quiescence` is per wave (R05 added the deadline check there).

## 3. Design

### 3.1 `BoosterProofJob` (new, `scripts/economy/booster_proof_job.gd`, RefCounted)
- **One job = one player-facing question:**
  - Random 3-step proof;
  - Selector list (all batches);
  - Selector single batch.
- **API:**
  - `start(adapter, kind, args)`;
  - `step(slice_usec) -> {"done": bool, ...}`;
  - `result()`;
  - `cancel()`;
  - `state_key()`.
- **Inside:** a sequence of resumable classifier searches. Random = baseline plus 3 placements. Selector = one search per batch.
- **The solver gains a resumable form:** `begin_progress_search(root, config)` returns a search object holding stack, visited, counters and root_active. `advance(deadline_usec)` returns `PENDING` at the slice deadline instead of `UNKNOWN_BOUND`.
- **The synchronous `search_progress` stays.** It is the same object run to completion, so every existing caller is bit-identical.
- **The kernel cascade is atomic per `apply_placement` in V1.** If step 0 shows a single call is over about 8 ms at 59×59, V2 makes `_run_to_quiescence` resumable per wave.
- **Stale-proof guard:** `state_key()` = board revision + supply `debug_snapshot` + slots snapshot hash at `start`. A result is only usable while the live key is unchanged; otherwise it is discarded and re-proved.
- **Determinism:** the same visit order as the synchronous search. A job that completes gives exactly the synchronous verdict. A test asserts equality on fixtures.

### 3.2 Host driver
- `ProductionGameplayHost` owns at most one active job and steps it from `_process` with a per-frame slice. The default `PROOF_SLICE_MS = 4`, tuned in step 0 against the M46 frame budgets.
- The job stops when the state key changes, the popup closes, the level ends or exits, or the total cap is reached.
- **Total cap** `PROOF_TOTAL_MS`: proposed default 5,000 ms (owner gate O2). Hitting it is `proof_timeout`, as in R05, so nothing is spent and retry stays possible.
- Results are cached per (kind, args, state_key). Execute uses the cached proven verdict, so a booster is never proved twice for one decision. With no valid cached proof it falls back to the R05 synchronous 400 ms path.

### 3.3 Economy contract (unchanged from R05)
- The charge / SB reservation happens only after a successful proof that matches the current state key.
- `proof_timeout`, a cancel, or a stale result spends nothing.
- `booster_service` keeps the reserve → commit → refund order.

## 4. UX (owner gates marked O#)

### 4.1 Booster popup (Random / Selector, charge or SB)
- It opens immediately.
- **Random:** the safety line shows "Checking…" (new `BOOSTER_CHECKING`); Use / SB are disabled until the job finishes, then legal or the R05 retry line.
- **Selector:** chips appear progressively as each batch is proven, in supply order with the rotation from R05, and the list keeps growing while the popup is open.
- Close (X / back) cancels the job.

### 4.2 Proof visual
- Text only ("Checking…"), or an animated dots / spinner Control (O1).
- No new art in V1; use native Controls (UI rules §16).

### 4.3 Owned Random from the HUD
**Proposed (O3):** the tap starts a short modal "Checking…" hold, which pauses gameplay like a popup. It then commits, or shows the refusal line, and resumes. The alternative (no pause, discard the result if the state changes) can refuse often while robots move, but the R04 shortcut answers in about 3 ms whenever robots are in flight, so the hold only appears at still moments.

### 4.4 Out of scope for R06 (separate owner items)
- **Need-a-Hand next-start proofs** (unbudgeted, deterministic) could later reuse the job behind "Checking…" cards.
- **Completion LOSE-proof freeze** (1.1–3.3 s per tick at still 59×59) is owner-locked semantics and reported only. The same job could later carry it with no change to win / lose meaning.

## 5. Steps
1. **Measure granularity.** Get single `apply_placement` and `quiesce` worst cases at 59×59 and L1–L10. Pick the slice size, and decide whether the per-wave resumable kernel is needed. Write a local test only.
2. **Resumable solver search object.** Keep the synchronous API as a wrapper.
   - Equivalence test: resumable with tiny slices gives the same status, visited count and trace as synchronous, on the m27 / m52 fixtures and the p16 / p21 59×59 fixtures.
3. **`BoosterProofJob`:** Random, Selector-list and Selector-single kinds, the state-key guard, and the result cache in the adapter.
4. **Host driver:** slicing, the total cap, and cancel on close / exit / terminal / state change.
5. **UI:** popup "Checking…", progressive Selector chips, the owned-Random hold (per O3), and `ui_text` keys.
6. **Tests (local Godot 4.7.2 only, no Actions):**
   - new p22 at 59×59 with still and moving robots:
     - no frame over the M46 frame budget while checking;
     - the Random verdict equals the synchronous unbudgeted verdict;
     - the Selector list completes to the full unbudgeted set;
     - close mid-check cancels with nothing spent;
     - a state change mid-check discards the result;
     - total-cap `proof_timeout` with nothing spent, on the SB and charge paths;
   - the L1–L10 still-start refusal table re-measured. Expected: Random refused only where truly unsafe or over the cap;
   - regressions: m39*, m43_c003 / c004 / c005f, m28_c002_c003, m55, m30, m27, m52, run_tests, m46 rs / budget.
7. **Review:** a fresh-context `CLAUDE_PEER_REVIEW`, the R06 log, a `TASKS.md` update, commit and push.

## 6. Owner gates
- **O1:** "Checking…" text only, or with a small spinner.
- **O2:** total cap per check. Proposed 5 s. A longer cap still means no freeze, but a longer wait.
- **O3:** owned Random from the HUD — a short pause hold (proposed), or a no-pause attempt.
- **Owner visual sign-off** of the popup / hold after implementation (F5).

Phone / GPU, a ChatGPT audit and cloud CI stay open, as for all M46 work.
