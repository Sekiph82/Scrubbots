# SCRUBBOTS - H!veAI Project Dashboard

<!--
hiveaiDashboardSchema: hiveai-project-dashboard/v1
dashboardMode: source-map
trackingMode: single-dashboard-watch
refreshPolicy: project-agent-maintained; H!veAI watches only .hiveai/PROJECT_DASHBOARD.md
coordinationSchema: scrubbots-coordination/v3
-->

This file is the single H!veAI-facing materialized project status surface. It is not a second task ledger. Task checkboxes and milestone truth remain canonical only in `tasks.md`.

## Coordination v4 active status

| Field | Value |
| --- | --- |
| Active cycle | M12-C001 |
| Active version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md |
| Purpose | M12 Five-Slot Logic: SlotState + SlotSystem implemented. 5-slot invariant, palette validation, availability/activity independence. 667/667 ALL PASS. |

### Current progress from tasks.md

- Ecosystem: **185 / 848 = 21.82%**
- Main game: **185 / 624 = 29.65%**
- Level Factory: **0 / 112 = 0.00%**
- Content Pipeline: **0 / 112 = 0.00%**

Tracking sources:

- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ACTIVE_CYCLES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ARTIFACT_MAP.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROGRESS_SNAPSHOT.md

## M11-C001 final independent audit

- Status: **AUDITED_PASS**
- Renderer correction audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V03.md
- Coordination/log normalization audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md
- M11: **12 / 12 tasks complete**
- Next main-game milestone: **M12 Five-Slot Logic**

## Active main-game cycle

| Field | Value |
| --- | --- |
| Cycle | M12-C001 |
| Milestone | M12 - Five-Slot Logic |
| Version | V01 |
| State | AWAITING_AUDIT |
| Next actor | CHATGPT |
| Prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V01.md |
| Audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md |
| Logging rule | GitHub-only; no Desktop phase/handoff log |
| Result | SlotState + SlotSystem implemented, 667/667 ALL PASS |

## M12-C001 independent audit V01

- Status: **CHANGES_REQUIRED**
- Audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md
- Finding: **F-M12-001** — `get_slot()` leaks mutable internally owned SlotState,
  allowing callers to bypass palette validation via direct `set_palette_id()`.
- Active correction prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V02.md
- Expected Claude log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V02.md
- Reopened: SB-M12-003, 005, 009, 010, 011.
- Current ecosystem progress: **180 / 848 = 21.23%**.
- Main-game progress: **180 / 624 = 28.85%**.

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
| Health | OK — M12-C001 implementation complete; AWAITING_AUDIT for ChatGPT |
| Current implementation frontier | M12 - Five-Slot Logic |
| Current task | M12-C001 - Five-Slot Logic V01 |
| Current task ID | `M12-C001` |
| Current workflow state | `AWAITING_AUDIT` — SlotState + SlotSystem implemented. 5-slot invariant, palette validation, availability/activity independence, 119 new tests. 667/667 ALL PASS. |
| Required actor | CHATGPT |
| Next project action | ChatGPT performs independent audit V01 on five-slot data/model implementation. |
| Waiting on | M08 production-art audit and remaining M07 visual inventory tasks require owner-supplied SCRUBBOTS artwork. M10 final DIRTY/CLEAN preset remains owner-controlled. |
| Canonical task truth | https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md |

## Latest session summary

| Field | Value |
| --- | --- |
| Timestamp | 2026-09-05 |
| Actor | CLAUDE |
| Cycle | `M12-C001` |
| Session type | M12 Five-Slot Logic implementation |
| Cycle status | `AWAITING_AUDIT` |
| Summary | Implemented SlotState + SlotSystem (RefCounted, AL-001 preload, 5-slot invariant). Palette validation against explicit boundary, duplicate IDs allowed. Availability/activity independent per-slot. 119 new test checks covering all 18 required categories. 667/667 ALL PASS. No GameplaySession/renderer/board changes. M10 gate preserved. |
| Active prompt | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_PROMPT_V01.md |
| Active audit criteria | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V01.md |
| Latest ChatGPT audit | PENDING |
| Claude log | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md |
| Next expected actor | CHATGPT |

## Current work

