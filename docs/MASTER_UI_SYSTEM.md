# SCRUBBOTS Master UI System

Status: OWNER-APPROVED architecture baseline
Engine: Godot 4.7.2
Primary orientation: portrait
Visual generation provider: ChatGPT image generation primary; Magnific MCP fallback

## 1. Purpose

SCRUBBOTS UI is not shipped as flattened AI-generated screenshots. Full-screen AI images are art-direction references only. Production UI is assembled from reusable Godot Control components plus a small set of owner-approved/generated decorative assets.

Core rule:

```text
AI-generated concept or component art     = visual source/reference
Godot Control scene                  = production UI
Gameplay/BoardState                  = gameplay truth
```

No UI scene may own or duplicate gameplay truth.

## 2. Locked production principles

1. Mobile-first, portrait-first.
2. Reference design viewport: 1080×2160 (1:2).
3. Stretch mode: `canvas_items`; stretch aspect: `expand`.
4. Every production screen must respect device safe areas.
5. Pixel board receives the largest practical share of gameplay-screen space.
6. Board aspect ratio is never distorted. Rectangular boards remain rectangular.
7. The color-selection panel must preserve its usable width; it is not sacrificed to make decorative art fit.
8. Production gameplay shows five visible active slots.
9. Minimum interactive touch target: 88 reference pixels unless a platform-specific accessibility pass chooses larger.
10. Text remains live Godot text. Do not bake normal UI labels/numbers into generated images.
11. Plain scalable panels/buttons/progress bars are Godot-native styles or 9-slice assets, not full-screen bitmaps.
12. Owner-approved source images are immutable originals. Derived assets go to separate paths.
13. ChatGPT image generation is the primary AI image-generation workflow; Magnific MCP remains an approved fallback/alternate.
14. Higgsfield is not a project dependency.
15. Never silently regenerate or overwrite an approved visual asset.

## 3. Responsive targets

Required visual/layout test viewports:

```text
1080×2160   baseline 1:2
1170×2532   tall iPhone-class portrait
1290×2796   large/tall iPhone-class portrait
1080×2400   common Android 20:9
1440×3200   high-resolution Android 20:9
```

Also retain coverage for shorter 16:9 portrait and tablet portrait before release.

Layout modes:

```text
COMPACT  ratio < 1.85
NORMAL   ratio >= 1.85 and < 2.15
TALL     ratio >= 2.15
```

Breakpoints affect spacing, character decoration and HUD density. They must not change gameplay rules, slot count, logical board dimensions or board content.

## 4. Safe-area contract

Every production screen root uses a safe-area wrapper. No essential control may be hidden by a notch, Dynamic Island, rounded-corner cutout, Android status/navigation region or gesture area.

Recommended tree:

```text
ScreenRoot (Control)
└── SafeAreaRoot (Control)
    └── MarginContainer
        └── ScreenContent
```

Safe-area code belongs to presentation only.

## 5. Gameplay screen final composition contract

Owner-approved layout direction:

```text
TOP
  compact player/profile area where required
  NO Goal/Moves panel in the approved gameplay composition

CENTER / PRIMARY
  board area, largest visual element on screen

BELOW BOARD
  five-slot + color-selection area at protected minimum width
  left: Scrubby positioned low
  Scrubby speech bubble sits above Scrubby, not as a full-width row
  right: cleaning props/decorative equipment

LOWER
  four boosters in one horizontal row, compact icons

BOTTOM
  pause control to the left of ad region
  ad region in center when monetization is actually enabled
  speed-up control to the right
```

The board must grow before decorative regions grow. Decorative Scrubby/cleaning props may scale down or crop within approved limits before the selection panel becomes unusably narrow.

### Board sizing priority

Available height is conceptually:

```text
safe viewport
- required top controls
- selection/slot area
- booster row
- bottom/ad/speed row
- minimum spacing
= maximum board allocation
```

