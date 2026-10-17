# M46-RM-001 — Performance & test-evidence remediation — CLAUDE LOG V01

**Prompts:** `CHATGPT_M46_MASTER_REMEDIATION_V01.md` → child `CHATGPT_M46_RM001_PERFORMANCE_EVIDENCE_PROMPT_V01.md`, criteria `CHATGPT_M46_RM001_PERFORMANCE_AUDIT_CRITERIA_V01.md`, audit `CHATGPT_M46_FULL_SURFACE_REAUDIT_V01.md` (F02 / F03 / F08).

**Evidence level:** implementer E1/E2 only. This is not an audit and claims no `AUDITED_*` status. Root `TASKS.md` was not edited.

**Source:**
- Implementation reference: `76e4aff8` (R07).
- RM-001 changes `tests/m46_performance.gd` only; **no production code changed**.
- Pinned tested SHA: **`884c2348cf7b017b6d761f088651b928d0c5a4b2`**.

**Environment:**
- Godot 4.7.2 headless, one Windows desktop, CPU only.
- **No GitHub Actions**, no phone, no GPU.
- Owner working-copy edits (`project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/*.tscn`) were present and untouched.

## 1. What changed in `tests/m46_performance.gd`

### M46-011 — real transient-allocation observation (F02)
**Probe.** `_obj_serial()` reads the engine's global ObjectDB validator counter (instance_id bits 24..62). Every new Object takes the next value, so the difference between two probes counts **every Object created in between, including ones already freed**.
- Verified with a throw-away diagnostic, since deleted: 1,000 `RefCounted` → 1,000; 500 `Node` new+free → 500.
- Arrays and Dictionaries count 0. **It counts Objects only (Node / RefCounted / Resource), not Variant container heap churn.** This limitation is stated in the test.

**Harness calibration.** Each `await` in the test coroutine creates exactly one `GDScriptFunctionState`. A function's first await creates one extra.
- p15 asserts the calibration at runtime: 60 awaited frames → exactly 60.
- Every window subtracts it.

**New assertions:**

| Case | Assertion | Measured |
| --- | --- | --- |
| p15 | 100 identical slot rebinds create 0 Objects | 0 |
| p15 | 60 idle frames with slot view + 59×59 board + magnifier create ≤ `IDLE_OBJ_WINDOW_MAX` (4) | 0 |
| p15 (built-in sensitivity, every run) | a synthetic transient pulse of 25 Objects/frame, created and freed with net retained ±0, is counted and breaks the idle budget | 750 over 30 frames, net +0 |
| p13 | 120 idle host frames after a warm-up create ≤ 4 | 0–1 |
| p13 | Objects created per cleared cell over the whole level ≤ `LEVEL_OBJ_PER_CLEAR_MAX` (70) | 47.6–47.65 |

**Warm-up.** The first 120 runtime ticks after host build create about **3,207 Objects once**: one-time lazy state, not per-frame. That is excluded from the idle window and reported in the assertion text.
- Diagnosis: tick-only vs frame-only windows. After warm-up, idle ticks create 0, and the frame-only window equals the harness count exactly.
- **This is not a production defect**; no code was changed.

The p11 net-Object checks are kept unchanged.

### M46-014 — meaningful density (F02)
The p13 fixture is deterministic (fixed `DT` ticks, scripted feeding), so its peak is a property of the code:
- **114 agents in flight**, in every run (and earlier R02 logs).
- `DENSITY_MIN` = **90** (about 79%): it allows legitimate tuning, but rejects halving.

**At each new peak the test cross-checks:**
- real `ScrubbotAgent` nodes == dispatcher count: 114 == 114;
- reserved targets ≥ agents: 114;
- duplicate reservations: 0.

**Built-in sensitivity, every run:** the same fixture fed one batch at a time peaks at **31**, and the test asserts that 31 < 90 fails the floor.

M46-007 (200 synthetic agents) is unchanged and separate.

### Header
The suite header documents the new p11 / p14 / p15 semantics.

## 2. Negative controls (RM001-09)
Temporary test-only edits, marked `RMCTL`, were run once and then reverted. Grep found no `RMCTL` / `RMDIAG` marker before the commit.

Run: `godot_console --headless --path . -s res://tests/m46_performance.gd -- micro level` (subset, exit 1 by design).

| Control | Perturbation | Result (each fails the intended assertion) |
| --- | --- | --- |
| RMCTL1 | 100 rebinds with *changed* snapshots | `FAIL: 100 identical slot rebinds CREATE 1100 Objects` |
| RMCTL2 | +25 RefCounted per idle host frame | `FAIL: 120 idle host frames … CREATE 3000 Objects` |
| RMCTL3 | +25 RefCounted per level frame | `FAIL: Objects created per cleared cell 183.84 (<= 70.0)` |
| RMCTL4 | a duplicate reserved index injected at the peak | `FAIL: at the peak: … 115 reserved targets … 0 duplicate reservations` (1 duplicate printed) |
| RMCTL5 | agent-node count −1 | the same peak assertion fails (113 nodes ≠ 114) |
| built-in | transient pulse; one-batch feeding | always asserted in the suite (above) |

## 3. Final full suite (RM001-08)
**Command:**
```
godot_console --headless --path C:\Users\sekip\Desktop\ScrubBots -s res://tests/m46_performance.gd
```

**Result:**
- **`M46 performance evidence: PASS (22/22 cases, 0 fail)`, process exit 0.**
- SHA `884c2348`, elapsed 481 s, started 2026-10-17 18:38 +03:00.
- **One** full run, after the targeted checks; not repeated.

