# M25-C002 — CLAUDE LOG V01 (59x59 target-selection investigation, SB-M25-033)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`
Findings: `M25_59X59_TARGET_SELECTION_FINDINGS_V01.md`
Status: **AWAITING_CHATGPT_AUDIT** (investigation / proposal only)

## Sync / governance

- `main` fast-forwarded (`--ff-only`) from `8787d38` to `9987871` (M29 audit + M25-C002 prompt/criteria/TASKS commits); no conflict.
- Root `TASKS.md` was read and **not edited**. The local `project.godot` drift and the untracked owner files are preserved and not committed.
- **No production code changed.** `TargetSelector`, `ProductionTargetAccess`, routing, claims/reservations, scheduler/runtime, economy and level data are untouched. The historical M29-C002 implementation and evidence are untouched.

## Added (test-only / evidence / docs)

- `tests/tools/m25_c002_selection_probe.gd`: a non-shipping measurement tool, never loaded by the game and not a regression suite.
  - A test-only `TargetSelector` subclass is swapped into the host's claim engine. It passes the real `ProductionTargetAccess`, wrapped in a forwarding proxy, to the unmodified selector logic (`super.select_and_reserve`).
  - It records per-lane attribution: board revision, slot/batch/colour, origin, candidate count and canonical order, per-candidate prefilter verdict, `is_targetable`/`compute_route` calls and timings, success/failure, winner and rank, and cross-lane repeats.
  - Transparency proven: the instrumented dispatch sequence equals the uninstrumented one (219 = 219 in the 6 s window; **3481 = 3481 over the full level**).
- `evidence/selection_probe_report.txt` / `.json`: per-run distributions, the 5 worst lanes per run with full attribution, and uninstrumented RuntimePerfProbe breakdowns.
- `M25_59X59_TARGET_SELECTION_FINDINGS_V01.md`: findings, prefilter analysis, options A–E, staged recommendation, acceptance bounds.

Reproduce:

```
godot --headless --path . -s res://tests/tools/m25_c002_selection_probe.gd -- <out_dir>
```

This takes about 8 minutes, mostly the two full-level runs.

## Result in short

1. **The M29-C002 2.2–2.4 s lanes come from harness geometry.** The M29 59x59 fixture host was not laid out, so slot origins mapped to `(40,0)`, `(49,0)`, `(58,0)`, which are inside the board. For inside-board starts the M52 prefilter is bypassed by design and the interior debug planner fails every candidate. The worst lane made 590 of 590 failed `compute_route` calls, 2382.6 ms.
2. **Real laid-out geometry (1080x2160, origins `y ≈ 72.8`):** 0 failed route probes and ≤ 1 `compute_route` per lane in every run, including the full level (5177 lanes, 3481 clears, WON).
3. **Remaining real costs, pre-existing and identical at historical tempo:**
   - The WHAT-side O(candidates) scan: ≤ 26 ms per lane early, ~4 ms mean, and 33% of lanes are WAITING rescans.
   - The winning route's Railroad Dijkstra late in the level: uninstrumented mean 15.8 ms, max 164.7 ms, giving frame p99 70 ms and max 228 ms.
4. **Recommendation:**
   - **S0:** laid-out performance harness plus an origin-below-board assertion; owner decides the D2 inside-origin guard.
   - **S1:** Option A, an exact-safe per-revision touchable mask plus a canonical pre-filter handshake.
   - **S2:** a separate exact-equivalent routing acceleration prompt.
   - Option B (cache) is rejected (hit rate 0). Option C (continuation) is kept as the S2 fallback.

## Notes / limitations

- During this cycle no other Godot processes ran, unlike M29-C002. Timings are still host-dependent; counts and equality proofs are not.
- `slot = -1` in some worst-lane rows means the lane belonged to a wave begun inside that same tick, so the pre-tick lane list could not attribute the slot. Colour, origin and batch-independent metrics are still exact.
- The instrumented per-lane milliseconds include proxy overhead, so timing claims in the findings use the uninstrumented RuntimePerfProbe runs.
- The earlier "M25 target-selection scan" follow-up suggestion from M29-C002 is superseded by this cycle.

`AWAITING_CHATGPT_AUDIT / M25-C002 59X59 TARGET-SELECTION INVESTIGATION V01`
