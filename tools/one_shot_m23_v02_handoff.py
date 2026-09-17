from pathlib import Path

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

repls = {
    '- Current Sprint: M23-C001 V01 — Batch Supply Engine foundation': '- Current Sprint: M23-C001 V02 — Batch Supply transaction and candidate-state hardening',
    '- Current Task: M23-C001-V01': '- Current Task: M23-C001-V02',
    '- Current Task Status: IN_PROGRESS': '- Current Task Status: CHANGES_REQUIRED',
    '- Next Task/Action: Claude executes `coordination/sessions/M23-C001/CHATGPT_PROMPT_V01.md` under `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V01.md` and `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`, implements only M23 Batch Supply Engine, pushes implementation first, then `CLAUDE_LOG_V01.md` separately, and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.': '- Next Task/Action: Claude executes `coordination/sessions/M23-C001/CHATGPT_PROMPT_V02.md` under `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V02.md`, closes all findings in `coordination/sessions/M23-C001/CHATGPT_AUDIT_V01.md`, preserves the accepted V01 architecture and M22 gameplay contracts, pushes implementation first, then `CLAUDE_LOG_V02.md` separately, and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.'
}

for old, new in repls.items():
    if old not in s:
        raise SystemExit(f'missing expected tracker text: {old}')
    s = s.replace(old, new, 1)

p.write_text(s, encoding='utf-8')
