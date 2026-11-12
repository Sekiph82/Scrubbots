# Accessibility (M50)

What the shipped UI does for players who read large text, use a screen reader, need non-colour
cues, avoid motion or are sensitive to flashing, and the evidence for each. Owner rules that
stay as they are: COLOR SYMBOLS is opt-in (Settings, default OFF; CLAUDE.md "Board
color-assist") and REDUCED EFFECTS stays the one Settings toggle (owner 2026-11-06).

Tests: `tests/m50_accessibility_audit.gd` (CI, 11 cases), `tests/m50_a11y_surfaces.gd` (local
walk of every M43/M44 surface), `tests/m50_contrast_surfaces.gd` (local, windowed),
`tools/flash_audit.py` + `tools/flash_capture.gd` (local flash measurement).

## Text size (SB-M50-007, SB-M50-012)

- Floor: no shipped English or Turkish text is below 18 design px (~6.9 dp); m50 audit a06,
  m50_contrast_surfaces c02.
- OS font scale: Godot 4.7.2 exposes no query for the Android font scale or iOS Dynamic Type
  (DisplayServer only has `screen_get_scale`, the display density), and its own text rendering
  ignores both. There is no in-game TEXT SIZE setting (none was requested; no new Settings row).
- Headroom: `m50_a11y_surfaces` x02 scales every text control on every surface by 1.15 and 1.3.
  Nothing is cut, ellipsized or loses lines at 1.15 or 1.3 (1.15 asserted). Text that grows past
  its 1.0 box is reported per scale in the suite log: 8 controls at 1.15 (two Home captions, the
  Home REWARDED ADS label, the Profile caption, the four HUD booster price tags, each 3-25 px
  taller or wider than its plate), 10 at 1.3 (plus two Achievements badge numbers). That is the
  layout work if a text-size setting is ever added.

## Screen readers, focus and back (SB-M50-012, SB-M50-016)

- Strategy: Godot 4.7 AccessKit. Every interactive button exposes a name: its own text when
  that is a word, otherwise `Control.accessibility_name` from `UiText` (EN + TR, `A11Y_*` keys
  plus existing titles). Glyph / icon-only buttons named: popup and Settings `X` (CLOSE),
  Settings `?` (HELP & TIPS), Home profile card (PROFILE), Gift Meter (GIFTS), the two `+`
  buttons ("Get more Scrub Bucks" / "Get more Hearts"), HUD Pause (`II`) and 2x, the four
  boosters, Collection `<` / `>`, Tornado / Selector colour chips ("Color C05": the canonical
  colour id that also picks the chip's symbol). Locked Home tabs and boosters carry their
  "Unlocks at level N" as `accessibility_description`.
- Focus: player buttons use `FOCUS_ACCESSIBILITY` (focusable only while a screen reader is
  active), so touch players never see a focus ring and screen-reader users can move through
  every button in tree order. Info-only nodes (journey strip, slot views) stay `FOCUS_NONE`.
  Keyboard / gamepad navigation without a screen reader is not supported (portrait touch game).
- Back: Android back and Esc close only the top popup (ModalStack, LIFO; m49_surface_stress v04).
- Gameplay board / supply taps have no screen-reader operation (out of scope; the board is
  pixel art with optional colour symbols).
- Device check pending: TalkBack / VoiceOver on a real phone (AccessKit platform support
  depends on the Godot export template).

## Non-colour state cues (SB-M50-012, SB-M50-015, SB-M50-017)

| State | Cue besides colour |
|---|---|
| Robot locked / active | "LOCKED" / "ACTIVE" text, padlock emblem (Robots) |
| Home tab locked (Robots 25, Events 30, Ranks 40) | "LV N" pill on the tab (new, `NavLock_*`) |
| Booster locked | padlock plate + "LV N" |
| Card rarity | rarity name chip (COMMON / RARE / EPIC / LEGENDARY), "Not found yet" |
| Rank tiers | "YOUR RANK" / "REACHED" labels, "N more levels to ..." |
| Reward tracks (Daily, Rewarded Ads, Tasks, Events) | CLAIM / CLAIMED / LOCKED button text, "x / y" progress |
| Event reset / run | "Ends in ...", "Starts in ...", "Run: x / y", "Missing a day never resets progress" |
| Catch-Up / Comeback | "Comeback bonus x/3", "Next new level win: ..." |
| Pity guarantee | "NEW CARD GUARANTEED NEXT PACK" |
| Supply batch | live robot count text; colour symbols when COLOR SYMBOLS is on |

Asserted on the live surfaces by `m50_a11y_surfaces` x03 and `m50_accessibility_audit` a04 / a09.

## Rewarded ads (SB-M50-014)

The REWARDED ADS screen starts no video on open; a video starts only from WATCH AD; every slot
shows reward, state and button as text; reward 1 is free without a video; CLOSE and back decline;
a cancelled or unanswered video grants nothing and says so. While a video is out, back waits for
the provider's answer, at most `UI_TIMEOUT_S` (30 s), then the popup is free again. The screen owns
no audio; a real provider (M57) must start muted or user-initiated. Non-video paths: Hearts and
booster charges are sold for Scrub Bucks. Evidence: m50 audit a10 (provider double).

## Reduced Effects: FULL vs REDUCED per effect (SB-M50-005, SB-M50-013, SB-M50-018)

Reduced Effects never hides reward or gameplay truth: every value, label and final state is the
same; only motion, particles, video and pulses are removed (reveal sequences land on the final
state at once). One-shot keys are consumed in either mode, so toggling or reopening never replays
a ceremony. Each row's REDUCED arm is tested by the suite in `REDUCED_LEDGER`
(m50 audit a07); this table is checked against that ledger (a11).

| Script | FULL | REDUCED |
|---|---|---|
| feedback_adapter.gd (GameFeelFlow / Spark gateway) | punch_scale on Node2D targets, Spark spark / pickup / confetti 0-24 particles, <= 1.3 s per intent; no flash / camera / shake / freeze reachable | nothing dispatched (all intents empty) |
| meta_reward_feel.gd | reward settle feel via the adapter | values update, no settle |
| home_micro_feel.gd | small sine scale bump on value change | values update, no bump |
| meta_feedback.gd | haptic ticks (when Haptics on) | no haptics |
| character_motion.gd | robot pose bounce / wave / slide tweens | static pose |
| cleaning_effects_controller.gd | clear sparkle, <= 24 live, 0.30 s | <= 8 live, 0.18 s single cue |
| gameplay_screen.gd | booster activation burst + BoosterVfx, batch-complete pop | burst fade only, no BoosterVfx / pops |
| booster_vfx.gd | tornado vortex 0.85 s, +1 slot glow 0.7 s, random dice flicker 0.6 s, selector reticle 0.8 s, batch pop 1.6 s | not played |
| five_slot_strip.gd, batch_slot_view.gd | WAITING slot pulse | static tile at full alpha |
| results_screen.gd (LOST / ERROR only) | lose robot video | still pose |
| win_overlay.gd | level-complete win video (or victory pose motion) + WIN confetti, then Home | keyed still for 1.0 s, then Home |
| home_reward_flight.gd | reward icons fly into the Home HUD, counters count up | final HUD values at once, no flight |
| reveal_sequencer.gd | stepped reveal | exact final state immediately |
| meta_ceremonies.gd, ceremony_presenter.gd | turning glow, hero motion, set / gift / region videos | static glow and art, same labels and values |
| standard_pack_ceremony.gd, premium_pack_ceremony.gd, pack_presenter.gd | opening video, drop / shake / rays / confetti (48 / 90) / card flip | short version: no drop, shake, particles, burst, flip or spin; same cards and taps |
| home_scrubby_hero.gd | Scrubby video loops on Home | still frame |
| home_screen.gd, gift_tick_overlay.gd | Gift Meter tick pulse | static ticks |
| coachmark_layer.gd | pointer motion | static pointer |
| level_intro_overlay.gd | intro video, then fade | keyed still for 0.8 s, then the same fade |
| acquisition_flow.gd | Need a Hand helper video / slide + wave | static helper |
| profile_screens.gd | Welcome Back video | still frame |
| daily_screens.gd | no motion | identical |

## Flashing (WCAG 2.3.1, SB-M50-018)

`tools/flash_audit.py` counts general flashes (opposing relative-luminance changes >= 0.10 with
the darker side < 0.80, over >= 25% of a 10-degree field, about 0.78 x 0.59 screen widths on a
phone) in any 1 s; the rule is <= 3, in FULL as well as REDUCED. Measured 2026-11-09:

| Source | Peak field share changing | Max flashes / 1 s |
|---|---|---|
| 16 shipped videos (opening, Home Scrubby x4, level intro, results win / lose, Need a Hand, Welcome Back, new region, gift small / big, set complete, standard / premium pack) | 4-44% | 0, except result_scrubby_win 2 |
| BoosterVfx tornado / +1 slot / random / selector, five simultaneous batch pops (rendered on L1, 1080x2400, 60 fps) | 0-10% | 0 |
| Feel plugins | flash categories unreachable (allow-list) | 0 |

Reproduce: `python tools/flash_audit.py --selftest $(git ls-files '*.ogv')`;
`godot --path . -s res://tools/flash_capture.gd -- --out <dir>` then
`python tools/flash_audit.py --fps 60 <dir>/*`. Re-run when a video or BoosterVfx changes.
