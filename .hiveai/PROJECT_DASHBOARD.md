# SCRUBBOTS - H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
coordinationSchema: scrubbots-coordination/v3
-->

This file is the single H!veAI-facing materialized project status surface. It is not a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

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
| Current task | M07-C001 - V04 corrections applied, awaiting audit V02 |
| Current task ID | `M07-C001` |
| Current workflow state | `AWAITING_AUDIT` - V04 corrections complete; awaiting ChatGPT audit V02 |
| Required actor | CHATGPT |
| Next project action | ChatGPT reads corrected inventory.json and updated implementation log (Session 2), performs independent audit V02. |
| Waiting on | Owner-approved artwork remains required for SB-M07-008..014; M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T17:00:00+03:00 |
| Actor | CLAUDE |
| Cycle | `M07-C001` |
| Session type | V04 correction pass |
| Cycle status | `AWAITING_AUDIT` |
| Milestone/task impact | No task checkbox changes. F-M07-001 fixed (Akilta `originalFilename` → `null`). F-M07-002 fixed (full 7-command validation sequence individually logged). |
| Summary | Applied V04 corrections for audit V01 findings. Set unsupported `akilta_wordmark.originalFilename` to `null` per AL-008. Ran and individually logged all 7 prompt-mandated validation commands per AL-009, including previously omitted headless startup smoke and final `git status --short`. 227/227 regression PASS. 13/13 inventory checks PASS. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CHATGPT |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07-C001 | Visual Reference Library foundation + audit corrections | `AWAITING_AUDIT` | CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure implemented; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Audit model

The corrected audit model is deliberately asymmetric:

1. **ChatGPT publishes implementation prompts** and may publish audit criteria in advance.
2. **Claude implements and tests**. Claude records commands, expected outcomes, failure conditions, actual results, failures/fixes, prior-audit comparisons, and commit/push evidence only in `CLAUDE_IMPLEMENTATION_LOG.md`.
3. **Claude does not self-audit** and does not create audit verdicts/files.
4. **ChatGPT independently audits** actual GitHub state after Claude hands the cycle back.
5. Only ChatGPT may publish `CHATGPT_AUDIT_VNN.md` and assign `AUDITED_PASS` / `AUDITED_FAIL`.
6. If an audit finds issues, ChatGPT publishes the next prompt version in the same cycle.
7. Claude reads prior ChatGPT audits plus `AUDIT_INDEX.md` and uses those findings to strengthen its next implementation/test pass.

Historical `CLAUDE_SELF_AUDIT_*` artifacts created under the superseded workflow remain historical only and are not independent audit evidence. No new Claude self-audit files are allowed.

Canonical audit sources:

- Policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- Learning index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- ChatGPT prompt template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_PROMPT_TEMPLATE.md
- Claude implementation-log template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md
- ChatGPT audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_AUDIT_TEMPLATE.md

## Current M07 audit findings

| Finding | Severity | Required correction |
| --- | --- | --- |
| `F-M07-001` | MEDIUM | Set unsupported `akilta_wordmark.originalFilename` metadata to `null` unless evidence proves it. |
| `F-M07-002` | MEDIUM | Run and individually log the complete prompt-mandated validation sequence, including headless startup smoke and final `git status --short`. |

Reusable learnings added by ChatGPT audit V01:

- `AL-008` metadata provenance: unknown metadata stays null/unverified without owner/repository evidence.
- `AL-009` validation traceability: every required command is logged individually; aggregate green counts do not substitute for omitted checks.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M07-C001` | M07 | `AWAITING_AUDIT` | CLAUDE | V04 corrections applied (F-M07-001 + F-M07-002). Full validation logged. Awaiting ChatGPT audit V02. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| `META-C001` | META | `AUDITED_PASS` | CHATGPT | Established repository-native ChatGPT/Claude coordination and H!veAI synchronization. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md |

## Coordination source map

H!veAI actively watches only this dashboard. ChatGPT/Claude materialize relevant GitHub source state into it after every material session.

| Purpose | Canonical GitHub source |
| --- | --- |
| Task ledger | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| Agent governance | https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md |
| Coordination protocol | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md |
| Session index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| ChatGPT prompt template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_PROMPT_TEMPLATE.md |
| Claude implementation-log template | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md |
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
- active prompt/audit/log URLs;
- concise work summary;
- blocker/waiting state;
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
| M07 | Visual Reference Library | PARTIAL - infrastructure implemented, asset tasks awaiting owner |
| M08-M55 | Remaining milestones | NOT_STARTED |

## Quality baseline

- Last established gameplay code milestone before M07: Phase M06, 227/227 checks PASS at `abd9ceb`.
- Claude reported 227/227 during the initial M07 implementation pass, but ChatGPT did not independently rerun Godot in audit V01 and therefore did not treat that number as independent proof.
- V04 requires the full validation sequence to be rerun and individually logged before audit V02.

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
