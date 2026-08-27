# SCRUBBOTS Coordination Protocol

This directory is the versioned communication bus between ChatGPT, Claude Code, the repository, and the H!veAI Project Dashboard.

## Authority model

- `tasks.md` is the only canonical task ledger. Coordination files may reference task IDs, but must not create a competing backlog.
- `CLAUDE.md` is the agent operating manual.
- `.hiveai/PROJECT_DASHBOARD.md` is the H!veAI-facing status and latest-session summary surface.
- `coordination/SESSION_INDEX.md` is the append-only index of communication cycles.
- `CHANGELOG.md` is project history, not task truth.
- Desktop phase logs remain the detailed, crash-safe Claude work journal. GitHub coordination logs do not replace them.

## Coordination cycle

A coordination cycle is the smallest complete ChatGPT -> Claude -> ChatGPT handoff loop for one scoped unit of work.

Use IDs in this form:

- `M07-C001`, `M07-C002`, ... for milestone work.
- `META-C001`, `META-C002`, ... for repository/process-only work that does not belong to a gameplay milestone.

A cycle may span multiple ChatGPT or Claude sessions. Do not create a new cycle merely because a session restarted.

## Cycle files

Store each cycle under:

`coordination/sessions/<CYCLE_ID>/`

Allowed artifacts:

- `CHATGPT_PROMPT_V01.md`, `CHATGPT_PROMPT_V02.md`, ...: exact implementation instructions issued to Claude. Once a prompt version has been acted on, do not rewrite it. Create the next version instead.
- `CLAUDE_IMPLEMENTATION_LOG.md`: Claude-owned, append-only implementation record for the cycle. Multiple Claude sessions append to the same file.
- `CHATGPT_AUDIT_V01.md`, `CHATGPT_AUDIT_V02.md`, ...: ChatGPT review of repository evidence after Claude work. Published audit versions are immutable except for clearly marked factual corrections.
- `OWNER_NOTES.md`: optional owner decisions or clarifications that must survive chat context loss.

Do not store secrets, credentials, tokens, private keys, local absolute secret-file contents, or sensitive environment values in coordination artifacts.

## Status lifecycle

Use one of these cycle states:

- `PLANNED`: ChatGPT prompt exists; Claude has not started.
- `CLAUDE_IN_PROGRESS`: Claude is implementing.
- `AWAITING_AUDIT`: Claude finished a pass and recorded evidence; ChatGPT audit is next.
- `CHANGES_REQUIRED`: audit found required corrections; same cycle continues.
- `AUDITED_PASS`: ChatGPT verified the cycle against prompt/task/repository evidence.
- `BLOCKED`: progress requires owner/external input.
- `SUPERSEDED`: a later cycle intentionally replaces this cycle. Never delete the historical record.

## ChatGPT responsibilities

At the start of a material project session:

1. Read `tasks.md`, `CLAUDE.md`, `.hiveai/PROJECT_DASHBOARD.md`, this protocol, and `coordination/SESSION_INDEX.md`.
2. Inspect the repository/commit state rather than trusting old chat memory.
3. Reuse the current cycle if the same scoped work is continuing; otherwise allocate the next cycle ID.
4. When issuing Claude work, save the exact prompt as the next `CHATGPT_PROMPT_VNN.md` before or together with the handoff.
5. After Claude work, inspect the implementation log plus actual Git diff/commits/tests and write `CHATGPT_AUDIT_VNN.md`.
6. If changes are required, keep the same cycle and issue a new prompt version that cites the audit.
7. Update `coordination/SESSION_INDEX.md` and the Latest Session Summary in `.hiveai/PROJECT_DASHBOARD.md` after every material ChatGPT session.

A ChatGPT audit must be evidence-based. Do not mark PASS from Claude prose alone when repository/test evidence can be checked.

## Claude Code responsibilities

Before modifying code:

1. Read `CLAUDE.md`, `tasks.md`, `.hiveai/PROJECT_DASHBOARD.md`, this protocol, and `coordination/SESSION_INDEX.md`.
2. Identify the active cycle and read every `CHATGPT_PROMPT_VNN.md`, `CHATGPT_AUDIT_VNN.md`, and owner note in that cycle, in version order.
3. Update/create `CLAUDE_IMPLEMENTATION_LOG.md` and mark the cycle `CLAUDE_IN_PROGRESS` in the session index/dashboard before substantial work when practical.
4. Continue the existing Desktop phase log required by `CLAUDE.md`; do not replace it with the GitHub log.

Before ending a material Claude session:

1. Append exact implementation evidence to `CLAUDE_IMPLEMENTATION_LOG.md`: starting commit, files changed, architecture decisions, commands/tests, failures/fixes, performance evidence, task/doc updates, commit/push result, unresolved items.
2. Keep failure history. Do not rewrite the log to pretend failed approaches never happened.
3. Update `tasks.md` only when task truth actually changed and validation evidence supports it.
4. Update `coordination/SESSION_INDEX.md` to `AWAITING_AUDIT`, `BLOCKED`, or the accurate state.
5. Update `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary and recent-cycle row.
6. Commit coordination artifacts with the implementation when safe, or in an immediately following focused documentation commit. Never commit secrets.

Claude must not edit a published ChatGPT prompt or audit to make implementation look compliant.

## H!veAI watcher contract

H!veAI should track these sources:

- `.hiveai/PROJECT_DASHBOARD.md`
- `tasks.md`
- `coordination/SESSION_INDEX.md`
- `coordination/sessions/**/CHATGPT_PROMPT_V*.md`
- `coordination/sessions/**/CHATGPT_AUDIT_V*.md`
- `coordination/sessions/**/CLAUDE_IMPLEMENTATION_LOG.md`
- `CHANGELOG.md`

The dashboard may summarize these sources, but task checkboxes remain authoritative only in `tasks.md`.

## Dashboard synchronization rule

Every material ChatGPT or Claude session must refresh `.hiveai/PROJECT_DASHBOARD.md` with:

- session timestamp;
- actor (`CHATGPT`, `CLAUDE`, `OWNER`, or `SYSTEM`);
- cycle ID;
- cycle status;
- milestone/task refs;
- concise work summary;
- evidence/commit links or repository paths;
- blocker/waiting state;
- next expected actor/action.

The dashboard is a summary surface, not a second task ledger. Detailed history lives in the cycle files and `SESSION_INDEX.md`.

## Relationship to Desktop phase logs

The two log systems serve different purposes:

- `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md`: continuous, detailed Claude phase journal, local-only, never committed.
- `coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md`: durable GitHub communication evidence for ChatGPT/H!veAI/owner review.

Both are required for Claude implementation work unless the owner explicitly changes the workflow.
