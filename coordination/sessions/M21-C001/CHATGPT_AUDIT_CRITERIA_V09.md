# M21-C001 V09 — Final Direct-Evidence Reconciliation Strict Audit Criteria

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Scope: validation-only reconciliation of the frozen V08 evidence gaps
Owner gate: **PASS already recorded** in `CHATGPT_OWNER_GATE_V07_PASS.md`
Production basis: accepted V07 production candidate, preserved byte-for-byte through V08

V09 is **production immutable**. It must not change accepted gameplay, routing, scene, project or M21 artifact source merely to make a test pass. If any fresh real-scene test exposes a genuine production defect, stop `BLOCKED` and do not patch production.

## A. Governance / immutable scope

- **V09-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **V09-002** Safely sync with current `origin/main` before work.
- **V09-003** Preserve all owner/local tracked and untracked work.
- **V09-004** Read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, the M21 V07 owner PASS artifact, V08 prompt/criteria/log/audit and this V09 criteria file.
- **V09-005** Do not modify root `TASKS.md`; ChatGPT owns tracker writes.
- **V09-006** Do not modify accepted `scripts/**` source.
- **V09-007** Do not modify accepted `scenes/**` source.
- **V09-008** Do not modify `project.godot`.
- **V09-009** Do not modify owner Hazard Bot PNG or M21 LevelData/preview/metadata/reference composite.
- **V09-010** Do not weaken, delete or rewrite existing V08/V07 tests to manufacture a pass.
- **V09-011** Prefer one new test file: `tests/m21_v09_direct_evidence_reconciliation.gd`.
- **V09-012** V09 committed implementation diff contains only the new V09 test and `CLAUDE_LOG_V09.md`.
- **V09-013** No force push, destructive reset/clean/restore or owner-work deletion.
- **V09-014** If fresh validation reveals a production defect, stop `BLOCKED` without changing production.

## B. Locked production identity

Recheck and log exact canonical blob identities after V09:

- **V09-015** `production_routing_system.gd` = `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`.
- **V09-016** `m21_real_art_vertical_slice.gd` = `153c042a17dc0ef9e83699a0beb2932217057ff4`.
- **V09-017** Hazard Bot owner PNG = `b565743ba52699899007882b750b7c8e7cdd00f9`.
- **V09-018** `complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- **V09-019** `scrubbot_dispatcher.gd` = `eee10149e4f116af6706beec832042352bf3a6dd`.
- **V09-020** `target_selector.gd` = `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.
- **V09-021** `production_access_query.gd` = `7ba9d13556abb0e3a0a6d281449438330a25386d`.
- **V09-022** `board_presentation.gd` = `2093df48d367903d332a910dfb3369154831a9ed`.
- **V09-023** `slot_view.gd` = `480dffc0ee135150bd3dd2258f002264273ead10`.
- **V09-024** `scrubbot_agent.gd` = `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370`.

## C. G-V08-01 — no-work Button click exact zero side effects

Use a **fresh real owner scene** and the real visible no-work SlotView Button path.

- **V09-025** Fresh scene starts with exact five SlotViews.
- **V09-026** Capture complete BoardState state vector before the no-work click.
- **V09-027** Capture dispatcher active count before the click.
- **V09-028** Capture reservation count and exact mappings before the click.
- **V09-029** Capture AgentLayer ScrubbotAgent count before the click.
- **V09-030** Capture relevant candidate sets before the click.
- **V09-031** Stimulus is the real visible no-work Button path, not direct `request_slot()` or direct loop activation.
- **V09-032** Result is a legitimate no-work/failure result.
- **V09-033** Complete BoardState state vector is byte/value-identical after the click.
- **V09-034** Reservation count is exactly unchanged and remains zero.
- **V09-035** No target→owner or owner→target mapping appears.
- **V09-036** Dispatcher active count is exactly unchanged/zero.
- **V09-037** AgentLayer ScrubbotAgent count is exactly unchanged/zero.
- **V09-038** Candidate sets are exactly unchanged.

## D. G-V08-02 — distinct adjacent-side corner evidence

