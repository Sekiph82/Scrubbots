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
| Health | HEALTHY - narrow importer path-safety correction required |
| Current implementation frontier | M09 - Pixel Art to Level Data Pipeline |
| Current task | M09-C001 - filesystem identity correction V03 |
| Current task ID | `M09-C001` |
| Current workflow state | `CHANGES_REQUIRED` - ChatGPT audit V02 published; Prompt V03 issued |
| Required actor | CLAUDE |
| Next project action | Claude reads Audit V02 + Criteria V03 + Prompt V03, fixes equivalent-path identity normalization, appends tests/evidence to the existing implementation log, updates dashboard/index, and returns `AWAITING_AUDIT`. |
| Waiting on | M08 production-art audit and remaining M07 visual inventory tasks require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-28T00:02:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M09-C001` |
| Session type | Independent audit V02 + correction issuance |
| Cycle status | `CHANGES_REQUIRED` |
| Milestone/task impact | SB-M09-001..016 remain substantively implemented. SB-M09-017 is not independently closed until equivalent filesystem-path aliases are safely normalized and retested. SB-M09-018..020 remain open. M08 remains open. |
| Summary | Audit V02 independently reviewed V02 importer safety corrections. PNG-only gate, multi-artifact preflight/unchanged behavior, and malformed reconstruction safety are accepted. Remaining finding F-M09-005: `_canonical_path()` does not simplify `.`/`..` or fully resolve relative-vs-absolute identity, so syntactically different paths may still target the same file and bypass source/artifact alias checks. Prompt V03 and Criteria V03 issued. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V03.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C001 | Exact-pixel importer core + path safety | `CHANGES_REQUIRED` | CLAUDE then CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md |
| M08 | Level Art Technical Audit | `BLOCKED_ON_OWNER_ASSET` | HUMAN supplies production art | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## M09-C001 audit status

### Audit V01

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md

Found four issues:

- F-M09-001 source/artifact aliasing;
- F-M09-002 multi-artifact overwrite safety;
- F-M09-003 PNG-only format enforcement;
- F-M09-004 malformed reconstruction safety.

### Audit V02

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md

Decision: `CHANGES_REQUIRED`.

V02 independently accepts:

- F-M09-002 closed;
- F-M09-003 closed;
- F-M09-004 closed;
- direct/exact-string parts of F-M09-001 improved.

Remaining finding:

- `F-M09-005` - path identity is not fully canonicalized. `.` / `..` and relative-vs-absolute equivalent paths can still compare as different strings while targeting the same filesystem object.

Active correction:

- Prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V03.md
- Criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V03.md

## Active audit learnings relevant now

- `AL-009`: validation traceability;
- `AL-010`: import/export path alias and source immutability;
- `AL-012`: multi-artifact overwrite safety;
- `AL-013`: filesystem identity normalization, including dot segments and relative-vs-absolute equivalents.

Full index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Behavior already accepted and protected from regression

- exact PNG source dimensions;
- one RGBA8 source pixel = one logical cell;
- no resize/resample/interpolation/crop/pad;
- deterministic first-seen row-major palette;
- canonical `index = y * width + x`;
- Level Data V1 output only;
- DifficultyRules / ProductionLevelValidator authority;
- TEST vs production separation;
- separate source metadata sidecar;
- reconstruction from generated Level Data, not source shortcut;
- alpha round-trip;
- rectangular 20x27 coverage;
- 59x59 maximum coverage;
- explicit PNG gate and valid-JPEG rejection;
- corrupt-PNG distinction;
- all-artifact overwrite preflight and unchanged detection;
- malformed reconstruction guards;
- no owner artwork fabricated or committed.

Claude reported 320/320 tests after V02. ChatGPT did not execute the local Godot binary, so that total remains Claude-run implementation evidence rather than independent runtime execution proof.

## Audit model

1. ChatGPT publishes implementation prompts and audit criteria.
2. Claude implements/tests/logs only in `CLAUDE_IMPLEMENTATION_LOG.md`.
3. Claude does not create audit/self-audit files or assign audit verdicts.
4. ChatGPT independently audits repository state after handoff.
5. Only ChatGPT publishes `CHATGPT_AUDIT_VNN.md` and assigns `AUDITED_PASS` / `AUDITED_FAIL`.
6. Audit corrections remain in the same cycle via new prompt versions.
7. Claude reads prior ChatGPT audits plus `AUDIT_INDEX.md` and uses those findings to strengthen implementation/testing.

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M09-C001` | M09 | `CHANGES_REQUIRED` | CHATGPT | Audit V02 accepted most V02 fixes but found remaining equivalent-filesystem-path bypass. V03 issued. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md |
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
| M02 | BoardState Core | COMPLETE except intentionally deferred RESERVED work |
| M03 | Official Difficulty Bands + 59x59 | COMPLETE |
| M04 | Expanded Board Fixtures & Test Matrix | COMPLETE |
| M05 | Test Harness Maturity | PARTIAL |
| M06 | Board Renderer | COMPLETE |
| M07 | Visual Reference Library | PARTIAL - owner assets pending |
| M08 | Level Art Technical Audit | BLOCKED_ON_OWNER_ASSET |
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS - M09-C001 correction V03 |
| M10 | Dirty/Clean Visual Model | OWNER_REQUIRED gate remains open |
| M11-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
