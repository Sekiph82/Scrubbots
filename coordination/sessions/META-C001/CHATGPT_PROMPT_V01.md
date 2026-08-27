---
coordinationSchema: scrubbots-coordination/v1
artifactType: chatgpt-prompt
cycleId: META-C001
version: 1
createdAt: 2026-08-27T11:09:00+03:00
actor: CHATGPT
status: RECORDED
milestone: META
taskRefs: []
baselineCommit: d7a701941cdfb7f6f326673be8516087bb1a981a
---

# META-C001 — GitHub Coordination System Setup

## Owner request

Re-inspect `Sekiph82/Scrubbots` and establish a repository-native tracking and communication system where:

1. ChatGPT stores the implementation prompts it gives Claude.
2. ChatGPT stores evidence-based audits after Claude work.
3. Claude stores a durable GitHub implementation log for code written from those prompts/audits.
4. The H!veAI Project Dashboard reflects these coordination artifacts.
5. After every material ChatGPT or Claude session, a concise session summary is refreshed in the Project Dashboard.
6. Existing `tasks.md` task truth and the existing local Desktop phase-log workflow must remain coherent rather than being replaced by competing ledgers.
7. The existing `single-dashboard-watch` H!veAI model and Akilta attribution on `main` must be preserved.

## Execution mode

This is a process-only META cycle. ChatGPT is implementing the repository documentation/coordination infrastructure directly through GitHub. No Claude gameplay/code implementation is requested in this cycle, so no `CLAUDE_IMPLEMENTATION_LOG.md` is required for META-C001.

## Required result

- Add a durable coordination protocol.
- Add an append-only session index.
- Add templates for ChatGPT prompts, ChatGPT audits, and Claude implementation logs.
- Add this setup cycle as the first indexed coordination record.
- Update `CLAUDE.md` so Claude participates in the protocol while keeping the existing Desktop phase log.
- Extend `.hiveai/PROJECT_DASHBOARD.md` so ChatGPT/Claude materialize the latest coordination summary into the single H!veAI-watched dashboard after each material session.
- Keep `tasks.md` as the only canonical task ledger.
- Document the system in `CHANGELOG.md`.
- Use a focused branch/PR and preserve unrelated `main` changes.

## Non-goals

- No gameplay code changes.
- No task checkbox changes in `tasks.md`.
- No DIRTY/CLEAN design decision.
- No M07 artwork ingestion.
- No secrets or local log contents committed.
