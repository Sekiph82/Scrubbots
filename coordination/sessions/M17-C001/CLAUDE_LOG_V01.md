---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M17-C001
version: 01
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C001/CHATGPT_PROMPT_V01.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C001/CHATGPT_AUDIT_CRITERIA_V01.md
startingCommit: b815b35438f140b5d2d5f87ca28188b632c5efdd
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS - Claude Log V01

Evidence for exactly CHATGPT_PROMPT_V01.md (M17-C001 Routing Prototype Lab).
Claude does not audit itself. This is a PROTOTYPE/COMPARISON cycle: no
production routing algorithm is selected; the OWNER movement-language design
gate remains OPEN.

## Inputs read

- `CLAUDE.md` (all owner overrides, incl. GitHub-only logging M12-C001,
  coordination-ownership normalization M10-C001 V05).
- `coordination/sessions/M17-C001/CHATGPT_PROMPT_V01.md` and
  `CHATGPT_AUDIT_CRITERIA_V01.md`.
- M16 route contract: `scripts/gameplay/routing/{routing_system,route_request,
  route_result,route_validator}.gd`, `scripts/debug/route_debug_overlay.gd`,
  test doubles `tests/support/route_*`.
- `scripts/gameplay/board/board_state.gd`, `scripts/debug/board_debug_fixtures.gd`.
- `docs/05_TECH_DECISIONS.md` ADR-024, `docs/01_GAMEPLAY_SPEC.md` (movement
  language `[TO BE DESIGNED]`), `docs/00_PROJECT_BRIEF.md` "Why robot movement
  matters".
- `tests/run_tests.gd` structure/helpers.
- Owner reference inbox `assets/art/references/_owner_inbox/README.md` + listing.

## Repository start state

- Branch `main`, synced to `origin/main` @ `b815b35` via `git merge --ff-only`
  (18 behind, 0 ahead; fast-forward only, no destructive ops).
- Pre-existing owner working-tree change **preserved, not staged**:
  `M project.godot` (editor key reorder + comment rewrite; incoming commits do
  not touch it — verified before sync). Also left untouched: a pre-existing
  stray temp file from another session and untracked `.uid`/`.import`
  sidecars and `_owner_inbox` intake files.

## Prior audit feedback / AL learnings applied

- **AL-001** explicit `preload()` in every new script (no bare `class_name`).
- **AL-003 / performance discipline** CPU-only timing; no FPS/GPU claims (a test
  asserts the benchmark dict has no `fps`/`gpu` keys).
- **AL-004** rectangular + max-size coverage (S7 59×59, S8 53×59).
- **AL-005** direct evidence: real headless runs recorded, not file existence.
- **AL-009** each prompt-required check listed separately below, not just the
  aggregate total.
- **AL-011** negative tests assert the specific `NO_ROUTE` reason + retained
  target, not just "not success".
- **AL-018** direct observability: tests assert every emitted segment is
  accepted by access truth, and inspect exact route points for determinism.
- **AL-020** no mutable-state leakage: routes are detached value objects; BoardState
  passed as argument; snapshots prove no mutation.
- **AL-026** owner/local work preserved (project.godot untouched).
- **AL-027** ACTIVE/CLEARED model honoured in the experimental access truth.
- **AL-028** candidate != reachable; enclosed target → no dispatch/route, no
  silent retarget (S3).
- **AL-033** palette v2 unaffected (no artwork/palette changes).

## Work performed

Three EXPERIMENTAL prototypes behind the locked M16 `compute_route(request,
board, access_query) -> RouteResult` contract, plus experimental access truth,
metrics, scenarios and a debug lab. Nothing wired into production gameplay.

New files:
- `scripts/gameplay/routing/prototypes/prototype_access_query.gd` — experimental
  access truth. Translates BoardState ACTIVE/CLEARED into segment traversability
  (`is_segment_traversable`) + a `classify_cell`/`cell_of_point` topology seam.
  Non-target ACTIVE blocks; CLEARED open; outside-board open; assigned ACTIVE
  target enterable ONLY when the segment's `to` is the target centre (final
  endpoint). Sampled at 0.1 cell. No selection/reservation/mutation.
- `scripts/gameplay/routing/prototypes/direct_route_prototype.gd` — Prototype A.
  Single straight `[start, target]`; succeeds only if accepted; else NO_ROUTE;
  never detours/retargets.
- `scripts/gameplay/routing/prototypes/grid_route_prototype.gd` — Prototype B.
  Deterministic BFS, 4-neighbour cell-centre lattice, fixed neighbour order
  (up,right,down,left). Exterior slot origins enter via a nearest-first, capped
  (`MAX_ENTRIES=12`), validated perimeter bridge (documented, not hidden).
  Target reachable only as final step.
