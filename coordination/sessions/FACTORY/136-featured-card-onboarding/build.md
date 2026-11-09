STATUS: READY

# Build: Featured Card schedule + milestone cards (SB-M44-026) and L1 Collection onboarding / data-driven gates (SB-M44-022..023)

## Summary
Branch `factory/136-featured-card-onboarding`, commits e5075c40 (data + code + tests) and d436d5e5 (TASKS.md). Not pushed.

- `data/config/featured_cards_v1.json` (new): all 135 cards scheduled by level. Set 01 uses the owner levels 20/22/24/26/29/32/35/38/40. Sets 02..15 use their owner featured range start (OWNER_META_PROGRESSION_DESIGN_V01 §2) plus +0/+10/+20/+30/+40/+50/+60/+70/+90, in catalogue order. `guarantees`: L20 `s1_c0` (Scrubby); L30 and L40 `set: 1` with an explicit `fallback_card` (L30 s1_c4 Squeegee, L40 s1_c8 Scrubmaster X). Every featured range start was defined in the owner doc, so no question went to the owner.
- `scripts/collection/featured_cards.gd` (new): reads the schedule, `grant_milestone(economy, level)`, `milestone_cards(reward)`.
- `scripts/economy/first_clear_transaction.gd`: step 3 grants the milestone card on a FIRST clear, inside the existing snapshot/rollback.
- `scripts/economy/economy_services.gd`: the `featured_card` reward handler adds the card named in the parent tx `featured_card:L<n>:<card>`.
- `scripts/economy/ceremony_events.gd`, `scripts/ui/ceremony/meta_ceremonies.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`: one `featured_card` ceremony per grant (card art, name, "Level N reward, added to your Collection.").
- `scripts/economy/production_action_facade.gd` (023 gap): `claim_daily_login` is now refused while `daily` is locked, and `claim_daily_task` / `claim_daily_all_tasks` while `tasks` is locked. This matches the existing Robots/Events gates.
- `scripts/collection/README.md`: one line documenting Featured Cards.
- Tests: new `tests/m44_featured_card_onboarding.gd` (8 cases), added to CI validate with an exact 8/8 guard in `.github/workflows/android-family-first10.yml`. Two fixture updates: `tests/m43_c001b_won_results_visual.gd` (the L30 case commits the L30 card beforehand, because its ceremony would otherwise hold Results) and `tests/m43_master_c011_c014.gd` (a07: canonical kinds now include `featured_card` -> reward).
- `TASKS.md`: SB-M44-022, 023 and 026 are checked off with evidence, and both queue rows are now DONE.

Design choices (open details in the owner doc, defaulted rather than escalated):
- "At L20/L30/L40" means the first clear of that level. Replays never grant.
- Saves that are already past L20, L30 or L40 do not get the card retroactively.
- Which unowned card: the first Set 01 card not owned yet, in schedule order.
- When Set 01 is already complete, the row's `fallback_card` is granted as an ordinary duplicate. The economy doc has no SB fallback for this, so none is used.

