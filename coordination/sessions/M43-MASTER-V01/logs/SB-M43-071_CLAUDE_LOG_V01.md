# SB-M43-071 — CLAUDE LOG V01

Child: **SB-M43-071** — "Robot unlock ceremony allows selecting/equipping the unlocked robot or continuing with the current robot."
Parent: M43-C005 — Reward, Pack, Collection, Robot, Feature and World Ceremonies
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `a958c96` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md` §4: the player may equip the new robot or keep the current robot.
- `coordination/OWNER_ROBOT_ROSTER_V01.md` §1: robot selection/perks never touch BoardState, targeting, routing, solver or batch legality.

## Implementation

| File | Change |
|---|---|
| `scripts/progression/robot_unlock_service.gd` | persisted active robot: `active_robot()`, `set_active(id)` (unlocked only, spends nothing); snapshot `active`; import: absent = initial robot, present must be an unlocked id else fail closed |
| `scripts/economy/production_action_facade.gd` | `equip_robot(id)` (saves + `action_committed`) |
| `scripts/ui/ceremony/ceremony_presenter.gd` | routes a ceremony CHOICE to its authority: Robot Unlock `equip` -> `equip_robot`; `keep` changes nothing; emits `ceremony_action` |
| `tests/m43_master_c005_meta_ceremonies.gd` | cases e16 (CTAs), e17, e18, e19 |

Shipped in the same commit as SB-M43-070. The ceremony's two CTAs both close and acknowledge it; only EQUIP changes the selection, through the facade (never decided in UI). Selection is meta presentation state; no gameplay object reads it in this change (SB-M43-108/109 bind presentation later).

## Tests

Lane suite **PASS 22/22**. For this child: e17 EQUIP → `active_robot()==moppy`, Bot Parts unchanged, ceremony acknowledged, persisted across reload; e18 KEEP CURRENT → still Scrubby, acknowledged; e19 strict import (locked / non-string / empty `active` rejected with live state unchanged; absent → Scrubby) and equipping a locked robot refused.

## Regression

Shared-authority checkpoint (RobotUnlockService snapshot `active`, facade `unlock_next_robot` / `equip_robot`), all exit 0 / 0 `SCRIPT ERROR`: lane suite 22/22 · M39 `a_economy_core`, `e_full_matrix`, `v02_atomicity`, `v03_full_surface`, `v04_integration` PASS (M39 `unlock_robot(id)` semantics unchanged) · M40 `save_system`, `v02_safety`, `v03_canonical`, `v04_bootstrap` PASS · `m42_home` PASS · `m43_c001a_results_foundation` 11/11 · C008 27/27 · root `run_tests.gd` **5,323 ALL PASS** · `git diff --check` clean.

## Runtime evidence

Same captures as SB-M43-070 (`evidence/SB-M43-070/`): EQUIP MOPPY primary + KEEP CURRENT secondary.

## Blockers / gates

Owner runtime acceptance pending with the Robot Unlock ceremony.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-071
