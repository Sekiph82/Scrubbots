# M25-C002 — 59x59 TARGET-SELECTION INVESTIGATION — FINDINGS V01

Date: 2026-09-29 · Task: `SB-M25-033` · Status: **INVESTIGATION / PROPOSAL ONLY (no production change)**
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Log: `CLAUDE_LOG_V01.md`
Blocking audit: `coordination/sessions/M29-C002/CHATGPT_AUDIT_V01.md` (criterion H)
Tool: `tests/tools/m25_c002_selection_probe.gd` (test-only, non-shipping)
Evidence: `evidence/selection_probe_report.txt` (per-run tables + 5 worst lanes per run), `evidence/selection_probe_report.json` (full per-run summaries, worst-lane attribution, equivalence proofs)

---

## 0. Summary

1. **The M29-C002 multi-second stall is real code behaviour, but it is triggered by the harness geometry, not by the production slot layout.**
   - The M29 59x59 fixture host was built headless with no sized viewport and no relayout, so `SlotOriginProvider` mapped the unlaid slot anchors to board-local `(40,0)`, `(49,0)`, `(58,0)`, `(67,0)`, … Three of the six origins lie inside the 59x59 board, on its top row.
   - `ProductionTargetAccess._could_reach()` deliberately skips the M52 prefilter for inside-board starts ("debug interior planner"). `ProductionRoutingSystem` then uses the interior BFS from an ACTIVE start cell, which fails for every candidate.
   - Each such lane therefore runs one full, failing `compute_route` per candidate: **590 routes, 0 successes, 2.17–2.38 s**.
   - On a real 1080x2160 laid-out host, every origin is at `y ≈ 72.8`, below the board (the owner contract, already asserted by `tests/m29_exact_slot_origin_evidence.gd`). This regime never occurs there.
2. **On real production geometry the existing M52 prefilter already bounds route probing to exactly one `compute_route` per lane.** Across a whole 59x59 level (5177 lanes, all 3481 cells cleared, WON) there were **0 failed route probes**, `compute_route ≤ 1` per lane, and verdicts never disagreed between origins.
3. **Two smaller real costs remain, and neither is caused by the M29 retune.** At historical tempo the per-lane profile is identical; the faster cadence only attempts lanes more often (6 s window at 2x: 144 lanes at historical tempo vs 222 at new tempo).
   - **WHAT-side, O(candidates) scan.** The canonical bottom-most-first order walks the whole colour stripe before reaching a targetable top-row cell: winner rank up to 570 of about 575. The scan costs ~9 µs per prefilter-rejected `is_targetable` call, plus the selector's strict per-candidate loop, giving **≤ 26 ms per lane** early in the level and ~4 ms per lane on average over the level. One third of all lanes (1696 of 5177) are WAITING rescans with no target: every authenticated clear wakes every WAITING slot, and the rescan examines every candidate.
   - **HOW-side, the single winning route.** Late in the level the Railroad Dijkstra for the one winning target explores most of the open area: uninstrumented `route_dijkstra` mean 15.8 ms, max 164.7 ms; `access_compute_route` mean 19.1 ms, max 191.6 ms. This is the dominant real 59x59 frame cost: uninstrumented full level frame p99 70 ms, max 228 ms.
4. **Recommendation, staged:**
   - **(S0)** Make 59x59 performance evidence run on laid-out hosts, and add a production diagnostic or guard for inside-board production origins (owner decision).
   - **(S1)** Option A: an exact-safe per-revision "touchable" byte mask owned by `ProductionTargetAccess`, plus a canonical pre-filter handshake, so the selector's strict loop only visits candidates that can pass the necessary condition. Target order and winner are unchanged.
   - **(S2)** A separate routing (HOW) prompt for exact-equivalent acceleration of the winning-route Dijkstra.
   - Option B (memo/cache) is rejected on the data: hit rate is 0 on real geometry. Option C (continuation) is kept only as a fallback if S2 cannot reach the budget.

---

