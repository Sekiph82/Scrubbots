# M43-C005F-PHASE4-QA-R01 — Long-Session Baseline Hygiene + MetaRewardFeel Await Safety — CLAUDE REMEDIATION PROMPT V01

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-09

## Objective

Close the only strict Phase 4 blocker identified by:

`coordination/sessions/M43-C005F-PHASE4/CHATGPT_INDEPENDENT_AUDIT_V01.md`

Phase 4 product code `F010/F012` is technically accepted.

The remaining QA debt is:

1. `tests/m55_long_session.gd` falsely treats first-use/lazy UI warm-up as a leak;
2. baseline and Phase 4 both emit:
   `Resumed function '_play()' after await, but class instance is gone`
   from `scripts/ui/feel/meta_reward_feel.gd`.

This is a QA/lifecycle-hygiene remediation.

Do NOT redesign Phase 4 feel.
Do NOT change Results/Home visual hierarchy or effect intensity unless a real leak is independently proven.

Root `TASKS.md` is READ-ONLY for Claude.

---

# GATE 0 — OWNER DESKTOP SAFETY

Before implementation:

1. Record persistent Desktop:
   - HEAD
   - origin/main
   - ahead/behind
   - tracked dirty files
   - untracked count
   - stashes/worktrees
   - SHA-256 of owner `project.godot`
2. Run:
   `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin`
3. Non-destructively reconcile Desktop to exact current origin/main.
4. Preserve every owner-local file.
5. Never run against Desktop:
   - `git checkout -- <file>`
   - `git restore <file>`
   - `git reset --hard`
   - `git clean`
   - destructive stash/pop
   - force checkout/rebase/push
6. TEMP worktree only after Gate 0.
7. Every TEMP command uses absolute:
   - `git -C "<TEMP>" ...`
   - `godot --path "<TEMP>" ...`
8. TEMP creation failure = STOP. Never fall back to Desktop.
9. Final Desktop must be synced to final origin/main and owner `project.godot` hash unchanged.

---

# READ FIRST

- root `TASKS.md`
- `coordination/sessions/M43-C005F-PHASE4/CHATGPT_INDEPENDENT_AUDIT_V01.md`
- `coordination/sessions/M43-C005F-PHASE4/M43_C005F_PHASE4_AUDIT_CRITERIA_V01.md`
- `coordination/sessions/M43-C005F-PHASE4/M43_C005F_PHASE4_CLAUDE_LOG_V01.md`
- `tests/m55_long_session.gd`
- `scripts/ui/feel/meta_reward_feel.gd`
- `scripts/ui/feel/home_micro_feel.gd`
- `scripts/ui/feel/feedback_adapter.gd`
- historical M55 C001 audit and builder evidence

Inspect the actual current code before changing anything.

---

# PART A — M55 LONG-SESSION BASELINE HYGIENE

## Current defect

The current test does:

1. pre-action transition churn;
2. treats that empty/never-used Home state as the memory/node baseline;
3. runs the first real Levels 1..10 session;
4. requires Home Node count to return exactly to the pre-use state;
5. requires Object drift <=64 against that pre-use state.

Current app architecture now lazily materializes legitimate presentation/UI/plugin first-use state during the first real 10-level session.

Observed on untouched pre-Phase4 baseline:

- Home Nodes: 219 -> 254 on lap 1;
- Object drift ~157 on lap 1;
- lap 2 Home Nodes == lap 1 end;
- lap 2 Object drift = 58;
- orphan count stable;
- static memory steady-state stable.

Therefore the first-lap rule is stale.

## Required correction

Treat the FIRST real 10-level lap as explicit **warm-up / first-use materialization** for Node/Object/static-memory baselining.

Then enforce strict leak bounds on the next same-workload lap.

Preferred shape:

