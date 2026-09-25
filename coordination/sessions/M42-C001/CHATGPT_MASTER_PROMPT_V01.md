# M42-C001 V01 — MASTER CONTINUOUS EXECUTION PROMPT

Milestone: M42 — Home / Navigation
Tasks: SB-M42-001 through SB-M42-033
Actor: Claude
Repository: Sekiph82/Scrubbots

Execute every M42 task in numerical order using:
- task prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-XXX.md`
- audit criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-XXX.md`

## Mandatory loop for each task

1. Pull/read current `main`, root `TASKS.md`, `CLAUDE.md`, that task's prompt and audit criteria.
2. Inspect actual source/state before editing.
3. Implement only the authorized task/minimum prerequisite.
4. Run prompt-required focused tests/regressions and `git diff --check`.
5. Review diff; root `TASKS.md`, ChatGPT audit files and owner decision/acceptance files must not be changed.
6. Commit and push implementation with the task ID.
7. Create `coordination/sessions/M42-C001/task_logs/SB-M42-XXX.md` containing exact implementation SHA(s), changed files, exact commands/results, SCRIPT ERROR count, criteria map and remaining gates.
8. Commit and push the task log.
9. In user-facing progress output print the full clickable URL:
   `https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M42-C001/task_logs/SB-M42-XXX.md`
10. Continue immediately to the next task. Do not wait for ChatGPT audit.

## Gates that do NOT stop the convoy

- SB-M42-014/016/017: if art needs owner approval, preserve generated candidates and log `OWNER_ASSET_APPROVAL_REQUIRED`; never self-approve/promote.
- SB-M42-026: absent owner MP4 -> `OWNER_ASSET_REQUIRED`; continue independent work.
- SB-M42-027: missing encoder/tool -> `TOOLING_REQUIRED`; continue independent work.
- SB-M42-030: if no explicit owner skip decision exists, do not invent one; publish `OWNER_DECISION_REQUIRED` and continue to 031.
- SB-M42-032: without real Android device -> `DEVICE_OWNER_REQUIRED`; never fake device validation.
- SB-M42-033: static/export iOS readiness may complete; physical playback remains `IOS_DEVICE_LATER` unless actually tested.

A gate blocks only genuinely dependent work. Continue all independent tasks.

## Locked decisions

- NO SHIPPING LEVEL SELECT:
  `coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`
- Opening playback frequency:
  `coordination/OWNER_M42_OPENING_PLAYBACK_FREQUENCY_DECISION_V01.md`
- Economy/Home semantics:
  `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- UI architecture:
  `docs/MASTER_UI_SYSTEM.md`
- Home asset contract:
  `docs/HOME_UI_ASSET_PLAN.md`
  `assets/ui/HOME_ASSET_MANIFEST.json`

## Global prohibitions

Never edit root `TASKS.md`. Never author ChatGPT audit verdicts. Never modify owner decision files. Never force-push. Never self-pass manual/device/design gates. Never reintroduce Stars, Event Points or profile XP authority. Never expose a shipping Level Select. Never flatten the Home reference into one interactive screenshot. Never silently overwrite approved assets. Never bake live amounts/timers/counts/labels into art.

## Master log

Maintain and periodically push:
`coordination/sessions/M42-C001/CLAUDE_MASTER_LOG_V01.md`

For every task record:
- task ID;
- implementation SHA;
- task-log commit SHA;
- full task-log URL;
- status (`AWAITING_AUDIT` or explicit external gate);
- one-line test result.

## Final handoff

After SB-M42-033, STOP. Do not audit yourself and do not edit `TASKS.md`.

Final response must summarize all 33 statuses, list remaining owner/device/asset/tooling gates, give the full GitHub URL to `CLAUDE_MASTER_LOG_V01.md`, and end with:
`AWAITING_BATCH_AUDIT / M42-C001 V01`

ChatGPT will independently audit every task log, write audit results to GitHub, decide PASS/FAIL, create narrow remediation prompts where required, and update the canonical tracker.
