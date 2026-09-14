# M21-C001 V10 — ChatGPT Independent Strict Audit

Date: 2026-09-14
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited V10 commit: `141ce6ba4daea13292be68c3397b94e5296db51e`
V10 parent / ChatGPT tracker handoff: `f81672c43536c18178a1f7d6629cc27cd02ddda0`
Owner manual gate: **PASS** (`CHATGPT_OWNER_GATE_V07_PASS.md`)

## Decision

**AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**

M21-C001 is closed. No V11 is required.

The V10 production-immutable reconciliation closes the final frozen V09 direct-evidence residuals without changing accepted gameplay, routing, presentation, scene, project, owner-art, generated-artifact, or tracker source. Together with the accepted V01–V09 evidence and the already-passed owner F6 gate, the first real-art vertical slice now satisfies Strict-v2 closure.

## 1. Exact V10 diff isolation

Canonical `main` at audit start is `141ce6ba4daea13292be68c3397b94e5296db51e`, whose direct parent is ChatGPT's V10 tracker handoff `f81672c43536c18178a1f7d6629cc27cd02ddda0`.

The comparison is exactly one commit and exactly two added files:

1. `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`
2. `tests/m21_v10_final_reservation_evidence.gd`

No `scripts/**`, `scenes/**`, `project.godot`, root `TASKS.md`, owner Hazard Bot PNG, M21 LevelData/preview/metadata/reference composite, or existing V07/V08/V09 test changed in the Claude V10 commit.

Therefore the V10 production-immutability/governance surface is accepted.

## 2. Final ReservationState residual CLOSED

V09 deliberately observed dispatcher assignment state as a proxy for reservation truth. V10 removes that proxy ambiguity.

The fresh V10 test obtains the exact live `ReservationState` already bound into the real owner scene's actual `CompleteClearingLoop` through read-only test introspection of the existing `_loop._reservations` field. It then directly proves:

- the ReservationState is bound to the exact real scene BoardState;
- the real dispatcher reports coherence with the same exact BoardState + ReservationState object via `is_bound_to(board, reservation_state)`;
- no substitute/parallel ReservationState is constructed;
- all reservation counts and mappings are queried directly with `get_reservation_count()`, `get_owner(target)`, and `get_target_for_owner(owner)`.

This satisfies V10-024..028 and closes `F-M21-V09-EVIDENCE-001`.

## 3. No-work visible Button evidence CLOSED

On a fresh owner scene the test directly asserts exactly five SlotViews, obtains the live ReservationState, records reservation count `0`, and presses the real visible no-work slot Button. It then proves:

- legitimate no-work failure;
- live ReservationState count remains exactly `0`;
- BoardState snapshot remains byte/value-identical;
- candidate truth remains unchanged;
- dispatcher active count remains `0`;
- AgentLayer ScrubbotAgent count remains `0`.

With a ReservationState count of zero before and after the transaction, no reservation mapping exists or can survive that transaction. This is direct zero-side-effect evidence on the correct authoritative object.

## 4. First C08 exact reservation lifecycle CLOSED

On a second fresh real owner scene, one real visible C08 Button press naturally produces target `380`, coordinate `(0,19)`.

While the real Scrubbot is in flight, V10 directly proves on the live ReservationState:

- `get_owner(380) == owner_id`;
- `get_target_for_owner(owner_id) == 380`;
- reservation count is exactly `1`.

After authenticated arrival through the accepted production chain it proves:

- both reservation directions return `-1`;
- reservation count returns to `0`;
- whole-board changed-index set is exactly `[380]`;
- C08 candidate set loses exactly `380`;
- dispatcher and AgentLayer return to zero.

This closes the remaining exact same-transaction reservation evidence.

## 5. Rapid x3 real Button lifecycle CLOSED

On a third fresh real owner scene, V10 presses the actual C08 Button three times before the first completion. It directly proves:

