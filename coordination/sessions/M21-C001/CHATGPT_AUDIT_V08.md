# M21-C001 V08 — ChatGPT Independent Strict Audit

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited V08 implementation commit: `6d54133cd41ad2d91cb340f49182d1c6365df5c2`
V08 parent: `365e71e864ec623e3a05d156d5e0485555d240d6`
Owner manual gate: **PASS already recorded** in `CHATGPT_OWNER_GATE_V07_PASS.md`

## Decision

**CHANGES_REQUIRED / PRODUCTION_ACCEPTED / DIRECT_EVIDENCE_RECONCILIATION_ONLY / V09_REQUIRED**

This is **not** a production-defect verdict. The accepted V07 production candidate remains accepted, the V07 owner manual Godot gate remains PASS, and V08 introduced no production/source/scene/project change. V09 is a final validation-only reconciliation because several auditor-authored V08 criteria were not observed on the exact surface they required.

No owner re-test is required unless V09 discovers a real source defect and a later production correction changes the owner-accepted behavior.

## 1. Canonical V08 handoff is now valid

The earlier `CHATGPT_AUDIT_V08_HANDOFF_BLOCKED.md` recorded a temporary handoff problem: the V08 commit/log were not yet on canonical `main` and the pasted draft still contained `<FILL_...>` placeholders.

That handoff defect is now resolved:

- canonical `main` contains `CLAUDE_LOG_V08.md`;
- all `<FILL_...>` placeholders are replaced with concrete evidence;
- root suite is logged as **4617/4617 PASS**;
- V08/V07/V06/V05/M21/M20 regressions are logged PASS;
- 59×59 isolated routing diagnostic is logged as `7.488 ms`;
- all ten locked blobs are recorded unchanged;
- the V08 commit is present on canonical `main`.

The pre-audit blocked artifact remains historical evidence of the earlier incomplete handoff; it is superseded by this full audit.

## 2. Exact V08 diff isolation

Comparing V08 parent `365e71e...` to V08 handoff `6d54133...` yields exactly one commit and exactly two added files:

1. `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`
2. `tests/m21_v08_corridor_validation.gd`

No production source, scene, `project.godot`, M21 generated artifact, owner PNG, or root `TASKS.md` changed in the Claude V08 commit.

Therefore V08-004..012, V08-109, V08-112 and V08-115 are accepted at the committed-diff level.

## 3. Production blob lock accepted

The committed V08 diff is validation-only, so the accepted V07 production tree is preserved. Independent canonical spot checks also confirm, among others:

- `production_routing_system.gd` = `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`
- `m21_real_art_vertical_slice.gd` = `153c042a17dc0ef9e83699a0beb2932217057ff4`
- `complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`

The V08 log records the remaining seven locked identities exactly as required. No evidence suggests any accepted production blob moved.

## 4. Strong V08 evidence accepted

The fresh V08 validation test is independently structured and materially stronger than a prose-only replay of V07.

Accepted evidence includes:

- owner controller source is scanned for the removed SPACE/debug-dispatch symbols;
- the real owner scene is instantiated and exactly five SlotViews are observed;
- disconnecting `slot_activated` prevents the real Button path from dispatching, reconnecting restores dispatch;
- the real C08 Button path naturally selects target index `380`, coordinate `(0,19)`;
- route start is the mapped visible slot anchor and route end is `(0.5,19.5)`;
- the detached real route revalidates through unchanged `RouteValidator + ProductionAccessQuery`;
- a recording access wrapper shows planner classifications do not expand beyond the legal one-cell exterior ring;
- a blocking-ring wrapper makes the same far-left-bottom target unreachable without retargeting, proving the ring is load-bearing;
- bottom/top/left/right, rectangular, 59×59, enclosed-interior, opened-interior and diagonal-blocking arrangements are exercised;
- authenticated first arrival clears target 380 and cleans the real owner-scene dispatcher/agent presentation;
- production-bundle reservation/candidate cleanup is exercised;
- rapid three-assignment ordering `380,381,382` and bidirectional reservations are exercised at the core production bundle;
- reset with two in-flight exterior-routed assignments is exercised at the core production bundle;
- root suite and historical M21/M20 regressions are logged green.

No source-level or runtime evidence reviewed in V08 indicates a production regression.

## 5. Frozen direct-evidence gaps

Per AL-054/full-surface finding freeze, the following is the complete V08 reconciliation set. V09 must address all of these together. Do not create serial micro-prompts.

### G-V08-01 — V08-032 reservation zero-side-effect is not directly asserted

V08-032 requires a no-work visible slot click to create **zero agent, zero reservation and zero clear** side effects.

The V08 scene test directly checks:

- no successful assignment,
- no new agent,
- board ACTIVE count remains 400.

It does **not** directly compare reservation count/mapping before and after the no-work Button click.

