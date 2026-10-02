# M43-C005-C001 — Ceremony Visual Matrix V01

Date: 2026-10-02
Scope: SB-M43-076 (visual-master candidates only; SB-M43-063..075, 077 and 013 stay open)

## 1. Harness (isolated, non-shipping)

| Piece | Path | Role |
|---|---|---|
| Candidate builders + fixtures | `tests/tools/ceremony_preview/ceremony_candidates.gd` | Nine candidates as configured `BasePopup`s (the accepted M43-C002 family) over read-only fixtures |
| Evidence renderer | `tests/tools/ceremony_preview/ceremony_snapshot.gd` | Renders PNGs on a BG01 backdrop through the real `ModalStack` (rendering driver; no AppState / save) |
| Focused checks | `tests/m43_c005_c001_ceremony_visual_masters.gd` | 17 checks (§4) |

Isolation:

- Nothing under `scripts/` references the harness (checked by c12).
- There is no navigation route and no production action. Every candidate action only closes its own popup.
- The fixtures read config, roster and catalog only:
  - `EconomyConfig` (packs, set / master rewards, Gift milestones);
  - `CollectionInventory`, built **without** a reward service, for card rarity;
  - `OWNER_ROBOT_ROSTER_V01.md`, for robot text.
- The harness source contains no `open_standard` / `open_premium` / `add_card` / `unlock` / `claim` / `grant` / wallet / save calls (static scan in c12).

## 2. Candidate → truth

| Candidate | Frame | Fixture truth | Actions |
|---|---|---|---|
| Standard Pack | large | 3 draws (= config); s3_c1 COMMON NEW, s3_c4 RARE DUPLICATE (you now have 2), s7_c2 COMMON NEW | CONTINUE |
| Premium Pack | large | 5 draws (= config); s2_c0 COMMON NEW, s4_c6 EPIC NEW, s9_c3 COMMON DUPLICATE (3), s11_c4 RARE NEW, s14_c8 LEGENDARY NEW (3 Rare-or-better). No "guaranteed" claim. | CONTINUE |
| Set Complete | reward | Set 6 "Bathroom Mayhem", 9/9 with the 9 real card thumbs, **+600 SB +8 Bot Parts** (config set 6). All 15 sets are verified in c05. | CONTINUE |
| Master Collection | reward | 15/15 sets; **+2,500 SB +20 Bot Parts** (config `all_sets_complete`); "One-time master reward" | CONTINUE |
| Robot Unlock | reward | Moppy (#2): role and "Clean Bonus: +20% first-clear Scrub Bucks." verbatim from the roster; `moppy_master.png`; Bot Parts left 37 (fixture) | **EQUIP MOPPY** (primary) / KEEP CURRENT (secondary) |
| Gift 250 | reward | +100 SB, +2 Bot Parts, +1 Standard Card Pack (config 250) | CONTINUE |
| Gift 1000 | reward | +500 SB, +4 Bot Parts, +1 Premium Card Pack, +2 Booster of your choice, +1 guaranteed NEW card (config 1000). The 500 SB fallback is shown as a **condition**, not an extra reward. | CONTINUE |
| Feature unlock | medium | Fixture label "CARDS EXCHANGE" with its real shortcut icon, a NEW badge and a one-line explanation; **no level number**; tagged "FIXTURE LABEL · real unlock policy unchanged" | GOT IT |
| World shell | large | Title slot "WORLD NAME", subtitle slot "Area subtitle"; World 01 art in the art slot tagged **PREVIEW HARNESS · SHELL TEST ONLY**; no id, range or World 02 | CONTINUE |
| Generic reward | small | Title plus 1–4 reward rows (0 or 5 refused); evidence shows 1 row ("DAILY REWARD") and 4 rows ("TASKS 3/3 COMPLETE") | CONTINUE |

Reward rows always appear in one fixed order: SB, Bot Parts, Standard pack, Premium pack, Random booster, Booster of your choice, guaranteed NEW card, Heart. Every row is a live label with a final icon.

Wording such as "Already added to your collection / account" states that a grant was committed before the ceremony; the ceremony never grants on tap.

## 3. Motion and Reduced Effects

| Motion (animated) | Reduced Effects |
|---|---|
| The hero glow rotates slowly (9 s loop) | Static glow |
| Cards flip in one after another (0.25 s + 0.18 s per card; back-ease 0.22 s) | All cards face-up immediately |
| All labels, values and actions are present from the first frame | Identical labels and actions (c14) |

## 4. Focused checks (`tests/m43_c005_c001_ceremony_visual_masters.gd`, 17/17 PASS)

| # | Check |
|---|---|
| c01 / c02 | Standard 3 / Premium 5 card slots (= config); real pack art; Premium has ≥ 1 Rare-or-better |
| c03 | Every card: rarity chip == `CollectionInventory.card_rarity`, matching rarity frame, its own card art, NEW / DUPLICATE (+ copies) |
| c04 | Packs have only CONTINUE: no reroll or open-again, and no "guaranteed" copy |
| c05 | All 15 Set Complete fixtures: exact config SB + Bot Parts, name, 9/9, 9 thumbs; reward stated as already added |
| c06 | Master: exactly +2,500 SB +20 Bot Parts (texts and config) |
| c07 | Robot: name, role and perk verbatim from the roster; canonical art; Bot Parts left; EQUIP + KEEP CURRENT |
| c08 | Gift 10/50/250/500/1000 rows == config bundles; the fallback appears as a note; the 1000 hero is larger than 250 |
| c09 | Feature: no `level N` text, no level key, fixture-tagged, no reward rows |
| c10 | World shell: no numeric range, no World 02, no id / range keys; test-only tag visible |
| c11 | Generic reward: 1–4 rows build; 0 and 5 refused |
| c12 | Opening every candidate and pressing every action leaves the AppState economy and progression snapshots and the save bytes unchanged; the source scan finds no forbidden calls; no shipping script references the harness |
| c13 | All 10 candidates × 5 viewports: frame inside the safe area (96 / 64 insets), `text_fits`, CTAs ≥ 88 px, cards inside the frame |
| c14 | Reduced Effects: identical labels and actions; no spin or flip metadata; cards at scale 1 |
| c15 | No jackpot, lucky, almost, so close, hurry, last chance, limited, odds, reroll or extra-reward copy |
| c16 | All 38 bound textures and 135 card arts exist under `assets/ui/final`; the only recorded missing art is the booster-of-choice icon |
| c17 | 20 × 10 open / close cycles: no node, tween or connection accumulation |

## 5. Evidence (`evidence/`, 29 PNGs)

- **Reference 1080×2160:**
  - `standard_pack`, `premium_pack`, `set_complete`, `master_complete`, `robot_unlock`;
  - `gift_250`, `gift_1000`;
  - `feature_unlock`, `world_shell`, `generic_1`, `generic_4`.
- **Reduced Effects:** `premium_pack_reduced_effects`, `robot_unlock_reduced_effects`.
- **Viewport matrix:** `premium_pack`, `robot_unlock`, `gift_1000` and `master_complete` at 1080×1920, 1170×2532, 1290×2796 and 1536×2048.

All shots use synthetic safe insets of 96 top and 64 bottom; none was rejected by the fit check.

## 6. Manifest

`assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json` is **unchanged**. Its status vocabulary has no "candidate" state, so marking these entries would conflate them with owner approval. Proposed transitions are listed in `OWNER_VISUAL_REVIEW_V01.md` §3.
