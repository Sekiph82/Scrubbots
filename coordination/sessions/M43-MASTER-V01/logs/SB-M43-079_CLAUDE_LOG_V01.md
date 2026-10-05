# SB-M43-079 — CLAUDE LOG V01

Child: **SB-M43-079** — "Produce/owner-approve a Shop visual master before final production binding."
Parent: M43-C006 — Shop / Store / Currency Destination
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `d560e7e` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md` §1–2 (SHOP is a real destination; No Ads belongs in Shop; SB + opens Shop with preserved return context).
- `coordination/OWNER_ECONOMY_REWARDS_V01.md` + `data/config/economy_rewards_v1.json` (one SB economy; Heart / booster / 2x prices).
- Master prompt C006 lock: Hearts/boosters/2x via existing services; real-money products, No Ads, localized cash price, restore and provider logic gated by M57.

## Implementation

| File | Change |
|---|---|
| `scripts/ui/shop/shop_screen.gd` | **new** the Shop destination (live wallet/Hearts, Hearts / Boosters / 2x / Scrub Bucks / No Ads sections, confirm → facade commit → feedback, exact ticket return) |
| `scripts/ui/popup/acquisition_flow.gd` | every Shop intent (Home SB +, insufficient-SB handoff) opens ShopScreen instead of the C003 coming-soon placeholder |
| `scripts/app/main.gd` | Home SHOP panel → Shop (`_on_home_shortcut`) |
| `scripts/ui/ui_text.gd` | `SHOP_*` keys |
| `tests/m43_master_c006_shop.gd` | **new** lane suite s01–s11 |
| `tests/tools/shop_snapshot.gd` | **new** real-app evidence tool |

Shared Shop implementation for SB-M43-078..089 (one commit). Candidate = the production Shop built from the owner-approved M43-C002 popup chrome kit and the existing final Shop art (`assets/ui/final/shop/*`, booster / currency icons); runtime captures in the evidence folder. No new art generated.

## Tests

`tests/m43_master_c006_shop.gd` → **PASS 11/11 (26 assertions)**.

## Regression

Shop + popup + Home checkpoint, all exit 0 / 0 `SCRIPT ERROR`: C006 Shop 11/11 · `m43_c003_c001_acquisition` 34/34 (one assertion updated: the C003 test pinned the coming-soon placeholder's single BACK action; it now asserts the same intent on the real Shop — no SB pack sold because the Scrub Bucks entry is M57-gated/disabled, BACK present) · `m43_c004_c001` 40/40 · `m43_c002_c001` 23/23 · `m42_home`, `v04`, `v05`, `v06`, `v07_safe_area` PASS · C005 32/32 · C005R 8/8 · root `run_tests.gd` **5,323 ALL PASS** · `git diff --check` clean.

## Runtime evidence

`coordination/sessions/M43-MASTER-V01/evidence/SB-M43-078/` — `1_shop_default` at 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048; at 1080×2160 also `2_shop_store_gated_entries`, `3_shop_return_context_insufficient`, `4_shop_confirm`, `5_shop_success_feedback` (frame inside viewport + text fits, 0 rejected).

## Blockers / gates

**Owner visual approval** of the Shop composition (evidence captures) is required; Claude cannot self-approve.

BLOCKED_AWAITING_AUTHORITY — SB-M43-079
