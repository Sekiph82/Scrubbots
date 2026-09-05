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
| Active cycle | META-C004 |
| Active version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Branch | main |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_PROMPT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CLAUDE_LOG_V01.md |
| Purpose | META-C004: gameplay-rule migration DIRTY/CLEAN → ACTIVE/CLEARED (ADR-019). BoardState ACTIVE/CLEARED; renderer ACTIVE=source-color-opaque / CLEARED=alpha-0-transparent; removed `dirty_clean_presets.gd`; M13 index renamed to `ColorCandidateIndex` under `scripts/gameplay/targeting/`; docs/tasks/LF migrated; CP inspected (no edit). 774/774 ALL PASS. SB-M10-001 closed. 207/943 = 21.95%. |

### Also active (on main)

| Field | Value |
| --- | --- |
| Active cycle | META-C003 |
| Active version | V01 |
| State | AUDITED_PASS |
| Next actor | COMPLETE |

### Current progress from tasks.md (main, after META-C004)

- Ecosystem: **207 / 943 = 21.95%**
- Main game + SB-UI (M00-M55): **207 / 719 = 28.79%**
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
| Version | V02 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V02.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_CRITERIA_V02.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V02.md |
| Scope | Eligible DIRTY target index/cache only; no TargetSelector or M14 reservation ownership |
| Result | V02: F-M13-001 fixed (all-traversal-API zero-delta proof) + 006..010 formally validated. SB-M13-001..010 closed. 773/773 ALL PASS. 206/943 = 21.85%. |

## M13-C001 independent audit V01

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V01.md
- Accepted complete: **SB-M13-001, 002, 004, 005**
- Open V02: **SB-M13-003, 006, 007, 008, 009, 010**
- F-M13-001: strengthen no-rescan spy to observe all relevant BoardState traversal APIs.
- F-M13-002: 006..010 were early due to ChatGPT V01 scope error; preserve provisional work, formally validate in V02.
- F-M13-003: preserve pre-existing tracked owner/local changes; never git-restore them just to clean the tree.
- Canonical progress at audit V01 (six tasks reopened): **200 / 943 = 21.21%**
- Active V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_PROMPT_V02.md
- Expected log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CLAUDE_LOG_V02.md

## M13-C001 V02 implementation (AWAITING_AUDIT)

- F-M13-001 fixed: scan spy now counts all four BoardState traversal APIs (`get_cell_count`, `is_valid_index`, `get_color_id`, `get_cell_state`); steady-state `get_eligible`/`has_work`/`count_eligible` add zero traversal reads; sensitivity check proves a full-board color loop moves the counter.
- F-M13-003/AL-026 honored: no pre-existing tracked owner change existed; nothing restored/reset/overwritten/staged.
- SB-M13-006..010 formally validated (exclusion robustness, no-work matrix, incremental + rebuild exhaustion, last-target lifecycle, 3,481-cell exclusion non-mutation).
- Production `eligible_target_index.gd` unchanged; accepted V01 code reused.
- 44 new V02 checks; full suite **773 / 773 ALL PASS**. SB-M13-001..010 closed.
- Canonical progress restored: **206 / 943 = 21.85%**. Next actor CHATGPT.

## M13-C001 final independent audit V02

- Status: **AUDITED_PASS**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V02.md
- M13: **10 / 10 complete**
- Canonical progress: **206 / 943 = 21.85%**
- Main game + UI: **206 / 719 = 28.65%**
- M14: **NOT_STARTED**
- Owner requested manual-play/manual-QA before the next implementation cycle.

## Active owner-locked gameplay rule migration