- all three succeed naturally;
- targets are exactly `380,381,382`;
- owner IDs are unique;
- live ReservationState count is exactly `3`;
- all three exact bidirectional ReservationState pairs exist;
- AgentLayer contains exactly `3` real ScrubbotAgent children;
- the actual C08 SlotView is active.

It then completes the agents one at a time and directly proves the synchronized sequence:

- first arrival: reservation count `2`, first pair absent, remaining pairs intact, AgentLayer `2`, slot still active;
- second arrival: reservation count `1`, second pair absent, final pair intact, AgentLayer `1`, slot still active;
- final arrival: reservation count `0`, final pair absent, AgentLayer `0`, slot returns idle.

The accepted V09 exact board/candidate law is also reasserted: only `{380,381,382}` clears and only those three C08 candidates disappear.

This closes the rapid-input/presentation portion of `F-M21-V09-EVIDENCE-002`.

## 6. Reset-in-flight exact identity evidence CLOSED

On a fourth fresh real owner scene, two real C08 Button presses are left in flight. V10 directly proves before reset:

- exact targets `380,381` in order;
- unique owner IDs;
- two distinct ScrubbotAgent instance identities;
- AgentLayer contains exactly those two identities;
- live ReservationState count is exactly `2`;
- both exact bidirectional reservation pairs exist.

After canonical reset through the real scene's `reset_presentation()` / bound `CompleteClearingLoop.reset()` chain, it directly proves:

- live ReservationState count is exactly `0`;
- both old target→owner and owner→target pairs are absent;
- dispatcher active count is `0`;
- complete BoardState snapshot is identical;
- both in-flight targets remain ACTIVE;
- C08 candidate set remains identical/coherent;
- after deferred cleanup neither captured agent identity remains and AgentLayer is `0`;
- a fresh real C08 Button again naturally selects `380/(0,19)`.

This closes the reset portion of `F-M21-V09-EVIDENCE-002`.

## 7. Regression and immutable production basis

Claude records Godot `4.7.2.stable.official.ed1daf0bf` and did not alter the installed engine.

Required evidence is green:

- V10 final reservation evidence: PASS;
- V09 direct-evidence reconciliation: PASS;
- V08 corridor validation: PASS;
- V07 corridor smoke: PASS;
- V06 tall-layout smoke: PASS;
- V05 playtest smoke: PASS;
- M21 full 400-cell real-art smoke: PASS, all 400 cells cleared, all five colors, no orphan;
- full root suite: **4617 checks / 0 failures / ALL PASS**;
- required M20 queue-free and lifecycle regressions: PASS;
- owner scene headless boot: zero SCRIPT/Parse errors;
- M21 LevelData/preview/metadata rebuild: UNCHANGED;
- reference composite rebuild: UNCHANGED;
- `git diff --check`: clean for authorized V10 work.

The ten locked V07 production identities are recorded unchanged again in the V10 log. The exact V10 committed diff itself also proves none of those production paths moved during V10.

## 8. Owner gate remains valid

The owner manually tested the accepted V07 runtime in Godot and explicitly reported that all required behavior was correct:

- visible-slot-click-only activation;
- SPACE dispatch removed;
- Scrubbot leaves the clicked slot;
- one-cell exterior walking corridor behavior;
- fresh C08 target begins at the bottom-most/left-most `(0,19)` cell;
- subsequent clearing follows the expected accessible order;
- real target selection, routing and clearing presentation behave correctly.

V08–V10 are production-immutable, so no accepted runtime behavior changed after that owner PASS. No repeated owner gate is required.

## 9. M21 closure

The following M21 rows are eligible for closure:

- SB-M21-001..012
- SB-UI-014..016

M22 remains a separate milestone. The functional SlotView subset pulled forward for the M21 owner harness does not automatically close final M22 production-UI rows.

ChatGPT now owns the canonical tracker update, including checkbox closure, progress recomputation, `lastCompletedTaskId`, and advancement to the M22 frontier.

## Final

**M21-C001: AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**

No V11. Next project frontier: **M22 — Production Slot UI**.