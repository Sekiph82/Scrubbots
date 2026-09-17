# M22-C001 V04 — Claude Final Validation-Only Reconciliation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: close the frozen V03 direct-evidence residuals with production byte-identical.

Authoritative inputs:

- `TASKS.md` — read-only for Claude
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V03.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
- `coordination/sessions/M22-C001/CLAUDE_LOG_V03.md`
- V03 implementation commit `8ded3580a8eacee1c64364e530142e23d6f115db`

V04 is **validation-only**. The V03 production correction is accepted. Do not modify production source/scenes merely to make evidence convenient. If direct V04 observations reveal a real production mismatch, stop `BLOCKED` with exact evidence and do not patch production under this prompt.

Frozen residuals to close together:

1. `F-M22-V03-EVIDENCE-001` — five global SlotCell anchors were not persisted in the handoff evidence.
2. `F-M22-V03-EVIDENCE-002` — the all-aligned-blocked case did not directly observe ReservationState/dispatcher/agent side-effect absence through the full authority chain.
3. `F-M22-V03-EVIDENCE-003` — required validation commands were abbreviated rather than logged literally.
4. `F-M22-V03-EVIDENCE-004` — exact final Railroad route arrays were summarized rather than persisted in the handoff log.

## 1. Safe start / immutable boundary

Before validation:

1. Confirm repository is exactly `Sekiph82/Scrubbots` on `main`.
2. Fetch and safely fast-forward/synchronize with current `origin/main` while preserving all owner/local tracked and untracked work.
3. Record exact starting `origin/main` SHA.
4. Read every authoritative file above.
5. Inspect `git status` and the exact V03 production SHA.
6. Establish a production-immutability baseline for all production source/scenes changed through V03.
7. Do not modify root `TASKS.md`.

No force push, destructive clean/reset, owner-art mutation, Magnific/image generation, M23 work, or unrelated refactor.

Authorized V04 change surface:

- one new dedicated validation script under `tests/` if needed, preferably `tests/m22_v04_final_evidence.gd`;
- `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md`;
- no production source/scenes;
- no historical M21 tests/audits/logs.

## 2. Capture all five real global anchors and mapped starts

Use the real `m22_slot_demo.tscn` in a real `SubViewport` and await enough layout frames.

For slot IDs `0..4`, directly capture and print:

- slot id;
- actual laid-out top-center global anchor from the real production SlotCell/Button;
- independently mapped board-local start via `BoardPresentation.global_to_board_local()`.

Persist all five pairs in runtime output and later in `CLAUDE_LOG_V04.md`.

Then press the real C08 Button and directly prove:

- target `380 / (0,19)` arises naturally;
- route point 0 equals the independently mapped slot-2 start;
- route point 1 equals canonical `ScrubRailGeometry.bottom_entry(mapped_x)`;
- connector length is non-zero;
- full exact route point array is printed;
- rail travel is domain-clean;
- final approach is aligned/orthogonal to `(0.5,19.5)`;
- authenticated arrival clears exactly target 380 and reservation/assignment cleanup is observed directly.

Repeat with a second viewport/re-layout and print the newly measured slot-2 global anchor, mapped start and route point 0 to prove no stale connector geometry.

Do not infer global anchors from mapped values after the run. Record the direct runtime values.

## 3. Add direct all-aligned-blocked full-lifecycle evidence

Create a validation-only fixture using the real current production authority chain rather than calling only the routing helper.

The fixture must have a requested matching target that is ACTIVE, color-matching and initially unreserved, but for which all legal aligned Railroad approaches are blocked under authoritative access/routing truth.

Prefer an isolated same-color target so no alternative candidate can obscure the result.

Before activation capture:

- BoardState snapshot/state array;
- target index/coordinate/color/state;
- ReservationState count and mappings;
- dispatcher assignment count/map;
- current agent identities/count.

Activate through the real selection/dispatch/clearing path and prove directly:

