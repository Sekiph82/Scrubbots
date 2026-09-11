# CLAUDE_LOG_V07 — M20-C001 Batched Whole-Sprint Correction + Evidence Closure

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V07.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V07.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V07.md`
- V06 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V06.md`
- Actor: CLAUDE (implement + test only). Handoff: AWAITING_AUDIT.
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- V07 tracker start transition (IN_PROGRESS): `3966d03` (verified on remote).

## 0. Tracker start gate
Synced ff (`b4e960a..66588d6`), owner work preserved. Verified V06 audit + V07
freeze/prompt/criteria; tracker at V06/AWAITING_AUDIT/CHATGPT. Set V07/IN_PROGRESS/
CLAUDE and pushed the tracker-only transition `3966d03` BEFORE any V07 production/
test/support/doc edit or sensitivity mutation; verified on remote. NO V07
production/test/support/doc mutation existed before the successful start push.

## 1. Pre-fix sensitivity on the V06 baseline (recorded before correction)
Ran a throwaway frame-aware recorder against unchanged V06 production (deleted
after capture; no production change). Verbatim observations:

S-PRE-1 (duplicate CompleteClearingLoop authority):
```
  loop1 bind=true loop2 bind=true
  assignment_arrived connection count=2
  after one arrival: loop1.cleared=1 loop2.cleared=0
```
=> two M20 controllers bound one dispatcher's authenticated-arrival source (split
authority; divergent cleared_count). Confirms F-M20-STRICT-001.M.

S-PRE-2 (truly-freed explicit agent_parent):
```
  parent is_instance_valid=false  parent==null=>true  typeof==TYPE_OBJECT=>true
  SCRIPT ERROR: Invalid type in function 'bind' ... argument 7 (previously freed)
                is not a subclass of the expected argument class.
```
=> the V06 `agent_parent: Node` typed parameter raised a hard type error for a
truly-freed Node before the body could fail closed; a freed Object also aliases to
`== null`. Confirms F-M20-STRICT-001.N and that the `: Node` annotation must be
removed so the body can gate on Variant type.

## 2. Production correction A — one M20 arrival consumer per dispatcher (F-M20-STRICT-001.M)
`scrubbot_dispatcher.gd`: added a NON-OWNING `WeakRef _m20_consumer_ref` and
`_claim_m20_arrival_consumer(consumer) -> bool` / `_release_m20_arrival_consumer(consumer)`.
The claim succeeds when the slot is free or held by the same consumer, fails for a
different LIVE consumer, and auto-frees when a previously-claimed consumer has been
GC'd (WeakRef → null). No strong cycle, no singleton, not signal-based (a benign
diagnostic listener never affects it). `complete_clearing_loop.gd` `bind()` acquires
the claim only AFTER the bundle is otherwise valid, then connects its exact arrival
callback; if the claim or connection fails it releases the claim and remains fully
unbound; only then commits. Tests: `_run_m20_v07_consumer_claim_tests` (first loop
binds; diagnostic listener does not block; second different loop rejected with no
added connection; first loop coherent/usable; second cannot activate; claim released
after first loop freed → fresh loop binds). BoardState/candidate/reservation/renderer
mutation was NOT moved into the dispatcher.

## 3. Production correction B — explicit agent_parent presence (F-M20-STRICT-001.N)
`scrubbot_dispatcher.gd`: the public `agent_parent` parameter is now UNTYPED
(`agent_parent = null`), so a truly-freed Node no longer triggers Godot's typed-arg
error and the body fails closed itself. Presence is `parent_expected = typeof(agent_parent)
!= TYPE_NIL` (TYPE_NIL omitted/null → self; any non-NIL Variant → explicit dependency
that must be a live Node), captured before the coherence callbacks and revalidated
after using the captured truth (never `agent_parent != null`); `_agent_parent` commits
as `agent_parent if parent_expected else self`, still Node-typed storage. Also reordered
the static `_is_live_node` to `is_instance_valid(n) and n is Node and not
n.is_queued_for_deletion()` so `n is Node` never evaluates a freed operand (that is a
SCRIPT ERROR). Explicit factory semantics unchanged. Tests:
`_run_m20_v07_agent_parent_tests` (omitted → self attach; explicit null → self attach;
healthy explicit Node → agent attaches THERE; scalar → rejected; RefCounted → rejected;
queued Node → rejected) + `tests/m20_v07_lifecycle_smoke.gd` (truly-freed explicit
parent → bind false, no self fallback, no SCRIPT ERROR).

## 4. Renderer whole-lifecycle evidence (V06 model preserved)
`_run_m20_v07_renderer_variant_tests`: omitted/explicit-null → headless; int, float,
String, Vector2, Array, Dictionary, arbitrary RefCounted, wrong Node, queued exact
BoardRenderer all rejected with zero arrival connection; failed-bind metadata recovery
(same loop then binds clean headless, no stale `_renderer_expected`); second-bind
preservation (original configured renderer still required — foreign-board → incoherent);
post-bind drift (same-size different board → incoherent, activation fails before new
dispatcher work); configured renderer queued after a live assignment before arrival →
no clear, cleared_count unchanged, reservation+dispatcher held until reset; healthy
presentation (target alpha 0 after finalize; an unrelated pixel unchanged). Truly-freed
configured renderer after dispatch before arrival → `tests/m20_v07_lifecycle_smoke.gd`
(no clear).

