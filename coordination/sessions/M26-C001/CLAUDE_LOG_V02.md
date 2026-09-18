# M26-C001 V02 — CLAUDE IMPLEMENTATION LOG

Repository: `Sekiph82/Scrubbots`
Branch: `claude/m26-c001-v02-remediation-9jvis8`
Milestone: `M26 — Auto Dispatch Scheduler`
Cycle: `M26-C001 V02` (narrow transaction & coherence remediation)
Engine: Godot **4.7.2** (`4.7.2.stable.official.ed1daf0bf`), GDScript
Status: **AWAITING_AUDIT**

Prior audit: `coordination/sessions/M26-C001/CHATGPT_AUDIT_V01.md`
Start SHA (pre-work `origin/main`): `8a538c76d6549956dbac67ad9dd17c1a329e62aa`
Implementation SHA: `cad2d75f747736969c6062e50901000f2c2bb2ff`
Log commit SHA: `(this commit)` (this file, separate final commit)

## 0. Governance / scope confirmation

- Repo/branch verified before work; synchronized with `origin/main` (no `reset --hard`/`clean`/force; no destructive cleanup).
- Root `TASKS.md` modified by Claude: **NO** (absent from every commit).
- M27 solvability/deadlock implemented: **NO**.
- Final M28 gameplay UI implemented: **NO**.
- Image-generation credits spent: **0** (no image tool invoked).
- This is ONE continuous remediation pass over the already-implemented full M26 milestone. M25 not re-opened.
- Implementation commit precedes this separate `CLAUDE_LOG_V02.md` commit.

## 1. Scope

Close ALL four M26 V01 findings while preserving every accepted M26 V01 behavior
(preclaimed dispatcher path, no-target/claim/route ⇒ no robot, no retarget, one
assignment/step, BLUE 8/14/12 arbitration, cross-color fairness, WAITING/wake, BLUE15
exact 15 clears, Hazard Bot real-slot-anchor integration, 59x59 sanity, and all
M25/M24/M23/M22/M20/M19 regressions). No new target-selection, reservation, routing or
clearing authority introduced; every WHAT/HOW boundary preserved.

## 2. Changed files

Production:
- `scripts/gameplay/dispatch/auto_dispatch_scheduler.gd` — reset made deferred/
  generation-safe + transaction-safe; authenticated-clear finalize ordering corrected;
  bind proves the exact cross-engine bundle.
- `scripts/gameplay/targeting/batch_target_claim_engine.gd` — added read-only seam
  `is_bound_to(board, batch_engine, reservations)` (M25). No behavior change elsewhere.
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — added read-only seam
  `is_bound_to(board, reservations, dispatcher)` (M20). No behavior change elsewhere.

Tests / evidence:
- `tests/run_tests.gd` — new `_run_m26_v02_remediation_tests()` (+60 direct adversarial
  checks) mapping F-M26-V01-STRICT-001..004, plus a `_m26_build_injected(...)` helper.
- `tests/support/m26_reset_injector.gd` (NEW) — single-shot deferred-reset injector used
  as both origin provider and dispatcher agent factory.

## 3. Finding-by-finding closure (F-M26-V01-STRICT-001..004 → code + tests)

### F-M26-V01-STRICT-001 — deferred/generation-safe reset during an active step

Code (`auto_dispatch_scheduler.gd`):
- Replaced the drop-on-`_in_step` guard with a monotonic `_generation` + `_reset_requested`
  intent. `reset()` records intent and advances the generation; it performs the teardown
  immediately only when no step is active, otherwise defers.
- `step()` snapshots `my_gen`, and after it unwinds calls `_drain_pending_reset()` so a
  reset injected mid-step drains once no step is in flight (a fresh `step()` also drains a
  pending reset before scheduling).
