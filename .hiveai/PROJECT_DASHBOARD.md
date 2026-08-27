# SCRUBBOTS - H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
coordinationSchema: scrubbots-coordination/v2
-->

This file is the single H!veAI-facing materialized project status and latest-session summary surface. It is not a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

## Project identity

| Field | Value |
| --- | --- |
| Project | SCRUBBOTS |
| Repository | https://github.com/Sekiph82/Scrubbots |
| Branch | `main` |
| Engine | Godot 4.7.1-stable (GDScript) |
| Platform target | Mobile (Android first, iOS later) |
| Attribution | Developed by Akilta |

## H!veAI live status

| Field | Value |
| --- | --- |
| Project status | ACTIVE |
| Health | HEALTHY |
| Current implementation frontier | M07 - Visual Reference Library |
| Current task | M07-C001 - Visual Reference Library foundation + asset availability audit |
| Current task ID | `M07-C001` |
| Current workflow state | AWAITING_AUDIT - Claude implementation + self-audit complete; awaiting ChatGPT independent audit |
| Last established code baseline | Phase M06: 227/227 headless checks PASS at `abd9ceb` |
| Verification rule | Future Claude-run results are provisional self-evidence until ChatGPT independent audit |
| Open design gate | M10 DIRTY/CLEAN final preset selection |
| Required actor | CHATGPT |
| Next project action | ChatGPT reads implementation log + self-audit V01 against audit criteria V01, performs independent audit, publishes CHATGPT_AUDIT_V01.md |
| Waiting on | Owner-approved artwork remains required for asset-specific M07 inventory tasks; infrastructure work can proceed |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T10:30:00+03:00 |
| Actor | CLAUDE |
| Cycle | `M07-C001` |
| Session type | Implementation + self-audit |
| Cycle status | AWAITING_AUDIT |
| Milestone/task impact | 10 M07 infrastructure tasks marked [x] with validation evidence (SB-M07-001..007, 015..017). 7 asset tasks remain [ ] AWAITING OWNER ASSET (SB-M07-008..014). No other milestones changed. |
| Summary | Implemented M07 Visual Reference Library infrastructure: directory structure, human-readable reference guide, machine-readable inventory (9 entries, 7 MISSING with null paths, 1 TEXT_ONLY, 1 PRESENT), tasks.md updated. Applied AL-005/006/007. Regression: 227/227 PASS (unchanged). Self-audit V01 covers 14 requirement checks, all SELF_PASS. No fabrication, no scope creep, no M10 gate violation. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Claude self-audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md |
| Expected ChatGPT independent audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| Next expected actor | CHATGPT |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07-C001 | Visual Reference Library foundation + asset availability audit | AWAITING_AUDIT | CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md |
| M07 | Visual Reference Library | PARTIAL — infrastructure done, assets AWAITING OWNER | CHATGPT (audit) + HUMAN (assets) | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | OWNER_REQUIRED | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Audit model

The repository uses two audit layers plus a published criteria layer:

1. **ChatGPT audit criteria** define in advance what will count as pass/fail for the cycle.
2. **Claude self-audit** is implementer-owned and provisional. Claude may use `SELF_PASS`, `SELF_FAIL`, `NOT_RUN`, `NOT_APPLICABLE`, `BLOCKED`, or `OWNER_REQUIRED`, but never `AUDITED_PASS`.
3. **ChatGPT independent audit** compares the prompt, actual repository state, Claude implementation log, Claude self-audit, test design, prior audit learnings, and reproducible evidence. Only this step may assign `AUDITED_PASS` or `AUDITED_FAIL`.

Canonical audit sources:

- Policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- Learning index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- Claude self-audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md
- ChatGPT audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_AUDIT_TEMPLATE.md
- Current M07 audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Claude must read the audit index before each material implementation/self-audit pass and explicitly state which `AL-XXX` learnings changed its test plan. ChatGPT updates the audit index after independent audits when a reusable verification lesson is discovered.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M07-C001` | M07 | AWAITING_AUDIT | CLAUDE | Implementation + self-audit V01 complete. 10/17 tasks provisionally validated. 227/227 regression PASS. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md |
| `META-C001` | META | AUDITED_PASS | CHATGPT | Established repository-native ChatGPT<->Claude coordination and H!veAI synchronization. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md |

## Coordination source map

H!veAI actively watches only this dashboard file. ChatGPT/Claude must read and synchronize the following GitHub sources into it after every material session.

| Purpose | Canonical GitHub source |
| --- | --- |
| Task ledger | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| Agent governance | https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md |
| Coordination protocol | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md |
| Session index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Prompt template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_PROMPT_TEMPLATE.md |
| Claude implementation-log template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md |
| Claude self-audit template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md |
| ChatGPT audit template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_AUDIT_TEMPLATE.md |
| Project history | https://github.com/Sekiph82/Scrubbots/blob/main/CHANGELOG.md |
| Roadmap | https://github.com/Sekiph82/Scrubbots/blob/main/docs/04_ROADMAP.md |
| Architecture | https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md |
| Technical decisions | https://github.com/Sekiph82/Scrubbots/blob/main/docs/05_TECH_DECISIONS.md |
| Gameplay specification | https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md |
| Test strategy | https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md |

## Single-dashboard synchronization contract

After every material ChatGPT or Claude session, update this dashboard with:

- timestamp and actor;
- cycle ID/status;
- active prompt/audit-criteria/self-audit/audit URLs;
- concise work summary;
- current blocker/waiting state;
- next actor/action;
- actual task/project state only when canonical truth changed.

Also update:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md

Never duplicate the full `tasks.md` checklist here.

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00 | Foundation & Environment | COMPLETE |
| M01 | Variable-Size Level Data Core | COMPLETE |
| M02 | BoardState Core | COMPLETE |
| M03 | Official Difficulty Bands + 59x59 | COMPLETE |
| M04 | Expanded Board Fixtures & Test Matrix | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | PARTIAL — infrastructure complete, assets awaiting owner |
| M08-M55 | Remaining milestones | NOT_STARTED |

## Quality baseline

- Last established code-milestone evidence before M07: Phase M06, 227/227 checks PASS at `abd9ceb`.
- Claude must rerun required checks in M07-C001, but its own results remain provisional until ChatGPT independent audit.
- A successful aggregate count does not override requirement-specific failures, weak test design, missing negative checks, false-positive risk, or owner-controlled gates.

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude self-tests are provisional evidence.
- Only ChatGPT independent audit may assign `AUDITED_PASS`/`AUDITED_FAIL`.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Never rewrite historical prompt/audit versions to improve appearances retroactively.
- Never publish secrets or sensitive environment values.
