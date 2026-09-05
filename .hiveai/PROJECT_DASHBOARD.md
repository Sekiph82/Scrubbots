# SCRUBBOTS - H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
coordinationSchema: scrubbots-coordination/v4
-->

This file is the single H!veAI-facing materialized project status surface. It is not a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

## Coordination v4 active status

| Field | Value |
| --- | --- |
| Active cycle | META-C002 |
| Active version | V02 |
| State | CHANGES_REQUIRED |
| Next actor | CLAUDE |
| Branch | feature/master-ui-magnific-pipeline (PR #3) |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V02.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V02.md |
| Purpose | META-C002 V02: Correction cycle — machine-readable inventory, per-file hashes/dimensions/classification, canonical ref records, manifest truth, task truth, progress recount from 943-task branch truth. |

### Also active (on main)

| Field | Value |
| --- | --- |
| Active cycle | M12-C001 |
| Active version | V02 |
| State | AUDITED_PASS |
| Next actor | COMPLETE |

### Current progress from tasks.md (feature/master-ui-magnific-pipeline branch)

Progress will be recalculated from canonical SB task IDs during V02 correction.

Tracking sources:

- https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/.hiveai/ACTIVE_CYCLES.md
- https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/.hiveai/ARTIFACT_MAP.md
- https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/.hiveai/PROGRESS_SNAPSHOT.md

## M12-C001 final independent audit V02

- Status: **AUDITED_PASS**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V02.md
- M12: **11 / 11 complete**
- F-M12-001: **CLOSED**
- Main progress before PR #3 merge: **185 / 848 = 21.82%**
- Next action: finish PR #3 META-C002 audit/correction before M13.

## Project identity

| Field | Value |
| --- | --- |
| Project | SCRUBBOTS |
| Repository | https://github.com/Sekiph82/Scrubbots |
| Branch | `feature/master-ui-magnific-pipeline` (PR #3) |
| Engine | Godot 4.7.1-stable (GDScript) |
| Platform target | Mobile (Android first, iOS later) |
| Attribution | Developed by Akilta |

## H!veAI live status

| Field | Value |
| --- | --- |
| Project status | ACTIVE |
| Health | OK — META-C002 V02 correction in progress |
| Current implementation frontier | META-C002 - Master UI + Magnific pipeline integration |
| Current task | META-C002 V02 correction |
| Current task ID | `META-C002` |
| Current workflow state | `CHANGES_REQUIRED` — V02 corrects F-META-001..004 from audit V01 |
| Required actor | CLAUDE |
| Next project action | Claude implements V02 corrections, then AWAITING_AUDIT for ChatGPT. |
| Waiting on | Scrubby master reference: OWNER_REQUIRED. M08 production-art audit and M10 DIRTY/CLEAN preset remain owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `META-C002` |
| Session type | META-C002 V02 correction (merge main + implement audit findings) |
| Cycle status | `CHANGES_REQUIRED` |
| Summary | Merged origin/main (M12-C001 AUDITED_PASS). Starting V02 corrections per CHATGPT_PROMPT_V02.md. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V02.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_CRITERIA_V02.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V02.md |
| Next expected actor | CLAUDE (implementing V02 corrections) |

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00-M04 | Foundation through expanded board fixtures | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | PARTIAL - owner assets still missing |
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | COMPLETE |
| M10 | Dirty/Clean Visual Model | OWNER_REQUIRED / PARTIAL infrastructure |
| M11 | Gameplay Session Core | AUDITED_PASS - 12/12 tasks, 548/548 ALL PASS |
| M12 | Five-Slot Logic | AUDITED_PASS - 11/11 tasks, 657/657 ALL PASS |
| M13-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.

## Audit model

1. ChatGPT publishes implementation prompts and audit criteria.
2. Claude implements/tests/logs only in version-matched `CLAUDE_LOG_VNN.md`.
3. Claude does not create audit/self-audit files or assign audit verdicts.
4. ChatGPT independently audits GitHub state after handoff.
5. Only ChatGPT publishes `CHATGPT_AUDIT_VNN.md` and assigns `AUDITED_PASS` / `AUDITED_FAIL`.
6. Corrections stay in the same cycle using a new prompt version.
7. Claude reads prior ChatGPT audits plus `AUDIT_INDEX.md` and applies those findings to implementation/testing.

## Coordination source map

| Purpose | Canonical GitHub source |
| --- | --- |
| Task ledger | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/tasks.md |
| Agent governance | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/CLAUDE.md |
| Coordination protocol | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md |
| Session index | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/SESSION_INDEX.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |

## Parallel sidecar projects

| Project | Root | Status | Canonical tasks | Coordination |
| --- | --- | --- | --- | --- |
| SCRUBBOTS Level Factory | `level_factory/` | PLANNED / architecture registered | `SB-LF00-001..` in root `tasks.md` | `level_factory/coordination/SESSION_INDEX.md` |
| SCRUBBOTS Content Pipeline | `content_pipeline/` | PLANNED / architecture registered | `SB-CP00-001..` in root `tasks.md` | `content_pipeline/coordination/SESSION_INDEX.md` |
