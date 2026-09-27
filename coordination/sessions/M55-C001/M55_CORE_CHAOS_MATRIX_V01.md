# M55-C001 — CORE CHAOS MATRIX V01

Status: implementer evidence, AWAITING_CHATGPT_AUDIT (no verdict claimed)
Date: 2026-09-28
Build: Godot 4.7.2.stable.official.ed1daf0bf, headless, `main` after `3beaaf1`
Scope: SB-M55-001..017 plus the Heart 900 s reconciliation. SB-M55-018..024 are out of scope (M43+ surfaces).

## Suites (every run: exit code, `FAIL:`, `SCRIPT ERROR` and engine `ERROR:` lines checked)

| Suite | Rows | Result |
|---|---|---|
| `tests/m55_heart_900_authority.gd` | Step 0 | exit 0, 19 ok, 0 FAIL, 0 SCRIPT ERROR |
| `tests/m55_core_chaos.gd` | 001–007, 014–017 | exit 0, **128 ok**, 0 FAIL, 0 SCRIPT ERROR; case ledger complete (12/12) |
| `tests/m55_long_session.gd` | 008–013 | exit 0, 39 ok, 0 FAIL, 0 SCRIPT ERROR; case ledger complete (6/6) |
| `tests/m55_economy_release_regression.gd` | 010 fix | exit 0, 11 ok. **Sensitivity:** with the fix removed it exits 1 with 3 FAIL |

Fixtures:
- **Production content:** Levels 1–10 LevelData, owner supply plans and intended clicks. Level 1 uses the historical M23 generator path and is played greedily.
- **Stripe fixture:** one QA-only `TEST` board written to `user://` by the suite. It is 20×20 with five 4-wide stripes and 20 batches, and any placement order solves it.
- **Clock:** an injected deterministic wall clock is used for Hearts/2x (production `HeartService`/`SpeedEntitlementService` accept it).

## Step 0 — Heart 900 s reconciliation: PASS

**Active references reconciled to 900 s / 15 min:**

| File | Change |
|---|---|
| `data/config/player_experience_plan_v1.json` | `regen_minutes_per_heart` 30 → 15 |
| `docs/MASTER_UI_SYSTEM.md` | Home Heart counter 30-minute → 15-minute (900 s) |
| `README.md` | Hearts line 30 → 15 real-world minutes |
| `scripts/economy/README.md` | `heart_service.gd` description 30 → 15 minutes |

**Already at 900 and unchanged:** `economy_rewards_v1.json` `hearts.regen_seconds`, `HeartService`, `docs/01_GAMEPLAY_SPEC.md`, `docs/06_TEST_STRATEGY.md`, and `tests/m39b_hearts_speed.gd`.

**Historical owner/session files keep their superseded 30-minute text as provenance.** These are `OWNER_ECONOMY_REWARDS_V01.md` §Hearts, `OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md` §4, the M39/M42/M54 session logs and audits, and the ChatGPT-owned `TASKS.md`.

**Drift guard — `m55_heart_900_authority.gd` checks:**
- runtime config = 900; max 5; +1 Heart = 500 SB; refill = 400 SB per missing Heart;
- `HeartService`: 899 s → still 4 Hearts, 900 s → 5;
- planning config = 15 minutes;
- 9 active docs contain no unsuperseded 30-minute/1800 s Heart claim;
- timed 2x products are still exactly 900/300, 1800/500, 3600/750;
- the Home full-Heart pill shows `15:00`.

## Rows

