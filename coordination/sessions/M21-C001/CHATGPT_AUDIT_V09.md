# M21-C001 V09 — ChatGPT Independent Strict Audit

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited V09 commit: `4bfe47dc1ce7731d75a099d715751fcfdb470c89`
Parent: `4d1ac43afd32285a692242be3cc8db422877ac57`
Owner manual gate: **PASS** (`CHATGPT_OWNER_GATE_V07_PASS.md`)

## Decision

**CHANGES_REQUIRED / PRODUCTION_ACCEPTED / FINAL_DIRECT-EVIDENCE_RESIDUALS_FROZEN / V10_VALIDATION_ONLY_REQUIRED**

This is not a production-defect verdict. V09 changed only its new validation test plus `CLAUDE_LOG_V09.md`; accepted gameplay/routing/presentation source remains byte-identical. The V07 owner manual PASS remains valid. No owner re-test is required unless a later production correction changes accepted behavior.

V09 materially closes the largest V08 evidence mismatches: the fresh real scene and real visible SlotView Button path are now used for the first clear, rapid x3 and reset-in-flight transactions; whole-board deltas and slot active presentation are observed directly; the corner proof now excludes the corner from satisfying both adjacent-side assertions.

However, the auditor-authored V09 contract explicitly required exact ReservationState evidence and several exact scene-state assertions. The committed V09 test knowingly substitutes dispatcher assignment truth for ReservationState truth. Because this cycle exists specifically to reconcile direct evidence, inherited lockstep proofs cannot replace the exact observation surface requested by V09.

## 1. Exact V09 diff isolation

Comparing parent `4d1ac43...` to V09 handoff `4bfe47dc...` yields exactly one commit and exactly two added files:

1. `tests/m21_v09_direct_evidence_reconciliation.gd`
2. `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`

No `scripts/**`, `scenes/**`, `project.godot`, M21 generated artifact, owner PNG or root `TASKS.md` changed in the V09 implementation commit.

Therefore the V09 production-immutable governance surface is accepted.

## 2. Accepted V09 direct evidence

The following V09 evidence is accepted:

- real no-work SlotView Button is the stimulus and the board/candidate/agent/dispatcher state stays unchanged;
- corner routing is now proven on two distinct adjacent **non-corner** ring sides by dense crossed-cell sampling;
- first real C08 Button transaction naturally selects `380/(0,19)` from the mapped visible slot anchor;
- first-clear whole-board changed-index set is exactly `[380]`;
- first-clear C08 candidate delta is exactly `{380}`;
- rapid three real C08 Button presses naturally yield `380,381,382` with unique owner IDs;
- the actual C08 SlotView remains active after the first and second arrivals and returns idle after the final arrival;
- rapid-x3 whole-board delta is exactly `{380,381,382}` and the C08 candidate set loses exactly those three;
- reset-in-flight is now exercised through a fresh real owner scene after two real Button presses;
- reset preserves the board-state snapshot and C08 candidate truth, removes dispatcher assignments and leaves no orphan agents;
- a new real C08 Button press after reset naturally selects `380/(0,19)` again;
- V09/V08/V07/V06/V05/M21/M20 regressions are logged PASS and the root suite remains `4617/4617 PASS`;
- Godot version drift is reported truthfully as `4.7.2.stable.official.ed1daf0bf` without a V09 engine mutation.

No reviewed evidence indicates a production regression.

## 3. Frozen final residual finding set

Per AL-054, this is the complete residual set. V10 must close all of it in one validation-only pass. Do not create serial micro-prompts.

### F-M21-V09-EVIDENCE-001 — exact ReservationState truth is still not directly observed

The V09 test explicitly documents that the owner scene exposes no ReservationState getter and therefore uses the ScrubbotDispatcher owner→target assignment map as a proxy for reservation lifecycle.

That is useful evidence, but it does not satisfy the exact V09 contract for ReservationState itself. In particular, V09-028/034/035, V09-049/053/054/061/062, V09-066/072/073/083 and V09-089/094 require direct reservation count and/or exact target→owner plus owner→target mappings.

The dispatcher source itself states that reservation storage belongs to the separate injected `ReservationState`, held as `_reservations`; dispatcher `_active` is a distinct assignment dictionary. M19/M20 strict suites prove these layers are intended to remain coherent, but the purpose of this reconciliation pass is direct observation, not inherited inference.

V10 must inspect the exact ReservationState instance already bound into the real scene/loop without adding a production hook. Test-only read-only introspection of existing scene/loop fields is authorized. For example, if the current scene exposes `_loop` and the unchanged loop holds `_reservations`, the V10 test may read that exact existing object and call its existing read-only queries. Production source must remain byte-identical.

Required direct observations include:

- no-work Button: reservation count remains exactly zero; no mapping appears;
- first C08 Button: exact `380 -> owner_id` and `owner_id -> 380` exist in flight and are both absent after authenticated clear;
- rapid x3 Button: exact bidirectional ReservationState mappings exist for all three targets/owners in flight and are all absent after completion;
- reset-in-flight: exact ReservationState count/mappings are captured before reset, count becomes zero and both old bidirectional pairs are absent after reset.

### F-M21-V09-EVIDENCE-002 — several exact scene assertions requested by V09 are still implicit or absent

These are evidence gaps, not demonstrated source defects:

1. V09-025 asks the fresh no-work scene to directly prove **exactly five SlotViews**; the V09 test indexes the slot array but does not assert its size.
2. V09-075 asks rapid-x3 to directly prove the AgentLayer contains exactly the expected in-flight real ScrubbotAgent count. The V09 test proves slot-active presentation and eventual zero cleanup but never asserts `3 -> 2 -> 1 -> 0` AgentLayer counts while completing the three assignments.
3. V09-086 asks the reset scenario to prove the two accepted targets are the unique expected bottom-row C08 targets; V09 does not directly assert `380,381` and uniqueness before reset.
4. V09-091 asks the reset scenario to capture AgentLayer identities/count before reset; V09 asserts count `2` but does not capture/compare the two actual agent identities.

V10 must close these exact cells directly on fresh real owner scenes.

## 4. Findings explicitly NOT reopened

V10 must not reopen or rewrite:

- V07 owner manual PASS;
- owner-locked bottom-most/left-most TargetSelector policy;
- one-cell exterior-routing-ring architecture;
- visible-slot-click-only owner activation and removed SPACE fallback;
- accepted V07 production routing source;
- M19 dispatcher authority;
- M20 clearing authority;
- V05 presentation corrections;
- V06 tall-layout validation;
- accepted V08 ring-domain/load-bearing/59×59 evidence;
- accepted V09 corner, whole-board delta and slot active-presentation evidence.

## 5. V10 closure law

V10 is **validation-only and production-immutable**.

Authorized implementation surface:

- `tests/m21_v10_final_reservation_evidence.gd`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`

Claude must not modify root `TASKS.md`, production source, scenes, `project.godot`, owner art, M21 generated artifacts, or existing V07/V08/V09 tests.

If direct ReservationState inspection reveals a genuine production mismatch, stop `BLOCKED` without patching production.

If V10 closes the frozen residuals, production remains byte-identical, regressions remain green and ChatGPT's independent V10 audit passes, ChatGPT will perform **M21 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**, close eligible M21/SB-UI rows, recompute progress and advance the project frontier to M22. No repeat owner playtest is required because production remains unchanged and V07 owner acceptance is already recorded.
