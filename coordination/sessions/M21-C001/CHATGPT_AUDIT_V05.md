# M21-C001 V05 — Independent Strict Audit

Date: 2026-09-13
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation head: `4dd3fb04585bdab02e9b9a1b8dccfe336d26a1d8`
Prompt basis: `CHATGPT_PROMPT_V05.md`
Criteria basis: `CHATGPT_AUDIT_CRITERIA_V05.md`
Claude evidence: `CLAUDE_LOG_V05.md`

## Verdict

**CHANGES_REQUIRED / VALIDATION_EVIDENCE_ONLY / FINDING_SET_FROZEN**

The V05 production/presentation correction is materially sound. Frozen findings `F-M21-V04-001`, `F-M21-V04-002`, and `F-M21-V04-003` are CLOSED. Most of `F-M21-V04-004` is also CLOSED: the real Button signal chain is now load-bearing, the slot-anchor mapping is directly observed, and AgentLayer cleanup is frame-observed.

One narrow evidence residual remains inside the already-frozen `F-M21-V04-004` surface:

**R-V05-TALL-001 — the claimed 1080×2400 second/tall portrait test does not actually run a second 1080×2400 layout configuration.**

No new gameplay/production finding is opened. V06 must be validation-only unless the genuine tall-layout run exposes a real defect.

Owner manual playtest remains **BLOCKED pending V06 independent audit**. Do not ask the owner for visual PASS yet.

---

## 1. Git / governance audit

- Canonical branch head inspected: `4dd3fb04585bdab02e9b9a1b8dccfe336d26a1d8`.
- V05 began with a separate tracker-only commit `4e7871b40093a3bcbef3a4c3cfeb56a69225f063`; that commit changes only root `TASKS.md` lifecycle to V05 / IN_PROGRESS / CLAUDE.
- Implementation/handoff commit is `4dd3fb04585bdab02e9b9a1b8dccfe336d26a1d8`.
- Root tracker correctly ends at M21-C001 V05 / AWAITING_AUDIT / CHATGPT.
- Progress remains `304 / 719 = 42.28%` main+ui and `304 / 943 = 32.24%` overall.
- `lastCompletedTaskId` remains `M20-C001-V11`.
- Claude closed no `SB-M21-*`, `SB-M22-*`, or `SB-UI-*` checkbox.
- V05 diff is correctly confined to owner-playtest presentation/UI/tests/docs/tracker. No accepted M19/M20 production gameplay file changed.

Governance result: **PASS**.

---

## 2. Locked identity audit

Direct canonical GitHub blob rechecks at the audited head:

- owner-approved Hazard Bot source: `b565743ba52699899007882b750b7c8e7cdd00f9` — unchanged;
- `CompleteClearingLoop`: `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged;
- `ScrubbotDispatcher`: `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged;
- V04 owner-policy `TargetSelector`: `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` — unchanged.

The V04 bottom-most / left-most target-selection policy therefore remains outside the V05 correction diff and is not reopened.

Locked identity result: **PASS**.

---

## 3. Frozen finding audit

### F-M21-V04-001 — controller double-drives ScrubbotAgent

**CLOSED.**

Current owner-scene `_process(_delta)` only reconciles presentation state and never calls `advance()` on a real ScrubbotAgent. Canonical ScrubbotAgent remains the single frame-to-frame movement owner through its own `_process(delta) -> advance(delta)` contract.

The new root-suite sensitivity is direct rather than proxy:

1. dispatch a real M21 C08 assignment;
2. capture agent local position/progress;
3. call the owner controller `_process(0.5)`;
4. prove position/progress are unchanged;
5. apply one explicit `agent.advance(0.05)` and prove movement is approximately `speed * delta`, not the former multiplied controller step.

This test would fail against the V04 controller behavior.

Result: **PASS / CLOSED**.

### F-M21-V04-002 — visible SlotView not authoritative for route start

**CLOSED for the reference-layout path.**

V05 introduces one narrow presentation seam:

`SlotView.get_spawn_anchor_global()` → `BoardPresentation.global_to_board_local()` → `CompleteClearingLoop.activate_slot(... start_position ...)`.

The old visible-activation left-edge origin synthesis is no longer authoritative. Direct frame-aware evidence proves, after Control layout:

- all five slot anchors round-trip through the BoardPresentation transform;
- the real C08 `agent.spawn_origin` equals the mapped clicked-slot anchor;
- the real agent global start equals the visible clicked-slot anchor;
- the real route first point equals that mapped start;
- arrival global agrees with the BoardRenderer target-cell center;
- moving a SlotView changes the mapped start, proving the layout geometry is load-bearing.

Result: **PASS / CLOSED for the exercised layout**.

### F-M21-V04-003 — singular active UI bookkeeping

**CLOSED.**

The scene no longer owns a single `_active_agent` / `_active_slot`. It tracks successful assignments by owner id and derives active slots from still-moving real agents.

Direct tests prove:

