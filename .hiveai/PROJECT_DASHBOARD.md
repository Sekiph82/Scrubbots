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
| Active version | V05 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Branch | feature/master-ui-magnific-pipeline (PR #3) |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V05.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V05.md |
| Purpose | META-C002 V05: Applied AL-025 — pre-commit evidence in Git-tracked log, post-push receipt in PR #3 comment. Evidence/coordination only — all prior accepted baseline preserved. 196/943 = 20.78%. |

### Also active (on main)

| Field | Value |
| --- | --- |
| Active cycle | M12-C001 |
| Active version | V02 |
| State | AUDITED_PASS |
| Next actor | COMPLETE |

### Current progress from tasks.md (feature/master-ui-magnific-pipeline branch)

- Ecosystem: **196 / 943 = 20.78%**
- Main game + SB-UI (M00-M55): **196 / 719 = 27.26%**
- Level Factory: **0 / 112 = 0.00%**
- Content Pipeline: **0 / 112 = 0.00%**

Counts derived from unique canonical SB task IDs on checkbox lines.

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

## META-C002 independent audit V02

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V02.md
- F-META-001..004: **CLOSED**
- Remaining F-META-005: V02 log omits individually required validation items 29–41.
- Remaining F-META-006: PR #3 body is materially stale despite the corrected V02 comment.
- Active V03: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V03.md
- Expected log: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V03.md
- Progress remains **196 / 943 = 20.78%**.
- PR #3 remains draft/unmerged.
- No broad/final Magnific generation.

## META-C002 independent audit V03

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V03.md
- PR-body truth: **PASS**
- V03 scope/diff: **PASS**
- Remaining: exact full commit SHA / remote-head provenance and exact repo-local untracked working-tree evidence in matching Claude log.
- Active V04: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V04.md
- Expected log: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V04.md
- Progress unchanged: **196 / 943 = 20.78%**.
- PR #3 remains draft/unmerged.

## META-C002 independent audit V04

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V04.md
- V04 implementation/task/inventory/UI baseline: **PASS**
- Remaining issue: self-referential final-SHA logging rule is impossible by construction.
- New rule AL-025: final post-push SHA/status goes in a non-Git-mutating PR receipt.
- Active V05: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V05.md
- Expected log: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V05.md
- Progress unchanged: **196 / 943 = 20.78%**.
- PR #3 remains draft/unmerged.

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
| Health | OK — META-C002 V05 AL-025 post-push receipt evidence complete, AWAITING_AUDIT |
| Current implementation frontier | META-C002 - Master UI + Magnific pipeline integration |
| Current task | META-C002 V05 non-self-referential merge evidence |
| Current task ID | `META-C002` |
| Current workflow state | `AWAITING_AUDIT` — V05 applied AL-025 (pre-commit evidence in log, post-push receipt in PR comment). All prior accepted baseline preserved. |
| Required actor | CHATGPT |
| Next project action | ChatGPT performs independent audit V05. |
| Waiting on | Scrubby master reference: OWNER_REQUIRED. M08 production-art audit and M10 DIRTY/CLEAN preset remain owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `META-C002` |
| Session type | META-C002 V05 non-self-referential merge evidence (AL-025) |
| Cycle status | `AWAITING_AUDIT` |
| Summary | Applied AL-025: pre-commit evidence (branch SHAs, git status, task counts, PR state, untracked classification) recorded in Git-tracked CLAUDE_LOG_V05.md. Post-push receipt (final commit SHA, remote head equality proof) posted as PR #3 comment. One focused commit, no self-referential SHA loop. No implementation/task/inventory changes. 196/943. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_PROMPT_V05.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_CRITERIA_V05.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V04.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V05.md |
| Next expected actor | CHATGPT (audit V05) |

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
