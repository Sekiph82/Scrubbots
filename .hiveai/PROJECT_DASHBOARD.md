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
| Active cycle | META-C003 |
| Active version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Branch | main (PR #3 merged) |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_PROMPT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CLAUDE_LOG_V01.md |
| Purpose | META-C003 V01: PR #3 merged into main via normal merge commit. Pre- and post-merge 657/657 ALL PASS. Canonical main truth 196/943 = 20.78%. Post-merge receipt posted. |

### Also active (on main)

| Field | Value |
| --- | --- |
| Active cycle | M12-C001 |
| Active version | V02 |
| State | AUDITED_PASS |
| Next actor | COMPLETE |

### Current progress from tasks.md (main, after PR #3 merge)

- Ecosystem: **196 / 943 = 20.78%**
- Main game + SB-UI (M00-M55): **196 / 719 = 27.26%**
- Level Factory: **0 / 112 = 0.00%**
- Content Pipeline: **0 / 112 = 0.00%**

Counts derived from unique canonical SB task IDs on checkbox lines.

Tracking sources:

- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ACTIVE_CYCLES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ARTIFACT_MAP.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROGRESS_SNAPSHOT.md

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

## META-C003 merge cycle

| Field | Value |
| --- | --- |
| Cycle | META-C003 |
| Version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Merge commit | `bb5de4b88fcaef7a72109ff3cdeb2d6c77588106` |
| Merged PR | PR #3 (MERGED) |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_PROMPT_V01.md |
| Criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CLAUDE_LOG_V01.md |
| Gate | META-C002 V05 AUDITED_PASS |
| Purpose | Controlled merge commit + canonical main reconciliation. 657/657 ALL PASS. No M13. |

## META-C002 final independent audit V05

- Status: **AUDITED_PASS**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V05.md
- PR #3 feature truth accepted: **196 / 943 = 20.78%**
- 95-task migration and 51-reference inventory accepted.
- Scrubby master remains **OWNER_REQUIRED**.
- Next: META-C003 controlled merge/reconciliation.
- M13 remains **NOT_STARTED**.

## META-C003 final independent audit V01

- Status: **AUDITED_PASS**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_V01.md
- PR #3: **MERGED**
- Canonical main progress: **196 / 943 = 20.78%**
- Visual inventory: **51 / 51**
- Scrubby master: **OWNER_REQUIRED**
- Next main-game milestone: **M13 Eligible Target Index**
- M13 is not started yet.

## Active main-game cycle

| Field | Value |
| --- | --- |
| Cycle | M13-C001 |
| Milestone | M13 - Eligible Target Index |
| Version | V01 |
| State | PLANNED |
| Next actor | CLAUDE |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V01.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Expected Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md |
| Scope | Eligible DIRTY target index/cache only; no TargetSelector or M14 reservation ownership |
| First action | Safely sync local main with origin/main while preserving owner work |

## Project identity

| Field | Value |
| --- | --- |
| Project | SCRUBBOTS |
| Repository | https://github.com/Sekiph82/Scrubbots |
| Branch | `main` (PR #3 merged) |
| Engine | Godot 4.7.1-stable (GDScript) |
| Platform target | Mobile (Android first, iOS later) |
| Attribution | Developed by Akilta |

## H!veAI live status

| Field | Value |
| --- | --- |
| Project status | ACTIVE |
| Health | OK — PR #3 merged into main, META-C003 AWAITING_AUDIT |
| Current implementation frontier | META-C003 - PR #3 merge & canonical main reconciliation |
| Current task | META-C003 V01 post-merge reconciliation |
| Current task ID | `META-C003` |
| Current workflow state | `AWAITING_AUDIT` — PR #3 merged via normal merge commit. 657/657 ALL PASS pre- and post-merge. 196/943 canonical main truth. Post-merge receipt posted. |
| Required actor | CHATGPT |
| Next project action | ChatGPT performs independent audit META-C003 V01. |
| Waiting on | Scrubby master reference: OWNER_REQUIRED. M08 production-art audit and M10 DIRTY/CLEAN preset remain owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `META-C003` |
| Session type | META-C003 V01 PR #3 merge & canonical main reconciliation |
| Cycle status | `AWAITING_AUDIT` |
| Summary | PR #3 merged into main via normal merge commit `bb5de4b88fcaef7a72109ff3cdeb2d6c77588106`. Pre-merge 657/657 ALL PASS on feature. Post-merge 657/657 ALL PASS on main. 943/196/747 canonical task truth. 95 UI migration IDs, 51 references, Scrubby OWNER_REQUIRED. No M13/LF00/CP00/Magnific generation. Feature branch preserved. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_PROMPT_V01.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_CRITERIA_V01.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C002/CHATGPT_AUDIT_V05.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CLAUDE_LOG_V01.md |
| Next expected actor | CHATGPT (audit META-C003 V01) |

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
