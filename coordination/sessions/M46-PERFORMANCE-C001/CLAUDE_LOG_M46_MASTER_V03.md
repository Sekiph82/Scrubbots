# CLAUDE_LOG_M46_MASTER_V03 — joint report for `CHATGPT_M46_MASTER_REMEDIATION_V03.md`

Children: `CLAUDE_LOG_M46_RM005_V01.md` (completion / terminal frame) and `CLAUDE_LOG_M46_RM006_V01.md` (proof diagnostics / Selector availability / +1 reason). Prior M46 logs RM001–RM004 unchanged and still cited for their scope. Implementer evidence only (E1/E2); no audit verdict, root `TASKS.md` and all `CHATGPT_*` files untouched, no self-awarded PASS.

## Provenance
- **Final source SHA: `b36d48fa37e73e37350bd9b0bd817901b24fcc2e`** (`ce67212c` RM005 → `b36d48fa` RM006), on top of `origin/main` `9663c44c` (no newer upstream commit at push time). Logs are committed after it (log-only commit).
- Branch pushed: `claude/practical-darwin-ndbmxa` (the session's required branch; the prompt names `main` — merging is the owner's / ChatGPT's step).
- Environment: **Claude Code cloud container, Linux, headless Godot 4.7.2 stable `ed1daf0bf`** — not the owner's Windows checkout. Every number below is this container's CPU; desktop V03 numbers are quoted for comparison only. **OWNER_LOCAL_PROJECT_PARITY_OPEN.** Godot's import rewrite of `project.godot` was discarded after every run, never committed.
- Zero GitHub Actions (no dispatch / validation_only / rerun), no network, no clone / worktree / reset / clean / force, no owner file touched, scratch < 2 MiB. Cloud CI: **CLOUD_CI_DEFERRED_COST_FREEZE**.

## Single full M46 run on the final source (MV3-06)
`godot --headless --path . -s res://tests/m46_performance.gd` at `b36d48fa`, 2026-10-21 20:28:35 → 20:32:19 UTC, no other Godot process: **`M46 performance evidence: PASS (22/22 cases, 0 fail)`, exit 0, 224 s.**
| Gate | Value | Budget |
|---|---|---|
| SB-M46-013 full 59x59 level | mean 1.084 / p95 3.363 / p99 4.659 / max 19.058 ms | mean ≤ 4.0, p99 ≤ 16.7 (unchanged) |
| p16 pocket | mean 0.935 / p99 4.372 / max 18.202 ms, peak agents 117 | |
| p17 6 slots + Tornado | mean 1.198 / p99 4.955 / max 21.369 ms; Tornado 24.65 ms | report |
| p18 maze | mean 1.633 / p99 6.684 / max 25.084 ms | report |
| p19 FX FULL / REDUCED | p99 5.175 / 4.892 ms; Spark self-free 950 ms | |
| SB-M46-012 30 retries (p12) | **worst 23.19 ms**, nodes 292 → 292, objects −2 | ≤ 50.1 (unchanged) |
| SB-M46-014 density | 114 agents (114 nodes, 114 reserved) | ≥ 90 |
| p21 400 ms budget | worst call 408 ms; still-moment completion tick **28 / 26 ms** (was 3293 / 2931 ms desktop) | ≤ budget + 200 |
| p22 5 s off-frame | Selector popup settles 2057 / 2305 ms with **109 / 98 chips proven** (all batches), worst frame 3.8 / 3.1 ms; HUD Random 109 / 126 ms | 5 s cap unchanged |
Max spikes are reported separately as before; no threshold was edited.

Affected regressions on the final source content (sequential, one Godot at a time): **45/45 exit 0** — list in `CLAUDE_LOG_M46_RM006_V01.md` §4 (M27 ×3, M30 ×3, M39 ×12, M28 ×2, M43 ×6, M44, M46 RM002–RM006 + R07 + slot rebuild, M55 ×5, CP04–CP06, M53 first10, run_tests).

## V3-F01..F07 reconciliation
| Finding | Disposition | Evidence |
|---|---|---|
| **V3-F01** 59x59 quiescent classifier 2.9–3.3 s on the main thread | **Fixed, exact output.** Root: the progress search fully cascaded every sibling placement (120 routes / masks per classification) though one clearing child decides STALLED. Deferred children + first-clear probe + no duplicate root quiesce. 1.3–1.7 s → 24–50 ms here; full-run p21 completion tick 26–28 ms. LOST still only on a fully proven DEADLOCK; 129-state oracle equivalence dict-equal (STALLED / PROGRESSABLE / DEADLOCK / UNKNOWN_BOUND, 5/6 slots, WAITING, VOID, 3/4/5 columns) | RM005 §1–4, T1/T2/T3, mutants N1–N5 |
| **V3-F02** L1 WON terminal tick 193.66 cold / 82.70 warm | **Warm fixed** (re-validating the whole builtin catalog on every Results: 15–19 ms → cached 0.09 ms; warm 26–28 → 9.5–17 ms here). **Cold: OWNER_DECISION_REQUIRED** — first-use decode of the lossless 1.2k² Results art (~144 ms) + row icons (~59 ms); options A keep / B prewarm (+~6.3 MB RAM per texture during play) / C re-import (changes owner art) presented once in RM005 §3, nothing implemented | RM005 §1.3, §3, T4, N4 |
| **V3-F03** Selector partial prefix 29/118 at offset 0 | **Fixed.** Verdict-only booster proofs (root cascade stops at the first clear; same status) make one 59x59 batch proof 17–33 ms: all 118 batches proven in 2.3–2.7 s inside the unchanged 5 s cap; a list that still gets cut resumes after the last cut on the next genuine state (0 → 25 → 51 → 82 vs control 0 → 0 → 0 → 0), never re-proving an unchanged state; chips proven-only, cap 12, supply order | RM006 §2 S1, S1a/S1b, M1–M3 |
| **V3-F04** deep script error labelled completed | **Fixed for every source-detectable case** (`worker_internal_error` + `preflight_failed` / `malformed_proof_state` / `malformed_proof_result` / `script_error` via an engine `Logger` on the worker thread), all fail closed as `proof_timeout`, no same-state restart. **NOT_VERIFIED_ENGINE_LIMITATION** for interpreter errors a release export template does not report | RM006 §2 S2, S2 rows, M4/M5 |
| **V3-F05** second +1 blank reason | **Fixed:** internal `plus_one_used` on SB, owned-charge and HUD paths; no spend / slot / receipt change; no visible text change; no seventh slot | RM006 S3, M6/M7 (M7a masked by defense in depth) |
| **V3-F06** owner / environment items | **OPEN** (unchanged, owner-only): real F5 "Checking…" / HUD hold / "Booster saved!" review, phone GPU / heat / portrait / device tests, owner-local `project.godot` runtime parity, cloud CI (cost freeze) | — |
| **V3-F07** p12 43.46 ms vs 50.1 watch | **Within bound, not weakened:** 23.19 ms here (RM005 T5 20.15 ms); desktop value needs the owner's local run. Retry runs no classifier synchronously | full run, RM005 T5 |

## Master criteria (implementer view)
| ID | Status | Note |
|---|---|---|
| MV3-01 | PASS (E2) / cold Results OWNER_DECISION_REQUIRED | RM005 |
| MV3-02 | PASS (E2) | RM006 S1 |
| MV3-03 | PASS (E2) for source-detectable; NOT_VERIFIED_ENGINE_LIMITATION (release templates) | RM006 S2 |
| MV3-04 | PASS (E2) | RM006 S3 |
| MV3-05 | PASS (E2) | RM005 N1–N5, RM006 M1–M7 (M7a masked); all reverted byte-identical. Test seams kept in production code are inert and disclosed: new stages of the pre-existing `set_fault_injector` seam, `SolvabilitySolver.full_progress_cascade` oracle switch (default false) |
| MV3-06 | PASS (E2), Linux container | 22/22 exit 0 at `b36d48fa` + 45/45 suites |
| MV3-07 | ChatGPT's | — |
| MV3-08 | OPEN items stated | F5, phone GPU, owner-local parity, cloud CI; Need-a-Hand untouched (still unbudgeted, deterministic) |
| MV3-09 | complied | TASKS / CHATGPT files untouched |
| MV3-10 | complied | the one owner choice (cold Results art) presented once with exact options, not implemented |

## Local pull (owner Windows checkout)
After review, in `C:\Users\sekip\Desktop\ScrubBots` with the owner's local edits kept: `git fetch origin claude/practical-darwin-ndbmxa` then `git merge --ff-only origin/claude/practical-darwin-ndbmxa` only if the branch has been merged / the owner wants it; no reset, stash or force needed for these files (none of them is owner-modified).

Status: **AWAITING_CHATGPT_FULL_M46_REAUDIT**
