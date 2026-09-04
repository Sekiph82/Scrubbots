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
| Health | ATTENTION - M09-C002 audit V02 found one remaining deterministic destination-type preflight gap |
| Current implementation frontier | M09 - Pixel Art to Level Data Pipeline |
| Current task | M09-C002 - Destination-Type Preflight Correction V03 |
| Current task ID | `M09-C002` |
| Current workflow state | `CHANGES_REQUIRED` - Audit V02 accepted F-M09B-001..005 but found F-M09B-006 (existing directory can still be used as a final destination until commit-time failure) |
| Required actor | CLAUDE |
| Next project action | Claude implements V03 destination-object-type preflight, runs targeted/full validation, updates implementation log, and returns M09-C002 to AWAITING_AUDIT. |
| Waiting on | M08 production-art audit and remaining M07 visual inventory tasks require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-04T08:54:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M09-C002` |
| Session type | Independent audit V02 + V03 correction issuance |
| Cycle status | `CHANGES_REQUIRED` |
| Summary | Independently inspected implementation head `a95ca5bff646e9e8f2a1382303be2df14d847ace`. Accepted V01 corrections for destination-parent preflight, fail-closed catalog root/health, bidirectional catalog ownership, and optional manifest schema types. Found new HIGH issue F-M09B-006: parent-only preflight does not reject a final destination path that is itself an existing directory, so a later deterministic commit failure can leave earlier artifacts written. Issued V03 and added AL-017. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C002 | Batch import / validation / duplicate-ID tooling | `CHANGES_REQUIRED` | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md |
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

## M09-C002 independent audit V02

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md

Decision: `CHANGES_REQUIRED`.

V02 independently accepted F-M09B-001..005 as closed. New finding:

- `F-M09B-006` HIGH - parent-only destination preflight does not reject an existing directory as the final output/preview/metadata target. This deterministic target-type failure can still occur after an earlier item commits.

Correction prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md

Correction criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md

Reusable learning added:

- `AL-017`: validate the final destination object's incompatible type, not only its parent.

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
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS - C001 AUDITED_PASS, C002 CHANGES_REQUIRED (V03 issued) |
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
