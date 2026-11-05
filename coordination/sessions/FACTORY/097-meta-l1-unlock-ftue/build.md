STATUS: READY

# Build: SB-M44-032 + SB-M44-033 + SB-M44-031 part 2 (owner 2026-11-03 meta at L1, Welcome at first Home, booster intros)

## Summary
Branch `factory/097-meta-l1-unlock-ftue`, 2 commits on 0e3e366d. Not pushed.

- `3ed1a496` is the code, tests and docs commit:
  - `data/config/feature_unlocks_v1.json`: daily, shop, tasks, collection, card_packs and achievements are now 1. hearts and gift_bar stay at 1, robots 25, events 30, ranks 40, and the boosters stay at 6/11/16/21. The `grandfather` note is replaced by a `policy` note.
  - Grandfather removed. `FeatureUnlocks.is_unlocked(id, frontier)` and `AppState.feature_unlocked` apply one rule to every profile (fresh, existing, migrated, imported, debug). Locking never touches charges or inventory.
  - The gate is now enforced at the entry points, not just on the Home buttons:
    - `main.gd` `_entry_locked`: direct nav and shortcut entry, plus deep links (a locked destination lands on Home).
    - `ProductionActionFacade.feature_gate`, bound by AppState and the gameplay host. It refuses, with `reason: "locked"`, booster buy, rewarded watch (`booster:*`) and plus_one_slot/random/selector/tornado; robot unlock and equip; event join and claim.
    - Shop booster rows are not for sale and show "Unlocks at level N".
    - The Need a Hand prover never picks a locked booster.
    - `execute_booster` no longer runs the fx capture for a locked booster. This also removes a script error in m44_unlock_gate that already happened on base.
  - Locked booster button (`gameplay_screen.gd`): a frosted navy `LockedPlate` with a cyan edge, the `icon_lock.png` padlock, a `LV N` Label (`BOOSTER_LOCKED_LEVEL`) and an "Unlocks at level N" tooltip. Touch is disabled. `booster_states()` now carries `unlock_level`.
  - FTUE:
    - The `l2_boosters` lesson is removed. New `booster_intros` (config-validated, one per booster) are served by `FtueDirector.booster_intro_step()` in gameplay through `main._coach_want`.
    - Each intro shows once, only for an unlocked booster, only for a new profile that has not skipped tips. Acknowledging it writes the intro id into the FTUE seen ledger, which is the saved per-booster "introduced" flag.
    - Skip Tips also works after the L1-L3 window has closed.
    - The Daily and Tasks first-Home tips now run at L1, because those features are open.
  - Welcome task (SB-M44-033): no code change was needed. With Tasks at L1, the bootstrap Welcome task is claimable at the first Home. The existing claim path pays +100 once.
  - `HomeBadges.new_features` no longer marks entries that are open from L1 as NEW.
  - UiText: added `BOOSTER_LOCKED_LEVEL`, `FTUE_BOOSTER_INTRO_TITLE` and `FTUE_BOOSTER_INTRO_BODY` (empty, built at runtime). Removed `FTUE_L2_*`.
  - Test seam: `AppState.test_unlock_all` (static, false, never set by the shipping boot). Suites that exercise gated features on L1 fixture saves set it.
  - Docs: AGENTS.md, docs/16 (sections 1.2, 1.2a, 1.4, 1.4a), docs/07 note, scripts/progression/README.md, player_experience_plan_v1.json and the stale code comments.
  - CI: `m44_meta_l1_unlock_ftue` is added to the validate loop with an exact 6/6 guard.
- `a0df4f8a` updates TASKS.md: the three queue rows are DONE and the three checklist rows are `[x]` with evidence.

Files changed: data/config/{feature_unlocks_v1,ftue_onboarding_v1,player_experience_plan_v1}.json; scripts/app/{app_state,ftue_config,ftue_director,main}.gd; scripts/economy/production_action_facade.gd; scripts/gameplay/runtime/production_gameplay_host.gd; scripts/progression/{feature_unlocks.gd,README.md}; scripts/ui/{gameplay_screen,ui_text}.gd; scripts/ui/shop/shop_screen.gd; scripts/ui/home/home_badges.gd; scripts/ui/ceremony/{ceremony_presenter,pack_presenter}.gd; AGENTS.md; docs/07, docs/16; .github/workflows/android-family-first10.yml; tests/m44_meta_l1_unlock_ftue.gd (new); TASKS.md. Existing tests were edited only where they encoded the old values (listed in the Log).

