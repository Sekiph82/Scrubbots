# M43-C001R-C001 — CLAUDE LOG V01

Date: 2026-10-02
Prompt: `coordination/sessions/M43-C001R-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C001R-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Scope: SB-M43-R01-001..008
Status: **AWAITING_GPT_M43_C001R_C001_AUDIT**

## Sync / governance

- **Repository:** `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `df59ea2`, fast-forwarded from `351edd4`.
- **Implementation commit:** `06bac5f`.
- **Evidence/log commit:** the next commit, which adds this file. Its SHA is reported in the hand-off message.
- **Owner/local work preserved, not committed:**
  - the pre-existing local `project.godot` modification;
  - untracked media, `.import` and `.uid` caches;
  - `tests/_m55_diag_tmp.gd`.
- Root `TASKS.md` was read only and **not edited**.

**Read before implementing:**
- `CLAUDE.md` and `TASKS.md`;
- `AUDIT_POLICY.md`;
- the C001R prompt and criteria;
- the M43-C004 audit and final owner acceptance;
- the C001A/C001B Results code and tests;
- `main.gd`, `home_screen.gd` and the launch resolver;
- `LevelProgressionService`, `LevelCatalog` / `LevelCatalogEntry`;
- the production catalog JSON and the level metadata;
- `player_experience_plan_v1.json`.

**Not done (out of scope):**
- no M43-C005 ceremonies; SB-M43-013 stays open;
- no M43-C005R;
- no Level Select, no tappable node, no World Diorama;
- no generated art;
- no reward, Gift Meter, Heart, streak, booster, ad, cadence or difficulty change;
- Need a Hand is untouched.

## Implementation

| File | Change |
|---|---|
| `scripts/progression/results_momentum.gd` (new) | `ResultsMomentum`: the one read-only authority. `load_config` (fail-closed), `cycle_of`/`slot_of`, `journey(progression, "home"/"results", anchor, cfg)`, `home_journey`, `next_cleanup(launch, cfg)`, `crop_rect(img, id, f)`, `results_model(...)`. It reads progression, the resolved catalog entry, that entry's LevelData palette and its own preview texture. It has no write path. |
| `data/config/results_momentum_v1.json` (new) | Schema `scrubbots.results_momentum.v1`: cycle 10, mini 5, boss 10 (must equal the owner lock); `cropped_detail`; fraction 0.20 inside min/max, which may only narrow 0.15..0.25; `reveal_delay_s` 0.2. |
| `scripts/ui/components/journey_strip.gd` (new) | One drawn Control showing 10 nodes: complete / current / next / future, a mini-boss diamond (orange rim) and a larger boss diamond (crimson rim). It has `MOUSE_FILTER_IGNORE`, `FOCUS_NONE` and no children, so nothing can be tapped. |
| `scripts/app/gameplay_launch_resolver.gd` | Also returns the entry's `preview_path`, so the teaser uses the exact resolution Continue uses. Additive only. |
| `scripts/app/main.gd` | Loads the momentum config once and shares it with Home. `_results_model` adds `momentum` for WON only, reusing the same `launch` it already resolved for Continue, so there is no extra catalog load. |
| `scripts/ui/results_screen.gd` | WON momentum section after the reward rows: journey caption + strip, then the Next Cleanup card. The teaser image is an `AtlasTexture` crop region with nearest filtering; with no image it shows a neutral "?". The primary reads `CLEAN NEXT` and is the same `continue_requested` intent. Also adds `set_ceremony_barrier(id, active)` and `has_ceremony_barrier()`, a momentum fade after the rows, and barriers clear when Results hides. |
| `scripts/ui/home/home_screen.gd` | `HomeJourneyStrip` (560×58, translucent plate) is a child of `PlayButton`, anchored above it like the existing status pill, so it takes no layout slot. The status pill shifts above it. Adds `set_momentum_config`. |
| `scripts/ui/ui_text.gd` | `RESULTS_CLEAN_NEXT`, `JOURNEY_CAPTION`, `NEXT_CLEANUP_*` and `DIFFICULTY_*`. |
| `tests/m42_navigation.gd`, `tests/m43_c001b_won_results_visual.gd` | **Deliberate migration:** the WON primary label is now `CLEAN NEXT` (`RESULTS_CLEAN_NEXT`) instead of `CONTINUE`. No other assertion changed. |

