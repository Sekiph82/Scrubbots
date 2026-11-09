# Review round 1 - job 136 featured card onboarding (SB-M44-026 + 022..023)

Schedule: verified by script against coordination/OWNER_META_PROGRESSION_DESIGN_V01.md. 135 entries, 135 distinct cards, sorted by level. Set 01 levels are 20/22/24/26/29/32/35/38/40. Sets 02..15 equal the owner range start plus 0/10/20/30/40/50/60/70/90 in catalogue order. set_ranges match the owner doc.

Guarantees: L20 gets the fixed card s1_c0 (Scrubby). L30 and L40 get the first Set 01 card the player does not own. This matches owner doc line 330.

Transaction: the grant is step 3 of FirstClearTransaction, inside the existing snapshot and rollback. It is skipped when an earlier stage failed. The tx id `featured_card:L<n>:<card>` goes through RewardGrantService, so it is idempotent. grant_milestone also refuses when any applied tx for that level exists. Packs, RNG and pity are untouched (the test asserts this).

Open items in the owner doc (lines 343, 326, 329): the owner left the Set-01-complete behaviour undefined, so the duplicate fallback card is a sound default. It is an ordinary card, not an invented currency. "First clear only" and "no retroactive grant" are consistent with "Ranges are featuring periods, not automatic grants". The doc does not contradict either.

Gates (023): the daily/tasks facade refusals are consistent with the Robots/Events gates and cannot block players, because both gates are L1 now.

Ceremony: it holds Results correctly. The only fixture that was affected, the L30 case in c001b, pre-marks the event as seen. That is fair because it tests the end-of-content layout, not the ceremony. The c011 a07 kind-list update is legitimate. EN/TR strings are present. An unknown card gives a null popup and no fabricated card.

Tests run in the worktree (Godot 4.7.2 headless):
- m44_featured_card_onboarding: PASS 8/8
- m43_master_c007_collection: PASS 19/19
- m43_master_c007r_pity: PASS 11/11
- m39_v02_atomicity: PASS
- m43_c001b_won_results_visual: PASS 11/11

Non-blocking notes:
- grant_milestone returning applied=false when reward.grant fails is not turned into a rollback. The handler cannot fail today, so this is acceptable.
- The worktree still holds untracked Godot .uid files from my import run. They are generated and not part of the branch.

No must-fix items.

VERDICT: PASS
