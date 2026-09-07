---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M18-C001
version: 02
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M18-C001/CHATGPT_PROMPT_V02.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M18-C001/CHATGPT_AUDIT_CRITERIA_V02.md
startingCommit: 4e7fcade988284825f1d8e2cc01bbbcfb87f8936
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS — Claude Log V02

Evidence for exactly CHATGPT_PROMPT_V02.md (M18-C001, Strict Adversarial
Validation / Correction). Fixes ONLY the three strict re-audit findings. No M19,
no M20. Claude does not audit itself.

## Inputs read

- CLAUDE.md (all owner overrides).
- coordination/AUDIT_INDEX.md.
- coordination/sessions/M18-C001/CHATGPT_STRICT_REAUDIT_V02.md (F-M18-STRICT-001/002/003).
- coordination/sessions/M18-C001/CHATGPT_AUDIT_V01.md, CHATGPT_PROMPT_V02.md, CHATGPT_AUDIT_CRITERIA_V02.md.
- coordination/sessions/M19-C001/CHATGPT_BLOCKER_NOTE_V01.md (M19 paused behind this gate).
- scripts/gameplay/agents/scrubbot_agent.gd (source under correction).
- scripts/gameplay/routing/route_request.gd, route_result.gd, production_routing_system.gd, production_access_query.gd.
- scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd (scenario/route builders reused).
- tests/run_tests.gd (harness + existing M18 blocks), scripts/debug/scrubbot_agent_debug.gd, scripts/gameplay/dispatch/scrubbot_dispatcher.gd (confirmed it makes a fresh agent per dispatch → single-use gate is safe).
- docs/05_TECH_DECISIONS.md (ADR-026).

## Repository start state

- Branch `main`, synced to `origin/main` via `git fetch` + `git merge --ff-only`
  (0 ahead / 6 behind → fast-forwarded to `4e7fcad`). Confirmed the 6 incoming
  (docs-only) commits touch none of the owner-modified files before ff. No
  destructive ops.
