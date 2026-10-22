STATUS: READY

# Build: Factory dashboard + owner-answer flow

## Summary
Commit `abdd8f7e` on `factory/002-dashboard-answers` adds the factory dashboard and the owner-answer flow.
- `factory/server.py`: copied from the Desktop source. The parser is now the pure `parse_questions(text: str) -> list[str]`, and `questions()` = `parse_questions(git show origin/main:TASKS.md)`. `POST /answer` returns 400 for a body that is not a JSON object (bad JSON, invalid UTF-8 or a non-dict). The docstring URL is now 127.0.0.1. The limit, bind, port and entry format are unchanged.
- `factory/dashboard.html`: byte-identical copy of the Desktop source.
- `factory/test_server.py`: new stdlib assert self-check.
- `.gitignore`: added `/factory/answers.md` under "Factory loop runtime state".
- `.claude/skills/factory/SKILL.md`: added a new step 2 "Owner answers first" to `/factory next` (old steps 2/3 are now 3/4), added `git checkout -- project.godot` with its reason in `### Merge` before the fetch/rebase, and added a new `## Dashboard` section.

## Acceptance criteria
1. [x] `python factory/test_server.py` printed `PASS test_server` with rc=0 from the worktree root and also from `factory/`.
2. [x] I swapped the parser body for `return []` (temporary, then restored from a backup). The test failed with an AssertionError on line 20 (assertion (a), exact list equality) and rc=1.
3. [x] The `python -c ... server.parse_questions(...)` one-liner printed `['a', 'b']` and returned at once. The server only starts under `if __name__ == "__main__"`, and git runs only inside `questions()`.
4. [x] Live check, with one deviation: port 8765 was already held by the owner's Desktop `server.py` (PID 22584). I did not kill it, and binding a second server would hijack it, because `allow_reuse_address` permits that on Windows. So a scratchpad harness served the worktree's unmodified `server.Handler` with `directory=server.HERE` on 127.0.0.1:8766. The only difference from `server.py`'s `__main__` is the port. Results:
   - `/questions` returned 10 questions, equal (`True`) to an independent parse of `git show origin/main:TASKS.md`.
   - `dashboard.html` returned `200`.
   - POST `notjson` returned `400`, and so did POST `[1]`. No traceback in the log, and no answers.md was created.
   - The valid POST `{"question":"Q1","answer":"A1"}` returned `{"ok": true}`. The worktree's `factory/answers.md` then contained `- [2026-10-22T11:24] Q: Q1\n  A: A1`.
   - Afterwards I killed the harness (identified by its command line) and deleted the test answers.md and the scratch files.
5. [x] `git check-ignore factory/answers.md` printed `factory/answers.md`. `git ls-files factory` listed exactly `factory/dashboard.html`, `factory/server.py` and `factory/test_server.py`.
6. [x] SKILL.md now has a `## Dashboard` section containing `python factory/server.py` and `http://127.0.0.1:8765/dashboard.html`.
7. [x] Step 2 of `## /factory next` comes before the READY-row step (now 3). It reads `<repo>/factory/answers.md` and covers all three TASKS.md edits (record the decision, remove the question line, flip OWNER rows to READY with the decision) plus the post-merge deletion of exactly the applied entries.
8. [x] In SKILL.md `### Merge`, `git checkout -- project.godot` (line 114) comes before `git fetch origin && git rebase origin/main` (line 117).
9. [x] `git diff --name-only origin/main...HEAD` listed exactly `.claude/skills/factory/SKILL.md`, `.gitignore`, `factory/dashboard.html`, `factory/server.py` and `factory/test_server.py`. `git diff --check origin/main...HEAD` was clean.
10. [x] The Desktop `factory/{server.py,dashboard.html,answers.md}` md5 hashes were the same before and after the build: dfb4da15…, 20016f40… and 0c60bf7d….

## Validation
- `python factory/test_server.py` (root and `factory/`): PASS.
- Mutation check (parser returning `[]`): failed as expected, rc=1.
- Live HTTP check on 8766 via the harness: PASS (details in criterion 4).
- `git diff --check origin/main...HEAD`: clean.
- No Godot suites were run, because no game code, scenes or tests changed.

## Log
### Round 1
- Built everything in a single commit, `abdd8f7e`.
- I did not change TASKS.md, because spec requirement 7 says this job must not change it. That overrides the builder's default TASKS.md update.
- The worktree's `project.godot` modification and the untracked `.uid`/`.import` files come from the orchestrator's `--import`. I left them alone and did not commit them.
