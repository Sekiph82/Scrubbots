STATUS: READY

# Build: M43-C005 ceremonies: verify-close 068-071, build 072

## Summary
068-071 are verify-close: the existing suite passes on the branch and nothing in their code changed. 072 adds the Feature Unlock ceremony for unlocks from the owner unlock table. `CeremonyPresenter.feature_events()` is read-only. For a NEW FTUE profile, it returns one `unlock:<feature_id>` event (kind `feature_unlock`) for each table feature with level > 1 once `AppState.feature_unlocked(id)` is true and the key is not yet seen.
- Events are sorted by table level and come after the gift / set / Master / robot events.
- They use the existing `MetaCeremonies.feature_unlock` popup ("NEW FEATURE!", GOT IT) with the UiText keys `FEATURE_<ID>_NAME/BODY`.
- Icons come from the existing promoted shortcut art. Only Daily, Shop, Tasks and Collection have one. The rest are derived but not presentable (the builder returns null on an empty icon), so no art was invented.
- Acknowledgement is unchanged: `meta_ui.mark_seen` plus the canonical save. If that save fails, the mark is rolled back and the key is snoozed for the session (no re-open loop), and it shows again on the next launch. This rollback applies to every ceremony kind in `_on_closed`.
- Scheduling rides the existing Results barrier and quiet Home drain. No new path.

Commits: 0aa42895 (code, suite, CI, docs), 5f433d1a (TASKS.md).

Files changed:
- scripts/ui/ceremony/ceremony_presenter.gd: FEATURE_ICONS, feature_key, feature_events, pending() includes feature events and skips snoozed ones, save-failure rollback in _on_closed
- scripts/ui/ceremony/meta_ceremonies.gd: feature_unlock doc comment only (no longer "nothing emits this")
- scripts/ui/ui_text.gd: FEATURE_DAILY/SHOP/TASKS/COLLECTION_NAME/BODY
- tests/m43_c005_c072_feature_unlock_ceremony.gd (new, 9 cases a-i)
- tests/m44_ftue.gd: t23 now acknowledges the L4 Daily feature ceremony first and asserts it is alone on the stack, then What's New
- tests/m44_contextual_coach.gd: `_play` marks the walk's feature-unlock ceremonies as seen, so coachmark cases are not covered by the Daily ceremony (which is tested in its own suite)
- .github/workflows/android-family-first10.yml: suite added to the validate list, header comment says 48 total
- docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md: new section 1.4a lists the M43-C005 ceremonies and the 072 rule
- TASKS.md: SB-M43-068..072 checked with evidence, queue row set to DONE

## Acceptance criteria
GODOT = the WinGet 4.7.2 console exe, `--headless --path <worktree> -s res://tests/<name>.gd`.

1. [x] 068-071 still hold: m43_master_c005_meta_ceremonies prints "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)", exit 0. Run before any change and again after.
2. [x] New suite prints "M43 C005 feature unlock ceremony evidence: PASS (9/9 cases, 0 fail)", exit 0, no SCRIPT ERROR.
   a. a_daily_at_l4: no feature event at L3. At L4 only `unlock:daily` is pending. Title "NEW FEATURE!", FeatureName/Body equal the UiText values, actions == ["got_it"], HeroArt is `res://assets/ui/final/home/shortcuts/icon_shortcut_daily.png`.
   b. b_several_ascending: jumping L1 to L21 with set 1 complete gives the order [set:1, unlock:daily, unlock:shop, unlock:tasks, unlock:collection], with stack depth 1 throughout.
   c. c_ack_once_no_grant: one ack per key. A second pending() omits it. Reloading via AppState and an economy + progression export/import replay nothing. The economy snapshot (everything except meta_ui and the clock anchors) is byte-identical while presenting and after, and the unlock state and frontier are unchanged.
   d. d_grandfather_and_l1: an established save at L25 gets zero events. A fresh profile at L1 and at L40 gets no hearts / gift_bar events.
   e. e_no_icon_skipped: robots / ranks / tornado are derived at L40 but only daily/shop/tasks/collection are presentable. For robots the empty icon makes the builder return null, with no error.
   f. f_reduced_same_labels: label texts are identical, full mode has spin meta on HeroGlow, Reduced has none.
   g. g_save_failure_pending: with a fault-injected save, the ack rolls back the seen mark, no popup re-opens in the session, and pending() is empty in the session. After relaunch `unlock:daily` is pending again.
   h. h_keys_distinct: marking `feature_visited:daily` and the What's New key does not hide `unlock:daily`. Acking adds only `unlock:daily`. The shop NEW pill and What's New key are untouched.
   i. i_results_handoff (extra): the real main.tscn runs on a test save path set by boot_save_path_override. Winning L3 sets the Results ceremony barrier. After the reveal, `unlock:daily` is alone on top with no coachmark showing. Acking releases the barrier and the mark is durably saved.
