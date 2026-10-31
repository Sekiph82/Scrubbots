STATUS: READY

# Build: SB-POLISH-004 + 005 + 006 batch (CLEAN NEXT hit area, Robots rows 1-2 details, Scrub Bucks + focused popup)

## Spec (written by the builder; no spec-writer this job)
Owner phone playtest 2026-10-31. Acceptance criteria:
1. SB-POLISH-004: find why CLEAN NEXT on Results is sometimes hard to press and fix the cause. CLEAN NEXT responds to the first real tap, and its hit area is at least 88 px in both directions, with no other control picking input over it.
2. SB-POLISH-005: on the Robots screen, tapping row 1 (Scrubby, ACTIVE) or row 2 (Moppy, UNLOCK 250) opens that robot's detail card, the same card rows 3+ open with DETAILS.
3. SB-POLISH-005: the ACTIVE button (blocked) and the UNLOCK button (unlock + ceremony) work exactly as before. A swipe that starts on a row opens nothing.
4. SB-POLISH-006: the Home Scrub Bucks "+" opens a focused Scrub Bucks popup instead of the Shop. It uses the BasePopup family like the Heart "+" Life popup and shows the live SB balance and only the SB pack offer. That offer is shown honestly as UNAVAILABLE with "Available when the store opens.".
5. SB-POLISH-006: a MORE IN SHOP action in the popup opens the full Shop (ticket source `home_sb_plus`). There is no new purchase path and no new currency (economy lock).
6. A permanent test covers each behaviour. The 1-3 suites covering these screens pass locally. No CI run and no phone build (owner usage rule).

## Summary
- **004, the cause:** the Supply front `HitArea`s (invisible, slightly larger tap surfaces) are `top_level` Controls. That makes each one its own GUI root, and Godot picks it ABOVE every non-top-level Control of the app root. The Results screen sits over the finished board, so one HitArea covered the middle of CLEAN NEXT and silently ate taps there. Taps elsewhere on the button worked, which is why it was only "sometimes" hard to press. A probe confirmed it: hovering the button centre picked `GameplayHost/.../SupplyColumn1/.../HitArea`.
- **004, modal gate (coordinator follow-up):** `ProductionInputController._sync_hit_areas()` now sets the HitAreas pickable only when neither the terminal stop nor the modal block is on. `set_modal_blocked` is the existing hook: the host mirrors `ModalStack.modal_changed` into it, so every popup over gameplay (Pause, Need a Hand, booster/acquisition, Shop) turns them off, and closing the last popup turns them back on. Honest note: ModalStack is a CanvasLayer (layer 64) and is already picked above the default canvas, so for popups this is a defensive guard, not a fix for a reproduced bug. Settings opens only from Home, where no gameplay host exists.
- **004, the fix:** `ProductionInputController.set_terminal_stopped(true)` now calls the new `BatchSupplyPanel.set_hit_areas_pickable(false)`, which sets every HitArea to MOUSE_FILTER_IGNORE. Retry calls `set_terminal_stopped(false)`, which sets them back to STOP. The fronts are already rejected after a terminal result, so gameplay is unchanged.
- **005:** each Robots row now has a `gui_input` handler. A stationary tap opens `open_detail` for that robot. A tap does nothing if the pointer moved more than the TouchScroll deadzone, if it landed on the row's action button, or if the roster is not the top popup. `open_detail` now also handles unlocked robots: they get full-colour art, role, perk and the meta-only line, without the lock or the Bot Parts lines. The locked card is unchanged.
- **006:** a new `AcquisitionFlow.open_scrub_bucks(source)` builds a BasePopup `scrub_bucks` in the Life-popup family. It has a medium frame, the help-pose hero, the SB bundle art, the live balance row, the "Scrub Bucks packs" line and the "Available when the store opens." line. Its actions are a blocked `sb_pack` UNAVAILABLE offer, MORE IN SHOP (`open_shop({"source": source})`) and CLOSE. Home SB + is routed to it in `main.gd`.
- **Changed files:** `scripts/ui/batch_supply_panel.gd`, `scripts/ui/production_input_controller.gd`, `scripts/ui/robots/robots_screen.gd`, `scripts/ui/popup/acquisition_flow.gd`, `scripts/app/main.gd`, `scripts/ui/ui_text.gd` (SB_POPUP_TITLE, SB_POPUP_MORE), `scripts/ui/shop/shop_screen.gd` (header comment), `tests/sb_polish_004_006_ui_batch.gd` (new), `tests/m43_c003_c001_acquisition.gd` and `tests/m43_master_c006_shop.gd` (SB + now goes through the popup), `.github/workflows/android-family-first10.yml` (new suite in the validate list), `TASKS.md`.
- **Commits:** baa7e2d6 (004), 7ff854d8 (005), d1f4e3da (006), 8177da63 (suite + CI list), d8d55088 (TASKS.md), 0ec20897 (004 modal gate), 5eb0131d (TASKS.md).

