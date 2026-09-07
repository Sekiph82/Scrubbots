# Strict Upstream Repair Sequence V01

Status: **ACTIVE**

Purpose: repair the strict-v2 upstream chain before M19 is audited.

Canonical order:

1. M15-C001 V02 — AUDITED_PASS
2. M16-C001 V02 — READY
3. M17-C002 V02
4. M19 re-sync/retest, then its own strict audit flow

M18-C001 V02 is already strict-audited PASS and is not a repair stage.

## Critical execution rule

Do NOT implement all three repair stages in one uninterrupted batch.

Strict Audit Standard v2 requires the upstream correction to be audited before a
dependent stage advances.

On each invocation:

1. sync main safely;
2. execute ONLY the first stage below whose state is READY;
3. write that stage's matching CLAUDE_LOG_V02;
4. commit/push;
5. return AWAITING_AUDIT;
6. STOP.

After ChatGPT audits that stage, ChatGPT will update this sequence so the next
stage becomes READY.

## Stage states

- M15-C001 V02 — **AUDITED_PASS**
  - prompt: coordination/sessions/M15-C001/CHATGPT_PROMPT_V02.md
  - re-audit: coordination/sessions/M15-C001/CHATGPT_STRICT_REAUDIT_V02.md
- M16-C001 V02 — **READY**
  - prompt: coordination/sessions/M16-C001/CHATGPT_PROMPT_V02.md
  - re-audit: coordination/sessions/M16-C001/CHATGPT_STRICT_REAUDIT_V02.md
- M17-C002 V02 — **BLOCKED_BY_M16**
  - prompt: coordination/sessions/M17-C002/CHATGPT_PROMPT_V02.md
  - re-audit: coordination/sessions/M17-C002/CHATGPT_STRICT_REAUDIT_V02.md

M19-C001 remains IMPLEMENTED_BUT_AUDIT_BLOCKED until all three upstream repair
stages strict-pass and M19 is re-synced/retested against the corrected chain.


## 2026-09-07 audit transition

M15-C001 V02 passed independent ChatGPT audit at implementation head `4b3433731ffc7698aa0aafae3f8a822430a9cbc3`. M16-C001 V02 is now the first READY stage. Separate M10-M14 strict foundation findings are tracked in `coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md` and must be repaired before final M19 strict closure/M20 acceptance.
