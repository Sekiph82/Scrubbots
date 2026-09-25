# SB-M42 HOME OWNER REVISION V03 — Claude implementation log

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit; owner visual acceptance NOT claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-OWNER-REVISION_V03.md`
Criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-OWNER-REVISION_V03.md`
Owner decision: `coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`

## Commits

| Role | SHA |
|---|---|
| Baseline (synced `origin/main`) | `6807521` |
| Implementation + tests + harness (final implementation SHA) | `d5f11e1` |
| Evidence + this log | follow-up commit |

## Changed files

- `scripts/ui/home/home_screen.gd` — all V03 layout/modal revisions (below).
- `scripts/ui/home/home_presentation_map.gd` — modes `STATIC` / `OWNER_RETIRED` / `OWNER_DISABLED`, `INACTIVE_MODES`, per-row `reason`.
- `scripts/app/main.gd` — Settings open/close drives `HomeScreen.set_modal_active("settings", open)`.
- `scripts/ui/ui_text.gd` — `HOME_RATIO` ("%s/%s").
- `tests/m42_home_v03.gd` (new, 14 cases), `tests/m42_home.gd`, `tests/m42_home_composition.gd` (updated to V03 truth),
  `tests/tools/home_snapshot.gd` (zero synthetic insets = phone without insets; `modals` captures).
- Evidence: `coordination/sessions/M42-C001/runtime_evidence/home_v03/`.

Untouched: root `TASKS.md`, owner decision files, ChatGPT prompt/criteria/audit files,
`assets/ui/HOME_ASSET_MANIFEST.json` (approval history + sha pins intact), manifest validator, all PNGs.

## Implementation summary

- **A Profile/HUD:** `ProfileCard` width = 50% of viewport width (clamped 460..620; 540 at 1080 vs ~622 in V02), height kept.
  Portrait 182x182 (V02 118 wide) drawn after (in front of) `ProfileAvatarFrame`, rising 86 px above the frame
  and above the card top; no ancestor clips it. `MenuButton` removed; bottom-nav SETTINGS is the only entry.
  Bot Parts caption = live `N/250` only (gold bar when a robot is unlockable, no extra copy). Level stays its own badge.
- **B Gift Meter:** caption = live `N/1,000` only, drawn over the 52 px meter; emblem HOME-051 + crate HOME-054 kept;
  GiftMeterService untouched (test asserts canonical next milestone still 250 after 61 SB).
- **C City:** approved HOME-001..004 re-composed with uniform scaling (no stretch): mid city (HOME-003) base behind the
  platform, extending well left/right of the portal; far city (HOME-002) rising behind/above the crown; street
  (HOME-004) scaled so its pavement runs from the dock top up past the SHOP|PLAY|CARDS row to the platform base.
  Dock flush to the bottom; its stylebox paints 600 px below (`expand_margin_bottom`) so bottom insets never show a
  world strip. **No city candidate was required** (none generated).
- **D Portal:** arch base at the platform middle (same plane); `AreaBanner` (live `AreaTitle`/`AreaNumber`, UiText
  defaults, Area 1 not stored as truth) is a slim teal plate set into the arch head, overlapping the lower crown edge.
- **E One platform:** HOME-011 node removed (`OWNER_RETIRED`); Scrubby's feet at HOME-010's top surface (0.40 of the texture height).
- **F Idle overlays:** `_process` idle loop, `ScrubbyBlink`/`ScrubbyBrushArm` and `set_idle_state` removed; HOME-031/032 `OWNER_DISABLED`.
- **G Cards:** left = WIN STREAK / GIFTS / COLLECTION, right = NO ADS / DAILY / TASKS; `ActionRow` = SHOP | PLAY | CARDS EXCHANGE
  (Shop still future-disabled, Cards Exchange still live popup).
- **H Play:** 470x150 (V02 700x196), font 76 (V02 104), subtitle 28 px; native white `PlayTriangle` (custom `_draw`, no
  texture); HOME-078 `OWNER_RETIRED`.
- **I Track:** panel ~136 px (V02 ~206); five gifts; values `1 / 5 / 10 / 25 / 100` only (no `+`, no SB icons, no WIN
  copy); current step gold, reached full, future dimmed; badge 96 px; HOME-087 `OWNER_RETIRED`.
