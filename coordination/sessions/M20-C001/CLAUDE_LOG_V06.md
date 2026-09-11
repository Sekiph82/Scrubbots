# CLAUDE_LOG_V06 — M20-C001 Optional Renderer Lifecycle Correction

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V06.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V06.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V06.md`
- V05 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V05.md`
- Actor: CLAUDE (implement + test only). Handoff: AWAITING_AUDIT.
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Starting `origin/main`: `85ab9d7`. V06 tracker start transition (IN_PROGRESS): `77b09bd` (verified on remote).
- Result: full headless suite **3655 / 3655 PASS**, exit 0. All three smokes PASS
  (V05 lifecycle now green). Zero M20 SCRIPT/Parse error.

Fixes F-M20-STRICT-001.L (the V05-exposed freed-optional-renderer defect).
Production change is limited to `scripts/gameplay/clearing/complete_clearing_loop.gd`;
`scrubbot_dispatcher.gd` and every other upstream file are unchanged (§10). No
`CHATGPT_*`, audit verdict, AUDIT_INDEX, SB-M20 row, or `.hiveai/*` touched. Owner
working-tree changes preserved/unstaged.

## 0. Tracking / start-order (§0)
Synced ff (`d50a454..85ab9d7`); verified V05 audit + V06 freeze/prompt/criteria;
verified tracker at V05/BLOCKED/CHATGPT; set V06/IN_PROGRESS/CLAUDE; pushed the
tracker-only transition `77b09bd` BEFORE any V06 edit; verified on remote.

## 1. Preserved V04/V05 behavior
No redesign. Exact-script dependency boundary, dispatcher live-node checks,
post-dispatch reset/generation + coherence barriers, pair-narrow board-safe
dispatcher reset, exact reservation owner-map proof, current-arrival dedup +
distinct FIFO, deferred transactional reset, clear order + renderer-post-finalize,
and the no-M21/win/scoring/session/slot scope are all intact and still green.
`scrubbot_dispatcher.gd` kept READ-ONLY (blob `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`).

## 2/3/4 The correction (F-M20-STRICT-001.L)
Root cause (V05, authoritative): in Godot 4.7 a truly-freed `Object` compares
`== null` while `typeof == TYPE_OBJECT`, so `renderer != null` / `_renderer != null`
cannot be the authority for whether a renderer was configured — a
configured-then-freed renderer aliased to the headless case and dropped the
liveness gate.

Changes in `complete_clearing_loop.gd` (only):
- New private immutable bundle metadata `var _renderer_expected: bool = false`.
- `_bind_txn` derives `renderer_expected = typeof(renderer) != TYPE_NIL` (TYPE_NIL
  = intentional headless; any other Variant = explicit dependency that must pass
  the exact `_is_live_exact_node(renderer, BoardRenderer)` gate). A truly-freed
  renderer is a non-NIL Variant (TYPE_OBJECT) → `renderer_expected == true` →
  `_is_live_node` false (freed aliases to null) → bind fails cleanly, no SCRIPT
  ERROR, no arrival connection, loop unbound. `_renderer` + `_renderer_expected`
  are committed only on success; a failed bind leaves no renderer-present metadata.
- `is_coherent()` passes the persisted `_renderer_expected` into `_probe`, which now
  gates the renderer check on `renderer_expected` (never `renderer != null`). A
  configured renderer that later dies → probe false (incoherent); it can never
  silently downgrade the bundle to headless. `_renderer_expected` is never inferred
  from `_renderer` after bind.
- Post-finalize repaint and `_renderer_pixel` use `_renderer_expected` for presence
  plus `is_instance_valid` for liveness. A dead configured renderer is never
  called; preflight (`is_coherent`) fails before any BoardState mutation, so an
  authenticated arrival cannot clear under a falsely-headless interpretation; no
  false-clear frame; a healthy renderer still repaints exactly the target to
  alpha 0; a genuinely headless bundle still clears normally.

## 5. Test-only harness
`_m20_harness_bind` now sets `loop._renderer_expected = (w.get("renderer") != null)`
(harness renderers are live, so equality is correct there), mirroring production
presence semantics without a public setter. Production `bind()` remains the only
production entry; support subclasses remain production-rejected.