- `scripts/gameplay/routing/prototypes/organized_route_prototype.gd` — Prototype
  C. Post-process of the grid path: collinear reduction → validated greedy
  shortcut → validated quadratic-bezier corner rounding; invalid
  simplification/curve falls back to the last valid section (never accepted).
  Exposed params: `enable_shortcut`, `enable_rounding`, `corner_radius=0.35`,
  `corner_samples=3`.
- `scripts/gameplay/routing/prototypes/route_metrics.gd` — distance,
  proper-crossing count (shared-endpoint policy explicit), congestion
  (occupied/max_overlap/total_repeated), CPU benchmark (µs only), determinism
  compare. Static, algorithm-agnostic.
- `scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd` — deterministic
  S1..S8 builders + multi-route request generation (targets assigned OUTSIDE
  routing).
- `scripts/debug/routing_lab/routing_lab_overlay.gd` — Node2D that draws the
  board + all routes in ONE `_draw` (no per-cell nodes). Draws only; computes
  nothing.
- `scripts/debug/routing_lab/routing_prototype_lab.gd` + `scenes/debug/
  routing_prototype_lab.tscn` — the Routing Prototype Lab (Control containers).
  Strategy / scenario / bot-count selectors, route-visibility, curved-rounding
  and S4-clear toggles, rebuild, metric panel, success/no-route counts. No
  source editing required to switch prototypes. Performs NO target selection and
  mutates no production gameplay.

Modified:
- `tests/run_tests.gd` — 7 new M17 suites appended (+118 checks).

Deliberately NOT done: no ADR added. ADR-024 unchanged. Adding an ADR now would
risk reading as a routing selection; the lab is experimental and the owner
design gate is open (prompt "Documentation / ADR"). No ScrubbotAgent /
Dispatcher / spawn / movement playback / arrival / vertical slice / route-
completion clearing (M18+ non-scope).

## Files changed

Added (source): the 8 files under
`scripts/gameplay/routing/prototypes/` and `scripts/debug/routing_lab/`, plus
`scenes/debug/routing_prototype_lab.tscn`.
Added (coordination): `coordination/sessions/M17-C001/CLAUDE_LOG_V01.md`,
`coordination/sessions/M17-C001/ROUTING_COMPARISON_V01.md`.
Modified: `tests/run_tests.gd`.
NOT staged (owner/local): `project.godot`; untracked `.uid`/`.import`/inbox/
stray-temp files.

## Validation evidence

Environment: `godot --version` → `4.7.1.stable.official.a13da4feb`.

Full suite: `godot --headless --path . -s res://tests/run_tests.gd`
→ **Total checks: 1384, Failures: 0, RESULT: ALL PASS** (baseline before M17 was
1266; +118 M17 checks). `git diff --check` → clean (only benign LF→CRLF notices).

Prompt "Required tests" (§488-530) mapping — each verified in the run above:

1. all three satisfy compute_route signature — `_run_m17_prototype_contract_tests` PASS.
2. all three keep target identity — same suite (target_index retained) PASS.
3. all three preserve BoardState — snapshot equal before/after PASS.
4. all three preserve ReservationState — reserved owner unchanged PASS.
5. direct succeeds on open segment — `_run_m17_direct_tests` PASS.
6. direct fails cleanly on blocked segment (NO_ROUTE, empty pts, target kept) PASS.
7. grid succeeds on deterministic detour (S2) — `_run_m17_grid_tests` PASS.
8. grid fails on fully enclosed target (S3, NO_ROUTE, same target) PASS.
9. newly-opened-after-clear makes same target routable (S4) PASS.
10. grid deterministic repeated points (exact equality) PASS.
11. organized valid route from valid source path — `_run_m17_organized_tests` PASS.
12. organized deterministic repeated points PASS.
13. organized simplification never crosses a blocked segment (every segment
    accepted by access truth, directly asserted) PASS.
