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
| Current task | M07-C001 closed; owner visual assets required for remaining M07 asset tasks |
| Current task ID | NONE |
| Current workflow state | `AUDITED_PASS` - M07-C001 coordination cycle closed by ChatGPT audit V02 |
| Required actor | HUMAN |
| Next project action | Owner supplies original/approved SCRUBBOTS visual assets for SB-M07-008..014. A new scoped ChatGPT prompt/cycle should be issued before further Claude implementation. |
| Waiting on | Owner-approved artwork remains required for SB-M07-008..014; M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T16:40:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M07-C001` |
| Session type | Independent audit V02 |
| Cycle status | `AUDITED_PASS` |
| Milestone/task impact | No task checkbox changes. SB-M07-001..007 and 015..017 remain complete; SB-M07-008..014 remain open `AWAITING OWNER ASSET`. M07 remains PARTIAL. |
| Summary | Independently reviewed the V04 correction diff, corrected inventory metadata, Claude Session 2 implementation log, Session Index, and coordination scope. F-M07-001 and F-M07-002 are closed. Correction diff touched only inventory metadata plus coordination/log files. Godot runtime results remain Claude-run evidence, but no gameplay/test code changed in the correction. Cycle M07-C001 is AUDITED_PASS. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V04.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | HUMAN |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M07-C001 | Visual Reference Library foundation + audit corrections | `AUDITED_PASS` | COMPLETE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
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

## M07 audit closure

| Finding | Audit V01 | Audit V02 |
| --- | --- | --- |
| `F-M07-001` unsupported Akilta `originalFilename` | `CHANGES_REQUIRED` | `AUDITED_PASS` - corrected to `null` |
| `F-M07-002` missing validation traceability | `CHANGES_REQUIRED` | `AUDITED_PASS` - full V04 sequence individually logged |

Reusable learnings remain active:

- `AL-008` metadata provenance: unknown metadata stays null/unverified without owner/repository evidence.
- `AL-009` validation traceability: every required command is logged individually; aggregate green counts do not substitute for omitted checks.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M07-C001` | M07 | `AUDITED_PASS` | CHATGPT | Audit V02 closed both V01 findings. M07 infrastructure cycle complete; owner asset tasks remain open. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md |
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
| M07 | Visual Reference Library | PARTIAL - infrastructure audited, asset tasks awaiting owner |
| M08-M55 | Remaining milestones | NOT_STARTED |

## Quality baseline

- Last established gameplay code milestone before M07: Phase M06, 227/227 checks PASS at `abd9ceb`.
- Claude reported 227/227 during the M07 V04 correction pass. ChatGPT did not independently execute the local Godot binary and therefore records that runtime result as Claude-run evidence, not independent execution proof.
- ChatGPT independently verified that the V04 correction diff does not modify gameplay or test code and that the two audit findings concern metadata and validation traceability only.

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
