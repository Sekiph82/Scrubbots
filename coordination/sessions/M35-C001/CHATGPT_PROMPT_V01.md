# M35-C001 V01 — Production Level Catalog Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M35-001..SB-M35-011`

Read:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M35-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- `scripts/data/level_data.gd`
- `scripts/data/level_loader.gd`
- `scripts/data/production_level_validator.gd`
- current `data/levels/` and metadata

## Batch rule
This is part of the owner-authorized M34→M40 overnight implementation batch.
Finish, commit, push and log M35, then continue directly to M36 without waiting for ChatGPT audit.
Do not self-close tasks and do not edit root `TASKS.md`.

## Implement
Create a deterministic production LevelCatalog and its declarative catalog data/manifest as appropriate to current architecture.

Requirements:
- unique stable IDs
- deterministic explicit ordering
- difficulty field compatible with Difficulty V1
- validated width/height read model
- stable preview/reference field with safe missing behavior
- duplicate ID/order/path detection
- missing-file detection
- production/test separation
- hard rejection of TEST fixture entries even if manually referenced
- full batch validation with entry-specific diagnostics
- no arbitrary runtime inclusion of every JSON in `data/levels/`
- no mutation of LevelData source truth from catalog readers

Preserve M21 production compatibility. Do not generate new levels or art.

## Mandatory task logs
Create one separate file for each:
SB-M35-001 through SB-M35-011 under:
`coordination/sessions/M35-C001/task_logs/`.

Each log records requirement, implementation files, direct tests, failure condition, actual result, status, and commit evidence.

Create:
`coordination/sessions/M35-C001/CLAUDE_LOG_V01.md`
that indexes all 11 task logs and records exact prompt/criteria URLs, implementation SHA(s), regression commands/results, known limitations and handoff.

## Git
No destructive cleanup. Preserve owner/untracked work.
Implementation/tests commit(s) first. Evidence/log docs after. Push M35 before starting M36.

Final M35 log handoff:
`AWAITING_AUDIT / M35-C001 V01`

Then continue immediately to M36 via the overnight master prompt.