# Spec: SB-M43-R07-001..006 pity threshold balance sim + First Collection Sprint

Source: TASKS.md SB-M43-R07-001..006 (queue row "READY SB-M43-R07-001..006"). The pity mechanism
(scripts/collection/pack_pity.gd, CardPackService earned-pack path, COLLECTION_PITY_NEXT copy,
tests/m43_master_c007r_pity.gd) already exists; the shipped config has no threshold. Open work:
balance-simulate and ship a threshold (001), and tune a First Collection Sprint so an ordinarily
engaged fresh player completes Set 1 in roughly L20-40 from earned sources (006).

Economy lock (coordination/OWNER_ECONOMY_REWARDS_V01.md, data/config/economy_rewards_v1.json):
no new currency, no fifth booster, no paid/ad acceleration of pity, no UI economy mutation,
card packs open from L20 (earlier earned packs queue). Robot-unlock pacing must not change.
L1..L10 are not calibration references.

## Acceptance criteria

1. A deterministic headless tool (tools/sim_pack_pity.gd) drives the real EconomyServices
   graph (Gift Meter / Daily claims, PendingPackQueue, CardPackService / CollectionInventory /
   PackPity) over >= 200 seeds and reports per pity candidate: Set 1 completion level
   p10/p50/p90, share by L40, and full-collection pace.
2. A threshold is chosen from the table and shipped data-driven in `collection.pity`; if pity
   alone cannot reach the window, the smallest data-driven addition that does, without changing
   any pack source, reward table, Bot Part amount or unlock level.
3. Shipped tuning puts the Set 1 p50 within L20-40 at the stated baseline cadence.
4. tests/m43_master_c007r_pity.gd: p06 asserts the shipped threshold (not absence), all other
   cases kept, new assertions for any added behaviour; the suite is in the CI validate loop with
   an exact-summary guard, header count bumped, `tools/run_suites.py --list` shows it.
5. docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md: assumptions, table, choice, rationale.
6. Regressions PASS: m43_master_c007r_pity, m43_master_c007_collection, m44_pending_packs_gate,
   m43_c005_c008_pack_commit_transaction, m43_master_c005_meta_ceremonies,
   m54_collection_set_master_exactly_once, and the other suites reading the collection config.
7. TASKS.md R07-001..006 ticked with LOCAL_PASS evidence and the queue row marked DONE;
   CRLF preserved, only those lines changed.
