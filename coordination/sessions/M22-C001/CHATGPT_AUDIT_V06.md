# M22-C001 V06 — ChatGPT Independent Strict Audit

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited validation commit: `4253da04e04af09c46e8b6a56466d2c857bd9a84`
Validation parent: `6d4639ec1b4e2e19b3047d3efe1fea064cfd3c41`
Evidence/log commit: `10adfad428e668e6031ce7dd86e92270ba6d9e3b`
Accepted production baseline: `8ded3580a8eacee1c64364e530142e23d6f115db`
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit criteria: `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V06.md`

## Verdict

**AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE**

The single frozen V05 residual `F-M22-V05-EVIDENCE-001` is closed. V06 proves the required C08 lifecycle on the actual laid-out `m22_slot_demo.tscn` instance, through the actual C08 Button signal path, while inspecting the exact ReservationState, dispatcher and AgentLayer owned by that same demo transaction.

No production correction is required. Production `scripts/` and `scenes/` remain byte-identical to accepted implementation commit `8ded3580a8eacee1c64364e530142e23d6f115db`.

## 1. Scope and immutability

Independent Git comparison confirms `6d4639e... -> 4253da0...` contains exactly one changed file:

- `tests/m22_v06_real_demo_state_evidence.gd` — added validation-only evidence.

Independent comparison `4253da0... -> 10adfad...` contains exactly one changed file:

- `coordination/sessions/M22-C001/CLAUDE_LOG_V06.md` — added handoff evidence.

Independent comparison from accepted production baseline `8ded3580...` to V06 evidence HEAD `10adfad...` contains only M22 audit/prompt/log files and V04/V05/V06 validation tests. There is no `scripts/` or `scenes/` change after the accepted production baseline.

Root `TASKS.md` and historical M21 evidence are absent from Claude's V06 changes. Zero Magnific/image-generation credits were spent.

## 2. Real demo / real Button closure

`tests/m22_v06_real_demo_state_evidence.gd` directly satisfies the exact V06 transaction requirement:

- instantiates `res://scenes/demo/m22_slot_demo.tscn` in a real `SubViewport(1080,2160)`;
- awaits three process/layout frames;
- observes exactly five real SlotCell/Button instances;
- reads the exact demo ReservationState from `inst._loop._reservations`;
- uses the exact same demo dispatcher `inst._dispatcher`;
- uses the real demo AgentLayer;
- activates by `panel.get_cell(2).pressed.emit()`;
- reads the real Button transaction result from `inst._last_result`;
- does not build a parallel ReservationState/dispatcher/loop chain.

The natural C08 result is target `380`, coordinate `(0,19)`, with a real demo agent.

## 3. Same-transaction in-flight ownership

Runtime evidence on the exact demo objects proves:

- `owner_id = 0`;
- `ReservationState.get_owner(380) == 0`;
- `ReservationState.get_target_for_owner(0) == 380`;
- `dispatcher.has_owner(0) == true`;
- `dispatcher.get_target_for_owner(0) == 380`;
- `dispatcher.get_agent_for_owner(0)` is the exact Button-created agent.

This closes the remaining concern that prior evidence could have been valid only on a separately reconstructed gameplay chain.

## 4. Same-transaction authenticated arrival and cleanup

The exact Button-created agent is driven to completion through its accepted agent completion path. After deferred cleanup, runtime evidence proves:

- target 380 is `CLEARED`;
- ReservationState count returns to pre-dispatch baseline `0`;
- `get_owner(380) == -1`;
- `get_target_for_owner(owner_id) == -1`;
- dispatcher active count returns to baseline `0`;
- `has_owner(owner_id) == false`;
- dispatcher `get_target_for_owner(owner_id) == -1`;
- dispatcher `get_agent_for_owner(owner_id) == null`;
- real demo AgentLayer contains zero `ScrubbotAgent` after deferred cleanup.

The exact pre/in-flight/post values are persisted in `CLAUDE_LOG_V06.md`.

## 5. Regression evidence

Recorded validation remains green:

- Godot `4.7.2.stable.official.ed1daf0bf`;
- root suite: `4798` checks, `0` failures, exit `0`;
- V06 real-demo state evidence: PASS, exit `0`;
- V05 final-state evidence: PASS, exit `0`;
- V04 final evidence: PASS, exit `0`;
- V03 connector evidence: PASS, exit `0`;
- M22 Railroad responsive smoke: PASS, exit `0`;
- M22 V01 responsive/component smoke: PASS, exit `0`;
- M21 real-art full 400-cell clear: PASS, exit `0`;
- M21 V10 reservation/direct evidence: PASS, exit `0`;
- required M20 lifecycle/clearing smokes: PASS, exit `0`;
- `git diff --check`: clean.

Historical M21 V08/V09 assertions whose only failure encodes the deliberately superseded adjacent-ring geometry remain historical and unchanged. They do not reopen current Railroad V1 production behavior.

## 6. Frozen finding closure

`F-M22-V05-EVIDENCE-001` — **CLOSED**.

All earlier frozen Railroad V1 findings from V02 through V05 are now closed together by the accepted implementation plus V03/V04/V05/V06 direct evidence.

## 7. M22 engineering task consequence

The following Railroad engineering rows are now eligible for ChatGPT tracker closure:

- `SB-M22-009`
- `SB-M22-026`
- `SB-M22-027`
- `SB-M22-028`
- `SB-M22-029`
- `SB-M22-030`
- `SB-M22-031`
- `SB-M22-032`
- `SB-M22-033`
- `SB-M22-034`

`SB-M22-035` is **not** engineering-complete. It is now the separate **OWNER F6 visual/game-feel acceptance gate**.

No M23 work is authorized by this audit.

## 8. Owner F6 gate

Engineering evidence is sufficient to begin owner visual acceptance. The owner should run the M22 demo and visually confirm, on the real rendered experience:

1. real pixel artwork is visible and readable;
2. at least two logical cells of breathing room exist around the artwork;
3. the same reusable robotic railroad is visible on all four sides;
4. rounded rail corners look intentional and clean;
5. exactly five slots sit below the rail;
6. clicking a slot visibly starts the Scrubbot from that slot and travels through the connector into the bottom rail;
7. exterior travel stays on the rail and turns through rail corners;
8. exit from the rail is aligned with the assigned target row/column;
9. final target approach is orthogonal, with no diagonal shortcut or early rail departure;
10. first fresh Hazard Bot C08 visibly resolves naturally to target `380 / (0,19)`;
11. overall railroad scale, spacing, contrast and motion feel acceptable to the owner.

Owner approval of this visual/game-feel gate is required before `SB-M22-035` may close and before any milestone transition that depends on F6 acceptance.
