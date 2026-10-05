# M43 — COMPLETE MILESTONE MASTER EXECUTION PROMPT V01

Status: **READY FOR CLAUDE**
Date: 2026-10-05
Repository: `Sekiph82/Scrubbots`
Local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Branch: `main`
Canonical tracker: root `TASKS.md` — READ ONLY for Claude
Open M43 children at issuance: **146**

## OWNER WORKFLOW CHANGE

Do **not** execute M43 as one ChatGPT handoff per task.

This prompt is the one and only Claude handoff for the remaining M43 milestone. Read every unchecked `SB-M43-...` row inside the M43 section of root `TASKS.md` and execute the entire milestone continuously, subject only to dependency and authority gates below.

Closed M43 rows stay closed. SB-M43-067 has final owner visual acceptance and is not part of this run.

## ABSOLUTE FIRST ACTION

Before any work:

1. Work only from `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git fetch origin main --prune`.
3. Compare local execution checkout with latest `origin/main`.
4. Synchronize non-destructively.
5. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty files and unrelated untracked work.
6. Never destructive-reset, clean or overwrite owner work.
7. If safe sync is impossible, STOP the whole master and report exact conflicting paths.

Then read:
- `CLAUDE.md`
- root `TASKS.md` READ ONLY
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- all prior M43 ChatGPT audits and OWNER acceptance files relevant to touched surfaces
- current shipping source/tests/config/assets for each child before implementation

## CANONICAL CHILD PROMPT RULE

For every unchecked M43 task, the exact root `TASKS.md` row is the canonical child requirement.

Before EACH child task:
1. fetch/sync latest `origin/main` non-destructively again;
2. reread that exact TASKS row and its parent Sprint section;
3. inspect the current repository instead of assuming APIs/paths/state;
4. implement only that child and the minimum shared seams it genuinely requires;
5. run focused tests and impacted regressions;
6. write a separate child log;
7. commit + push the child;
8. continue automatically to the next runnable M43 child.

Do not wait for another ChatGPT prompt after a child completes.

## PER-CHILD LOG

Every attempted child must create exactly one log:

`coordination/sessions/M43-MASTER-V01/logs/<TASK_ID>_CLAUDE_LOG_V01.md`

The log must record:
- child id + exact TASKS requirement;
- sync preflight;
- starting SHA / final SHA;
- files changed;
- authority sources/config/owner decisions used;
- focused tests + exact results;
- regressions;
- runtime evidence paths for player-facing work;
- blockers/gates;
- one final state:
  - `READY_FOR_INDEPENDENT_AUDIT — <TASK_ID>`
  - `BLOCKED_AWAITING_AUTHORITY — <TASK_ID>`
  - `DEFERRED_DEPENDENCY — <TASK_ID>`

Claude must not claim ChatGPT audit PASS or OWNER PASS.

## COMMON CHILD AUDIT CONTRACT

Every implemented child must satisfy all applicable items:

- exact TASKS requirement implemented without silently broadening scope;
- existing owner decisions, config and authoritative services are the only truth sources;
- no UI becomes an unauthorized economy/progression/save authority;
- no new currency, reward, probability, world range, ranking metric, unlock level, product/provider rule, robot rule or perk is invented;
- positive canonical path tested;
- boundary/failure/error/offline/stale state tested where applicable;
- rapid-tap/duplicate callback/retry/reopen/reload is idempotent where applicable;
- persisted/imported economic state fails closed where applicable;
- Reduced Effects preserves information/truth for player-facing work;
- real runtime evidence exists for meaningful player-facing work;
- owner visual gates are never self-approved;
- CLOSED M43 surfaces touched by shared changes pass regression;
- shared/authority changes run root `tests/run_tests.gd`;
- `git diff --check` clean;
- no unexplained script/runtime errors;
- root `TASKS.md` untouched by Claude.

## M43 LANE AUTHORITY LOCKS

### Results / SB-M43-013
Results reward receipt, Continue and exactly-once authority are frozen. Bind downstream ceremonies only after the corresponding ceremony exists and only after core Results reward commit succeeds.

### M43-C005 Ceremonies
Use the already OWNER-approved C001 ceremony visual masters. Presentation never grants. Exact set rewards come from config; Master is +2500 SB +20 Bot Parts exactly once. Robot truth comes from canonical roster/services. Gift milestones remain 10/50/250/500/1000. Never invent world ranges or feature pacing.

### M43-C005R Gift micro-progress
Pure presentation only. Intermediate ticks mint no reward and are not claimable. One GiftMeterService-derived normalized model across Home/Results/Gift Bar.

### M43-C005F GameFeelFlow + Saltmire Spark
Canonicalize exact installed addon/API/license state before shipping calls. Plugins are presentation-only and fail-open through one adapter. Preserve the TASKS intensity ladder MICRO/SMALL/REWARD/MAJOR_REWARD/WIN/MAJOR_UNLOCK. Respect Reduced Effects. Camera shake, freeze frame, time scale, pause, physics/collider/velocity authority, screen-wide/strobing flash and plugin-owned economy/gameplay/navigation truth remain prohibited.

