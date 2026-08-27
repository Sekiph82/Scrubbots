---
coordinationSchema: scrubbots-coordination/v2
artifactType: chatgpt-prompt
cycleId: M07-C001
version: 3
createdAt: 2026-08-27T12:04:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M07
taskRefs:
  - SB-M07-001
  - SB-M07-002
  - SB-M07-003
  - SB-M07-004
  - SB-M07-005
  - SB-M07-006
  - SB-M07-007
  - SB-M07-008
  - SB-M07-009
  - SB-M07-010
  - SB-M07-011
  - SB-M07-012
  - SB-M07-013
  - SB-M07-014
  - SB-M07-015
  - SB-M07-016
  - SB-M07-017
supersedes: CHATGPT_PROMPT_V02.md
---

# SCRUBBOTS - M07-C001 Prompt V03

## Supersession and inherited scope

This is the active implementation authority for cycle `M07-C001` and supersedes V02 before Claude implementation begins.

All M07 implementation scope, locked visual rules, validation commands, task-status rules, Git requirements, and stop conditions defined in V02 remain in force unless this V03 explicitly changes them.

Inherited V02 scope:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md

V01 and V02 remain immutable historical evidence. Do not edit them.

## Mandatory canonical sources

Before implementation, read these GitHub files in order:

1. https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
7. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V02.md
9. this V03:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md
10. pre-implementation audit criteria:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md
11. Claude implementation-log template:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_IMPLEMENTATION_LOG_TEMPLATE.md
12. Claude self-audit template:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md
13. all project docs referenced by V02.

Before substantial work, safely sync the local working copy with `origin/main` without destroying local owner work.

## Audit-driven verification is mandatory

Claude must not treat its own green tests as independent proof.

Use the vocabulary and evidence levels in:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Claude-run results are provisional and must be classified only as:

- `SELF_PASS`
- `SELF_FAIL`
- `NOT_RUN`
- `NOT_APPLICABLE`
- `BLOCKED`
- `OWNER_REQUIRED`

Never use `AUDITED_PASS` or `AUDITED_FAIL` for Claude's own work.

## Apply prior audit learnings

Before planning implementation tests, read:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

For M07-C001, explicitly apply at minimum:

- `AL-005`: file existence is not task-completion evidence.
- `AL-006`: missing owner artwork cannot be fabricated or guessed into existence.
- `AL-007`: M10 DIRTY/CLEAN final visual choice remains owner-controlled.

Apply any additional `AL-XXX` item relevant to files/systems touched during the cycle.

Record in the implementation log exactly how each relevant audit learning changed implementation or testing.

## Use ChatGPT audit criteria as the test oracle

Read and use this file before coding and again before self-audit:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Build the test/check plan around those criteria.

For every material requirement, define before final handoff:

- expected outcome;
- explicit failure condition;
- check/test method;
- negative/boundary/integrity checks where applicable;
- false-positive risk;
- remaining untested assumption.

Do not optimize for a large green test count. Optimize for tests/checks that can distinguish correct behavior from a plausible false positive.

## Mandatory Claude self-audit

After implementation and provisional tests, but before handing the cycle to ChatGPT, create:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md

Repository path:
`coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md`

Use:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md

The self-audit must:

1. map every material V02/V03 requirement to a check;
2. cite the applicable audit-criteria IDs `AC-M07-001` through `AC-M07-014`;
3. cite the `AL-XXX` audit learnings applied;
4. compare current observations against prior audited baselines/known failure modes;
5. include negative/boundary/integrity checks where applicable;
6. identify false-positive risks;
7. list untested assumptions;
8. distinguish provisional `SELF_PASS` from independent proof;
9. recommend, but not independently authorize, `tasks.md` state changes;
10. conclude only `READY`, `NOT_READY`, or `BLOCKED` for independent audit.

If implementation requires a later correction pass after ChatGPT audit, create `CLAUDE_SELF_AUDIT_V02.md` rather than rewriting V01.

## Mandatory implementation log

Maintain:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_IMPLEMENTATION_LOG.md

The log must cite absolute GitHub URLs for prompt, audit criteria, audit policy/index, commits, self-audit, session index, dashboard, and relevant repository evidence.

Continue the local-only phase journal as required by V02/CLAUDE.md:
`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M07_LOG.md`

Never commit the Desktop log.

## Handoff rule

Only after implementation log + self-audit are complete enough for independent review:

- update https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- update https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- set cycle status to `AWAITING_AUDIT` when ready, or `BLOCKED` when truly blocked.

Expected independent audit location after handoff:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md

Claude must never create or modify `CHATGPT_AUDIT_VNN.md` files.

## Final response

Keep the Claude chat response concise. Include only:

- cycle ID;
- cycle state;
- implementation commit;
- provisional regression result;
- implementation log URL;
- Claude self-audit URL;
- remaining blocker(s);
- `READY FOR CHATGPT INDEPENDENT AUDIT` when appropriate.

Then stop. Do not begin M08.