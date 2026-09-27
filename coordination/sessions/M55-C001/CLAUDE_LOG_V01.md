# M55-C001 — CLAUDE LOG V01 — Core Chaos / Long-Run QA + Heart 900 s reconciliation

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict is claimed.
Prompt: `coordination/sessions/M55-C001/task_prompts/SB-M55-C001_CORE_CHAOS_HEART900.md`
Criteria: `coordination/sessions/M55-C001/audit_criteria/SB-M55-C001_CORE_CHAOS_HEART900.md`
Base: `origin/main` `3beaaf1` (local `main` was already up to date).
Root `TASKS.md` is read only and was not edited.
Matrix: `coordination/sessions/M55-C001/M55_CORE_CHAOS_MATRIX_V01.md`

## Result

- **17/17 rows pass** under the current build.
- **One real production defect was found and fixed: SB-M55-010, memory growth.** Each durable save leaked a whole `EconomyServices` graph. The fix is in the owning economy/save subsystem and is covered by a sensitivity regression.
- **One owner decision is surfaced: F-M55-02.** Timed 2x has no clock-rollback rule; a backwards device clock revives an expired timed 2x.
- **Heart 900 s:** active references are reconciled, and a drift guard was added.
- SB-M55-018..024 were not touched.

## Provenance of this cycle's work (takeover disclosure)

When this session started, the working tree already held **uncommitted M55-C001 work-in-progress from another agent session** (timestamps 2026-09-27 19:51–20:05 and 2026-09-28 00:20). A Codex process set was running.

**What was found:**
- the 4 Step-0 edits: `README.md`, `data/config/player_experience_plan_v1.json`, `docs/MASTER_UI_SYSTEM.md`, `scripts/economy/README.md`;
- `tests/m55_heart_900_authority.gd`, `tests/m55_core_chaos.gd`, `tests/m55_long_session.gd`;
- a scratch diagnostic, `tests/_m55_diag_tmp.gd`.

**What happened next:**
1. Before writing anything, I stopped and asked the owner.
2. The owner chose **"I take over"**.
3. I confirmed the other writer had gone quiet (the working tree was unchanged for 60 s).
4. I then read every inherited file in full, ran each suite as-is, and verified each against the production code.

**What was adopted and what changed:**
- **Adopted verbatim:** the 4 Step-0 edits (exactly the owner-ruling reconciliation) and `m55_heart_900_authority.gd`.
- **`m55_core_chaos.gd` strengthened:** SB-M55-016's "other colours untouched" assertion was vacuous (0 other-colour assignments in flight). I added a mixed-colour case where other colours really are in flight. Nothing was weakened.
- **`m55_long_session.gd` completed:**
  - As inherited, it **failed**. Its lap-1 static-memory and Object-count bounds exposed F-M55-01, which is now fixed.
  - After the fix, the Object bound passes (+19 over the whole lap).
  - The remaining lap-1 static growth (+11.4 MB) is one-time content caching of 10 distinct levels. Evidence: the same level played 10× post-fix moves static memory +27 KB and Objects 0.
  - I therefore added a **second full lap in the same process**. The **same pre-declared bounds** (Objects ≤ 64, static ≤ 4 MiB) now apply to lap-2 end vs lap-1 end, which is the steady-state leak check. Lap-1 growth over the empty-Home baseline is printed as warm-up.
  - The bounds themselves were not loosened. The Object bound still applies to lap 1 too.
