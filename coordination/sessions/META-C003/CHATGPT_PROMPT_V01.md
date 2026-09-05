---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-prompt
cycleId: META-C003
version: 1
createdAt: 2026-09-05T15:50:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V01.md
triggerAudit: META-C002/CHATGPT_AUDIT_V05.md
pr: 3
sourceBranch: feature/master-ui-magnific-pipeline
targetBranch: main
---

# SCRUBBOTS - META-C003 PR #3 Merge & Canonical Main Reconciliation V01

## FIRST ACTION — synchronize before all other work

Repository:
`C:\Users\sekip\Desktop\ScrubBots`

Start on:
`feature/master-ui-magnific-pipeline` / PR #3.

Fetch origin and safely synchronize the local feature branch with its remote
while preserving all owner work.

Also fetch `origin/main`.

Do not use reset --hard, clean -fd, force push, rebase, destructive checkout,
or any command that deletes/stages unrelated owner work.

Do not create any Desktop/local handoff log.

Preserve the two known repo-local untracked paths unless their current identity
has changed:

- Claude scratch temp path;
- `docs/logs/` historical owner work.

Unknown untracked paths must fail closed: preserve them and record them.

## Read first

1. META-C002 final audit:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V05.md
2. META-C003 criteria:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C003/CHATGPT_AUDIT_CRITERIA_V01.md
3. META-C002 V05 log:
   https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CLAUDE_LOG_V05.md
4. CLAUDE.md
5. coordination/VERSIONED_LOG_POLICY.md
6. coordination/AUDIT_INDEX.md
7. current PR #3 body/state
8. tasks.md
9. inventory/manifest/UI architecture sources
10. SESSION_INDEX and H!ve tracking

Apply AL-025.

## Objective

Merge the independently accepted PR #3 into canonical `main`, then prove the
merged repository preserves task truth, tests, visual-reference truth and
coordination truth.

Do not start M13 in this cycle.

## Phase A — pre-merge evidence on feature branch

Create:

`coordination/sessions/META-C003/CLAUDE_LOG_V01.md`

at the start of material work.

Before any merge action, record individually:

1. local branch;
2. local feature HEAD full SHA;
3. origin feature full SHA;
4. origin/main full SHA;
5. full `git status --short`;
6. classification of every untracked repo-local path;
7. META-C002 V05 AUDITED_PASS visible;
8. PR #3 draft/open/unmerged state;
9. PR #3 current body truth;
10. PR #3 mergeability;
11. 943 unique canonical SB IDs;
12. 196 completed IDs;
13. exactly 95 feature-only UI/Magnific IDs relative to current main;
14. no completed current-main task regressed;
15. 51 inbox image paths == 51 inventory records;
16. Scrubby remains OWNER_REQUIRED;
17. no M08 production-art overclaim;
18. no broad/final Magnific output;
19. `godot --version`;
20. root project verification helper;
21. root headless boot;
22. full feature-branch Godot regression suite;
23. `git diff --check`;
24. exact intended pre-merge changed files.

### Pre-merge log commit

Commit/push the initial META-C003 `CLAUDE_LOG_V01.md` to the feature branch
so the log is included in PR #3.

This pre-merge commit may contain only:

- META-C003/CLAUDE_LOG_V01.md;
- coordination state needed to show META-C003 merge-in-progress, if necessary.

Do not change tasks/inventory/manifest/UI implementation.

After that push:

- verify the new feature head;
- verify PR #3 includes META-C003 log;
- re-query PR mergeability.

## Phase B — merge PR #3

Only if Phase A passes:

1. mark PR #3 ready for review;
2. re-query that it is open, unmerged and mergeable;
3. merge PR #3 into `main` using a **normal merge commit**.

Do not squash.
Do not rebase.
Do not force.
Do not delete the feature branch.

Record:

- exact pre-merge main SHA;
- exact feature head merged;
- exact GitHub merge commit SHA;
- both merge parents;
- PR mergedAt/state.

If normal merge is blocked, stop as `BLOCKED`; do not improvise history.

## Phase C — canonical main verification

After successful merge:

1. fetch origin;
2. safely switch to local `main` while preserving untracked owner work;
3. safely synchronize local main with `origin/main`;
4. record exact main merge head;
5. verify the merge contains the feature head from Phase B.

On merged main independently re-run/verify:

6. `godot --version`;
7. root project verification helper;
8. root headless boot;
9. full Godot regression suite;
10. exactly 943 unique canonical SB task IDs;
11. exactly 196 complete;
12. exactly 747 remaining;
13. exactly 95 migrated UI/Magnific task IDs relative to the pre-merge main;
14. no previously completed main task regressed;
15. 51 inbox image files == 51 inventory records;
16. SHA/dimension/provenance inventory still valid structurally;
17. canonical gameplay/Home/popup references still recorded;
18. Scrubby master remains OWNER_REQUIRED;
19. M08 production-art tasks remain conservative;
20. M12 remains AUDITED_PASS;
21. no broad/final Magnific output;
22. no Higgsfield dependency;
23. no M13/LF00/CP00 implementation.

## Phase D — canonical main reconciliation commit

On main, append the merge/post-merge evidence to the same:

`coordination/sessions/META-C003/CLAUDE_LOG_V01.md`

Then update canonical main tracking:

- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md only if the merge requires a factual reference
  update, never change ChatGPT verdicts
- .hiveai/ACTIVE_CYCLES.md
- .hiveai/ARTIFACT_MAP.md
- .hiveai/PROGRESS_SNAPSHOT.md
- .hiveai/PROJECT_DASHBOARD.md

Required state:

- META-C002 = AUDITED_PASS
- META-C003 = AWAITING_AUDIT
- canonical main progress = 196/943 = 20.78%
- main game + SB-UI = 196/719 = 27.26%
- LF = 0/112
- CP = 0/112
- M13 = NOT_STARTED
- Scrubby master = OWNER_REQUIRED

Create one focused **post-merge reconciliation commit** on main and push it
safely without force.

After this push, do not edit/commit the log again.

## Phase E — POST-MERGE RECEIPT

After the final main push, query the real remote state.

Post exactly one new comment on merged PR #3 headed:

`## META-C003 V01 POST-MERGE RECEIPT`

The comment must contain:

- pre-merge main full SHA;
- merged feature full SHA;
- GitHub merge commit full SHA;
- final post-merge reconciliation commit full SHA;
- exact final `origin/main` full SHA;
- proof final origin/main == reconciliation commit;
- PR mergedAt and merged state;
- full final `git status --short`;
- classification/reminder for all remaining untracked repo-local paths;
- final task truth 196/943;
- full merged-main regression result;
- confirmation Scrubby remains OWNER_REQUIRED;
- confirmation no M13/LF00/CP00/Magnific generation occurred;
- confirmation feature branch was not deleted;
- confirmation no commit was created after the receipt-proven main head.

Do not create another commit after posting the receipt.

## Stop

Set META-C003 to `AWAITING_AUDIT` and stop.

Do not delete the feature branch.
Do not start M13.
Do not generate Magnific assets.
Do not create or modify CHATGPT_AUDIT files.
