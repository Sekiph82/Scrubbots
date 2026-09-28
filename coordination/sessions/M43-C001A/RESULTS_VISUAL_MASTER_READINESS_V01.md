# M43-C001A — RESULTS VISUAL MASTER READINESS V01

Date: 2026-09-28
Actor: Claude (implementer). **This is a readiness spec, NOT an approval.**
Surface: `victory_results` in `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json` → status stays **`MASTER_REQUIRED`** (not edited).
No asset was generated, regenerated, moved or overwritten in this cycle.

## 1. Gate state

| Item | State |
|---|---|
| `victory_results` manifest status | `MASTER_REQUIRED` (unchanged; not promoted to `MASTER_OWNER_APPROVED`) |
| Canonical Victory/Results master image | **does not exist** |
| Owner style anchor for the popup family | `assets/art/references/_owner_inbox/Additionals/life screens.png`, `.../need a hand.png` (SB-M43-009: Results must be consistent with the Life/Help family) |
| Runtime Results | technical/wireframe-safe shell bound to the live receipt model (`scripts/ui/results_screen.gd`); no final art bound |

## 2. Existing reusable asset inventory

All paths exist on `main`; provenance per `assets/ui/VISUAL_ASSET_INDEX.md` (Codex visual production, commits `3012ebb` Phase 1 and `8f9a9ba` Phase 2, 2026-09-19). Each is RGBA with transparent background.

### 2.1 Victory family — `assets/ui/final/popups/victory/`

| Asset | Size | Content | Results use |
|---|---|---|---|
| `victory_emblem.png` | 1296×1213 | gold star in teal/gold medallion with rays | header/crest over the title |
| `reward_glow.png` | 1374×1145 | gold/cyan radial burst + sparkles | halo behind reward items / emblem |
| `continue_button_frame.png` | 1536×1024 | cyan pill, white right arrow, no text | Continue CTA (see decision D3) |
| `victory_scrubby_pose.png` | 1230×1278 | Scrubby cheering, arms up | celebrating robot (default robot) |
| `robots/atlas_victory_pose.png` | 1024×1536 | Robot victory pose | per-robot variant (D5) |
| `robots/bubbles_victory_pose.png` | 1145×1374 | 〃 | 〃 |
| `robots/clippy_victory_pose.png` | 1024×1536 | 〃 | 〃 |
| `robots/dusty_victory_pose.png` | 1024×1536 | 〃 | 〃 |
| `robots/moppy_victory_pose.png` | 1024×1536 | 〃 | 〃 |
| `robots/polly_victory_pose.png` | 1024×1536 | 〃 | 〃 |
| `robots/rinse_victory_pose.png` | 1024×1536 | 〃 | 〃 |
| `robots/spark_victory_pose.png` | 1147×1371 | 〃 | 〃 |
| `robots/squeegee_victory_pose.png` | 1024×1536 | 〃 | 〃 |

Note: pose canvases differ (1024×1536 portrait vs ~1:1). Composition must fit by aspect, not fixed size.

### 2.2 Reward items — `assets/ui/final/rewards/` and related