| ID | Item | Status | Owner/actor | Evidence/source |
| --- | --- | --- | --- | --- |
| M12-C001 | Five-Slot Logic | `AWAITING_AUDIT` | CHATGPT | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CLAUDE_LOG_V01.md |
| M11-C001 | Gameplay Session Core | `AUDITED_PASS` | COMPLETE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md |
| M09-C002 | Batch import / validation / duplicate-ID tooling | `AUDITED_PASS` | COMPLETE | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md |
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

## V03 correction (complete, awaiting audit)

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_PROMPT_V03.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_CRITERIA_V03.md

Closed F-M09B-006: destination-type preflight now rejects existing directories at output/preview/metadata final paths before any commit write. Uses same `LevelImporter._resolve_path()` resolver. Read-only in both modes. `overwrite=true` cannot bypass directory-type safety. 21 new tests (447/447 total). See `CLAUDE_IMPLEMENTATION_LOG.md` Session 3. `AWAITING_AUDIT` for ChatGPT audit V03.

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

## M09-C002 final audit V03

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md

Decision: `AUDITED_PASS`.

F-M09B-006 is closed. M09 tasks SB-M09-001..020 are complete. Claude reported 447/447 checks; ChatGPT independently inspected the code/diff/test design and did not relabel the local runtime total as independently executed.

M09 milestone: COMPLETE.

## M11-C001 contract

Active prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Scope:

- session lifecycle states and transition truth;
- LevelLoader -> immutable LevelData -> fresh BoardState composition;
- READY/ACTIVE/PAUSED/reset/explicit COMPLETED lifecycle;
- optional BoardRenderer binding while presentation remains non-authoritative;
- headless lifecycle, failure-atomicity, rectangular and 59x59 tests.

Non-goals remain locked:

- no automatic win condition;
- no lose condition, timer or move limit;
- no M12 slots;
- no target selection/routing/Scrubbot agents;
- no M10 final visual preset selection.

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
| M09 | Pixel Art to Level Data Pipeline | COMPLETE |
| M10 | Dirty/Clean Visual Model | OWNER_REQUIRED / PARTIAL infrastructure |
| M11 | Gameplay Session Core | AUDITED_PASS - 12/12 tasks, 548/548 ALL PASS |
| M12 | Five-Slot Logic | AWAITING_AUDIT - 11/11 tasks, 667/667 ALL PASS |
| M13-M55 | Remaining milestones | NOT_STARTED / gated as defined in tasks.md |

## Dashboard integrity rules

- H!veAI actively watches only this file.
- `tasks.md` remains task truth.
- Claude implements/tests/logs only.
- ChatGPT alone audits.
- Owner-controlled design gates remain `OWNER_REQUIRED` until explicit owner action.
- Historical prompt/audit versions are immutable evidence.
- Never publish secrets or sensitive environment values.


## M11-C001 independent audit V01

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md

Decision: `CHANGES_REQUIRED`.

- `F-M11-001` MEDIUM: production renderer-binding code is correct on inspection, but M11-23 and M11-24 do not directly observe whether the real BoardRenderer uses the session-owned/fresh BoardState. A regression removing reset-time renderer reconfiguration could pass those tests.
- Active correction prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V02.md
- Active criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- M12, LF00 and CP00 remain unstarted until this narrow correction is audited.

## M11-C001 independent audit V02

Audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V02.md

Decision: `BLOCKED_NO_NEW_IMPLEMENTATION`.

No V02 correction commit/log append was visible on GitHub. F-M11-001 remains open. Active recovery:

- Prompt V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V03.md
- Criteria V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V03.md

## Parallel sidecar projects

| Project | Root | Status | Canonical tasks | Coordination |
| --- | --- | --- | --- | --- |
| SCRUBBOTS Level Factory | \`level_factory/\` | PLANNED / architecture registered | \`SB-LF00-001..\` in root \`tasks.md\` | \`level_factory/coordination/SESSION_INDEX.md\` |
| SCRUBBOTS Content Pipeline | \`content_pipeline/\` | PLANNED / architecture registered | \`SB-CP00-001..\` in root \`tasks.md\` | \`content_pipeline/coordination/SESSION_INDEX.md\` |

Both sidecars use the same GitHub-native ChatGPT↔Claude evidence chain as the
main game. Root \`tasks.md\` remains the only task ledger and this root H!veAI
dashboard remains the materialized status surface. Sidecar work must not
silently supersede the active main-game audit cycle.