## Acceptance criteria
1. [x] **CLEAN NEXT, first tap.** `sb_polish_004_006_ui_batch` p004, real pointer events pushed into a 1080x2160 SubViewport running main.tscn:
   - after the Level 1 WON terminal, "all 3 top_level Supply HitAreas stop picking";
   - "CLEAN NEXT live, hit area (824.5, 113.2) >= 88 px";
   - "15 points across CLEAN NEXT all pick the button itself []";
   - "ONE real tap -> next level (Level 2)";
   - "terminal -> IGNORE, retry -> STOP again";
   - the new level's fronts pick again.
   - Modal gate (p004_pause_popup_not_under_hit_areas): "Pause open: HitAreas IGNORE, Pause button 'Action_resume' centre picks the button" and "Pause closed: HitAreas pick again".
   With the input-controller fix reverted, the same suite fails 3 asserts, including `(540.0, 1544.7)->HitArea`. That is the button centre being eaten.
2. [x] **Rows 1-2 open details.** p005:
   - "tap Scrubby row -> unlocked detail (art, no lock, no Bot Parts need)" and "role + perk, BACK only";
   - "tap Moppy row -> locked detail, 250 Bot Parts needed".
3. [x] **Buttons unchanged, swipe opens nothing.** p005:
   - "ACTIVE button: still blocked, opens nothing";
   - "UNLOCK button: unlocks Moppy + ceremony, no detail card (got ceremony_robot_unlock)";
   - "a swipe that starts on a row opens no detail".
   m43_master_c008_robots also passes 10/10 (r02 out-of-order DETAILS, r04 unlock/equip, r05 locked detail).
4. [x] **Focused popup.** p006:
   - "SB + opens the focused popup, not the Shop";
   - "live SB balance 'You have 1,000 SB'";
   - "only the SB pack offer, 'Available when the store opens.'";
   - "pack honestly UNAVAILABLE; actions [sb_pack, shop, close]";
   - "tapping UNAVAILABLE does nothing (no purchase, no currency)".
5. [x] **MORE IN SHOP.** p006:
   - "MORE IN SHOP -> full Shop (source home_sb_plus), SB popup gone";
   - "Shop closed: back on Home, ticket finished, SB unchanged".
   m43_c003_c001_acquisition c13 and m43_master_c006_shop s01 were updated to the new route and pass.
6. [x] **Permanent test.** `tests/sb_polish_004_006_ui_batch.gd` covers all three items (10 cases, exact ledger) and is added to the CI validate list. No CI run and no phone build.

## Validation
All suites were run with Godot 4.7.2 headless in the worktree. Each one exited 0, printed no `SCRIPT ERROR`/`Parse Error`, and its last summary line says PASS.
- `tests/sb_polish_004_006_ui_batch.gd`: "SB-POLISH-004/005/006 UI batch evidence: PASS (10/10 cases, 0 fail)". LOCAL_PASS. This is the round-1 follow-up run; the earlier 9/9 run covered the same cases minus the Pause case.
- `tests/m43_c003_c001_acquisition.gd`: "M43-C003-C001 acquisition evidence: PASS (34/34 cases, 0 fail)". LOCAL_PASS.
- `tests/m43_master_c006_shop.gd`: "M43 master C006 Shop evidence: PASS (15/15 cases, 0 fail)". LOCAL_PASS.
- `tests/m43_master_c008_robots.gd`: "M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)". LOCAL_PASS.
- **Four suites, one more than the owner's 1-3:** two existing suites asserted the old "SB + -> Shop" route, so they had to be updated and re-run.
- **Line-ending note for c008:** its first local run failed r07, because a Git Bash `sed -i` had turned the working copy of robots_screen.gd into LF and the suite's CRLF comment stripper missed the header comments. I restored CRLF and it passed. The committed content is unaffected because git normalizes line endings.
- `git diff --check`: clean.
- **Worktree not clean:** the only dirty entries left are Godot import churn that was already there when the job started: about 1,500 `.import` files with line-ending-only changes, plus untracked `.uid`/`.import` files for `_owner_inbox` and `addons`. I did not touch them. `project.godot` was restored from the index at the start.

## Log
### Round 1
I wrote the spec above myself because there was no spec-writer this job.

For 004, I probed with real pointer events and found the root cause: a top_level Supply HitArea sits above the Results screen. The fix is in the shared input controller's terminal gate, so every terminal path (WON, LOST, ERROR) is covered and Retry restores the HitAreas.

For 005, I added a row tap that opens the detail card, and the detail card now handles unlocked robots.

For 006, I added a focused Scrub Bucks popup that reuses the Life-popup building blocks, the Shop's honest store-gated copy and the existing Shop handoff.

I wrote the new suite, updated the two suites that pinned the old SB + route, and updated TASKS.md (queue rows plus the Owner Polish checklist).

### Round 1 follow-up (coordinator message)
- **Request:** the HitAreas must also stop taking input while any modal is open over gameplay, hooked to the modal stack rather than to each popup. Add a Pause-popup assertion and re-run only the new suite.
- **Done in 0ec20897:** I did it through the existing `set_modal_blocked` path (driven by `ModalStack.modal_changed`) via `_sync_hit_areas()`, and added the case `p004_pause_popup_not_under_hit_areas`.
- **Result:** I re-ran only `sb_polish_004_006_ui_batch`, which gave PASS 10/10. TASKS.md evidence is updated in 5eb0131d.
- **Settings:** the Settings panel opens only from Home, where no gameplay host exists, so it needs no extra hook.
