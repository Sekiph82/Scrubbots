# Factory dashboard + owner-answer flow

> Feature: FACTORY-DASHBOARD — commit the factory dashboard and the owner-answer flow (owner request in chat 2026-10-22: "answer owner questions from the dashboard").

## Context
- Factory loop rules: `.claude/skills/factory/SKILL.md` (sections "/factory next", "Merge", "Escalate"). `CLAUDE.md` §0D.4/§0D.5: root `TASKS.md` is the only tracker; undecidable owner questions are ONE line each under `## Questions for Şekip` (TASKS.md line ~115), and queue rows in `## Autonomous Queue` use `- READY|OWNER|DONE <TASK-ID> — <one line>`.
- `.gitignore` already ignores `/factory/jobs/` (runtime state). `factory/` does not exist on `origin/main`.
- Working, uncommitted sources in the owner's Desktop checkout (the source of truth for this job; read-only for the builder):
  - `C:/Users/sekip/Desktop/ScrubBots/factory/server.py` — stdlib `ThreadingHTTPServer` on `127.0.0.1:8765` (port 8000 is taken by a local Godot MCP server) serving `factory/`. `GET /questions` returns `{"questions": [...], "answers": "<answers.md text>"}`, where `questions()` runs `git show origin/main:TASKS.md` and collects `- ` lines under the `## Questions for…` heading until the next `## ` heading. `POST /answer` `{"question","answer"}` appends `- [YYYY-MM-DDTHH:MM] Q: <q>\n  A: <a>\n` (whitespace-collapsed) to `factory/answers.md`.
  - `C:/Users/sekip/Desktop/ScrubBots/factory/dashboard.html` — kanban of `jobs/*/job.json` by stage (polled every 2 s via the http.server directory listing), job file viewer, and a "Questions for Şekip" panel with a textarea + Send per question; a question shows as answered when `answers` contains `"Q: " + <question>`.
  - `C:/Users/sekip/Desktop/ScrubBots/factory/answers.md` — real owner answer(s) already exist there; it must never be committed.
- Known defects in the source to fix: the question parser is fused with the `git` call (not testable without git); `POST /answer` with a non-JSON body raises inside the handler instead of returning 400.
- Merge section today runs `git rebase origin/main` directly; the one-time `--import` in step 2 of "/factory <task>" modifies tracked `project.godot` in the worktree, so the rebase refuses ("cannot rebase: You have unstaged changes").
- No Python test runner exists in the repo; the self-check is a plain script with `assert`s.