| Row | Verdict | Production path exercised | Repetitions / duration | Evidence (direct assertions) |
|---|---|---|---|---|
| SB-M55-001 spam all five slots | **PASS** | `ProductionInputController.activate_front` → M23/M24 → runtime ticks | **Fixture:** every frame, 3 taps × 3 columns plus 2 invalid columns, 3,930 frames. **Level 2:** 1,036 frames, 1 s ticks | 0 invalid accepts; accepted taps == supply batches consumed (20 / 36); capacity and transaction cardinalities coherent on **every** frame; WON exactly once; 400 / 1,024 cells each cleared exactly once; 30 post-WON taps rejected as `terminal` with nothing consumed; no agent/reservation/claim left |
| SB-M55-002 restart while bots travel | **PASS** | host `retry()` (M30 transaction-safe Retry) with ≥ 3 agents moving | 4 cycles on Level 2 + 1 fixture completion | No assignment, claim, reservation, work, draining or agent survives; board fully ACTIVE and supply == exact owner queues; one Heart per post-action restart, 0 for an immediate pre-action restart; 300 frames later no ghost dispatch or clear; tree nodes 109 → 109 across cycles; cancelled agent nodes freed after one frame; after an in-flight restart the fixture completes WON with 400 unique clears |
| SB-M55-003 pause while bots travel | **PASS** | `ProductionRuntimeController.set_user_paused` | 600 paused frames + 1,800 taps + 100 rapid toggles | Agent positions, board and assignments frozen while paused; all 1,800 taps refused as `paused`; supply untouched; afterwards WON once with 400 unique clears |
| SB-M55-004 background while bots travel | **PASS** | OS `NOTIFICATION_APPLICATION_PAUSED/RESUMED/FOCUS_OUT/IN` through the SceneTree | 600 background frames + 600 taps + 40 focus flips | Suspended, frozen and every tap refused; resume clears only the system suspension (an explicit user pause survives); WON once, 400 unique clears |
| SB-M55-005 complete with bots in flight | **PASS** | Level 1 production run to supply exhaustion | Supply exhausted with **11** assignments still in flight | Never terminal while cells were ACTIVE or agents moving; WON exactly once after the last arrival; 400 cells cleared once each; 300 post-WON frames + taps grant no extra SB, reward tx or terminal |
| SB-M55-006 exhaust color | **PASS** | four C01 batches placed on the fixture | ~40 k frames max | Exactly C01's 80 cells cleared; no slot, draining record, candidate or new assignment for C01 afterwards; Tornado on the exhausted colour refused (`color_not_present`) and its charge kept; the other colours complete WON |
| SB-M55-007 exhaust slot work | **PASS** | M24 early release (R02) under continuous placement | Up to 60 k frames | A released slot was refilled **15** times while its old batch still had robots in flight; capacity and cardinalities coherent on every frame; WON, 400 unique clears |
| SB-M55-008 repeated scene transitions | **PASS** | real `main.tscn`: `NavigationController`, Home, `play_current_frontier`, `handle_back`, Settings | **40 cycles**. Each: Settings open, double-open refused, close; PLAY; same-frame second PLAY; pre-action back | Every cycle: exactly one `GameplayHost`, the second PLAY rejected (`not_home`), back → HOME, exactly 2 route changes. 0 Hearts and 0 streak spent. After warm-up (cycle 5 → 40): nodes 167 → 167, orphans 0 → 0, Objects 2192 → 2192, static memory +141 KB (≤ 4 MiB), listeners constant (route 2, settings 1, effects 0) |
| SB-M55-009 long high-load session | **PASS** | Home → Gameplay → Results → Continue, Levels 1..10 back-to-back, owner clicks | **2 laps × 10 levels = 20 levels WON**, 20,202 clears, 21,222 simulated 1 s frames, 324 s wall | All levels WON in one app session per lap; frontier advances to 11 (CONTENT_MISSING, so Continue after L10 is correctly refused) |
| SB-M55-010 memory growth monitoring | **PASS after fix** | same session, sampled at every Home return | Lap-2 end vs lap-1 end (steady state) | **Defect found and fixed (F-M55-01).** Post-fix steady state: Objects +34 (≤ 64; exactly 2 discarded `AppState` graphs of the test, see log), static memory +430 KB (≤ 4 MiB), nodes and orphans equal. Lap-1 growth over the empty-Home baseline (+11.4 MB static, +19 Objects) is one-time content caching of 10 distinct levels: the same level played 10× post-fix changes static memory by only +27 KB and Objects by 0 |
| SB-M55-011 duplicate signal monitoring | **PASS** | `authenticated_clear`, `terminal_reached`, `route_changed`, `settings_changed`, `effects.changed` | 20 levels + 40 transition cycles | Per level: exactly one RESULTS route and one clear event per cell (0 duplicates). A re-emitted `terminal_reached`, a re-run host terminal handler and a re-committed `FirstClearTransaction` add 0 routes, 0 SB and 0 tx. Long-lived listener counts return exactly to baseline after 10 hosts per lap |
| SB-M55-012 orphan Node monitoring | **PASS** | `Performance.OBJECT_ORPHAN_NODE_COUNT` + tree node count | 40 transition cycles + 20 levels | Orphans 0 at every sample; Home tree node count returns exactly to 167 after each lap; 0 `GameplayHost` at Home |
| SB-M55-013 duplicate reward monitoring | **PASS** | `FirstClearTransaction` via the host terminal; `RewardGrantService` | 20 WON; for each: re-emitted terminal, re-run handler, re-commit, 10 same-frame Continue taps | Each WON: SB == `first_clear_sb(class) + win_streak_sb(position)`, reward tx grew, Bot Parts grew, streak +1. All duplicate paths add 0 SB and 0 tx; exactly one next host per 10 Continue taps. A save reload shows the identical SB and reward-tx set |
| SB-M55-014 booster spam | **PASS** | `ProductionActionFacade` (+1 Slot, Selector, Random, Tornado, current-level/timed 2x) and the 2x popup buttons | 30× +1 Slot, 30× Selector (same batch), 30× Random, 10× Tornado, 3 charged Tornados, 20 speed-button taps, 20 direct 2x re-buys | +1 Slot once (capacity 6, never 7) and charged once (500 SB); Selector extracts once; every Random either commits and charges or refuses as `not_solver_safe`; Tornado commits once per colour; charges consumed 3 = 3 with 0 SB; global SB ledger exact (spent 12,250); current-level 2x charged once, 20 re-buys refused (`already_entitled`) |
| SB-M55-015 background across 900 s Heart regen + timed 2x | **PASS** (+ owner gate F-M55-02) | `HeartService` / `SpeedEntitlementService` on the injected wall clock, background notification, save flush, relaunch | Background +899 / +900 / +2,700 s; rollback −5,000 s; closed-app relaunch at 899 / 900 s | 899 s → 3 Hearts with 1 s left; 900 s → exactly +1 and the next interval restarts at 900; timed 2x independent (1,800 s remain) and expired by wall clock at +2,700 s; Hearts capped at 5; a −5,000 s rollback gains or loses no Heart; relaunch after 899 s → 4, after 900 s → 5 |
| SB-M55-016 Tornado with matching agents in flight | **PASS** | `ProductionActionFacade.tornado` during runtime travel | **Level 2:** 5 same-colour agents in flight. **Mixed fixture (added in this takeover):** 1 target-colour + 2 other-colour assignments in flight | One charge, 0 SB; all ACTIVE cells of the colour purged atomically; no same-colour assignment survives and no batch of it remains in supply; cardinalities coherent; 600 frames with no ghost clear. **Mixed:** every other-colour assignment owner unchanged, and those agents still arrive and clear. Both attempts reach exactly one terminal (WON) with no duplicate clear |
| SB-M55-017 Cards Exchange-all repeated taps | **PASS** | `ProductionActionFacade.exchange_all_extras` + relaunch | 25 taps, then relaunch + 10 taps | One exchange and 24 `nothing_to_exchange`; SB credited once (+2,825), one reward tx; every owned card keeps its protected first copy and unowned cards are untouched; after relaunch, one exchange of the 2 new extras (+50) with the protected copy kept |

