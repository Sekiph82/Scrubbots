# SB-M43-151 — CLAUDE LOG V01

Child: **SB-M43-151** — "Test timezone changes, missed days, expired events, disabled permissions and stale deep links."
Parent: M43-C012 — Comeback / Notifications + M43-C012R — Comeback Catch-Up / Smart Notification Prioritization [OWNER APPROVED 2026-09-30]
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `8e717a4` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- TASKS M43-C012 / C012R rows (48 h candidate, three qualifying wins, capped approved rewards, priority/dedup, 1 push / 24 h, quiet hours, factual copy)
- CLAUDE.md §15 / master prompt: no invented reward, no paid dependency

## Implementation

| File | Change |
|---|---|
| `scripts/economy/return_service.gd` | **new** absence windows (monotonic), summary once per window, Catch-Up track (config-gated), `return` section |
| `data/config/comeback_v1.json` | **new** 48 h candidate; Catch-Up steps empty (owner) |
| `scripts/economy/notification_policy.gd` | **new** opt-in prefs, quiet hours, priority collapse, 24 h cap, live-state candidates, deep-link validation (`notifications` section) |
| `scripts/ui/profile/profile_screens.gd` | Comeback summary + Notifications preferences screens |
| `scripts/app/main.gd` | boot / resume `on_active`, flush `touch`, comeback after ceremonies on Home, `open_deep_link` |
| `tests/m43_master_c011_c014.gd` | c01–c04, n01–n03 |

Shared C012 implementation (one commit).

## Tests

`tests/m43_master_c011_c014.gd` → **PASS 18/18**. This lane:
c01 47 h → no window; a 49 h gap opens one window and the summary is due once; a resume minutes later opens nothing; a 10-day clock rollback opens nothing; the lifecycle `touch` stops short breaks from counting; persisted across relaunch; `high < last` rejected.
c02 real app: flush, then a 3-day absence, then relaunch → Welcome Back on Home with Hearts + Daily-ready lines; nothing granted, Daily untouched; shown once.
c03 the shipped Catch-Up has no steps, so it is never offered; 48 h candidate.
c04 with a test sequence: offered in the new window; step 1 once; capped at 3 wins; +60 SB total; resume / relaunch never re-grants; a new genuine absence opens a new window; a sequence above three wins is rejected; no Daily / level-economy access.
n01 global OFF by default; known categories only; unknown deep links → home; quiet hours across midnight.
n02 opted out → nothing; Hearts full + Daily + Gift collapse into ONE Daily message; quiet hours → nothing; one per 24 h; category OFF → next priority.
n03 claimed Daily + non-full Hearts + nothing claimable → no candidate; no guilt / false-expiry wording; event-ending only with a real claimable reward.


## Regression

Shared C010–C014 checkpoint (37 suites + root): m43_master_c010_meta 12/12, m43_master_c011_c014 18/18, m43_master_c009_daily 12/12, m43_master_c008_robots 10/10; closed m42_home, m42_home_composition 9/9, m42_home_v04 18/18, v05 13/13, v06 13/13, v07_safe_area 9/9, m42_navigation, m42_c003_scrubby_animation 18/18; m43_c001a 11/11, c001b 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40; m43_master c005 32/32, c005r 8/8, c005f 10/10, c006 11/11, c007 13/13, c007r 9/9; m43_c005_c008_pack_commit_transaction 27/27; m28_c002_c002_static_shell 16/16; m39a, m39d, m39_v02_atomicity, m39_v03_full_surface, m39_v04_integration, m40_save_system, m40_v03_canonical, m40_v04_bootstrap, m54_collection_set_master_exactly_once, m55_economy_release_regression PASS; root `tests/run_tests.gd` **ALL PASS 5323 checks**; `git diff --check` clean.

**Regression caught and fixed in this lane:** closed `m39e_full_matrix` ("removed economies": the economy snapshot text must contain no `star`) failed once, because the new notification preference key `quiet_start` contains that substring. The keys were renamed `quiet_from` / `quiet_to`, with no rule weakened. After the rename these PASS: m39e_full_matrix, m39_v02_atomicity, m40_save_system, m43_master_c010_meta 12/12 and m43_master_c011_c014 18/18. The root run executed after the rename.


## Runtime evidence

Rendering tool `tests/tools/meta_snapshot.gd` → `META_EVIDENCE CLEAN (0 rejected)` across five viewports; frames under `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-122/`: Profile, Achievements, Events empty, Events with a TEST config (not shipped), Notifications, Welcome Back, Home badges.

## Blockers / gates

Timezone = injected local-day authority; disabled permission = global OFF (platform permission itself is SB-M43-146).

READY_FOR_INDEPENDENT_AUDIT — SB-M43-151
