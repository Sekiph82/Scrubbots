# SCRUBBOTS Versioned Claude Log Policy

Status: LOCKED
Coordination schema: scrubbots-coordination/v4

## Canonical rule

Every ChatGPT implementation prompt version has exactly one matching Claude
GitHub evidence file in the same cycle directory:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

Prompt/log version matching is mandatory.

## Ownership

- ChatGPT owns CHATGPT_PROMPT_VNN.md.
- ChatGPT owns CHATGPT_AUDIT_CRITERIA_VNN.md.
- Claude owns CLAUDE_LOG_VNN.md.
- ChatGPT owns CHATGPT_AUDIT_VNN.md.
- Claude never creates or edits CHATGPT_* files.
- ChatGPT never fabricates Claude logs.

## Claude log rules

1. Create CLAUDE_LOG_VNN.md when material work begins under
   CHATGPT_PROMPT_VNN.md.
2. Put it beside the prompt in the same cycle folder.
3. Record the exact prompt URL, criteria URL, prior audits, AL learnings,
   starting commit, changed files, all required validation steps, failures,
   fixes, task/docs/coordination changes, commits, push result, final
   GitHub-visible SHA, and handoff state.
4. Multiple local sessions under one prompt append to the same CLAUDE_LOG_VNN.
5. Never hide VNN work inside another version's log.
6. If multiple prompt versions are deliberately executed together, create
   every matching log and clearly identify shared evidence.
7. Preserve historical CLAUDE_IMPLEMENTATION_LOG.md files as legacy evidence.
8. Desktop SCRUBBOTS_PHASE_MXX_LOG.md remains a separate local crash-safe log
   and is never committed.

## H!veAI

Derived tracking sources:

- .hiveai/ACTIVE_CYCLES.md
- .hiveai/ARTIFACT_MAP.md
- .hiveai/PROGRESS_SNAPSHOT.md

H!veAI actively watches only .hiveai/PROJECT_DASHBOARD.md.

## Progress reporting

ChatGPT recalculates progress from tasks.md for every owner-facing audit/new
prompt handoff and reports both ecosystem and per-track completion.


## GitHub-only evidence override [effective M12-C001]

The previous Desktop-phase-log statement is historical only.

For M12-C001 and every later prompt:

- first action: safe local ↔ origin/main synchronization preserving owner work;
- no Desktop phase log or other external handoff log;
- all durable evidence lives in GitHub `CLAUDE_LOG_VNN.md`;
- this applies to the main game, Level Factory, and Content Pipeline.


## Non-self-referential post-push evidence [LOCKED]

A Git-tracked `CLAUDE_LOG_VNN.md` must never be required to contain the SHA
of the final commit that contains that same log. Such a requirement is
self-referential and creates an endless commit-finalization loop.

Rule:

1. CLAUDE_LOG_VNN records all evidence knowable before the focused commit.
2. Create and push the focused commit.
3. Do not edit the Git-tracked log merely to insert that commit's final SHA.
4. When exact post-push SHA/status evidence is required, use a non-Git-mutating
   GitHub receipt. For PR cycles, post one clearly titled PR comment containing
   final commit SHA, remote-head SHA, equality proof, final status, and PR
   state.
5. ChatGPT independently verifies the receipt against actual GitHub remote
   state.
