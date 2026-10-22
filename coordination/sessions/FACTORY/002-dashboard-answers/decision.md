APPROVE

## Why
The change is factory tooling only: a localhost dashboard server with a pure, tested question parser, the dashboard page, a gitignore entry for local owner answers, and SKILL.md steps for applying answers and restoring project.godot before the rebase. It needs no owner action under §0D. All three factory reviewers (the skill defines rules, code and tests, so there is no fourth) gave PASS, and none of their Notes describes a real defect. `git merge-tree --write-tree origin/main factory/002-dashboard-answers` exits 0 with no conflicts.

## Acceptance criteria
1. test_server.py passes from the repo root and from factory/: met. I re-ran it both ways and got `PASS test_server`.
2. A broken parser fails the test: met. Assertion (a) uses exact list equality, and build.md reports a mutation that returned rc=1.
3. Importing server neither starts the server nor runs git: met. I read the diff: serve_forever is only under `__main__`, and git only runs inside `questions()`.
4. POST /answer returns 400 for a non-JSON-object body, and the limit, bind, port and entry format are unchanged: met. I read the diff, and build.md has a live harness run on port 8766 that checked 400, 400 and ok.
5. answers.md is gitignored and git ls-files factory lists exactly 3 files: met. I confirmed `git check-ignore` myself.
6. SKILL.md has a Dashboard section with the command and the 127.0.0.1:8765 URL: met, from the diff.
7. The owner-answers step comes before the READY-row step and covers all three TASKS.md edits plus the cleanup after merge: met, from the diff.
8. `git checkout -- project.godot` comes before the rebase in Merge: met, from the diff.
9. Only the 5 allowed files change and diff --check is clean: met. `git diff --stat` shows exactly those 5 files.
10. The Desktop sources are unchanged: met. The server.py and dashboard.html md5 hashes match build.md, and dashboard.html is byte-identical to the committed copy. Desktop answers.md has changed since the build, but the change is a second real owner answer written at 11:26 through the owner's own 8765 server, not test data from the job. The harness only wrote inside the worktree.

## For the human
Nothing to do.
