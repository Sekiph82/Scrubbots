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
| Health | HEALTHY - correction pass required by independent audit |
| Current implementation frontier | M09 - Pixel Art to Level Data Pipeline |
| Current task | M09-C001 - importer safety correction pass V02 |
| Current task ID | `M09-C001` |
| Current workflow state | `CHANGES_REQUIRED` - ChatGPT audit V01 found four importer safety/negative-test gaps; correction Prompt V02 issued |
| Required actor | CLAUDE |
| Next project action | Claude reads ChatGPT audit V01 + criteria V02 + Prompt V02, fixes F-M09-001..004, appends implementation/test evidence, returns `AWAITING_AUDIT`, and stops. |
| Waiting on | M08 production-art audit and remaining M07 asset inventory tasks still require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-08-27T23:47:00+03:00 |
| Actor | CHATGPT |
| Cycle | `M09-C001` |
| Session type | Independent audit V01 + correction prompt issuance |
| Cycle status | `CHANGES_REQUIRED` |
| Milestone/task impact | SB-M09-001..016 remain provisionally implemented. Audit found SB-M09-017 overstated until format/path/reconstruction safety is corrected. SB-M09-018..020 remain open. M08 remains open. |
| Summary | Independent code/diff/test review confirmed deterministic palette/row-major/Level Data V1 architecture, but found four gaps: source/artifact path aliasing can overwrite files; preview/metadata do not honor safe overwrite semantics; PNG-only support is not explicitly gated; malformed reconstruction can index a short cell array unsafely. V02 correction prompt and criteria published. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md |
| Latest ChatGPT audit | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
| Claude implementation log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md |
| Audit learning index | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md |
| Next expected actor | CLAUDE |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M09-C001 | Exact-pixel importer core + safety corrections | `CHANGES_REQUIRED` | CLAUDE then CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
| M08 | Level Art Technical Audit | `BLOCKED_ON_OWNER_ASSET` | HUMAN supplies production art; Claude audits after scoped prompt | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M07 | Visual Reference Library | PARTIAL - infrastructure audited; owner assets still missing | HUMAN for asset-specific tasks | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M10 | DIRTY/CLEAN Visual Approval | `OWNER_REQUIRED` | HUMAN | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |
| M05 | Test Harness Maturity | PARTIAL | CLAUDE | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## M09-C001 independent audit V01

Decision: `CHANGES_REQUIRED`

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md

Correction prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V02.md

Correction criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V02.md

| Finding | Severity | Correction required |
| --- | --- | --- |
| F-M09-001 | HIGH | Canonicalize path identity and reject source↔destination / destination↔destination aliases before any write; source must remain immutable even with overwrite=true. |
| F-M09-002 | HIGH | Apply safe overwrite/preflight semantics to Level JSON, preview, and metadata, not only primary output. |
| F-M09-003 | MEDIUM | Enforce PNG-only input in reusable importer core and distinguish valid unsupported format from corrupt PNG. |
| F-M09-004 | MEDIUM | Harden reconstruction against short cells, invalid palette IDs/strings, and invalid dimensions without runtime indexing errors. |

Reusable learnings added:

- `AL-010`: path alias/source immutability;
- `AL-011`: negative-test specificity;
- `AL-012`: multi-artifact overwrite safety.

## M09-C001 behavior that audit confirmed

The following remain valid and must not regress during V02:

- exact source dimensions for normal PNG import;
- one RGBA8 source pixel = one logical cell;
- no resize/resample/crop/pad path;
- deterministic first-seen row-major palette;
- canonical `index = y * width + x` cells;
- existing Level Data V1 schema only;
- DifficultyRules / ProductionLevelValidator authority;
- TEST vs production split;
- metadata sidecar remains separate;
- reconstruction uses generated Level Data, not source shortcut;
- 3x2, rectangular production-band, 59x59, transparency and repeated-color test coverage;
- explicit preload discipline;
- no owner artwork fabricated or committed.

Claude reported 286/286 tests passing on the initial implementation. ChatGPT did not execute the local Godot binary, so that runtime total remains Claude-run evidence rather than independent execution proof.

## Audit model

1. ChatGPT publishes implementation prompts and audit criteria.
2. Claude implements/tests/logs only in `CLAUDE_IMPLEMENTATION_LOG.md`.
3. Claude does not create audit/self-audit files or assign audit verdicts.
4. ChatGPT independently audits repository state after handoff.
5. Only ChatGPT publishes `CHATGPT_AUDIT_VNN.md` and assigns `AUDITED_PASS` / `AUDITED_FAIL`.
6. Audit corrections stay in the same cycle using a new prompt version.
7. Claude reads prior ChatGPT audits plus `AUDIT_INDEX.md` and applies those findings to implementation/testing.

Canonical audit sources:

- Policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- Learning index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- ChatGPT prompt template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_PROMPT_TEMPLATE.md
- Claude implementation-log template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md
- ChatGPT audit template: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CHATGPT_AUDIT_TEMPLATE.md

## Recent coordination cycles

| Cycle | Milestone | Status | Last actor | Summary | Evidence |
| --- | --- | --- | --- | --- | --- |
| `M09-C001` | M09 | `CHANGES_REQUIRED` | CHATGPT | Audit V01 found four importer safety/test gaps; V02 correction prompt issued. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
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

After every material ChatGPT or Claude session, update this dashboard with timestamp/actor, cycle/status, active prompt/audit/log URLs, concise work summary, blocker/waiting state, next actor/action, and actual task/project state only when canonical truth changed.

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
| M09 | Pixel Art to Level Data Pipeline | IN_PROGRESS - M09-C001 correction pass required |
| M10-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.