- `_attempt_color(color, my_gen)` checks `_generation != my_gen` after EVERY callback-
  bearing boundary: building access (origin provider), the M25 claim (selector/access
  callbacks), the post-claim origin lookup, route computation, and the preclaimed dispatch.
  Once a live M25 claim exists, any observed generation move rolls that claim back through
  `M25.rollback_claim` and records NO assignment. A reset injected INSIDE preclaimed
  dispatch (which does not move the dispatcher's own generation) is caught right after
  dispatch returns: the claim is rolled back and any agent the dispatch spawned is freed by
  the deferred `_loop.reset()` that drains as the step unwinds → zero net robot.

Tests (`_m26_v02_deferred_reset_during_step`): injection BEFORE dispatch (post-claim
origin-provider callback) and INSIDE preclaimed dispatch (agent-factory callback). Both
prove: step aborts with no assignment, reset fired exactly once, zero robot / zero live
M25 claim / zero reservation after the deferred drain, no live/moving agent, and later
scheduling resumes.

### F-M26-V01-STRICT-002 — transaction-safe reset (no teardown after failed rollback)

Code (`_reset_teardown()`):
- Preflight A: every live scheduler assignment must still name a live M25 claim
  (`get_claim(...)` non-empty) or the reset fails closed.
- Preflight B + rollback: delegates to `BatchTargetClaimEngine.reset()`, which preflights
  EVERY live claim's exact reservation pair AND M24 work tuple read-only and mutates
  NOTHING if any is incoherent. A `false` return fails closed **before** any
  `CompleteClearingLoop.reset()` (dispatcher/M20 teardown) or scheduler-ledger clear, so a
  single drifted claim leaves the healthy sibling claim, its reservation and its dispatcher
  agent recoverable. Only on `true` are dispatcher agents freed and the ledger cleared.
- `reset()` now returns `bool`; `last_reset_succeeded()` / `is_reset_pending()` expose the
  deterministic outcome; a fail-closed reset stays pending and blocks new scheduling until
  repaired + retried.

Tests (`_m26_v02_transaction_safe_reset`): two live assignments; one claim's exact M24 work
tuple drifted (`_live_work[cid]["batch_id"]`); reset fails closed with ledger + both M25
claims + both dispatcher agents intact and the unrelated reservation surviving; after repair
reset succeeds and leaves zero scheduler assignments, M25 claims, dispatcher agents and
scheduler reservations, unrelated reservation still surviving.

### F-M26-V01-STRICT-003 — authenticated-clear finalize ordering + exact agent identity

Code (`_on_authenticated_clear`):
- Identity match now includes the EXACT agent instance (plus owner/target/color). A wrong
  agent / wrong target / wrong color / stale-unknown owner is ignored with zero side
  effects (no finalize, no quota change, assignment intact).
- `M25.finalize_clear(claim_id)` is called FIRST; the owner→claim mapping is erased and
  WAITING colors woken ONLY after it returns true. On failure the assignment + M25 claim +
  M24 committed truth are retained, nothing is woken, no quota is decremented, and a
  deterministic fatal state (`is_fatal()`) is surfaced that blocks new scheduling until
  reset/recovery.

Tests (`_m26_v02_finalize_ordering`): wrong-agent/target/color/unknown-owner notifications
ignored with no quota change; forced finalize failure (M24 work-tuple drift after a real
clear) retains assignment/claim/committed truth, decrements no quota, goes fatal and blocks
`step()`; a genuine successful clear erases the mapping only after true finalize success and
leaves no claim and no fatal state.

### F-M26-V01-STRICT-004 — exact cross-engine bundle coherence at bind

Code:
- New minimal read-only seams (identity queries only, no mutable refs exposed):
  - `BatchTargetClaimEngine.is_bound_to(board, batch_engine, reservations)` (M25);
  - `CompleteClearingLoop.is_bound_to(board, reservations, dispatcher)` (M20).
- `AutoDispatchScheduler.bind()` now proves, before any signal connection or state commit,
  all six required identities: M25 exact board/M24/reservations, and M20 exact board/
  reservations/dispatcher (M14 `reservations.is_bound_to(board)` and M19
  `dispatcher.is_bound_to(board, reservations)` already anchored the rest). A rejected
  bundle leaves zero side effects and connects no `authenticated_clear` signal.

Tests (`_m26_v02_bundle_coherence_bind`): coherent bundle accepted and the finalize signal
connected; foreign M24, foreign M25 (wrong board/reservations) and a foreign M20 loop
(wrong dispatcher) each rejected with the scheduler unbound and no signal connected; the
coherent bundle still binds cleanly after all rejections.

## 4. Preserved V01 behavior

The full existing M26 unit section (`_run_m26_scheduler_tests`) — preclaimed boundary,
no-ghost adversarial, pacing/capacity, BLUE 8/14/12 spill + cross-color round-robin,
WAITING/wake, pause/resume/reset, BLUE15 autonomy — plus both integration scripts remain
green with the reworked reset/finalize/bind paths.

## 5. Test commands + results

Literal commands (this machine, Godot 4.7.2):
```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd
git diff --check
```

Results:
- `tests/run_tests.gd`: **5253 checks / 2 failures**. The +60 new M26 V02 remediation
  checks (F-M26-V01-STRICT-001..004) all PASS; all prior M26 and cross-milestone checks
  PASS. The **only** 2 failures are pre-existing and environment-only — the level-importer
  "distinct dot-segment output path" checks — reproduced identically on the clean start SHA
  (`8a538c7`, stash-verified: 5193 checks / same 2 failures) and unrelated to M26. My change
  adds zero new failures.
- `tests/m26_hazard_bot_integration.gd`: **PASS** — real Hazard Bot slot-anchor/Railroad
  integration; wake proven (total clears 128 > 76 initially-reachable edge).
- `tests/m26_scale_59_sanity.gd`: **PASS** — `board=59x59 cells=3481 peak_inflight=30`,
  quota conserved to zero, reset idempotent.
- `git diff --check`: clean.

## 6. Changed-file set (implementation commit `cad2d75`)

```
scripts/gameplay/clearing/complete_clearing_loop.gd     |  13 +
scripts/gameplay/dispatch/auto_dispatch_scheduler.gd    | 238 +++++--
scripts/gameplay/targeting/batch_target_claim_engine.gd |  13 +
tests/run_tests.gd                                      | 284 ++++++
tests/support/m26_reset_injector.gd                     |  48 +
```

## 7. Handoff

`AWAITING_AUDIT`. Findings F-M26-V01-STRICT-001..004 mapped to exact code + direct
adversarial tests above. Root `TASKS.md` left for ChatGPT to update after independent audit.