## 1. Reproduction

Everything runs on a real `ProductionGameplayHost`, the same fixture as M29-C002: a 59x59 TEST board of six ~10-column vertical colour stripes C01..C06, with round-robin 30-robot batches in three FIFO columns. The placement policy is the same as M29 (place whenever a slot is free, rotating columns) and so is `RuntimeController.tick(1/fps)`. Two host geometries were compared:

- **UNLAID** is the M29-C002 harness shape: `add_child(host)` on the headless root, with no SubViewport and no relayout.
- **LAID-OUT** is the M29 Hazard-smoke shape: a 1080x2160 `SubViewport`, two frames, `build()`, two frames, `relayout()`, two frames. After +1 Slot the layout is settled again, then `set_process(false)` and `reset_runtime()`.

**Instrumentation is transparent.**
- A test-only `TargetSelector` subclass (`ProbeSelector`) is bound to the host's board, candidate index and reservations, and swapped into the claim engine.
- It hands the selector the **same** `ProductionTargetAccess`, wrapped in a proxy. For each asked candidate the proxy first reads the real access's own `_could_reach()`, a pure revision-keyed cache read or build that the real call performs anyway. It then forwards to the **real** `is_targetable()`, so the verdict, the memo and `consume_route` are unchanged.
- Proof: the instrumented and uninstrumented laid-out runs produce identical dispatch sequences, `(target, colour)` in order: **219 = 219 in the 6 s window, and 3481 = 3481 over the full level** (`equivalence`, `equivalence_full_level` in the JSON).
- Timing claims below use the **uninstrumented** RuntimePerfProbe numbers wherever they exist. Instrumented numbers carry proxy overhead and are used only for counts and attribution.

Runs (6 s gameplay windows unless noted): UNLAID 59x59 6 slots 2x 60 FPS; LAID-OUT 59x59 6 slots 2x/1x 60 FPS; LAID-OUT historical tempo (0.5 s, 6 cells/s); LAID-OUT 30 FPS; LAID-OUT 5 slots; 32x32 controls (laid-out and unlaid); LAID-OUT **full level to WON** (instrumented and uninstrumented).

Machine note: no other Godot process was running during the final measurement (unlike M29-C002). Absolute milliseconds are still host-dependent; counts are not.

## 2. Exact measured hotspot

Call path, which is the same in both regimes:

`ProductionRuntimeController.tick → AutoDispatchScheduler.step_lane → _attempt_slot (new ProductionTargetAccess(origin)) → BatchTargetClaimEngine.claim_for_slot → TargetSelector.select_and_reserve (priority-sorted candidates) → per candidate: board checks, rs.is_reserved, _op_coherent, access.is_targetable → [_could_reach] → _probe → ProductionRoutingSystem.compute_route → _railroad_route (outside start) | interior BFS (inside start)`

### 2a. UNLAID: the M29-C002 stall

| metric | value |
|---|---|
| slot origins | `(40,0) (49,0) (58,0)` **inside board**; `(67,0) (76,0) (85,0)` outside |
| lanes / inside-origin lanes / no-target lanes | 123 / 10 / 23 |
| failed route probes | 5605 (475 perimeter, 5130 interior), all from inside-origin lanes |
| worst lane | frame 352, rev 5, slot 1, batch T004, colour 4, origin (51,0): **590 candidates, 590 `is_targetable`, 0 prefilter-rejected, 590 `compute_route`, 0 ok**, selection 2382.6 ms (routes 2363.2 ms, max 6.96 ms each) |
| selection ms per lane | p50 8.95, p90 28.4, p99 2271, max 2383 |
| frame ms | p99 2167, max 2387 |

The first failed candidates are `(40,58) (41,58) …`, which are bottom-row perimeter cells of the colour-4 stripe. From an ACTIVE start cell inside the board the interior planner cannot reach anything.

### 2b. LAID-OUT: real production geometry, 6 s windows