## Acceptance criteria
1. [x] **Owner table exact:** m44_unlock_gate config_reader checks the table and the level walk. The new suite checks the L1 open and locked sets.
2. [x] **No grandfather, same gate for every profile, inventory kept:** m44_unlock_gate no_grandfather and home_gating (an established L1 save has the same disabled tabs). The new suite's old_save_same_gate covers an established save at L3 (boosters and Robots locked, 3 Random + 1 Tornado kept) and at L30, plus a debug frontier at L16.
3. [x] **First Home at L1 has every required meta feature open:** new suite first_home_l1_meta_open. DAILY, TASKS, SHOP and COLLECTION are enabled; ROBOTS 25, EVENTS 30 and RANKS 40 are disabled with their level; the Gift Bar is enabled; the Daily and Tasks badges and coach tips appear on the real panels.
4. [x] **Gate bypass audit:** new suite gate_bypass covers:
   - a deep link to a locked Robots destination lands on Home;
   - direct nav to robots, events and leaderboard opens nothing;
   - Shop booster rows are blocked with "Unlocks at level N";
   - the facade refuses buy, watch, robot unlock and equip, and event join and claim, with nothing spent;
   - the same buy commits once the frontier reaches L11.
5. [x] **Booster edge levels 5/6, 10/11, 15/16, 20/21:** new suite booster_edges checks state and `unlock_level`, the plate, padlock, "LV N" and tooltip, the disabled button, and that a press is refused with charges and SB unchanged. It also checks that Need a Hand never picks a locked booster, and that the starter 2/2/2/2 charges are kept.
6. [x] **Welcome task (SB-M44-033):** new suite welcome_claim_once covers:
   - the balance stays at 1,000 until CLAIM;
   - TASKS at L1 shows the Welcome row ready;
   - 5 rapid taps pay +100 once;
   - one ledger transaction, and the badge clears;
   - exiting and re-entering TASKS shows CLAIMED;
   - after a relaunch the balance is 1,100 and a second claim is refused;
   - replaying bootstrap does not grant a second Welcome;
   - after the day rollover the ordinary 75-SB slot returns and there is no grant;
   - a snapshot re-import cannot install the Welcome task again;
   - an existing save has no Welcome task and ordinary tasks.

   m44_ftue t05-t09 and t14 still pass.
7. [x] **No L2 booster lesson; intros at 6/11/16/21:** new suite booster_intro_once covers:
   - no lesson has boosters, and L2 shows nothing;
   - intros appear exactly at 6, 11, 16 and 21, each only for an unlocked booster;
   - established profiles get none;
   - Skip Tips after the window dismisses them;
   - in real L6 gameplay the intro sits on the real +1 Slot button with a live count;
   - GOT IT sets the flag, and a retry or relaunch does not show it again.

   The hint copy uses the existing off-frame legality path (m46_r07, rm002 and rm003 pass with the intros).
8. [x] **Localization, docs and tests updated:** m51_localization_readiness passes (the empty-body key was renamed). Docs are listed in the Summary.

