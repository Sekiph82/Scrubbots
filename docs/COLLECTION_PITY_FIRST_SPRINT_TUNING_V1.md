# Collection pity + First Collection Sprint tuning V1

Tasks: SB-M43-R07-001..006 (factory job 069). Shipped values live in
`data/config/economy_rewards_v1.json` → `collection.pity`:

```json
"pity": { "threshold": 3, "first_sprint_threshold": 1 }
```

## Rules (unchanged mechanism, one sprint extension)

- `threshold` (R07-001/002): consecutive earned Standard/Premium packs with no NEW card count up;
  any NEW card resets. At `count >= threshold` the next earned pack is guaranteed a missing card
  (the last draw is replaced; Premium card 0 stays Rare-or-better). Nothing is fabricated when
  the collection is complete. 0 / absent = off.
- `first_sprint_threshold` (R07-006): while **Set 1** is incomplete, "new" means a new **Set 1**
  card and this threshold applies. The guaranteed card is a Set 1 card because
  `first_missing_eligible_card()` walks sets in order. Once Set 1 is 9/9 the plain rule applies
  for good. 0 / absent = no sprint.
- Same counter, same save section (`pack_pity {version, count}`), same earned-only path
  (R07-004), same "NEW CARD GUARANTEED NEXT PACK" copy when due (R07-005). No new currency,
  no source, reward table, Bot Part or robot-unlock value changed.

## Method

`tools/sim_pack_pity.gd` (headless, deterministic per seed, 200 seeds) drives the real
`EconomyServices` graph for a fresh player: first-clear wins → `WinStreakService` → Gift Meter
milestones claimed through `GiftMeterService.claim`, Daily login claimed through
`DailyService.claim_login`, earned packs queued in `PendingPackQueue` and opened with the real
`CardPackService` / `CollectionInventory` / `PackPity` once the `card_packs` frontier (L20) is
reached; Daily from the `daily` frontier (L4). Each candidate is a temp copy of the economy
config with only `collection.pity` replaced.

Sources counted: Gift Meter (10/250/500 Standard, 1000 Premium + guaranteed-new card) and the
Daily login cycle (D2/D4 Standard, D5 Premium). Excluded (conservative): ad-gated Rewarded
Daily packs, events, comeback gifts, purchases (none exist).

**Ordinarily engaged player (assumption):** plays 3–5 new levels per local day (baseline 4),
claims Daily and every Gift milestone, loses 15% of attempts (a loss resets the win streak and
the level is retried). Sensitivity: 0% and 30% losses. "Level" = last level cleared when the
event happened. The first ten campaign levels are not used as a calibration reference; they
only feed the Gift Meter like any other level.

## Results (200 seeds each)

Columns: Set 1 completion level p10/p50/p90, share of players with Set 1 by L40, distinct cards
owned at L40 (p50), full 15-set collection level p10/p50/p90, longest run of all-duplicate packs
while cards were still missing (outside the sprint).

### Baseline: 4 levels/day, 15% losses

| threshold | sprint | Set 1 p10 | p50 | p90 | by L40 | cards@L40 p50 | full p10 | full p50 | full p90 | max dry packs |
|---|---|---|---|---|---|---|---|---|---|---|
| off | off | 71 | 93 | 124 | 0% | 43 | 292 | 334 | 383 | 44 |
| 2 | off | 71 | 93 | 123 | 0% | 43 | 243 | 274 | 305 | 2 |
| 3 | off | 71 | 93 | 124 | 0% | 43 | 257 | 290 | 323 | 3 |
| 4 | off | 71 | 93 | 124 | 0% | 43 | 266 | 299 | 336 | 4 |
| 5 | off | 71 | 93 | 124 | 0% | 43 | 270 | 307 | 345 | 5 |
| 6 | off | 71 | 93 | 124 | 0% | 43 | 276 | 312 | 349 | 6 |
| **3** | **1** | **31** | **38** | **51** | **57%** | **43** | **256** | **285** | **314** | **3** |
| 3 | 2 | 39 | 51 | 62 | 13% | 44 | 255 | 285 | 320 | 3 |
| 3 | 3 | 46 | 57 | 72 | 3% | 44 | 254 | 287 | 317 | 3 |
| 2 | 1 | 31 | 38 | 51 | 57% | 43 | 244 | 273 | 300 | 2 |
| 4 | 1 | 31 | 38 | 51 | 57% | 43 | 266 | 295 | 329 | 4 |

### Sensitivity for the chosen pair (threshold 3, sprint 1)

| cadence | Set 1 p10 | p50 | p90 | by L40 | full p50 | without sprint: Set 1 p50 |
|---|---|---|---|---|---|---|
| 3 levels/day, 15% losses | 30 | 37 | 46 | 66% | 256 | 90 |
| 4 levels/day, 15% losses | 31 | 38 | 51 | 57% | 285 | 93 |
| 5 levels/day, 15% losses | 31 | 41 | 52 | 49% | 307 | 96 |
| 4 levels/day, 0% losses | 24 | 25 | 27 | 100% | 194 | 64 |
| 4 levels/day, 30% losses | 45 | 57 | 65 | 6% | 417 | 153 |

Reproduce: `godot --headless --path . -s res://tools/sim_pack_pity.gd -- --seeds=200 --lpd=4 --loss=0.15`.

## Choice and rationale

1. **No pity threshold alone reaches the sprint window.** Draws are uniform over all 135 cards,
   so every early pack holds some NEW card and the plain counter almost never fires before L40;
   Set 1 p50 stays at L93 for every threshold. The guarantee only matters later, when
   duplicates dominate.
2. **`threshold: 3`.** Without pity the late game has dry runs of 36–64 all-duplicate packs.
   3 caps them at 3 and finishes the full collection about 13% sooner (p50 L334 → L290 at
   baseline). 2 is noticeably more generous (L274, a guarantee every third pack when dry); 4–6
   change little against 3. 3 is the middle: a dry spell never lasts longer than three packs.
3. **`first_sprint_threshold: 1`.** It is the only sprint value that puts the Set 1 p50 inside
   L20–40 for the 3–4 levels/day baseline (L37–38; L41 at 5/day, because a faster player
   reaches L40 in fewer calendar days and so has fewer Daily packs). 2 and 3 land at L46–61.
   A sprint pack without a new Set 1 card makes the next pack guarantee one, so about half the
   early packs carry a Set 1 card. Set 1 is not handed over at once when packs unlock at L20
   (p10 L30–31).
4. **Smallest change.** No pack source, reward bundle, Bot Part amount, unlock level or robot
   cost changed. Adding guaranteed-new cards to the repeating Gift/Daily tables was rejected:
   it would change those owner tables permanently and add 500 SB fallbacks every cycle once
   the collection is complete. The sprint ends for good at Set 1 9/9. Cards owned at L40 and
   the full-collection pace barely move.
5. **Robot pacing.** Bot Part sources are untouched. The only knock-on effect is that the
   existing Set 1 completion reward (350 SB + 5 Bot Parts) now arrives around L38 instead of
   around L93, which R07-006 asks for.

Players who lose often (30%) get fewer Gift packs and finish Set 1 around L57, still about 100
levels earlier than without the sprint. Faster pack sources would mean changing the owner reward
tables, which is out of scope here.