The existing `BoardRenderer` remains the production board renderer. Do not replace it with one Control/Node per logical cell.

### Gameplay speed control

Owner-locked V1 gameplay speed is `1x` or `2x` only. The bottom-right gameplay control is the speed control and must visually support the current 1x/2x state.

Production manual 2x is economy-gated:
- current level: 200 SB;
- 15 minutes: 300 SB;
- 30 minutes: 500 SB;
- 60 minutes: 750 SB.

Timed entitlements are wall-clock expiry periods and continue counting in gameplay, Home/menus, pause, background and while the app is closed. If an entitlement exists, the player may switch 1x<->2x without another charge during that entitlement.

The game also automatically switches to 2x for free when authoritative M23 supply is exhausted: every FIFO column, including formerly hidden future batches, has zero remaining batches after the final successful transactional transfer into M24. This is not the same as "all normal slots are occupied." A rejected final placement does not trigger auto-2x.

2x is a gameplay-time multiplier only and must not change FIFO order, target selection, reservations, routing, quotas, no-ghost invariants or solver semantics. See `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md` and `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

## 6. Home screen responsive composition

Production Home uses containers, not a flattened screenshot:

```text
HomeScreen
└── SafeAreaRoot
    └── VBoxContainer
        ├── TopCurrencyHUD
        ├── GiftMeter
        ├── MainWorldArea
        │   ├── LeftShortcutColumn
        │   ├── CenterScrubbyArea
        │   └── RightShortcutColumn
        ├── PlayButton
        ├── WinStreakRewardTrack
        └── BottomNav
```

The central Scrubby/world composition is decorative. Navigation buttons and counters remain live components.

Canonical Home asset inventory: `assets/ui/HOME_ASSET_MANIFEST.json`. Raw generation candidates live under `assets/ui/generated/`; owner-approved production art lives under `assets/ui/final/`.

## 7. Reusable component library

Target component structure:

```text
scenes/components/ui/
  common/
    safe_area_root.tscn
    primary_button.tscn
    icon_button.tscn
    currency_chip.tscn
    progress_bar.tscn
    notification_badge.tscn
    section_header.tscn
  gameplay/
    color_tile.tscn
    color_column.tscn
    color_selection_panel.tscn
    slot_cell.tscn
    booster_button.tscn
    booster_row.tscn
    scrubby_speech.tscn
  hud/
    player_profile_chip.tscn
    top_hud.tscn
    ad_speed_row.tscn
    bottom_nav.tscn
  popup/
    base_popup.tscn
    popup_header.tscn
    reward_popup.tscn
    confirm_popup.tscn
    dim_background.tscn
  collection/
    card_tile.tscn
    robot_card.tscn
    album_page.tscn
```

Corresponding scripts live under `scripts/ui/` and may be split into matching subfolders as implementation grows.

## 8. Design tokens

Do not scatter arbitrary spacing and sizing values across scenes. Centralize UI constants/themes.

Baseline tokens:

```text
SPACE_XS  4
SPACE_SM  8
SPACE_MD  16
SPACE_LG  24
SPACE_XL  32

RADIUS_SM 12
RADIUS_MD 20
RADIUS_LG 28

ICON_SM 48
ICON_MD 72
ICON_LG 96