| Asset | Size | Reveal-queue entry it can illustrate |
|---|---|---|
| `rewards/scrub_bucks_bundle_small.png` / `_large.png` | 1448×1086 / 1536×1024 | `first_clear_sb`, `win_streak_sb` |
| `common/currencies/icon_currency_scrub_bucks.png` | 1374×1145 | inline SB icon next to live amount |
| `rewards/bot_parts_bundle_small.png` / `_large.png` | 1374×1145 / 1230×1278 | `bot_parts` |
| `robots/bot_parts_icon.png` | 1222×1287 | inline Bot Parts icon |
| `home/reward_track/win_streak_reward_badge.png` | 1245×1263 | `win_streak_sb` badge |
| `home/shortcuts/icon_shortcut_win_streak.png` | — | alternative streak icon |
| `home/gift_meter/gift_meter_emblem.png` | 1254×1254 | `gift_meter` progress |
| `home/gift_meter/gift_meter_reward_crate.png`, `rewards/gift_box.png` | 1254×1254 | `gift_milestone` follow-up |
| `common/frames/progress_bar_frame.png` + `progress_bar_fill.png` | — | Gift Meter bar (value stays live) |
| `rewards/card_pack_standard.png` / `card_pack_premium.png` | 1024×1536 | future `collection_cards` (not on today's terminal path) |
| `rewards/chest_small.png`, `reward_chest.png` | 1374×1145 | not required by current receipt |

### 2.3 Chrome / common

| Asset | Size | Note |
|---|---|---|
| `common/frames/popup_reward_frame.png` | 1199×1312 | cream panel, cyan/gold sci-fi frame, star crest |
| `common/frames/popup_large_frame.png`, `popup_medium_frame.png`, `popup_confirmation_frame.png`, `popup_small_frame.png` | — | same cyan/white sci-fi family |
| `common/frames/button_green_frame.png`, `button_blue_frame.png`, … | — | untexted pill buttons |
| `common/icons/icon_close.png` | — | close control |
| `popups/failure/*` (fail header, hearts, retry/refill frames) | — | LOST Results / Fail-Retry (separate surface, M43 fail rows) |

## 3. Composition mapping (proposal for the owner master, not approved)

Portrait, board dimmed behind (the current shell already dims):

```text
[ victory_emblem + reward_glow ]          crest over the frame top edge
[ header ribbon: "LEVEL COMPLETE" ]       live text
[ celebrating robot pose ]                default Scrubby
[ Level N ]                               live
[ reward rows in reveal_queue order ]     icon asset + live amount per row
   first-clear SB · Win Streak SB (streak n) · Bot Parts · Gift Meter bar (+ gift ready)
[ CONTINUE ]  [ HOME ]                    CTA frames + live labels
[ "Level N is coming soon." ]             live, only when next frontier has no content
```

Every label, amount, streak count, Gift progress and level number stays live Godot text (`UiText` keys `RESULTS_*`).

## 4. Genuinely missing components / composition decisions

| # | Gap | Why it matters |
|---|---|---|
| M1 | **No canonical Victory/Results master image** | SB-M43-009 requires one; manifest is `MASTER_REQUIRED`. |
| M2 | **No Life/Help-family popup chrome asset** | The owner Life/Help references use a warm cream panel, thick royal-blue bolted frame, blue header ribbon with leaf accents, a character peeking over the top, a red round close, and a beige footer plaque. The repo's `popup_*_frame.png` family is a different, cooler cyan/white sci-fi style. No header ribbon or footer plaque asset exists. This is also the SB-M43-028 popup chrome kit. |
| M3 | CTA style mismatch | `continue_button_frame.png` is a cyan arrow pill without text. The Life/Help family uses green/yellow text pills (`button_green_frame.png` exists). Which one is canonical is an owner choice. |
| M4 | Emblem vs character crest | Life/Help put the character above the frame. The Victory family has both an emblem and a robot pose, so the owner must choose one crest, or a stacked arrangement. |
| M5 | Per-robot pose selection | There are 10 poses, but no equipped/active-robot authority exists yet (robot selection is M44). Until then, Scrubby is the only safe default. |
| M6 | Reveal choreography | The timing, sequence, skip-on-tap behaviour, SFX/haptic cues and Reduced-Effects variant are undefined. The data order is fixed (matrix §4). The motion is not. |
| M7 | Already-cleared / no-content states | Copy and placement for the "Already cleared · no progression reward" note and the "Level N is coming soon." note. |
| M8 | LOST Results vs Fail/Retry popup | Should LOST reuse this surface or the separate Fail/Retry popup (failure assets exist)? This decides whether Results needs a LOST master at all. |

No new component art is proposed here. If M2 is answered "use Life/Help chrome", the chrome kit must be produced under SB-M43-028 with owner approval before promotion.

## 5. Replay — OWNER DECISION REQUIRED (SB-M43-006 / 011)

Existing semantics, inspected:
- `OWNER_ECONOMY_REWARDS_V01` §2/§3: a replay may exist for fun/QA/score. It grants **no** first-clear SB, Bot Parts, Gift Meter progress, Win Streak or first-clear Collection milestones.
- `OWNER_M37_LEVEL_SELECT_DECISION_V01`: no replay-by-select menu in the shipping flow unless the owner later changes this.
- Code is already replay-safe:
  - `LevelProgressionService.record_win` rejects non-frontier and replay levels;
  - `FirstClearRewardService` and `WinStreakService` take `is_replay`, and duplicates are no-ops by level transaction id;
  - `FirstClearTransaction` returns `not_frontier` with zero mutation;
  - the receipt reports `already_cleared: true` with zero reveals (tested through the real host).
- **Missing launch path:** `GameplayLaunchResolver` and `main.play_current_frontier()` only launch the current frontier. There is no production way to start a completed level.

Owner decisions needed before any Replay control ships:
1. **Allow Replay at all?** If yes, where: on WON Results only, or also elsewhere? Is it the level just won (now below the frontier)?
2. **Heart cost:** does a replay attempt cost a Heart on loss or on a post-action restart? `OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01` already says replay failures do not increment the assistance counter.
3. **Win Streak:** can a replay loss reset the active progression Win Streak, or must replay be fully streak-neutral?
4. **2x / boosters:** may a replay consume a current-level 2x entitlement or booster charges?
5. **Results on a replay WON:** confirm it shows "zero progression reward" (SB-M43-011) and that Continue returns to the frontier.
6. **Launch authority:** how is a replay launched without creating a Level Select (M37 lock)? For example, a single "replay the level just cleared" intent.

In this cycle no Replay button, replay launch path or replay economy rule was added.

## 6. Must be owner-approved before final Results visual implementation

1. Victory/Results master image (M1). After that, move `victory_results` → `MASTER_OWNER_APPROVED` (ChatGPT/owner action, not the implementer's).
2. Popup chrome family choice (M2), plus the chrome kit if the Life/Help style is chosen (SB-M43-028).
3. CTA style (M3) and crest arrangement (M4).
4. Robot pose rule (M5): Scrubby-only until M44, or bind to a future equipped-robot authority.
5. Reveal choreography and Reduced Effects variant (M6).
6. Note copy for the already-cleared and no-next-content states (M7), and LOST routing (M8).
7. Replay policy (§5).

After those approvals: bind the assets in `ResultsScreen` against the unchanged receipt/model contract. No change to the grant path is needed.
