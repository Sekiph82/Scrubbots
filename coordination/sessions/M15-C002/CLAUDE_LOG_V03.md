# M15-C002 — CLAUDE_LOG_V03

Cycle: **M15-C002** · Prompt: `CHATGPT_PROMPT_V03.md` · Task: **M15-C002-V03**
Finding set (frozen, same): **F-M15-STRICT-004**, **F-M15-STRICT-005**
Actor: CLAUDE · Handoff: **AWAITING_AUDIT** (no self-audit verdict claimed)

## 1. Environment / sync

- Godot: **4.7.1.stable.official.a13da4feb**.
- Synced starting `origin/main` SHA: **41045e3fc36c2aa12c5a68cfcd645811d6e59f37**
  (fast-forward; incoming M15-C002 V02 audit + V03 prompt/criteria did not touch
  any locally-modified file).
- Canonical state on sync matched the prompt (currentTaskId `M15-C002-V03`,
  workflowState `CHANGES_REQUIRED`, requiredActor `CLAUDE`, progress
  `278/719 = 38.66%`) → no `HIVEAI_STATE_CONFLICT`.
- Pre-existing owner working-tree changes preserved and NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`.

## 2. H!veAI start ordering (corrected from V02)

Per the V03 mandate, the start transition was pushed BEFORE any production/test
edit:
- `.hiveai/TASKS.md` `CHANGES_REQUIRED → IN_PROGRESS` (requiredActor CLAUDE,
  progress unchanged) + `.hiveai/EVENTS.jsonl` WORKFLOW_CHANGED row
  (id `f1e83610-1016-4159-b8fd-e1d407e0f9c9`);
- committed and pushed as **cb2b7a8** (`41045e3..cb2b7a8`);
- only then were `target_selector.gd` / tests edited.

The V02 local-ordering nonconformance was NOT repeated.

## 3. Frozen minimal correction (production, `target_selector.gd` only)

- **§1 / F-M15-STRICT-005.H — selection blocked during a bind transaction.**
  `select_and_reserve()` now returns `-1` immediately when `_in_selection OR
  _in_bind` is true, before any collaborator callback. A nested selection
  injected from a bind-time candidate/reservation `is_bound_to()` callback can no
  longer run against the OLD bundle and leave an orphan reservation while the
  outer bind is mid-commit.
- **§2 / F-M15-STRICT-005.I — post-targetability owner query is a full boundary.**
  After `is_targetable()`: coherence check → `get_target_for_owner()` →
  TYPE_INT validation → **coherence check again** → only then branch on owner
  assignment / verdict. Drift injected from the owner-query callback now stops the
  operation before any reserve or later-candidate targetability query, for
  true / false / non-bool verdicts. Same-owner no-later-query law preserved.
- **§3 / F-M15-STRICT-005.J — post-reserve ownership proof bracketed one callback
  at a time.** After `reserve()` true: coherence → `get_owner(idx)` → TYPE_INT
  (on malformed: exact rollback + return with **zero** target-proof callback) →
  coherence → `get_target_for_owner(owner_id)` → TYPE_INT → coherence → exact
  owner/target identity → return. Any malformed return or detected drift after any
  proof callback triggers exact-pair `release(idx, owner_id)` rollback and `-1`.

All accepted V01/V02 hardening (§4) preserved: real-BoardState bind category,
RefCounted dep/access categories, actual-bool coherence/targetability gates,
Variant/return-type validation, non-int candidate-entry guard, guard-before-first-
coherence, recursive-selection + nested-bind rejection, bind-in-progress guard,
is_reserved true/false coherence, mutation-before-malformed-reserve exact
rollback, get_owner-independent rollback, same-owner side-effect no-later-query,
contention law, deterministic order, no routing / no board or candidate mutation /
no full-board scan, `is_bound_to(board, reservation_state)` seam.

## 4. Adversarial coverage added (validation-first, direct observability)

`tests/run_tests.gd` → `_run_target_selector_strict_v05_tests()` (registered
after the V02 `_run_target_selector_strict_v04_tests`). New observability on
`tests/support/m15_reservation_double.gd`: `on_get_owner` hook and
`get_owner_calls` / `owner_query_calls` / `reserve_calls` counters.

- **005.H:** already-bound-A selector, outer `bind(B)`; nested selection injected
  from B candidate-coherence and B reservation-coherence callbacks each returns
  `-1`, makes zero targetability query, adds no A/B reservation; outer bind commits
  once; selector ends coherent with B; later selection on B succeeds.
- **005.I:** true-verdict candidate drift and ReservationState drift in the
  post-targetability owner query → `-1`, `reserve_calls == 0`, no reservation;
  false-verdict drift → `-1` with no later-candidate targetability query;
  non-bool-verdict drift → `-1`.
- **005.J:** ordered happy path (`get_owner` called once, after reserve);
  `get_owner` callback drifts candidate → `-1`, exact pair rolled back, unrelated
  `(9,777)` preserved, **target-proof query not invoked** (owner-query count
  unchanged past the post-targetability call); `get_owner` callback drifts
  ReservationState → `-1`, no orphan; target-proof callback drifts candidate →
  `-1`, exact pair rolled back, unrelated preserved; target-proof drifts
  ReservationState → `-1`, no orphan; malformed `get_owner` → `-1`, target-proof
  not invoked, exact pair rolled back, unrelated preserved.

Sensitivity proof (prompt §5): temporarily disabling the post-target-proof
coherence check (Step 5) made the target-proof-candidate-drift test FAIL
(selector returned `0` and left 2 reservations instead of `-1`/1). Restored;
full suite green again. This confirms the test fails if the coherence check is
removed.

## 5. Validation results

- Full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
  → **Total checks: 3024 · Failures: 0 · RESULT: ALL PASS**
  (V02 baseline 2984/0; +40 new V03 checks).
- Zero SCRIPT/Parse errors (two transient inference Parse Errors during
  development — untyped member access inferred with `:=` — were fixed by explicit
  `var x: int =`; final run clean).
- `git diff --check`: clean (only benign LF→CRLF notices).
- Pre-existing renderer-test resource-leak WARNINGs unchanged and unrelated.

## 6. Scope / governance

- Production changed: `scripts/gameplay/targeting/target_selector.gd` only.
- Tests/support changed: `tests/run_tests.gd`,
  `tests/support/m15_reservation_double.gd`.
- Not touched: BoardState, ColorCandidateIndex, ReservationState, routing,
  ScrubbotAgent, M19 dispatcher production; root `tasks.md` checkboxes;
  `coordination/AUDIT_INDEX.md`; any `CHATGPT_*` artifact; legacy H!veAI trackers;
  `.hiveai/PROJECT.json`/`.hiveai/RULES.md`.
- No self-audit verdict; audit disposition is ChatGPT-owned.

## 7. Commits / events

- Start transition: **cb2b7a8** (`CHANGES_REQUIRED -> IN_PROGRESS`), pushed
  `41045e3..cb2b7a8` BEFORE any production/test edit.
- Implementation + AWAITING_AUDIT handoff pushed after this log; see
  `.hiveai/EVENTS.jsonl` `IN_PROGRESS -> AWAITING_AUDIT` row
  (`9f8976a0-7712-4be0-b10b-6ae0db8d6954`). Per the non-self-referential final-SHA
  rule, no extra commit is made solely to embed this log's own commit SHA.

Handoff state: **AWAITING_AUDIT** (requiredActor CHATGPT).