TOUCH_MIN 88
```

Typography baseline, subject to owner-approved font availability:

```text
body   30
button 34
title  48
hero   64
```

Use Godot `Theme` resources so later font/spacing/style changes propagate centrally.

## 9. Native Godot vs generated art

### Godot-native by default

- scalable panel bodies
- popup bodies
- button layout/interaction state
- progress bars
- slots and color tiles
- currency chips/counters
- notification containers/badges where simple geometry suffices
- dim overlays
- navigation/layout containers
- text, quantities and timers
- board container and responsive sizing

### AI-generated where illustration adds value

- Scrubby master character reference and approved poses
- robot portraits
- booster icon art
- reward chests and gift art
- special difficulty emblems
- collection decorative art
- special event illustrations
- branded decorative cleaning props
- optional complex icon families that cannot be reproduced cleanly with native shapes

This split protects credit usage and prevents routine layout tweaks from requiring image regeneration.

## 10. 9-slice / scalable texture policy

When generated art is used for a scalable frame/button:

- source is front-facing and symmetrical enough for 9-slice use;
- no baked text;
- transparent background;
- no uncontrolled outer drop shadow outside defined bounds;
- corners/borders occupy known fixed inset regions;
- import uses a `NinePatchRect` or `StyleBoxTexture` as appropriate;
- center area may stretch; corners must not.

Prefer native `StyleBoxFlat` when it can achieve the required look without compromising art direction.

## 11. Popup inheritance

All major modal flows share one base structure:

```text
BasePopup
├── DimBackground
└── CenterContainer
    └── PanelContainer
        └── VBoxContainer
            ├── PopupHeader
            ├── ContentSlot
            └── FooterSlot
```

Planned derived flows include:

- Normal/Hard/Very Hard level intro
- Life
- Need a Hand / Extra Help
- Victory
- Fail
- Out of Moves
- Reward/confirmation

Do not duplicate the same modal chrome in unrelated scenes.

## 12. Booster component state model

A reusable booster view should support at least:

```text
CHARGE_AVAILABLE
PURCHASABLE_SB
SELECTED
UNAVAILABLE
LOCKED
```

Quantity, SB price and state badges are separate live overlays, never baked into icon art.

Economy V1 authorizes exactly four boosters:
- +1 Slot: 500 SB; current-attempt capacity 5->6, max once/attempt.
- Random: 350 SB; solver-validated remaining-supply reorder with >=3 safe moves.
- Selector: 500 SB; one solver-safe arbitrary remaining batch into rightmost EMPTY slot.
- Tornado: 750 SB; atomically purge one selected color and reconcile all related runtime state.

Gift Bar and Daily may grant free booster charges. No fifth V1 booster is authorized. Canonical semantics: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

## 13. Asset directories

Generated/derived UI art uses:

```text
assets/ui/
  generated/     # raw AI outputs, not automatically approved
  final/         # owner-approved production-ready derived assets
  icons/
  characters/
  boosters/
  rewards/
  difficulty/
  decorative/
