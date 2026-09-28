# M43-C003-C001 — CLAUDE LOG V01

Date: 2026-09-28
Prompt: `coordination/sessions/M43-C003-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C003-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Scope: SB-M43-030..049
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- Repo `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `bb0434d` (fast-forward from `75eefa5`).
- **Final commit:** the commit that adds this log. Its SHA is reported in the hand-off message, because a file cannot contain its own commit id.
- The pre-existing local `project.godot` modification and untracked owner media / `.uid` / `.import` caches were preserved and excluded from the commit.
- Root `TASKS.md` was read only. **It was not edited.**
- **Not done** (all out of scope):
  - no ad SDK or provider, and no placement ids, frequency, cooldown or caps;
  - no rewarded 2x;
  - no fifth booster;
  - no price changes; Heart regen stays 900 s;
  - no M43-C004 Need a Hand;
  - no M43-C006 Shop catalog;
  - no new art;
  - no Results or Gameplay V02 shell changes.
- The accepted M43-C002 visuals are unchanged: the BasePopup additions are opt-in, and the C002 suite passes 23/23.

## Architecture / seams added

See `ACQUISITION_MATRIX_V01.md` §1–§3 for the full map.

**Economy (smallest authoritative extension, no second ledger):**
- `RewardedAdProvider`: provider-neutral seam. The production default is unavailable.
- `RewardedGrantService`: verified-completion only. Grants go through `RewardGrantService` under tx `rewarded:<token>`, whose applied set is persisted. Save is requested before `resolved` fires. Timeouts call `abandon()`.
- `EconomyServices`: `rewarded` plus the `rewarded_heart` and `booster_charge_<id>` reward handlers.
- `HeartService.grant_one()`.
- `SpeedEntitlementService.is_level_entitled()` (read-only).
- Facade: `rewarded_available()` and `start_rewarded()`.
- `AppState` binds the rewarded save boundary.

**App:**
- `ShopHandoff`: detached tickets, `finish` exactly once, and an explicit "Shop coming soon" state. Nothing is sold.
- `main.gd`:
  - owns ShopHandoff + AcquisitionFlow;
  - wires Home Heart + → Life and Home SB + → Shop;
  - adds zero-Heart gates on PLAY, Results Continue and Results Retry.

**UI:**
- `AcquisitionFlow`: Life, the one data-driven Booster Acquire (with a Selector/Tornado target picker), insufficient SB → Shop, and rewarded pending/busy handling. It runs on the C002 BasePopup/ModalStack.
- `SpeedAcquisitionPopup` is rewritten as a BasePopup subclass: the canonical 2x Acquire. The old parallel PanelContainer is gone.
- `BasePopup` opt-ins: hero, `offer` style, rows, `set_action_visible/blocked`, `add_footer_note`, `rearm_soon`.

**Host:**
- `booster_legality(id)`: read-only proofs from the same adapter the transaction uses.
- `execute_booster(id, target)`: canonical facade, charge-first then SB, solver-safe, refunded on failure.
- Zero charge → Booster Acquire. An owned Selector/Tornado → USE mode.
- The 2x popup is on the stack with a live 1 s entitlement refresh.
- Restart zero-Heart gate.
- A private economy (no-AppState harness) binds its own rewarded save.

## Files changed

**New:**
- `scripts/economy/rewarded_ad_provider.gd`
- `scripts/economy/rewarded_grant_service.gd`
- `scripts/app/shop_handoff.gd`
- `scripts/ui/popup/acquisition_flow.gd`
- `tests/m43_c003_c001_acquisition.gd`
- `tests/support/rewarded_provider_double.gd`
- `tests/tools/acquisition_snapshot.gd`
- the three session docs and `evidence/` (27 PNGs)

**Modified:**
- `scripts/economy/economy_services.gd`, `heart_service.gd`, `production_action_facade.gd`, `speed_entitlement_service.gd`
- `scripts/app/app_state.gd`, `scripts/app/main.gd`
- `scripts/gameplay/runtime/production_gameplay_host.gd`
- `scripts/ui/popup/base_popup.gd`, `scripts/ui/speed_acquisition_popup.gd`, `scripts/ui/ui_text.gd`

**Test migrations (deliberate; the economic assertions are kept):**
- `tests/m28_c002_c001_gameplay_v02.gd`: zero charge now opens Booster Acquire. An owned Selector charge opens USE mode (reason `target_selection`, was `target_selection_required`). The charge is still not consumed.
- `tests/m52_r01_parallel_runtime.gd`: the canonical 2x popup is a one-shot BasePopup, so each open is re-fetched. Insufficient SB now also pushes the Shop handoff popup.
- `tests/m39_v02_integration.gd`: the refused unentitled press opens the modal 2x popup, which blocks the next background press. The test closes it first.
- `tests/m43_c002_c001_popup_modal_pause.gd`: **NB-001 fixed.** The vacuous `or true` "fresh attempt" expression is replaced with a real assertion: 5 unoccupied slots and the board fully ACTIVE.

