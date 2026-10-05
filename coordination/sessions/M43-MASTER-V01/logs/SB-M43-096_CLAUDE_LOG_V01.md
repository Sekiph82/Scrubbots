# SB-M43-096 — CLAUDE LOG V01

Child: **SB-M43-096** — "Implement per-card duplicate exchange and EXCHANGE ALL EXTRAS with atomic confirmation and protected-copy floor of 1."
Parent: M43-C007 — Collection / Cards Exchange Destination
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `79544a7` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- Master prompt C007 lock: 15 sets x 9 = 135 canonical cards; first copy protected; EXTRAS = copies above 1; Cards Exchange inside Collection; values Common 25 / Rare 75 / Epic 200 / Legendary 500 SB; pack open entry routes through closed C005/C008 authorities.
- `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md` §1 (Cards Exchange belongs inside Collection).
- `data/config/economy_rewards_v1.json` collection + cards_exchange (exact set rewards, Master reward, protected copies, values).
- CollectionInventory / CardsExchangeService / RewardGrantService (M39/M54 authorities) and ProductionActionFacade (`exchange_card`, `exchange_all_extras`).

## Implementation

| File | Change |
|---|---|
| `scripts/ui/collection/collection_screen.gd` | **new** album / set detail / card detail / Cards Exchange (confirm → facade commit → committed feedback); presentation-only `card:<id>` viewed marks (dirty flag, flushed at lifecycle); bounded card-art texture cache |
| `scripts/economy/economy_services.gd` | legacy `meta_ui` baseline also marks already-owned cards viewed (no NEW flood on an old save) |
| `scripts/app/main.gd` | Home COLLECTION panel → album |
| `scripts/ui/ui_text.gd` | `COLLECTION_*` keys |
| `tests/m43_master_c007_collection.gd` | **new** lane suite k01–k12 |
| `tests/tools/collection_snapshot.gd` | **new** real-app evidence tool |

Shared Collection implementation for SB-M43-090..101 (one commit). k04 EXCHANGE 1 / EXCHANGE ALL OF THIS CARD and k05 EXCHANGE ALL EXTRAS: confirm → facade (CardsExchangeService atomic removal + SB credit, idempotent tx) → save → committed feedback; floor 1 kept, buttons blocked at 0 extras; k06 cancel changes nothing; k07 rapid taps exchange once.

## Tests

`tests/m43_master_c007_collection.gd` → **PASS 12/12**.

## Regression

Shared-authority checkpoint (EconomyServices legacy baseline, app root), all exit 0 / 0 `SCRIPT ERROR`: C007 12/12 · C006 11/11 · C005 32/32 · C008 27/27 · M40 `save_system`, `v02_safety`, `v03_canonical`, `v04_bootstrap` PASS · M39 `d_daily_collection`, `e_full_matrix`, `v02_atomicity`, `v03_full_surface` PASS · M54 PASS · `m42_home` PASS · `m43_c003_c001` 34/34 · root **5,323 ALL PASS** · `git diff --check` clean.

## Runtime evidence

`coordination/sessions/M43-MASTER-V01/evidence/SB-M43-090/` — `1_album` at 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048; at 1080×2160 `2_set_detail_new_extras_notfound`, `3_card_detail`, `4_cards_exchange` (0 rejected).

## Blockers / gates

None.

READY_FOR_INDEPENDENT_AUDIT — SB-M43-096