Use unchanged production routing with a fresh board/access bundle.

- **V09-039** Construct a route whose legal solution genuinely transitions between two adjacent exterior sides.
- **V09-040** The route succeeds for the originally requested target with no retarget.
- **V09-041** Route validates through unchanged `RouteValidator + ProductionAccessQuery`.
- **V09-042** Directly identify at least one exterior **left-side non-corner** route point/cell (`x == -1` with board-row `y` inside `0..H-1`) or equivalent adjacent side.
- **V09-043** Directly identify at least one exterior **top-side non-corner** route point/cell (`y == -1` with board-column `x` inside `0..W-1`) or equivalent adjacent side.
- **V09-044** A single corner cell may not satisfy both V09-042 and V09-043.
- **V09-045** Evidence records route point/cell order sufficient to show a coherent transition between the two adjacent sides.
- **V09-046** No route point/classification expands beyond the owner-locked one-cell ring.

## E. G-V08-03 — first real Button clear exact same-transaction evidence

Use one **fresh real owner scene** and one real visible C08 Button click.

- **V09-047** Capture full 400-cell BoardState state vector before click.
- **V09-048** Capture complete C08 candidate set before click.
- **V09-049** Capture reservation/dispatcher/AgentLayer pre-state.
- **V09-050** Press the real C08 SlotView Button.
- **V09-051** Assignment naturally succeeds with target index exactly `380` / coordinate `(0,19)`.
- **V09-052** Assignment begins at the exact visible clicked SlotView spawn anchor mapped through BoardPresentation.
- **V09-053** While assignment is in flight, exact reservation `380 -> owner_id` exists.
- **V09-054** While assignment is in flight, exact reverse reservation `owner_id -> 380` exists.
- **V09-055** Before arrival, target 380 remains ACTIVE.
- **V09-056** Drive/authenticate the real ScrubbotAgent to completion through the normal production arrival chain.
- **V09-057** Compute full before/after BoardState delta and prove the changed-index set is exactly `[380]`.
- **V09-058** Target 380 is CLEARED after arrival.
- **V09-059** Every other board index has exactly its pre-click state.
- **V09-060** Post-clear C08 candidate set equals pre-clear C08 set minus exactly 380.
- **V09-061** Exact `380 -> owner` reservation is absent after clear.
- **V09-062** Exact `owner -> 380` reservation is absent after clear.
- **V09-063** Dispatcher active count returns to zero.
- **V09-064** AgentLayer returns to zero ScrubbotAgent children after deferred cleanup.

## F. G-V08-04 — rapid x3 on fresh real scene through real Button path

Use a second **fresh real owner scene**. Do not use `_wire()` + direct `activate_slot()` as the stimulus.

- **V09-065** Obtain the real visible C08 SlotView/Button.
- **V09-066** Capture full board/candidate/reservation/dispatcher/AgentLayer pre-state.
- **V09-067** Press the real C08 Button three times before driving the first accepted agent to arrival.
- **V09-068** Store the actual assignment result produced after each Button press before the next overwrite.
- **V09-069** All three are accepted under current production behavior, or if a legitimate refusal occurs follow the V08-075 zero-side-effect fallback without weakening rules.
- **V09-070** If all three are accepted, target order is exactly `380,381,382`.
- **V09-071** All accepted owner IDs are unique.
- **V09-072** Every accepted target has exact target→owner reservation mapping.
- **V09-073** Every accepted owner has exact owner→target reservation mapping.
- **V09-074** No duplicate target assignment occurs.
- **V09-075** AgentLayer contains exactly the expected in-flight real ScrubbotAgent count.
- **V09-076** Directly inspect the actual C08 SlotView presentation/model state and prove it is active while at least one C08 assignment remains in flight.
- **V09-077** Complete only the first assignment and prove the C08 SlotView remains active while the other two are still in flight.
- **V09-078** Complete the second assignment and prove it remains active while the third remains in flight.
- **V09-079** Complete the final assignment and prove the slot returns to its accepted non-active/idle state after cleanup.
- **V09-080** Full BoardState delta after all three completions is exactly `{380,381,382}`.
- **V09-081** Each of 380/381/382 transitions ACTIVE→CLEARED and no unrelated index changes.
- **V09-082** Candidate set loses exactly 380/381/382 and no unrelated C08 candidate.
- **V09-083** All three reservation pairs are gone after completion.
- **V09-084** Dispatcher and AgentLayer return to zero active/orphan agents after deferred cleanup.

