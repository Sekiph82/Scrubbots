# CLAUDE_LOG_V05 — M20-C001 Auditor-Authored Validation-Only Gate

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V05.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
- V04 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V04.md`
- Actor: CLAUDE (validation only — no production change).
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- V05 tracker start transition (IN_PROGRESS): `c79825a` (verified on remote).
- Accepted V04 implementation commit: `50be126cc7bf82e62650d81287c0bf2ba4ca7064`.

## OUTCOME: `V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT`

The fresh Node-lifecycle validation (§3E) exposed a real gap in the accepted V04
production for the **truly-freed OPTIONAL renderer**. V05 is validation-only and
production is immutable, so per prompt §1 I did NOT change production and STOPPED
with the defect code rather than papering over it or forcing AWAITING_AUDIT.

### The defect (precise)
In Godot 4.7 a freed `Object` reference compares `== null` (`!= null` is false).
Verified directly:

```
is_instance_valid(freed) = false
freed != null           => false
freed == null           => true
typeof(freed)==TYPE_OBJECT => true
```

`CompleteClearingLoop` treats the renderer as OPTIONAL and guards every renderer
access with `if renderer != null:` / `if _renderer != null`. Once the renderer is
TRULY freed (destroyed across a SceneTree frame), that reference is `== null`, so
the guard skips the V04 liveness check entirely and the loop behaves as a
headless (no-renderer) configuration:

- bind with a truly-freed renderer → returns TRUE (headless), not false;
- after a healthy bind, if the bound renderer is later freed → `is_coherent()`
  stays TRUE and `activate_slot()` still succeeds, instead of failing closed.

This contradicts the auditor-required laws that a freed/queued renderer be
rejected / make the bundle incoherent (V04 §3; V05 §3B/§3D/§3E). The DISPATCHER is
unaffected because it is a required dependency checked UNCONDITIONALLY (not behind
a `!= null` guard): `_is_live_node(disp)` returns false for a freed dispatcher, so
bind/coherence/activation all fail closed correctly. The gap is specific to the
OPTIONAL renderer's null-guard interacting with Godot's freed==null semantics.

### Evidence — `tests/m20_v05_lifecycle_smoke.gd` (real frames)
```
  ok:   renderer truly destroyed before bind
  FAIL: bind rejects truly-freed renderer without SCRIPT ERROR
  ok:   healthy bind with renderer
  ok:   bound renderer destroyed across frame
  FAIL: is_coherent() false after renderer destroyed (no SCRIPT ERROR)
  FAIL: activation fails closed with destroyed renderer
  ok:   reset() safe with destroyed renderer (no SCRIPT ERROR)
  ok:   dispatcher truly destroyed before bind
  ok:   bind rejects truly-freed dispatcher
  ok:   healthy bind (dispatcher)
  ok:   is_coherent() false after dispatcher destroyed
  ok:   activation fails closed with destroyed dispatcher
  ok:   reset() safe with destroyed dispatcher
```
No freed-object SCRIPT ERROR occurs in any case (the guard silently degrades). The
QUEUED renderer cases (V05 §3B/§3D, exercised in the synchronous root suite) DO
pass, because a queued node is still non-null+valid so the liveness check runs.

### Two nuances for the production owner (ChatGPT / a V06 production cycle)
1. **After-bind freed renderer (fixable):** the loop should record that a renderer
   was bound (e.g. a `_renderer_bound` flag captured at bind) and, in `_probe`/the
   transaction, treat `_renderer_bound and not is_instance_valid(_renderer)` as
   incoherent rather than as "no renderer". This closes §3D/§3E after-bind.
2. **Before-bind freed renderer (may be unsatisfiable / criteria question):** a
   caller passing an already-freed renderer reference passes something that IS
   `null` at the language level, so bind cannot distinguish it from the legitimate
   headless `renderer = null` config. The §3E "bind rejects truly-freed renderer"
   assertion may need to be relaxed to "treated as headless" OR the API changed so
   a freed renderer is detectable. This is an auditor decision, recorded not fixed.

I did NOT attempt either change (validation-only, production immutable, §1).

## Validation performed before the STOP

### §0 Tracking
Synced `origin/main` ff (`50be126..4e0fd9f`), owner work preserved. Verified V04
audit + V05 prompt/criteria present and tracker at V04/AWAITING_AUDIT/CHATGPT.
Pushed the tracker-only IN_PROGRESS transition `c79825a` BEFORE any validation
edit; verified on remote.

### §1 Production immutability — VERIFIED before and after
Pre-validation and final production blob SHAs (unchanged; match the locked values):
- `scripts/gameplay/clearing/complete_clearing_loop.gd` =
  `f00c34021da85e596df58f08857acde8846dd8a4` (locked value ✓)
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` =
  `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3` (locked value ✓)
