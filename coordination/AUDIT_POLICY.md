# SCRUBBOTS Audit Policy

This file defines how implementation claims, tests, self-audits, and independent ChatGPT audits are interpreted across SCRUBBOTS coordination cycles.

Canonical repository: https://github.com/Sekiph82/Scrubbots

## Core principle

An implementer's own test result is useful evidence, but it is not independent proof of the implementer's own work.

Claude must therefore treat its own successful tests as **provisional evidence**, not as final audit truth. ChatGPT performs the independent audit step after Claude implementation and self-audit.

A cycle may not reach `AUDITED_PASS` merely because Claude reports that tests passed.

## Evidence levels

### E0 - Claim / assumption

Examples:

- code exists;
- Claude says a requirement is implemented;
- a file appears to have the expected name;
- a test is expected to pass but was not run.

E0 is never enough for PASS.

### E1 - Implementer-run check

Claude ran a command/test and recorded the result.

This is useful but remains provisional because the same actor wrote the implementation and executed the check.

Use status `SELF_PASS`, `SELF_FAIL`, or `NOT_RUN` in Claude self-audits.

### E2 - Reproducible implementer evidence

Claude records enough detail for reproduction:

- exact command;
- exact commit/tree state;
- relevant output/result;
- expected behavior;
- failure criteria;
- affected requirement/task IDs.

E2 is strong provisional evidence, but is still not independent proof.

### E3 - Independent ChatGPT audit evidence

ChatGPT independently inspects repository state and, where tooling permits, reruns or cross-checks the relevant tests/commands/evidence.

Only ChatGPT audit files may assign `AUDITED_PASS` or `AUDITED_FAIL` to implementation requirements.

If a result cannot be independently rerun, ChatGPT must label it `NOT_INDEPENDENTLY_VERIFIED` rather than silently treating Claude's result as independent proof.

### E4 - Owner / design-gate approval

Some requirements are intentionally human-controlled, such as final visual design choices. Automated or AI audit cannot close these gates.

Use `OWNER_REQUIRED` until the owner explicitly approves.

## Pass/fail vocabulary

Claude self-audit uses:

- `SELF_PASS`: Claude executed sufficient checks and found the requirement satisfied. Provisional only.
- `SELF_FAIL`: Claude found a requirement violated or a required check failed.
- `NOT_RUN`: required/desired verification was not executed.
- `NOT_APPLICABLE`: requirement genuinely does not apply to this scope.
- `BLOCKED`: verification or implementation cannot proceed without external/owner input.
- `OWNER_REQUIRED`: only the owner can close the requirement/design gate.

ChatGPT audit uses:

- `AUDITED_PASS`: independently verified to the level appropriate for the requirement.
- `AUDITED_FAIL`: independent audit found the requirement unsatisfied.
- `NOT_INDEPENDENTLY_VERIFIED`: Claude evidence exists but ChatGPT could not independently establish the claim.
- `BLOCKED`: audit cannot complete because required external evidence/input is missing.
- `OWNER_REQUIRED`: human design/product approval remains open.

Do not use plain `PASS` where actor/verification level would be ambiguous.

## Claude self-audit requirements

Before handing a cycle to ChatGPT, Claude must create a versioned self-audit:

`coordination/sessions/<CYCLE_ID>/CLAUDE_SELF_AUDIT_VNN.md`