### Teaser crop

- **Size:** a `w × h` window with `w = W·√0.20` and `h = H·√0.20`.
- **Detail:** pixels that differ from the dominant colour, scored with a summed-area table.
- **Eligible:** windows with at least half of the best window's detail.
- **Pick:** FNV-1a of the stable entry id chooses among them.

On the 10 catalog previews the result is 9×9 to 17×17, at 19.1–20.7% of the full image (table in `MOMENTUM_MATRIX_V01.md` §4). If a crop would fall outside the configured envelope, no image is shown at all.

### Design note

The teaser's difficulty token is the catalog entry's LevelData `difficulty`, and the test asserts it equals `progression.class_for(level)`. The colour count is the LevelData local palette size, and the test asserts it equals the metadata `usedColorCount`. No display name is shown, because no canonical display-name authority exists: `display_name` is empty in every level file.

## Tests

### Focused suite

`godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd` → **PASS, 34/34 cases, 0 fail.**

| # | Expected | Result |
|---|---|---|
| 1 | WON L2 → teaser entry == resolver entry == catalog order 3 | PASS |
| 2 | Atlas texture `.atlas.resource_path` == the entry's exact `preview_path` | PASS |
| 3 | Same id + image → same crop, for all 10 levels and the read model | PASS |
| 4 | Every crop lies inside its texture | PASS |
| 5 | Config fraction is 0.20 within 0.15..0.25; every real crop is 15–25% | PASS |
| 6 | Over every frame of the normal reveal (120 frames) and of Reduced Effects, no TextureRect draws a full preview or a region > 25%. Sensitivity: a planted full preview and a 30×30 region are both flagged. | PASS |
| 7 | Shown difficulty == catalog token == `class_for(3)` (MEDIUM) | PASS |
| 8 | Colour count 6 == LevelData palette == metadata `usedColorCount` | PASS |
| 9 | L10 → L11 `CONTENT_MISSING`: "Coming soon", `?`, no texture | PASS |
| 10 | An empty or unknown preview gives no image; the UI shows no other level's art; each level binds only its own preview | PASS |
| 11 | Production L10: CLEAN NEXT disabled, `continue_from_results` → `no_next_content`; Home enabled | PASS |
| 12–14 | 10 nodes (model + drawn); slot 5 mini-boss; slot 10 boss; node classes == cadence | PASS |
| 15 | Strip: ignores the mouse, no focus, 0 children, no BaseButton; real clicks on all 10 nodes change neither navigation nor progression | PASS |
| 16 / 17 | Home frontier 1: slot 1 current, 0 complete. Frontier 6: 1–5 complete, 6 current | PASS |
| 18 / 19 | Results L9: 9/10, slot 10 next, teaser L10. Results L10: 10/10 | PASS |
| 20 | Home frontier 11: cycle 2, slot 1 current, levels 11–20; cycle math checked at 10 / 11 / 311 / 1000 | PASS |
| 21 | Injected test catalog stub with an L11 entry: Results 10/10 + L11 teaser available, then Home cycle 2 slot 1. The production resolver still has no L11 | PASS |
| 22 | Results and Home strips == `ResultsMomentum` models; same component script | PASS |
| 23 | A relaunched AppState from the saved progression gives an identical journey; the save JSON has no journey/momentum key | PASS |
| 24 | Receipt, economy snapshot and progression snapshot are identical after 3 re-shows, a barrier toggle and a Home refresh | PASS |
| 25 | Rows == `reward_lines(receipt)`; child order rows < momentum < primary | PASS |
| 26 / 27 | `continue_requested` → `continue_from_results`; 5 rapid taps → exactly one launch (L4) | PASS |
| 28 | Stale attempt → `stale_results` | PASS |
| 29 | 0 Hearts: CLEAN NEXT opens Life; no transition | PASS |
| 30 / 31 | Barrier: teaser hidden, CLEAN NEXT disabled, tap does nothing, journey and Home remain. Release: same crop region, CLEAN NEXT live, economy unchanged. Multiple barriers hold until all are released | PASS |
| 32 | Reduced Effects: momentum alpha 1 immediately, no reveal, identical journey/teaser truth | PASS |
| 33 | 5 viewports: Results (L4 + L10) panel, robot and CTAs in the viewport; strip and teaser inside the panel; no clipped momentum label; CTAs ≥ 88 px. Home strip inside the safe area, intersecting none of Play, track, nav, Gift Meter, ad slot, HUD or the 4 shortcuts | PASS |
| 34 | 20 hide / show / barrier / refresh cycles: nodes 414 → 414; timers and connections stable | PASS |
| 35 | Fraction 0.5 / 0.10, widened envelope, cycle 9, boss 7, mode full, NaN and a missing file all fail closed. With a bad config: no Home strip and PLAY works; no Results momentum, and CLEAN NEXT still launches L5 | PASS |
| copy | Momentum copy contains none of: almost / lucky / jackpot / hurry / free / reward / guarantee / last chance | PASS |