- Owner-modified tracked files present at start and PRESERVED / NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`. Untracked owner/generated artifacts
  (`*.uid`, `_owner_inbox/*.import`, scratchpad file) left untouched. No `*.uid`
  is tracked in the repo, so generated `.uid` files stay untracked.

## Corrections implemented

### F-M18-STRICT-001 — single-use lifecycle (SB-M18-001, AL-037)

`scripts/gameplay/agents/scrubbot_agent.gd`:

- `assign()` now returns false immediately when `_state != State.UNASSIGNED`,
  BEFORE touching any field. A second assign while MOVING/ARRIVED/CANCELLED
  fails closed and preserves state, owner_id, color_id, target_index,
  spawn_origin, target_position, route points, movement progress, current
  position, and completion-emitted truth. No second completion can arise.
- `cancel()` is terminal-safe: it no-ops when already `CANCELLED` **or**
  `ARRIVED` (previously it downgraded ARRIVED→CANCELLED). MOVING/UNASSIGNED →
  CANCELLED; repeated cancel is a no-op; cancel after ARRIVED never downgrades
  or alters completion truth.
- Docstrings + ADR-026 amended with the single-use lifecycle policy.
- Safe against existing callers: the dispatcher (M19) and debug scene both
  instantiate a fresh agent per use; existing malformed-data rejection tests use
  fresh throwaway agents (still UNASSIGNED), so the gate does not mask their
  intent.

### F-M18-STRICT-002 — observable multi-segment movement (SB-M18-006, AL-038)

New `_run_m18_multisegment_movement_tests()` with a deterministic handcrafted
route `(0,0)->(1,0)->(1,1)->(3,1)` (segment lengths 1, 1, 2; total 4):

- asserts the three known segment lengths (>=3 segments);
- one `advance(2.5)` at speed 1.0 provably crosses boundary@1.0 and boundary@2.0
  and lands at EXACTLY `(1.5, 1.0)` on the third segment, progress exactly
  `0.625`, still MOVING, no completion — this assertion FAILS if movement only
  advanced within a single segment;
- a subsequent huge `advance(100.0)` crosses all remaining route and exact-snaps
  to `(3,1)`, ARRIVED, with completion emitted exactly once; a further advance
  emits no second completion.

### F-M18-STRICT-003 — isolated performance evidence (SB-M18-014/015, AL-036)

Rewrote `_run_m18_agent_stress_tests()` to isolate agent-lifecycle cost:

- ALL routes are computed AND verified successful BEFORE the timer starts
  (a gated `_check_eq(routes_ok, reqs.size(), …)` precondition);
- the timed region contains ONLY: `ScrubbotAgent.new()` (alloc) + signal hookup
  + `assign()` + deterministic movement-to-completion + `free()`;
- route-generation time is measured and printed SEPARATELY and labelled;
- explicit "headless CPU only, no FPS/GPU/mobile-frame" wording;
- pooling wording limited to what this headless lifecycle test shows.

Isolated measurements (this run):

```
M18 lifecycle-ISOLATED 5-agent:  alloc+assign+move+free CPU=0.25 ms | route-gen (separate)=33.46 ms
M18 lifecycle-ISOLATED 10-agent: alloc+assign+move+free CPU=0.40 ms | route-gen (separate)=69.21 ms
M18 lifecycle-ISOLATED 25-agent: alloc+assign+move+free CPU=1.05 ms | route-gen (separate)=192.65 ms
M18 lifecycle-ISOLATED 40-agent: alloc+assign+move+free CPU=1.04 ms | route-gen (separate)=434.41 ms
```

Route generation (tens–hundreds of ms) dominated the old mixed number and is NOT
agent-lifecycle cost. Agent lifecycle for 40 agents is ~1 ms of headless CPU.
Pooling NOT added — no justification under this isolated test.

## Adversarial lifecycle tests added

New `_run_m18_agent_lifecycle_reentry_tests()` proves (using a SECOND
independently-valid route, first shown to assign on a fresh agent, so rejections
are pure re-entry — not malformed data):

1. valid first assign from UNASSIGNED succeeds → MOVING;
2. valid second assign while MOVING fails;
3. MOVING re-entry preserves state/owner/color/target/spawn/target_position/
   route points/progress/position and emits no completion;
4. after arrival, valid second assign fails;
5. ARRIVED state + endpoint position + completion count (==1) preserved;
6. after cancel, valid second assign fails;
7. CANCELLED state/position/identity preserved;
8. cancel after ARRIVED is a no-op (ARRIVED not downgraded, completion truth
   intact);
9. agent reuse cannot emit a second completion (extra advancing keeps count 1).

## Regression / invariants preserved

All prior M18 invariants remain green: no BoardState mutation, no
ReservationState mutation, no target selection, no route computation inside the
agent, no return/carrying, cancel-before-arrival blocks completion, no
child/tween/timer orphan, 59×59 + rectangular VH coordinate compatibility, debug
scene smoke. No M19/M20 code added or changed in this cycle (the M19 dispatcher
from cycle M19-C001 already in-repo is untouched here).

## Validation evidence

- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd`:

  ```
  ==== SCRUBBOTS test summary ====
  Total checks: 1609
  Failures: 0
  RESULT: ALL PASS
  ```

  (Full suite; adds the three strict blocks with zero failures. The PNG
  "Unicode parsing error" lines are pre-existing owner `_owner_inbox` reference
  imports, unrelated to this change.)
- `git diff --check` → clean (only benign LF→CRLF advisory warnings).

## Governance / boundaries honored

- Did NOT modify: tasks.md, `.hiveai/*`, coordination/SESSION_INDEX.md,
  coordination/AUDIT_INDEX.md, any CHATGPT audit/re-audit file.
- No self-audit, no verdict assigned. AL-036/037/038 registry lives in
  ChatGPT-owned coordination artifacts and was NOT edited; the ids are referenced
  in code comments/ADR only.
- Owner-modified working-tree files preserved and unstaged. No destructive git
  ops. No secrets. ADR-026 amended per hard rule 19.

## Files changed in this cycle

- M `scripts/gameplay/agents/scrubbot_agent.gd` (single-use assign gate; terminal-safe cancel)
- M `tests/run_tests.gd` (new re-entry + multi-segment tests; isolated stress; registration)
- M `docs/05_TECH_DECISIONS.md` (ADR-026 amendment)
- A `coordination/sessions/M18-C001/CLAUDE_LOG_V02.md`

## Handoff

State: **AWAITING_AUDIT**. ChatGPT owns the independent audit and all
SESSION_INDEX / H!veAI / dashboard / AUDIT_INDEX updates. Per the strict criteria,
if V02 passes, SB-M18-001/006/014/015 re-close and M19 may resume.
