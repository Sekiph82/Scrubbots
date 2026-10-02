# M43-C005-C001 — CLAUDE LOG V01 (Ceremony visual-master gate)

Date: 2026-10-02
Prompt: `coordination/sessions/M43-C005-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C005-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Primary row: SB-M43-076 (preparation for SB-M43-063..075, 077 and the SB-M43-013 handoff)
Status: **AWAITING_GPT_M43_C005_C001_VISUAL_AUDIT**

## Sync / governance

- **Repository:** `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `2bc93ad`, fast-forwarded from `d054a63`.
- **Commit:** a single cycle commit, which includes this log. Its SHA is reported in the hand-off message.
- **Owner/local work preserved, not committed:** the pre-existing `project.godot` modification and untracked caches/media.
- Root `TASKS.md` was read only and **not edited**.

**Read before implementing:**
- `CLAUDE.md`, `TASKS.md` and `AUDIT_POLICY.md`;
- the C005 prompt and criteria;
- `OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md` and `OWNER_ROBOT_ROSTER_V01.md`;
- `data/config/economy_rewards_v1.json` (collection, set rewards, master, Gift milestones, pack draws);
- `PLAYER_EXPERIENCE_ASSET_MANIFEST.json` and `assets/ui/VISUAL_ASSET_INDEX.md`;
- `CollectionInventory`, `CardPackService` and `RobotUnlockService`, read to understand truthful fields only;
- the accepted M43-C001B / C002 / C001R families.

**Not done (scope locks):**
- no production ceremony, queue or route;
- no grant, open, unlock, claim, equip, Daily or RewardGrantService call;
- no economy, roster, pack or Gift values changed;
- no feature unlock levels, world ranges or World 02 invented;
- no art generated or overwritten;
- the manifest is unchanged;
- SB-M43-063..075, 077 and 013 remain open;
- no C005R.

## Implementation (isolated preview harness, no shipping files changed)

| File | Purpose |
|---|---|
| `tests/tools/ceremony_preview/ceremony_candidates.gd` | Nine candidate builders using the accepted `BasePopup` family (promoted frames, royal pill, live labels, green / cream CTAs) plus read-only fixtures. See below. |
| `tests/tools/ceremony_preview/ceremony_snapshot.gd` | Evidence renderer: real `ModalStack`, BG01 backdrop, safe insets 96 / 64, rejects shots that fail `text_fits` or the safe area. No AppState or save. |
| `tests/m43_c005_c001_ceremony_visual_masters.gd` | 17 focused checks |

The fixtures in `ceremony_candidates.gd` read:
- `EconomyConfig` (draws, set rewards, master, Gift);
- `CollectionInventory`, constructed with **no reward service**, used only for card rarity;
- `OWNER_ROBOT_ROSTER_V01.md`, for name, role and perk.

Candidate actions only close their own popup. Motion (glow spin, card flip) is decorative, and Reduced Effects is static with identical information.

Card art mapping: canonical id `s<set>_c<k>` → `collection/cards/set_NN/card_(k+1).png`, in rarity-profile order. Spot checks match the rarity banners baked into the art; see the inventory.

Layout fixes made during evidence review:
- The NEW / DUPLICATE badge moved onto the card top, because it widened the tiles.
- The robot perk column got a 420 px wrap width, and "Bot Parts left" got a single-line label (autowrap inside an HBox had stacked the letters vertically).
- The markdown `**` was stripped from the parsed perk text.
- A 14 px gap was added above the card grid.

## Tests

### Focused suite

`godot --headless --path . -s res://tests/m43_c005_c001_ceremony_visual_masters.gd` → **PASS, 17/17 cases, 0 fail.**