3. [x] `grep -n "unlock:" scripts/ui/ceremony/ceremony_presenter.gd` shows lines 19 (doc) and 75 (`return "unlock:" + feature_id`). The grep of meta_ceremonies.gd for scrub_bucks|wallet|grant only hits the existing comments and the REWARD_ROWS / ART keys, with no economy mutator calls (I only changed a comment there).
4. [x] Regression: all 20 listed suites printed PASS with 0 fail and exited 0:
   - m43_master_c005 32/32, m44_unlock_gate 6/6, m44_new_badge 6/6, m44_contextual_coach 7/7, m44_ftue 23/23
   - m43_master_c008_robots 10/10, c009_daily 12/12, c011_c014 28/28, m43_r15_owner_remediation 18/18, c005f_phase3 15/15, phase4_qa_r01 4/4, phase4_terminal_home_micro 19/19, c001a 11/11
   - m39d PASS, m39_v04_integration PASS, m55_economy_release_regression PASS, m55_long_session PASS, m40_save_system PASS, m50_accessibility_audit 4/4, m51_localization_readiness 4/4

   The only SCRIPT ERRORs were the documented injected FaultySpark ones in c005f_phase3 (1, announced as EXPECTED_FAULT_INJECTION) and phase4_terminal_home_micro (CI filters these as INJECTED).

   The first run failed m44_contextual_coach c04 (3 fails) and m44_ftue t23 (2 fails). Both failures were the new L4 Daily ceremony correctly showing first (a coachmark is hidden under a modal, and What's New queues behind meta ceremonies). I adjusted the tests as described above and both now pass.
5. [x] `git diff --check HEAD~2 HEAD` is clean. The workflow list grep matches (`m43_c005_c072_feature_unlock_ceremony; do`). TASKS.md has 068-072 `[x]` with evidence and the queue row is DONE.

## Validation
- All 48 suites in the CI validate list were run locally on the final code. Each exited 0 with a PASS last line, and the only SCRIPT ERRORs were the injected phase4 ones. Includes run_tests "RESULT: ALL PASS", cp06 16/16, m46_performance 22/22, m49 8/8, m50_color_symbols 10/10, m47_touch 14/14, m43_c003_c001 34/34. Status: LOCAL_PASS.
- Non-CI suites from the spec (c005 master, c008, c011_c014, phase3, phase4_qa_r01) are LOCAL_PASS. They ran before the final comment-only edit to meta_ceremonies.gd and the m44 test edits.
- git diff --check: clean.
- The worktree still has about 1515 untracked or modified `.import` / `.uid` files. They were there when the job started (Godot import of the imported worktree) and their content is unchanged apart from line endings. I left them unstaged and committed no test `.uid`.

## Log
### Round 0
- Ran m43_master_c005 on the branch before changing anything: 32/32 PASS, so 068-071 are verify-close with no code change.
- Built 072 in CeremonyPresenter: derivation, FEATURE_ICONS, and save-failure rollback with a session snooze. Added UiText copy, the new suite (9 cases), the CI list entry and header count, the docs/16 section 1.4a, and a stale comment fix in meta_ceremonies.gd.
- Product choices made under owner delegation:
  - Presentable set = Daily / Shop / Tasks / Collection (existing shortcut icons).
  - card_packs (same level as Collection), robots (the Robot Unlock ceremony covers it), events / achievements / ranks (no icon) and the four boosters (left to the SB-M44-031 part 2 lessons, so a later lesson does not show a second popup) are skipped. They are listed in TASKS.md and docs.
  - The unlock level is not shown in the body text.
- Two M44 suites needed small test adjustments for the new L4 ceremony (see criterion 4).
