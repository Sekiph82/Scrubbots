from pathlib import Path
import re

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

def replace_line(prefix: str, new_line: str) -> None:
    global s
    pattern = re.compile(rf'(?m)^{re.escape(prefix)}.*$')
    s2, n = pattern.subn(new_line, s, count=1)
    if n != 1:
        raise SystemExit(f'expected one status line for {prefix!r}, got {n}')
    s = s2

replace_line('- Current Milestone:', '- Current Milestone: M24')
replace_line('- Current Sprint:', '- Current Sprint: M24-C001 V02 — Five-Slot placement transaction serialization hardening')
replace_line('- Current Task:', '- Current Task: M24-C001-V02')
replace_line('- Current Task Status:', '- Current Task Status: CHANGES_REQUIRED')
replace_line('- Next Task/Action:', '- Next Task/Action: Claude executes `coordination/sessions/M24-C001/CHATGPT_PROMPT_V02.md` under `coordination/sessions/M24-C001/CHATGPT_AUDIT_CRITERIA_V02.md`, closes all findings in `coordination/sessions/M24-C001/CHATGPT_AUDIT_V01.md`, preserves accepted M24 V01 ordinary behavior and all M23/M22 gameplay contracts, pushes implementation first, then `CLAUDE_LOG_V02.md` separately, and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.')
replace_line('- Required Actor:', '- Required Actor: CLAUDE')

# M24 remains fully open until strict V02 closure.
start = s.find('### M24 — Five-Slot Batch Engine')
end = s.find('### M25 — Batch Target Claim Engine', start)
if start < 0 or end < 0:
    raise SystemExit('could not locate M24/M25 boundaries')
section = s[start:end]
if re.search(r'(?m)^- \[x\] SB-M24-', section):
    raise SystemExit('unexpected completed M24 task before V02 closure')
if len(re.findall(r'(?m)^- \[ \] SB-M24-', section)) != 30:
    raise SystemExit('expected exactly 30 open M24 tasks')

p.write_text(s, encoding='utf-8')
