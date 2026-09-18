# M28-C001 V01 — Canonical Gameplay Reference Audit

Auditor artifact (Claude implementation evidence; ChatGPT owns audit closure).

## Reference audited

`assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`
(inventory `gameplay.status = CANONICAL_SELECTED`, i.e. the canonical **layout
reference**, NOT a production-approved illustration).

The reference was used ONLY to derive composition/layout intent. It was **not**
loaded, cropped, flattened, or bound as production UI or background. Reference PNGs
were preserved byte-for-byte (no reference file is modified or added by M28).

## Adopted composition/layout ideas

Mapped to native, container/responsive Godot Controls (never a screenshot):

| Reference idea | M28 realization |
|---|---|
| Board dominant, centered, aspect-correct | `BoardRegion` is the largest responsive band; `BoardPresentation` fits board+rail envelope preserving true W:H (never square-stretched). |
| Five color/robot slots along a strip | `FiveSlotStrip` = exactly five **read-only** `BatchSlotView` positions (occupancy/status, not destination buttons). |
| Supply of upcoming color batches | `BatchSupplyPanel` = 3/4/5 FIFO columns, exactly 3 visible rows (front primary, rows 2/3 preview), hidden depth never rendered. |
| Scrubby character low-left with speech bubble | `ScrubbyDecorationAnchor` (low-left of batch region) + `ScrubbySpeechAnchor` (above it, not full-width). |
| Cleaning props at right | `CleaningPropsAnchor` (right, lower priority — shrinks before supply/slots). |
| Four boosters in one row | `BoosterRow` = four compact presentation-only controls, horizontal. |
| Bottom bar: pause / ads / speed-up | `BottomActionRow` = pause (left) \| ad placeholder (center) \| **speed-up control** (right). Owner override `OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01` / `OWNER_GAMEPLAY_SPEED_RULE_V01` supersedes the old Settings position. |

## Speed control (owner-locked 1x/2x)

Bottom-right control is the **speed control**, not Settings. M28 presents distinct
1x/2x visual states (`get_speed_state()` / `set_speed_2x()`), new session defaults to
1x, and clearly indicates the current state. M28 wires **no** timing/toggle: the
manual toggle is M29, and the automatic `M23 supply exhausted -> 2x` transition must
consume authoritative M23 exhaustion state (never inferred from visible preview rows
or five-slot occupancy). Settings is a separate future concern, not on this screen.

## Superseded / excluded (deliberately NOT copied or bound)

- **Historical direct-slot interaction** (M21/M22 `ColorSelectionPanel.slot_activated`
  clickable slots): superseded. Production input is supply-front batch selection
  placed into the rightmost EMPTY slot (M24 truth); M29 wires touch. M28 revives no
  destination-slot click mechanic — `FiveSlotStrip`/`BatchSlotView` are not Buttons
  and expose no activation signal.
- **Goal/Moves panel**: excluded (owner-locked). `has_goal_moves_panel()` proven false.
- **Level/lock rail**: excluded (owner-locked). `has_level_lock_rail()` proven false.
- **Reference-only illustrations** (Scrubby art, props, icons, background in the
  screenshot): NOT production-approved. Not cropped, not promoted, not bound. Neutral
  native placeholder anchors stand in until an explicitly APPROVED asset exists.

## Layout contract / region priority

`SafeAreaRoot → ScreenContent → { TopRegion(minimal, no HUD) · BoardRegion(dominant)
· BatchRegion(FiveSlotStrip + [Scrubby/Speech | protected Supply | Props]) ·
BoosterRow(4) · BottomActionRow(pause|ad|settings) }`.

Responsive priority (shrink order): decoration anchors shrink first; the supply
region holds a protected minimum width; the batch region holds a protected minimum
height; the board region always remains the largest band (COMPACT/NORMAL/TALL).
