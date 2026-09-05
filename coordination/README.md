# SCRUBBOTS Coordination Protocol

This directory is the durable GitHub communication layer between ChatGPT, Claude Code, the repository, and the H!veAI Project Dashboard.

## Authority model

- `tasks.md` is the only canonical task ledger.
- `CLAUDE.md` is the agent operating manual.
- `.hiveai/PROJECT_DASHBOARD.md` is the single H!veAI-facing materialized status surface.
- `coordination/SESSION_INDEX.md` indexes work cycles.
- `coordination/AUDIT_INDEX.md` is ChatGPT-owned reusable audit memory.
- `CHANGELOG.md` is project history, not task truth.
- Desktop phase logs remain local crash-safe Claude journals and are never committed.

## Canonical GitHub URL rule

Use absolute GitHub URLs as the canonical references in prompts, audits, Claude logs, session summaries, and handoffs.

Canonical base:

`https://github.com/Sekiph82/Scrubbots/blob/main/`

Repository-relative paths may be included as secondary convenience references for local edits. Local-only Desktop phase logs remain local paths.

## Coordination cycle

A cycle is one scoped ChatGPT -> Claude -> ChatGPT implementation/review loop.

Examples:

- `M07-C001`, `M07-C002`, ... for milestone work.
- `META-C001`, ... for repository/process-only work.

A chat/session restart does not create a new cycle. Continue the existing cycle until `AUDITED_PASS`, `BLOCKED`, `SUPERSEDED`, or an explicit end.

## Cycle artifacts

Store cycle artifacts under:

`coordination/sessions/<CYCLE_ID>/`

Canonical artifact ownership:

- `CHATGPT_PROMPT_VNN.md` - **ChatGPT-owned** implementation instructions.
- `CHATGPT_AUDIT_CRITERIA_VNN.md` - optional **ChatGPT-owned** pre-implementation audit criteria.
- `CLAUDE_IMPLEMENTATION_LOG.md` - **Claude-owned**, append-only implementation/test log.
- `CHATGPT_AUDIT_VNN.md` - **ChatGPT-owned** independent audit after Claude work.
- `OWNER_NOTES.md` - optional durable owner clarifications.

### No Claude self-audit

Claude does **not** create audit files or self-audit files.

Historical `CLAUDE_SELF_AUDIT_*` files created before the owner corrected the workflow remain historical only. Do not create new ones and do not treat them as independent proof.

## Normal cycle flow

1. **ChatGPT inspects current GitHub state.**
2. **ChatGPT publishes the active prompt** and, where useful, audit criteria.
3. The prompt explicitly links relevant prior ChatGPT audits and `AUDIT_INDEX.md` learnings.
4. **Claude safely syncs local `main`.**
5. **Claude implements**, runs the tests/checks required by the prompt, and appends results to `CLAUDE_IMPLEMENTATION_LOG.md`.
6. Claude uses prior ChatGPT audit findings to strengthen the current test plan, but records that comparison only in the implementation log.
7. Claude updates `tasks.md` only with validated truth, then updates `SESSION_INDEX.md` and `.hiveai/PROJECT_DASHBOARD.md`.
8. Claude hands the cycle back as `AWAITING_AUDIT` or `BLOCKED`.
9. **ChatGPT independently audits actual GitHub state** and publishes `CHATGPT_AUDIT_VNN.md`.
10. If clean, ChatGPT sets `AUDITED_PASS`.
11. If corrections are required, ChatGPT sets `CHANGES_REQUIRED` and publishes the next prompt version in the **same cycle**, linking the audit.

## ChatGPT responsibilities

Before issuing work:

1. Read canonical GitHub task/governance/dashboard/coordination sources.
2. Inspect current commits/diffs rather than relying on chat memory.
3. Read relevant previous ChatGPT audit(s) and `AUDIT_INDEX.md`.
4. Save the full implementation instruction as a versioned `CHATGPT_PROMPT_VNN.md`.
5. Include absolute GitHub URLs for all mandatory sources.
6. State relevant prior audit findings that Claude must incorporate into implementation/testing.

After Claude work:

