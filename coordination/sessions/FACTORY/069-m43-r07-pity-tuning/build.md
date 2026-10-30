STATUS: READY

# Build: SB-M43-R07-001..006 pity threshold balance sim + First Collection Sprint

## Summary
The pity guarantee is now on, and a First Collection Sprint brings Set 1 completion forward.
Shipped `collection.pity` = `{threshold: 3, first_sprint_threshold: 1}`.
- Plain rule (R07-001/002): 3 earned packs in a row with no NEW card make the next pack
  guarantee a missing card.
- Sprint (R07-006): while Set 1 is incomplete, "new" means a new Set 1 card and the threshold
  is 1. After a pack with no new Set 1 card, the next pack guarantees one. This uses the same
  counter, save section, substitution path (Premium card 0 kept) and UI copy. The sprint ends
  for good at Set 1 9/9.
- No pack source, reward table, Bot Part amount, unlock level or robot value changed.

Pity alone cannot reach the sprint window: Set 1 p50 stays at L93 for every threshold, because
draws are uniform over 135 cards and early packs always contain some NEW card. That is why the
sprint extension was needed. I rejected adding guaranteed-new cards to the repeating Gift/Daily
tables: it would change owner tables permanently and add 500 SB fallbacks every cycle once the
collection is complete.

Files changed:
- scripts/collection/pack_pity.gd (`first_sprint_threshold`, `focus_set(inventory)`, inventory-aware threshold/guarantee_due/guaranteed_next)
- scripts/collection/card_pack_service.gd (`_has_new(drawn, focus)`)
- scripts/collection/collection_inventory.gd (`card_set()`)
- scripts/ui/collection/collection_screen.gd (`guaranteed_next(e.collection)`)
- data/config/economy_rewards_v1.json (`collection.pity`)
- tests/m43_master_c007r_pity.gd (p06 shipped-value case, new p10/p11; p01/p09 own Set 1 first so they measure the plain rule)
- .github/workflows/android-family-first10.yml (suite + exact 11/11 guard, header 60 total)
- tools/sim_pack_pity.gd (new)
- docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md (new)
- TASKS.md (R07-001..006 ticked, queue row DONE)

Commits (not pushed): 3068dc55 sim + doc, e9f0eeed tuning + tests + CI, a03a0309 TASKS.md.

## Acceptance criteria
1. [x] Simulation tool: tools/sim_pack_pity.gd drives the real EconomyServices graph:
   WinStreakService → GiftMeterService.claim, DailyService.claim_login, PendingPackQueue, and
   CardPackService/CollectionInventory/PackPity. Each run uses 200 seeds and a temp config per
   candidate. It reports Set 1 p10/p50/p90, the share by L40, cards owned at L40, full
   collection p10/p50/p90 and the longest dry run. I ran it at 3, 4 and 5 levels/day with 15%
   losses, and at 4 levels/day with 0% and 30% losses. All tables are in the doc.
2. [x] Threshold chosen and shipped as data: threshold 3 (dry runs capped at 3 packs instead of
   36–64; full collection p50 L334 → L290). Pity alone could not reach the window, so I added
   the smallest data-driven sprint value (`first_sprint_threshold: 1`).
3. [x] Set 1 p50 within L20–40: L38 at the 4 levels/day + 15% losses baseline (p10 31, p90 51,
   57% by L40); L37 at 3/day; L41 at 5/day (just outside); L25 with 0% losses. With 30%
   losses it is L57 (6% by L40), so the window is missed for players who lose often. All of
   this is documented.
4. [x] Test + CI: p06 now asserts the shipped config `{threshold 3, first_sprint_threshold 1}`,
   that the guarantee is due exactly at 3, and that the 4th pack holds the missing card. p10
   checks the sprint counter rules and that guaranteed packs always hold a missing Set 1 card;
   Set 1 completed after 17 packs and the threshold reverts to 3 afterwards. p11 checks that the
   "next pack guaranteed" copy follows the sprint state. All other cases are kept. The suite is
   in the CI loop with the exact guard `M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)`,
   the header reads "60 total", and `python tools/run_suites.py --list` prints 60 entries
   ending with m43_master_c007r_pity.
5. [x] Doc: docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md covers the rules, method, player
   assumption (3–5 levels/day, Daily and every Gift milestone claimed, 15% loss baseline;
   ad-gated, event and comeback packs excluded; L1..L10 not used as a calibration reference),
   the tables, the choice and the rationale, including robot pacing: only the existing Set 1
   reward of 350 SB + 5 BP now arrives earlier.
6. [x] Regressions: all PASS (see Validation).
7. [x] TASKS.md: R07-001..006 ticked with SHAs and LOCAL_PASS evidence, queue row DONE.
   CRLF kept (1991/1991 CRLF lines before and after). The diff is 7 lines: those 6 plus the
   queue row.

## Validation
`python tools/run_suites.py <13 suites>`: aggregate=PASS (13/13), every suite exit 0 and diag 0.
- m43_master_c007r_pity PASS (11/11 cases, 0 fail)
- m43_master_c007_collection PASS (19/19)
- m44_pending_packs_gate PASS (6/6)
- m43_master_c005_meta_ceremonies PASS (32/32)
- m54_collection_set_master_exactly_once PASS
- m39d_daily_collection, m39e_full_matrix, m39a_economy_core, m39_v03_full_surface PASS
- m55_economy_release_regression PASS
- m43_master_c010_meta PASS (12/12)
- m43_master_c005r_gift_micro_progress PASS (8/8)
- m43_c005_c074_c077_celebrations PASS (6/6)

These suites are not in the CI loop, so I ran them directly with $GODOT. All exit 0 with a
final PASS line:
- m43_c005_c008_pack_commit_transaction PASS (27/27), diag 0
- m43_c005f_phase2_r01_earned_pack_runtime PASS (22/22). Its 3 SCRIPT ERROR lines are the
  suite's own announced EXPECTED_FAULT_INJECTION ('explode' on null in a spy plugin).
- m43_c005_c006_standard_pack_presentation PASS (21/21), diag 0
- m43_c005_c007_premium_pack_presentation PASS (19/19), diag 0
- m43_c005_c001_ceremony_visual_masters PASS (17/17), diag 0

Other checks:
- `git diff --check`: clean.
- `git status --porcelain`: empty. I reverted the one-time `--import` noise (240 .import files
  and project.godot) and removed the untracked .uid/.import files that the import created.
- I removed leftover user:// sim temp configs.

All results are LOCAL_PASS (Godot 4.7.2 headless, Windows). No CI run.

## Log
### Round 0
- Wrote spec.md.
- Prototyped in Python, then built tools/sim_pack_pity.gd on the real economy graph.
- Found that no plain threshold moves Set 1 before about L90.
- Compared sprint thresholds 1/2/3 against permanent guaranteed-new additions to the
  Gift/Daily tables. Chose threshold 3 + sprint 1.
- Implemented the change and updated and extended the C007R suite. Added it to the CI loop.
- Wrote the doc, ran the regressions and updated TASKS.md.
- Note for review: the sprint is a small extension of the pity rule. During the sprint, a NEW
  card from another set does not reset the counter. R07-006 is the authority for that
  deviation from R07-001's "any new card resets", and it applies only until Set 1 is complete.

CI: GitHub Actions run 41077118828 success; M43-C007R verdict=PASS (11/11).
