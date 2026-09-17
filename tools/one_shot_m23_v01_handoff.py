from pathlib import Path

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

repls = {
    '- Current Task Status: READY': '- Current Task Status: IN_PROGRESS',
    '- Required Actor: CHATGPT': '- Required Actor: CLAUDE',
    '- Next Task/Action: ChatGPT prepares the strict M23-C001 V01 implementation prompt and audit criteria for the owner-locked Batch Supply Engine. Claude then implements only M23, preserving the accepted M22 Railroad V1/V07 routing, ReservationState, TargetSelector, dispatcher and authenticated clearing contracts. Root `TASKS.md` remains ChatGPT-write-owned.': '- Next Task/Action: Claude executes `coordination/sessions/M23-C001/CHATGPT_PROMPT_V01.md` under `coordination/sessions/M23-C001/CHATGPT_AUDIT_CRITERIA_V01.md` and `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`, implements only M23 Batch Supply Engine, pushes implementation first, then `CLAUDE_LOG_V01.md` separately, and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.'
}

for old, new in repls.items():
    if old not in s:
        raise SystemExit(f'missing expected tracker text: {old}')
    s = s.replace(old, new, 1)

p.write_text(s, encoding='utf-8')