`git status --short scripts/` shows no tracked `scripts/**` modification (only
pre-existing untracked `.uid` owner files). No production change was made or
committed.

### §2–§7 fresh auditor-validation block (all green in the root suite)
Added `_run_m20_v05_auditor_validation_tests()` to `tests/run_tests.gd` with fresh
arrangements (not aggregate re-calls):
- §3 A/B (queued dispatcher/renderer before bind → bind false, unbound, zero
  arrival connection), C (dispatcher queued after bind → incoherent, activation
  closed, reset safe), D (renderer queued after bind WITH a live assignment →
  coherence false, reset removes the assignment + exact reservation, BoardState
  ACTIVE, cleared_count 0). These QUEUED cases PASS.
- §4 post-dispatch barrier: reset inside M19 dispatch → exactly one owner token
  consumed, RESETTING (no raw SUCCESS), active 0, current reservation absent,
  target ACTIVE, cleared 0, owner not rewound, later activation uses a strictly
  later owner and clears; renderer freed inside M19 dispatch → one owner consumed,
  COHERENCE_FAILED, active 0, reservation gone, target ACTIVE, cleared 0, fresh
  bundle recovers. PASS.
- §5 pair-narrow reset A–F (healthy+unrelated; foreign different target; foreign
  same numeric target; same-board owner replacement + unrelated; missing pair +
  unrelated; loop.reset() foreign-board route) — all preserve the correct
  reservations and clear dispatcher active. PASS.
- §6 arrival adversaries (duplicate current no double-clear; distinct FIFO
  lossless; reset in candidate phase restores/no-clear; reset in reservation phase
  restores/no-clear; identity-swap → ROLLBACK_FAILED; unrelated same-color
  candidate survives; failed-preflight then reset removes stranded assignment;
  stale replay after reset cannot clear). PASS.
- §7 gameplay integration (1×1 clear+exhaustion; AL-028 gate A then second real
  activate selects/clears B; five unique owners/targets/exact pairs + first
  preserves four; 59×59; rectangular 53×59; rapid 28-target/≥25-cycle). PASS.

Full root suite: **`Total checks: 3640 / Failures: 0 / RESULT: ALL PASS`**, exit 0,
zero M20 SCRIPT/Parse error. `tests/m20_queue_free_smoke.gd` PASS,
`tests/m20_v04_lifecycle_smoke.gd` PASS. The only failing artifact is the new
`tests/m20_v05_lifecycle_smoke.gd`, which exists to expose the defect above.

### §8 load-bearing sensitivity mutations — NOT executed
Per prompt §1 (STOP when the accepted source needs a production correction), I
halted at the §3E validation and did not proceed to the three temporary S1/S2/S3
production mutations. Running them presumes a clean gate; the honest outcome here
is the exposed defect, handed back for a production decision.

## Changed files (this cycle)
- `tests/run_tests.gd` — new `_run_m20_v05_auditor_validation_tests()` block (+ its
  helpers); all prior V01–V04 tests remain enabled.
- `tests/m20_v05_lifecycle_smoke.gd` — NEW frame-aware smoke (evidence artifact
  exposing the freed-optional-renderer gap; dispatcher cases pass).
- `TASKS.md` — Project Status lifecycle only.
- `coordination/sessions/M20-C001/CLAUDE_LOG_V05.md` — this log.
No `scripts/**` change. `git diff --check` clean (only benign LF→CRLF advisories).

## Handoff
Tracker set to BLOCKED / Required Actor CHATGPT with the defect recorded; progress
unchanged (290/719; 290/943; lastCompletedTaskId M19-C001-V06); no SB-M20 checkbox
marked. Production blobs remain the exact locked V04 values.

Return: `V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT`.
