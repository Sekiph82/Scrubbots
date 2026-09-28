# OWNER GAMEPLAY 3/4/5 STATIC MASTER SHELL DECISION V01

Date: 2026-09-28
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL
Repository: `Sekiph82/Scrubbots`

## 1. Clarification

The three owner-supplied images are **not merely backgrounds**.

They are the canonical full-screen gameplay shell/master variants for production:

- `3 lu renk secim alani.png` — 3-column Batch Supply master
- `4lu renk secim alani.png` — 4-column Batch Supply master
- `5li renk secim alani.png` — 5-column Batch Supply master

Each image is 887×1774 and represents the same gameplay composition with a different Batch Supply column count.

This decision supersedes prior instructions that required Godot to redraw the static gameplay chrome already present in these masters.

## 2. Runtime master selection

The production gameplay screen selects exactly one shell according to the authoritative Batch Supply column count:

- 3 columns -> 3-column master
- 4 columns -> 4-column master
- 5 columns -> 5-column master

Do not stretch the shell non-uniformly.

Use one reference-coordinate transform for the shell and every live overlay/hitbox so all dynamic content remains aligned.

For non-1:2 devices, preserve the shell's aspect ratio and use safe-area-aware aspect-fit / surrounding background treatment rather than distorting the baked rail/slots/panels.

## 3. Static content that remains baked into the master

Do NOT redraw these as duplicate Godot chrome:

- industrial/jungle gameplay environment;
- four-sided visible Railway/Railroad artwork;
- board frame / blue board field;
- five visible slot frames;
- five visible slot-to-bottom-rail connector graphics;
- 3/4/5-column Batch Supply panel/frame and its three visible rows;
- top-left profile frame;
- two top-right control frames;
- Scrubby character illustration;
- speech bubble illustration;
- cleaning bucket / wet-floor props and decorative environment.

The master is the visual shell.

## 4. Live Godot overlays only

Godot/runtime remains authoritative for live/gameplay content only.

Overlay onto the shell:

### Board
- real `BoardRenderer` pixel art inside the master board aperture;
- transparent/cleared cells remain runtime truth.

### Scrubbot movement
- real Scrubbot agents and movement paths over the baked Railway;
- routing/target/reservation geometry remains canonical runtime truth;
- the baked Railway is visual only and must align to the runtime Railroad coordinate transform.

Do not draw a second visible Railway on top.

### Five execution slots
The five slot frames/connectors are already baked.

Overlay only:
- live batch color;
- live count;
- state/selection/cooldown information if needed.

Do not redraw five additional slot frames or five duplicate connector rails.

### Batch Supply
The cell frames are already baked.

Overlay only:
- live batch color;
- live count;
- state/highlight necessary for front vs preview truth;
- input hitboxes.

Only front batches are interactive.
Preview rows remain non-interactive.
Deeper queue remains hidden runtime truth.

### Profile
The frame is already baked.

Overlay only authoritative content:
- Scrubby/selected-robot profile image if required by the final composition;
- live Level N;
- live Bot Parts progress/text.

Do not invent XP/title/unsupported statistics.

### Pause / 2x
Use the two existing top-right baked control locations.

Overlay:
- Pause icon/state in the left control;
- 2x icon/state/live timed countdown in the right control.

### Bottom monetization / boosters
Reserve the lower gameplay area for:
- an ad region at the bottom;
- the four canonical boosters above/over that lower region.

Actual ad serving/monetization authority remains M57. This decision authorizes the visual/layout region, not real ad-network behavior.

Exactly four boosters remain:
- +1 Slot
- Random
- Selector
- Tornado

## 5. +1 Slot exception

The static masters intentionally contain the normal five-slot baseline.

When the authoritative +1 Slot booster creates a temporary sixth execution slot, that sixth slot cannot come from the baked five-slot master.

Therefore the **temporary sixth slot and its sixth connector are the one allowed runtime-added slot/connector visual**.

It must:
- appear only while capacity is actually six;
- use the same visual language as the master;
- align to the real sixth-slot route origin/entry;
- disappear on attempt reset/retry;
- not cause the normal baked five slots to be redrawn or duplicated.

Final sixth-slot placement remains subject to owner screenshot review if the existing implementation position does not visually fit the static shell.

## 6. Speech bubble

The bubble artwork itself is part of the static master.

The currently baked English sentence visible in the supplied images describes tapping same-colored board tiles, which is not the production input model.

Therefore that obsolete sentence must **not ship as gameplay instruction**.

Preferred production treatment:
- preserve the bubble artwork;
- blank/mask only the obsolete text area without changing the surrounding master composition;
- later M44 FTUE may place localized live tutorial text into the bubble.

Until M44, the bubble may remain visually blank.

Do not invent tutorial copy in this M28 cycle.

## 7. Owner visual choices resolved

The previous V1-V6 gate is superseded/resolved as follows:

- V1: use the supplied full-shell master set, not a native gradient-only gameplay surface.
- V2: use the baked profile/normal-slot chrome from the master; do not duplicate it with native look-alikes.
- V3: use only authoritative minimal profile data (Level + Bot Parts; no invented XP/title).
- V4: keep the master speech bubble artwork; obsolete baked instruction must be removed/masked; live tutorial copy deferred to M44.
- V5: preserve current safe responsive behavior, but the full shell must scale uniformly and remain aligned on tall/short devices.
- V6: use the Railway exactly as baked in the master. Do not redraw or change its visible segment density.

## 8. Asset intake

The three exact owner-supplied files must be copied byte-preserving from the owner's local visual-reference source into canonical repository paths before production binding.

Recommended canonical paths:

- `assets/ui/final/gameplay/master/gameplay_v02_shell_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5col.png`

Preserve the historical `scrubbots_gameplay_master.png`; do not overwrite it.

If the exact three owner files cannot be found locally, stop and report `OWNER_ASSET_REQUIRED`. Do not regenerate substitutes.

Likely exact owner filenames:
- `3 lu renk secim alani.png`
- `4lu renk secim alani.png`
- `5li renk secim alani.png`

Search only the canonical project / owner-reference locations already authorized by the project workflow. Do not create new Desktop project copies.

## 9. Precedence

This decision supersedes conflicting wording in:
- the C001 native-chrome visual fallback;
- earlier V1/V2/V6 owner-gate options;
- `OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md` only where it says the static shell must be rebuilt as separate Godot chrome.

It does NOT supersede:
- BoardRenderer truth;
- Railroad/routing geometry and movement truth;
- slot/supply gameplay truth;
- Economy/2x/Heart rules;
- responsive/safe-area requirements;
- M43 popup/modal dependency boundaries.