- **J Nav:** five tabs, HOME selected, `RANKS` unchanged, only Settings entry.

## Presentation-mode counts

50 manifest ART entries accounted: **45 STATIC / 3 OWNER_RETIRED / 2 OWNER_DISABLED** (0 REUSE, 0 STATE).
Retired: HOME-011, HOME-078, HOME-087. Disabled: HOME-031, HOME-032. Inactive rows have no node, carry a reason,
and keep APPROVED + sha pins in the manifest (asserted by `m42_home_composition` inactive_rows_present_nothing).

## Modal-state architecture

`HomeScreen.set_modal_active(source, active)` + `is_modal_active()`; sources = any visible Home popup (Gifts, Daily,
Cards Exchange — driven internally by `open_popup` and each popup's `closed` signal) plus external sources (the app
root passes `"settings"` from `_on_nav_settings_changed`). While active, `LeftShortcutColumn`, `RightShortcutColumn`,
`ActionRow`, `WinStreakRewardTrack` and `BottomNav` are `visible = false` (not drawn; GUI never delivers pointer or
focus to invisible controls). Only one Home popup at a time (opening one hides the other); popups also have
`z_index = 2`. Back: `main.handle_back()` closes Settings first when open, otherwise the top Home popup; closing
restores exactly the previous visibility and geometry (tested).

## Vision / snapshot loop

Vision inspection performed on:
1. `iter1_home_1080x2160.png` — WHISPERING PARK plate hidden under the arch crown; portrait not popping; desktop
   work-area inset left a navy band under the dock (harness then pinned zero synthetic insets = phone without insets).
2. `iter2_home_1080x2160.png` — plate visible, city visible left/right; portrait pop-out still weak.
3. Final `home_1080x2160.png`, `home_1290x2796.png`, `home_1080x1920.png`, `home_1536x2048.png` — checked: buildings
   left/right/behind the crown, portal on the platform plane, one platform with Scrubby standing on it, no idle
   overlays, SHOP | PLAY | CARDS row, thin 1/5/10/25/100 track, dock flush at the bottom.
   Remaining honest observations: some sky remains above the city on the tallest phone (1290x2796); the mid-city layer's
   own painted sky shows between towers.
4. Modal evidence `modal_gift_bar_…`, `modal_daily_…`, `modal_cards_exchange_…`, `modal_settings_1080x2160.png` —
   inspected: shortcut cards, action row, reward track and nav are absent behind every modal (HUD/Gift Meter values,
   which are not actions, remain dimmed).

## Tests (headless, tree = `d5f11e1`)

| Suite | Result | SCRIPT ERROR | engine ERROR* |
|---|---|---|---|
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_home_composition.gd` | 9/9, 0 failures, exit 0 | 0 | 0 |
| `tests/m42_home_v03.gd` | 14/14, 0 failures, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` | 5322 checks, ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG fixtures = baseline) |

\* excluding exit-time "resources still in use"/RID-leak teardown notices (pre-existing harness noise).
`git diff --check`: clean. Tool-induced `project.godot` churn restored before commit (not committed).

V03 checklist → tests: 1–3 `profile_card`; 4–5 `no_top_settings`; 6–7 `compact_captions` (+ m42_home bot_parts/gift);
8–9 `city_background`; 10 `nav_flush` + `viewport_matrix`; 11–12 `one_platform`; 13 `idle_overlays_disabled`
(240 frames + 12 ticks); 14–15 `side_cards_and_row`; 16–18 `play_cta`; 19–23 `reward_track` + `play_cta` accounting;
24–26 `popup_modals`; 27–28 `settings_modal_and_back` (real `main.tscn` root); 29 `hidden_controls_no_input`
(real pushed clicks; sensitivity-checked on a live card first); 30 `viewport_matrix` (7 sizes × 2 inset sets).

## Approved blob integrity

Before/after comparison of the Git blob SHA of all **49** unique approved Home PNG paths (manifest) between baseline
`6807521` and the final tree: **0 mismatches**. No PNG under `assets/ui/final/` changed, moved or was overwritten; no
generated candidate added (the untracked files under `assets/ui/generated/` pre-date this pass and were not touched).

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME OWNER REVISION V03`