## Requirements
1. Add `factory/server.py` and `factory/dashboard.html` to the worktree, copied from the Desktop sources above. Do not modify, move or delete anything in the Desktop checkout.
2. In `factory/server.py`, split the parser into a pure function `parse_questions(text: str) -> list[str]` (same rules as today: `- ` lines under a heading starting `## Questions for`, ending at the next `## ` heading, leading `- ` stripped and whitespace-trimmed, HTML comments and other lines ignored). `questions()` calls `git show origin/main:TASKS.md` and returns `parse_questions(...)`. Importing `server` must not start the server or run git.
3. `POST /answer` with a body that is not a JSON object returns HTTP 400 (no traceback, nothing written). Keep the 20000-byte limit, 127.0.0.1 bind, port 8765 and the answers.md entry format unchanged (the dashboard's "answered" check depends on `Q: <question>`).
4. Add `factory/test_server.py`: stdlib only, runnable as `python factory/test_server.py` from the repo root (and from `factory/`), asserting at least: (a) a sample TASKS.md text with lines before, inside and after `## Questions for Şekip` yields exactly the inside `- ` lines, in order, without the `- ` prefix; (b) the `<!-- ... -->` comment line is excluded; (c) a text with no Questions heading yields `[]`; (d) an empty Questions block followed by another `## ` section yields `[]`; (e) parsing the worktree's real `TASKS.md` yields a list whose every item is non-empty. Prints `PASS test_server` and exits 0 on success; a failed assert exits non-zero.
5. `.gitignore`: add `/factory/answers.md` under the existing "Factory loop runtime state" block.
6. `.claude/skills/factory/SKILL.md`:
   a. Add a `## Dashboard` section: start with `python factory/server.py` from the owner checkout (`<repo>`), open `http://127.0.0.1:8765/dashboard.html`; it shows jobs by stage and the `## Questions for Şekip` lines from `origin/main`; Send appends to `<repo>/factory/answers.md` (gitignored, local only).
   b. In `## /factory next`, add a step before taking the first READY row: read `<repo>/factory/answers.md`. If it has entries, the next job is "apply owner answers" (builder edits only `TASKS.md`): for each answer, record the decision in the relevant place in TASKS.md (the matching task item(s)), remove that question's line from `## Questions for Şekip`, and flip the matching `## Autonomous Queue` `OWNER` row(s) to `READY` with the decision in the line. After that job merges, the orchestrator deletes exactly the applied entries from `answers.md` (entries added meanwhile stay).
   c. In `### Merge`, before `git fetch origin && git rebase origin/main`, restore the tracked files the Godot import modified in the worktree: `git checkout -- project.godot` (and any other tracked file `git status --short` shows as modified that the job did not intend to change), with a one-line reason (the import dirties `project.godot` and rebase refuses with unstaged changes). Untracked `.uid` import output is left alone.
7. No game code, scenes, tests under `tests/`, data or `project.godot` changes are committed. `TASKS.md` is not changed by this job.

## Acceptance criteria
1. `cd <worktree> && python factory/test_server.py` prints `PASS test_server` and exits 0; `cd <worktree>/factory && python test_server.py` does the same.
2. Breaking the parser (e.g. temporarily making `parse_questions` return `[]`) makes `python factory/test_server.py` exit non-zero (reviewer may verify by inspection that assertion (a) checks exact list equality).
3. `python -c "import sys; sys.path.insert(0,'factory'); import server; print(server.parse_questions('## Questions for Şekip\n<!-- c -->\n- a\n- b\n## X\n- c'))"` from the worktree prints `['a', 'b']` and returns immediately (no server started).
4. Live check from the worktree: start `python factory/server.py` in the background; `curl -s http://127.0.0.1:8765/questions` returns JSON with a `questions` list equal to the `- ` lines under `## Questions for Şekip` in `git show origin/main:TASKS.md`; `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8765/dashboard.html` prints `200`; `curl -s -o /dev/null -w "%{http_code}" -X POST -d "notjson" http://127.0.0.1:8765/answer` prints `400`; a valid POST `{"question":"Q1","answer":"A1"}` returns `{"ok": true}` and appends `- [<stamp>] Q: Q1\n  A: A1` to the worktree's `factory/answers.md`. Kill the server and delete that test `answers.md` afterwards.
5. `cd <worktree> && git check-ignore factory/answers.md` prints `factory/answers.md`; `git ls-files factory` lists exactly `factory/dashboard.html`, `factory/server.py`, `factory/test_server.py`.
6. `.claude/skills/factory/SKILL.md` contains a `## Dashboard` section with `python factory/server.py` and `http://127.0.0.1:8765/dashboard.html`.
7. The `## /factory next` section of SKILL.md contains a step, ordered before taking the first READY row, that reads `factory/answers.md` and describes all three TASKS.md edits (record decision, remove question line, flip OWNER row(s) to READY with the decision) and the post-merge removal of applied entries.
8. In SKILL.md `### Merge`, a `git checkout -- project.godot` (restore of import-modified tracked files) line appears before the `git rebase origin/main` line.
9. `git diff --name-only origin/main...HEAD` (excluding the later evidence commit) lists only `.gitignore`, `.claude/skills/factory/SKILL.md`, `factory/dashboard.html`, `factory/server.py`, `factory/test_server.py`. `git diff --check origin/main...HEAD` is clean.
10. The Desktop checkout files `C:/Users/sekip/Desktop/ScrubBots/factory/{server.py,dashboard.html,answers.md}` are unchanged by the job (same content as before the build).

## Out of scope
- Applying the existing answer in the Desktop `answers.md` (SB-M51-005 languages) to TASKS.md — that is the next job's work under the new step.
- Any edit to `TASKS.md`, `AGENTS.md`, `CLAUDE.md`, game code, Godot tests, CI workflows.
- Auth, HTTPS, non-localhost binding, configurable port, websockets, a JS framework, a Python test framework, or a dashboard redesign.
- Automating answers.md cleanup inside server.py.

## Assumptions
- `/factory/answers.md` is ignored with a root-anchored pattern, matching the existing `/factory/jobs/` entry.
- The dashboard is not a "parallel project-status tracker" forbidden by TASKS.md line 3: it only displays factory runtime state and TASKS.md lines, writes nothing tracked; TASKS.md stays the only tracker.
- No AGENTS.md change is required: SKILL.md is the factory's documentation and AGENTS.md already defers to CLAUDE.md §0D.
- Use `127.0.0.1` rather than `localhost` in the documented URL, because the server binds IPv4 only and `localhost` can resolve to IPv6 first on Windows.
- The answers-apply job matches an answer to a queue row by the task IDs at the start of the question line (questions are written as `<TASK-IDs> — <question>`).