## 5/6. Arrival-desync + activation public-boundary matrices
`_run_m20_v07_desync_activation_tests`: activation boundary (slot -1/5/non-int,
unavailable slot, NaN/±INF origin components, NaN/±INF/0/negative speed) all rejected
with zero agent/reservation/BoardState/slot mutation; arrival desync (wrong owner/
target/color/agent, unknown owner, missing reservation) → PREFLIGHT_REJECTED with no
mutation, dispatcher assignment not silently finalized; stale replay after reset cannot
clear. The V01–V06 desync/foreign-board/candidate-rebind matrices remain enabled.

## 7. SB-M20-001..014 whole-sprint ledger
`_run_m20_v07_sb_ledger_tests` demonstrates each row directly through real production
dependencies: 001 full healthy tuple (CLEARED, absent candidate, ProductionAccessQuery
OPEN, reservation/dispatcher absent, agent queued-for-deletion, renderer alpha 0); 002
no-target + enclosed → no bot/clear; 003 frame queue-free (via queue-free smoke); 004
true 1×1 + exhaustion; 005 one-color exhaustion; 006 multi-color via slots, no
corruption; 007 five in-flight unique owners/targets/exact pairs + first preserves four;
008–011 Easy/Medium/Hard/Very-Hard; 012 59×59 single-cell (exactly one cell changed);
013 rectangular 53×59; 014 AL-028 second real B + rapid ≥25 cycles.

## 8. Rollback/reset regression lock
Preserved and re-run (V02–V06 + V07): candidate/reservation mutate-before-false →
verified rollback; candidate unrelated-loss restore; identity-swap → ROLLBACK_FAILED;
reset in candidate/reservation phase; duplicate current arrival dropped; distinct FIFO;
pair-narrow reset A–F; foreign-board + same-board-wrong-owner replacement survive;
post-dispatch generation barrier load-bearing (V05 §4). Exact production category gates
were NOT widened; adversarial candidate/reservation subclasses stay in the test-only
`_m20_harness_bind`.

## 9. Documentation reconciliation
- `tests/run_tests.gd` M20 overview comment corrected to
  `BoardState -> candidate -> reservation -> dispatcher finalize -> renderer`.
- `docs/02_TECH_ARCHITECTURE.md`: removed the stale "bounded by slot count" claim;
  states one-bot-per-activation, M20 sets no slot busy flag, and concurrent-bot caps/
  queues/cooldowns/consumption are later/design-gated. Owner-locked five-visible-slot
  law untouched. Added the V07 correction notes. Historical prompts/audits untouched.

## 10. Sensitivity after correction (temporary, restored, not committed)
Corrected blobs (targets): loop `06391839523cbc27e88a4b3ef12b730012cd45fa`,
dispatcher `eee10149e4f116af6706beec832042352bf3a6dd`.
- S1 (bypass the M20 consumer claim → `_claim_m20_arrival_consumer` returns true):
  `_run_m20_v07_consumer_claim_tests` failed as intended — "claim: second different loop
  rejected (owner claimed)" (+5 related), connection count 2→3. Restored; disp blob back
  to `eee10149…`.
- S2 (agent_parent presence → `agent_parent != null`): `tests/m20_v07_lifecycle_smoke.gd`
  failed — "bind rejects truly-freed explicit agent_parent". Restored; disp blob
  `eee10149…`.
- S3 (renderer presence → `renderer != null`): `tests/m20_v05_lifecycle_smoke.gd` failed —
  "bind rejects truly-freed renderer", "is_coherent() false after renderer destroyed",
  "activation fails closed with destroyed renderer". Restored; loop blob `06391839…`.
Each mutation was reverted before the next and before final validation; no mutation
committed. Final blobs match the corrected targets exactly (verified).

## 11. Final validation
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- Full root suite `godot --headless --path . -s res://tests/run_tests.gd` →
  `Total checks: 3772 / Failures: 0 / RESULT: ALL PASS`, exit 0; zero M20 SCRIPT/Parse error.
- `tests/m20_queue_free_smoke.gd` → PASS. `tests/m20_v04_lifecycle_smoke.gd` → PASS.
  `tests/m20_v05_lifecycle_smoke.gd` → PASS. `tests/m20_v07_lifecycle_smoke.gd` → PASS.
- `git diff --check` → clean (benign LF→CRLF advisories only).
- Changed files: production `scripts/gameplay/clearing/complete_clearing_loop.gd` +
  `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` (both authorized); tests
  `tests/run_tests.gd`, new `tests/m20_v07_lifecycle_smoke.gd`; `docs/02_TECH_ARCHITECTURE.md`;
  `TASKS.md`; this log. No other `scripts/**` change.
- Final production blob hashes: loop `06391839523cbc27e88a4b3ef12b730012cd45fa`,
  dispatcher `eee10149e4f116af6706beec832042352bf3a6dd`.
- Scope grep: no win/lose/scoring/session-complete/M21/slot-queue/cooldown/consumption
  behavior; the only match is a doc-comment describing what M19 does NOT do.
- All V01–V06 M20 tests and all M19 V01–V06 tests remain enabled.

## 12. Handoff
Did NOT mark COMPLETE/READY_FOR_NEXT_TASK or any SB-M20 checkbox. Progress unchanged
(290/719; 290/943; lastCompletedTaskId M19-C001-V06). Tracker set to AWAITING_AUDIT /
CHATGPT. A clean V07 source audit is not final M20 closure (production changed) —
ChatGPT will issue an auditor-authored V08 validation-only gate. Implementation +
tests + doc + log + tracker committed and pushed; remote verified.

Return: `AWAITING_AUDIT`.