- two same-slot C08 successes have distinct owner and target identities;
- the slot remains active after the first of two same-slot assignments completes;
- it becomes inactive only after the last same-slot assignment resolves;
- a non-C08 color is opened through real clearing and can coexist with a concurrent C08 assignment;
- different slot highlights remain independent;
- reset clears presentation bookkeeping/visual state.

No UI observation becomes BoardState/reservation/clear authority.

Result: **PASS / CLOSED**.

### F-M21-V04-004 — proxy/missing direct owner-playtest evidence

**PARTIALLY CLOSED.**

Closed portions:

- real `BaseButton.pressed -> SlotView._on_pressed -> slot_activated -> scene handler -> request_slot -> CompleteClearingLoop` path is exercised;
- disconnecting `slot_activated` makes the test fail to dispatch, so the signal wiring is load-bearing;
- clicked slot color identity is checked against real gameplay result;
- frame-aware AgentLayer child count reaches zero after authenticated arrival and deferred frees;
- reset + pumped frames also proves no orphan ScrubbotAgent remains;
- the old criterion-126 self-comparison was replaced by real visible-anchor → mapped start → real agent/route observations.

Remaining portion is `R-V05-TALL-001` below.

---

## 4. R-V05-TALL-001 — second/tall portrait evidence is not a real second configuration

**Severity: validation-blocking, production change not yet justified.**

The V05 criteria explicitly require a **second/tall portrait configuration distinct from the 1080×2160 reference case**, including proof that the slot-anchor → agent-start mapping remains correct after the layout configuration changes.

Canonical `project.godot` at the audited head still configures the reference viewport as:

```text
viewport_width = 1080
viewport_height = 2160
stretch/mode = canvas_items
stretch/aspect = expand
```

The V05 frame-aware smoke boots that normal scene/layout and later does only:

```gdscript
var vp := Vector2(1080, 2400)
for v in views:
    var gr := Rect2(v.global_position, v.size)
    ... compare existing rects to vp ...
```

It does **not** change the actual root/window/viewport/content geometry to 1080×2400, instantiate a second tall-layout harness, or otherwise prove that the Controls have re-laid-out under a genuine second presentation size. It then checks only containment and that SlotBar is below the board. It does not dispatch a real agent after a genuine tall-layout change and re-prove:

`actual tall SlotView anchor -> inverse transform -> agent.spawn_origin / route[0] / global start`.

Therefore criteria 82 and 122–126 are not fully satisfied. Enlarging the comparison rectangle from 2160 to 2400 while retaining the same 2160 layout can stay green even if tall-layout behavior is broken. Under AL-018, that is proxy evidence rather than direct observability.

This residual is specifically part of the already-frozen V04 finding 004; it is not a new architectural finding.

Result: **CHANGES_REQUIRED / VALIDATION-EVIDENCE-ONLY**.

---

## 5. Regression evidence assessment

Claude reports, and the committed test surface is consistent with:

- root suite `4602/4602` PASS;
- M21 full-real smoke PASS with exactly 400 clears;
- M20 lifecycle/queue-free smokes PASS;
- V05 frame-aware smoke PASS;
- scene boot with zero `SCRIPT ERROR` / `Parse Error`;
- deterministic M21 builder/reference reruns unchanged.

I did not independently execute Godot in this audit environment, so these are implementer runtime evidence, not auditor-executed runtime evidence. Static/source inspection confirms the V05 tests are materially load-bearing for F-001, F-002 at the exercised layout, F-003, real Button signal wiring, and AgentLayer cleanup. The tall-layout cell remains insufficient for the reason above.

---

## 6. Full-surface finding freeze

Per AL-054, I swept the full V05 changed surface and its immediate owner-playtest consumers before issuing another prompt:

- `scripts/debug/m21_real_art_vertical_slice.gd`;
- `scripts/gameplay/board/board_presentation.gd`;
- `scripts/ui/slot_view.gd`;
- V05 root-suite blocks;
- `tests/m21_v05_playtest_smoke.gd`;
- V05 owner guide;
- tracker/lifecycle state;
- locked M20 / TargetSelector / owner-source identities.

**Frozen residual set for V06: exactly one item, `R-V05-TALL-001`.**

No other V05-owned material finding is open at this time.

---

## 7. Required V06 disposition

V06 is a **validation-only tall-layout closure pass**.

It must not modify accepted M15/M18/M19/M20 or V05 production/presentation source merely to satisfy the test. It should first run the existing scene/controller under a genuine second 1080×2400 layout configuration, wait for layout frames, and directly prove the full slot-anchor-to-agent-start chain there.

If genuine 1080×2400 execution exposes a real layout/mapping defect, V06 must stop `BLOCKED` with exact evidence rather than silently correcting production inside the validation-only pass. ChatGPT will then scope a correction.

If the genuine tall configuration passes, V06 can return `AWAITING_AUDIT`. After independent V06 audit passes, the owner may run `M21_V05_OWNER_PLAYTEST.md` (or a V06 reconciliation guide if needed) for the final visual acceptance gate.

Until then:

**M21 remains open. Owner manual playtest is not yet authorized as the final acceptance step.**
