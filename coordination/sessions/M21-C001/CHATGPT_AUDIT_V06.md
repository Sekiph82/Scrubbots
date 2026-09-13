# M21-C001 V06 — Independent ChatGPT Audit

Date: 2026-09-13
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited Claude handoff commit: `8586a097e50f7cb2f10405b2471ee46b0d91196c`
Active prompt basis: `coordination/sessions/M21-C001/CHATGPT_PROMPT_V06.md`
Criteria basis: `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V06.md`
Matching implementation log: `coordination/sessions/M21-C001/CLAUDE_LOG_V06.md`

## Verdict

**AUDITED_PASS / V06_VALIDATION_CLOSED / OWNER_REQUIRED**

The single frozen V05 residual `R-V05-TALL-001` is closed. V06 establishes and directly observes a genuine second `1080×2400` Godot viewport/layout configuration and re-proves the accepted visible-slot-anchor → board-local start → real ScrubbotAgent → authenticated arrival → cleanup chain under that configuration.

No new implementation defect was found in the V06 full-surface re-audit. No V07 engineering/correction prompt is required.

M21 is **not yet finally closed** because the remaining acceptance gate is owner-controlled visual/game-feel confirmation. Per `coordination/AUDIT_POLICY.md`, automated/runtime engineering evidence cannot close that E4 gate. The next actor is the owner, using `M21_V05_OWNER_PLAYTEST.md`.

## 1. Governance and commit-chain audit

Prompt-head basis before Claude work was `8de5c89b1396370d10dacdafea68de3e1adb5f97`.

The V06 handoff is exactly two commits ahead:

1. `f57746d19c1f4852c0057fd883be0adbbb0ac5f2` — tracker-only transition to `M21-C001 V06 / IN_PROGRESS / CLAUDE`.
2. `8586a097e50f7cb2f10405b2471ee46b0d91196c` — validation evidence + handoff.

The tracker-only start commit changes only `TASKS.md`, as required. The total V06 changed-file surface from prompt head to handoff is only:

