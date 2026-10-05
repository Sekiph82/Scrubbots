# M43 — COMPLETE MILESTONE MASTER RESUME V02

Status: **READY FOR CLAUDE**
Date: 2026-10-05
Repository: `Sekiph82/Scrubbots`
Local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Branch: `main`
Canonical tracker: root `TASKS.md` — READ ONLY for Claude

This is a continuation of:
`coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

The prior master run stopped only because the Claude usage limit was reached. It did **not** reach final M43 handoff.

## 0. VERIFIED REMOTE STATE

At resume issuance:
- canonical remote `main` = `a217122a5336d050b0b99b1389408b0041e82e8d`;
- `coordination/sessions/M43-MASTER-V01/logs/` contains 55 pushed child logs;
- pushed work currently reaches through C007R;
- no final `M43_MASTER_CLAUDE_LOG_V01.md` exists yet;
- root `TASKS.md` remains ChatGPT-owned.

Do not rewrite or squash pushed M43 master history merely to make the batch prettier.

## 1. CRITICAL FIRST ACTION — PRESERVE THE UNCOMMITTED ROBOTS WIP

The previous run stopped during M43-C008 Robots.

Known uncommitted master-WIP paths on the Desktop checkout:

- new: `scripts/ui/robots/robots_screen.gd`
- edited: `scripts/app/main.gd`
- edited: `scripts/ui/home/home_screen.gd`
- edited: `scripts/ui/results_screen.gd`
- edited: `scripts/ui/popup/acquisition_flow.gd`
- edited: `scripts/ui/gameplay_screen.gd`
- edited: `scripts/gameplay/runtime/production_gameplay_host.gd`
- edited: `scripts/economy/economy_services.gd`

The prior run also left owner-local files intentionally unstaged, including:
- `project.godot`
- `scenes/app/main.tscn`
- local `addons/`
- owner-review `.tscn` metadata changes
- unrelated untracked files such as `tests/_m55_diag_tmp.gd`

### Before any sync or edit

1. Run `git status --short`.
2. Capture `git diff --name-status`.
3. Inspect the actual diff of every known Robots WIP path.
4. Separate:
   - **M43 master Robots WIP** listed above;
   - **owner-local/unrelated work**.
5. Preserve both classes.
6. Run `git fetch origin main --prune`.
7. Compare local HEAD with `origin/main`.
8. Reconcile non-destructively.

Do **not** reset/checkout/clean away the Robots WIP.

If remote `main` advanced after `a217122a...`, integrate safely around the WIP. If there is a real conflict that cannot be resolved without risking owner work, STOP and report the exact files.

## 2. RESUME POINT

Resume at:

**M43-C008 — Robots Destination**
**SB-M43-102..111**

The previous run reports the Robots lane is partially edited but uncommitted and only one Home suite was run. Treat it as incomplete work, not accepted implementation.

### First objective

Finish and validate the existing Robots WIP rather than starting over.

Specifically:
- inspect the current partial implementation;
- remove any broken/incomplete branch or stale placeholder logic;
- verify canonical 10-robot roster;
- verify unlock/locked order, Bot Parts N/250 and overflow;
- verify canonical perk display truth without implying solver power;
- verify active robot selection/equip persistence;
- verify locked-robot detail;
- verify active robot presentation binding across the intended surfaces;
- verify no BoardState/TargetSelector/routing/solver/batch mutation;
- verify unlock history / NEW badge semantics;
- verify mobile-scale fallback behavior.

The prior run suspected one failing M42 assertion only because it pinned ROBOTS as disabled. Do not blindly change the test.

First prove whether that assertion is genuinely stale under the now-canonical M43 requirement:
- if yes, update it to test the original safety/product intent rather than the old placeholder-disabled state;
- if no, fix production instead.

Never weaken a regression just to make it pass.

Create missing child logs for **SB-M43-102 through SB-M43-111**, run the lane checkpoint, commit/push the Robots lane, then continue.

## 3. DO NOT AUDIT / REIMPLEMENT ALREADY PUSHED CHILDREN

The following pushed lanes already have child logs and should not be reimplemented unless a regression forces a targeted fix:

- SB-M43-013
- SB-M43-068..074 except 075/077
- SB-M43-R05-001..002
- SB-M43-C005F-001..015 logs already exist with mixed READY/BLOCKED/DEFERRED status
- SB-M43-078..101
- SB-M43-R07-001..006

Preserve their pushed history.

If a resumed lane exposes a genuine regression in one of them:
- fix it narrowly;
- add a follow-up note to that existing child log or create a clearly named continuation note;
- do not rewrite prior commits.

## 4. KNOWN PARTIAL MASTER STATUS FROM PRIOR RUN

Use these as navigation facts, not audit acceptance:

### C005 / Results
READY candidates:
- 013
- 068
- 069
- 070
- 071
- 074

BLOCKED:
- 072 — M44 feature pacing authority missing
- 073 — world-range authority missing

Still to revisit later:
- 075
- 077

### C005R
READY candidates:
- R05-001
- R05-002

### C005F
READY candidates:
- C005F-002
- C005F-014

BLOCKED:
- C005F-001 — canonical plugin intake requires owner-approved repository intake of local addon/project changes

DEFERRED:
- C005F-003..013
- C005F-015

Do not bind plugin feel to shipping call sites before C005F-001 authority is resolved.

### C006 Shop
READY candidates:
- 078
- 080
- 081
- 082
- 083
- 085
- 086
- 087
- 089

BLOCKED:
- 079 — visual master / owner gate
- 084 — M57 real-money/provider authority
- 088 — provider/restore portion depends on M57

### C007 Collection
READY candidates:
- 090
- 092
- 093
- 094
- 095
- 096
- 097
- 099
- 100
- 101

BLOCKED:
- 091 — visual master / owner gate
- 098 — canonical closed regression currently says earned packs open immediately, so pack-inventory policy requires authority before changing semantics

### C007R
READY candidates:
- R07-001
- R07-004
- R07-005

BLOCKED:
- R07-002 — guarantee threshold tuning authority missing
- R07-003 — fallback authority missing
- R07-006 — M56 simulation / First Collection Sprint owner tuning missing

These statuses remain **un-audited by ChatGPT** until the master finishes.

## 5. CONTINUE THE REST OF M43 WITHOUT WAITING

After C008 Robots is safely completed, continue the entire original M43 master automatically.

Remaining major lanes include:
- C009 Tasks / Daily / Gift Bar
- C009R Daily Scrub Orders / earned ScrubBox
- C010 BottomNav / Profile / Achievements / Events / Ranks
- C010R Weekly Event / First-Try / Personal Best
- C011 Worlds
- C012 Comeback / Notifications
- C012R Catch-Up / notification prioritization
- C013 Account / Cloud
- C014 meta audio / haptics / offline / error
- C015 final player-facing visual inventory gate

Also revisit deferred:
- SB-M43-075
- SB-M43-077
- SB-M43-013 dependencies if later ceremony work changes their readiness
- C005F children only if C005F-001 authority becomes resolved during this run
- world-dependent ceremony work if C011 owner authority becomes available

Do not stop after one lane.

## 6. EXPECTED OWNER / EXTERNAL GATES STILL DO NOT STOP THE MASTER

Continue the original policy:

If a child is blocked by OWNER, M44, M56, M57, M58, world ranges/art, ranks scoring policy, provider/platform strategy or another explicit external authority:

1. never invent the missing truth;
2. implement safe prerequisites only;
3. write the child log as `BLOCKED_AWAITING_AUTHORITY`;
4. defer strict dependents;
5. continue independent M43 work.

Only stop the whole master for:
- unsafe git reconciliation;
- canonical authority contradiction/corruption;
- an unresolved regression that makes continuation unsafe;
- no runnable child remaining.

## 7. PER-CHILD LOG / COMMIT POLICY

Continue using:

`coordination/sessions/M43-MASTER-V01/logs/<TASK_ID>_CLAUDE_LOG_V01.md`

For every new attempted child:
- exact requirement;
- sync preflight;
- baseline/final SHA;
- files changed;
- authority sources;
- tests/results;
- evidence;
- blocker state.

Do not edit root `TASKS.md`.

Prefer one child commit where practical. If a tightly coupled lane must share one implementation commit, child logs must still separately prove each canonical requirement and point to the exact shared SHA. Do not fabricate per-child commits after the fact.

## 8. CHECKPOINTS

At each lane boundary:
- affected focused suites;
- all touched closed-M43 regressions;
- relevant M39/M40/M42/M54/M55 authority suites;
- `git diff --check`.

For shared architecture/economy/save/navigation changes:
- run root `tests/run_tests.gd`.

Before final handoff:
- run final runnable-state root suite;
- ensure no unexplained script/runtime errors;
- ensure owner-local files remain unstaged/uncommitted.

## 9. FINAL HANDOFF

Only when all currently runnable M43 children have been attempted, create:

`coordination/sessions/M43-MASTER-V01/M43_MASTER_CLAUDE_LOG_V01.md`

It must cover the full original master catalog, including work from the first run and this resume.

For each child:
- READY_FOR_INDEPENDENT_AUDIT
- BLOCKED_AWAITING_AUTHORITY
- DEFERRED_DEPENDENCY
- NOT_REACHED_STOP_RULE

Report:
- final HEAD;
- total counts;
- child log paths;
- final root/regression results;
- all remaining owner/external decisions;
- any local owner files intentionally left untouched.

Do not edit root TASKS.md.

Finish exactly:

`AWAITING_GPT_M43_MASTER_V01_INDEPENDENT_AUDIT`
