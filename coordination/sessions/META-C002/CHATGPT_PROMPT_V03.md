---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C002
version: 3
createdAt: 2026-09-05T15:04:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V03.md
triggerAudit: CHATGPT_AUDIT_V02.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# SCRUBBOTS - META-C002 Merge-Readiness Evidence Correction V03

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Continue on:
`feature/master-ui-magnific-pipeline` / PR #3.

Fetch origin and safely synchronize the local feature branch with its remote,
preserving all owner work.

Verify whether `origin/main` advanced after the V02 merge. If it did, safely
integrate it before continuing. Do not rewrite published history.

Never use reset --hard, clean -fd, force push, or destructive Git operations.

Do not create any Desktop/local handoff log.

All durable V03 evidence goes only to:

https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V03.md

## Read first

1. Audit V02:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V02.md
2. V03 criteria:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_CRITERIA_V03.md
3. V02 prompt:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V02.md
4. V02 log:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V02.md
5. Governance and H!ve/coordination sources.

## Objective

Close only F-META-005 and F-META-006.

Do not rework the accepted V02 visual inventory, manifest, task migration,
task truth, UI architecture or Magnific policy unless an actual regression is
found.

## Required work

### 1. Create CLAUDE_LOG_V03.md

Create it at the start of material V03 work.

Preserve V01/V02 logs unchanged.

### 2. Re-check missing V02 validation evidence

Explicitly record these as individual numbered V03 validation entries:

29. `git diff --check`
30. final scope/binary/temp inspection
31. SESSION_INDEX truth
32. ACTIVE_CYCLES truth
33. ARTIFACT_MAP truth
34. PROGRESS_SNAPSHOT truth
35. PROJECT_DASHBOARD truth
36. PR #3 updated with corrected branch truth
37. PR #3 remains draft and unmerged
38. focused correction commit(s)
39. safe non-force push
40. CLAUDE_LOG_V03.md + correction commit visible on GitHub
41. final `git status`

For each, record actual evidence and PASS/FAIL. Do not merely say “recorded
below”.

### 3. Refresh PR #3 body

Replace stale planning text with current branch truth.

The body must state at minimum:

- Master UI/Magnific foundation implemented;
- 95 UI/Magnific tasks migrated into canonical tasks.md exactly once;
- docs/UI_TASKS_APPENDIX.md removed after verified migration;
- 51 owner visual references imported copy-only and inventoried with hashes,
  dimensions and provenance;
- canonical gameplay/Home/popup references recorded;
- Scrubby master remains OWNER_REQUIRED;
- branch progress is 196/943 = 20.78%;
- M12-C001 is AUDITED_PASS and integrated;
- 657/657 Claude-run Godot regression result;
- real-device safe-area/visual checks remain honest if still not independently
  validated;
- no broad/final Magnific generation performed;
- PR remains draft/unmerged awaiting ChatGPT audit.

Do not claim ChatGPT AUDITED_PASS before the audit exists.

### 4. Reconfirm accepted V02 truth

Recheck without unnecessary edits:

- 943 unique canonical task IDs;
- 196 complete;
- exactly 95 UI migration IDs;
- no current-main task lost/regressed;
- 51 image paths = 51 inventory records;
- Scrubby OWNER_REQUIRED;
- no M08 production-art task accidentally closed;
- no broad/final Magnific output.

### 5. Coordination

Update:

- coordination/SESSION_INDEX.md
- .hiveai/ACTIVE_CYCLES.md
- .hiveai/ARTIFACT_MAP.md
- .hiveai/PROGRESS_SNAPSHOT.md
- .hiveai/PROJECT_DASHBOARD.md
- PR #3

Use matching CLAUDE_LOG_V03.md.

## Stop

Set META-C002 to `AWAITING_AUDIT`, push safely, verify GitHub visibility,
and stop.

Do not merge PR #3.
Do not start M13.
Do not start broad/final Magnific generation.
Do not create or modify CHATGPT_AUDIT files.
