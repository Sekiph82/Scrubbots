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
| Current workflow state | PLANNED - V02 prompt issued; awaiting Claude implementation/self-audit |
| Automated evidence baseline | 227/227 headless checks passed at Phase M06 (`abd9ceb`), but future Claude reruns are provisional until independently audited |
| Open design gate | M10 DIRTY/CLEAN final preset selection |
| Required actor | CLAUDE |
| Next project action | Claude reads the active M07-C001 V02 prompt, audit policy/index, applies prior audit learnings, implements M07 infrastructure, writes implementation log + self-audit, then hands back as `AWAITING_AUDIT` |
| Waiting on | Owner-approved artwork remains required for asset-specific M07 inventory tasks; infrastructure work can proceed |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T11:58:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M07-C001` |
| Session type | Prompt revision + audit-system hardening |
| Cycle status | PLANNED |
| Milestone/task impact | No task checkbox changed; verification protocol strengthened before Claude implementation |
| Summary | Superseded M07-C001 V01 with V02 before implementation, changed repository references to absolute GitHub URLs, added dual-audit rules, added Claude self-audits, and established reusable audit learnings so Claude's own green tests remain provisional until independent ChatGPT audit. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Expected Claude self-audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md |
| Expected ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07-C001 | Visual Reference Library foundation + asset availability audit | PLANNED | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md |
| M07 | Visual Reference Library | NOT_STARTED / awaiting implementation evidence | CLAUDE + HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | OWNER_REQUIRED | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Audit model

The repository uses two audit layers:

1. Claude self-audit: implementer-owned and provisional. Claude may report `SELF_PASS`, `SELF_FAIL`, `NOT_RUN`, `BLOCKED`, or `OWNER_REQUIRED`, but never `AUDITED_PASS`.
2. ChatGPT independent audit: reviews the prompt, actual repository state, implementation log, Claude self-audit, test design, prior audit learnings, and reproducible evidence. Only this step may assign `AUDITED_PASS` or `AUDITED_FAIL`.

Canonical audit sources:

- Policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- Learning index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- Claude self-audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md
- ChatGPT audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_AUDIT_TEMPLATE.md

Claude must read the audit index before each material implementation/self-audit pass and state which `AL-XXX` learnings changed its test plan. ChatGPT updates the audit index after independent audits when a reusable testing lesson is discovered.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M07-C001` | M07 | PLANNED | CHATGPT | V02 issued with GitHub URL references and dual-audit/self-audit requirements. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md |
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
- active prompt/audit/self-audit URLs;
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
| M07 | Visual Reference Library | NOT_STARTED / M07-C001 V02 issued |
| M08-M55 | Remaining milestones | NOT_STARTED |

## Quality baseline

- Last independently established code-milestone evidence before this audit-policy revision: Phase M06, 227/227 checks PASS at `abd9ceb`.
- Claude must rerun required tests in M07-C001, but its own results are classified as provisional self-evidence until ChatGPT audit.
- A successful aggregate count does not override requirement-specific failures, missing negative tests, false-positive risk, or owner-controlled gates.

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude self-tests are provisional evidence.
- Only ChatGPT independent audit may assign `AUDITED_PASS`/`AUDITED_FAIL`.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Never rewrite historical prompt/audit versions to improve appearances retroactively.
- Never publish secrets or sensitive environment values.