- pre-action transition churn remains and retains its own exact post-warmup stability assertions;
- lap 1 remains a full real production Levels 1..10 run and still verifies:
  - 10/10 WON;
  - exact progression;
  - exact reward/idempotency;
  - exactly one Results transition;
  - zero duplicate reward/route;
  - zero GameplayHost at Home;
  - zero orphan accumulation;
  - authority listeners stable;
- lap 1 records Node/Object/static-memory first-use delta as WARM-UP EVIDENCE rather than failing solely because the app has lazily created persistent presentation structures;
- lap 2 uses lap-1 end as the steady-state baseline and MUST enforce:
  - exact Home Node count equality;
  - orphan count non-growth;
  - Object drift <= existing `MAX_OBJECT_DRIFT`;
  - static-memory drift <= existing `MAX_STATIC_MEM_DRIFT`;
  - host/root-child/listener stability;
  - full gameplay/reward/idempotency checks again.

Do not weaken second-lap checks.

## Forbidden test fixes

Do NOT:

- increase `MAX_OBJECT_DRIFT`;
- increase `MAX_STATIC_MEM_DRIFT`;
- remove exact node-count equality from steady state;
- remove orphan checks;
- skip lap 2;
- mark FAIL as expected;
- hard-code current numbers 254 / 58;
- add retries until PASS;
- exclude Phase 4 nodes by name;
- suppress engine warnings globally.

The test must still fail on a real per-lap leak.

## Sensitivity

Add or preserve evidence that a hypothetical post-warm-up change would fail.

At minimum the source/test logic must clearly enforce:

- lap2.nodes != lap1.nodes => FAIL;
- lap2.orphans > lap1.orphans => FAIL;
- abs(lap2.objects - lap1.objects) > 64 => FAIL;
- lap2.static_mem - lap1.static_mem > 4 MiB => FAIL.

No “visual inspection only” closure.

---

# PART B — MetaRewardFeel await-after-free lifecycle safety

## Current warning

Current baseline can emit:

`Resumed function '_play()' after await, but class instance is gone`

The source is `MetaRewardFeel._play()`, which awaits up to `SETTLE_FRAMES` on the target tree.

The app/root/popup can be freed while that coroutine is suspended.

This is presentation-only lifecycle debt.

## Required behavior

Eliminate the warning robustly without changing reward/effect authority or owner-accepted visual hierarchy.

The final implementation must preserve:

- same ceremony/action/reward trigger seams;
- same intents;
- same one-shot keys;
- same target selection;
- same max settle frame behavior where a live target remains;
- same FULL/REDUCED policy;
- same grants/navigation/save truth.

## Acceptable implementation patterns

Choose the smallest safe current-API solution after investigation.

Examples:

### Option A — lifetime-safe static/weak runner
Move the async settle loop into a static/helper coroutine that:
- holds only weak references to owner/target where appropriate;
- is not resumed as a method on a freed RefCounted;
- checks target/tree validity after every await;
- updates owner diagnostic log only if owner still exists.

### Option B — explicit strong lifetime during the short settle
If proven by focused tests in Godot 4.7.2, retain a local strong RefCounted reference through the await window so the coordinator cannot die mid-coroutine, while still allowing target disappearance to abort safely.

### Option C — target/tree-owned short-lived helper
A tiny presentation-only helper owned by a live SceneTree/target may run the settle probe and self-remove, provided it:
- creates no persistent node leak;
- owns no authority;
- adds no new long-lived listener.

Do not guess. Prove the chosen pattern under root/popup teardown.

## Forbidden fixes

Do NOT:

- remove the settle wait and reintroduce wrong burst placement;
- catch/suppress the engine error text only;
- keep MetaRewardFeel alive forever;
- add an autoload;
- add durable state;
- delay navigation/reward commits;
- change effect intensity/timing for owner-accepted surfaces unless strictly necessary for lifecycle safety.

---

# PART C — PHASE 4 PRODUCT FREEZE

These Phase 4 shipping behaviors are frozen unless a focused QA test proves a real defect:

