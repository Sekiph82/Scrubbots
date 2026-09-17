from pathlib import Path
import re

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

def replace_line(prefix: str, new_line: str) -> None:
    global s
    pat = re.compile(rf'(?m)^{re.escape(prefix)}.*$')
    s2, n = pat.subn(new_line, s, count=1)
    if n != 1:
        raise SystemExit(f'expected one status line for {prefix!r}, got {n}')
    s = s2

replace_line('- Current Milestone:', '- Current Milestone: M25')
replace_line('- Current Sprint:', '- Current Sprint: M25-C001 V01 — Batch Target Claim Engine continuous implementation')
replace_line('- Current Task:', '- Current Task: M25-C001-V01')
replace_line('- Current Task Status:', '- Current Task Status: IN_PROGRESS')
replace_line('- Next Task/Action:', '- Next Task/Action: Claude executes `coordination/sessions/M25-C001/CHATGPT_MASTER_PROMPT_V01.md` under `coordination/sessions/M25-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`, runs all five M25 work packages in order without intermediate handoff, completes `SB-M25-001..032`, preserves accepted M24/M23/M22 authorities, pushes implementation first, then `CLAUDE_LOG_V01.md` separately and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.')
replace_line('- Required Actor:', '- Required Actor: CLAUDE')
replace_line('- Progress:', '- Progress: 408 / 885 = 46.10% (game+ui live scope); lastCompletedTaskId M24-C001-V02. M24 Five-Slot Batch Engine is independently audited PASS at implementation `808a06fd97ef1a7f271f675767cb9eb6697074b0` with root suite `5090/0`; all `SB-M24-001..030` are closed. M23 Batch Supply Engine remains closed. The 224 Level Factory + Content Platform requirements remain canonical in `Sekiph82/ScrubBots-Level-Factory` and are excluded from this repository\'s live denominator.')

start = s.find('### M24 — Five-Slot Batch Engine')
end = s.find('### M25 — Batch Target Claim Engine', start)
if start < 0 or end < 0:
    raise SystemExit('could not locate M24/M25 section boundaries')
section = s[start:end]
section2, n = re.subn(r'(?m)^- \[ \] (SB-M24-\d{3}\b)', r'- [x] \1', section)
if n != 30:
    raise SystemExit(f'expected to close exactly 30 M24 tasks, got {n}')
s = s[:start] + section2 + s[end:]

if re.search(r'(?m)^- \[ \] SB-M24-', s):
    raise SystemExit('an M24 task remains open')
if len(re.findall(r'(?m)^- \[x\] SB-M24-', s)) != 30:
    raise SystemExit('M24 checked task count is not 30')

m25_start = s.find('### M25 — Batch Target Claim Engine')
m26_start = s.find('### M26 — Auto Dispatch Scheduler', m25_start)
if m25_start < 0 or m26_start < 0:
    raise SystemExit('could not locate M25/M26 boundaries')
m25 = s[m25_start:m26_start]
if len(re.findall(r'(?m)^- \[ \] SB-M25-', m25)) != 32:
    raise SystemExit('expected exactly 32 open M25 tasks')
if re.search(r'(?m)^- \[x\] SB-M25-', m25):
    raise SystemExit('M25 task unexpectedly completed before implementation')

p.write_text(s, encoding='utf-8')
