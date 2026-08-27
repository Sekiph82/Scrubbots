---
coordinationSchema: scrubbots-coordination/v1
artifactType: claude-self-audit
cycleId: <MXX-CNNN>
version: 1
createdAt: <ISO-8601>
actor: CLAUDE
status: SELF_AUDIT_COMPLETE
milestone: <MXX>
taskRefs: []
activePromptUrl: <absolute GitHub URL>
implementationLogUrl: <absolute GitHub URL>
auditedCommit: <sha>
---

# SCRUBBOTS - Claude Self-Audit

This is an implementer self-audit. Its successful test results are provisional evidence and must not be presented as independent proof or `AUDITED_PASS`.

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Inputs read

- Active ChatGPT prompt(s): <absolute GitHub URLs>
- Prior ChatGPT audit(s) in this cycle: <absolute GitHub URLs or none>
- Relevant older ChatGPT audits from AUDIT_INDEX: <absolute GitHub URLs>
- Implementation log: <absolute GitHub URL>
- tasks.md: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- CLAUDE.md: https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- H!veAI dashboard: https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

## Audit learnings applied

List the relevant `AL-XXX` IDs from `coordination/AUDIT_INDEX.md`, what each changed in the current test plan, and any prior finding that is intentionally not applicable.

| Learning | Applied? | Effect on current verification |
| --- | --- | --- |
| AL-XXX | YES / NO / N/A | ... |

## Requirement test matrix

Every material prompt requirement must appear here.

| Requirement / task | Expected result | Explicit fail condition | Test/check | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | SELF_PASS / SELF_FAIL / NOT_RUN / BLOCKED / OWNER_REQUIRED | command/output/file/commit URL |

## Negative and boundary coverage

Describe checks beyond the happy path where relevant:

- malformed/invalid input;
- minimum/maximum boundaries;
- rectangular/variable sizing;
- state transitions;
- regression against prior behavior;
- missing-file/missing-asset behavior;
- scope integrity;
- performance/scale where relevant.

If a category does not apply, state why.

## Comparison with prior audited baseline

Compare current results with prior audited expectations/findings rather than only reporting a green current run.

| Prior audit learning/finding | Previous expectation | Current observation | Delta/regression? |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

## False-positive analysis

For each material test family, identify ways the test could pass without proving the intended behavior. Explain how the current self-audit mitigates that risk.

## Untested assumptions

List every material assumption that remains untested or not independently measurable. Do not hide them behind a successful aggregate test count.

## Test execution record

| Command/test | Expected | Failure criteria | Actual | Classification |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | SELF_PASS / SELF_FAIL / NOT_RUN / BLOCKED |

## Scope and locked-rule review

Check relevant project rules, including architecture boundaries, owner/design gates, no fabricated assets, no destructive Git actions, and any audit-learning IDs relevant to this cycle.

## Task-truth recommendation

Recommend which `tasks.md` items may be changed based on provisional evidence. Make clear that ChatGPT will independently audit these claims.

## GitHub evidence

- Active prompt: <URL>
- Implementation log: <URL>
- This self-audit: <URL>
- Session index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- Dashboard: https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- Relevant commit(s): <GitHub commit URLs>

## Self-audit conclusion

Use only the Claude self-audit vocabulary from `AUDIT_POLICY.md`.

Implementation readiness for independent audit: `READY`, `NOT_READY`, or `BLOCKED`.

Do not use `AUDITED_PASS`.