Canonical URL pattern:

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/<CYCLE_ID>/CLAUDE_SELF_AUDIT_VNN.md`

Each self-audit must:

1. Identify the active ChatGPT prompt version(s) by absolute GitHub URL.
2. Read `coordination/AUDIT_INDEX.md` before planning tests.
3. Read all prior `CHATGPT_AUDIT_VNN.md` files in the same cycle.
4. Read older ChatGPT audits identified by `AUDIT_INDEX.md` as relevant to systems touched in the current cycle.
5. Extract reusable prior findings, failure modes, tolerances, and test expectations.
6. Build a requirement-by-requirement test matrix before declaring completion.
7. Define the expected outcome and explicit failure condition for every material test.
8. Run more than the happy path when risk warrants it: boundary, negative, malformed, regression, scale, state-transition, and scope/integrity checks as applicable.
9. Classify its own results only with the Claude self-audit vocabulary above.
10. Treat successful implementer-run tests as provisional evidence, not final proof.
11. Compare current results to prior audited baselines and explain regressions, deltas, or changed expectations.
12. Record any test that could produce a false positive and how that risk was mitigated.
13. Record untested assumptions explicitly.
14. Link the implementation log, session index, dashboard, commits, and relevant files using absolute GitHub URLs.
15. Set the cycle to `AWAITING_AUDIT` only when the self-audit is complete enough for independent review.

Claude must never create or modify `CHATGPT_AUDIT_VNN.md` files.

## ChatGPT audit requirements

After Claude work, ChatGPT creates:

`coordination/sessions/<CYCLE_ID>/CHATGPT_AUDIT_VNN.md`

Each ChatGPT audit must:

1. Read the active prompt(s), Claude implementation log, Claude self-audit, task truth, audit policy, audit index, and actual repository state.
2. Treat Claude's test claims as provisional until independently cross-checked.
3. Compare required behavior with actual code/files/diffs/commits.
4. Independently rerun relevant tests when available through accessible tooling.
5. Where rerun is unavailable, use repository/test-code/output evidence but mark limits honestly.
6. Check for false-positive test design, missing negative tests, over-broad mocks, stale fixtures, incorrect tolerances, and claims that exceed measured evidence.
7. Check scope boundaries and locked project rules, not only whether tests are green.
8. Classify every material requirement with the ChatGPT audit vocabulary.
9. Record findings and exact corrective actions when status is `CHANGES_REQUIRED`.
10. Update `coordination/AUDIT_INDEX.md` when the audit discovers a reusable testing rule, recurring failure mode, new tolerance, or important verification lesson.
11. Update `coordination/SESSION_INDEX.md` and `.hiveai/PROJECT_DASHBOARD.md` after the audit.

## Continuous audit learning

`coordination/AUDIT_INDEX.md` is ChatGPT-owned audit memory for the repository.

Claude must read it before every material implementation/self-audit session and explicitly state which audit learnings were applied.

ChatGPT updates it after audits when a finding should affect future testing. This creates a feedback loop:

`prior audited finding -> AUDIT_INDEX learning -> next prompt/self-audit test plan -> Claude provisional evidence -> ChatGPT independent audit -> refined learning`

The objective is not to make tests larger for their own sake. The objective is to make future verification more discriminating and less likely to repeat known false positives.

## Existing high-value verification lessons

These are already-established project truths and should be treated as baseline audit learnings until superseded by a later audited decision:

1. Headless Godot reliability matters. Core/data cross-script references preserve the explicit `preload()` convention unless a deliberate task proves an alternative under headless execution.
2. Renderer pixel readback uses 8-bit `Image.FORMAT_RGBA8`; exact float equality can create false failures. Use meaningful/tolerant comparisons and test the intended color properties.
3. Headless execution cannot be presented as measured on-screen GPU/FPS evidence. Do not fabricate frame-rate claims from CPU/headless timing.
4. Variable-size and rectangular-board behavior must be tested. A passing square fixture is not proof of generic sizing.
5. Current maximum production envelope is 59x59 = 3,481 logical cells; scale-sensitive systems must include the maximum where relevant.
6. A file or feature existing is not enough to complete a `tasks.md` item; validation evidence is required.
7. Missing owner artwork must remain `AWAITING OWNER ASSET`; fabricated substitutes cannot satisfy visual-reference inventory requirements.
8. M10 DIRTY/CLEAN final visual choice remains an owner design gate; AI tests cannot close it.
