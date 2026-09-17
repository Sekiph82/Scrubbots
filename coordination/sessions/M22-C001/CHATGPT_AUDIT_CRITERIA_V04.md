# M22-C001 V04 — ChatGPT Final Validation-Only Audit Criteria

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Purpose: close the frozen V03 direct-evidence residuals without changing accepted production behavior.

## A. Governance / immutability

- **M22-V04-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V04-002** Safely synchronize with current `origin/main`; preserve owner/local work; no destructive reset/clean/force-push.
- **M22-V04-003** Read root `TASKS.md` but do not modify it.
- **M22-V04-004** Read `CHATGPT_AUDIT_V03.md`, this criteria file, `CHATGPT_PROMPT_V04.md`, the V03 log, V03 implementation commit, accepted V01/V02 sources and the owner Railroad decision.
- **M22-V04-005** Production source/scenes remain byte-identical to implementation commit `8ded3580a8eacee1c64364e530142e23d6f115db` unless a direct V04 observation reveals a genuine production defect, in which case stop `BLOCKED` rather than patching under this authorization.
- **M22-V04-006** Historical M21 tests/audits/logs remain untouched.
- **M22-V04-007** No M23 work, no unrelated refactor, no generation/runtime dependency change.
- **M22-V04-008** `Magnific/image-generation credits spent = 0`.

## B. Five exact global SlotCell anchors + mapped starts

Use the real production M22 demo in a real `SubViewport` after completed layout.

- **M22-V04-010** Await enough process/layout frames before measurement.
- **M22-V04-011** Observe exactly five actual production SlotCell/Button instances.
- **M22-V04-012** For slot IDs `0..4`, capture the actual laid-out top-center global anchor directly from each SlotCell.
- **M22-V04-013** For the same five slots, independently map each global anchor through `BoardPresentation.global_to_board_local()`.
- **M22-V04-014** Persist all five pairs `(slot id, global anchor, mapped board-local start)` in runtime output and `CLAUDE_LOG_V04.md`.
- **M22-V04-015** Five mapped starts are distinct and one-to-one with slot IDs.
- **M22-V04-016** A real C08 Button route point 0 equals the independently mapped slot-2 anchor.
- **M22-V04-017** C08 route point 1 equals canonical `bottom_entry(mapped_x)` and connector travel is non-zero.
- **M22-V04-018** A second viewport/re-layout case re-measures the actual global and mapped anchors and proves route point 0 follows the new mapping, not stale prior geometry.

## C. Exact C08 transaction

- **M22-V04-020** Fresh real C08 Button naturally selects target `380 / (0,19)`.
- **M22-V04-021** Log the exact post-layout slot-2 global anchor, mapped start and full route point array.
- **M22-V04-022** Route enters BOTTOM rail before lateral travel.
- **M22-V04-023** Intermediate rail travel remains on canonical Railroad centrelines/corners.
- **M22-V04-024** Final exit is target-row/column aligned and final segment is orthogonal to `(0.5,19.5)`.
- **M22-V04-025** Complete/authenticated arrival clears exactly target 380 and reservation/assignment cleanup is observed directly.

## D. All-aligned-blocked full-lifecycle no-side-effect evidence

Construct a validation-only fixture through the real production selection/dispatch/clearing authority where a requested matching target exists but is not targetable because all legal aligned Railroad approaches are blocked.

- **M22-V04-030** Record the exact matching target identity and board snapshot before activation.
- **M22-V04-031** Prove the matching target is ACTIVE, color-matching and unreserved before activation but not targetable under current Railroad access truth.
- **M22-V04-032** Real activation fails cleanly / spawns no ScrubbotAgent.
- **M22-V04-033** ReservationState count remains unchanged and exact target->owner / owner->target mappings are absent.
- **M22-V04-034** Dispatcher active-assignment count/map remains unchanged/empty.
- **M22-V04-035** BoardState snapshot is identical before/after; no target is cleared.
- **M22-V04-036** No alternate target is silently selected merely to obtain success. If the fixture contains more than one same-color candidate, prove deterministic selector behavior explicitly; preferably isolate the blocked matching target for unambiguous evidence.
- **M22-V04-037** AgentLayer/agent-parent contains no new ScrubbotAgent after activation and deferred frame cleanup.

## E. Exact route arrays for final Railroad evidence

Persist runtime-observed route point arrays, not only source assertions or prose summaries.

