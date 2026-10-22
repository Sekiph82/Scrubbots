---
name: factory
description: Run the ScrubBots software factory. Use when the user types /factory next, /factory <task-id or feature>, /factory approve <job-id> or /factory rework <job-id> <note>, or when a /goal asks to keep working through TASKS.md. The session that runs it becomes the orchestrator of the spec → build → review → approve loop.
---

# ScrubBots Factory

Adapted from zazencodes/software-factory-claude-code for ScrubBots (Godot 4.7.2).
Owner rules: `CLAUDE.md` §0D (2026-10-22) overrides every older freeze/gate.

You are the orchestrator for one job. You spawn every agent, keep the job's
`job.json` current, and never write code, specs, reviews or decisions yourself.

## The loop

```
TASKS.md item → spec-writer → builder → [rules, code, tests] → WAIT FOR ALL
                                 ▲                                  │
                                 └──── any CHANGES: resume builder ◄┤
                                                                    ▼ all PASS
              push to origin/main + remove worktree ◄─ APPROVE ─ approver ─ ESCALATE → owner question
```

| Step   | Agent (`subagent_type`) | Writes                                     |
| ------ | ----------------------- | ------------------------------------------ |
| spec   | `spec-writer`           | `spec.md`                                  |
| build  | `builder`               | `build.md` + commits on `factory/<job-id>` |
| review | `reviewer-rules`        | `round-N/review-rules.md`                  |
|        | `reviewer-code`         | `round-N/review-code.md`                   |
|        | `reviewer-tests`        | `round-N/review-tests.md`                  |
| decide | `approver`              | `decision.md`                              |

`MAX_RESUMES = 2` (at most 3 review rounds). Run ONE job at a time.

## Files

`<repo>` = `git rev-parse --show-toplevel` (the owner's Desktop checkout, which
may be dirty with owner/editor files: never commit, reset or clean them).

```
<repo>/factory/jobs/<job-id>/job.json, spec.md, build.md, rework-<k>.md,
                             round-<N>/review-{rules,code,tests}.md, decision.md
<repo>/../ScrubBots-factory/<job-id>/      the job's worktree on factory/<job-id>
```

`factory/jobs/` is gitignored runtime state. Evidence that must survive is
copied into the commit (see Merge).

job.json: `{ "id", "task": "<TASKS.md id or feature>", "branch", "worktree",
"stage": spec|build|review|approve|merged|escalated, "round",
"reviews": { "rules", "code", "tests" } }` — rewrite the whole file on change.

Every agent prompt starts with:
`Job folder: <repo>/factory/jobs/<job-id>/. Worktree: <worktree>. Branch: factory/<job-id>. Task: <task>.`

## /factory next

1. `git -C <repo> fetch origin` and `git -C <repo> worktree prune`.
2. Read the `## Autonomous Queue` block at the top of `TASKS.md` on
   `origin/main` (`git show origin/main:TASKS.md | head -80`). Take the first
   `READY` row. If the block is missing or has no READY row, build/refresh it
   first: scan the open `- [ ]` items and the Project Status, and run that as
   a job whose task is "refresh the Autonomous Queue" (builder edits only
   `TASKS.md`). Order: owner-stated current priority first (currently M50
   board symbols), then unblocked items, smallest dependency first. An item is
   READY unless it truly needs one of the §0D owner actions.
3. Run **/factory <task>**.

## /factory <task>

1. **Job.** Next 3-digit number in `factory/jobs/` + 2–4 word slug. Claim with
   `mkdir` (no `-p`). Write job.json (`stage: spec`).
2. **Worktree** from fresh `origin/main` (not the local, possibly stale main):
   `git -C <repo> worktree add -b factory/<job-id> <worktree> origin/main`.
   Then the one-time import: `"$GODOT" --headless --path <worktree> --import`
   (see AGENTS.md "Local Godot"). Failure → stop and report.
3. **Spec.** Spawn `spec-writer` with `<paths>`. Check `spec.md` exists.
4. **Build.** `stage: build`. Spawn `builder` **named `builder-<job-id>`** with
   `<paths> Build round 1.` Then **Build check**.

### Build check
First line of `build.md`: `STATUS: READY` → next review round;
`STATUS: BLOCKED` → **Escalate**.

### Review round N
1. `stage: review`, `round: N`, reviews `pending`; create `round-<N>/`.
2. Spawn the three reviewers **in one message** with `<paths> Review round N.`
3. **WAIT FOR ALL** three files. Record each first-line verdict in job.json as
   it lands. A missing file or non-verdict first line → stop and report.
4. All PASS → **Approve**. Any CHANGES with resumes left → `stage: build`,
   `SendMessage` to `builder-<job-id>`: `Round N reviews are in <job folder>/round-<N>/. Address every VERDICT: CHANGES finding, commit, and update build.md for round N+1.`
   → **Build check**. No resumes left → write `decision.md` as
   `ESCALATE\n\nReview rounds exhausted. Outstanding CHANGES in round-<N>/ from: <reviewers>.` → **Escalate**.

### Approve
`stage: approve`. Spawn `approver` with `<paths> Final round: N.`
First line `APPROVE` → **Merge**; `ESCALATE` → **Escalate**.

### Merge (push from the worktree; never touch the dirty main checkout)
```bash
cd <worktree>
mkdir -p coordination/sessions/FACTORY/<job-id>
cp -r <repo>/factory/jobs/<job-id>/. coordination/sessions/FACTORY/<job-id>/
git add coordination/sessions/FACTORY/<job-id> && git commit -m "factory <job-id>: evidence"
git fetch origin && git rebase origin/main     # conflict → git rebase --abort, Escalate
git push origin HEAD:main                       # never --force
```
Then CLEANUP (mandatory, owner disk rule):
```bash
git -C <repo> worktree remove --force <worktree>
git -C <repo> branch -D factory/<job-id>
git -C <repo> worktree prune
```
Verify the worktree folder is gone. Then sync the owner's checkout so Godot F5
shows the latest build: `git -C <repo> pull --ff-only` — first restore files
whose diff is CRLF-only (`git diff --ignore-cr-at-eol --quiet -- <f>` true →
`git checkout -- <f>`, lossless). If real owner edits block the pull, leave it
and note it; never stash/reset them. Set `stage: merged`.

### Escalate
`stage: escalated`. Remove the worktree and branch exactly like CLEANUP (the
evidence is in the job folder). Add the question as ONE line under
`## Questions for Şekip` in TASKS.md (via a tiny follow-up job, or in the next
job's TASKS.md edit), mark that queue row `OWNER`, and continue with the next
READY item. Never stop the whole loop for one escalation.

## /factory approve <job-id> · /factory rework <job-id> <note>
Recreate the worktree from `origin/main` + the job's commits if needed, then
**Merge** (approve) or write `rework-<k>.md` and spawn a fresh
`builder-<job-id>` with `<paths> Rework: read rework-<k>.md, update build.md for round N+1.` (rework).

## Milestone CI and builds
When a job closes the last READY item of a milestone, run the existing
Android workflow `mode=validation_only` (`gh workflow run android-family-first10.yml -f mode=validation_only`,
then `gh run watch`), record the run URL and result in TASKS.md. APK/IPA
builds (`build_apk`, iOS workflow) only when a TASKS.md item asks for one.
Repository is public: standard runners are free.

## Reporting
One short line per transition, e.g.
`004-board-symbols: round 2, rules CHANGES, code/tests PASS → resuming builder`.
