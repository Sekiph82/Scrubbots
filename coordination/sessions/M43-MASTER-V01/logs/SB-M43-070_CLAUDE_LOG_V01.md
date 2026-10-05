# SB-M43-070 — CLAUDE LOG V01

Child: **SB-M43-070** — "Implement Robot Unlock ceremony with canonical robot art, name, personality/perk summary and remaining Bot Parts carryover."
Parent: M43-C005 — Reward, Pack, Collection, Robot, Feature and World Ceremonies
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `a958c96` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- `coordination/OWNER_ROBOT_ROSTER_V01.md` (OWNER-APPROVED): canonical 10-robot roster, order, roles, 20% meta perks, per-robot asset family; 250 Bot Parts per robot.
- `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md` §4 (identity, personality/role, canonical meta perk, Bot Part carryover; equip or keep).
- `coordination/sessions/M43-C005-C001/OWNER_VISUAL_DECISION_V02.md`: Robot Unlock visual master owner-accepted (reward frame, unlocked burst, master art, name, role, perk panel, Bot Parts left, EQUIP / KEEP CURRENT).
- RobotUnlockService (owner economy §5) remains the only unlock / Bot Parts authority.

## Implementation

| File | Change |
|---|---|
| `data/config/robot_roster_v1.json` | **new** canonical roster restated from the owner decision (identity/display only; every asset path verified to exist) |
| `scripts/progression/robot_roster.gd` | **new** fail-closed roster loader, `entry`, `asset` (Scrubby fallback for a missing presentation asset), `next_locked` (canonical order) |
| `scripts/economy/production_action_facade.gd` | `unlock_next_robot()` — the next robot in canonical order for exactly the configured cost (M39 `unlock_robot(id)` kept unchanged) |
| `scripts/economy/ceremony_events.gd` | robot events carry the live `parts_left` / `active_robot` facts |
| `scripts/ui/ceremony/meta_ceremonies.gd` | `robot_unlock` builder (null for a non-roster id — nothing fabricated) |
| `scripts/ui/ui_text.gd` | `CEREMONY_ROBOT_*` keys |
| `tests/m43_master_c005_meta_ceremonies.gd` | cases e15, e16, e20, e21, e22 |
| `tests/tools/meta_ceremony_snapshot.gd` | reaches a robot unlock through the real facade |

Shipped in the same commit as SB-M43-071 (the equip/keep choice lives on this ceremony's CTAs; the active-robot seam is shared).

## Tests

`tests/m43_master_c005_meta_ceremonies.gd` → **PASS 22/22 cases (51 assertions)**. For this child: e15 roster == owner table (10 ids in order, cost 250, every perk name, every asset path exists, missing file fails closed); e16 real `unlock_next_robot` spends exactly 250 (37 carry over) and the ceremony shows MOPPY / role / perk name + text / canonical master art + perk icon / `Bot Parts left: 37` / EQUIP MOPPY + KEEP CURRENT; e20 unlocks follow canonical order Moppy..Atlas, refuse without parts, `all_unlocked` spends nothing; e21 a non-roster robot id is never presented (left pending, not dropped); e22 Reduced = same labels, unlocked-burst glow without motion.

## Regression

Shared-authority checkpoint (RobotUnlockService snapshot `active`, facade `unlock_next_robot` / `equip_robot`), all exit 0 / 0 `SCRIPT ERROR`: lane suite 22/22 · M39 `a_economy_core`, `e_full_matrix`, `v02_atomicity`, `v03_full_surface`, `v04_integration` PASS (M39 `unlock_robot(id)` semantics unchanged) · M40 `save_system`, `v02_safety`, `v03_canonical`, `v04_bootstrap` PASS · `m42_home` PASS · `m43_c001a_results_foundation` 11/11 · C008 27/27 · root `run_tests.gd` **5,323 ALL PASS** · `git diff --check` clean.

## Runtime evidence

`coordination/sessions/M43-MASTER-V01/evidence/SB-M43-070/robot_unlock_{FULL_1080x1920,FULL_1080x2160,FULL_1170x2532,FULL_1290x2796,FULL_1536x2048,REDUCED_1080x1920}.png` (0 rejected). The capture's Bot Parts value is the live wallet after the evidence tool's later real set completions (it reads the wallet, never a fixture).

## Blockers / gates

Owner-accepted C001 direction; independent audit + owner runtime acceptance pending. The Robots destination (SB-M43-102) is where players trigger `unlock_next_robot`; until then the ceremony appears for any robot unlocked through the authority.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-070