| run | lanes | `compute_route`/lane max | failed routes | selection ms p50/p90/p99/max | frame ms p99/max |
|---|---|---|---|---|---|
| 59x59 6 slots 2x 60 FPS | 222 | 1 | 0 | 4.81 / 20.8 / 26.2 / 26.2 | 30.6 / 32.3 |
| 59x59 6 slots 1x 60 FPS | 109 | 1 | 0 | 3.46 / 22.2 / 24.1 / 24.9 | 28.4 / 30.4 |
| 59x59 6 slots 2x **historical tempo** | 144 | 1 | 0 | 3.63 / 8.44 / 23.4 / 24.3 | 27.7 / 29.0 |
| 59x59 6 slots 2x 30 FPS | 180 | 1 | 0 | 4.52 / 8.08 / 26.1 / 30.2 | 31.8 / 36.9 |
| 59x59 5 slots 2x 60 FPS | 186 | 1 | 0 | 4.62 / 23.2 / 25.2 / 25.7 | 29.6 / 30.8 |
| 32x32 6 slots 2x 60 FPS control | 220 | 1 | 0 | 3.76 / 7.12 / 9.50 / 9.66 | 13.4 / 13.7 |
| uninstrumented 59x59 6 slots 2x (RuntimePerfProbe) | 222 | 1 | 0 | `target_selection` mean 6.27, **max 19.9** | 24.4 / 25.2 |

Representative expensive laid-out lane: frame 253, rev 65, slot 1, batch T004, colour 4, origin (15.6, 72.78).
- 565 candidates, 562 `is_targetable` calls, 561 prefilter-rejected, 1 `compute_route` (ok).
- Winner `(46,0)` at rank 561 of 565; selection 26.2 ms, of which the route took 4.17 ms.
- The rest is the O(candidates) scan: 561 × (~9 µs rejected `is_targetable` + selector loop checks).

### 2c. LAID-OUT full level (all 3481 clears, WON)

| metric | instrumented (counts) | uninstrumented (timing) |
|---|---|---|
| lanes | 5177 (1696 no-target WAITING rescans) | 5177 |
| candidates per lane | p50 227, p90 504, max 590 | — |
| `is_targetable` per lane | p50 28, p90 295, max 571 | — |
| `compute_route` per lane | **max 1**, mean 0.7; **0 failures** | 3481 calls = winners only |
| winner rank | p50 6, p90 221, max 570 | — |
| `target_selection` | — | mean 17.0 ms, **max 197.2 ms** |
| `access_compute_route` (winner route) | — | mean 19.1 ms, max 191.6 ms |
| of which `route_dijkstra` | — | mean 15.8 ms, **max 164.7 ms** |
| of which `route_sources` / `route_validate` | — | mean 2.17 / 0.26 ms |
| selection excluding the route (WHAT-side scan) | — | ≈ (87 944 − 66 470 − 657) ms / 5177 ≈ **4.0 ms per lane** |
| frame ms | — | p50 5.9, p90 32.5, **p99 70.0, max 227.8** |

Worst late-level lane (instrumented): frame 8111, rev 3288, colour 1, origin (43.45, 72.78). It had 28 candidates, 24 prefilter-rejected and 1 route (ok, 96.5 ms), and the winner was `(16,17)`. At that stage almost the whole board is CLEARED, so the Railroad Dijkstra expands nearly the entire open region before it pops the target.

### 2d. Pre-existing vs retune

- Historical tempo shows the same per-lane shape: 1 route per lane, 0 failures, selection p99 23.4 ms versus 26.2 ms new.
- The route cost depends on board state, not on tempo.
- The retune raises the lane-attempt rate (2x at the same factor: 144 → 222 lanes in 6 s), so the same per-lane costs are met more often per second.
- The UNLAID stall predates the retune too: the M29-C002 historical-tempo comparison ran on the same unlaid shape.

## 3. Existing M52 prefilter: what it removes and why it did not bound the case

`ProductionTargetAccess._could_reach(index)` (M52-C001-R01) returns true, meaning "probe it", iff:

