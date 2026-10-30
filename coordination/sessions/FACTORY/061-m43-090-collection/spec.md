# M43 Collection screen verify-close + pack-inventory entry (SB-M43-090..101)

> Feature: Factory job 061-m43-090-collection. SB-M43-090..095 (Collection main screen 15x9, album visual master, set progress, set detail, card detail, Exchange flow) and SB-M43-096..101 (duplicate exchange + EXCHANGE ALL, live SB values, pack inventory entry, reward history, locked sets, perf).

## Context
Worktree `C:/Users/sekip/Desktop/ScrubBots-factory/061-m43-090-collection`. Most of this is already built (same pattern as jobs 057-060).

- UI: `scripts/ui/collection/collection_screen.gd` (album, set detail, card detail popup, exchange confirm; header says pack-opening entry "is NOT here (SB-M43-098)"). Strings `COLLECTION_*` in `scripts/ui/ui_text.gd`.
- Authority: `CollectionInventory`, `CardsExchangeService`, `RewardGrantService` via the economy facade (`scripts/economy/economy_services.gd`); UI does not mutate. Exchange values in `data/config/economy_rewards_v1.json` (25/75/200/500).
- Suite `tests/m43_master_c007_collection.gd` has 13 cases k01..k13 (album 15 sets + Master row, 0/135 summary, set reward + claimed state, set detail NEW/EXTRAS/not found, card detail EXCHANGE 1 via facade, EXCHANGE ALL atomic, cancel, rapid taps single exchange, values table, no art leak, 135-card perf + touch, legacy no NEW flood, exchange inside Collection not Home, pity copy). Local run: 12 cases clean; k10 fails only the warm set-detail budget (410 ms vs 150 ms, headless local load; CI is the arbiter). `tests/m54_collection_set_master_exactly_once.gd` passes (set/master claim exactly-once).
- Neither suite is in the CI validate list in `.github/workflows/android-family-first10.yml` (currently 53 suites; the list ends `... m43_master_c006_shop; do`, and exact-summary guards follow, e.g. the `M43 master C006 Shop evidence: PASS (15/15 cases, 0 fail)` block).
- Real gap: SB-M43-098. No Collection-side pack entry exists. The durable earned-pack FIFO is `scripts/collection/pending_pack_queue.gd` (`PendingPackQueue`, `count_of(kind)`, `size()`), exposed as `economy.pending_packs`. `Main.request_earned_packs()` (scripts/app/main.gd ~410) drains it through the M43-C005 pack ceremony (`get_pack_presenter()`). No stored-inventory mechanic is to be invented: the entry only reflects and opens this existing queue.
- Gaps to check (assertion-only unless the code lacks them): SB-M43-099 reward history/status visibility (Master row and set rows already show reward + CLAIMED / on completion; k02 covers claimed state); SB-M43-100 locked/future sets (only 15 canonical sets exist, none locked); localization (all text via `UiText.t`).