- **M22-V04-040** True far-right/top production-envelope route: log exact board dimensions, start, target, chosen aligned exit and full point array.
- **M22-V04-041** Prove that route's rail-domain classification: connector, canonical rail segments/corners, final approach.
- **M22-V04-042** Two-side blocked-preferred-exit fallback route: log exact full point array and same target identity.
- **M22-V04-043** Shortest-legal-route fixture: log candidate context, selected exit side and exact full point array.
- **M22-V04-044** Equal-distance tie-break fixture on a 20..59 board: log the exact competing legal sides/context, chosen side and exact full point array; result must match `BOTTOM -> LEFT -> RIGHT -> TOP`.
- **M22-V04-045** All-aligned-blocked direct routing result: log `NO_ROUTE`, retained target identity and zero BoardState mutation.
- **M22-V04-046** Rectangular acceptance uses both dimensions within 20..59 and remains domain-clean.
- **M22-V04-047** 59x59 acceptance remains domain-clean.

## F. Production/source non-regression

- **M22-V04-050** Current `ProductionRoutingSystem` still contains no adjacent-ring seeding/search/helper and every outside start uses Railroad-compatible/fail-closed policy.
- **M22-V04-051** TargetSelector WHAT-policy remains unchanged.
- **M22-V04-052** ReservationState authority remains unchanged.
- **M22-V04-053** CompleteClearingLoop authenticated clearing authority remains unchanged.
- **M22-V04-054** `ColorSelectionPanel.bind_colors()` fail-closed behavior remains green.
- **M22-V04-055** Accepted V01 five-slot/touch/responsive behavior remains green.
- **M22-V04-056** Single-source rail geometry/view contract remains unchanged.

## G. Exact command/evidence logging

For every mandatory run below, `CLAUDE_LOG_V04.md` must contain the literal command exactly as executed, the result, exit code, and check count where the command reports one. Do not abbreviate commands to only `-s tests/...`.

- **M22-V04-060** exact `godot --version` command + exact output.
- **M22-V04-061** exact full root-suite command + total checks/failures/exit.
- **M22-V04-062** exact V04 final-evidence script command + result/exit.
- **M22-V04-063** exact V03 connector-evidence command + result/exit.
- **M22-V04-064** exact current Railroad responsive-smoke command + result/exit.
- **M22-V04-065** exact V01 responsive/component-smoke command + result/exit.
- **M22-V04-066** exact M21 full 400-cell clear command + result/exit.
- **M22-V04-067** exact M21 V10 reservation/direct-evidence command + result/exit.
- **M22-V04-068** exact required M20 lifecycle/clearing smoke commands + each result/exit.
- **M22-V04-069** strict TargetSelector/reservation/dispatcher/ScrubbotAgent regressions identified and PASS in the root suite or exact dedicated command(s).
- **M22-V04-070** exact headless M22 demo boot/validation command + zero SCRIPT/Parse errors + exit.
- **M22-V04-071** exact `git diff --check` command + clean result.
- **M22-V04-072** exact Git inspection proving production source/scenes are byte-identical to `8ded3580...` and root `TASKS.md` absent from V04 diff.

Historical M21 V08/V09 exact-ring-only failures may remain classified historical. Do not edit them.

## H. Handoff evidence

Create `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md` after the validation commit/evidence SHA strategy is known.

- **M22-V04-080** Record exact pre-work GitHub `main` SHA.
- **M22-V04-081** Record exact V04 validation commit SHA and separate evidence/log commit SHA if two-step.
- **M22-V04-082** Record exact changed files; only authorized validation/evidence files may change.
- **M22-V04-083** Record all five global-anchor + mapped-start pairs.
- **M22-V04-084** Record exact C08 post-layout anchor/mapped start/full route/arrival-cleanup evidence.
- **M22-V04-085** Record exact all-blocked lifecycle no-side-effect evidence.
- **M22-V04-086** Record exact route arrays required in section E.
- **M22-V04-087** Record every literal validation command/result/exit required in section G.
- **M22-V04-088** State `Magnific/image-generation credits spent = 0`.
- **M22-V04-089** Verify validation commit and `CLAUDE_LOG_V04.md` are visible on GitHub `main` before handoff.

## I. Closure rule

V04 passes only if all frozen V03 residuals close together:

- `F-M22-V03-EVIDENCE-001`
- `F-M22-V03-EVIDENCE-002`
- `F-M22-V03-EVIDENCE-003`
- `F-M22-V03-EVIDENCE-004`

V04 is validation-only. If direct observations expose a real production defect, return `BLOCKED` with exact evidence and do not patch production.

If V04 closes all residuals and production remains byte-identical, ChatGPT may perform `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`, close eligible M22 Railroad engineering rows, and open the separate owner F6 visual/game-feel acceptance gate (`SB-M22-035`).