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
| Current task | M09-C002 - Batch Import / Batch Validation / Duplicate-ID Protection |
| Current task ID | `M09-C002` |
| Current workflow state | `PLANNED` - ChatGPT closed M09-C001 as AUDITED_PASS and issued M09-C002 prompt V01 |
| Required actor | CLAUDE |
| Next project action | Claude reads the M09-C002 prompt, audit criteria, M09-C001 final audit and active audit learnings, then implements/tests/logs SB-M09-018..020 only. |
| Waiting on | M08 production-art audit and remaining M07 visual inventory tasks still require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-03T11:38:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M09-C001` -> `M09-C002` |
| Session type | Independent audit V03 + next-cycle issuance |
| Cycle status | `M09-C001 AUDITED_PASS`; `M09-C002 PLANNED` |
| Milestone/task impact | SB-M09-001..017 are independently accepted at coordination level. SB-M09-018..020 remain open and are the only M09-C002 task targets. M08 remains open. |
| Summary | ChatGPT independently verified V03 filesystem-identity normalization: bare relative paths resolve to the documented res:// base, dot segments are simplified, equivalent source/destination aliases are rejected, overwrite cannot authorize source destruction, and targeted tests exercise the exact bypass found in audit V02. No new audit learning was required. M09-C002 is now issued for manifest-driven batch import, validation-only preflight, catalog duplicate-ID protection and deterministic reporting. |
| M09-C001 final audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md |
| M09-C002 active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md |
| M09-C002 audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V01.md |
| M09-C002 Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C002 | Batch import / validation / duplicate-ID tooling | `PLANNED` | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md |
| M09-C001 | Exact-pixel single importer + safety hardening | `AUDITED_PASS` | COMPLETE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md |
| M08 | Level Art Technical Audit | `BLOCKED_ON_OWNER_ASSET` | HUMAN supplies production art | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## M09-C001 closure

Final independent audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md

Decision: `AUDITED_PASS`.

Accepted M09-C001 invariants now form the baseline for M09-C002:

- exact PNG source dimensions;
- one RGBA8 source pixel = one logical cell;
- deterministic first-seen row-major palette;
- canonical `index = y * width + x`;
- Level Data V1 output only;
- TEST vs production validation through existing authority;
- source immutability;
- PNG-only gate;
- multi-artifact overwrite preflight;
- deterministic unchanged/no-write behavior;
- reconstruction from Level Data with exact RGBA8 round-trip evidence;
- filesystem identity normalization for `.` / `..`, relative/absolute equivalents, separators and Windows case rules;
- symlink/realpath identity is not claimed as implemented.

Claude reported `332/332` checks after V03. ChatGPT independently inspected the relevant code/diff/test design but did not execute the local Godot binary, so the runtime total remains Claude-run implementation evidence.

## M09-C002 contract

Active prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md

Pre-published audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V01.md

Locked task scope:

- `SB-M09-018` Batch import;
- `SB-M09-019` Batch validation;
- `SB-M09-020` Duplicate level ID protection.

Core expectations:

- manifest-driven deterministic batch layer;
- reuse audited single importer, do not fork conversion semantics;
- validation-only mode with no final artifact writes;
- whole-batch logical preflight before final writes;
- duplicate IDs rejected within batch and against existing catalog;
- existing catalog duplicates/malformed entries are reported, not ignored;
- canonical path safety works across items, including cross-item source/destination aliases;
- unchanged batch rerun remains stable;
- no fake owner art;
- no M08, M10, M11 or later work.

## Audit model

1. ChatGPT publishes implementation prompts and audit criteria.
2. Claude implements/tests/logs only in `CLAUDE_IMPLEMENTATION_LOG.md`.
3. Claude does not create audit/self-audit files or assign audit verdicts.
4. ChatGPT independently audits repository state after handoff.
5. Only ChatGPT publishes `CHATGPT_AUDIT_VNN.md` and assigns `AUDITED_PASS` / `AUDITED_FAIL`.
6. Audit corrections remain in the same cycle via new prompt versions.
7. Claude reads prior ChatGPT audits plus `AUDIT_INDEX.md` and uses those findings to strengthen implementation/testing.

## Active audit learnings relevant to M09-C002

- `AL-005`: completion needs behavioral evidence;
- `AL-006`: missing owner art cannot be fabricated;
- `AL-008`: unknown metadata/provenance cannot be invented;
- `AL-009`: every required validation command/check is individually logged;
- `AL-010`: source/output path alias safety;
- `AL-011`: negative tests isolate their claimed failure mode;
- `AL-012`: overwrite safety covers every generated artifact;
- `AL-013`: filesystem identity handles dot segments and relative/absolute equivalence.

Full index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M09-C002` | M09 | `PLANNED` | CHATGPT | Batch import/validation + duplicate-ID prompt and audit criteria issued. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V01.md |
| `M09-C001` | M09 | `AUDITED_PASS` | CHATGPT | Audit V03 closed filesystem-identity finding and accepted SB-M09-001..017. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md |
| `M07-C001` | M07 | `AUDITED_PASS` | CHATGPT | Reference-library infrastructure audited; owner asset tasks remain open. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md |
| `META-C001` | META | `AUDITED_PASS` | CHATGPT | Repository-native ChatGPT/Claude coordination + H!veAI synchronization established. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md |

## Coordination source map

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
| M07 | Visual Reference Library | PARTIAL - owner assets still missing |
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS - C001 audited, C002 planned |
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