- **`tests/_m55_diag_tmp.gd`** (the other agent's scratch) is left untracked and not committed.
- The owner's local `project.godot` modification, the untracked opening video and other owner files are untouched and not committed.

## Step 0 — Heart 900 s reconciliation

**Active references reconciled (30 → 15 minutes / 900 s):**

| File | Change |
|---|---|
| `data/config/player_experience_plan_v1.json` | `hearts.regen_minutes_per_heart` 30 → **15** |
| `docs/MASTER_UI_SYSTEM.md` | Home Heart counter semantics → 15-minute (900 s), citing `OWNER_HEART_REGEN_INTERVAL_V01.md` |
| `README.md` | Hearts regeneration line → 15 real-world minutes (900 s) |
| `scripts/economy/README.md` | `heart_service.gd` description → 15-minute (900 s) |

**Unchanged because already canonical:**
- `data/config/economy_rewards_v1.json` `hearts.regen_seconds = 900`;
- `HeartService`;
- `docs/01_GAMEPLAY_SPEC.md` and `docs/06_TEST_STRATEGY.md` (already 900 s, with "was 1800" provenance);
- `tests/m39b_hearts_speed.gd`.

**Not rewritten (historical provenance, superseded by the owner ruling):** `OWNER_ECONOMY_REWARDS_V01.md` §Hearts, `OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md` §4, and the M39/M42/M54 session logs and audits. The ChatGPT-owned `TASKS.md` task line was not edited.

**The 30-minute paid 2x product is unchanged:** products are 900 s / 300 SB, 1800 s / 500 SB, 3600 s / 750 SB (asserted).

**Drift guard:** `tests/m55_heart_900_authority.gd` (19 ok). It covers the runtime config, `EconomyConfig`, `HeartService` 899/900 s behaviour, the planning config, 9 active docs (regex for unsuperseded 30-minute/1800 s Heart claims), the 2x product table, and the Home full-state pill `15:00`.

## F-M55-01 — production defect: EconomyServices graph leaked per durable save (FIXED)

**How it was found:**
- The long-session run gave Objects +342 and static memory +15.3 MB after 10 levels, with 426 ObjectDB instances leaked at exit.
- Bisecting: build-only hosts added 0 per repeat, while a played level added **+17 Objects per attempt regardless of level size**.
- A WeakRef reachability probe over each host's object graph named the survivors: the 16 `EconomyServices` members plus one `RandomNumberGenerator`.

**Root cause:**
- `EconomyServices._register_handlers()` and `RewardGrantService._init()` store handler lambdas that capture their own graph inside `RewardGrantService._handlers`. A discarded graph is therefore a reference cycle that `RefCounted` never frees.
- `SaveService.validate_candidate()` builds a scratch `EconomyServices` for its dry-run import, and it runs twice per durable save (re-read check plus primary check).
- So every terminal, purchase and lifecycle flush leaked about 200 KB.
- The no-AppState host fallback path leaked its private graph the same way.

**Fix** (owning subsystem only; ~38 lines):
- `RewardGrantService.release_handlers()` clears `_handlers`, breaking the cycle.
- `EconomyServices.dispose()` calls it. It is intended only for throw-away graphs.
- `SaveService.validate_candidate()` calls `scratch.dispose()` on every path. The accept/reject result is unchanged.
- `ProductionGameplayHost` gains an `_owns_economy` flag. It is set only when the host built its own fallback graph (no AppState), and the host disposes that graph on `NOTIFICATION_PREDELETE` or on rebuild. The shared `AppState` graph is never disposed.

**Regression** (`tests/m55_economy_release_regression.gd`, 11 ok):
1. After `dispose()`, a dropped graph (services / reward / packs) is freed.
2. 60 validated saves: Objects +1.
3. 30 rejected validations: Objects +0, and they are still rejected as `economy_import`.
4. 8 no-AppState hosts: Objects +0 (bound 4, above the known ±3 engine oscillation).
5. The canonical `AppState` graph still has its handlers after saves: an SB grant and a pack grant both work.

**Sensitivity:** with the two `dispose()` calls removed, the suite **FAILS (3)**: +2,041 Objects over 60 saves, +510 over 30 rejections, +102 over 8 hosts. It passes again with the fix restored.

**Post-fix long session (two laps, steady state):**
- lap-2 end vs lap-1 end: Objects +34 (≤ 64), static memory +430 KB (≤ 4 MiB), nodes 167 = 167, orphans 0.
- The +34 is exactly 2 × 17. It is the two `AppState` graphs the test itself discards: the lap-1 app root and the reload probe.
- In production an `AppState` lives for the whole app process, so this only happens at exit. Those same graphs also account for the remaining "ObjectDB instances leaked at exit" warnings.

## F-M55-02 — owner decision required (not implemented)

- **Observation:** timed 2x expiry is an absolute wall-clock timestamp. After a −5,000 s device-clock rollback, an expired timed 2x shows 5,000 s remaining again.
- **Why it isn't fixed:** owner rules require clock-rollback safety for Hearts (satisfied) and Daily claims (fail closed), but no owner rule covers timed 2x.
- **Decision needed:** should timed 2x fail closed on backwards time (for example, a saved highest-seen timestamp), or remain pure wall-clock?
- Per the stop rule, no policy was invented. SB-M55-015 itself passes.

## Rows

The full per-row evidence is in the matrix. In brief:
- **001–007 and 014–017:** `tests/m55_core_chaos.gd`, 128 ok. It drives the real `ProductionGameplayHost` stack (M23..M27 engines, input/runtime controllers, `ProductionActionFacade`, AppState economy) with an expected-case ledger (12/12).
- **008–013:** `tests/m55_long_session.gd`, 39 ok, case ledger 6/6. It runs through the real `main.tscn`:
  - 40 transition cycles;
  - 2 laps × Levels 1–10 (20 WON, 20,202 clears, 21,222 simulated frames, 324 s wall);
  - Node, orphan, Object, static-memory and listener sampling with fixed bounds;
  - exact reward-ledger checks and duplicate-terminal/Continue injection.

## Regression (Godot 4.7.2.stable.official.ed1daf0bf, headless)

Run in parallel. For every suite I checked the exit code, `FAIL:`, `SCRIPT ERROR` and the engine `ERROR:` classes.

| Suite | Result |
|---|---|
| `m55_heart_900_authority` | exit 0, 19 ok |
| `m55_core_chaos` (strengthened re-run) | exit 0, 128 ok |
| `m55_long_session` | exit 0, 39 ok |
| `m55_economy_release_regression` | exit 0, 11 ok |
| `m39b_hearts_speed` | exit 0, 32 ok |
| `m39c_boosters` / `m39d_daily_collection` / `m39e_full_matrix` | exit 0, 45 / 34 / 21 ok |
| `m39a_economy_core`, `m39_v02_*` (3), `m39_v03_*` (2), `m39_v04_integration`, `m39_v04_tornado_inflight` | all exit 0 (38, 21, 19, 34, 37, 18, 150, 132 ok) |
| `m40_save_system` / `m40_v02_safety` / `m40_v03_canonical` / `m40_v04_bootstrap` | exit 0, 38 / 34 / 21 / 58 ok |
| `m52_owner_supply_plans` / `m52_r01_parallel_runtime` / `m52_r02_early_slot_release` | exit 0, 255 / 79 / 65 ok (9/9 WON through production input; frontier 11 CONTENT_MISSING) |
| `m42_navigation` / `m42_home_v07_safe_area` | exit 0, 82 / 47 ok |
| `m53_first10_difficulty` / `m53_c002_difficulty_calibration` | exit 0, 315 / 214 ok |
| `m54_collection_set_master_exactly_once` | exit 0, 192 ok |
| root `tests/run_tests.gd` | exit 0, **5323 checks, RESULT: ALL PASS**, 0 SCRIPT ERROR, 9 engine `ERROR:` lines (the same corrupt/missing-image fixtures as baseline) |
| `git diff --check` | clean |

Across all 29 suites there are 0 `FAIL:` and 0 `SCRIPT ERROR`. The only engine `ERROR:` classes are:
- "N resources still in use at exit" (pre-existing);
- M52's intentional malformed-JSON loader fixture;
- the root suite's intentional corrupt/nonexistent image fixtures.

No new runtime fault appeared.

## Content lock

No change to:
- Levels 1–10 art or LevelData;
- owner supply plans or intended clicks;
- difficulty models, classes or targets;
- automatic solution/batch-colour work.

## Changed files

| File | Change |
|---|---|
| `README.md`, `data/config/player_experience_plan_v1.json`, `docs/MASTER_UI_SYSTEM.md`, `scripts/economy/README.md` | Step 0 (adopted) |
| `scripts/economy/reward_grant_service.gd` | + `release_handlers()` |
| `scripts/economy/economy_services.gd` | + `dispose()` |
| `scripts/save/save_service.gd` | dispose the dry-run scratch |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | dispose an owned fallback economy |
| `tests/m55_heart_900_authority.gd` | new (adopted) |
| `tests/m55_core_chaos.gd` | new (adopted + strengthened 016) |
| `tests/m55_long_session.gd` | new (adopted + lap-2 steady state) |
| `tests/m55_economy_release_regression.gd` | new |
| `coordination/sessions/M55-C001/M55_CORE_CHAOS_MATRIX_V01.md` | new |
| `coordination/sessions/M55-C001/CLAUDE_LOG_V01.md` | this file |

## Reproduce

```bash
godot --headless --path . -s res://tests/m55_heart_900_authority.gd
godot --headless --path . -s res://tests/m55_core_chaos.gd
godot --headless --path . -s res://tests/m55_long_session.gd
godot --headless --path . -s res://tests/m55_economy_release_regression.gd
```

`AWAITING_CHATGPT_AUDIT / M55-C001 CORE CHAOS LONG-RUN QA`
