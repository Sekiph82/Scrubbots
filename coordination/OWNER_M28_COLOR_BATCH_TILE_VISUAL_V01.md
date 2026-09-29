# OWNER M28 COLOR / BATCH TILE VISUAL V01

Date: 2026-09-29
Authority: OWNER
Status: PLANNED / OWNER-APPROVED VISUAL DIRECTION
Target task: SB-M28-C002-021
Target cycle: M28-C002-C004 — Color / Batch Tile Visual Polish

## Scope

This is a SEPARATE follow-up task.

It must NOT be merged into the currently running `M28-C002-C003-R01 V02` remediation.

The same reusable tile presentation must be used in:

1. the permanent five-slot gameplay system;
2. the temporary sixth slot when +1 Slot is active;
3. the Batch Supply / color-selection grid for 3/4/5-column configurations.

No gameplay truth changes are authorized.

## Owner-approved visual direction

Each occupied color/batch tile should look like a compact rounded 3D game button / cartridge:

- near-square face with rounded corners;
- main face uses the authoritative ScrubBots Palette v3 color;
- slightly lighter top highlight;
- subtle face shading only, avoiding heavy gradients that alter perceived palette identity;
- a clearly visible lower white / light-gray base layer projecting below the colored face;
- soft compact shadow under the tile;
- large centered batch/count number;
- count fill: white;
- count outline: strong black/dark outline for readability;
- clean, toy-like depth without becoming glossy plastic overload.

The overall reference is the owner-approved mockup shown in chat on 2026-09-29: colored rounded raised face, white/light lower platform, centered outlined white number.

## Reusable implementation

Preferred architecture: one shared Godot UI component, for example:

`ColorBatchTile`

Use the same component for slot contents and Batch Supply tiles.

Preferred implementation is procedural/native Godot UI:

- `Control` / `Panel` / `StyleBoxFlat` / `Label`;
- reusable theme/style function or component;
- runtime Palette v3 color injection;
- runtime live count text;
- responsive scaling.

Do NOT create 16 separate baked PNG tiles merely to represent C01-C16.

Do NOT bake numbers into textures.

A lightweight shader may be used only if native controls cannot produce the required result cleanly, but it is not the default approach.

## State presentation

### NORMAL / OCCUPIED

- standard raised tile;
- Palette v3 face color;
- white outlined count;
- normal base/shadow.

### ACTIVE

No literal `ACTIVE` text.

Communicate state visually only, using a restrained combination such as:

- subtle glow/outline;
- approximately 1.02–1.04 scale;
- slight highlight increase.

Avoid pulsing that becomes distracting.

### WAITING

No literal `WAITING` text.

Use the normal occupied appearance unless another already-authoritative visual distinction is required.

### EMPTY SLOT

- neutral empty housing/placeholder;
- must remain visibly different from an occupied color tile;
- no fake count.

### DISABLED / NON-INTERACTIVE PREVIEW

For Batch Supply preview rows or otherwise non-interactive states:

- lower opacity / lower emphasis;
- retain color identity and count readability;
- do not imply that the tile can be tapped.

## Slot housing separation

The railway / mechanical slot housing remains a separate visual structure.

The colored `ColorBatchTile` sits inside/on top of the slot housing like a cartridge.

Do not collapse the slot housing and the color tile into one asset.

This preserves the gameplay railway language while making the batch identity/count immediately readable.

## Batch Supply integration

For the Batch Supply / color selection grid:

- the same `ColorBatchTile` component is used;
- front selectable row remains clearly interactive;
- preview/deeper visible rows remain visibly lower priority and non-interactive;
- existing 3/4/5-column responsive support remains intact;
- hidden queue truth remains unchanged.

## Numeric readability

Counts must remain readable at all supported phone/tablet sizes.

### Owner correction — exact count centering

The player-facing batch/count number must be **geometrically centered in the COLORED TOP FACE of the tile on both axes**.

This is especially mandatory for the permanent five-slot / temporary sixth-slot system.

Rules:

- horizontal center of count label == horizontal center of colored face;
- vertical center of count label == vertical center of colored face;
- the white/light-gray lower 3D base is NOT part of the centering box;
- the lower base must not pull the number downward;
- invisible WAITING/ACTIVE spacer nodes, legacy VBox spacing, or any compatibility label must not influence the count's visual center;
- 1-, 2- and 3-digit counts must all remain centered without hand-tuned per-number offsets;
- use layout/anchors/alignment so centering remains correct after responsive resizing;
- if a legacy hidden state-label spacer must remain to preserve outer slot geometry/spawn anchors, keep it outside the colored-face count-layout calculation.

The shared ColorBatchTile should therefore own an explicit colored-face rect and place the count label as a full-face overlay centered with horizontal and vertical alignment.

Requirements:

- exact centered text on the colored face;
- bold font;
- white fill;
- dark/black outline;
- no clipping for at least 1–3 digit values used by production content;
- tile face color must never make the number unreadable.

## Palette fidelity

Use the existing authoritative ScrubBots Palette v3 values.

The visual treatment must not silently replace palette colors with approximate alternatives.

Highlight/shadow can modify local presentation subtly, but the central face must remain recognizably the canonical color.

## Responsive / touch

Validate:

- five permanent slots;
- temporary sixth slot;
- Batch Supply with 3, 4 and 5 columns;
- supported portrait phone matrix;
- tablet portrait.

Do not shrink hit targets below existing touch requirements.

## Logic invariants

This task is presentation-only.

Must not change:

- batch identities;
- counts;
- front/selectability truth;
- slot capacity truth;
- 5 -> 6 +1 Slot rules;
- placement;
- claims/reservations;
- routing;
- solver;
- economy;
- target selection;
- clear/completion truth.

## Performance

The component count is small and should remain lightweight.

No per-frame texture generation.
No separate texture loading per color/state if native styling suffices.
No one-node-per-logical-pixel relationship.

## Evidence / acceptance

Implementation cycle must provide fresh runtime evidence for:

- 5-slot occupied state, including exact geometric count centering;
- 6-slot occupied state, including exact geometric count centering;
- Batch Supply 5x3 visible layout;
- representative 3-column and 4-column layouts;
- ACTIVE state;
- EMPTY state;
- preview/non-interactive state;
- light and dark Palette v3 colors;
- narrow phone and tablet;
- explicit 1-, 2- and 3-digit count-centering evidence on slot tiles.

Owner visual acceptance is required before SB-M28-C002-021 closes.

## Sequencing

Canonical order:

1. finish current `M28-C002-C003-R01 V02` and owner replay;
2. run this as a separate `M28-C002-C004` implementation/audit cycle;
3. then continue queued follow-ups.

Do not modify the active V02 prompt to include this task.