- the origin is invalid or inside the board, so the prefilter is **deliberately skipped** and the debug interior planner handles it; or
- the target is a perimeter cell, which has direct rail ingress; or
- the target is 4-adjacent to a cell in `_reach_mask`, which is the set of CLEARED cells 4-connected through CLEARED cells to a perimeter CLEARED cell.

The mask is rebuilt per `(BoardState instance id, revision)` and shared statically across the lanes of one board state.

**What it removes:** every sealed candidate, i.e. an interior ACTIVE cell with no CLEARED, perimeter-connected neighbour. These are the full perimeter-scan plus Dijkstra calls that caused the Level 2 stutter. M52 proved the prefiltered verdict equals the full-route verdict for 3,486 cells.

**Why the 59x59 M29 case still reached 590 routes:** all the expensive lanes had an **inside-board origin**, for which `_could_reach` returns true unconditionally, so the prefilter was bypassed for every candidate.
- In the UNLAID run, 0 of the 5605 failed probes were prefilter-rejected. In the LAID-OUT runs, 100% of non-winning candidates were prefilter-rejected and 0 routes failed.
- The main reason is therefore not perimeter candidates, frontier shape, revision churn or repeated scans. It is **origin geometry**: slot origins that land inside the board.

**Is the prefilter sufficient on real geometry?** For route count, yes: it is a necessary condition, and on the Railroad V1 graph it was observed to be exact. A prefilter-passing candidate either is a perimeter cell (a source itself) or is adjacent to a mask cell that the Dijkstra reaches from a perimeter source. Result: 0 prefilter-passing failures in 5177 + 1061 laid-out lanes.

It does **not** bound the WHAT-side work: the loop is still O(candidates).
- Each rejected candidate costs ~9 µs (median, timed around the real `is_targetable` call). The cost comes from a call into `is_targetable`, the `_could_reach` bounds, origin and revision checks, `get_cell_position`, a freshly allocated 4-element `Vector2i` array literal per call, and `_clear_memo`.
- On top of that, the selector's strict per-candidate sequence (`is_valid_index`, `get_cell_state`, `get_color_id`, `is_reserved`, `_op_coherent` ×2 with two `is_bound_to` callbacks each, `get_target_for_owner`) runs for **every** candidate before the prefilter is even consulted.

## 4. Duplicated work

- **Within one lane:** none in route terms. The one successful route is memoized and consumed once by `_attempt_slot`, never recomputed. The duplicated work is the per-candidate strict loop over candidates that the prefilter will reject: 561 of 562 in the representative lane.
- **Across lanes and waves:**
  - The canonical order restarts from the bottom row for every lane of the same colour. The same prefix of rejected candidates is re-examined, because bottom rows stay reserved/ACTIVE while agents travel.
  - WAITING rescans: every authenticated clear calls `_wake()`, which clears **all** WAITING slots, so each is fully rescanned on the next wave. That is 1696 of 5177 lanes, finding nothing.
  - The reach mask is already shared per revision. There were 2108 distinct revisions over 5177 lanes, about 2.5 lanes per revision.
- **Failed probes repeated across lanes:** 0 on real geometry, since there are no failed probes. In the UNLAID shape, the same `(rev, idx)` failed again 1121 times, but always from a *different* origin (the same `(rev, origin, idx)` repeated 0 times).

## 5. Options

All options keep the WHAT policy exact: matching ACTIVE colour, unreserved, currently production-targetable, bottom-most then left-most then index, and the same winner. They also keep the transaction truth: one target per owner, reservation uniqueness, same-colour FIFO, no pre-claim, no ghost, exact rollback, and strict fail-closed coherence.

### Option A: exact-safe per-revision "touchable" necessary-condition mask (RECOMMENDED, WHAT side)

