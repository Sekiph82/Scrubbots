# SCRUBBOTS Level Factory — CLAUDE Governance

This file applies when an implementation prompt targets \`level_factory/\`.

## Project identity

- Nested Godot project: \`level_factory/project.godot\`
- Engine: Godot 4.7.1-stable
- Language: GDScript unless a later audited decision approves otherwise
- Canonical tasks: repository-root \`tasks.md\`, \`SB-LFxx-xxx\`
- Main-game governance: repository-root \`CLAUDE.md\`

## Isolation

The Factory is development tooling. Do not make the root mobile game preload
or depend on Factory GDScript. Export only documented declarative artifacts.

Do not duplicate or rewrite audited M09 importer behavior. Reuse/bridge its
data contract deliberately.

## Design gates

Do not invent dependency, stack, deadlock, reachability, slot-pressure,
win/solution or progression semantics. Implement adapters/interfaces and
wait for canonical gameplay decisions where needed.

## GitHub coordination

1. Safely sync \`origin/main\`.
2. Read the active cycle's \`CHATGPT_PROMPT_VNN.md\`,
   \`CHATGPT_AUDIT_CRITERIA_VNN.md\`, prior ChatGPT audit(s), root
   \`coordination/AUDIT_INDEX.md\`, root \`tasks.md\`, this file and relevant
   Factory docs.
3. Implement/test/log only.
4. Maintain exactly one append-only
   \`CLAUDE_IMPLEMENTATION_LOG.md\` per cycle.
5. Update root \`tasks.md\`, Factory \`coordination/SESSION_INDEX.md\` and
   root \`.hiveai/PROJECT_DASHBOARD.md\` with validated truth.
6. Push safely to \`origin/main\`; never force.
7. Return \`AWAITING_AUDIT\` and stop.
8. Never create audit/self-audit files and never assign audit verdicts.

ChatGPT alone creates \`CHATGPT_AUDIT_VNN.md\` and correction prompt versions.


## Coordination v4 owner override — version-matched Claude logs [LOCKED]

This section supersedes older references in this file to a single
`CLAUDE_IMPLEMENTATION_LOG.md` per cycle.

For every material ChatGPT prompt version:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

The prompt version and Claude log version must match exactly. Work performed
under VNN is recorded in `CLAUDE_LOG_VNN.md` in the same cycle directory.
If V02 and V03 are intentionally delivered/executed together, Claude still
creates both logs and identifies shared commits/tests explicitly.

Historical `CLAUDE_IMPLEMENTATION_LOG.md` files are legacy evidence only.
Do not delete them, but do not use that naming pattern for new prompt work.

Before ending a material session, update these derived H!veAI sources:

- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`

Then materialize the latest state into
`.hiveai/PROJECT_DASHBOARD.md`. H!veAI actively watches only the dashboard.
`tasks.md` remains the only canonical task ledger.

Canonical policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/VERSIONED_LOG_POLICY.md
