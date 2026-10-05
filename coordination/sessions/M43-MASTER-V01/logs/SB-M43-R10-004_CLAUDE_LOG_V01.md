# SB-M43-R10-004 — CLAUDE LOG V01

Child: **SB-M43-R10-004** — "Add an opt-in First-Try Cleanup challenge: five qualifying progression levels form a run; only the first attempt can extend the run; a qualifying loss resets only the event run."
Parent: M43-C010 — Bottom Navigation / Profile / Achievements / Events / Ranks + M43-C010R — Weekly Mini Event / First-Try Challenge / Personal Best [OWNER APPROVED 2026-09-30]
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `8e717a4` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- TASKS M43-C010 / C010R rows; master prompt §C010: no dead BottomNav, preserve M41 Settings, no event currency, RANKS policy cannot be invented, Personal Best self-only
- coordination/OWNER_ECONOMY_REWARDS_V01.md (approved reward types; no Star / Event currency)

## Implementation

| File | Change |
|---|---|
| `scripts/economy/player_records.gd` | **new** self-only records from committed progression terminals (`records` section) |
| `scripts/economy/event_service.gd` | **new** Weekly Cleaning Event + First-Try Cleanup templates over `data/config/events_v1.json` (`events` section) |
| `data/config/events_v1.json` | **new** — schedules nothing (owner decision needed for windows / milestones / rewards / expiry policy) |
| `scripts/progression/achievements.gd` | **new** data-driven, derived achievements |
| `data/config/achievements_v1.json` | **new** 8 starter definitions, reward policy NONE |
| `scripts/ui/profile/profile_screens.gd` | **new** Profile (+ Personal Bests / self-ghost), Achievements, Events, Notifications prefs, Comeback |
| `scripts/ui/home/home_badges.gd` | **new** one attention model for shortcuts + BottomNav |
| `scripts/ui/home/home_screen.gd` | ProfileButton hit area, NavBadge_<tab>, `set_app_nav`, Tasks / Collection badges |
| `scripts/app/main.gd` | EVENTS nav + Profile shortcut destinations, comeback drain, deep links, MetaFeedback |
| `scripts/economy/economy_services.gd` | `records` / `events` / `return` / `notifications` sections (absent = fresh, present = strict) |
| `scripts/economy/production_action_facade.gd` | `claim_event_milestone`, `join_first_try`, `claim_first_try`, `claim_catchup` |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `_meta_terminal`: progression terminals feed records / events / Catch-Up before the terminal save |
| `tests/m43_master_c010_meta.gd` | **new** lane suite m01–m12 |

Shared C010 implementation (one commit).

## Tests

`tests/m43_master_c010_meta.gd` → **PASS 12/12** (real app root, injected clock + local day, real gameplay host terminals):
m01 EVENTS / ROBOTS tabs live and open their destinations; RANKS disabled with the honest coming-later tooltip (no fake board).
m02 SETTINGS still opens the M41 panel, with no second Settings popup.
m03 the Home profile card opens Profile: active robot, campaign level, Collection 0/135 · 0 sets, robots 1/10, achievement summary; ACHIEVEMENTS reachable.
m04 data-driven definitions with known metrics; 10 clears → 1 / 10 done and 50 at 10/50; completed state shown with nothing granted; an unknown metric rejects the file.
m05 shipped config schedules no event → honest empty state; no points / currency; an unreadable config → unavailable state.
m06 Weekly event active; two first clears three days apart (no reset) reach milestone 1; a loss adds nothing; double tap claims +50 SB once; re-claim and unreached claims refused; countdown shown.
m07 no `unclaimed_on_expiry` → event invalid; forfeit: ended event gone and claim refused; claim_after_end: an ended event with an unclaimed reward stays listed and claimable; no progress after the window.
m08 First-Try reward fixed and visible before joining; nothing counts before joining; two first-try clears; a first-try loss resets only the run (campaign level kept, only the normal Heart); a second attempt cannot extend it; 5 in a row → reward once.
m09 best streak 2, best first-try run 2, boosterless 3 from real terminals; self-ghost bar = current vs own best; no social / leaderboard / http code.
m10 fresh → only Daily badge; tasks / gift / robots / collection counts appear on Home + BottomNav and all clear once handled.
m11 no rank scoring code.
m12 5 malformed `records` / `events` sections rejected with state untouched; absent → fresh.


## Regression

Shared C010–C014 checkpoint (37 suites + root): m43_master_c010_meta 12/12, m43_master_c011_c014 18/18, m43_master_c009_daily 12/12, m43_master_c008_robots 10/10; closed m42_home, m42_home_composition 9/9, m42_home_v04 18/18, v05 13/13, v06 13/13, v07_safe_area 9/9, m42_navigation, m42_c003_scrubby_animation 18/18; m43_c001a 11/11, c001b 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40; m43_master c005 32/32, c005r 8/8, c005f 10/10, c006 11/11, c007 13/13, c007r 9/9; m43_c005_c008_pack_commit_transaction 27/27; m28_c002_c002_static_shell 16/16; m39a, m39d, m39_v02_atomicity, m39_v03_full_surface, m39_v04_integration, m40_save_system, m40_v03_canonical, m40_v04_bootstrap, m54_collection_set_master_exactly_once, m55_economy_release_regression PASS; root `tests/run_tests.gd` **ALL PASS 5323 checks**; `git diff --check` clean.

**Regression caught and fixed in this lane:** closed `m39e_full_matrix` ("removed economies": the economy snapshot text must contain no `star`) failed once, because the new notification preference key `quiet_start` contains that substring. The keys were renamed `quiet_from` / `quiet_to`, with no rule weakened. After the rename these PASS: m39e_full_matrix, m39_v02_atomicity, m40_save_system, m43_master_c010_meta 12/12 and m43_master_c011_c014 18/18. The root run executed after the rename.


## Runtime evidence

Rendering tool `tests/tools/meta_snapshot.gd` → `META_EVIDENCE CLEAN (0 rejected)` across five viewports; frames under `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-122/`: Profile, Achievements, Events empty, Events with a TEST config (not shipped), Notifications, Welcome Back, Home badges.

## Blockers / gates

Not offered until an owner-configured reward exists (`first_try_cleanup: null`).

## MASTER REMEDIATION V03 — 2026-10-06

Prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_V03.md` · authority: `CHATGPT_MASTER_AUDIT_V01.md`. Baseline `0a7ff02` · remediation code commit `1cbe37f` (handoff: `M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`). The V01 sections above are kept unchanged as history; this section supersedes them where they differ.

**Status correction (audit §9): READY → `BLOCKED_AWAITING_AUTHORITY`.** The shipping `data/config/events_v1.json` has `first_try_cleanup: null`. The row requires a fixed reward, visible before participation, and no owner has authorized one, so the shipping child is not complete. No reward was invented.

The reusable mechanism and its tests stay (`tests/m43_master_c010_meta.gd` m08 with a TEST config): fixed reward visible before joining, first-attempt-only extension, a loss resets only the run, reward once at 5.

**Needed from the owner:** the First-Try Cleanup reward (type + amount from the approved reward types) and its schedule / offer rules.

`tests/m43_master_c011_c014.gd` → **PASS 28/28** (18 V01 cases kept or updated, plus 10 new). Regression: see `M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`.

V01 status line (superseded): `READY_FOR_INDEPENDENT_AUDIT — SB-M43-R10-004`

BLOCKED_AWAITING_AUTHORITY — SB-M43-R10-004