- **Structure.** `touch[i] = 1` iff `i` is a perimeter cell, or `i` is 4-adjacent to a `_reach_mask` cell. This is exactly the existing `_could_reach` predicate, materialised once per `(board instance id, revision)` next to the reach mask, in the same static shared cache.
- **Ownership.** Only `ProductionTargetAccess` (HOW/access side). The selector never sees topology; it sees an opaque "cannot possibly be targetable" oracle.
- **Two stages:**
  - **A1 (access-only, zero selector change):** `_could_reach` becomes one byte lookup (`touch[index]`) for outside origins, and the per-call `Vector2i` array allocation disappears. Expected ~9 µs → ~2–3 µs per rejected candidate (GDScript call overhead remains).
  - **A2 (canonical pre-filter handshake):**
    - `TargetSelector` asks the access for a *necessary-condition filter* **only when** the access is exactly the canonical `ProductionTargetAccess` (script identity, like the existing routing fast path) and reports `is_bound_to_board(board)`.
    - It gets back a detached `PackedByteArray` plus the board revision it was built for.
    - The selector then drops candidates with `touch[idx] == 0` from its already-sorted list **before** the strict loop, and re-checks that the revision is unchanged after the handshake (fail-closed: mismatch → unfiltered full loop).
    - Any other access object (doubles, adversarial tests, future accesses) keeps today's unfiltered loop.
- **Zero false negatives (proof obligation).** `touch` equals `_could_reach` for outside origins, and M52 already proved `_could_reach == false ⇒ compute_route fails` (the necessary condition of the Railroad graph). For inside-board origins the access returns "no filter", so today's behaviour is kept.
- **Same winner (proof obligation).**
  - The filtered list is a subsequence of the canonical order.
  - Every dropped candidate would have returned `is_targetable == false`.
  - On a false verdict the real access's only side effects are the revision-keyed mask build (deterministic, identical) and `_clear_memo()` on an already empty memo. The selector stops at the first success, so no memo exists before it.
  - `is_reserved` is a pure read, and the candidate list already excludes reserved indices.
  - So the first `true` in the filtered sequence is the first `true` in the full sequence.
- **Strict-loop observability.** Dropped candidates no longer trigger `is_reserved` / `is_targetable` / `_op_coherent` callbacks. This is exactly why A2 is limited to the canonical access, whose callbacks are side-effect-free for these outcomes. All M15/M19/M25 strict adversarial suites run against doubles and therefore still take the unfiltered path.
- **Invalidation.** The key is `(BoardState.get_instance_id(), BoardState.get_revision())`. Revision already bumps on every cell write and on `restore_all_active` (Retry), so reset, restore and retry are covered. The mask is never reused for another board or another revision; there is no timer and no heuristic.
- **Complexity.**
  - Mask build is O(W·H) once per revision. It is only needed when some outside-origin lane asks, and it is amortised over ~2.5 lanes per revision.
  - A lane costs O(C) byte tests plus O(F) strict iterations, where F is the touchable candidates (typically ≤ ~60 on 59x59 stripes: one boundary row per stripe plus the perimeter), plus exactly one route.
- **Expected benefit (real geometry).** The WHAT-side scan drops from ≤ 26 ms (early) and ~4 ms mean to **≤ ~1–2 ms per lane** on 59x59. WAITING rescans become near-free. Route probes per lane stay at 1 (already measured).

### Option B: exact memo/cache of targetability verdicts

- **Key:** `(board instance id, revision, origin (exact floats), target index, routing script identity)`. It must never reuse across board, revision or origin.
- **Measured hit rates:**
  - **Real geometry:** 0 failed probes to cache. The winning route is already memoized one-shot. A successful verdict cannot be reused by another lane because the target becomes reserved. There are ~2.5 lanes per revision, each from a different slot origin. **Hit rate ≈ 0.**
  - **UNLAID shape:** the same `(rev, origin, idx)` repeated 0 times. The same `(rev, idx)` from other origins repeated 1121 times with 0 verdict disagreements, but an origin-independent key is not proven safe: inside and outside starts use different planners.
