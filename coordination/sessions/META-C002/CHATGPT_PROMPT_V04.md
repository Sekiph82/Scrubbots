---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C002
version: 4
createdAt: 2026-09-05T15:04:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V04.md
triggerAudit: CHATGPT_AUDIT_V03.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# SCRUBBOTS - META-C002 Exact Git Evidence Finalization V04

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Continue on:
`feature/master-ui-magnific-pipeline` / PR #3.

Fetch origin and safely synchronize the local feature branch with its remote,
preserving all owner work.

Verify whether `origin/main` advanced. If it did, safely integrate it before
continuing and record the exact merge/reconciliation evidence.

Do not use reset --hard, clean -fd, force push, destructive checkout, or any
operation that deletes unrelated owner files.

Do not create any Desktop/local handoff log.

All durable V04 evidence goes only to:

https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V04.md

## Read first

- Audit V03:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V03.md
- Criteria V04:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_CRITERIA_V04.md
- Prompt/log V03:
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V03.md
  https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V03.md
- CLAUDE.md
- coordination/AUDIT_INDEX.md
- current PR #3
- current SESSION_INDEX/H!ve tracking

## Objective

Close only F-META-007.

Do not change accepted inventory, manifest, tasks.md truth, UI architecture,
reference selection, PR body content, or Magnific policy unless an actual
regression is discovered.

## Mandatory exact evidence

Create CLAUDE_LOG_V04.md at the start.

Record exact command output / values for:

1. current local branch name;
2. current local HEAD full SHA before V04;
3. current `origin/feature/master-ui-magnific-pipeline` full SHA before V04;
4. exact V03 commit full SHA and proof it equals the remote feature head before
   V04;
5. current `origin/main` full SHA and whether integration is required;
6. full `git status --short` before any V04 edits;
7. every repo-local untracked path from that output, classified as:
   - owner work to preserve;
   - intentional ignored/generated state;
   - accidental temp;
   - unknown, preserve/fail closed.
8. confirmation no unrelated owner work was deleted, overwritten or staged;
9. PR #3 current draft/unmerged state;
10. PR #3 body still contains current audited truth;
11. 943 unique canonical task IDs;
12. 196 completed IDs;
13. no task checkbox change in V04;
14. no inventory/manifest/UI implementation change in V04;
15. exact files intentionally changed by V04;
16. `git diff --check`;
17. full `git status --short` immediately before commit;
18. focused V04 commit;
19. **after the commit exists, record its full commit SHA in CLAUDE_LOG_V04**;
20. safe non-force push;
21. query origin and record the exact final remote feature-branch head SHA;
22. prove final remote head equals the V04 commit SHA;
23. verify CLAUDE_LOG_V04.md is visible on GitHub at that exact head;
24. full final `git status --short` output;
25. PR #3 still draft/unmerged after push.

### Important logging mechanics

Because the V04 commit SHA does not exist until after the first commit:

- it is acceptable to create a focused V04 evidence commit;
- then append the resulting full SHA and push verification to
  CLAUDE_LOG_V04.md;
- create one small log-finalization commit if necessary;
- if a finalization commit is created, record **both** SHAs and make clear
  which SHA is the final remote head;
- never claim a SHA before it exists.

The audit requires concrete full SHAs, not placeholders such as
`<commit>`, “current head”, or “size and sha returned”.

## Coordination

Update only as needed:

- coordination/SESSION_INDEX.md
- .hiveai/ACTIVE_CYCLES.md
- .hiveai/ARTIFACT_MAP.md
- .hiveai/PROJECT_DASHBOARD.md

PROGRESS_SNAPSHOT should remain unchanged if no task truth changes.

## Stop

Set META-C002 to `AWAITING_AUDIT`, push safely, verify final remote head and
log visibility, and stop.

Do not merge PR #3.
Do not start M13.
Do not generate Magnific assets.
Do not create or modify CHATGPT_AUDIT files.