14. invalid simplification falls back safely (detour kept, >2 pts, validates) PASS.
15. every success passes shared RouteValidator (contract + scale suites) PASS.
16. no prototype calls TargetSelector (no select_and_reserve method) PASS.
17. no prototype retargets (failure retains target_index) PASS.
18. no prototype mutates BoardState (snapshots) PASS.
19. no prototype clears cells (snapshots equal) PASS.
20. route distance metric correctness (3+4=7; total/mean/median) PASS.
21. crossing metric correctness (X→1, parallel→0) PASS.
22. shared-endpoint crossing policy (shared start→0) PASS.
23. overlap/congestion metric (shared corridor max_overlap=2, repeated>0) PASS.
24. CPU harness executes with no FPS/GPU claim (no fps/gpu keys) PASS.
25. determinism metric catches a deliberately changed route PASS.
26. 5-route comparison (S5×5) — `_run_m17_scale_tests` PASS.
27. 10-route comparison (S5×10) PASS.
28. 25-route comparison (S5×25) PASS.
29. stress route set >25 (S6×50) PASS.
30. 59×59 scenario (S7) PASS.
31. rectangular Very Hard scenario (S8 53×59) PASS.
32. blocked-interior regression (S3) PASS.
33. newly-opened-after-clear regression (S4) PASS.
34. debug lab switches all three strategies — `_run_m17_lab_scene_smoke` PASS.
35. debug lab exposes metrics/state without target selection PASS.
36. debug lab does not modify production gameplay (own boards; no session) PASS.
37. full Godot 4.7.1 regression suite passes (1384/0) PASS.
38. headless smoke for the lab scene (instantiate, drive, assert metrics) —
    included in the suite as `_run_m17_lab_scene_smoke` PASS.

Neutral comparison numbers (distance/crossings/congestion/CPU/determinism across
S1..S8, all strategies) recorded in `ROUTING_COMPARISON_V01.md`. CPU is route
computation microseconds only — no FPS/GPU claim.

Semantic regressions (direct evidence, headless):
- Blocked interior: S3 → all three NO_ROUTE, target index retained.
- Newly-opened-after-clear: S4 grid before=NO_ROUTE, after clearing prerequisite
  cells (row 5, x=0..4) = success to the SAME target, route validates.

## Failures and fixes

- Parse error: `var start_cell := <ternary>` could not infer type under headless
  GDScript → changed to an explicit `var start_cell: Vector2i` if/else. Fixed;
  re-verified. (An earlier full-suite scratch run appeared to "hang" — it was
  this compile failure on a `-s` script, not a runtime loop.)
- First grid design tested a straight bridge to EVERY perimeter cell → ~192
  µs×10³ per route on 59×59, swamping the CPU metric. Replaced with a
  nearest-first, capped (`MAX_ENTRIES=12`) perimeter bridge → ~6 ms/route on
  59×59; BFS still detours internally. Documented as experimental exterior model.

## Task/docs/coordination/H!veAI updates

Per M10-C001 V05 coordination-ownership normalization, Claude did **NOT** modify
`tasks.md`, `coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, any
`.hiveai/*` tracker/dashboard, or any `CHATGPT_AUDIT_*`. No ADR change. Only
this `CLAUDE_LOG_V01.md` and `ROUTING_COMPARISON_V01.md` were written as
coordination evidence.

SB-M17-001..016 objective evidence:
- 001 Direct baseline — direct prototype + tests. Done.
- 002 Grid-aware — grid prototype + tests. Done.
- 003 Organized polyline/curved — organized prototype + tests. Done.
- 004 Visual clarity — neutral proxies + lab; **owner-preference, gate open.**
- 005 Path crossings — metric + test + table. Done.
- 006 Congestion — metric + test + table. Done.
- 007 CPU cost — benchmark + table (CPU only). Done.
- 008 Route distance — metric + test + table. Done.
- 009 Determinism — metric + test + table. Done.
- 010 Original visual direction — **BLOCKED_BY_MISSING_OWNER_REFERENCE** (spec
  marks movement language `[TO BE DESIGNED]`; no authoritative movement
  reference exists; inbox images are unclassified, not substituted).
- 011 5 bots — S5×5. Done. 012 10 bots — S5×10. Done. 013 25 bots — S5×25. Done.
- 014 stress — S6×50. Done. 015 59×59 — S7. Done. 016 rectangular VH — S8. Done.

ChatGPT owns whether these checkboxes close; the milestone stays in
OWNER_DESIGN_GATE.

## Commit and push evidence

Committed the M17 source + scene + tests + coordination logs on `main`; owner's
`project.godot` and untracked sidecars intentionally excluded. Safe push to
`origin/main` (no reset/clean/force). Exact final commit SHA reported to the
owner in the session hand-back (not re-embedded here per the non-self-referential
final-SHA rule).

## Handoff

**AWAITING_AUDIT.** No self-audit performed. No prototype promoted to production;
M16 base contract intact; OWNER_DESIGN_GATE for the final movement language
remains OPEN. After ChatGPT audit, the owner selects the final movement language.