### Full regression

Godot 4.7.2 headless, 12-way parallel, 127 top-level `tests/*.gd`. **125 exited with rc=0.**

- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- **M35:** catalog, V02 — PASS.
- **M36:** V1, V02 — PASS.
- **M37:** progression, V02, V03 — PASS.
- **M40:** save, V02, V03, V04 — PASS.
- **M42:**
  - home, navigation, opening, assets — PASS;
  - composition 9/9, V04 18/18, V05 13/13, V06 13/13, V07 safe area 9/9;
  - Scrubby scale 7/7, animation 18/18.
- **M43:**
  - C001A 11/11, C001B 11/11;
  - C001R 34/34;
  - C002 23/23, C003 34/34, C004 40/40.
- **M55:** long session, core chaos, economy release, Heart 900, timed-2x — PASS.

**Non-zero exits, attributed:**
- `m21_v08_corridor_validation`: FAIL C/043 "above -> far-right top" and C/047 "corner route uses BOTH left and top exterior sides".
- `m21_v09_direct_evidence_reconciliation`: FAIL B "route crosses a distinct adjacent vertical-side NON-corner ring cell".

These are the same historical pre-Railroad-V1 corridor assertions recorded in the M43-C003 and C004 logs. This cycle changes no routing, targeting or dispatch file.

**Other checks:**
- `SCRIPT ERROR` appears only in the m20 lifecycle smoke logs (baseline assertion names).
- `git diff --check` is clean.

## Evidence

`evidence/` holds 21 PNGs rendered by `tests/tools/results_momentum_snapshot.gd` (a rendering driver; real app; real WON committed in the host). The tool rejects a shot whose Results panel or robot, or whose Home strip, leaves the viewport. None was rejected.

They cover:
- Results L2, L4 (→ L5 mini-boss), L9 (→ L10 boss), and L10 (10/10 + L11 coming soon, also at 1080×1920);
- Results L4 at 1080×1920, 1170, 1290 and tablet;
- Reduced Effects;
- the barrier held and released;
- Home frontiers 1, 6, 10 and 11, with frontier 6 at all sizes and in Reduced Effects.

`MOMENTUM_MATRIX_V01.md` holds the ownership, config, cycle, crop and corridor map. `OWNER_VISUAL_REVIEW_V01.md` holds the six owner questions.

## Deviations / owner decisions

1. The WON primary label changed from `CONTINUE` to `CLEAN NEXT`. Two tests were migrated for this.
2. On Level 10, both the card ("Coming soon") and the existing C001A/B note ("Level 11 is coming soon.") show. I kept both because the C001A/B tests require the note.
3. The Home strip is placed above PLAY as a non-layout overlay, chosen as the least disruptive placement.
4. The teaser crop amount and composition, the node treatment and the Results density are owner visual decisions (see the review pack).

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd
```

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

```bash
godot --path . -s res://tests/tools/results_momentum_snapshot.gd -- coordination/sessions/M43-C001R-C001/evidence
```

`AWAITING_GPT_M43_C001R_C001_AUDIT`