## Findings

| ID | Severity | Finding | Status |
|---|---|---|---|
| **F-M55-01** | Production defect (memory growth) | Each durable save leaked a whole `EconomyServices` graph: 16 services + 1 `RandomNumberGenerator`, about 200 KB. `SaveService.validate_candidate` dry-runs the economy import in a scratch `EconomyServices` (twice per save), and the reward handler lambdas registered by `EconomyServices` and `RewardGrantService` capture their own graph, so every discarded graph was a reference cycle. Measured before the fix: **+17 Objects per played level**, +342 Objects / +15.3 MB over the 10-level session, and +2,041 Objects over 60 saves. A no-AppState host leaked its private fallback graph the same way. | **FIXED** in the owning economy/save subsystem: `RewardGrantService.release_handlers()`, `EconomyServices.dispose()`, `SaveService` disposes its scratch graph on every path, and a host disposes only its own fallback graph on delete. Regression `tests/m55_economy_release_regression.gd` (post-fix: +1 over 60 saves, 0 over 30 rejected validations, 0 over 8 hosts; with the fix removed: +2,041 / +510 / +102, FAIL). Save validation semantics and the canonical `AppState` handlers are unchanged (asserted). |
| **F-M55-02** | Owner decision | **Timed 2x has no clock-rollback rule.** After a −5,000 s device-clock rollback, an expired timed 2x shows 5,000 s remaining again, because `SpeedEntitlementService` expiry is an absolute wall-clock timestamp. Owner rules require rollback safety for Hearts (satisfied) and Daily claims, but none covers timed 2x. | **OWNER_REQUIRED.** Decide whether timed 2x should fail closed on backwards time (for example with a saved highest-seen timestamp). Not implemented; no policy invented. Row 015 itself passes. |

## Content lock

No change to Levels 1–10 art, LevelData, owner supply plans or intended clicks, difficulty models/classes/targets, or solution/batch automation. The M52 owner-plan, M53-C001 and M53-C002 suites all pass.