```

Owner source/reference images remain under `assets/art/references/` and are never overwritten by generated outputs.

## 14. Owner desktop reference intake

The owner has explicitly identified this local folder as SCRUBBOTS visual-reference source material:

```text
C:\Users\sekip\Desktop\ScrubBots Gorselleri
```

These files are references, not automatically production assets. Local Claude Code should run the repository intake helper, preserve bytes/names, copy them into the owner inbox, inventory them, and classify them into gameplay/UI/Scrubbot/pixel-method categories without deleting the originals.

Canonical intake staging path:

```text
assets/art/references/_owner_inbox/
```

After classification, originals may be copied into category folders while the inbox/source copy remains preserved according to the reference-library policy.

## 15. AI image-generation contract

`ASSET_GENERATION_MANIFEST.json` is the machine-readable queue/source of truth.

Claude Code workflow:

1. Read this document and the manifest.
2. Inspect existing approved final assets first.
3. Do not regenerate `APPROVED` assets unless the owner asks.
4. Resolve the canonical Scrubby reference before character generation.
5. Use ChatGPT image generation by default; Magnific MCP may be used as an approved fallback/alternate.
6. Generate isolated component art with transparent backgrounds where requested.
7. Use background removal only when needed.
8. Upscale/resize only as declared by the manifest.
9. Store raw results separately from final approved assets.
10. Bind final assets to Godot components only after asset validation/owner approval.
11. Record status/provenance in the manifest or inventory metadata.

Preferred generation prompt suffix for isolated UI art:

```text
single isolated mobile-game UI component, transparent background,
front-facing, centered, no environment, no text, no watermark,
clean silhouette, high resolution, consistent SCRUBBOTS glossy cartoon-3D style
```

## 16. Reference-image authority

Order of authority:

1. Owner-approved original SCRUBBOTS assets.
2. Owner-supplied SCRUBBOTS visual references.
3. AI-generated outputs explicitly approved for production.
4. External game screenshots as conceptual/method reference only.

External references must never be copied into SCRUBBOTS characters, exact UI, art composition or levels.

## 17. Validation gates

A responsive UI task is not complete because a `.tscn` exists. Validate:

- no clipping at required viewport matrix;
- board remains visible and aspect-correct;
- five slots remain usable;
- color-selection panel does not collapse;
- essential controls remain inside safe area;
- minimum touch sizes hold;
- popup fits without overflow;
- text does not collide at target localization expansion;
- BoardRenderer touch/coordinate mapping remains correct;
- no unintended per-cell Control/Node architecture appears;
- existing headless regression suite remains green.

Where automated screenshot comparison is unavailable, record manual visual evidence rather than claiming an unperformed pass.

## 18. Delivery phases

```text
UI-A  Reference intake + style authority + manifest
UI-B  Theme/tokens + SafeArea + responsive primitives
UI-C  Gameplay reusable controls and layout
UI-D  Home/navigation composition
UI-E  Popup family
UI-F  Multi-device visual/touch validation
UI-G  Final generated-asset production/approval pass
```

This UI program must be scheduled alongside existing gameplay milestones without replacing gameplay-critical M13–M21 work.
## Scrubbot Railroad V1 presentation / spacing contract `[OWNER-LOCKED 2026-09-14]`

Owner decision: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`; ADR-028.

The gameplay screen renders a reusable robotic **railroad** around the pixel-art
board via `scenes/components/ui/gameplay/scrub_rail_view.tscn`
(`scripts/ui/scrub_rail_view.gd`), driven by the single-source `ScrubRailGeometry`.

Spacing / visual contract:

- artwork-to-rail clearance is exactly `2.0` logical cells (>= 2 cells of visible
  breathing room); rail width is `1.0` logical cell; centreline `2.5` cells outside
  each board boundary; rounded mechanical corners whose motion path stays inside the
  rail envelope;
- consistent dark-slate metallic track with restrained cyan/electric guide nodes —
  the SAME visual language for every level; the rail never inspects level
  subject/theme and no per-level themed rail exists in V1;
- the rail is visually subordinate to the artwork, native/procedural Godot 2D (zero
  generated assets), and reskinnable later without changing target/routing truth;
- the five production `SlotCell`s (accepted M22 V01) sit BELOW the bottom rail, never
  inside the 2-cell artwork clearance; each clicked slot shows a visible connector to
  the bottom rail (real travel, no teleport);
- the rail must not distort the board aspect ratio and must not add a Node per board
  cell; the logical 2-cell clearance is invariant across physical viewport scale.

The railroad is presentation/routing space only — not LevelData/BoardState, not a
C01..C16 artwork layer, and it does not change Difficulty V1. It supersedes the M21
adjacent one-cell ring as future production movement geometry; M21 V07-V10 remain
valid historical evidence for their commits.


## 14. Home Economy V1 semantics

Home's owner-approved visual composition remains authoritative, but production meanings are:
- top currency = Scrub Bucks, not coin/Star;
- Heart counter = max 5, 30-minute wall-clock regen;
- profile progress bar = Bot Parts toward next 250-part robot unlock, not XP;
- former event progress bar = Gift Meter fed only by Win Streak SB, milestones 10/50/250/500/1000, no event timer;
- former Star Exchange shortcut = Cards Exchange;
- lower reward road = Win Streak SB reward track (1/5/10/25/100 SB mapping);
- Stars and Event Points do not exist as functional balances.

All values, prices, countdowns, reward amounts and labels remain live Godot UI.