## 6. V05 lifecycle smoke now passes
`tests/m20_v05_lifecycle_smoke.gd` (frame-aware) post-fix: truly-freed renderer
before bind → bind false/unbound/no SCRIPT ERROR; healthy renderer bind → success;
renderer destroyed after bind → `is_coherent()` false; activation after renderer
destruction → stable failure, no dispatch/clear; reset after destruction → safe;
dispatcher before/after-bind cases remain green. Header updated from
"evidence artifact (exits 1)" to "permanent regression (exits 0)". V04 lifecycle
smoke + queue-free smoke remain green.

## 7. Direct null-vs-dead distinction tests
New `_run_m20_v06_renderer_presence_tests()` in `tests/run_tests.gd`, observed only
through bind/coherence/repaint (no private getter):
- A omitted renderer → headless bind succeeds + clears;
- B explicit `null` → headless succeeds + coherent;
- C scalar (123) → rejected, unbound, no arrival connection;
- D arbitrary RefCounted AND wrong Node (dispatcher-as-renderer) → rejected;
- E queued exact renderer → rejected;
- G healthy exact renderer → accepted, coherent, and a real clear repaints the
  target to alpha 0 (presence proven by behavior).
- F truly-freed exact renderer → rejected despite `== null` — covered by the
  frame-based V05 lifecycle smoke.

## 8. V05 validation matrix preserved
The fresh `_run_m20_v05_auditor_validation_tests()` block (queued dispatcher/
renderer lifecycle, post-dispatch reset + renderer-coherence barriers, pair-narrow
reset A–F, duplicate current arrival, distinct FIFO, reset candidate/reservation
phases, identity-swap → ROLLBACK_FAILED, unrelated candidate preservation,
failed-preflight reset recovery, stale replay rejection, 1×1, AL-028 second-B,
five unique owners/targets/pairs, 59×59, rectangular, rapid ≥25) remains enabled
and green.

## 9. Sensitivity for THIS fix (temporary, restored, not committed)
- Pre-mutation `complete_clearing_loop.gd` blob: `514838fa6d965ffa1f5663b9c4c5385c12f63114`.
- Mutation: reverted configured-renderer presence in the bind gate AND `_probe`
  from the persisted `_renderer_expected` bit back to `renderer != null` equality.
- Targeted failure (intended): `tests/m20_v05_lifecycle_smoke.gd` FAILED (exit 1) on
  exactly the freed-renderer cases — "bind rejects truly-freed renderer",
  "is_coherent() false after renderer destroyed", "activation fails closed with
  destroyed renderer" — proving the presence bit is load-bearing.
- Restored byte-for-byte (reverse replacement). Post-restore blob:
  `514838fa6d965ffa1f5663b9c4c5385c12f63114` (== pre-mutation ✓). Mutation not committed.

## 10/11 Validation / scope
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- Full root suite → `Total checks: 3655 / Failures: 0 / RESULT: ALL PASS`, exit 0.
- `tests/m20_v05_lifecycle_smoke.gd` → PASS, exit 0.
- `tests/m20_v04_lifecycle_smoke.gd` → PASS, exit 0.
- `tests/m20_queue_free_smoke.gd` → PASS, exit 0.
- Direct A/B/C/D/E/G renderer cases → green (F via smoke).
- `git diff --check` → clean (only benign LF→CRLF advisories).
- Final production blobs: `complete_clearing_loop.gd` =
  `514838fa6d965ffa1f5663b9c4c5385c12f63114` (V06 correction);
  `scrubbot_dispatcher.gd` = `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3` (unchanged,
  locked V04 value). Only `complete_clearing_loop.gd` changed under `scripts/**`.
- Scope grep: no win/scoring/session/queue/cooldown behavior; forbidden terms only
  in the exclusion comment.
- TASKS lifecycle: before = V05/BLOCKED/CHATGPT; start = V06/IN_PROGRESS/CLAUDE
  (`77b09bd`); final = V06/AWAITING_AUDIT/CHATGPT.

## 12. Handoff
Did NOT mark COMPLETE/READY_FOR_NEXT_TASK or any SB-M20 checkbox. Progress unchanged
(290/719; 290/943; lastCompletedTaskId M19-C001-V06). Tracker set to AWAITING_AUDIT /
CHATGPT. Noted: a clean V06 source audit is not final M20 closure (production changed)
— ChatGPT will issue an auditor-authored V07 validation-only gate. Implementation +
tests + log + tracker handoff committed and pushed; remote verified.

Return: `AWAITING_AUDIT`.