Production behavior is likely correct and inherited rollback tests are green, but the fresh V08 criterion asked for direct evidence.

### G-V08-02 — V08-046/047 corner-side evidence is weaker than the criterion

The corner test asserts:

- route succeeds;
- some returned point has `x < 0`;
- some returned point has `y < 0`.

A single top-left corner point can satisfy both booleans. Therefore the assertion does not strictly prove traversal evidence on **two distinct adjacent side interiors**.

V09 must distinguish side cells from corner cells and prove at least one left-side non-corner exterior point and at least one top-side non-corner exterior point in the claimed corner case (or an equivalent adjacent-side pair), with a coherent route transition.

Again, this is an evidence-strength issue, not a demonstrated routing defect.

### G-V08-03 — V08-064..066 are split across different observation surfaces

The real owner-scene first-clear test proves target 380 becomes CLEARED, but it does not directly snapshot the whole BoardState and prove **the only changed cell is 380**.

The candidate-index drop and exact reservation cleanup required by V08-065/066 are then proven in a separate core-bundle test rather than on that same fresh real owner-scene Button-path assignment.

V09 must prove on one fresh owner-scene Button-path transaction:

- pre/post whole-board state delta is exactly `{380}`;
- C08 candidate set loses exactly 380;
- target↔owner reservation exists while in flight;
- that exact pair is absent after authenticated clear;
- dispatcher/AgentLayer cleanup completes.

### G-V08-04 — V08-069..076 require a fresh real scene/Button path, but V08 E uses direct loop activation

This is the largest direct mismatch.

V08-069 explicitly requires:

> on a fresh scene, press C08 at least three times through the real Button path before first accepted arrival.

The committed V08 E section instead builds a production core bundle with `_wire(...)` and invokes:

`CompleteClearingLoop.activate_slot(...)`

directly three times.

That is useful core evidence, but it bypasses the real SlotView/Button/controller/presentation path required by V08-069.

In the same section, V08-074 requires visible slot active presentation to remain active while any C08 assignment is in flight. The committed V08 E test contains no direct SlotView active-presentation assertion.

V09 must use one fresh real owner scene, three real C08 Button presses before the first arrival, store each real assignment result, prove `380,381,382`, unique owners and exact reservations, and directly prove the C08 SlotView stays active until its final in-flight assignment is finished, then returns inactive/idle according to the accepted V05/V07 presentation contract.

It must also prove the three targets transition ACTIVE→CLEARED exactly once each with no unrelated board mutation.

### G-V08-05 — V08-077/078 require a fresh real scene and exact pre-reset snapshot; V08 H uses the direct core bundle

The V08 H reset test again uses `_wire(...)` + direct `activate_slot(...)` rather than the fresh owner scene required by the V08 criteria.

Its pre-reset evidence is also partial: it records two target IDs plus aggregate active/reservation counts, not the exact BoardState/candidate/reservation/agent truth requested by V08-078.

V09 must perform reset-in-flight on a fresh real owner scene after two real C08 Button presses and capture exact pre-reset truth sufficient to compare:

- complete BoardState state vector or exact equivalent;
- C08 candidate set;
- exact reservation target→owner and owner→target pairs;
- dispatcher active assignments/count;
- AgentLayer ScrubbotAgent count/identities where available.

After canonical `CompleteClearingLoop.reset()`, it must directly prove:

- assignments zero;
- reservations zero / exact old pairs absent;
- board state unchanged by reset;
- in-flight targets remain ACTIVE;
- candidate truth remains coherent;
- no orphan agents after deferred frames;
- a new real C08 Button press can again naturally select `380/(0,19)`.

## 6. Findings explicitly NOT opened

The audit does **not** reopen:

- owner-approved V07 manual behavior;
- bottom-most/left-most TargetSelector policy;
- one-cell exterior-ring production architecture;
- slot-click-only owner activation;
- M19 dispatcher authority;
- M20 clearing authority;
- V03 production-art path safety;
- V05 presentation/source corrections;
- V06 tall-layout closure.

No V09 production/source change is authorized merely to make evidence easier.

## 7. V09 closure law

V09 is **validation-only and production-immutable**.

Authorized V09 surface:

- one new auditor-authored test, preferably `tests/m21_v09_direct_evidence_reconciliation.gd`;
- `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`;
- no root `TASKS.md` edit by Claude;
- no `scripts/**`, `scenes/**`, `project.godot`, M21 artifact or owner PNG change.

If the fresh real-scene V09 evidence exposes a genuine production defect, Claude must stop `BLOCKED` and must not patch it.

If V09 satisfies the frozen gaps, root regressions remain green, production remains byte-identical, and the independent ChatGPT V09 audit passes, ChatGPT will directly perform **M21 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**, close the eligible M21/SB-UI rows, recompute progress, and advance the tracker. The owner does not repeat the already-passed V07 manual test unless a later production correction changes accepted behavior.
