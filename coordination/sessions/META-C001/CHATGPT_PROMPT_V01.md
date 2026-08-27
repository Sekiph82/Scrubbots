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
baselineCommit: c384e14fb3cbc4c3201e683a88988f8e48868fc8
---

# META-C001 — GitHub Coordination System Setup

## Owner request

Re-inspect `Sekiph82/Scrubbots` and establish a repository-native tracking and communication system where:

1. ChatGPT stores the implementation prompts it gives Claude.
2. ChatGPT stores evidence-based audits after Claude work.
3. Claude stores a durable GitHub implementation log for code written from those prompts/audits.
4. The H!veAI Project Dashboard tracks these coordination artifacts.
5. After every material ChatGPT or Claude session, a concise session summary is refreshed in the Project Dashboard.
6. Existing `tasks.md` task truth and the existing local Desktop phase-log workflow must remain coherent rather than being replaced by competing ledgers.

## Execution mode

This is a process-only META cycle. ChatGPT is implementing the repository documentation/coordination infrastructure directly through GitHub. No Claude gameplay/code implementation is requested in this cycle, so no `CLAUDE_IMPLEMENTATION_LOG.md` is required for META-C001.

## Required result

- Add a durable coordination protocol.
- Add an append-only session index.
- Add templates for ChatGPT prompts, ChatGPT audits, and Claude implementation logs.
- Add this setup cycle as the first indexed coordination record.
- Update `CLAUDE.md` so Claude participates in the protocol while keeping the existing Desktop phase log.
- Upgrade `.hiveai/PROJECT_DASHBOARD.md` from a pointer-only manifest into a source map plus agent-maintained latest-session summary without duplicating `tasks.md` task checkboxes.
- Document the system in `CHANGELOG.md`.
- Use a focused branch/PR and preserve main until reviewed/merged.

## Non-goals

- No gameplay code changes.
- No task checkbox changes in `tasks.md`.
- No DIRTY/CLEAN design decision.
- No M07 artwork ingestion.
- No secrets or local log contents committed.