- `TASKS.md`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V06.md`
- `tests/m21_v06_tall_layout_smoke.gd`

No `scripts/**`, `scenes/**`, `project.godot`, LevelData, production-art builder/importer, routing, agent, dispatcher, clearing, TargetSelector, or UI/presentation source changed in V06.

Governance result: **PASS**.

## 2. Frozen residual R-V05-TALL-001

### Prior defect

V05's tall check used a local `Vector2(1080, 2400)` bounds value while the owner scene remained in its existing layout configuration. That proved containment against a larger rectangle, but did not prove a real second/tall layout configuration.

### V06 mechanism

`tests/m21_v06_tall_layout_smoke.gd` now creates a real `SubViewport`, assigns its actual `size` to `Vector2i(1080, 2400)`, adds that viewport to the running SceneTree, then instantiates the real owner scene inside it and awaits layout/process frames.

This is materially different from the V05 proxy because the owner scene's root is a full-rect `Control`:

- `layout_mode=3`
- `anchors_preset=15`
- `anchor_right=1.0`
- `anchor_bottom=1.0`

Therefore the real scene participates in the `SubViewport` layout context rather than merely being compared against a standalone constant.

The smoke directly asserts the actual `SubViewport.size == Vector2i(1080, 2400)` after application and asserts it differs from the canonical project reference `1080×2160`. The repository's committed `project.godot` remains `viewport_width=1080`, `viewport_height=2160` and is unchanged by V06.

Result: **R-V05-TALL-001 CLOSED**.

## 3. Anti-proxy / sensitivity review

The new smoke is load-bearing against the exact V05 failure mode:

- Removing the `sub.size = TALL_SIZE` step makes the direct `sub.size == TALL_SIZE` assertion fail.
- Merely changing a local bounds variable cannot satisfy the actual viewport-size assertion.
- Removing/bypassing `BoardPresentation.global_to_board_local()` makes `agent.spawn_origin == mapped` and `route[0] == mapped` fail.
- Reinstating an unrelated hardcoded route start makes the same direct equalities fail.
- Using another slot's anchor is observable because the selected slot's actual post-layout anchor is compared to the real agent's initial global position and route start.
- Breaking `Button.pressed -> SlotView -> slot_activated -> scene handler` leaves `_last_result` null/failed and fails the dispatch assertion.
- Cleanup is observed after deferred frames by direct AgentLayer ScrubbotAgent child count.

False-positive risk is therefore materially lower than V05's tall bounds proxy.

Sensitivity result: **PASS**.

## 4. Direct tall-layout gameplay chain

Under the real `1080×2400` SubViewport the V06 evidence uses the actual owner scene and real production collaborators. It does not call `request_slot()` as the activation stimulus; it emits the real Button `pressed` signal and consumes the resulting scene handler dispatch result.

Recorded concrete tuple:

- slot id: `2`
- palette id: `2` / C08
- visible slot anchor global: `(400.0, 880.0)`
- mapped board-local start: `(9.444445, 21.11111)`
- `agent.spawn_origin`: `(9.444445, 21.11111)`
- route first point: `(9.444445, 21.11111)`
- owner id: `0`
- target index: `388`
- target coordinate: `(8, 19)`
- agent initial global: `(400.0, 880.0)`
- renderer target-cell global center: `(366.0, 822.0)`
- AgentLayer child count after deferred cleanup: `0`

The test also checks that authenticated M20 arrival changes the selected target to CLEARED and does not perform test-side BoardState mutation for the clear.

Direct-chain result: **PASS**.

## 5. Accepted V05/M20 identity preservation

Independently re-read from the audited handoff commit:

| Protected artifact | Required blob | Audited V06 blob | Result |
| --- | --- | --- | --- |
| Hazard Bot owner source | `b565743ba52699899007882b750b7c8e7cdd00f9` | `b565743ba52699899007882b750b7c8e7cdd00f9` | PASS |
| `complete_clearing_loop.gd` | `06391839523cbc27e88a4b3ef12b730012cd45fa` | same | PASS |
| `scrubbot_dispatcher.gd` | `eee10149e4f116af6706beec832042352bf3a6dd` | same | PASS |
| `target_selector.gd` | `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` | same | PASS |
| `m21_real_art_vertical_slice.gd` | `66050fe5ec95498a43c6d4abccf62c4d82744d39` | same | PASS |
| `board_presentation.gd` | `2093df48d367903d332a910dfb3369154831a9ed` | same | PASS |
| `slot_view.gd` | `480dffc0ee135150bd3dd2258f002264273ead10` | same | PASS |

`project.godot` remains blob `26e48f56be73321d94d4aaaa37fb2dd14be51bee` with canonical project viewport `1080×2160`.

Identity-preservation result: **PASS**.

## 6. Regression evidence and independent-audit limitation

Claude records the following fresh V06 execution evidence:

- root suite: `4602/4602` PASS;
- V06 tall-layout smoke: PASS, 16 checks;
- V05 frame-aware playtest smoke: PASS;
- M21 real-art smoke: PASS with exactly 400 clears and exact clean final state;
- all required M20 lifecycle/queue-free smokes: PASS;
- owner scene headless boot: clean;
- zero `SCRIPT ERROR` / `Parse Error` in required outputs;
- builders/references unchanged;
- `git diff --check` clean apart from documented pre-existing local/LF advisories.

I cannot execute the local Godot runtime from the GitHub connector, so these runtime results remain Claude E1/E2 evidence rather than independently rerun E3 runtime evidence. Strict-v2 permits closure here because V06 itself is the auditor-authored adversarial validation stage following V05, and this audit independently inspected the actual committed validation code, its sensitivity properties, the exact changed-file surface, protected source identities, scene layout contract, prompt/criteria/log mapping, and tracker lifecycle.

No aggregate test count is being used as the sole proof of the tall-layout residual.

Regression result: **PASS with runtime-rerun limitation disclosed**.

## 7. Whole-sprint post-validation sweep

V06 changed no accepted M21 production/presentation implementation. The V05 correction surface remains intact:

- single movement owner: accepted;
- visible SlotView anchor → real route start: accepted;
- per-assignment concurrent active presentation: accepted;
- actual Button activation chain: accepted;
- AgentLayer deferred cleanup: accepted;
- bottom-most/left-most TargetSelector policy: unchanged;
- owner-approved source / canonical level / ACTIVE→CLEARED path: unchanged;
- full 400-cell real-art run: retained;
- genuine second `1080×2400` layout proof: now accepted.

No new source defect, trust-boundary widening, lifecycle defect, state mutation issue, or new evidence proxy was found in the V06 surface.

Whole-sprint status: **ENGINEERING/AUTOMATED VALIDATION COMPLETE; OWNER VISUAL GATE REMAINS**.

## 8. Criteria-to-evidence reconciliation

V06 criteria 1–15: governance/lifecycle — PASS.

Criteria 16–30: immutable accepted V05 basis — PASS by exact blob/diff inspection.

Criteria 31–40: genuine second/tall configuration — PASS; real `SubViewport` size is applied and directly observed, project default remains unchanged.

Criteria 41–49: tall visible geometry — PASS for the focused M21 owner-playtest scene; no claim of M44 full responsive UI completion is made.

Criteria 50–62: anchor → real agent → route → authenticated clear → deferred cleanup — PASS by direct test structure and recorded E2 runtime tuple.

Criteria 63–70: anti-proxy/sensitivity — PASS by source inspection of load-bearing assertions.

Criteria 71–86: inherited regression surface — PASS as recorded E1/E2; no prior test deletion appears in the V06 diff.

Criteria 87–94: exact immutability — PASS by independent GitHub blob/diff inspection.

Criteria 95–105: evidence/handoff — PASS. Claude correctly stopped at `AWAITING_AUDIT` and did not close owner-controlled tasks.

## 9. Task closure decision

No M21/M22/UI task is marked complete in this audit commit because M21's live-playtest acceptance is explicitly owner-controlled.

Engineering evidence is sufficient for the owner gate to run. If the owner confirms the V05 manual acceptance flow visually, ChatGPT may then perform the final M21 task-by-task closure, progress recomputation, `lastCompletedTaskId` update, audit-index final state, and next-frontier transition.

If the owner reports a visual/game-feel failure, do not close M21; preserve the exact observation and scope a correction from that owner evidence.

## Final state

**AUDITED_PASS / V06_VALIDATION_CLOSED / OWNER_REQUIRED**

Next required action: owner runs `scenes/debug/m21_real_art_vertical_slice.tscn` via F6 according to `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md` and reports PASS or the exact observed problem.
