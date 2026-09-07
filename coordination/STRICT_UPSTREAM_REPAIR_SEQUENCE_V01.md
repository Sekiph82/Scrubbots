# Strict Upstream Repair Sequence V01

Status: **ACTIVE**

Purpose: repair the strict-v2 upstream chain before M19 is audited.

Canonical order:

1. M15-C001 V02 — AUDITED_PASS
2. M16-C001 V05 — AUDITED_PASS
3. M17-C002 V03 — READY
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
- M16-C001 V02 — **CHANGES_REQUIRED**
  - audit: coordination/sessions/M16-C001/CHATGPT_AUDIT_V02.md
- M16-C001 V03 — **CHANGES_REQUIRED**
  - audit: coordination/sessions/M16-C001/CHATGPT_AUDIT_V03.md
- M16-C001 V04 — **CHANGES_REQUIRED / FINDING_SET_FROZEN**
  - audit: coordination/sessions/M16-C001/CHATGPT_AUDIT_V04.md
- M16-C001 V05 — **AUDITED_PASS**
  - audit: coordination/sessions/M16-C001/CHATGPT_AUDIT_V05.md
- M17-C002 V02 — **SUPERSEDED_BY_V03**
  - old prompt: coordination/sessions/M17-C002/CHATGPT_PROMPT_V02.md
- M17-C002 V03 — **READY**
  - full-surface re-audit: coordination/sessions/M17-C002/CHATGPT_FULL_SURFACE_REAUDIT_V03.md
  - prompt: coordination/sessions/M17-C002/CHATGPT_PROMPT_V03.md
  - criteria: coordination/sessions/M17-C002/CHATGPT_AUDIT_CRITERIA_V03.md

M19-C001 remains IMPLEMENTED_BUT_AUDIT_BLOCKED until all three upstream repair
stages strict-pass and M19 is re-synced/retested against the corrected chain.


## 2026-09-07 audit transition

M15-C001 V02 passed independent ChatGPT audit at implementation head `4b3433731ffc7698aa0aafae3f8a822430a9cbc3`. M16-C001 V02 is now the first READY stage. Separate M10-M14 strict foundation findings are tracked in `coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md` and must be repaired before final M19 strict closure/M20 acceptance.


## M16 V02 audit transition

M16-C001 V02 closed the original finite-coordinate/result-coherence/non-bool findings but strict-v2 independent audit found F-M16-STRICT-004: malformed non-null request/board dependencies can still fault before fail-closed validation. M16-C001 V03 is READY. M17 remains blocked.


## M16 V03 audit transition

V03 closed malformed object-shaped request/board cases, but strict audit found remaining arbitrary-Variant boundary gaps for scalar board/result/access-query inputs. M16-C001 V04 is READY. M17 remains blocked.


## M16 V04 full-surface audit transition

V04 closed its scalar validator-input findings. ChatGPT then performed the owner-requested full subsystem attack-surface sweep before any new correction prompt. The M16 finding set is now frozen to F-M16-STRICT-006/007/008 and consolidated into V05. M17 remains blocked until V05 passes.


## M16 V05 final + M17 full-surface transition

M16-C001 V05 passed final frozen full-surface audit. Before enabling M17 correction, ChatGPT applied the new locked full attack-surface rule to M17, superseded the older unexecuted V02 prompt, froze the complete M17 finding set, and issued M17-C002 V03 as READY.