- `main.gd` F010 nav-first terminal bridge;
- WON-only SMALL bridge;
- no LOST celebration;
- HomeMicroFeel tracked fields;
- MICRO-only Home feedback;
- 6% native pulse;
- max two serialized Home events;
- no Home Spark;
- Reduced behavior.

No new Phase 4 feature work.

---

# REQUIRED TESTS

## 1. M55 long-session

Run the corrected:

`tests/m55_long_session.gd`

Required:
**PASS / 0 fail**

Run it at least **3 consecutive times**.

Required:
**3/3 PASS**.

No retry substitution. Any failed run means fix and restart the 3-run sequence.

Record for every run:
- lap1 warm-up Node/Object/static-memory delta;
- lap2 vs lap1 Node delta;
- lap2 orphan delta;
- lap2 Object delta;
- lap2 static-memory delta.

## 2. MetaRewardFeel lifecycle

Add a focused permanent regression or extend an appropriate feel/lifecycle suite to prove:

- schedule a reward feel request that enters the settle-await path;
- free/close the popup or app root before the settle loop completes;
- advance enough frames;
- no crash;
- no duplicate dispatch;
- no orphan helper/node/tween;
- authoritative reward/save state unchanged.

Also run an external log scan proving the exact warning text:

`Resumed function '_play()' after await, but class instance is gone`

occurs **0 times**.

## 3. Phase 4 focused

`tests/m43_c005f_phase4_terminal_home_micro.gd`

Required:
**19/19 PASS** or higher if QA-only lifecycle cases are intentionally added.

F010/F012 expected semantics must remain unchanged.

## 4. Phase 3 feel

Run:
- `m43_c005f_phase3_meta_rewards_acquisition`
- Phase1
- Phase2 Results/Pack
- earned-pack R01/R02

All PASS.

---

# REQUIRED FINAL REGRESSION

Run the same Phase 4 required battery with a TRUE clean result:

- focused Phase 4
- Phase1
- Phase2
- Phase3
- Standard/Premium QA-R01
- M30
- M40
- M41
- M42 Home/navigation/safe-area
- M43 Results
- M55 long-session
- M55 economy release regression
- M55 core chaos
- M55 Heart 900
- M55 timed-2x anti-rollback
- CP04
- CP05
- root `tests/run_tests.gd`
- headless import
- headless boot
- `git diff --check`

Final required battery must report **zero failing suite**.

Announced deliberate fault-injection SCRIPT ERROR lines remain acceptable only where the existing test explicitly labels them.

The await-after-free warning is NOT an accepted fault injection and must be absent.

---

# SCOPE

Allowed likely changes:

- `tests/m55_long_session.gd`
- `scripts/ui/feel/meta_reward_feel.gd`
- focused QA test under `tests/`
- QA log

Only if required by verified lifecycle behavior:
- tiny presentation-only helper under `scripts/ui/feel/`.

Do NOT modify:

- economy/reward values;
- Results visual design;
- Home visual layout;
- packs;
- Gift/Daily semantics;
- Remote Content/R2;
- LevelData/supply/VOID;
- Family APK/export;
- Level Factory;
- root TASKS.md.

---

# SOURCE CONTROL / LOG

Builder log:

`coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_CLAUDE_LOG_V01.md`

The log must clearly separate:

1. baseline defect evidence;
2. M55 test-model correction;
3. MetaRewardFeel lifecycle correction;
4. 3/3 long-session stability;
5. final clean Phase 4 battery;
6. owner Desktop final sync proof.

Push normally to `main`.

After push:

- sync persistent Desktop non-destructively to final origin/main;
- verify HEAD == origin/main;
- ahead/behind 0/0;
- owner `project.godot` hash unchanged;
- remove only QA-created TEMP worktrees.

Final state:

`AWAITING_GPT_M43_C005F_PHASE4_QA_R01_REAUDIT`
