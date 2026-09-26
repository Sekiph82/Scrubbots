# M52-C001-R01 — Parallel Runtime Remediation — Claude Log V01

Status: **AWAITING_CHATGPT_AUDIT**
Prompt: `coordination/sessions/M52-C001/task_prompts/SB-M52-C001-R01_PARALLEL_RUNTIME_REMEDIATION.md`
Owner authority: `coordination/OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01.md`, `coordination/sessions/M52-C001/OWNER_PLAYTEST_FINDINGS_V01.md`

## SHAs

- Baseline HEAD: `0fa38f6f3d2968ec800304231d351d87ae290781`
- Implementation: `914f182bca8e8c51890eba07e8807aedaf315f77`
- Log: the commit adding this file (the resulting `main` HEAD, reported in the hand-off message)

## Changed rule surfaces

| Surface | Before | After (R01) |
|---|---|---|
| M25 claim | `claim_for_color`: oldest same-color batch with capacity monopolizes, spill at 0 | NEW `claim_for_slot(slot, access)`: exact slot, color/batch from M24, that slot's own origin/access, one unique reserved target, same identity/rollback/finalize/reset guarantees. Legacy `claim_for_color` kept for M25 API/evidence compatibility only; production scheduling never calls it. |
| M26 cadence | one accepted assignment per `step()`, color round-robin, global per-color WAITING | one **parallel wave** per cadence: every eligible occupied slot (capacity > 0, not WAITING on its current batch) in placement-sequence order (slot-index tie-break) gets at most one assignment; 0..5 (6 with +1 Slot); a WAITING/failed lane never aborts siblings; **per-slot WAITING** keyed by batch id; `step()` returns `assigned` + `assignments`. |
| Runtime clock | up to 4 steps per frame (catch-up) | wave lanes serviced **one per frame** (`begin_wave`/`step_lane`); at most one wave in flight; cadence backlog beyond one interval dropped (no multi-wave storm, no unbounded catch-up). A 5-lane wave lands in 5 frames (~83 ms), far below one 0.5 s / 0.25 s cadence and long before any agent can reach its target. |
| M24 counters | unchanged | unchanged: `remaining_to_clear` only on authenticated clear, `committed` on accepted work, rollback restores; display = `remaining − committed` (already so — now proven by runtime tests). |
| 2x control | no entitlement → silent no-op | no entitlement → functional **SpeedAcquisitionPopup** (current level 200 SB, 15m 300, 30m 500, 60m 750, Cancel; prices from `EconomyConfig`), purchases via `ProductionActionFacade` (durable save), success → 2x immediately + control shows 2x; cancel/insufficient/failure → nothing spent, no entitlement, speed unchanged, visible message. Entitled toggles 1x↔2x. Auto supply-exhausted 2x unchanged. **Functional UI pending M43 visual master/polish.** |
| M27 kernel | color-serialized quiescence | **wave kernel**: each iteration = one wave of exact-slot claims (each slot's own below-board origin) against the pre-wave board, then the wave's clears; per-slot WAITING; mirrors runtime lane policy. |

Unchanged: M23 front-only FIFO, rightmost-empty placement, 5/6 capacity, per-color conservation, batch identity, TargetSelector order, ReservationState uniqueness, Railroad legality, no-ghost order, authenticated clear authority, exact-once terminal/economy.

## Five BLUE x30 (Level 2 Apple, clicks 1,2,3,1,2) — `evidence/{baseline,after}_five_blue.json`

| | First cadence | Assignments by slot | Displays | Cleared |
|---|---|---|---|---|
| Baseline | 2 live | slot 4 only `{4: 2}` | `[30, 30, 30, 30, 28]` | 0 |
| After | 5 live (5 lane frames) | `{0:1, 1:1, 2:1, 3:1, 4:1}` | `[29, 29, 29, 29, 29]` | 0 |

Subsequent waves: 10 → 15 → 20 … exactly one more per slot per wave (`28×5`, `27×5`, …). Tests assert unique targets/claims/agents, 5 reservations/claims/work/agents coexisting, and every display 30→29 before any target clears.

## Departure counter (tests/m52_r01_parallel_runtime.gd)

One 30 batch, one lane: before its clear `remaining=30, committed=1, displayed=29` (and the live slot view shows 29); after the authenticated clear `remaining=29, committed=0, displayed=29`; an established claim shows 28 and `rollback_claim` before clear restores 29.

## 2x acquisition — `evidence/{baseline,after}_2x_no_entitlement.json`

Baseline: press → speed 1x, no UI, SB 1000→1000 (silent no-op). After: press → `SpeedAcquisitionPopup` visible, speed 1x, SB unchanged. Tests: cancel spends nothing; insufficient SB shows "Not enough Scrub Bucks.", spends nothing, speed unchanged; current-level purchase −200 SB, 2x on, control "2x", result carries the durable `save`; entitled press toggles 2x→1x→2x without popup; 15m timed purchase −300 SB, 2x on, timed remaining > 0; supply-exhausted auto-2x still activates with no entitlement.

## Stutter root cause (measured)

Context: Windows 11, 12th Gen Intel Core i7-1260P (16 threads), Godot 4.7.2 headless, fixed 60 Hz ticks, Level 2 production runtime (AppState frontier 2 → catalog → owner plan), natural fast play of the owner click sequence. Instrumentation: `scripts/debug/runtime_perf_probe.gd` (off by default; single static bool per hook) around wave/lane, M25 claim, target selection, access route compute, route sources/Dijkstra/validation, dispatcher spawn, agent drive/arrival, renderer update, completion on_tick, M27 classifier, UI snapshot sync. Harness: `tools/r01_runtime_probe.gd`.

**Dominant cause:** `TargetSelector.select_and_reserve` → `ProductionTargetAccess.is_targetable` ran a full Railroad route search (perimeter source scan + interior Dijkstra with per-edge supercover checks) for EVERY candidate in bottom-most/left-most order. Late in Apple most C08 candidates are sealed pockets, so each claim paid hundreds of failing full searches: **M25 claim mean 177 ms, max 1.55 s; worst frame 1.84 s.** M27 classifier, renderer, UI sync, completion were negligible (completion max 8 ms, renderer max 0.12 ms).

Fixes (all exact-equivalent — verdicts/routes/order unchanged, proven by tests):
1. **Reachability prefilter** in `ProductionTargetAccess` (outside/rail starts): a target can only route if it is a perimeter cell or 4-adjacent to a CLEARED cell 4-connected to a perimeter CLEARED cell — exactly the graph the Railroad Dijkstra searches, so skipping cannot change a verdict. Mask cached by `BoardState` instance + new monotonic `get_revision()` (bumped on every cell write and `restore_all_active`). Test: prefiltered verdict == full route verdict for 3,486 ACTIVE cells across 6 Apple states, 0 mismatches. Result: exactly one route compute per successful claim.
2. **Railroad Dijkstra**: packed per-cell arrays and an allocation-free packed binary heap (keys (cost, side, seq, cell) are a strict total order ⇒ identical pop order); canonical-access fast path (exact `ProductionAccessQuery` script only) reads CLEARED directly for axis-aligned unit steps / rail bridges, whose supercover crosses no corner; `ScrubRailGeometry.rail_dist` = `rail_path(...)["dist"]` without building the polyline. Test: fast path route points identical to the fully segment-checked path (subclass access) for 812 targets on a randomized Palm Tree board, 0 diffs.
3. **Keyed candidate sort**: comparator order (y desc, x asc, index asc) == ascending int key `(h−1−y)·w + x` for valid row-major indices; native sort, comparator fallback for anything else. Test: 20 random candidate sets identical.
4. **Lane servicing**: one lane (one claim + route) per frame.

Before/after (idle machine; `evidence/{baseline,after}_perf_level2_{1x,2x}.json`):

| Level 2 | Worst frame | p99 | Frames >100 ms | >50 ms | >33 ms | >16.7 ms | M25 claim mean / max | Terminal |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Baseline 1x | 1840.3 ms | 160.9 ms | 516 | 755 | 837 | 906 | 177.3 / 1549.6 ms | WON |
| After 1x | **30.5 ms** | 19.1 ms | **0** | **0** | **0** | 303 | 7.3 / 27.4 ms | WON |
| Baseline 2x | 1877.5 ms | 384.7 ms | 512 | 752 | 831 | 883 | 176.7 / 1572.5 ms | WON |
| After 2x | **30.7 ms** | 21.7 ms | **0** | **0** | **0** | 299 | 6.9 / 27.2 ms | WON |

Peak concurrent live assignments rose from 36 to 115 (parallel lanes). Remaining >16.7 ms frames are single lane frames (one claim + one ~8 ms route) on this desktop; real-device frame smoothness must be confirmed in the owner playtest.

## Solver / proof consistency decision

`ProofKernel` now models the exact runtime lane policy (per-slot waves, own origins, per-slot WAITING, placement-sequence order). Documented in the kernel header (no longer claiming color-serialized equivalence; SolvabilitySolver header updated):
- **LOST soundness:** from a quiescent state nothing clears before the next successful claim and claim semantics are identical, so kernel "no future progress" == runtime "no future progress" — the classifier cannot report a false DEADLOCK/LOST from stale arbitration.
- **SOLVED:** a proof for the canonical wave timing (all of a wave's clears land before the next wave); runtime travel timing may differ, so production admission additionally requires the owner click sequence to reach WON through the real production runtime — done for all nine levels (below).

## First 10 re-proof / replay / runtime (new kernel + new runtime)

Evidence regenerated: `coordination/sessions/M52-C001/evidence/owner_plans/*_verification.json`.

| L | Solver | Visited | Decisions | Trace hash | Solver replay | Owner-click replay (kernel) | Production runtime (tests/m52_owner_supply_plans.gd) |
|---:|---|---:|---:|---:|---|---|---|
| 2 Apple | SOLVED | 37 | 36 | 4098941249 | PASS | PASS | exact queues, 3 visible rows, WON, 0 ACTIVE, supply exhausted, slots empty |
| 3 Palm Tree | SOLVED | 59 | 51 | 3808086370 | PASS | PASS | same |
| 4 Orange Cat | SOLVED | 40 | 39 | 2842640196 | PASS | PASS | same |
| 5 Party Toucan | SOLVED | 46 | 41 | 3056207161 | PASS | PASS | same |
| 6 Chicken | SOLVED | 41 | 40 | 3310440768 | PASS | PASS | same |
| 7 Pigeon | SOLVED | 40 | 39 | 2191893116 | PASS | PASS | same |
| 8 Butterfly | SOLVED | 38 | 37 | 2524445735 | PASS | PASS | same |
| 9 Frog | SOLVED | 40 | 38 | 3800836965 | PASS | PASS | same |
| 10 Ice Cube | SOLVED | 47 | 40 | 1480752256 | PASS | PASS | same |

(Trace hashes for L4/L6/L9/L10 changed because the canonical wave schedule differs from the old color-serialized one; statuses unchanged. Solver wall time dropped 2–10× from the perf fixes.) Level 1 Hazard Bot: `m27_hazard_bot_solve` SOLVED + replay; production runtime WON (`m29_hazard_bot_runtime_smoke`, `m30_manual_playtest_smoke`); `m52_owner_supply_plans` proves its supply is exactly the M23 seed-1 candidate (unchanged); frontier 11 = CONTENT_MISSING.

## Tests

New/updated:
- NEW `tests/m52_r01_parallel_runtime.gd` — 79 ok, 0 FAIL: five same-color one wave; runtime lane wave (≤1 new assignment per frame, 5 lanes in ≤6 frames); five different colors one wave; WAITING lane does not block siblings; unique identities; never two per slot per wave; +1 Slot six lanes never seven; departure count + rollback; pause/focus freeze + safe resume; Retry cleans 10 live parallel assignments and restores exact owner queues; Tornado with 10 same-color in-flight agents stays coherent; terminal cardinalities N=5; 2x halves cadence / doubles travel; 2x acquisition matrix; free auto-2x; prefilter/fast-route/keyed-sort equivalence; kernel wave model.
- `tests/run_tests.gd` — M26 fairness block honestly rewritten from the superseded "oldest BLUE monopolizes then spills / round-robin one color per step" rule to lane semantics (one per same-color slot per wave, four waves → four each, last targets, WAITING, no duplicate targets; one wave serves both colors). No other expectation changed.
- `tests/m30_manual_playtest_smoke.gd` — drain harness "settled" condition now also requires no queued lane, held for a full 1x cadence (a wave is serviced one lane per frame, so "0 live" can be momentarily true between lanes). The LOST/WON assertions themselves are unchanged and pass.

Runs (final code):
- Focused/historical sweep, each `godot --headless --path . -s res://tests/<suite>.gd` — **75 suites, all exit 0, 0 SCRIPT ERROR, 0 FAIL**: every `m23_*`…`m42_*` suite, `m52_owner_supply_plans` (255 ok, 9 production WONs), `m52_r01_parallel_runtime` (79 ok), `palette_v3_leveldata_contract`.
- Root `tests/run_tests.gd`: **exit 0, 5323 checks, RESULT: ALL PASS**, 0 SCRIPT ERROR. Engine `ERROR:` lines: 9, sorted-content hash `34c0bb32` — identical to the pre-R01 baseline (e.g. "18 resources still in use at exit", intentional corrupt-image fixtures).
- `git diff --cached --check`: clean.

Note: a headless run rewrote `project.godot` (key reorder + dropped `buses/default_bus_layout`) as a side effect; it was restored with `git checkout -- project.godot` and is not part of any commit.

## Protected scope

Not edited: `TASKS.md`, owner decision files, ChatGPT audit/criteria files, source PNGs, owner supply plans, Level 1 content, Heart economy/prices, opening cinematic, Home.

## Git status

After push `main` == `origin/main`; only pre-existing untracked owner/editor files remain (`*.import`, `*.uid`, `_owner_inbox`, UI candidates, audio, root-level duplicate level PNGs). Owner stash untouched.

`AWAITING_CHATGPT_AUDIT / M52-C001-R01 PARALLEL RUNTIME REMEDIATION`
