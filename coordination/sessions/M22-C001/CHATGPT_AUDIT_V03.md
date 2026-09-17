# M22-C001 V03 — ChatGPT Independent Strict Audit

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited implementation commit: `8ded3580a8eacee1c64364e530142e23d6f115db`
Implementation parent: `51fdc62649177d46a6facf4513c041cfa52e508b`
Evidence commit: `60336c4803ed686501a64cac3036d5bf50be3397`
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit criteria: `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

## Verdict

**CHANGES_REQUIRED / PRODUCTION_CORRECTION_ACCEPTED / FINAL_DIRECT_EVIDENCE_RESIDUALS_FROZEN / V04_VALIDATION_ONLY_REQUIRED**

V03 materially closes the two production/source defects and most of the V02 direct-route evidence gap. The current production router no longer constructs or searches the superseded M21 adjacent one-cell exterior ring for outside starts; real below-board slot starts use Railroad V1; the new frame-driven connector test measures the post-layout SlotCell mapping independently; and the Railroad route matrix now contains centreline-domain assertions, production-envelope rectangular/tie-break fixtures and a true far-right/top case.

No reviewed V03 source evidence requires another production correction. The remaining blockers are **direct evidence / handoff completeness only**. V04 is therefore validation-only unless its direct observations expose a genuine production mismatch.

The final residual finding set below is frozen. V04 must close all of it in one pass. Do not create serial micro-prompts.

## 1. Independent diff / governance inspection

`51fdc626... -> 8ded3580...` is exactly one implementation commit and changes only:

- `scripts/gameplay/routing/production_routing_system.gd`
- `tests/run_tests.gd`
- `tests/m22_v03_connector_evidence.gd`

Root `TASKS.md` is absent from the implementation diff. Accepted V01/V02 geometry/presentation/slot sources, TargetSelector, ReservationState, dispatcher, ScrubbotAgent and CompleteClearingLoop were not rewritten in the V03 implementation commit.

The handoff log is correctly separated into evidence commit `60336c4803...`, and it records the exact implementation SHA after that SHA existed on GitHub. This closes the V02 circular commit-identity defect.

## 2. Accepted V03 production corrections

### 2.1 F-M22-V02-STRICT-001 — CLOSED

Accepted.

`ProductionRoutingSystem.compute_route()` now routes every start whose floored board cell is outside `[0,W) x [0,H)` into `_railroad_route()`. The previous `_is_below_board_start()` gate is replaced by `_is_outside_start()`.

The current interior BFS no longer:

- constructs the `[-1..W] x [-1..H]` adjacent exterior ring;
- seeds ring cells;
- traverses `_is_ring()` cells;
- contains `_is_ring()` at all.

The retained non-rail planner is therefore limited to genuine inside-board starts and searches inside-board cells only. Historical M21 audit/test files remain historical rather than being rewritten to claim Railroad V1 existed earlier.

No TargetSelector call or retarget was added. Railroad routes still bypass the generic shortcut/rounding post-process and remain subject to authoritative access truth plus whole-route validation.

### 2.2 F-M22-V02-STRICT-002 — CLOSED at source/test level

Accepted at source/test level.

`tests/m22_v03_connector_evidence.gd` hosts the real M22 demo inside a real `SubViewport`, waits multiple process frames before measurement, reads actual production SlotCell anchors, maps them independently through `BoardPresentation.global_to_board_local()`, and then compares a real Button-produced route against that independently measured mapping.

The previous circular `(0,24)` evidence is corrected. The V03 log reports the post-layout mapped slot-2 start as approximately `(9.222222, 24.0)` and the real C08 route as:

`(9.222222,24.0) -> (9.222222,22.5) -> (0.5,22.5) -> (0.5,19.5)`

The test also performs a second layout/reposition case and proves route point 0 tracks the newly measured anchor rather than a cached prior value.

### 2.3 F-M22-V02-EVIDENCE-001 — materially CLOSED at test-source level

Accepted at test-source level.

The root suite now includes `_assert_rail_domain()`, which does more than axis-alignment. It directly requires intermediate rail-travel segments to lie on canonical TOP/BOTTOM/LEFT/RIGHT centrelines and requires side changes to occur only at canonical corners.

The updated matrix includes:

- far-left/bottom target;
- true far-right/top target on 20x20;
- bottom + left two-side travel via the BL corner;
- blocked preferred exit fallback for the same target;
- all-aligned blocked `NO_ROUTE` retaining target index;
- shortest-route choice;
- deterministic tie-break on 21x21;
- rectangular routing on 40x24;
- 59x59 routing.

The formerly out-of-envelope acceptance fixtures `19x19` and `30x12` are no longer the required production proof for tie-break/rectangular routing.

### 2.4 F-M22-V02-EVIDENCE-002 — CLOSED

Accepted.

V03 uses the required two-step evidence procedure. `8ded3580...` is the implementation commit. `CLAUDE_LOG_V03.md` was created only afterward in evidence commit `60336c4803...` and records the exact implementation SHA.

## 3. Frozen final evidence residuals

These are evidence blockers, not demonstrated production defects.

### F-M22-V03-EVIDENCE-001 — M22-V03-104 handoff evidence is incomplete: global SlotCell anchors are not recorded

The V03 criteria and prompt require the handoff to record, for all five slot IDs, both:

1. the actual laid-out top-center **global anchor**; and
2. the independently mapped board-local start.

`CLAUDE_LOG_V03.md` records only the five mapped board-local values:

- slot 0 -> `(1.666667, 24.0)`
- slot 1 -> `(5.444445, 24.0)`
- slot 2 -> `(9.222222, 24.0)`
- slot 3 -> `(13.0, 24.0)`
- slot 4 -> `(16.77778, 24.0)`

The dedicated V03 test reads `anchor_global` internally but does not print or otherwise persist the five global anchor values. Therefore the exact M22-V03-104 evidence cell is not closed.

V04 must capture and log all five actual global anchors and mapped starts after real layout. Do not infer global anchors later from mapped numbers; record the direct runtime observations.

### F-M22-V03-EVIDENCE-002 — M22-V03-055 does not directly prove ReservationState/agent side-effect absence for the all-aligned-blocked case

The V03 routing unit case for an enclosed interior target directly proves:

- route failure;
- `NO_ROUTE`;
- same target index retained;
- BoardState ACTIVE count unchanged.

That is useful and accepted, but M22-V03-055 explicitly requires **no BoardState/reservation/agent side effects** for this all-aligned-blocked condition.

The existing unit case invokes routing directly, before ReservationState or agent creation is involved. Separate no-work/reset tests prove those layers in other scenarios, but they do not directly observe the same all-aligned-blocked target transaction requested by M22-V03-055.

V04 must create a validation-only fixture through the real selection/dispatch/loop authority where the relevant matching target is not targetable because all legal aligned approaches are blocked, then directly prove:

- activation fails cleanly / no agent is spawned;
- ReservationState count and bidirectional mappings remain absent/unchanged;
- dispatcher active assignments remain absent/unchanged;
- BoardState is byte/state-equivalent before/after;
- no target is silently substituted merely to obtain success.

If this direct test exposes a genuine mismatch, stop `BLOCKED` and do not patch production under the validation-only authorization.

### F-M22-V03-EVIDENCE-003 — the V03 log does not record the exact validation commands required by M22-V03-085..096 / prompt section 6

The V03 log records useful result summaries, but several command entries are shorthand such as:

- `-s tests/run_tests.gd`
- `-s tests/m22_v03_connector_evidence.gd`
- grouped M20 script names

The prompt explicitly required the **exact command, result, check count where applicable, and exit code**. The evidence log therefore does not fully satisfy the handoff contract even though the reported outcomes are green.

V04 must record the literal commands actually executed, including executable invocation and `--headless --path . -s res://...` arguments (or the exact equivalent used locally), plus result and exit code for each mandatory validation item.