## Tests

**Focused:** `tests/m43_c003_c001_acquisition.gd` — **PASS, 34/34 cases, 0 fail.** It covers the 32 required items, the responsive matrix (7 surfaces × 5 sizes, safe-area insets, ≥ 88 px targets) and a production-provider check (default unavailable, no fake success, no rewarded 2x).

Highlights:
- Heart authority is 5 max / 900 s.
- Refill cost comes from live state at commit: 800 was charged, not the stale 1,200 on screen.
- A rewarded completion arriving when Hearts are already full fails closed (5, not 6).
- 4 duplicate callbacks grant +1 once.
- After a UI timeout, a late completion grants 0.
- Across background/resume, exactly +1 is granted.
- After save + relaunch, the same provider token is refused and a stale callback grants nothing.
- A rewarded +1 Slot, when already used, keeps its charge; there is no 7th slot.
- 5 rapid taps produce 1 purchase or 1 provider request.
- Across 8 full cycles, nodes (309 → 309), connections and timers are stable.

**Full regression** (Godot 4.7.2 headless, 12-way parallel, all 112 suites):

- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- M28: `c002_c001` 14/14, `c002_c002_r01` 10/10, `c002_c002_static_shell` 16/16, layout smoke — PASS.
- M29 (all), M30 completion + transaction-safe retry: PASS.
- M39 A–E, V02 (after migration, re-run PASS), V03, V04, tornado in-flight: PASS.
- M40 save / V02 / V03 / V04: PASS.
- M42 home, composition, V03–V07 safe area (9/9), navigation, opening: PASS.
- M43-C001A 11/11, C001B 11/11, C002 23/23: PASS.
- M52 supply plans / R01 (after migration) / R02: PASS.
- M55 long session, core chaos, economy release, Heart 900, C002 timed-2x anti-rollback: PASS.

**Non-zero exits:**
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B). These are the historical pre-Railroad-V1 baseline, identical to previous cycles; no routing was touched.
- `m39_v02_integration` failed in the parallel run before its migration (above). The migrated file was re-run: PASS.

**Other checks:**
- `SCRIPT ERROR` matches are only the m20 lifecycle assertion names (baseline).
- `git diff --check` is clean.

## Evidence

27 PNGs are in `evidence/`; the list is in matrix §5. They cover every state the prompt requires (Life partial / full / insufficient / rewarded available / unavailable, all four boosters, booster rewarded available / unavailable, booster insufficient → Shop, 2x no entitlement / timed active / insufficient) plus the short phone, 1170, 1290 and tablet sizes.

The tool rejects any shot whose stacked popups fail `text_fits()`.

## Deviations / owner decisions needed

These are also listed in `OWNER_ACQUISITION_REVIEW_V01.md`.

1. **Selector/Tornado target picker.** No target-selection UI or TASKS row existed, so a zero-charge Selector/Tornado purchase could never execute. The one Booster Acquire component carries a data-driven picker:
   - Selector offers solver-safe batches from `eligible_safe_batches()`, showing at most 12 chips;
   - Tornado offers colours from `present_colors()`.

   Execution goes through the unchanged BoosterService transactions. This needs owner approval as the V1 target UX.
2. **Rewarded booster while currently illegal.** FREE stays offered and the charge is saved, per prompt §F. The owner may prefer hiding it.
3. **Zero-Heart gate on Pause → Restart.** A Restart whose resulting Heart count would be < 1 opens Life instead of restarting, and nothing is consumed. The owner should confirm this interpretation.
4. **Shop** is an explicit "coming soon" state until M43-C006. Tickets resolve as `cancelled`; the `fulfilled` path is reserved for the real Shop.
5. **Life frame.** The approved C002 family frame and royal X are used rather than the reference's plain blue frame and red X. Matching the reference more literally would need owner-approved art.
6. **UI safety timeout.** An unresolved rewarded video is abandoned (no grant) after 90 s (`AcquisitionFlow.reward_ui_timeout_s`). This is not ad policy.

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c003_c001_acquisition.gd
```

```bash
godot --path . -s res://tests/tools/acquisition_snapshot.gd -- coordination/sessions/M43-C003-C001/evidence
```

`AWAITING_CHATGPT_AUDIT / M43-C003-C001 LIFE BOOSTER 2X ACQUISITION`
