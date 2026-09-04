---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: REPLACE
version: 1
actor: CHATGPT
status: ISSUED
taskRefs: []
---

# Independent Audit Criteria

Claude-run tests are implementation evidence. ChatGPT independently inspects
the GitHub implementation log, actual commits/diff/code/tests, task truth and
coordination state before assigning a verdict.

Every criterion must identify:
- pass requirement
- fail condition
- required evidence
- scope/design-gate boundaries