- **Verdict:** adds cache ownership and invalidation risk for no measured benefit on production geometry. **Not recommended.** Revisit only if Option A plus the route work leaves a measurable repeated-verdict cost.

### Option C: bounded incremental scan / deterministic continuation across frames

- **Idea:** split a lane's candidate scan, or its winning route computation, over several frames with a fixed per-frame budget, resuming at the exact canonical position.
- **Constraints it must solve:**
  1. `select_and_reserve` is one synchronous, re-entrancy-guarded transaction (`_in_selection`, `_op_coherent`, bind generation). Splitting it needs a persistent "scan cursor" object owned by the scheduler lane, not by the selector.
  2. The board revision can change between frames (clears land every frame). The cursor must restart from rank 0 on any revision change, because an earlier canonical candidate may have just become targetable. Otherwise a later candidate could be chosen while an earlier one is untested.
  3. Reservations may change between frames (other lanes reserve). The candidate list must be re-derived on resume, or on any reservation change.
  4. The scheduler lane must stay pending (`has_pending_lanes`) while the cursor is live, and `MAX_LANES_PER_FRAME = 1` means the lane blocks its wave for several frames.
  5. Reset, Retry and terminal must drop the cursor atomically. No reservation may exist until the final successful probe, and reservation stays the atomic last step.
- **Verdict:** exact and bounded, but **architecturally heavy**. It touches TargetSelector, M25 and M26 lane state, and any restart-on-revision cursor can starve under continuous clears. It is unnecessary for the WHAT side once Option A holds. **Keep only as the fallback for S2** if exact route acceleration cannot bring the winner route under budget.

### Option D: origin-geometry correctness (evidence and diagnostic)

- **D1 (tests/evidence):** every 59x59 or dense performance harness must run on a laid-out host and assert `origin.y ≥ board height` for every slot, as `m29_exact_slot_origin_evidence` does for the production scene. The M29-C002 s8 and M52-style unlaid fixture hosts do not.
- **D2 (production, owner decision):** an inside-board production origin is a layout fault. Today it silently selects the debug interior planner and can stall for seconds.
  - Proposal: a cheap guard where `SlotOriginProvider` or `_attempt_slot` treats an inside-board origin as INVALID (fail-closed: no robot, one diagnostic), mirroring its existing "no synthetic fallback" rule.
  - This changes shipping behaviour for a broken layout only. It needs owner and ChatGPT approval.

### Option E: exact-equivalent winning-route acceleration (HOW side, separate routing prompt)

The single remaining real hotspot is `_railroad_route`'s interior Dijkstra (mean 15.8 ms, max 165 ms late in the level). Candidates, each requiring **bit-identical routes** (same points; route identity and railway-first tie-break are owner-locked):

1. **GDScript-level exact micro-optimisation:** precomputed neighbour offsets as ints, no `Vector2` per pop, `Dictionary src_rp` → packed arrays, and an early per-source cost bound.
2. **Per-revision shared, origin-independent pre-pass:** with `INTERIOR_STEP_COST = 1000` above any `cost0`, the primary key is interior step count, which is origin-independent given the perimeter sources. A per-revision multi-source BFS layer map could bound the Dijkstra to the target's layer. Exactness of the secondary rail-cost and (side, seq) tie-break must be proven by differential test.
3. **Native module:** out of scope without an owner decision (a dependency / GDExtension).

A differential test harness (old vs new `compute_route` on randomized and real boards, equal `RouteResult` points) is mandatory.

## 6. Recommendation (staged)

