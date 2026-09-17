# M22-C001 V04 — ChatGPT Independent Strict Audit

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited validation commit: `325232900ae8676c65617250f7f045f00292863d`
Validation parent: `5e9dc848536e74f7e40735df2065f425a688cffe`
Evidence/log commit: `7a39f285fc1af60fb4042b0867127883bf78f8c9`
Accepted production baseline: `8ded3580a8eacee1c64364e530142e23d6f115db`
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit criteria: `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

## Verdict

**CHANGES_REQUIRED / PRODUCTION_BYTE_IDENTITY_ACCEPTED / V04_MAJORITY_EVIDENCE_ACCEPTED / V05_VALIDATION_ONLY_FINAL_CLOSURE_REQUIRED**

V04 correctly remained validation-only. The implementation commit adds only `tests/m22_v04_final_evidence.gd`; the separate evidence commit adds only `CLAUDE_LOG_V04.md`. No production `scripts/` or `scenes/` file, root `TASKS.md`, or historical M21 evidence file changed. The accepted V03 production baseline therefore remains intact.

V04 closes the prior global-anchor persistence gap, literal-command logging gap, exact C08 route-array gap, and most of the all-blocked/route-matrix evidence. However three narrow direct-observation gaps remain against the frozen V04 criteria. They are evidence-only. No reviewed evidence justifies reopening production code.

## Accepted V04 evidence

The following are accepted:

1. Five post-layout global SlotCell anchors and mapped board-local starts are persisted for the 1080×2160 viewport.
2. Real C08 post-layout activation naturally selects target `380 / (0,19)` and logs the exact route `[(9.222222,24.0),(9.222222,22.5),(0.5,22.5),(0.5,19.5)]`.
3. A second viewport/re-layout proves dynamic anchor recomputation.
4. Authenticated C08 arrival directly proves target 380 clears, dispatcher active count returns to baseline, and no agent remains after deferred cleanup.
5. The all-aligned-blocked fixture is isolated to exactly one matching color-0 candidate and proves `NO_REACHABLE_TARGET`, no agent, reservation count 0, dispatcher active count 0, BoardState equality, and target remains ACTIVE.
6. Exact runtime route arrays are persisted for far-left/bottom, far-right/top, two-side fallback, shortest, tie-break, rectangular 40×24 and 59×59 cases.
7. Literal commands/results/exits are recorded for the root suite and required smokes; root suite reports `4798` checks / `0` failures.
8. Production source/scenes remain byte-identical to accepted V03 implementation `8ded3580...`.
9. Magnific/image-generation credits spent = 0.

## Frozen residual findings

### F-M22-V04-EVIDENCE-001 — C08 arrival does not directly prove ReservationState cleanup

Criteria `M22-V04-025` requires direct observation of reservation **and** assignment cleanup after authenticated arrival.

The V04 C08 test records `pre_active`, clears target 380, asserts dispatcher active count returns to baseline, and asserts zero remaining agents. It does **not** directly inspect the ReservationState after arrival using the actual returned `owner_id` / `target_index` pair.

Required closure:

- capture C08 `owner_id` and target 380 before arrival;
- prove the reservation exists in both directions while the assignment is in flight;
- after authenticated arrival, prove `get_owner(380) == -1`, `get_target_for_owner(owner_id) == -1`, reservation count returned to its pre-dispatch value, dispatcher `has_owner(owner_id) == false`, dispatcher `get_target_for_owner(owner_id) == -1`, and no agent remains.

### F-M22-V04-EVIDENCE-002 — all-blocked reverse ownership / dispatcher-map absence is not directly observed

Criteria `M22-V04-033` requires both reservation directions to be absent; `M22-V04-034` requires dispatcher count/map to remain empty.

V04 proves reservation count 0 and target→owner absence with `get_owner(tgt) == -1`, but does not directly query `ReservationState.get_target_for_owner(pending_owner)`. It proves dispatcher active count 0, but does not directly query `has_owner(pending_owner)`, `get_target_for_owner(pending_owner)` or `get_agent_for_owner(pending_owner)`.

Required closure:

- capture `pending_owner = dispatcher.peek_next_owner_id()` before activation;
- before and after activation prove reservation target→owner and owner→target are absent;
- after activation prove dispatcher has no entry for that pending owner and no agent mapping;
- prove the owner-id counter did not advance on `NO_REACHABLE_TARGET`, if that is the accepted dispatcher contract.

### F-M22-V04-EVIDENCE-003 — shortest/tie-break choice context is asserted by fixture description, not directly measured

Criteria `M22-V04-043` and `M22-V04-044` require direct candidate context for shortest-path and equal-distance tie-break evidence.

The V04 test logs the selected route, but the strings `both BOTTOM+LEFT legal` and `competing=LEFT,RIGHT` are fixture descriptions. The test does not directly calculate/observe the legal aligned exit candidates and their candidate total lengths before checking the selected route. Therefore it does not independently prove that BOTTOM was chosen because it was shorter, or that LEFT and RIGHT were both legal and exactly equal before the tie-break.

Required closure:

- validation-only helper computes each aligned-side candidate under the same geometry/access truth used by production;
- shortest fixture: directly prove at least two legal candidates, log their sides and exact total lengths, and prove selected side has the minimum length;
- tie-break fixture: directly prove LEFT and RIGHT are both legal, log exact total lengths, prove equality within production tolerance, prove earlier-priority legal sides do not outrank them, and prove production selects LEFT;
- do not duplicate or modify production decision logic; the helper is evidence-only and must derive candidates from `ScrubRailGeometry` + authoritative access truth.

## Additional audit note

`M22-V04-081` asks the handoff log to record its own evidence/log commit SHA. A file cannot stably contain the SHA of the commit that first creates that exact file because the content participates in the commit hash. ChatGPT independently verifies the evidence commit as `7a39f285fc1af60fb4042b0867127883bf78f8c9`; this self-referential field is therefore treated as auditor-resolved, not a V05 blocker.

The V04 direct-route all-blocked case logs `NO_ROUTE` and retained target. V05 should also snapshot/fingerprint BoardState immediately around that direct routing call so `M22-V04-045` is undeniable, although the separate full-lifecycle fixture already shows the production chain is mutation-free.

## Closure rule

V05 is validation-only. Production `scripts/` and `scenes/` must remain byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.

V05 passes only if all three frozen findings above close together. If direct observation exposes a production mismatch, stop `BLOCKED` and do not patch production under V05.

On V05 PASS, ChatGPT may issue `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`, close eligible `SB-M22-009` and `SB-M22-026..034`, and open the separate owner F6 visual/game-feel gate `SB-M22-035`.