## G. G-V08-05 — reset-in-flight on a fresh real scene with exact snapshot

Use a third **fresh real owner scene** and the real C08 Button path.

- **V09-085** Press real C08 Button twice without completing either agent.
- **V09-086** Both assignments are accepted and target two unique expected bottom-row C08 cells.
- **V09-087** Capture complete BoardState state vector before reset.
- **V09-088** Capture exact C08 candidate set before reset.
- **V09-089** Capture exact target→owner and owner→target reservation pairs for both assignments.
- **V09-090** Capture dispatcher active assignments/count before reset.
- **V09-091** Capture AgentLayer ScrubbotAgent identities/count before reset.
- **V09-092** Invoke canonical `CompleteClearingLoop.reset()` through the real scene/bound loop.
- **V09-093** Dispatcher active count becomes exactly zero.
- **V09-094** Reservation count becomes exactly zero and both old bidirectional pairs are absent.
- **V09-095** Full BoardState state vector after reset equals the pre-reset vector exactly.
- **V09-096** Both in-flight targets remain ACTIVE.
- **V09-097** C08 candidate set after reset equals the pre-reset candidate set exactly.
- **V09-098** After deferred cleanup AgentLayer contains zero ScrubbotAgent children.
- **V09-099** A new real C08 Button click after reset naturally succeeds and again selects `380/(0,19)`.

## H. Regression / runtime evidence

- **V09-100** Record exact `godot --version`; do not modify the engine in V09.
- **V09-101** Run `tests/m21_v09_direct_evidence_reconciliation.gd` and log PASS/exit 0.
- **V09-102** Run unchanged V08 corridor validation and log PASS.
- **V09-103** Run unchanged V07 corridor smoke and log PASS.
- **V09-104** Run unchanged V06 tall-layout smoke and log PASS.
- **V09-105** Run unchanged V05 playtest smoke and log PASS.
- **V09-106** Run unchanged M21 400-clear real-art smoke and log PASS.
- **V09-107** Run full root `tests/run_tests.gd`; log exact check count, zero failures and exit 0.
- **V09-108** Run required M20 queue-free/lifecycle regression smokes and log PASS.
- **V09-109** Owner scene headless boot has zero SCRIPT/Parse errors.
- **V09-110** M21 build rerun remains LEVEL/PREVIEW/METADATA UNCHANGED.
- **V09-111** Reference-composite rerun remains UNCHANGED.
- **V09-112** `git diff --check` is clean for authorized V09 changes.

## I. Handoff / closure law

- **V09-113** Create `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md` with exact commands/results and evidence tuples.
- **V09-114** Root `TASKS.md` remains byte-identical throughout Claude work.
- **V09-115** No M21/M22/SB-UI checkbox is closed by Claude.
- **V09-116** Claude authors no audit verdict/file.
- **V09-117** V09 commit changes only `tests/m21_v09_direct_evidence_reconciliation.gd` and `CLAUDE_LOG_V09.md`.
- **V09-118** Push safely to canonical `origin/main`, no force.
- **V09-119** Final Claude response is exactly two lines: `AWAITING_AUDIT` and the direct GitHub blob URL for `CLAUDE_LOG_V09.md`.
- **V09-120** If any V09 fresh scene test exposes a real production defect, stop `BLOCKED`, do not patch production, and log the exact failing observation.
- **V09-121** Owner manual V07 PASS remains valid because production is immutable; no repeat owner playtest is requested on a clean V09.
- **V09-122** If V09 independently audits clean with all frozen V08 gaps closed, ChatGPT performs `M21 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`, updates root `TASKS.md`, closes eligible M21/SB-UI rows, recomputes progress and advances the project frontier.
