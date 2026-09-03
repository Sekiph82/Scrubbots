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
| Health | HEALTHY - M09-C002 V02 correction complete, awaiting audit V02 |
| Current implementation frontier | M09 - Pixel Art to Level Data Pipeline |
| Current task | M09-C002 - Batch Import / Validation / Duplicate-ID Protection correction V02 complete |
| Current task ID | `M09-C002` |
| Current workflow state | `AWAITING_AUDIT` - Claude closed all five audit V01 findings (F-M09B-001..005), 426/426 tests pass |
| Required actor | CHATGPT |
| Next project action | ChatGPT independent audit V02 against criteria V02. If AUDITED_PASS, M09 milestone is complete pending M08/M10 owner-asset gates. |
| Waiting on | M08 production-art audit and remaining M07 visual inventory tasks require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-03T13:00:00+03:00 |
| Actor | CLAUDE |
| Cycle | `M09-C002` |
| Session type | V02 correction implementation (Session 2) |
| Cycle status | `AWAITING_AUDIT` |
| Summary | Closed all five audit V01 findings: F-M09B-001 destination-parent preflight (missing/non-directory parents now block the whole batch before commit), F-M09B-002 catalog-root fail-closed, F-M09B-003 bidirectional catalog ID/path ownership (overwrite=true can no longer let a different ID steal an existing catalog path, and aliasing a malformed catalog entry fails closed), F-M09B-004 catalog malformed/duplicate state now invalidates overall validation instead of being merely informational, F-M09B-005 optional manifest field types (`preview`/`metadata`/`overwrite`) explicitly validated before typed use. Applied AL-014..016. Added 32 new tests (426 total). Real CLI verification for every negative case, including MD5 byte-preservation proof for the catalog-takeover rejection. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V02.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V02.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CHATGPT |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C002 | Batch import / validation / duplicate-ID tooling | `AWAITING_AUDIT` | CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md |
| M09-C001 | Exact-pixel single importer + safety hardening | `AUDITED_PASS` | COMPLETE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md |
| M08 | Level Art Technical Audit | `BLOCKED_ON_OWNER_ASSET` | HUMAN supplies production art | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## M09-C002 independent audit V01

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md

Decision: `CHANGES_REQUIRED`.

| Finding | Severity | Required correction |
| --- | --- | --- |
| F-M09B-001 | HIGH | Preflight output/preview/metadata parent directories so a predictable later missing-parent failure cannot partially commit earlier items. |
| F-M09B-002 | HIGH | Missing/unopenable/non-directory catalog root must fail closed and return non-zero. |
| F-M09B-003 | HIGH | Protect canonical catalog path -> declared ID ownership; `overwrite=true` cannot replace an existing catalog path with a different ID. |
| F-M09B-004 | MEDIUM | Malformed/structurally invalid entries and existing duplicate IDs must invalidate overall catalog validation, not merely appear in an informational report. |
| F-M09B-005 | MEDIUM | Validate optional manifest field types (`preview`, `metadata`, `overwrite`) before typed use. |

New reusable audit learnings:

- `AL-014` - batch preflight fidelity for deterministic filesystem preconditions;
- `AL-015` - fail-closed catalog root/health and bidirectional path/ID ownership;
- `AL-016` - optional manifest schema type safety.

## V02 correction (complete, awaiting audit)

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V02.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V02.md

Correction scope was M09-C002 only. All five findings closed while preserving accepted V01 behavior and the audited M09-C001 single-import invariants — see `CLAUDE_IMPLEMENTATION_LOG.md` Session 2 for full evidence. `AWAITING_AUDIT` for ChatGPT audit V02.

## Accepted behavior from M09-C002 V01 that must not regress

- manifest-driven deterministic batch order/reporting;
- reuse of the audited `LevelImporter` per item;
- validation-only no final artifact writes for valid destination paths;
- duplicate ID detection within one manifest;
- requested ID collision against a different catalog file;
- canonical cross-item source/destination alias detection;
- same-ID same-canonical-output re-import concept;
- deterministic unchanged rerun behavior;
- bounded non-transactional OS-failure documentation;
- no owner artwork fabricated/ingested;
- M08/M10/gameplay scope untouched.

Claude reported `426/426` checks after V02 (394 V01 baseline + 32 new). ChatGPT has not yet independently executed the local Godot binary against V02, so that total remains Claude-run implementation evidence rather than independent runtime execution proof.

## Audit model

1. ChatGPT publishes implementation prompts and audit criteria.
2. Claude implements/tests/logs only in `CLAUDE_IMPLEMENTATION_LOG.md`.
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
| Project history | https://github.com/Sekiph82/Scrubbots/blob/main/CHANGELOG.md |
| Level Data spec | https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md |
| Test strategy | https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md |

## Milestone summary

| Milestone | Name | Status |
| --- | --- | --- |
| M00-M04 | Foundation through expanded board fixtures | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | PARTIAL - owner assets still missing |
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS - C001 AUDITED_PASS, C002 AWAITING_AUDIT (V02) |
| M10 | Dirty/Clean Visual Model | OWNER_REQUIRED / PARTIAL infrastructure |
| M11-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