**CPU contention (recorded honestly):**
- Windows average CPU load 28% at start, 15% at end, 16 logical CPUs.
- 10 other headless Godot processes from **another project** (`Beach Cocktails - Merge` tests) were running the whole time. They were not stopped (another agent's work).
- So these are contended desktop timings: not an isolated benchmark, and not phone figures.

**Case ledger (all 22 completed):** p01 p02 p03 p04 p05 p06 p07 p15 | p09 p10 | p12 | p13 p14 p08 p11 | p16 | p17 | p18 | p19 | p20 | p21 | p22.

**Key measured values:**

| Case | Values |
| --- | --- |
| p13 | WON 3,481/3,481 in 18,961 frames; mean **2.424 ms** (≤ 4.0), p99 **8.387 ms** (≤ 16.7), max 51.567 ms (one-off, logged) |
| p14 | peak 114 (floor 90): nodes 114, reserved 114, duplicates 0; one-batch control 31 |
| p11 | idle created 1 (≤ 4); 47.65 created per clear (≤ 70); net Objects +0 idle, −115 level end |
| p15 | 0 created by rebinds and the idle window; pulse 750 counted |
| p16 v2 | WON 3,025 art + 456 VOID, 20,828 frames; mean 2.172 / p99 9.147, max 613.776 ms (one-off); every slot WAITING at once, 92 entered / all left |
| p17 | 6 slots + Tornado, WON; 7th slot refused; retry back to 5 |
| p18 | maze route 7 turns / 41 cells, no duplicate targets; mean **3.541** / p99 13.817 |
| p19 | FULL / REDUCED owned work, 0 leftovers, structural "never per cell" |
| p20 | Random / Selector 59×59, 92-id equivalence, in-flight shortcut exactness; WON |
| p21 | worst proof call 418 ms (budget 400 ms + node margin) |
| p22 | worst wait frame < 16.7 ms; cancel 5.0–5.2 ms |
| p09 / p10 | cold 20×20 host +99.35 MB, warm +57.00; 59×59 +57.34 → board-size cost **+0.34 MB** (≤ 8); free → objects +0 |
| p12 | 30 retries: nodes 292 → 292, objects −2, static −23,852 B, retry worst **48.51 ms** (limit 50.1) |

**Outlier note:** the p12 retry worst (48.51 ms) sits close to its 50.1 ms one-off limit under contention, and the p16 max frame is 613.8 ms. Both are pre-existing one-off metrics: reported, not gated, and the limits were not loosened.

## 4. Criterion ledger (RM001)
| Criterion | Status | Evidence |
| --- | --- | --- |
| RM001-01 all p01..p22, ledger, no silent skip | **PASS** | `EXPECTED_CASES` = 22 and `_done()` fails on any missing case. A script error aborting a case leaves it out of the ledger, so the suite fails. The full run reported 22/22. |
| RM001-02 transient allocations, with sensitivity | **PASS** (scoped) | ObjectDB counter, calibrated; 0 idle / 0 rebind; pulse counted (built-in) plus RMCTL1–3. **Limitation:** Objects only; Variant / Array / String heap churn is not counted. |
| RM001-03 density floor from real p13 overlap, with sensitivity | **PASS** | 114 peak (deterministic), floor 90, nodes / reservations / duplicates cross-check, one-batch control 31 plus RMCTL4–5. |
| RM001-04 p13 / p16 / p17 / p18 / p20 counts, 5/6, WAITING, no duplicate reservations | **PASS** | full-run lines above (3,481; 3,025 + 456; 6 slots; maze; 92 ids). p13 now also asserts 0 duplicate reservations at the peak. |
| RM001-05 mean ≤ 4.0 / p99 ≤ 16.7, max logged, contention controlled | **PASS** for thresholds; contention **disclosed, not eliminated** | All gated means / p99s inside the limits; one run only; other-project load recorded. No phone / GPU claim. |
| RM001-06 restarts, cold vs warm, board-only delta ≤ 8 MiB | **PASS** | p12 / p09 / p10 lines above. |
| RM001-07 M46-015 FULL / REDUCED, 0 per cell, 0 leftovers, GFF Node2D limitation | **PASS** (scoped) | p19. GameFeelFlow `punch_scale` is proven on a Node2D target; **a production Control target for GFF is not proven**. Phone open. |
| RM001-08 one complete 22/22 run, exit 0, pinned SHA | **PASS** | §3. |
| RM001-09 negative control per new load-bearing assertion, reverted | **PASS** | §2. |
| RM001-10 owner gates open, no Actions | **OPEN (as required)** | R06 / R07 F5, Android / iPhone GPU and cloud CI are not claimed. No workflow touched; both job guards untouched. |
| RM001-11 log governance | **PASS** | exact commands / SHA / exits here; no `TASKS.md` edit; no audit file; owner files untouched. |

**Milestone-criteria mapping notes (RM001 scope):**
- **M46-001** invalid inputs (bad dimensions / colours / supply) are covered by existing `tests/run_tests.gd` (M21 LevelLoader fail-closed); p01 covers valid catalog + 59×59 timing.
- **M46-012** 5/6 restoration on retry is p17. The stale worker on retry / exit is RM-002 (T03) and p22.

## 5. Not changed / open
- **No production code changed.** No thresholds were loosened: 4.0 / 16.7, restart budgets, 400 ms, 5 s.
- **Open:** phone / GPU / heat; owner F5; ChatGPT E3 re-audit.

## Footprint
- The throw-away diagnostic `tests/_m46_rm_diag_tmp.gd` was deleted.
- Fixtures are deleted by the suite.
- No temporary files remain.
- No other agent's process was touched.

**Status: AWAITING_AUDIT** (child RM-001). RM-002 follows under the master.
