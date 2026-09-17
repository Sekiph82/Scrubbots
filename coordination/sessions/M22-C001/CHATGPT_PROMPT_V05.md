# M22-C001 V05 — Final Validation-Only Engineering Closure Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: close the three frozen V04 direct-state evidence findings without changing accepted production behavior.

Authoritative inputs:

- `TASKS.md` — read-only for Claude
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V04.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
- `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md`
- accepted production implementation commit `8ded3580a8eacee1c64364e530142e23d6f115db`

V05 is validation-only. Production `scripts/` and `scenes/` are accepted and must stay byte-identical to `8ded3580...`. Do not patch production merely to satisfy evidence. If direct observation contradicts the accepted behavior, stop `BLOCKED` and report exact evidence.

Frozen findings to close together:

1. `F-M22-V04-EVIDENCE-001` — C08 authenticated arrival did not directly inspect ReservationState cleanup.
2. `F-M22-V04-EVIDENCE-002` — all-blocked validation did not directly inspect reverse reservation mapping / dispatcher owner map.
3. `F-M22-V04-EVIDENCE-003` — shortest/tie-break route-choice context was described rather than independently measured from legal candidates and exact distances.

## 1. Safe start

1. Confirm working repo exactly `Sekiph82/Scrubbots` on `main`.
2. Safely fast-forward/synchronize with current `origin/main` preserving owner/local work.
3. Record exact starting main SHA.
4. Read every authoritative file above and the production ReservationState/Dispatcher/CompleteClearingLoop APIs.
5. Do not modify root `TASKS.md`.
6. Do not modify production `scripts/`, `scenes/`, historical M21 evidence, docs, assets, generated content or M23 work.
7. Zero Magnific/image-generation credits.

## 2. Add one V05 validation-only evidence script

Prefer a single new file such as:

`tests/m22_v05_final_state_evidence.gd`

You may reuse V04 test-only helpers or write narrow validation helpers. Do not copy production routing decision logic wholesale. Candidate measurement helpers must consume `ScrubRailGeometry` and authoritative `ProductionAccessQuery` and only observe/measure what production would consider.

### A. Real C08 authenticated-arrival cleanup

Use the real laid-out M22 demo in a real SubViewport.

On fresh C08 dispatch:

- record reservation count and dispatcher active count before dispatch;
- press real C08 Button;
- capture returned `owner_id`, target 380 and exact agent;
- while in flight directly prove:
  - ReservationState `get_owner(380) == owner_id`;
  - ReservationState `get_target_for_owner(owner_id) == 380`;
  - dispatcher `has_owner(owner_id)`;
  - dispatcher `get_target_for_owner(owner_id) == 380`;
  - dispatcher `get_agent_for_owner(owner_id) == exact agent`;
- drive the accepted authenticated arrival path;
- after deferred cleanup directly prove:
  - BoardState target 380 is CLEARED;
  - ReservationState count returned to baseline;
  - `get_owner(380) == -1`;
  - `get_target_for_owner(owner_id) == -1`;
  - dispatcher active count returned to baseline;
  - `has_owner(owner_id) == false`;
  - dispatcher `get_target_for_owner(owner_id) == -1`;
  - dispatcher `get_agent_for_owner(owner_id) == null`;
  - zero ScrubbotAgent remain.

Print and log exact pre/in-flight/post values.

### B. All-aligned-blocked no-map evidence

Reuse the isolated one-candidate blocked fixture from V04.

Before activation capture:

`pending_owner = dispatcher.peek_next_owner_id()`.

Directly prove before and after:

- target→owner absent;
- pending-owner→target absent;
- dispatcher does not have pending owner;
- dispatcher pending-owner target is -1;
- dispatcher pending-owner agent is null;
- reservation count and dispatcher active count unchanged;
- owner-id counter does not advance on NO_REACHABLE_TARGET if that is the current accepted behavior;
- board snapshot identical, target ACTIVE, no alternate clear, no agent spawned.

If any observation contradicts current accepted behavior, stop `BLOCKED`. Do not patch production.

### C. Shortest-route candidate measurement

For the same shortest fixture used in V04:

- enumerate TOP/BOTTOM/LEFT/RIGHT aligned exits using `ScrubRailGeometry`;
- use authoritative `ProductionAccessQuery.is_segment_traversable()` to determine legal final approaches;
- for every legal side derive the canonical rail path using `ScrubRailGeometry.rail_path()` from the actual bottom entry;
- compute exact total route length = connector + canonical rail path + final orthogonal approach;
- print every side, legality and total length;
- prove at least two legal candidates;
- run production `ProductionRoutingSystem.compute_route()` and determine selected exit;
- prove selected side is uniquely shortest under `_RAIL_LEN_EPS = 0.0001` semantics;
- print full production route array.

Do not retarget and do not reproduce a separate policy implementation.

### D. Equal-distance tie-break measurement

For the V04 21×21 tie fixture or another 20..59 fixture:

- directly measure legality of all four aligned exits;
- compute exact total length of every legal candidate;
- print side/legality/length;
- prove intended tied sides are both legal and equal within 0.0001;
- directly show whether BOTTOM or any higher-priority candidate is legal and its length, so the tie winner cannot be falsely attributed;
- run production routing and prove chosen side is the first equal minimum according to `BOTTOM → LEFT → RIGHT → TOP`;
- print full production route array.

### E. Direct all-blocked routing mutation fingerprint

Around a direct `ProductionRoutingSystem.compute_route()` all-blocked call:

- capture full BoardState cell-state vector before and after;
- calculate a deterministic exact fingerprint of the full state vector (cell count + SHA-256 is preferred; printing the complete vector is also acceptable);
- prove fingerprints/vector identical;
- prove `NO_ROUTE` and retained target;
- print exact before/after fingerprints and target identity.

## 3. Required validation

Run and record literal command, result, exit and check count where reported:

1. `godot --version`
2. `godot --headless --path . -s res://tests/run_tests.gd`
3. V05 final-state evidence script
4. `tests/m22_v04_final_evidence.gd`
5. `tests/m22_v03_connector_evidence.gd`
6. `tests/m22_railroad_responsive_smoke.gd`
7. `tests/m22_responsive_smoke.gd`
8. `tests/m21_real_art_smoke.gd`
9. `tests/m21_v10_final_reservation_evidence.gd`
10. required M20 lifecycle/clearing smokes
11. `git diff --check`
12. exact Git inspection proving production `scripts/` + `scenes/` byte-identical to `8ded3580...` and root `TASKS.md` absent from V05 diff.

## 4. Commit / handoff

1. Review diff. Only authorized validation/evidence files may change.
2. Commit and push the V05 validation file first.
3. Capture exact validation commit SHA.
4. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V05.md` after validation SHA exists.
5. Log:
   - starting SHA;
   - validation SHA;
   - exact changed files;
   - production byte-identity proof;
   - exact C08 ReservationState/dispatcher pre/in-flight/post values;
   - exact all-blocked reverse-map/dispatcher-map values;
   - exact shortest candidate legality + lengths + production selection + route;
   - exact tie candidate legality + lengths + production selection + route;
   - direct all-blocked BoardState fingerprint before/after;
   - literal validation commands/results/exits;
   - `Magnific/image-generation credits spent = 0`;
   - root `TASKS.md` unchanged.
6. Commit/push the log separately.
7. Verify validation commit and `CLAUDE_LOG_V05.md` visible on GitHub main.
8. Return only:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V05.md`

Do not claim PASS. ChatGPT owns engineering closure and the subsequent owner F6 gate.