### F-M22-V03-EVIDENCE-004 — M22-V03-107 handoff evidence summarizes, but does not persist the exact route arrays needed for final reconciliation

The committed tests contain the required route assertions, but `CLAUDE_LOG_V03.md` summarizes the far-right/top, shortest-route and tie-break cases rather than persisting their exact route point arrays. The V03 prompt explicitly requires the log to record the far-right/top route and the blocked/all-blocked/shortest/tie-break evidence.

For final closure, V04 must log exact route point arrays for at least:

- true far-right/top production-envelope route;
- two-side/corner fallback route;
- shortest-route fixture;
- equal-distance tie-break fixture;

and record the exact `NO_ROUTE` result/target identity for the all-blocked case. This makes the final evidence independently inspectable without reconstructing runtime output from source comments.

## 4. Runtime evidence assessment

Claude reports:

- Godot `4.7.2.stable.official.ed1daf0bf`;
- root suite `4798` checks, `0` failures, exit `0`;
- dedicated V03 connector evidence PASS;
- M22 Railroad responsive smoke PASS;
- V01 M22 responsive/component smoke PASS;
- M21 real-art full 400-cell clear PASS;
- M21 V10 reservation evidence PASS;
- required M20 lifecycle smokes PASS;
- strict TargetSelector/reservation/dispatcher/agent checks in the root suite PASS;
- `git diff --check` clean;
- zero Magnific/image-generation credits.

The historical M21 V08/V09 failures are explicitly classified as obsolete exact-ring assertions and were not rewritten. That classification is acceptable.

ChatGPT cannot independently execute the user's local Godot binary in this audit environment, so runtime claims remain implementer evidence cross-checked against committed source and test structure. No source-level contradiction was found in the accepted V03 production correction.

## 5. Task / owner-gate decision

Do **not** open `SB-M22-035` owner F6 visual/game-feel acceptance yet.

Do **not** close `SB-M22-009` or `SB-M22-026..034` yet under the strict tracker rule, because final milestone evidence is still incomplete. Production implementation is provisionally accepted, but task closure remains gated by final direct evidence reconciliation.

Progress and `lastCompletedTaskId` remain at the accepted M22 V01 frontier until V04 passes.

No owner manual playtest is required for V04. V04 is validation-only. If V04 closes the frozen evidence residuals with production byte-identical, ChatGPT may perform the engineering `AUDITED_PASS`, close eligible Railroad rows, and then open the separate owner F6 visual/game-feel gate.

## 6. V04 closure law

V04 is **validation-only and production-immutable**.

Authorized surface:

- a new dedicated V04 validation script under `tests/`, if needed;
- `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md`;
- no production source, scenes, existing historical M21 tests, root `TASKS.md`, owner art or generated content.

V04 must close together:

- `F-M22-V03-EVIDENCE-001`
- `F-M22-V03-EVIDENCE-002`
- `F-M22-V03-EVIDENCE-003`
- `F-M22-V03-EVIDENCE-004`

Mandatory final reruns include the full root suite, V03 connector evidence, current Railroad responsive smoke, V01 responsive smoke, M21 full-clear smoke, M21 V10 reservation evidence, required M20 lifecycle smokes, strict routing/target/reservation/dispatcher/agent checks, demo boot and `git diff --check`.

If direct all-blocked lifecycle evidence reveals a production mismatch, stop `BLOCKED` and return the observation without changing production.

If all residuals close and production remains byte-identical, return `AWAITING_AUDIT` with `CLAUDE_LOG_V04.md` for final engineering closure and owner F6 gate opening.