## Validation
All runs are LOCAL_PASS on Godot 4.7.2 headless (`--headless --path <wt> -s res://tests/<s>.gd`). I ran the 58 validate suites that relate to this change; the cp/remote-content, catalog and real-play suites were skipped because they don't touch this code. I also ran the affected suites that are not in CI. Final results after the fixes:
- **PASS:** m44_meta_l1_unlock_ftue 6/6, m44_unlock_gate 6/6 (0 script errors), m44_new_badge 7/7, m44_pending_packs_gate 6/6, m43_c005_c072 9/9, m43_c005f_phase6 8/8, m44_contextual_coach 7/7, m42_home, m42_navigation, m42_home_v04 18/18, m40_save_system, m40_v04_bootstrap, run_tests, m55_economy_release_regression, all m39* suites, m41_settings, m43_master_c009 12/12, m43_r15_owner_remediation 18/18, m43_r15_001_r01 14/14, m45 8/8, m49 8/8, m50_accessibility 4/4, m51 4/4, m50_color_symbols 10/10, m28_c002_c004 17/17, m28_c002_c003_r01 24/24, m47 14/14, m43_c003_c001 34/34, m43_c005_c074_c077 6/6, m43_master_c005r 8/8, sb_polish_002 11/11, sb_polish_003, sb_polish_004_006 10/10, m43_master_c005 32/32, m43_master_c006 15/15, m43_master_c007 19/19, m54, m43_master_c008 10/10, m43_master_c010 12/12, m43_master_c011_c014 28/28, m43_master_c007r 11/11, campaign_l11_l30 5/5, m43_personal_ranks 8/8, m43_c001a 11/11, m46_r07_ui_legality, m46_rm002_adversarial, m46_rm003_ftue_coach_performance.
- **Expected diagnostics only:** m43_c005f_phase4 19/19 and m43_c005f_phase3 15/15 print their documented injected `explode` SCRIPT ERROR.
- **Failures that also fail on base 0e3e366d (checked in a temporary base worktree, since removed):**
  - m44_ftue 22/23: t21 asserts the opening has no "skip" path, but 881a6c66 added the wordmark tap-skip.
  - m55_long_session: static memory drift (7.6 MB on base).
  - m43_c004_c001_fail_need_a_hand 40/40 with 1 fail: the help-Scrubby art assertion.
  - m28_c002_c001_gameplay_v02 14/14 but with 3 `booster_vfx.gd:122` "previously freed instance" SCRIPT ERRORs.
  - m46_performance frame-time budgets: base failed 1 to 3 timing checks; my runs failed 1 to 6. Only timing checks fail, and it varies with machine load.
- `git diff --check` is clean. The JSON configs parse. `.import` churn was restored and the tree has no tracked changes. Untracked generated `.import`, `.uid` and `.translation` files were left in place as instructed.

## Log
### Round 1
I built the three tasks together as instructed. The acceptance criteria are written above; there is no separate spec.md.

Judgement calls:
- **Locked actions are refused in the facade**, with an injected `feature_gate` Callable that AppState and the host bind. This is the root fix: it covers every UI caller, including Shop, Booster Acquire, Need a Hand, the Robots screen and the Events popup.
- **Intro audience:** booster intros go to new profiles that have not skipped tips, the same as contextual tips. Established saves get none. Skip Tips now also works after the L1-L3 window closes, so the intros can be dismissed.
- **NEW badge:** entries open from L1 never show NEW, because they were never newly unlocked. Otherwise four NEW pills would appear on the first Home.
- **Welcome expiry unchanged:** an unclaimed Welcome task still expires at the local-day rollover. That is the existing owner V03 rule. "Persisted across rollover" is implemented as no duplicate and no re-grant.
- **Test seam:** `AppState.test_unlock_all` is a static test seam in the style of the main.gd `boot_*_override` vars. 20 suites set it because they test boosters, Robots, Events or Ranks behaviour on L1 fixture saves, not the gate.

Test edits where a test encoded the old values or the grandfather rule:
- m44_unlock_gate: new table, no_grandfather case, Home and FTUE expectations.
- m44_ftue: lesson levels, mutations, Daily/Tasks tips at L1, the booster intro replaces the L2 copy, no L4 Daily ceremony.
- m44_new_badge: legacy-level fixture plus a shipped_table case.
- m44_pending_packs_gate: fixture card_packs at 20, plus a shipped_l1_opens case.
- m43_c005_c072 and m43_c005f_phase6: legacy-level fixture, plus a shipped-table assertion; the robot case walks to L25.
- campaign_l11_l30: new table values.
- m42_home: the ROBOTS tab is locked at L1.
- m43_personal_ranks: test seam for p04, p05 and p07.
- m51: empty-key name.
- m46_r07, rm002 and rm003: the intro presentation order seam replaces l2_boosters_a/b.
- `test_unlock_all` was added to the remaining booster, robot and event suites.

No assertion about amounts, charges or rewards was weakened.