## Acceptance criteria
1. [x] The schedule covers all 135 cards exactly once with correct offsets: `m44_featured_card_onboarding` schedule_exact. 135 entries; every catalogue id appears once; Set 01 levels and names match the owner table; sets 02..15 = owner start + offset[k] with catalogue card index k+1; set_ranges match the owner starts; sorted by level; guarantees rows checked.
2. [x] Scrubby is guaranteed at L20, once across relaunch and import: l20_scrubby_once. The commit returns `{applied: true, card: s1_c0}`. A duplicate WON or a direct regrant gives nothing. After relaunch (reload from save) owned is still 1 and there is no regrant. Snapshot import into a fresh profile gives no regrant.
3. [x] L30/L40 grant an unowned Set 01 card once: l30_l40_unowned_set01. With s1_c0/c1/c3 owned, L30 grants s1_c2. With 8/9 owned, L40 grants s1_c7, completing Set 01 under the normal set-reward rule. The ledger holds exactly 2 grants. all_owned_fallback: Set 01 complete -> L30 grants Squeegee as a duplicate (owned 2), with no second set reward.
4. [x] Packs are otherwise unchanged: the L20 grant leaves the pack RNG state and the pity count untouched. other_levels_nothing: first clears of L21..L29 (including featured-only L22/24/26/29) leave the Collection unchanged. m43_master_c007_collection 19/19, m43_master_c007r_pity 11/11 and m54_collection_set_master_exactly_once PASS.
5. [x] The milestone card is presented: ceremony case. There is exactly one pending `featured_card:L20:s1_c0` event, and the popup shows Scrubby art, name and the Level 20 line. An unknown card produces no ceremony. Once acknowledged, it is not shown again after relaunch.
6. [x] Onboarding at L1 (022): l1_onboarding_sprint_pity. On a fresh new profile at L1, Collection/Card Packs/Tasks/Daily are open and the First Collection Sprint is on Set 01 (threshold 1). The pity line does not show in the real Collection album. The first earned pack opens at L1. Once a guarantee is due, the album shows "NEW CARD GUARANTEED NEXT PACK", and the next pack really holds a missing Set 01 card. After that the line hides again.
7. [x] Daily Orders, Weekly and First-Try unlocks are data-driven and Events stays at L30 (023): data_driven_gates. `feature_unlock_level("events") == 30`, and First-Try join is refused at L1. With Daily 4 / Tasks 12 written into the in-memory table at L1, all three daily claims are refused and the economy is unchanged. On the shipped L1 table the Daily claim commits. At L30 Events are open.
8. [x] Tests that still assumed the old L20/L12 gates: none were left. The only `LEGACY_LEVELS` / `card_packs = 20` uses are explicit in-memory fixtures, already labelled as such by SB-M44-032.

## Validation
Godot 4.7.2 console (`--import` once). Every suite listed exited 0 with no SCRIPT ERROR or Parse Error, and its last line was PASS. LOCAL_PASS:
- m44_featured_card_onboarding: PASS (8/8 cases, 0 fail)
- m43_master_c007_collection 19/19, m43_master_c007r_pity 11/11, m54_collection_set_master_exactly_once PASS, m44_meta_l1_unlock_ftue 6/6, m54_regression_pack_028_036 12/12
- m43_master_c005_meta_ceremonies 32/32, m43_c005_c001_ceremony_visual_masters 17/17, m43_master_c011_c014 29/29 (after the a07 update), m43_c001b_won_results_visual 11/11 (after the L30 fixture update)
- m39_v04_integration PASS, m43_c001a_results_foundation 11/11, m44_unlock_gate 6/6, m44_pending_packs_gate 6/6, m43_master_c009_daily 12/12, m43_c005_c074_c077_celebrations 6/6, campaign_l11_l30 5/5, m44_new_badge 7/7, m56_analytics_taxonomy 27/27, m54_regression_pack_022_027 12/12, m43_c005_c072_feature_unlock_ceremony 9/9, m51_localization_readiness 8/8, m43_master_c010_meta 12/12, cp04_remote_content_runtime 28/28

Two suites fail for reasons unrelated to this change. Neither is in the CI list.
- m43_c005f_phase2_results_pack_feel: "REWARD = 8-particle pickup" fails exactly the same with `featured_cards_v1.json` removed.
- m43_c005f_phase3_meta_rewards_acquisition: it reports `scripts/ui/credits_screen.gd` (from 4222bbd7) naming a plugin. That file is not touched here.

Other checks:
- `git diff --cached --check` was clean.
- I restored project.godot and the `.import` churn, and deleted the Godot-generated untracked `.uid`/`.import`/`.translation` files. `git status --porcelain --untracked-files=all` is empty.

## Log
### Round 1
- Read the owner meta-progression doc, the economy lock, feature_unlocks_v1 and the collection/pity/pack/ceremony code.
- Built the schedule data, the FeaturedCards reader/guarantee, the first-clear hook, the reward handler, the ceremony with EN/TR text and the daily/tasks facade gate.
- Added the new suite to CI. Fixed the two fixtures broken by the new L30 ceremony and the new ceremony kind.
- Note for merge: `.github/workflows/android-family-first10.yml` and `TASKS.md` may conflict textually with parallel jobs that also append suites or rows. The edits are one appended suite name, one guard block, one header comment line, two queue rows and three checklist lines.
