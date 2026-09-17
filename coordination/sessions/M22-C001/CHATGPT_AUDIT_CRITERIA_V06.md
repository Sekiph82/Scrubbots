# M22-C001 V06 — Final Real-Demo Validation-Only Closure Criteria

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Purpose: close the single remaining V05 evidence finding using the actual laid-out M22 demo and actual C08 Button, without changing accepted production behavior.

## A. Governance / immutability

- **M22-V06-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V06-002** Safely synchronize with current `origin/main`; no destructive reset/clean/force-push.
- **M22-V06-003** Read root `TASKS.md` but do not modify it.
- **M22-V06-004** Read `CHATGPT_AUDIT_V05.md`, this criteria file, `CHATGPT_PROMPT_V06.md`, V05 log/test, accepted V03 production baseline and owner Railroad decision.
- **M22-V06-005** Production `scripts/` and `scenes/` remain byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.
- **M22-V06-006** Historical M21 evidence remains untouched.
- **M22-V06-007** Zero Magnific/image-generation credits; no M23 work.
- **M22-V06-008** If direct real-demo validation exposes a production mismatch, stop `BLOCKED`; do not patch production under V06.

## B. Actual real laid-out demo / C08 activation

- **M22-V06-010** Instantiate the real `res://scenes/demo/m22_slot_demo.tscn` in a real `SubViewport`.
- **M22-V06-011** Await enough process/layout frames before measurement and activation.
- **M22-V06-012** Observe exactly five actual SlotCell/Button instances.
- **M22-V06-013** Use the exact ReservationState bound inside that demo instance, obtained through the already-bound demo/loop object; do not build a second ReservationState/dispatcher/loop chain.
- **M22-V06-014** Use the exact dispatcher owned by that same demo instance.
- **M22-V06-015** Capture pre-dispatch reservation count, dispatcher active count and zero/expected agent count from those exact demo objects.
- **M22-V06-016** Activate by pressing/emitting the real laid-out C08 Button path, not by calling a separately rebuilt `CompleteClearingLoop.activate_slot()`.
- **M22-V06-017** Capture the actual `inst._last_result` produced by the Button and prove target `380 / (0,19)` arises naturally.

## C. In-flight exact state on the same demo transaction

- **M22-V06-020** Capture exact `owner_id`, target and real agent from the real Button result.
- **M22-V06-021** While the actual demo agent is in flight, prove ReservationState `get_owner(380) == owner_id`.
- **M22-V06-022** While in flight, prove ReservationState `get_target_for_owner(owner_id) == 380`.
- **M22-V06-023** Prove demo dispatcher `has_owner(owner_id) == true`.
- **M22-V06-024** Prove demo dispatcher `get_target_for_owner(owner_id) == 380`.
- **M22-V06-025** Prove demo dispatcher `get_agent_for_owner(owner_id)` is the exact real Button-created agent.
- **M22-V06-026** Persist exact in-flight values in runtime output and `CLAUDE_LOG_V06.md`.

## D. Authenticated arrival / cleanup on the same demo transaction

- **M22-V06-030** Drive the exact Button-created real agent to completion through the accepted authenticated arrival path.
- **M22-V06-031** After deferred cleanup, target 380 is CLEARED.
- **M22-V06-032** Reservation count returns exactly to the captured pre-dispatch baseline.
- **M22-V06-033** ReservationState `get_owner(380) == -1`.
- **M22-V06-034** ReservationState `get_target_for_owner(owner_id) == -1`.
- **M22-V06-035** Dispatcher active count returns to the captured baseline.
- **M22-V06-036** Dispatcher `has_owner(owner_id) == false`.
- **M22-V06-037** Dispatcher `get_target_for_owner(owner_id) == -1`.
- **M22-V06-038** Dispatcher `get_agent_for_owner(owner_id) == null`.
- **M22-V06-039** The real demo AgentLayer contains zero ScrubbotAgent after deferred cleanup.
- **M22-V06-040** Persist exact post-arrival values in runtime output and `CLAUDE_LOG_V06.md`.

## E. Validation / non-regression

- **M22-V06-050** Full `tests/run_tests.gd` remains `4798` checks / zero failures / exit 0, or record exact changed total if only authorized validation registration legitimately changes it.
- **M22-V06-051** New V06 real-demo evidence script PASS exit 0.
- **M22-V06-052** V05 final-state evidence PASS exit 0.
- **M22-V06-053** V04 final evidence PASS exit 0.
- **M22-V06-054** V03 connector evidence PASS exit 0.
- **M22-V06-055** Railroad responsive and V01 responsive/component smokes remain PASS.
- **M22-V06-056** M21 real-art clear / V10 reservation and required M20 lifecycle smokes remain PASS.
- **M22-V06-057** `git diff --check` clean.
- **M22-V06-058** Git inspection proves production `scripts/` and `scenes/` byte-identical to `8ded3580...`, historical M21 evidence unchanged and root `TASKS.md` absent from V06 changes.
- **M22-V06-059** Log literal commands/results/exits; exact check count where reported.

## F. Handoff

Create `coordination/sessions/M22-C001/CLAUDE_LOG_V06.md` after the validation commit exists.

- **M22-V06-060** Record exact starting main SHA and validation commit SHA.
- **M22-V06-061** Only authorized validation/evidence files changed.
- **M22-V06-062** Persist exact real-demo pre/in-flight/post ReservationState, dispatcher and AgentLayer values.
- **M22-V06-063** Record the exact real Button path used and actual target/owner/agent identity.
- **M22-V06-064** State `Magnific/image-generation credits spent = 0`.
- **M22-V06-065** Verify validation commit and log visible on GitHub `main` before handoff.

## G. Closure rule

V06 passes only if the single frozen finding closes:

- `F-M22-V05-EVIDENCE-001`

No parallel rebuilt gameplay chain counts as closure. The proof must come from the actual laid-out demo instance and actual C08 Button transaction.

On V06 PASS, ChatGPT should issue `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`, close eligible `SB-M22-009` and `SB-M22-026..034`, and open owner F6 visual/game-feel gate `SB-M22-035`.
