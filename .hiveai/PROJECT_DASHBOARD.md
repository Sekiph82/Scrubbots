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
| Current implementation frontier | M09 - Pixel Art to Level Data Pipeline |
| Current task | M09-C001 - deterministic exact-pixel PNG importer core |
| Current task ID | `M09-C001` |
| Current workflow state | `AWAITING_AUDIT` - Claude implemented/tested/logged SB-M09-001..017; ChatGPT audit is next |
| Required actor | CHATGPT |
| Next project action | ChatGPT independently audits M09-C001 implementation against prompt V01 and audit criteria V01, inspecting repository state, test evidence (286/286), implementation log, and code changes. |
| Waiting on | M08 production-art audit and remaining M07 asset inventory tasks still require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27 |
| Actor | CLAUDE |
| Cycle | `M09-C001` |
| Session type | Implementation + testing + logging |
| Cycle status | `AWAITING_AUDIT` |
| Milestone/task impact | SB-M09-001..017 marked complete with validation evidence. SB-M09-018..020 remain open (deferred to M09-C002). M08 still open (no production artwork). 286/286 checks pass (was 227). |
| Summary | Built deterministic exact-pixel PNG → Level Data V1 importer core. Reusable importer (`scripts/tools/level_importer.gd`) + CLI entrypoint (`tools/import_level.gd`). 59 new automated checks. Pixel-perfect RGBA8 reconstruction verified at 3×2, 20×27, 59×59. Deterministic rerun produces UNCHANGED. 11 negative/error tests. All 7 applicable audit learnings (AL-001..009) explicitly applied and logged. No fabricated artwork. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Prior independent audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md |
| Next expected actor | CHATGPT |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C001 | Exact-pixel importer core | `AWAITING_AUDIT` | CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| M08 | Level Art Technical Audit | `BLOCKED_ON_OWNER_ASSET` | HUMAN supplies production art; Claude audits after scoped prompt | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## M09-C001 scope contract

- Source inputs in this cycle are deterministic TEST-generated PNG fixtures only.
- One source RGBA pixel equals one logical cell.
- No resize, resample, interpolation, crop, pad, square coercion, palette reduction, or source overwrite.
- Palette order is deterministic first-seen row-major order.
- Cells use canonical `index = y * width + x`.
- Output is existing Level Data V1, not a new schema.
- Reconstruction must match raw RGBA8 source bytes exactly.
- TEST vs production difficulty remains explicit and uses existing validators/rules.
- Batch import/validation and catalog-wide duplicate-ID protection are deferred to M09-C002.
- M08 remains open; no real-art audit/import claim is allowed.

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md

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

## Active audit learnings relevant to M09-C001

- `AL-001`: preserve headless-safe explicit preload discipline where relevant.
- `AL-003`: headless CPU timing is not GPU/FPS evidence.
- `AL-004`: rectangular and maximum-size checks catch hidden fixed-size assumptions.
- `AL-005`: file existence is not task completion evidence.
- `AL-006`: missing owner art cannot be fabricated.
- `AL-008`: unknown metadata stays null/unverified without evidence.
- `AL-009`: every required validation command/check is individually traceable in Claude's implementation log.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M09-C001` | M09 | `AWAITING_AUDIT` | CLAUDE | Importer core implemented. 286/286 tests, pixel-perfect reconstruction, deterministic rerun, 11 negative tests. SB-M09-001..017 complete. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md |
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
| Level Data V1 | https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md |
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
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS via M09-C001 tooling cycle |
| M10-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Quality baseline

- Last established gameplay code milestone before M09: Phase M06, 227/227 checks PASS at `abd9ceb`.
- M07-C001 is `AUDITED_PASS`; its final correction did not modify gameplay/test code.
- M09-C001 implementation: 286/286 checks PASS (59 new importer checks). Full 15-step validation sequence recorded in implementation log. ChatGPT audit is next.

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
