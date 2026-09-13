# M21-C001 V10 — Final Reservation/Scene Evidence Strict Audit Criteria

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Scope: final validation-only reconciliation of the frozen V09 evidence residuals
Owner gate: **PASS already recorded** in `CHATGPT_OWNER_GATE_V07_PASS.md`
Production basis: accepted V07 production candidate, preserved byte-for-byte through V08/V09

V10 is **production immutable**. If fresh direct inspection exposes a genuine production mismatch, Claude must stop `BLOCKED` and must not patch production.

## A. Governance / immutable scope

- **V10-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **V10-002** Safely sync with current `origin/main` before work.
- **V10-003** Preserve all owner/local tracked and untracked work.
- **V10-004** Read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, V07 owner PASS, V08/V09 audits/logs/criteria and this V10 criteria file.
- **V10-005** Do not modify root `TASKS.md`.
- **V10-006** Do not modify any accepted `scripts/**` file.
- **V10-007** Do not modify any accepted `scenes/**` file.
- **V10-008** Do not modify `project.godot`.
- **V10-009** Do not modify owner Hazard Bot PNG or M21 generated artifacts.
- **V10-010** Do not weaken/delete/edit existing V07/V08/V09 tests.
- **V10-011** Authorized V10 implementation additions are only `tests/m21_v10_final_reservation_evidence.gd` and `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`.
- **V10-012** No force push/destructive reset/clean/restore/stash loss.
- **V10-013** If direct V10 evidence reveals a production defect, stop `BLOCKED` without source correction.

## B. Locked production identity

Recheck and log exact identities:

- **V10-014** `production_routing_system.gd` = `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`.
- **V10-015** `m21_real_art_vertical_slice.gd` = `153c042a17dc0ef9e83699a0beb2932217057ff4`.
- **V10-016** owner Hazard Bot PNG = `b565743ba52699899007882b750b7c8e7cdd00f9`.
- **V10-017** `complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- **V10-018** `scrubbot_dispatcher.gd` = `eee10149e4f116af6706beec832042352bf3a6dd`.
- **V10-019** `target_selector.gd` = `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.
- **V10-020** `production_access_query.gd` = `7ba9d13556abb0e3a0a6d281449438330a25386d`.
- **V10-021** `board_presentation.gd` = `2093df48d367903d332a910dfb3369154831a9ed`.
- **V10-022** `slot_view.gd` = `480dffc0ee135150bd3dd2258f002264273ead10`.
- **V10-023** `scrubbot_agent.gd` = `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370`.

## C. Exact ReservationState object identity

Use the real fresh owner scene and existing fields only. No new source hook is authorized.

- **V10-024** Obtain the real bound `CompleteClearingLoop` instance used by the owner scene.
- **V10-025** Obtain the exact `ReservationState` object already bound inside that real loop using test-only read-only introspection of existing fields.
- **V10-026** Prove this object is non-null/live and exposes existing `get_reservation_count`, `get_owner`, and `get_target_for_owner` queries.
- **V10-027** Prove the real dispatcher is coherent with the same board + exact ReservationState object using its existing `is_bound_to(board, reservation_state)` query.
- **V10-028** Do not instantiate a substitute/parallel ReservationState and call that direct evidence.

## D. No-work real Button exact reservation zero side effect

On a fresh real owner scene:

- **V10-029** Directly assert exactly five SlotViews before stimulus.
- **V10-030** Identify the real no-work visible slot used by the Hazard Bot fixture.
- **V10-031** Before click, exact ReservationState reservation count is zero.
- **V10-032** Before click, no owner/target mapping exists for any assignment introduced by the test.
- **V10-033** Stimulus is the real visible SlotView Button path.
- **V10-034** Result is legitimate no-work/failure.
- **V10-035** After click, exact ReservationState reservation count remains zero.
- **V10-036** After click, no target→owner or owner→target mapping appears.
- **V10-037** Dispatcher active and AgentLayer counts remain zero.
- **V10-038** Board/candidate state remains unchanged, reusing or freshly reproducing the accepted V09 snapshot law.

## E. First C08 real Button exact ReservationState pair

On a second fresh real owner scene:

- **V10-039** Press the actual visible C08 Button once.
- **V10-040** Assignment naturally succeeds at target `380/(0,19)`.
- **V10-041** Capture the exact owner ID before arrival.
- **V10-042** Exact ReservationState `get_owner(380) == owner_id` while in flight.
- **V10-043** Exact ReservationState `get_target_for_owner(owner_id) == 380` while in flight.
- **V10-044** Reservation count is exactly one while this is the sole in-flight assignment.
- **V10-045** Complete through the real agent/authenticated arrival path.
- **V10-046** After clear, ReservationState `get_owner(380) == -1`.
- **V10-047** After clear, ReservationState `get_target_for_owner(owner_id) == -1`.
- **V10-048** Reservation count returns exactly zero.
- **V10-049** Dispatcher/AgentLayer clean up to zero and target 380 is CLEARED.

