# OWNER GAMEPLAY 3/4/5 STATIC MASTER SHELL DECISION V01

Date: 2026-09-28
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL
Repository: `Sekiph82/Scrubbots`

## 1. Clarification

The owner-supplied images are **not merely backgrounds**.

They are the canonical full-screen gameplay shell/master variants for production.

### Normal capacity = 5 slots

- `3 lu renk secim alani.png` — 3-column Batch Supply, 5 execution slots
  - 887×1774 RGBA
  - SHA-256 `4ee6712df6aedb3ee48d5cf2e2971356bd9df14363e777965c7e4691ca3121da`
- `4lu renk secim alani.png` — 4-column Batch Supply, 5 execution slots
  - 887×1774 RGBA
  - SHA-256 `dcf92b4fe163d0c5e6543f90943528ea064c08b31ed11d5c26c158265a9a8fac`
- `5li renk secim alani.png` — 5-column Batch Supply, 5 execution slots
  - 887×1774 RGBA
  - SHA-256 `c520c5055caff58f5a9a1ff7eb7ceb98ce5873b9abf86e03b183a8442afc7636`

### +1 Slot active = 6 slots

These three newly owner-approved masters are canonical for the temporary six-slot state:

- `6 li slot 3 renk-batch sistemi.png` — 3-column Batch Supply, 6 execution slots
  - 887×1774 RGBA
  - SHA-256 `75c148266a4d0aec20a0eb5c299d00a2840e13d8cc10ae6ec60731f0823f8f06`
- `6 li slot 4 renk-batch sistemi.png` — 4-column Batch Supply, 6 execution slots
  - 887×1774 RGBA
  - SHA-256 `d3d01b697d14fbb8896b70594c5768dd1be7606a6519aec2aa71770a5fa38a55`
- `6 li slot 5 renk-batch sistemi.png` — 5-column Batch Supply, 6 execution slots
  - 887×1774 RGBA
  - SHA-256 `5ad162d288e8c8d33c5e40d0bb3caedb32939165853a602d868a4caa6428c12b`

All six images are the same owner-approved gameplay composition family, varying only by authoritative Batch Supply column count and execution-slot capacity.

This decision supersedes prior instructions that required Godot to redraw the static gameplay chrome already present in these masters.

## 2. Runtime master selection

The production gameplay screen selects the shell from **two authoritative runtime facts**:

1. Batch Supply column count: 3 / 4 / 5.
2. Execution-slot capacity: 5 / 6.

Canonical matrix:

| Supply columns | Capacity 5 | Capacity 6 (+1 Slot active) |
|---|---|---|
| 3 | normal 3-column master | 6-slot 3-column master |
| 4 | normal 4-column master | 6-slot 4-column master |
| 5 | normal 5-column master | 6-slot 5-column master |

When +1 Slot activates, the whole static shell switches to the corresponding six-slot master. When the attempt resets/retries and capacity returns to five, it switches back to the corresponding normal five-slot master.

**Do not dynamically draw a sixth slot or sixth connector anymore.** Those visuals are now baked into the approved six-slot masters.

Do not stretch the shell non-uniformly.

Use one reference-coordinate transform for the selected shell and every live overlay/hitbox so all dynamic content remains aligned.

For non-1:2 devices, preserve the shell's aspect ratio and use safe-area-aware aspect-fit / surrounding background treatment rather than distorting the baked rail/slots/panels.

## 3. Static content that remains baked into the master

Do NOT redraw these as duplicate Godot chrome:

- industrial/jungle gameplay environment;
- four-sided visible Railway/Railroad artwork;
- board frame / blue board field;
- five or six visible slot frames, according to the selected master;
- five or six visible slot-to-bottom-rail connector graphics, according to the selected master;
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

### Execution slots
The selected master already contains the exact authoritative slot capacity:
- normal shell: five slot frames/connectors;
- +1 Slot shell: six slot frames/connectors.

Overlay only:
- live batch color;
- live count;
- state/selection/cooldown information if needed.

Do not redraw additional slot frames or duplicate connector rails.

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

## 5. +1 Slot master switch

The owner has supplied and approved exact six-slot masters for all 3/4/5 Batch Supply column counts.

Therefore +1 Slot presentation is now shell selection, not dynamic chrome generation.

When authoritative capacity changes 5 -> 6:
- switch atomically to the matching six-slot master for the same Batch Supply column count;
- preserve all live slot/supply/profile/board/agent state;
- remap live overlays/hitboxes through the same reference transform;
- do not reset gameplay;
- do not create a seventh slot.