| Field | Value |
| --- | --- |
| Cycle | META-C004 |
| Version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Branch | main |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_PROMPT_V01.md |
| Criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CLAUDE_LOG_V01.md |
| Baseline | M13-C001 AUDITED_PASS, 206/943 |
| Owner rule | ACTIVE source-color pixels -> CLEARED transparent holes; background visible |
| Reachability | matching color is not sufficient; blocked ACTIVE cells are not targetable |
| Result | Migrated code/docs/tasks/LF; removed `dirty_clean_presets.gd`; renamed M13 index to `ColorCandidateIndex` (`scripts/gameplay/targeting/`). 774/774 ALL PASS. SB-M10-001 closed → 207/943. M10-005..011, M02-017, M14/M15/M16/M17 remain open. |
| Gate | M14 remains NOT_STARTED until META-C004 audit and new manual QA |

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
| Health | OK — META-C004 implemented, AWAITING_AUDIT |
| Current implementation frontier | META-C004 - ACTIVE/CLEARED gameplay-rule migration |
| Current task | META-C004 DIRTY/CLEAN → ACTIVE/CLEARED migration |
| Current task ID | `META-C004` |
| Current workflow state | `AWAITING_AUDIT` — BoardState ACTIVE/CLEARED; renderer ACTIVE=source-opaque / CLEARED=alpha-0; `dirty_clean_presets.gd` removed; M13 index → `ColorCandidateIndex` (`scripts/gameplay/targeting/`); docs/tasks/LF migrated; CP inspected (no edit); ADR-019 appended; CHANGELOG appended. 774/774 ALL PASS. SB-M10-001 closed → 207/943 canonical main truth. |
| Required actor | CHATGPT |
| Next project action | ChatGPT performs independent audit META-C004 V01. |
| Waiting on | Scrubby master reference: OWNER_REQUIRED. M10-005..011 owner manual QA of the NEW transparent model. M02-017/M14/M15/M16/M17 implementation gates open. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `META-C004` |
| Session type | Gameplay-rule migration DIRTY/CLEAN → ACTIVE/CLEARED |
| Cycle status | `AWAITING_AUDIT` |
| Summary | Migrated the whole current canonical surface from the DIRTY/CLEAN grime/reveal prototype to the owner-locked ACTIVE/CLEARED model (ADR-019). BoardState `CellState` = ACTIVE(0)/CLEARED(1), fresh/reset all-ACTIVE. BoardRenderer draws ACTIVE=exact source palette color/opaque, CLEARED=`Color(0,0,0,0)` transparent (background shows through) — proven by pixel-alpha readback. Removed `scripts/gameplay/board/dirty_clean_presets.gd` (no alias). Moved `eligible_target_index.gd`→`scripts/gameplay/targeting/color_candidate_index.gd` (`ColorCandidateIndex`, candidate API; raw color candidates only, no reachability — AL-028). Debug tool migrated to ACTIVE/CLEARED patterns + visible background; A/B/C dropdown removed. Migrated README, CLAUDE.md, docs/00–06 (ADR-019 appended, ADR-011 unchanged), tasks.md (M02/M10/M11/M13/M15/M16/M17/M18–M20/M21/M40/M41/M49), Level Factory solver/architecture docs; Content Pipeline inspected — declarative-only, no edit. CHANGELOG append-only migration entry. AL-026 honored: pre-existing tracked owner change `project.godot` preserved, never staged/restored. Full suite 774/774 ALL PASS. SB-M10-001 closed (owner-approved ACTIVE appearance); no task IDs added; recomputed 207/943 = 21.95%. M10-005..011 owner manual-QA gates and M02-017/M14/M15/M16/M17 implementation gates remain open. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_PROMPT_V01.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_CRITERIA_V01.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V02.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CLAUDE_LOG_V01.md |
| Next expected actor | CHATGPT (audit META-C004 V01) |

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00-M04 | Foundation through expanded board fixtures | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | PARTIAL - owner assets still missing |
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | COMPLETE |
| M10 | ACTIVE/CLEARED Board Visual Model | OWNER_DECISION_LOCKED (ADR-019); SB-M10-001..004,012 done; SB-M10-005..011 owner MANUAL_QA_OPEN |
| M11 | Gameplay Session Core | AUDITED_PASS - 12/12 tasks; re-verified under ACTIVE/CLEARED in META-C004 |
| M12 | Five-Slot Logic | AUDITED_PASS - 11/11 tasks, 657/657 ALL PASS |
| M13 | Color Candidate Index | AUDITED_PASS - 10/10 tasks; renamed `ColorCandidateIndex` (targeting/) in META-C004 |
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
