# M34–M40 OVERNIGHT BATCH V01 — Uninterrupted Implementation Master Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Owner authorization: explicit uninterrupted implementation through M40.
Total scheduled task IDs: **115**.

## 0. Governance and current exception
Read first:
- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/TASKS.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

M33 code audit has passed but its owner F6 listening gate is explicitly deferred by the owner for later.
**Do not modify or self-close M33.**
The owner's current instruction explicitly authorizes Claude to continue implementation work M34→M40 despite that deferred subjective M33 gate.

Root `TASKS.md` remains ChatGPT-write-owned. Claude MUST NOT edit it.

Claude implements/tests/logs/pushes only.
Claude does not create `CHATGPT_AUDIT_*.md`, does not assign `AUDITED_PASS`, and does not close task checkboxes.

## 1. NEVER-STOP batch rule
Proceed through M34, M35, M36, M37, M38, M39, M40 **without waiting for ChatGPT between milestones**.

At the end of each milestone:
1. finish all safely implementable tasks;
2. run required tests;
3. write every required individual task log;
4. write/update the canonical `CLAUDE_LOG_V01.md`;
5. commit implementation/tests;
6. commit evidence/logs;
7. push to `origin/main`;
8. verify the remote GitHub log exists;
9. immediately read the next milestone prompt/criteria and continue.

Do NOT stop merely because a task is:
- `OWNER_REQUIRED`;
- `DEVICE_REQUIRED`;
- a later visual/listening/playtest gate;
- awaiting independent ChatGPT audit.

Record that gate truthfully in its task log, then continue.

Only stop as `BLOCKED` if continuing would:
- destroy/overwrite owner work;
- require an unresolved owner design choice that changes canonical mechanics and has no safe non-shipping deferral;
- require unavailable secrets/credentials/paid external service;
- leave the repository uncompilable after reasonable repair attempts;
- encounter a Git divergence/conflict that cannot be resolved without guessing or destructive operations.

No `reset --hard`, `clean -fd`, destructive restore, or force push.

## 2. Resume-after-context-loss protocol
This batch is intentionally long. Scratchpad/chat memory is NOT authority.

Before every milestone, and after any context compression/restart:
1. `git fetch origin`
2. inspect `git status --short`
3. inspect `git log --oneline --decorate -15`
4. safely sync with `origin/main`
5. re-read THIS master prompt from GitHub
6. re-read the target milestone prompt + criteria
7. re-read the immediately previous milestone's `CLAUDE_LOG_V01.md`
8. inspect the target session `task_logs/` directory and existing commits
9. determine the first unfinished task from durable GitHub evidence
10. continue from there without redoing already-pushed work

Never rely on a local scratchpad as the sole record of progress.

## 3. Milestone sequence

### M34 — Haptics
Tasks:
`SB-M34-001..SB-M34-006`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M34-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M34-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M34-C001/CLAUDE_LOG_V01.md

Real-device task SB-M34-006 may remain DEVICE_REQUIRED; do not stop.

### M35 — Level Catalog
Tasks:
`SB-M35-001..SB-M35-011`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M35-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M35-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M35-C001/CLAUDE_LOG_V01.md

### M36 — Difficulty System
Tasks:
`SB-M36-001..SB-M36-006`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M36-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M36-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M36-C001/CLAUDE_LOG_V01.md

Human playtest task SB-M36-005 may remain OWNER_REQUIRED; do not stop.

### M37 — Level Progression
Tasks:
`SB-M37-001..SB-M37-008`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CLAUDE_LOG_V01.md

If no owner approval exists for shipping Level Select, log SB-M37-006 OWNER_REQUIRED and continue.

### M38 — Win Streak
Tasks:
`SB-M38-001..SB-M38-016`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M38-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M38-C001/CLAUDE_LOG_V01.md

M38 may create only the narrow canonical RewardGrantService/GiftMeterService foundations required for streak. M39 must extend those same services.

### M39 — Economy & Rewards V1
Tasks:
`SB-M39-001..SB-M39-052`, including `SB-M39-047A`, `SB-M39-047B`, `SB-M39-047C`.
Total M39 task IDs: 55.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CLAUDE_LOG_V01.md

This is critical/stateful. Follow phase commits in the prompt. Do not self-audit. After push, continue to M40.

### M40 — Save System
Tasks:
`SB-M40-001..SB-M40-013`

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Expected durable log:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CLAUDE_LOG_V01.md

M40 is the final implementation milestone in this batch. Do not start M41.

## 4. Per-task logging is mandatory
For **every one of the 115 task IDs**, create a separate durable task log inside its milestone:

`coordination/sessions/MXX-C001/task_logs/<TASK_ID>.md`

A task log must exist even when status is OWNER_REQUIRED / DEVICE_REQUIRED / BLOCKED.

Each task log includes:
- task ID + exact requirement
- status
- prompt/criteria version
- production owner/path/API
- files changed
- canonical state touched/read
- exact tests/checks
- expected result
- explicit failure condition
- actual result
- boundary/negative tests
- rollback/idempotency/conservation notes when applicable
- owner/device/dependency gate
- commit SHA(s)
- GitHub evidence URL(s)
- remaining risk

Do not use one giant combined paragraph as a substitute for task-level evidence.

The milestone `CLAUDE_LOG_V01.md` must index every task log with direct GitHub paths/URLs and summarize milestone commits/tests.

## 5. Commit and push policy
Each milestone must be durably present on GitHub before the next milestone begins.

Minimum shape:
- implementation/test commit(s)
- evidence/log commit
- normal push to `origin main`
- remote verification

M39 may use multiple subsystem implementation commits before its evidence/log commit.

Do not amend already-pushed historical milestones merely for cosmetic message changes.
Do not put generated log files only in scratchpad/Desktop.

## 6. Testing rule
A green root suite is not enough by itself.
Run every direct test required by that milestone's audit criteria and record it individually.

For critical M38/M39/M40 state:
- duplicate/re-entry
- stale identity/state
- rollback/partial failure
- reset/retry
- malformed snapshot/input
- idempotency
- exact-set/conservation
must be directly tested where applicable.

If a required test fails:
- diagnose;
- repair within milestone scope;
- rerun;
- record failure + fix in task log;
- continue only once repository is green enough to safely build the next dependency.

## 7. Do not fake gates
Do not fabricate:
- real-device haptic results;
- human difficulty playtest results;
- owner Level Select approval;
- independent ChatGPT audit verdicts.

Those task logs stay explicitly gated while coding continues.

## 8. Final M40 batch handoff
After M40 is committed, logged, pushed and remotely verified, stop production work.

Return exactly this structured summary:
- M34 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M35 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M36 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M37 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M38 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M39 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- M40 implementation/log commit(s) + CLAUDE_LOG GitHub URL
- list of OWNER_REQUIRED / DEVICE_REQUIRED tasks still open
- confirmation root TASKS.md was not edited
- confirmation no M41+ implementation was started

Final line:
`AWAITING_AUDIT / M34-M40 OVERNIGHT BATCH IMPLEMENTATION COMPLETE`

Do not claim `AUDITED_PASS`.