When capacity returns 6 -> 5 on retry/reset:
- switch back to the matching five-slot master;
- preserve canonical attempt/reset semantics.

The six-slot shell is visual presentation only; the actual sixth-slot existence still comes from the authoritative +1 Slot capacity state.

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

All six exact owner-supplied files must be copied byte-preserving into canonical repository paths before production binding.

Recommended canonical paths:

### Normal five-slot set
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_5col.png`

### +1 Slot six-slot set
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_5col.png`

Preserve historical `scrubbots_gameplay_master.png`; do not overwrite it.

Exact filenames/hashes are locked in Section 1. The owner may provide these assets either under their original owner filenames OR already renamed to the canonical repository filenames above.

Acceptance is based on:
1. exact locked SHA-256;
2. exact 887×1774 RGBA dimensions;
3. correct 5-slot/6-slot × 3/4/5 mapping.

Filename alone is not authority.

If any exact file cannot be found from the owner-approved source, stop and report `OWNER_ASSET_REQUIRED`. Do not regenerate or substitute.

The six exact files are also persisted in the user's ChatGPT Library under `/ScrubBots/Gameplay Masters/` as a preservation copy.

A convenience package also exists:
`ScrubBots_Gameplay_V02_Canonical_Masters.zip`

That package uses the canonical repository filenames:
- `gameplay_v02_shell_5slot_3col.png`
- `gameplay_v02_shell_5slot_4col.png`
- `gameplay_v02_shell_5slot_5col.png`
- `gameplay_v02_shell_6slot_3col.png`
- `gameplay_v02_shell_6slot_4col.png`
- `gameplay_v02_shell_6slot_5col.png`

Runtime implementation still requires committing the exact bytes into the repository.

Search only authorized project/reference locations; do not create extra Desktop project copies.

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

## 10. Owner amendment 2026-11-16: calm plaza shells (SB-GAMEPLAY-BG-2026-11-16)

Owner (chat, 2026-11-16): the dark industrial gameplay backgrounds distract. The owner supplied ONE
new calm plaza master (blue sky, trees, pink tile floor; same metal/blue frame, slot row, supply
panel, Scrubby, speech bubble and caution sign), 852×1846, 5 execution slots / 4 supply columns, and
asked for "the 6 versions at the correct measurements" produced from that image.

The six runtime masters are now `assets/ui/final/gameplay/master/gameplay_v03_plaza_shell_<id>.png`
(852×1846 RGB, one canvas for all six). `5slot_4col` is the owner image byte-for-byte; the other
five are cut only from the owner image's own pixels (no image generation): one real slot period
(slot frame + connector pipe + bottom-rail segment) added for 6 slots, one real supply column period
removed for 3 columns (uncovered floor rebuilt from the floor beside it), and for 5 columns the
emptied real panel widened 35 px with the real cell tiles (frame + top clip) laid at 0.80 scale and
an 87 px column pitch (keeps every front hitbox >= 88 px on 1080×1920). The speech bubble is
re-composited from the owner image over any widened part. Generator, measurement script, contact
sheet and captures: `factory/jobs/159-gameplay-shell-plaza/`.

| id | SHA-256 |
|---|---|
| 5slot_3col | `9242651d436cd354005b0311a0ff2a43f4ff789123fa5741412d9d39123b0e8d` |
| 5slot_4col | `47a8b9f86c74fcda2f94fd144db2d82a42aa9fdc6d2aca83dce6bf3b5722a4d8` (owner image) |
| 5slot_5col | `4c01e2322c41b3b5ce3d2e8742af7a675ae81ea5a2535b20cba6377d4d099026` |
| 6slot_3col | `e7502d7e6286fafa7d02254174fad6f1459c75e9d4f62f53792662f1de4d5ddc` |
| 6slot_4col | `c042c211fdb76c8177062be460fc2b6a95dd5e2b05718b566633a0086cef0272` |
| 6slot_5col | `b796ad4c78a529d8914a9628f2b5837d08664f00370cb3ca14e2492fa1071390` |

All baked reference coordinates (rail, slots, connectors, supply cells, top bar, bubble text mask,
booster and ad bands) were re-measured by pixel analysis and live in
`scripts/ui/gameplay_shell_geometry.gd`. Selection rules (§2), the +1 Slot switch (§5), the masked
bubble text (§6) and every live-overlay rule (§4) are unchanged. The 887×1774 `gameplay_v02_shell_*`
masters listed in §1 stay in the repository byte-identical as history and are no longer loaded.
