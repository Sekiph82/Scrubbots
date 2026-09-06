---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M17-C002
version: 01
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C002/CHATGPT_PROMPT_V01.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C002/CHATGPT_AUDIT_CRITERIA_V01.md
startingCommit: 72ea92f
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS - Claude Log V01 (M17-C002)

Evidence for exactly CHATGPT_PROMPT_V01.md (M17-C002 "Promote Owner-Selected
Routing to Production"). Claude does not audit itself.

## Inputs read

- `coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md`
  (**OWNER_SELECTS_ORGANIZED**: Organized/curved movement language + grid-aware
  deterministic backbone; Direct = debug only; conservative curves; never
  sacrifice validity).
- `coordination/sessions/M17-C002/CHATGPT_PROMPT_V01.md` + audit criteria V01.
- `coordination/sessions/M17-C001/CHATGPT_AUDIT_V01.md`, `ROUTING_COMPARISON_V01.md`,
  `CLAUDE_LOG_V01.md`.
- M16 contract + ADR-024 (`docs/05_TECH_DECISIONS.md`), `docs/01_GAMEPLAY_SPEC.md`.
- M17 prototypes/lab (`scripts/gameplay/routing/prototypes/`, `scripts/debug/routing_lab/`).

## Repository start state

- `git fetch` + `git merge --ff-only origin/main`: 25 behind, 0 ahead →
  fast-forwarded to `72ea92f` (no reset/clean/force).
- Pre-existing owner working-tree changes **preserved, not staged**:
  `M project.godot` and `M scenes/debug/routing_prototype_lab.tscn` (owner
  regenerated the lab scene uid; incoming commits touch neither — verified before
  sync). Untracked `.uid`/`.import`/inbox files left untouched.

## Prior audit feedback / AL learnings applied

- AL-001 explicit preload in new production scripts.
- AL-003 CPU/perf discipline; no FPS/GPU claims.
- AL-004 rectangular + max-size coverage (59×59, 53×59).
- AL-005 direct headless evidence.
- AL-009 each required check listed separately below.
- AL-011 negative tests assert specific NO_ROUTE + retained target.
- AL-018 direct observability (every emitted segment asserted traversable; exact
  point comparison for determinism; measured conservative-vs-experimental deltas).
- AL-020 detached route data; BoardState passed as arg; snapshots prove no mutation.
- AL-026 owner/local work preserved.
- AL-027 ACTIVE/CLEARED. AL-028 candidate != reachable; enclosed → no route.

## Work performed

Promoted the owner-selected direction into PRODUCTION scope (outside
`prototypes/`), independent of experimental code:

New files:
- `scripts/gameplay/routing/production_access_query.gd` — canonical production
  access truth (ACTIVE blocks, CLEARED/outside open, target only as final
  endpoint). Provides `is_segment_traversable` + `classify_cell`/`cell_of_point`.
- `scripts/gameplay/routing/production_routing_system.gd` — `ProductionRoutingSystem`
  (subclasses M16 `RoutingSystem`). Backbone = deterministic grid-aware BFS
  (4-neighbour, fixed order, nearest-first capped exterior bridge). Movement
  language = validity-preserving organized/curved post-process (collinear reduce
  → **bounded** shortcut → controlled corner rounding). Every emitted segment
  re-checked through access truth; invalid shortcut/curve falls back. Never
  selects/retargets; never mutates BoardState/ReservationState.
  Conservative production defaults: `max_shortcut_span = 2` (experimental =
  unbounded), `corner_radius = 0.25` (experimental = 0.35), `corner_samples = 3`.

Docs:
- `docs/05_TECH_DECISIONS.md` — added **ADR-025** (owner-selected production
  movement language; Direct rejected; prototypes retained for diagnostics).
- `docs/01_GAMEPLAY_SPEC.md` — updated "Target selection vs. routing" and the
  movement-language paragraph from `[TO BE DESIGNED]` to the owner-selected
  production routing (ADR-025).

Tests:
- `tests/run_tests.gd` — new `_run_m17c002_production_routing_tests` (+28 checks).

Retained (not deleted): M17 experimental prototypes, Routing Prototype Lab, and
`ROUTING_COMPARISON_V01.md`. Direct kept ONLY in `prototypes/`.

## Files changed

Added: `scripts/gameplay/routing/production_access_query.gd`,
`scripts/gameplay/routing/production_routing_system.gd`,
`coordination/sessions/M17-C002/CLAUDE_LOG_V01.md`.
Modified: `tests/run_tests.gd`, `docs/05_TECH_DECISIONS.md`,
`docs/01_GAMEPLAY_SPEC.md`.
NOT staged (owner/local): `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
untracked `.uid`/`.import`/inbox files.

## Validation evidence

Environment: `godot --version` → `4.7.1.stable.official.a13da4feb`.
Full suite: `godot --headless --path . -s res://tests/run_tests.gd`
→ **Total checks: 1412, Failures: 0, RESULT: ALL PASS** (was 1384; +28 C002).
`git diff --check` → clean (only benign LF→CRLF notices).

Prompt §8 required-test mapping (each verified in the run above):
- production route derives from a valid grid route — S2 detour, >2 pts, validates. PASS.
- blocked target → no route — S3 NO_ROUTE, target retained. PASS.
- opened-after-clear → same target routes — S4 before=NO_ROUTE, after=success, same target. PASS.
- no BoardState mutation — snapshot equal. PASS.
- no ReservationState ownership mutation — reserved owner unchanged. PASS.
- deterministic repeated points — exact equality. PASS.
- no invalid diagonal shortcut accepted — every emitted segment asserted
  traversable; all routes RouteValidator-clean. PASS.
- production defaults more conservative than M17 experimental — on 59×59:
  production points 265 > experimental 85; production distance 1141.0 ≥
  experimental 982.5; production max segment 42.4 < experimental 66.1; plus
  `max_shortcut_span` bounded and `corner_radius` 0.25 < 0.35. PASS.
- 59×59 coverage — all 25 production routes succeed + validate. PASS.
- rectangular VH 53×59 coverage — all 25 succeed + validate. PASS.
- full Godot regression suite passes — 1412/0. PASS.

Audit-criteria coverage (objective): 1 organized+grid implemented; 2 production
outside prototypes/; 3 Direct not promoted (kept in prototypes/ only); 4 M16
contract intact; 5 target identity fixed; 6 no retarget; 7 no BoardState
mutation; 8 no ReservationState mutation; 9 derived from grid reachability; 10
every segment validated; 11 blocked→no route; 12 opened-after-clear same target;
13 determinism; 14 no invalid shortcut; 15 conservative defaults proven; 16
59×59; 17 rectangular VH; 18 lab/prototypes/comparison retained; 19 current-law
docs updated; 20 ADR-025 added; 21 no M18+ leakage; 22 tasks.md untouched; 23
H!veAI/SESSION_INDEX/AUDIT_INDEX untouched; 24 this log; 25 no self-audit.

## Failures and fixes

None. Suite green on first full run after implementation; a pre-commit probe
confirmed the conservative-vs-experimental deltas before wiring the assertions.

## Task/docs/coordination/H!veAI updates

Per M10-C001 V05, Claude did NOT modify `tasks.md`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, any `.hiveai/*`, or any `CHATGPT_AUDIT_*`.
Docs updated: ADR-025 + gameplay spec (current-law). No M18+ implementation.

## Commit and push evidence

Committed production routing + docs + tests + this log on `main`; owner's
`project.godot` and `routing_prototype_lab.tscn` and untracked sidecars excluded.
Safe push to `origin/main` (no reset/clean/force). Final commit SHA reported in
the session hand-back (not re-embedded per the non-self-referential final-SHA rule).

## Handoff

**AWAITING_AUDIT.** No self-audit. Owner-selected Organized/curved + grid-aware
backbone is now production routing (ADR-025); Direct remains debug-only; M16
contract intact; M17 lab/prototypes/comparison retained. M18 may open after audit.
