# SB-M43-109 — CLAUDE LOG V01

Child: **SB-M43-109** — "Robot selection must never mutate BoardState, TargetSelector, routing, solver or batch legality."
Parent: M43-C008 — Robots Destination
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

Resume V02 preflight: `git status` / `git diff --name-status` captured; the uncommitted Robots WIP (8 paths) inspected path by path and separated from owner-local files; `git fetch origin main --prune` then fast-forward `a217122` → `1ca149c` (resume prompt + criteria + TASKS only, no overlap with the WIP). Owner-local `project.godot`, `scenes/app/main.tscn`, owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `1ca149c` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- coordination/OWNER_ROBOT_ROSTER_V01.md (owner-approved 10-robot roster, order, names, 20% meta perks, asset family) restated in data/config/robot_roster_v1.json
- coordination/OWNER_ECONOMY_REWARDS_V01.md + data/config/economy_rewards_v1.json: 250 Bot Parts per robot, Bot Parts earned only (no SB / money path in V1)
- CLAUDE.md §9/§10: robots are presentation/meta; TargetSelector / RoutingSystem / solver / batch truth untouched
- M43 master prompt V01 + resume V02 §2 (finish the existing Robots WIP)

## Implementation

| File | Change |
|---|---|
| `scripts/ui/robots/robots_screen.gd` | **new** Robots destination: 10 rows in roster order (portrait, name, ACTIVE/UNLOCKED/LOCKED chip, NEW badge, perk, note), Bot Parts N / 250 toward next + overflow line, EQUIP / UNLOCK (next only) / DETAILS, locked detail popup, seen marks `robot_seen:<id>` |
| `scripts/app/main.gd` | `_on_home_nav` opens Robots on BottomNav ROBOTS (Home route, no modal); Results model carries `robot_id` |
| `scripts/ui/home/home_screen.gd` | ROBOTS tab enabled; profile card shows the active robot's name + portrait, restores the owner-approved binder texture for Scrubby (broken `_art_binder_portrait` branch from the WIP removed) |
| `scripts/ui/results_screen.gd` | victory / help pose from `RobotRoster.asset(rid, ...)` (Scrubby default) |
| `scripts/ui/popup/acquisition_flow.gd` | `_help_pose()` for the Life hero and Need a Hand |
| `scripts/ui/gameplay_screen.gd` | HUD profile portrait + name from `robot_id` |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `prof["robot_id"]` (HUD profile only) |
| `scripts/economy/economy_services.gd` | legacy `meta_ui` baseline also marks already-unlocked robots as seen (no NEW flood on old saves) |
| `scripts/ui/ui_text.gd` | 15 `ROBOTS_*` keys |
| `tests/m43_master_c008_robots.gd` | **new** lane suite r01–r10 |
| `tests/m42_home.gd` | closed assertion updated: EVENTS / RANKS stay disabled, ROBOTS now live (see Regression note) |
| `tests/tools/robots_snapshot.gd` | **new** rendering evidence tool |

Shared C008 implementation (one commit). Resumed from the uncommitted WIP of the first run: WIP inspected path by path, the broken Home portrait branch removed and replaced by a binder-texture restore, UiText keys, tests and evidence added.

## Tests

`tests/m43_master_c008_robots.gd` → **PASS 10/10**: r01 Nav ROBOTS → real roster, 10 rows in owner order; r02 ACTIVE / LOCKED, `Bot Parts 120 / 250 toward Moppy`, unlock blocked below 250, later robots DETAILS only, 300 → +50 overflow, out-of-order tap never unlocks; r03 roster perk text per row, every modifier 20%, no perk text claims board/slot/target/solve power; r04 UNLOCK → facade spends exactly 250 → Robot Unlock ceremony on top → refreshed roster → EQUIP (spends nothing) → persisted through canonical save → re-equip Scrubby; r05 locked detail: master art under lock, `Needs 500 Bot Parts in total (you have 40)`, perk, earned-only, only BACK, no SB/money path in source; r06 Moppy → Home profile name/portrait, Results model, help pose, gameplay HUD portrait/name, back to Scrubby restores the binder texture; r07 robot files (code, comments excluded) reference no board/target/route/solver/batch type, gameplay host reads the robot only into the HUD profile, equip changes only the `robots` snapshot section; r08 ceremony shown once, NEW on Moppy only, cleared after first view, never repeated, persisted, legacy save not flooded; r09 all 10 unlocked at 1080x2160 and 720x1280: every portrait, no row overflow, ≥80 px buttons; r10 missing Moppy portrait / unknown id fall back to Scrubby art and Home/HUD keep rendering.

## Regression

Lane checkpoint (all exit 0, 0 script errors): m43_master_c008_robots 10/10; closed m42_home (one assertion updated, see below), m42_home_composition 9/9, m42_home_v04 18/18, v05 13/13, v06 13/13, v07_safe_area 9/9, m42_navigation, m42_assets, m42_c003_scrubby_animation 18/18; m43_c001a 11/11, c001b 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40; m43_master c005 32/32, c005r 8/8, c006 11/11, c007 13/13, c007r 9/9; m28_c002_c002_static_shell 16/16; m39a, m39_v03_full_surface, m40_save_system, m40_v03_canonical, m55_economy_release_regression PASS; root `tests/run_tests.gd` **ALL PASS 5323 checks**; `git diff --check` clean.

**Closed-test change (tests/m42_home.gd:85):** it asserted `Nav_robots.disabled` under the message "later-milestone tabs disabled, not faked". SB-M43-102 now makes ROBOTS the canonical live destination, so the pin was stale; the assertion keeps its intent (EVENTS / RANKS still disabled, nothing faked) and now requires ROBOTS live — the live destination itself is proven by m43_master_c008 r01.

## Runtime evidence

Rendering tool `tests/tools/robots_snapshot.gd` → `ROBOTS_EVIDENCE CLEAN (0 rejected)` across 1080x1920 / 1080x2160 / 1170x2532 / 1290x2796 / 1536x2048; frames under `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-102/` (fresh, unlockable + overflow, locked detail, Home with Moppy active, all unlocked scrolled). First render caught a zero-width Parts label (one letter per line) and a clipped UNLOCK button; fixed before commit.

## Blockers / gates

None.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-109
