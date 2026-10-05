# SB-M43-R07-002 — CLAUDE LOG V01

Child: **SB-M43-R07-002** — "When pity reaches its configured threshold, the next eligible earned pack guarantees at least one currently eligible missing card while still preserving Premium's Rare-or-better guarantee; pack contents commit atomically before reveal."
Parent: M43-C007R — Collection Fairness / Pity / First Collection Sprint [OWNER APPROVED 2026-09-30]
Master prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_PROMPT_V01.md`

## Sync preflight

`git fetch origin main --prune` before the child: local `main` level with `origin/main` (no incoming commits); owner-local `project.godot`, `scenes/app/main.tscn`, the editor-touched owner-review `.tscn`, `addons/`, `.mcp.json`, `tests/_m55_diag_tmp.gd` and untracked owner files preserved and never staged.

Starting SHA: `60c2511` · Final SHA: the commit that adds this log (listed in the master log).

## Authority used

- TASKS M43-C007R rows (owner-approved 2026-09-30): earned-only, data-driven, transparent, non-purchasable pity; Premium Rare-or-better and atomic pack commit preserved; no paid-random pack (M57).
- Master prompt C007R lock: no paid acceleration/reroll; preserve Premium Rare-or-better and atomic pack commit.

## Implementation

| File | Change |
|---|---|
| `scripts/collection/pack_pity.gd` | **new** versioned counter `{version, count}` (strict import, absent = 0); threshold read from `collection.pity.threshold` (absent/0 = disabled); test-only override |
| `scripts/collection/card_pack_service.gd` | earned opens draw first, then `_apply_earned`: optional guarantee substitution (last slot, never Premium card 0, first missing eligible card, nothing fabricated), apply in the same order, report NEW/no-NEW to pity |
| `scripts/economy/economy_services.gd` | `pack_pity` wired into CardPackService; economy section `pack_pity` (absent = 0, present strict) — rolled back with every C008 / economy snapshot |
| `tests/m43_master_c007r_pity.gd` | **new** lane suite p01–p09 |

Shared C007R implementation (one commit).

## Tests

`tests/m43_master_c007r_pity.gd` → **PASS 9/9**: p01 counter rules on real packs; p02 persisted across reload, 9 malformed sections rejected, absent → 0; p03 test threshold 2 → third pack contains the first missing card, counter reset; p04 Premium: substitution at the last slot, natural draws 0..3 unchanged, card 0 Rare-or-better; p05 nothing missing → no fabricated card, counting continues; p06 shipped config has no threshold → never due; p07 C008 failed commit restores the counter, success counts once durably; p08 no Shop/facade/ad path touches pity, no spend API; p09 not due → identical draws, RNG state and Collection to pre-C007R behaviour.

## Regression

Pack-authority checkpoint (CardPackService draw/apply restructure + economy section), all exit 0 / 0 `SCRIPT ERROR`: C007R 9/9 · C008 27/27 · C006 Standard 21/21 · C007 Premium 19/19 · C007 Collection 12/12 (13/13 after k13) · C005 32/32 · M39 `a_economy_core`, `d_daily_collection`, `e_full_matrix`, `v02_atomicity`, `v03_full_surface` PASS · M54 PASS · M55 release regression PASS · M40 `save_system`, `v03_canonical` PASS · root **5,323 ALL PASS** · `git diff --check` clean.

## Runtime evidence

Pity has no visible surface while dormant; the conditional copy is covered by k13.

## Blockers / gates

Mechanism implemented and proven with a test-only threshold (p03/p04/p07). **Missing authority:** the shipping threshold value must be balance-simulated (M56) and owner-approved; inventing it would create an unapproved probability rule. Until then the guarantee is dormant (p06).

BLOCKED_AWAITING_AUTHORITY — SB-M43-R07-002
