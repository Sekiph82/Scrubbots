# M22-C001 V05 — ChatGPT Independent Strict Audit

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited validation commit: `b707fe85413768bd562c10a5c1887aee3e1f75a6`
Validation parent: `2ccc9145701bf930e60cbb780488ede32f33a80c`
Evidence/log commit: `1f51701c12294cf36ff3801e5e93bad256ccaf2c`
Accepted production baseline: `8ded3580a8eacee1c64364e530142e23d6f115db`
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit criteria: `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V05.md`

## Verdict

**CHANGES_REQUIRED / PRODUCTION_BYTE_IDENTITY_ACCEPTED / TWO_OF_THREE_V04_FINDINGS_CLOSED / V06_REAL_DEMO_VALIDATION_ONLY_REQUIRED**

V05 remains validation-only and does not modify accepted production `scripts/` or `scenes/`. The validation commit adds only `tests/m22_v05_final_state_evidence.gd`; the evidence commit adds only `CLAUDE_LOG_V05.md`. Production baseline `8ded3580...` therefore remains accepted.

Two of the three frozen V04 findings are closed by direct evidence:

1. **F-M22-V04-EVIDENCE-002 CLOSED.** The isolated all-aligned-blocked lifecycle now directly observes both ReservationState directions, dispatcher owner/target/agent state, owner-id non-advance, zero agents and unchanged BoardState.
2. **F-M22-V04-EVIDENCE-003 CLOSED.** Shortest/tie-break candidate legality and exact total lengths are independently measured from `ScrubRailGeometry` plus authoritative `ProductionAccessQuery`, then compared with the production-selected exit. The direct all-blocked routing fingerprint also proves zero BoardState mutation.

One strict residual remains:

## F-M22-V05-EVIDENCE-001 — required real demo/Button proof was replaced by a rebuilt parallel chain

**Status: OPEN / BLOCKING ENGINEERING CLOSURE**

The V05 prompt and criteria explicitly require C08 cleanup evidence from the **real laid-out `m22_slot_demo.tscn` inside a real SubViewport and a real C08 Button activation**.

`tests/m22_v05_final_state_evidence.gd` does not do that in Section A. Instead it loads the same Hazard Bot level and rebuilds a separate production-class chain via `_build_real_chain(board)`, then calls `CompleteClearingLoop.activate_slot(2, Vector2(9.222222, 24.0), 6.0)` directly.

That proves the production classes clean ReservationState/dispatcher state correctly, but it is not the requested proof that the **actual demo instance / actual real C08 Button / exact ReservationState and dispatcher objects owned by that demo transaction** perform the cleanup.

This distinction is audit-significant because `CHATGPT_PROMPT_V05.md` explicitly says:

- use the real laid-out M22 demo in a real SubViewport;
- press the real C08 Button;
- inspect the reservation and dispatcher state for that actual dispatch.

The stated reason in `CLAUDE_LOG_V05.md` that production exposes no ReservationState accessor does not make the required observation impossible. The accepted demo stores the real `CompleteClearingLoop` in `inst._loop`, and `CompleteClearingLoop` stores the exact bound ReservationState in `_reservations`; the demo also stores the exact dispatcher in `inst._dispatcher`. A validation-only test can therefore inspect `inst._loop._reservations` and `inst._dispatcher` without modifying production.

### Required closure

One final validation-only script must:

1. instantiate the real `m22_slot_demo.tscn` in a real SubViewport;
2. await layout frames;
3. obtain the real demo ReservationState via the already-bound demo/loop object and the real demo dispatcher;
4. capture pre-dispatch counts;
5. press the real laid-out C08 Button (`panel.get_cell(2).pressed.emit()` or equivalent real signal path);
6. obtain the actual `inst._last_result` owner/target/agent produced by that Button;
7. directly prove the exact ReservationState two-way ownership and dispatcher owner/target/agent mapping while in flight;
8. drive the actual agent to authenticated arrival;
9. after deferred cleanup prove target 380 CLEARED, both ReservationState directions absent, dispatcher owner/target/agent state absent, counts returned to baseline, and zero real ScrubbotAgent remain;
10. persist exact pre/in-flight/post values in runtime output and `CLAUDE_LOG_V06.md`.

No production source change is authorized or needed.

## Accepted V05 runtime evidence

The following V05 evidence is accepted and need not be repeated except for regression sanity:

- all-blocked pre/post reverse ReservationState mappings and dispatcher map absence;
- pending owner-id counter remains unchanged on `NO_REACHABLE_TARGET`;
- shortest fixture: BOTTOM `22.0000`, LEFT `28.0000`, RIGHT/TOP illegal, production BOTTOM;
- tie fixture: LEFT `40.5000`, RIGHT `40.5000`, BOTTOM/TOP illegal, production LEFT;
- direct all-blocked routing BoardState SHA-256 before/after identical;
- full root suite `4798 / 0` and required V03/V04/M20/M21 regressions green;
- zero Magnific/image-generation credits;
- root `TASKS.md` absent from Claude's V05 diff.

## Closure consequence

Engineering closure is withheld only for `F-M22-V05-EVIDENCE-001`. V06 is validation-only and must not reopen accepted production or already-closed V05 evidence.

If the real demo/Button direct-state observation matches the already-proven parallel-chain result, V06 should receive:

`AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`

and ChatGPT may then close eligible `SB-M22-009` and `SB-M22-026..034` rows and open owner F6 visual/game-feel gate `SB-M22-035`.