## Requirements
1. Task classification, recorded in TASKS.md: verify-close 090, 092, 093, 094, 095, 096, 097, 099, 101 (after the assertions below); 091 verify-close as "existing promoted assets, no new art, §0D.1 owner visual sign-off given"; 098 build; 100 verify-close as "no locked/future set content exists; screen renders exactly the 15 canonical sets with no placeholder rows or fake progress" backed by an assertion.
2. Pack entry (SB-M43-098) in `collection_screen.gd`: a Collection-owned row showing live pending counts from `economy.pending_packs.count_of("standard")` / `("premium")`, with an OPEN button enabled only when `pending_packs.size() > 0`, that calls `Main.request_earned_packs()` (the existing C005 route). It does not draw, grant, or modify the queue or Collection itself. Hidden or disabled with an empty-state label when 0. Re-read live after a drain/grant. New strings go in `ui_text.gd`.
3. Add assertion cases to `tests/m43_master_c007_collection.gd` (append to `EXPECTED_CASES`, keep the case ledger guard): k14 pack entry (counts, button state 0 vs >0, press routes to `request_earned_packs`, queue unchanged by the UI itself and no card granted by pressing alone beyond the existing ceremony path); k15 history/status (every completed set row and Master row show CLAIMED vs on-completion, and re-opening after claim shows CLAIMED with no second grant, balance unchanged); k16 no locked/fake rows (album has exactly 15 set rows + Master, no row for a nonexistent set, progress sums equal inventory truth); k17 duplicate-heavy inventory (e.g. 9x of every card) EXCHANGE ALL total equals sum(extras x value) and every owned() ends at 1, exchange through the facade exactly once.
4. k10 perf budget stays unchanged unless it is flaky purely on load: do not loosen the 150 ms warm budget. If locally failing, the builder reports it as machine-load and relies on CI.
5. Add `m43_master_c007_collection` and `m54_collection_set_master_exactly_once` to the validate suite list in `.github/workflows/android-family-first10.yml`, with exact-summary guards: `M43 master C007 Collection evidence: PASS (17/17 cases, 0 fail)` (adjust N if the builder ends with a different case count) and the m54 `M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS` line. Update the header comment (suite total 55). Mirror the C006 guard block style.
6. Docs: tick 090..101 in `TASKS.md` (Autonomous Queue READY lines 55-56 updated/removed per factory convention) with LOCAL_PASS evidence, honest peer-review label placeholders; update AGENTS.md only if it lists the Collection screen or CI suite count.

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c007_collection.gd` prints `M43 master C007 Collection evidence: PASS (17/17 cases, 0 fail)` (k10 timing excepted if load-bound locally; report it).
2. `"$GODOT" --headless --path <worktree> -s res://tests/m54_collection_set_master_exactly_once.gd` prints `M54 COLLECTION SET/MASTER EXACTLY-ONCE: PASS`.
3. Pack entry: with 2 standard + 1 premium queued the Collection shows those counts and OPEN is enabled; with an empty queue OPEN is disabled/hidden (k14).
4. `grep -c "Collection\|collection" ` n/a; instead `grep -n "request_earned_packs" scripts/ui/collection/collection_screen.gd` shows the route, and `grep -nE "\.(enqueue|remove|grant|exchange)\(" scripts/ui/collection/collection_screen.gd` shows no direct queue/inventory mutation by the UI beyond existing facade exchange calls.
5. `.github/workflows/android-family-first10.yml` contains both suites in the validate list and both exact-summary guards; `grep -c` of each suite name is at least 2.
6. `python tools/run_suites.py` passes as regression gate (m46_performance may fail locally from machine load; CI is the arbiter).
7. `git diff --check` is clean; `git diff --stat` touches only: `collection_screen.gd`, `ui_text.gd`, `tests/m43_master_c007_collection.gd`, the workflow, `TASKS.md`, and the job folder.
8. TASKS.md rows 090..101 are ticked with the classification from Requirement 1.

## Out of scope
New art or album redesign; new currencies, a fifth booster, or a stored pack-inventory mechanic beyond the existing `PendingPackQueue`; locked/future set content; changing exchange values, set rewards or economy config; loosening the perf budget; shop/home changes; shipping free manual 2x.

## Assumptions
- Pack entry reflects the existing durable earned-pack queue (no purchase/inventory mechanic invented), since packs earned but unopened are exactly what an "inventory/open entry" can mean without new mechanics.
- SB-M43-100 has no content to present because only 15 canonical sets exist; asserting no placeholder/fake rows satisfies "without leaking nonexistent cards or fake progress".
- Localization (101) is satisfied by all strings routed through `UiText.t`; no new languages are added.
- Visual master (091) is closed on existing promoted assets under `assets/ui/final/collection/` plus the §0D.1 sign-off.
- k10's local failure is load-related headless timing (cold 969 ms / warm 410 ms), CI is the arbiter.
