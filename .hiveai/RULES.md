# H!veAI GitHub-First Tracking Rules (v3)

Provider-neutral. Applies to every agent (Claude, ChatGPT/Codex, owner tooling)
working on this repository.

## H!veAI core

1. GitHub `origin/main` is the H!veAI project-state authority. Read the tracked
   branch, not local caches or stale trackers.
2. `.hiveai/TASKS.md` is the single operational current-state tracker.
3. Before starting project work, read `.hiveai/TASKS.md`.
4. If current project state changes, update `.hiveai/TASKS.md`.
5. Append one canonical `hiveai-event/v1` row to `.hiveai/EVENTS.jsonl` when
   lifecycle state changes.
6. Commit intended project and tracker changes.
7. Push to `origin/main` before reporting successful project-state completion.
8. If push fails, report: `GITHUB_TRACKING_NOT_SYNCED`.
9. Do not claim H!veAI was updated until the GitHub push succeeded.
10. Do not maintain competing live milestone / current-task / next-action /
    progress state in `CLAUDE.md`, `AGENTS.md`, coordination files, or
    dashboards.
11. Historical project evidence may exist elsewhere but does not override
    `.hiveai/TASKS.md`.
12. Builder self-assessment may not mark independently audited work accepted
    when SCRUBBOTS governance requires independent audit.

### Canonical H!veAI file set

Live H!veAI authority is exactly:

- `.hiveai/PROJECT.json`
- `.hiveai/TASKS.md`
- `.hiveai/RULES.md`
- `.hiveai/EVENTS.jsonl`

`.hiveai/STATE.json`, `.hiveai/HANDOFF.md`, `.hiveai/PROJECT_DASHBOARD.md`,
`.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`,
`.hiveai/PROGRESS_SNAPSHOT.md`, `coordination/SESSION_INDEX.md`, and local
Desktop phase logs are **not** live H!veAI authority. They are removed or
retained (in git history / coordination evidence) as historical evidence only.

### Event schema

`{"schema":"hiveai-event/v1","id":"<uuid>","projectKey":"scrubbots","type":"<type>","actor":"CLAUDE|CHATGPT|OWNER|SYSTEM","timestamp":"<UTC ISO8601>", ...}`

### Workflow states

`IDLE`, `READY_FOR_NEXT_TASK`, `IN_PROGRESS`, `AWAITING_AUDIT`,
`CHANGES_REQUIRED`, `BLOCKED`, `WAITING_OWNER`, `COMPLETE`,
`NEEDS_RECONCILIATION` (last only when authoritative sources genuinely
conflict and cannot be resolved).

## SCRUBBOTS-specific project rules

The full gameplay, architecture, testing, visual, and coordination rules are
NOT duplicated here. They live in:

- `CLAUDE.md` — project operating manual (gameplay rules, owner-locked
  parameters, architecture boundaries, working style).
- `AGENTS.md` — provider-neutral pointer to this contract.
- `docs/` — technical decisions (`05_TECH_DECISIONS.md`), gameplay spec
  (`01_GAMEPLAY_SPEC.md`), architecture (`02_TECH_ARCHITECTURE.md`), roadmap
  (`04_ROADMAP.md`), test strategy (`06_TEST_STRATEGY.md`), UI/asset pipeline.
- `tasks.md` (root) — detailed project roadmap and task history/evidence.
- `coordination/` — versioned ChatGPT↔Claude prompt/audit/log evidence chain.

### SCRUBBOTS governance (preserved)

- Independent audit separation stands: Claude implements + tests + writes
  `CLAUDE_LOG_VNN.md` + safe commit/push + hands off `AWAITING_AUDIT`.
  ChatGPT performs the independent audit and writes `CHATGPT_AUDIT_VNN.md`.
- A task is not `COMPLETE` merely because a builder says implementation is done
  when independent audit is required; use `AWAITING_AUDIT` until the audit
  passes, then `READY_FOR_NEXT_TASK`.
- Never use destructive git operations (`reset --hard`, `clean -fd`, force
  push) without explicit owner permission.
- Preserve pre-existing tracked owner work; fail closed as `BLOCKED` rather than
  overwriting owner intent.