### M43-C006 Shop
One SB economy only. Hearts/boosters/2x use existing services. Real-money product cards, No Ads, localized cash price, restore and provider logic remain gated by M57. Preserve exact return context.

### M43-C007 Collection / Exchange
15 sets × 9 cards = 135 canonical cards. First copy protected. EXTRAS are copies above 1. Cards Exchange stays inside Collection. Values: Common 25 / Rare 75 / Epic 200 / Legendary 500 SB. Pack inventory/open entry routes through closed M43-C005/C008 pack authorities.

### M43-C007R Pity
Earned-pack only, data-driven, transparent, non-purchasable, no paid acceleration/reroll. Preserve Premium Rare-or-better and atomic pack commit.

### M43-C008 Robots
Canonical 10-robot roster. Scrubby starts unlocked; later robots cost 250 Bot Parts. Perks are meta only. Selecting/equipping never mutates BoardState, TargetSelector, routing, solver or batch legality.

### M43-C009 + C009R
Exactly three tasks/day with 75/100/125 SB. Daily is canonical repeating 5-day truth. Gift claim/history is exactly-once and non-recursive. Daily Scrub Orders are deterministic ordinary-play tasks. Earned ScrubBox is never sold. Future surprise slot remains disabled until M56 + owner approval.

### M43-C010 + C010R
No dead BottomNav. Preserve M41 Settings. Events use no new event currency. RANKS scoring/ranking policy cannot be invented. Weekly/First-Try use ordinary progression without paid continue/replay farming. Personal Best is self-comparison only; no asynchronous social.

### M43-C011 Worlds
World 01 Whispering Park remains current default. Future ranges/conditions/art require owner authority before hardcoding/activation. World presentation never changes level solver/difficulty truth.

### M43-C012 + C012R
Comeback/notifications are factual, opt-in, quiet-hours aware, non-punitive and anti-spam. Catch-Up never restores missed Daily/event rewards. Notification priority/dedup and proactive cap remain authoritative.

### M43-C013 Cloud / Account
Local save remains authoritative/offline-capable. Sign-in provider strategy requires owner/platform decision before SDKs. Preserve M40 schema and idempotent economy transaction ids. Purchase restore remains M57-gated. Privacy/account requirements remain M58-gated.

### M43-C014 Audio / Haptics / Error
Obey Master/Music/SFX/Haptics immediately. Never imply purchase/ad/reward success before authoritative callback. Final cross-screen sound/haptic feel requires owner acceptance.

### M43-C015 Final visual inventory
Run last. M43 cannot close while any required surface is missing, visually unreviewed, dummy-bound or debug-only.

## DEPENDENCY-AWARE SCHEDULING

Use TASKS order as baseline, but correct for real dependencies:

- SB-M43-067 is already CLOSED.
- C005 Set/Master/Robot/Gift ceremonies must exist before SB-M43-013 Results handoff.
- SB-M43-075 may be deferred until C009 Daily/Tasks authority exists.
- SB-M43-073 and SB-M43-140 must never invent world-range authority.
- C005F binds only surfaces that already exist; C005F-015 is a late end-to-end gate.
- C009R follows C009.
- C010R follows C010.
- C012R follows C012.
- C015 runs last.
- Revisit deferred tasks once prerequisites are attempted.

## EXPECTED OWNER / EXTERNAL GATES DO NOT STOP THE MILESTONE

M43 intentionally contains tasks gated by OWNER, M44, M56, M57, M58, world authority, RANKS policy and provider/platform decisions.

When such authority is genuinely missing:
1. do not invent it;
2. implement every safe prerequisite/shell/interface/test allowed without fabricating truth;
3. child log = `BLOCKED_AWAITING_AUTHORITY`;
4. defer strict dependent tasks;
5. continue other independent M43 tasks.

A normal owner/external gate does NOT stop the whole master.

## WHOLE-MASTER STOP RULES

Stop only if:
- safe git sync is impossible without damaging owner work;
- repository/canonical authority is contradictory or corrupted;
- current-child regression cannot be safely isolated/remediated and makes continuation unsafe;
- a missing production dependency contaminates every remaining runnable lane;
- no runnable child remains and all remaining work is honestly blocked.

Otherwise continue.

## OWNER VISUAL GATES

Claude may generate candidate masters, harnesses and runtime evidence, but may not self-approve. If a task explicitly needs owner approval, publish the candidate/evidence, log the gate, skip dependent production binding and continue independent lanes.

## FINAL MILESTONE HANDOFF

When all currently runnable M43 children have been attempted, create:

`coordination/sessions/M43-MASTER-V01/M43_MASTER_CLAUDE_LOG_V01.md`

This is an execution handoff, not a tracker.

It must list every unchecked-M43 child from this run as:
- READY_FOR_INDEPENDENT_AUDIT
- BLOCKED_AWAITING_AUTHORITY
- DEFERRED_DEPENDENCY
- NOT_REACHED_STOP_RULE

Report:
- final HEAD;
- counts by status;
- each child log path;
- lane regression summaries;
- final root suite;
- every remaining owner/external decision;
- exact reason for any deferred/not-reached child.

Do NOT edit root TASKS.md.

Finish exactly:

`AWAITING_GPT_M43_MASTER_V01_INDEPENDENT_AUDIT`
