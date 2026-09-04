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
