# M22-C001 V05 — Final Validation-Only Engineering Closure Criteria

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Purpose: close the three frozen V04 evidence findings without changing accepted production behavior.

## A. Governance / immutability

- **M22-V05-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V05-002** Safely synchronize with current `origin/main`; no destructive reset/clean/force-push.
- **M22-V05-003** Read root `TASKS.md` but do not modify it.
- **M22-V05-004** Read `CHATGPT_AUDIT_V04.md`, this criteria file, `CHATGPT_PROMPT_V05.md`, V04 log/test, accepted V03 production commit, and owner Railroad decision.
- **M22-V05-005** Production `scripts/` and `scenes/` remain byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.
- **M22-V05-006** Historical M21 evidence remains untouched.
- **M22-V05-007** Zero Magnific/image-generation credits; no M23 work.
- **M22-V05-008** If direct validation exposes a real production defect, stop `BLOCKED`; do not patch production under V05.

## B. C08 authenticated-arrival reservation cleanup

Use the real post-layout M22 demo and real C08 Button.

- **M22-V05-010** Capture pre-dispatch reservation count and dispatcher active count.
- **M22-V05-011** After successful C08 dispatch and before arrival, capture exact `owner_id` and prove target 380 is reserved to that owner in both directions: `get_owner(380) == owner_id` and `get_target_for_owner(owner_id) == 380`.
- **M22-V05-012** Prove dispatcher owns the same assignment in flight: `has_owner(owner_id) == true`, `get_target_for_owner(owner_id) == 380`, and `get_agent_for_owner(owner_id)` is the same real agent.
- **M22-V05-013** Drive authenticated arrival through the accepted real chain and prove target 380 becomes CLEARED.
- **M22-V05-014** After arrival/deferred cleanup, prove ReservationState count returns to pre-dispatch baseline, `get_owner(380) == -1`, and `get_target_for_owner(owner_id) == -1`.
- **M22-V05-015** After arrival/deferred cleanup, prove dispatcher active count returns to baseline, `has_owner(owner_id) == false`, `get_target_for_owner(owner_id) == -1`, `get_agent_for_owner(owner_id) == null`, and zero ScrubbotAgent remain.
- **M22-V05-016** Persist exact pre/in-flight/post values in runtime output and `CLAUDE_LOG_V05.md`.

## C. All-aligned-blocked reverse-map / dispatcher-map absence

Reuse or extend the isolated one-candidate full-lifecycle fixture from V04.

- **M22-V05-020** Capture `pending_owner = dispatcher.peek_next_owner_id()` before activation.
- **M22-V05-021** Before activation prove target is unreserved in both directions: `get_owner(target) == -1` and `get_target_for_owner(pending_owner) == -1`.
- **M22-V05-022** Real loop activation returns `NO_REACHABLE_TARGET` / failure and spawns no agent.
- **M22-V05-023** After activation ReservationState count is unchanged; target→owner and pending-owner→target mappings are both absent.
- **M22-V05-024** After activation dispatcher active count is unchanged; `has_owner(pending_owner) == false`, `get_target_for_owner(pending_owner) == -1`, and `get_agent_for_owner(pending_owner) == null`.
- **M22-V05-025** Prove `dispatcher.peek_next_owner_id()` remains equal to the captured pending owner when no reachable target is selected, if current accepted dispatcher behavior does so. If not, record exact observed value and stop `BLOCKED` rather than rewriting production.
- **M22-V05-026** BoardState exact snapshot remains identical, target remains ACTIVE, and no alternate target is cleared.
- **M22-V05-027** Persist all exact pre/post mapping/count values in runtime output and log.

## D. Direct shortest-route evidence

Validation helper may derive candidate metrics, but must not duplicate or mutate production routing policy.