- no successful assignment/agent spawn;
- no reservation appears for the blocked target or any owner;
- dispatcher active assignments remain unchanged;
- BoardState remains exactly unchanged;
- no target is cleared;
- no alternate target is silently selected;
- AgentLayer/agent parent has no new ScrubbotAgent after deferred cleanup.

If any of these observations fail because production behaves incorrectly, stop `BLOCKED` and do not change production.

## 4. Persist exact Railroad route arrays

From runtime, print and later copy exactly into `CLAUDE_LOG_V04.md`:

1. true far-right/top production-envelope route: board size, start, target, chosen aligned exit, full point array;
2. two-side blocked-preferred-exit fallback route: same target retained, full point array;
3. shortest-legal-route fixture: relevant candidate/side context, chosen side, full point array;
4. equal-distance tie-break fixture on a 20..59 board: competing legal sides/context, chosen side, full point array;
5. all-aligned-blocked direct routing result: `NO_ROUTE`, exact retained target identity;
6. rectangular 20..59 acceptance route;
7. 59x59 acceptance route.

For successful routes, classify connector vs canonical rail segments/corners vs final approach directly. Do not substitute source comments or prose for runtime arrays.

## 5. Required exact validation commands

Run the mandatory validations from `CHATGPT_AUDIT_CRITERIA_V04.md` and record in `CLAUDE_LOG_V04.md` the **literal command exactly as executed**, exact result, exit code, and check count when the command prints one.

At minimum include:

1. `godot --version` exact invocation/output;
2. full root `tests/run_tests.gd` command and total checks/failures/exit;
3. V04 final-evidence script command/result/exit;
4. V03 connector evidence command/result/exit;
5. M22 Railroad responsive smoke command/result/exit;
6. M22 V01 responsive/component smoke command/result/exit;
7. M21 full 400-cell real-art smoke command/result/exit;
8. M21 V10 reservation/direct evidence command/result/exit;
9. each required M20 lifecycle/clearing smoke command/result/exit;
10. strict TargetSelector/reservation/dispatcher/ScrubbotAgent coverage identified as root-suite checks or dedicated exact commands;
11. headless M22 demo boot/validation exact command with zero SCRIPT/Parse errors;
12. `git diff --check` exact command/result;
13. exact Git commands proving production source/scenes are byte-identical to V03 implementation SHA and root `TASKS.md` is absent from the V04 diff.

Do not write shorthand like only `-s tests/run_tests.gd`.

Historical M21 V08/V09 exact-ring-only failures may remain historical and must not be edited.

## 6. Git / evidence handoff

Use a non-circular evidence procedure.

1. Review the V04 diff and prove only authorized validation/evidence files changed.
2. Commit/push the validation script first if a script is added.
3. Capture its exact GitHub SHA.
4. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md` after the validation SHA exists.
5. The log must contain:
   - exact starting SHA;
   - exact V04 validation commit SHA;
   - separate log/evidence commit identity if applicable;
   - exact changed files;
   - all five global-anchor + mapped-start pairs;
   - exact C08 global anchor, mapped start, full route and arrival cleanup;
   - exact all-blocked full-lifecycle no-side-effect evidence;
   - exact route arrays from section 4;
   - every literal validation command/result/exit from section 5;
   - historical-only failures classified precisely if still present;
   - `Magnific/image-generation credits spent = 0`;
   - proof production source/scenes remain byte-identical to `8ded3580...`;
   - root `TASKS.md` unchanged.
6. Commit and push the log separately if needed.
7. Verify both the validation commit and `CLAUDE_LOG_V04.md` are visible on GitHub `main`.
8. Return only:

`AWAITING_AUDIT`

and the direct GitHub blob URL for `CLAUDE_LOG_V04.md`.

Do not claim PASS. ChatGPT performs the final engineering audit and, only if V04 passes, will close eligible Railroad engineering tasks and open the separate owner F6 visual/game-feel gate.