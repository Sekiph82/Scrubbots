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
| Active cycle | M13-C001 |
| Active version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Branch | main |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md |
| Purpose | M13-C001 V01: Eligible Target Index implemented (color-grouped DIRTY-cell query/cache over BoardState). SB-M13-001..010 closed. 729/729 ALL PASS (72 new M13 checks). Canonical main 206/943 = 21.85%. No TargetSelector/RoutingSystem/reservation ownership. |

### Also active (on main)

| Field | Value |
| --- | --- |
| Active cycle | META-C003 |
| Active version | V01 |
| State | AUDITED_PASS |
| Next actor | COMPLETE |

### Current progress from tasks.md (main, after M13-C001)

- Ecosystem: **206 / 943 = 21.85%**
- Main game + SB-UI (M00-M55): **206 / 719 = 28.65%**
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
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V01.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md |
| Scope | Eligible DIRTY target index/cache only; no TargetSelector or M14 reservation ownership |
| Result | SB-M13-001..010 closed. 729/729 ALL PASS (72 new M13 checks). 206/943 = 21.85%. |

## M13-C001 independent audit V01

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V01.md
- Accepted complete: **SB-M13-001, 002, 004, 005**
- Open V02: **SB-M13-003, 006, 007, 008, 009, 010**
- F-M13-001: strengthen no-rescan spy to observe all relevant BoardState traversal APIs.
- F-M13-002: 006..010 were early due to ChatGPT V01 scope error; preserve provisional work, formally validate in V02.
- F-M13-003: preserve pre-existing tracked owner/local changes; never git-restore them just to clean the tree.
- Current canonical progress: **200 / 943 = 21.21%**
- Active V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V02.md
- Expected log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V02.md

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
| Health | OK — M13-C001 implemented, AWAITING_AUDIT |
| Current implementation frontier | M13-C001 - Eligible Target Index |
| Current task | M13-C001 V01 eligible target index implementation |
| Current task ID | `M13-C001` |
| Current workflow state | `AWAITING_AUDIT` — Eligible Target Index implemented. 729/729 ALL PASS (72 new M13 checks incl. 59x59/3,481-cell correctness + spy-verified no-per-query-rescan + CPU/index benchmark). SB-M13-001..010 closed. 206/943 canonical main truth. |
| Required actor | CHATGPT |
| Next project action | ChatGPT performs independent audit M13-C001 V01. |
| Waiting on | Scrubby master reference: OWNER_REQUIRED. M08 production-art audit and M10 DIRTY/CLEAN preset remain owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `M13-C001` |
| Session type | M13-C001 V01 Eligible Target Index implementation |
| Cycle status | `AWAITING_AUDIT` |
| Summary | Implemented `scripts/gameplay/routing/eligible_target_index.gd` — color-grouped DIRTY-cell query/cache over one BoardState. Eligibility = valid+DIRTY+color+not-caller-excluded. Reservation seam is per-query caller-supplied exclusion only; no RESERVED state, no reservation ownership (M14/M02-017 stay open). No TargetSelector/RoutingSystem/dispatch/agent. 72 new M13 checks; full suite 729/729 ALL PASS (baseline 657/657). Benchmark: indexed query ~0.0005 ms vs naive full-scan ~4.7 ms (CPU/index only). SB-M13-001..010 closed. 206/943 = 21.85%. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V01.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V01.md |
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
| M13 | Eligible Target Index | AWAITING_AUDIT - 10/10 tasks, 729/729 ALL PASS |
| M14-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

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
| Task ledger | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| Agent governance | https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md |
| Coordination protocol | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md |
| Session index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md |
| Audit policy | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |

## Parallel sidecar projects

| Project | Root | Status | Canonical tasks | Coordination |
| --- | --- | --- | --- | --- |
| SCRUBBOTS Level Factory | `level_factory/` | PLANNED / architecture registered | `SB-LF00-001..` in root `tasks.md` | `level_factory/coordination/SESSION_INDEX.md` |
| SCRUBBOTS Content Pipeline | `content_pipeline/` | PLANNED / architecture registered | `SB-CP00-001..` in root `tasks.md` | `content_pipeline/coordination/SESSION_INDEX.md` |