- **M22-V05-030** Use `ScrubRailGeometry` and authoritative `ProductionAccessQuery` to enumerate the same four aligned exit sides for the already-selected target.
- **M22-V05-031** For each side, directly determine whether final approach is legal under authoritative segment truth.
- **M22-V05-032** For each legal side, compute connector + canonical rail-path + final-approach total polyline distance from the same start/target used by production.
- **M22-V05-033** Shortest fixture has at least two legal candidates; persist each legal side and exact total length.
- **M22-V05-034** Production selected side equals the uniquely shortest legal candidate, within the production `_RAIL_LEN_EPS` semantics.
- **M22-V05-035** Persist production route full point array and selected side.

## E. Direct equal-distance tie-break evidence

- **M22-V05-040** Tie-break fixture dimensions remain within 20..59.
- **M22-V05-041** Directly prove the intended competing sides are both legal under authoritative segment truth.
- **M22-V05-042** Persist their exact computed total lengths and prove equality within `0.0001`.
- **M22-V05-043** Directly record legality/lengths of any higher-priority side(s) so they cannot silently outrank the intended tie.
- **M22-V05-044** Production route selects the first tied legal side according to `BOTTOM → LEFT → RIGHT → TOP`.
- **M22-V05-045** Persist the full production route point array and chosen side.

## F. Direct all-blocked routing mutation proof

- **M22-V05-050** Around the direct `ProductionRoutingSystem.compute_route()` all-blocked call, capture exact BoardState snapshot before and after.
- **M22-V05-051** Result is `NO_ROUTE`, retained target index, and snapshots are identical.
- **M22-V05-052** Persist a deterministic exact snapshot fingerprint before/after (cell count + full-state SHA-256, or the complete state vector) and prove equality.

## G. Non-regression / commands

- **M22-V05-060** Full `tests/run_tests.gd` passes with exact total/fail count and exit 0.
- **M22-V05-061** V05 evidence script passes exit 0.
- **M22-V05-062** V04 final evidence remains PASS exit 0.
- **M22-V05-063** V03 connector evidence remains PASS exit 0.
- **M22-V05-064** M22 Railroad responsive and V01 responsive/component smokes remain PASS.
- **M22-V05-065** M21 real-art 400-cell clear and M21 V10 reservation evidence remain PASS.
- **M22-V05-066** Required M20 lifecycle smokes remain PASS.
- **M22-V05-067** `git diff --check` clean.
- **M22-V05-068** Git diff proves production `scripts/` and `scenes/` byte-identical to `8ded3580...` and root `TASKS.md` absent from V05 changes.
- **M22-V05-069** Log literal commands/results/exits; check count where reported.

## H. Handoff

Create `coordination/sessions/M22-C001/CLAUDE_LOG_V05.md` after the validation commit exists.

- **M22-V05-080** Record exact starting main SHA and validation commit SHA.
- **M22-V05-081** Only validation/evidence files changed.
- **M22-V05-082** Persist exact C08 reservation/dispatcher pre/in-flight/post evidence.
- **M22-V05-083** Persist exact all-blocked reverse-map/dispatcher-map evidence.
- **M22-V05-084** Persist shortest candidate legality + exact lengths + production selection.
- **M22-V05-085** Persist tie candidate legality + exact equal lengths + production selection.
- **M22-V05-086** Persist all-blocked direct-route snapshot fingerprint and `NO_ROUTE` result.
- **M22-V05-087** State `Magnific/image-generation credits spent = 0`.
- **M22-V05-088** Verify validation commit and log visible on GitHub main before handoff.

## I. Closure rule

V05 passes only if these frozen findings close together:

- `F-M22-V04-EVIDENCE-001`
- `F-M22-V04-EVIDENCE-002`
- `F-M22-V04-EVIDENCE-003`

No new production implementation is authorized.

On V05 PASS, ChatGPT should issue `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`, close eligible `SB-M22-009` and `SB-M22-026..034`, and open owner F6 visual/game-feel acceptance gate `SB-M22-035`.