## F. Rapid x3 real Button exact ReservationState + AgentLayer lifecycle

On a third fresh real owner scene:

- **V10-050** Press the actual C08 Button three times before first completion.
- **V10-051** All three naturally succeed with exact targets `380,381,382`.
- **V10-052** Owner IDs are unique.
- **V10-053** ReservationState reservation count is exactly three in flight.
- **V10-054** Exact target→owner mappings exist for all 380/381/382.
- **V10-055** Exact owner→target mappings exist for all three owner IDs.
- **V10-056** AgentLayer contains exactly three live ScrubbotAgent children before first completion.
- **V10-057** Actual C08 SlotView is active while three are in flight.
- **V10-058** Complete only first assignment; ReservationState count becomes exactly two and only first pair is gone.
- **V10-059** AgentLayer count becomes exactly two and slot remains active.
- **V10-060** Complete only second; ReservationState count becomes exactly one and only second pair is additionally gone.
- **V10-061** AgentLayer count becomes exactly one and slot remains active.
- **V10-062** Complete final; ReservationState count becomes exactly zero and all three bidirectional pairs are absent.
- **V10-063** AgentLayer count becomes zero after deferred cleanup and slot returns idle.
- **V10-064** Accepted V09 exact board delta `{380,381,382}` and candidate delta remain green.

## G. Reset-in-flight exact ReservationState + identities

On a fourth fresh real owner scene:

- **V10-065** Press actual C08 Button twice without completing either.
- **V10-066** Both succeed with exact unique targets `380` and `381` in that order.
- **V10-067** Capture both owner IDs and both exact agent instance identities before reset.
- **V10-068** AgentLayer contains exactly those two ScrubbotAgent instances pre-reset.
- **V10-069** ReservationState count is exactly two pre-reset.
- **V10-070** Exact target→owner pairs exist for 380 and 381.
- **V10-071** Exact owner→target pairs exist for both owners.
- **V10-072** Invoke canonical reset through the real scene/bound loop.
- **V10-073** ReservationState count becomes exactly zero.
- **V10-074** Old `380/381 -> owner` mappings are absent.
- **V10-075** Old `owner -> 380/381` mappings are absent.
- **V10-076** Dispatcher active count becomes zero.
- **V10-077** Full board state remains identical to pre-reset and both targets remain ACTIVE.
- **V10-078** C08 candidate set remains coherent/identical to pre-reset.
- **V10-079** After deferred cleanup neither captured agent identity remains in AgentLayer and AgentLayer ScrubbotAgent count is zero.
- **V10-080** A new real C08 Button click naturally selects `380/(0,19)` again.

## H. Regression / runtime evidence

- **V10-081** Record exact `godot --version`; do not alter engine installation.
- **V10-082** Run V10 test and log PASS/exit 0.
- **V10-083** Run unchanged V09 test and log PASS.
- **V10-084** Run unchanged V08 test and log PASS.
- **V10-085** Run unchanged V07/V06/V05 M21 smokes and log PASS.
- **V10-086** Run M21 400-clear real-art smoke and log PASS.
- **V10-087** Run full root suite; log exact check count, zero failures and exit 0.
- **V10-088** Run required M20 queue-free/lifecycle regressions and log PASS.
- **V10-089** Owner scene headless boot has zero SCRIPT/Parse errors.
- **V10-090** M21 level builder rerun remains LEVEL/PREVIEW/METADATA UNCHANGED.
- **V10-091** Reference composite rerun remains UNCHANGED.
- **V10-092** `git diff --check` clean for authorized V10 work.

## I. Handoff / closure law

- **V10-093** Create `CLAUDE_LOG_V10.md` with exact commands/results and direct ReservationState tuples/counts.
- **V10-094** Root `TASKS.md` remains byte-identical through Claude work.
- **V10-095** Claude closes no M21/M22/SB-UI checkbox.
- **V10-096** Claude authors no audit verdict/file.
- **V10-097** V10 commit changes only the new V10 test and V10 log.
- **V10-098** Push safely to canonical `origin/main`, no force.
- **V10-099** If fresh direct ReservationState evidence contradicts accepted production coherence, stop `BLOCKED` and do not patch production.
- **V10-100** Owner manual V07 PASS remains valid on a clean V10 because production is immutable.
- **V10-101** If V10 independently audits clean, ChatGPT performs `M21 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`, updates root `TASKS.md`, closes eligible M21/SB-UI rows, recomputes progress and advances the project frontier to M22. No V11 is created reflexively.
