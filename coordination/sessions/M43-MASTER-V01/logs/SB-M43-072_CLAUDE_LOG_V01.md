# SB-M43-072 — CLAUDE LOG V01

Child: **SB-M43-072** — "Implement feature-unlock ceremony/coachmark used when a new meta system becomes available through M44 feature-unlock pacing."
Parent: M43-C005 — Reward, Pack, Collection, Robot, Feature and World Ceremonies
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `46e50fd` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md` §5: feature unlock order is data-driven and **exact campaign unlock level numbers remain owner-tuning-required and must not be invented**; appears once per feature/version; may mark a destination NEW; mints no reward.
- M44 (Tutorial / FTUE / Feature Unlock Pacing) is the pacing authority; it does not exist yet.
- `coordination/sessions/M43-C005-C001/OWNER_VISUAL_DECISION_V02.md`: Generic Feature Unlock visual master owner-accepted.

## Implementation

| File | Change |
|---|---|
| `scripts/ui/ceremony/meta_ceremonies.gd` | `feature_unlock` builder (medium frame, icon + glow, NEW chip, feature name/body, GOT IT); refuses an event without a real name/icon |
| `scripts/ui/ui_text.gd` | `CEREMONY_FEATURE_*` keys |
| `tests/m43_master_c005_meta_ceremonies.gd` | cases e29, e30 |
| `tests/tools/meta_ceremony_snapshot.gd` | explicit fixture entry for shell evidence |

Safe prerequisite only: the shipping ceremony builder and its presenter path (any future `feature_unlock` event with a key flows through CeremonyEvents → CeremonyPresenter → acknowledged once). No feature-unlock event source was created because the unlock order / levels are an unresolved owner + M44 decision; nothing in the shipping app emits this ceremony.

## Tests

Lane suite **PASS 32/32 cases (77 assertions)**. e29 builder truth (title / name / NEW badge / GOT IT; Reduced same labels without motion; missing name or icon → no ceremony); e30 CeremonyEvents derives no feature/world event (no authority invented).

## Regression

Builder-only addition; lane suite PASS; covered by the SB-M43-013 checkpoint (root 5,323 ALL PASS).

## Runtime evidence

Shell evidence from an explicit fixture entry (approved Cards Exchange shortcut icon): `coordination/sessions/M43-MASTER-V01/evidence/SB-M43-072/feature_unlock_*` (5 viewports FULL + REDUCED), 0 rejected.

## Blockers / gates

**BLOCKED_AWAITING_AUTHORITY**: M44 feature-unlock pacing (which features unlock, in what order, at which owner-approved campaign points, per-feature copy/icon) does not exist. Needed: owner-approved FTUE/feature-unlock table → an M44 FeatureUnlock authority emitting `feature:<id>` events. The ceremony and NEW-until-visited badge binding (SB-M43-134) then plug in without new UI.

BLOCKED_AWAITING_AUTHORITY — SB-M43-072
