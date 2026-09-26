# SB-M42 HOME POLISH V06 — Claude implementation log

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit; owner visual acceptance NOT claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V06.md`
Owner decision: `coordination/OWNER_M42_HOME_POLISH_V06.md`

## Commits

| Role | SHA |
|---|---|
| Baseline (synced `origin/main`) | `e094981` |
| Implementation + tests + harness (final implementation SHA) | `0f0614f` |
| Evidence + this log | follow-up commit |

## Changed files

- `data/config/economy_rewards_v1.json` — `hearts.regen_seconds` 1800 → **900** (only change).
- `scripts/economy/economy_config.gd` — fallback default 900; `scripts/economy/heart_service.gd` — doc comment only (logic
  unchanged: it already reads the interval from config).
- `docs/01_GAMEPLAY_SPEC.md`, `docs/02_TECH_ARCHITECTURE.md`, `docs/06_TEST_STRATEGY.md` — 30 min → 15 min (drift fix,
  citing the V06 owner decision). `coordination/OWNER_ECONOMY_REWARDS_V01.md` is an owner file and was not edited; V06
  records that it supersedes its §6 regen interval.
- `scripts/ui/home/home_screen.gd` — V06 Home changes (below).
- `tests/m42_home_v06.gd` (new, 13 cases); `tests/m39b_hearts_speed.gd`, `tests/m40_save_system.gd`, `tests/m42_home.gd`,
  `tests/m42_home_v04.gd`, `tests/m42_home_v05.gd` updated; `tests/tools/home_snapshot.gd` (Heart full / after-consume
  captures; restores the temp-app SB spent by the refill so all shots show the same balance).

Untouched: HOME-120 + manifest + world catalog, Gift Meter, Win Streak, Play, BottomNav, profile, icon sizes, modal
logic, TASKS.md, owner and ChatGPT files.

## Geometry (1080x2160)

- **World transform**: unchanged (pure V05 function); `m42_home_v06` world_locked asserts all 14 V05 matrix rows.
- **Hero scale**: `SCRUBBY_SCALE` **1.24** x V04 fit (k = 0.410407). Visible rect x 308.1..771.9, y 759.0..1303.6;
  centre X 540, soles Y 1297. Clears the baked sign (bottom 745) and all four helper-bot rects; no reduction needed.
- **HeroFocusShade**: `TextureRect` with a native `GradientTexture2D` (FILL_RADIAL, 256², 9 stops, navy
  (0.012, 0.024, 0.070), alpha `0.20·(0.5+0.5·cos πt)` → peak **0.20**, monotonic to 0 — no hard edge). Canonical rect
  (252, 760, 576, 640) → screen (252, 760, 576x640); first child of `Layer_characters` (above `WorldBackground`, behind
  `Art_scrubby`); top 760 is below the sign; x 252..828 does not reach any helper bot (x ≤ 248 / ≥ 902); mouse ignored.
- **Panels**: normal body alpha **0.51** (hover 0.61, pressed 0.67, disabled 0.51), 3 px outline, 8 px glow — unchanged
  size 210x156; TASKS/DAILY icon sizes asserted unchanged.
- **Currency pills**: 282 x **68** (V05 262 x 88 measured / 84 min). Icon footprint 64 x pop 1.71875 = **110 px drawn**
  (unchanged), overhanging the pill. Value font 40.
- **Plus**: `PlusGlyph` custom draw (soft circular cyan glow discs, navy outline, bold white plus) **52x52** at (992, 50)
  / (992, 164), inside the pill (pill ends at 1058), vertically centred; transparent `Button` hit target **88x88** at
  (974, 32) / (974, 146), centred on the glyph; StyleBoxEmpty in all states; emits intents only.
- **Hearts**: `HeartsCount` label (48 px white, navy outline 14) centred on the heart icon; pill value = regen clock only.

## Heart regen / timer evidence

Config before/after: `hearts.regen_seconds` **1800 → 900**; max 5, plus-one 500 SB, refill 400/missing unchanged.
`m39b_hearts_speed` (PASS): full = 5 with `seconds_to_next()` 0; consume → 4 and 900; +899 s → still 4 (1 s left);
+1 s → 5; three missing regenerate every 900 s (mid-interval 450); 2700 s offline → all 3 back; clock rollback accrues
nothing and forward time regenerates normally; purchase/refill prices and atomic no-charge refusals unchanged.
`m40_save_system` relaunch test: 1800 s later → exactly 2 regens.
`m42_home_v06` hearts_display_and_timer (injected wall clock, real AppState): full shows "5" on the icon + static
"15:00" (still 15:00 after 600 s); consume → "4" + "15:00"; +1 s "14:59"; +899 s "00:01"; +900 s "5" + "15:00"; two
consumed → "3" + "15:00"; +900 s "4" + "15:00" (next interval); +300 s "10:00" = `HeartService.seconds_to_next()`.
Home owns no timer state (1 Hz `_tick` refresh only; no `_process`).

## Lower stack (1080x2160)

| Element | V05 top Y | V06 top Y | Δ |
|---|---|---|---|
| PlayButton | 1515 | 1559 | +44 |
| WinStreakRewardTrack | 1686 | 1730 | +44 |
| BottomNav | 1822 | 1866 | +44 |
| AdBannerSlot | 2016 (144 px) | 2060 (**100 px**) | +44 |

Reservation `round(width·100/1080)` clamped **72..112**, `SIZE_SHRINK_END`, empty AdMount, collapse seam kept.
Gift Meter rects (chassis 98,270 884x88; emblem/crate 132 px; bar 172,287 736x54) and the reward rail rects (relative to
the track: rail 72.4,38 985.6x82; badge 22,12 112; gift1 140,0 181x82; track 120 tall) asserted equal to V05.

## Visual evidence (vision inspected)

`coordination/sessions/M42-C001/runtime_evidence/home_v06/`: `home_1080x2160.png`, `home_1290x2796.png`,
`home_1080x1920.png`, `home_1536x2048.png`, `hearts_full_1080x2160.png`, `hearts_after_consume_1080x2160.png`,
`modal_daily_1080x2160.png`, `modal_settings_1080x2160.png`, `home_adslot_collapsed_1080x2160.png`,
`compare_v05_vs_v06_1080x2160.png`, `iter1_home_1080x2160.png`.
Checked: world placement identical to V05; Scrubby visibly larger on the same spot, no new bright halo (the shade is a
subtle darkening of the portal glow directly behind him); panels a touch more solid; thinner SB/Heart pills with the
glow '+' inside; white count on the heart; pill reads 15:00 (full) / 15:00 right after a consume; ad band visibly
shorter and PLAY/track/nav lower; Gift Meter and rail unchanged.
Iteration fixes: balance text crowding the in-pill '+' (pill 262→282, glyph inset 14); square/blocky glow (switched to
concentric discs); pills floored at 80 px by the icon footprint (footprint 64 with pop so the drawn icon stays 110 px).
Note: one intermediate snapshot run returned blank/duplicate frames (window rendering glitch while other work ran);
it was discarded and the evidence re-rendered cleanly.

## Tests (headless, tree = `0f0614f`)

| Suite | Result | SCRIPT ERROR | engine ERROR* |
|---|---|---|---|
| `tests/m39b_hearts_speed.gd` | PASS, exit 0 | 0 | 0 |
| `tests/m40_save_system.gd` (touched) | PASS, exit 0 | 0 | 0 |
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_home_composition.gd` | 9/9, exit 0 | 0 | 0 |
| `tests/m42_home_v04.gd` | 18/18, exit 0 | 0 | 0 |
| `tests/m42_home_v05.gd` | 13/13, exit 0 | 0 | 0 |
| `tests/m42_home_v06.gd` | 13/13, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` | 5322 checks, ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG fixtures = baseline) |

\* excluding exit-time teardown notices. `git diff --check` clean. Headless `project.godot` churn restored, not committed.

Earlier-suite updates (values superseded by V06 only): `m42_home` (Heart count on icon, timer "14:00" after 60 s at the
900 s interval); `m42_home_v05` (hero scale via `SCRUBBY_SCALE`, alpha 0.40..0.52, pill 67..70, glyph inside the pill,
ad = current reservation, touch test uses the component clamp); `m42_home_v04` (alpha ≤ 0.52, glyph present, ad
72..160). All V05 world/stack/Gift/rail/modal assertions unchanged.

## Asset integrity

All 457 PNG blobs under `assets/ui/final` identical to the baseline tree (0 mismatches); HOME-120 SHA-256
`8e04eda6…5e5b` re-verified; all 51 manifest APPROVED pins match; no raster asset added (shade and plus are native).

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V06`
