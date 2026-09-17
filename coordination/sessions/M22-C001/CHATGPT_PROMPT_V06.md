# M22-C001 V06 — Final Real-Demo Validation-Only Closure Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: close the single remaining V05 evidence finding using the actual M22 demo/Button transaction without changing accepted production behavior.

Authoritative inputs:

- `TASKS.md` — read-only for Claude
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V05.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V06.md`
- `coordination/sessions/M22-C001/CLAUDE_LOG_V05.md`
- accepted production baseline `8ded3580a8eacee1c64364e530142e23d6f115db`

V06 is validation-only. Production `scripts/` and `scenes/` are accepted and must remain byte-identical to `8ded3580...`. If the real demo/Button observation contradicts the accepted behavior, stop `BLOCKED` and report exact evidence. Do not patch production under this prompt.

The only frozen finding is:

`F-M22-V05-EVIDENCE-001` — V05 rebuilt a parallel production-class chain instead of observing ReservationState/dispatcher cleanup on the actual laid-out `m22_slot_demo.tscn` real C08 Button transaction required by the prompt/criteria.

## 1. Safe start

1. Confirm repo exactly `Sekiph82/Scrubbots` on `main`.
2. Safely synchronize with current `origin/main`, preserving owner/local work.
3. Record exact starting main SHA.
4. Read the audit/criteria above and the accepted demo/CompleteClearingLoop/ReservationState/dispatcher sources.
5. Do not modify root `TASKS.md`.
6. Do not modify production `scripts/`, `scenes/`, docs, assets, historical M21 evidence or M23 work.
7. Zero Magnific/image-generation credits.

## 2. Add one narrow V06 validation-only test

Prefer one new file:

`tests/m22_v06_real_demo_state_evidence.gd`

Do **not** rebuild a second gameplay chain.

Required procedure:

1. Create a real `SubViewport` and instantiate `res://scenes/demo/m22_slot_demo.tscn` inside it.
2. Await enough layout/process frames.
3. Confirm exactly five actual SlotCell/Button instances.
4. Use the exact ReservationState already bound inside that demo instance. The accepted demo stores the real `CompleteClearingLoop` at `inst._loop`; the loop stores the exact bound ReservationState at `_reservations`. Validation may directly inspect this existing object. Do not add a production accessor.
5. Use the exact dispatcher already owned by the same demo instance at `inst._dispatcher`.
6. Capture pre-dispatch reservation count, dispatcher active count and AgentLayer ScrubbotAgent count.
7. Activate C08 through the **real laid-out Button signal path**: press/emit the actual `panel.get_cell(2)` Button so `_on_slot_activated()` and `request_slot()` produce `inst._last_result`.
8. Require that real result succeeds and naturally selects target `380 / (0,19)`.
9. Capture its actual `owner_id`, target and exact real agent.
10. While the agent is in flight, directly inspect the exact demo ReservationState and dispatcher:
    - `get_owner(380) == owner_id`
    - `get_target_for_owner(owner_id) == 380`
    - dispatcher `has_owner(owner_id) == true`
    - dispatcher `get_target_for_owner(owner_id) == 380`
    - dispatcher `get_agent_for_owner(owner_id) == exact agent`
11. Drive that exact Button-created agent to authenticated completion using the same accepted agent completion path used in prior tests. Do not bypass the dispatcher/loop arrival authority.
12. Await deferred cleanup frames.
13. Directly prove on the same demo objects:
    - board target 380 CLEARED;
    - ReservationState count back to pre-dispatch baseline;
    - `get_owner(380) == -1`;
    - `get_target_for_owner(owner_id) == -1`;
    - dispatcher active count back to baseline;
    - dispatcher `has_owner(owner_id) == false`;
    - dispatcher `get_target_for_owner(owner_id) == -1`;
    - dispatcher `get_agent_for_owner(owner_id) == null`;
    - zero ScrubbotAgent remain in the real demo AgentLayer.
14. Print exact pre/in-flight/post values and the real Button result identity.

No parallel `ReservationState.new()`, `ScrubbotDispatcher.new()`, `CompleteClearingLoop.new()` or manually rebuilt authority chain counts for this finding.

## 3. Regression validation

Run and log literal command/result/exit/check count where applicable for:

1. `godot --version`
2. `godot --headless --path . -s res://tests/run_tests.gd`
3. new V06 real-demo evidence script
4. `tests/m22_v05_final_state_evidence.gd`
5. `tests/m22_v04_final_evidence.gd`
6. `tests/m22_v03_connector_evidence.gd`
7. `tests/m22_railroad_responsive_smoke.gd`
8. `tests/m22_responsive_smoke.gd`
9. `tests/m21_real_art_smoke.gd`
10. `tests/m21_v10_final_reservation_evidence.gd`
11. required M20 lifecycle/clearing smokes
12. `git diff --check`
13. exact Git inspection proving production `scripts/` and `scenes/` byte-identical to `8ded3580...`, root `TASKS.md` absent from V06 diff and historical M21 evidence untouched.

## 4. Commit / handoff

1. Review diff. Only authorized validation/evidence files may change.
2. Commit/push the V06 validation file first.
3. Capture exact validation commit SHA.
4. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V06.md` after that SHA exists.
5. Log:
   - exact starting SHA;
   - exact validation SHA;
   - changed files;
   - production byte-identity proof;
   - exact real demo/Button activation path;
   - pre/in-flight/post ReservationState values;
   - pre/in-flight/post dispatcher values;
   - target/owner/agent identity;
   - target clear and zero-agent cleanup;
   - literal validation commands/results/exits;
   - `Magnific/image-generation credits spent = 0`;
   - root `TASKS.md` unchanged.
6. Commit/push the log separately.
7. Verify validation commit and log visible on GitHub `main`.
8. Return only:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V06.md`

Do not claim PASS. ChatGPT owns engineering closure and the owner F6 gate.