| Required | Result |
|---|---|
| 1 Standard: exactly 3 slots | PASS (= config `standard_pack_draws` 3, real Standard Pack art) |
| 2 Premium: exactly 5 slots | PASS (= config 5; 3 Rare-or-better in the fixture; real Premium art) |
| 3 Rarity + NEW/DUPLICATE on every card | PASS: chip == `card_rarity`, matching frame, own art, NEW / DUPLICATE (+ "You now have N") |
| 4 No reroll CTA | PASS: only CONTINUE; no reroll / again / "guaranteed" copy in Premium |
| 5 Exact set reward | PASS for **all 15 sets** (SB + Bot Parts + name + 9/9 + 9 thumbs); "already added" wording |
| 6 Master exactly +2,500 SB +20 Bot Parts | PASS (row texts and config) |
| 7 Robot canonical text / perk, EQUIP + KEEP CURRENT | PASS (verbatim roster row #2; perk "Clean Bonus: +20% first-clear Scrub Bucks.") |
| 8 Gift rows exact | PASS for 10 / 50 / 250 / 500 / 1000; the 1000 fallback 500 SB is a note, not a row; 1000 hero > 250 hero |
| 9 Feature: no level | PASS |
| 10 World: no range / World 02 | PASS (test-only tag visible) |
| 11 Generic reward: 1–4 rows | PASS (0 and 5 refused) |
| 12 No mutation | PASS: with a fixed-clock AppState, opening all candidates and pressing every action leaves the economy and progression snapshots and the save bytes identical. The static source scan finds no grant / open / unlock / claim / wallet / save calls, and no `scripts/` file references the harness. |
| 13 Viewport fit | PASS: 10 candidates × 1080×1920, 1080×2160, 1170×2532, 1290×2796 and 1536×2048 — frame in the safe area, no clipped text, CTAs ≥ 88 px, cards inside the frame |
| 14 Reduced Effects parity | PASS: identical labels and actions; no motion; cards face-up |
| 15 Copy guard | PASS |
| 16 Asset paths | PASS: 38 bound textures + 135 card arts exist under `assets/ui/final`; the only recorded missing art is the "booster of your choice" icon |
| 17 Lifecycle | PASS: 20 × 10 open / close, no node, tween or connection growth |

**Failure found and fixed during authoring:** the first no-mutation run differed only in `hearts.anchor` and `speed.clock_high_water`. These are wall-clock fields that drift with the real clock on every read, not a preview mutation. The check now uses a fixed injected clock and passes.

### Regression

Godot 4.7.2 headless, 12-way parallel, 128 top-level `tests/*.gd`. **125 exited with rc=0.**

- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- **M39:** A–E, V02 atomicity / capacity / integration, V03, V04, tornado — PASS (economy, collection and robot truth baseline).
- **M43:** C001A 11/11, C001B 11/11, C001R 40/40, C002 23/23, C003 34/34, C004 40/40, C005 17/17 — PASS.

**Non-zero exits, attributed:**
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B): the unchanged historical routing baseline.
- `m29_c002_tempo_retune`: one CPU-timing bound failed under 12-way load ("per-route-probe cost new 0.917 ms vs historical 0.316 ms").
  - **Re-run alone: PASS.** It also passed in the two previous full runs.
  - This cycle changes no shipping code at all, so it is load noise.

**Other checks:**
- `SCRIPT ERROR` appears only in the m20 lifecycle smoke logs (baseline).
- `git diff --check` is clean.

## Deliverables

- `CEREMONY_ASSET_INVENTORY_V01.md`: per-candidate exact paths and presence; final art reuse; missing art; card-art observations.
- `CEREMONY_VISUAL_MATRIX_V01.md`: harness isolation, candidate → truth, motion, the checks, the evidence list, and the manifest decision.
- `OWNER_VISUAL_REVIEW_V01.md`: 7 grouped owner decisions, asset items, and proposed manifest transitions (not applied).
- `evidence/`: 29 PNGs (all six required reference shots, both Reduced Effects shots, feature / world / generic, and the 5-viewport matrix).

## Missing art (blockers only if wanted)

1. A "Booster of your choice" icon (Gift 500 / 1000). A native "?" chip is used for now.
2. Future world art and names: intentionally absent until an owner world registry exists.
3. Optional: a uniform card-art re-export, because the current crops are uneven 266–297 × 306–323 px sheet cuts.

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c005_c001_ceremony_visual_masters.gd
```

```bash
godot --path . -s res://tests/tools/ceremony_preview/ceremony_snapshot.gd -- coordination/sessions/M43-C005-C001/evidence
```

`AWAITING_GPT_M43_C005_C001_VISUAL_AUDIT`
