STATUS: READY

# Build: FACTORY-EFFICIENCY

## Summary
Edited .claude/skills/factory/SKILL.md (Light path, Reading TASKS.md, queue-block sed replaces head -80), .claude/agents/{approver,reviewer-rules,spec-writer}.md (model sonnet), and the TASKS.md read rule in builder.md and spec-writer.md. reviewer-rules/approver never read TASKS.md whole, so no rule added there.

## Acceptance criteria
1. [x] Only .claude/ files changed: `git diff --name-only origin/main...HEAD` lists only .claude/ paths.
2. [x] Only builder is opus: `grep -c "^model: opus" .claude/agents/*.md` gives 1 for builder, 0 for others.
3. [x] `git diff --check` clean; head -80 no longer in SKILL.md.

## Validation
Commands above, all passed. Tree clean after commit.

## Log
### Round 1
Implemented as above.
