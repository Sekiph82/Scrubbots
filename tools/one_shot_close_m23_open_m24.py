from pathlib import Path
import re

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

# Project status block: replace only the canonical top-level status fields.
def replace_line(prefix: str, new_line: str) -> None:
    global s
    pattern = re.compile(rf'(?m)^{re.escape(prefix)}.*$')
    s2, n = pattern.subn(new_line, s, count=1)
    if n != 1:
        raise SystemExit(f'expected one status line for {prefix!r}, got {n}')
    s = s2

replace_line('- Current Milestone:', '- Current Milestone: M24')
replace_line('- Current Sprint:', '- Current Sprint: M24-C001 V01 — Five-Slot Batch Engine continuous implementation')
replace_line('- Current Task:', '- Current Task: M24-C001-V01')
replace_line('- Current Task Status:', '- Current Task Status: IN_PROGRESS')
replace_line('- Next Task/Action:', '- Next Task/Action: Claude executes `coordination/sessions/M24-C001/CHATGPT_MASTER_PROMPT_V01.md` under `coordination/sessions/M24-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`, then runs all five M24 work packages in order without intermediate handoff, completes `SB-M24-001..030`, pushes implementation commits, then `CLAUDE_LOG_V01.md` separately and returns `AWAITING_AUDIT`. Root `TASKS.md` remains ChatGPT-write-owned.')
replace_line('- Required Actor:', '- Required Actor: CLAUDE')
replace_line('- Progress:', '- Progress: 378 / 885 = 42.71% (game+ui live scope); lastCompletedTaskId M23-C001-V03. M23 Batch Supply Engine is independently audited PASS at implementation `bc7f03844630377f350e2f13676ca2b8b7328ce7` with root suite `4941/0`; all `SB-M23-001..030` are closed. The 224 Level Factory + Content Platform requirements remain canonical in `Sekiph82/ScrubBots-Level-Factory` and are excluded from this repository\'s live denominator.')

# Close exactly the 30 M23 tasks, and do not touch M24+ checkboxes.
start = s.find('### M23 — Batch Supply Engine')
end = s.find('### M24 — Five-Slot Batch Engine', start)
if start < 0 or end < 0:
    raise SystemExit('could not locate M23/M24 section boundaries')
section = s[start:end]
section2, n = re.subn(r'(?m)^- \[ \] (SB-M23-\d{3}\b)', r'- [x] \1', section)
if n != 30:
    raise SystemExit(f'expected to close exactly 30 M23 tasks, got {n}')
s = s[:start] + section2 + s[end:]

# Verify all M23 task IDs are checked and M24 remains open.
if re.search(r'(?m)^- \[ \] SB-M23-', s):
    raise SystemExit('an M23 task remains open')
if len(re.findall(r'(?m)^- \[x\] SB-M23-', s)) != 30:
    raise SystemExit('M23 checked task count is not 30')
if not re.search(r'(?m)^- \[ \] SB-M24-001\b', s):
    raise SystemExit('M24 task state unexpectedly changed')

p.write_text(s, encoding='utf-8')