1. Read `CLAUDE_IMPLEMENTATION_LOG.md`.
2. Inspect actual GitHub commits/diffs/files/task state.
3. Independently cross-check tests/evidence where accessible.
4. Do not accept Claude prose or green test totals as automatic proof.
5. Publish `CHATGPT_AUDIT_VNN.md` with requirement-level PASS/FAIL and exact corrections.
6. Update `AUDIT_INDEX.md` when a reusable lesson is discovered.
7. Update `SESSION_INDEX.md` and the H!veAI dashboard.

## Claude responsibilities

Before implementation:

1. Read the active ChatGPT prompt from its GitHub URL.
2. Read the prior ChatGPT audit URLs explicitly listed in that prompt.
3. Read https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md and apply relevant `AL-XXX` learnings.
4. Safely synchronize the local repository without destroying owner work.
5. Continue the correct local Desktop phase log.
6. Create/append only the cycle's `CLAUDE_IMPLEMENTATION_LOG.md` for durable GitHub evidence.

During implementation/testing:

- run the prompt-required checks;
- record exact command/check, expected result, explicit failure condition, actual result, and failures/fixes;
- include negative/boundary/regression checks when prior audits or system risk require them;
- explicitly note how prior ChatGPT audit findings changed the test plan;
- treat Claude-run green tests as implementer evidence, not an audit verdict;
- never use `AUDITED_PASS` or `AUDITED_FAIL`.

Before ending:

1. Append the implementation/test evidence to `CLAUDE_IMPLEMENTATION_LOG.md`.
2. Update `tasks.md` only when validated truth changed.
3. Update `coordination/SESSION_INDEX.md`.
4. Update `.hiveai/PROJECT_DASHBOARD.md`.
5. Commit/push safely.
6. Set `AWAITING_AUDIT` when ready for ChatGPT review, or `BLOCKED` when truly blocked.
7. Stop. Do not perform an audit.

Claude must never create or modify `CHATGPT_AUDIT_VNN.md`.

## Audit policy

Canonical policy:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Key rule: **Claude tests; ChatGPT audits.**

## H!veAI single-dashboard contract

H!veAI actively watches only:

https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

ChatGPT and Claude materialize the latest relevant state into that file after every material session.

Source evidence includes:

- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- cycle-specific ChatGPT prompt URLs
- cycle-specific Claude implementation-log URLs
- cycle-specific ChatGPT audit URLs
- owner-note URLs when present

The dashboard summarizes these sources; it does not replace them or duplicate task checkboxes.

## Relationship to Desktop phase logs

Both remain required for Claude implementation work:

- `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` - detailed local phase journal, never committed.
- `https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md` - durable GitHub implementation/test handoff evidence.


## Coordination v4 — version-matched artifact bundles [LOCKED]

This section supersedes the earlier one-log-per-cycle model.

Each implementation version is a matched bundle:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

Claude owns only `CLAUDE_LOG_VNN.md`. ChatGPT owns the CHATGPT_* artifacts.
The version number must match. Multiple local Claude sessions under one prompt
append to that prompt's one versioned log. Historical
`CLAUDE_IMPLEMENTATION_LOG.md` files remain preserved legacy evidence.

ChatGPT must not audit a prompt version until the expected matching Claude log
is visible on GitHub.

### Owner-facing progress reporting

Every ChatGPT audit/new-prompt handoff to the owner must recalculate from
canonical `tasks.md` and report total, completed, remaining, overall
percentage, main-game percentage, Level Factory percentage, and Content
Pipeline percentage.

### H!veAI derived tracking

Maintain:

- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ACTIVE_CYCLES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/ARTIFACT_MAP.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROGRESS_SNAPSHOT.md

H!veAI still actively watches only:
https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md


## GitHub-only logging from M12-C001 [LOCKED]

The historical Desktop phase-log workflow is retired for all new work.

Every new prompt must begin by ordering Claude to safely synchronize the local
repository with `origin/main` while preserving owner work.

After synchronization, Claude reads the GitHub prompt/audit/governance sources
and records all durable evidence only in `CLAUDE_LOG_VNN.md`.

Do not create or update Desktop phase logs for M12-C001 or later cycles.


## Post-push receipt rule

Final commit SHA evidence must not be made self-referential inside the same
Git-tracked Claude log. For PR cycles, exact post-push commit/head/status
evidence may be recorded in a clearly titled PR comment, then independently
verified by ChatGPT. No new commit may be created merely to write that SHA
back into the log.