| stage | what | files likely changed | new state / ownership | invalidation |
|---|---|---|---|---|
| **S0** | Laid-out 59x59 performance harness plus an origin-below-board assertion (D1). Owner/ChatGPT decide D2. | tests only (`tests/m29_c002_tempo_retune.gd` s8 fixture host, a new M25 perf suite); D2 would touch `slot_origin_provider.gd` or `auto_dispatch_scheduler.gd` | none | n/a |
| **S1** | Option A1 + A2 | `scripts/gameplay/dispatch/production_target_access.gd` (touch mask, filter handshake), `scripts/gameplay/targeting/target_selector.gd` (canonical-access pre-filter before the strict loop, revision re-check, fallback) | touch mask in `ProductionTargetAccess`'s existing static shared cache, next to `_shared_mask`, keyed by board instance id + revision | any revision change; different board instance; inside-board or invalid origin → no filter |
| **S2** | Option E (separate routing prompt) | `scripts/gameplay/routing/production_routing_system.gd` | optional per-revision layer map owned by routing | revision / board identity |
| fallback | Option C only if S2 misses the budget | scheduler + M25 lane cursor | scheduler-owned cursor | revision or reservation change → restart at rank 0 |

**Expected bounds after S1** (reproduced 59x59, real geometry):
- Route probes per lane ≤ 1 (already true; must stay ≤ 1 + validator rejections, which were measured as 0).
- Strict selector iterations per lane ≤ |touchable ∩ candidates|.
- WHAT-side selection excluding the winner route ≤ 2 ms per lane.
- The winner route remains until S2.

**Proof obligations for S1:**
1. `touch == _could_reach` for all indices, origins and revisions: a differential test over the full M52 state set plus 59x59 stripe states at many revisions.
2. For **every** lane of the full-level reproduction and all first-10 production levels, the filtered and unfiltered selectors produce the identical winner and the identical `ReservationState`.
3. A dispatch-sequence identity test: filtered vs unfiltered, all levels, laid-out host.
4. All M15/M19/M25 strict/adversarial suites unchanged, so the non-canonical access path is untouched.
5. Retry/restore invalidation test: the mask is rebuilt after `restore_all_active`.

**Regression risks:** a stale mask after a revision-less mutation (mitigated because every `BoardState` write bumps revision; to be asserted), and accidentally filtering for non-canonical accesses (mitigated by the script-identity gate). **Rollback:** delete the handshake call in `TargetSelector`. The access-only A1 remains harmless, and behaviour returns to today's loop.

## 7. Proposed acceptance target for the implementation prompt(s)

Algorithmic (hard, machine-independent), on the laid-out 59x59 six-stripe full-level reproduction and all production levels:
- **A-1:** `compute_route` calls per lane ≤ 1 for outside-origin lanes (count, asserted).
- **A-2:** strict selector per-candidate iterations per lane ≤ touchable candidates + 1 (count, asserted), with `_could_reach` evaluated as O(1) per candidate.
- **A-3:** identical winner / reservation / dispatch sequence vs the unfiltered baseline (equality, asserted).
- **A-4 (S0):** every harness origin is outside the board (asserted). If D2 is approved, an inside-board production origin produces zero `compute_route` calls (asserted).

Observed (reported with machine note, not the correctness gate):
- **T-1 (S1):** uninstrumented `target_selection − access_compute_route` per lane p99 ≤ 3 ms on 59x59 (today ≈ 4 ms mean, ≤ 26 ms early).
- **T-2 (S2):** uninstrumented `access_compute_route` p99 ≤ 8 ms and frame p99 ≤ 20 ms on the full-level 59x59 reproduction at 60 FPS (today 19.1 ms mean / 191.6 ms max route; frame p99 70 ms / max 228 ms).
  - If exact S2 cannot reach this, fall back to Option C with a per-frame work budget (a count-based bound, e.g. ≤ N Dijkstra pops per frame).

## 8. Scope / governance

- No production gameplay code changed. The only code added is `tests/tools/m25_c002_selection_probe.gd`, which is test-only, never loaded by the game and not part of the regression suite set. Evidence and docs are the rest.
- `TargetSelector`, `ProductionTargetAccess`, routing, claims, scheduler, runtime, economy and level data are untouched. Root `TASKS.md` is not edited.
- Historical M29-C002 implementation and evidence are unchanged. SB-M29-010 stays open per the audit; ChatGPT decides how these findings affect the M29 performance gate and owner playtest.
