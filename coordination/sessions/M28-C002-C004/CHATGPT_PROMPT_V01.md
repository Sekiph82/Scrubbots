# M28-C002-C004 — COLOR / BATCH TILE VISUAL POLISH — IMPLEMENTATION PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Status: READY FOR CLAUDE

Owner authority:
`coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`

Previous cycle M28-C002-C003-R01 is CLOSED / OWNER PASS. This is a separate visual-polish cycle.

Do not edit root `TASKS.md`.

## Mission

Replace the current flat occupied slot/supply batch presentation with the owner-approved reusable rounded 3D color/batch tile language, while preserving every gameplay/input/economy/solver rule.

The SAME visual component/style must drive:

1. the five permanent gameplay slots;
2. the temporary sixth slot;
3. Batch Supply front tiles;
4. Batch Supply preview rows for 3/4/5-column layouts.

The result must match the owner-approved direction recorded in the authority file:

- rounded near-square colored top face;
- authoritative Palette v3 face color;
- restrained top highlight / subtle depth;
- visible white/light-gray lower base projecting beneath the face;
- compact shadow;
- large white batch/count number with strong dark outline;
- ACTIVE communicated visually only;
- no visible WAITING / ACTIVE words;
- EMPTY remains a distinct neutral housing/placeholder;
- preview rows lower-emphasis/non-interactive.

## Critical owner correction: slot count numbers must be EXACTLY centered

This is mandatory.

The numeric count in each occupied slot must be geometrically centered in the **COLORED TOP FACE** on both axes.

Not "approximately centered". Not centered in the total control including the lower 3D base.

Required:

- count-label center X == colored-face center X;
- count-label center Y == colored-face center Y;
- lower white/light-gray 3D base does NOT affect the count centering box;
- invisible WAITING/ACTIVE labels/spacers do NOT affect the count position;
- legacy VBox spacing must not push the number upward/downward;
- 1-, 2- and 3-digit counts stay centered without special-case offsets;
- responsive resizing keeps the same centering relationship.

Preferred implementation: the shared tile owns an explicit colored-face Control/Panel and the count Label overlays that face full-rect with horizontal + vertical CENTER alignment.

If `BatchSlotView` still needs a hidden state-line compatibility spacer to preserve the OUTER slot geometry / spawn anchor, that spacer must sit outside the tile face and must not participate in count layout.

Do not change `FiveSlotStrip.get_slot_anchor_global()` semantics or Scrubbot spawn origins.

## Reusable architecture

Prefer one reusable component such as:

`scripts/ui/color_batch_tile.gd`

or an equivalent shared presentation helper/component.

Avoid duplicating nearly identical slot and supply styling.

Preferred native Godot implementation:
- Control / Panel / PanelContainer;
- StyleBoxFlat;
- Label;
- runtime Palette v3 color injection;
- runtime count injection;
- explicit state styling;
- no 16 separate baked color PNGs;
- no count text baked into textures.

A shader is optional only if native controls cannot achieve the approved look cleanly.

## Slot integration

`BatchSlotView` remains presentation-only and retains detached snapshot semantics.

Preserve:
- occupied/empty truth;
- ACTIVE/WAITING internal truth;
- displayed count = `remaining_to_clear - committed`;
- no player click/activation behavior;
- five -> six capacity behavior;
- slot outer rect and spawn-anchor geometry;
- rail/housing relationship.

The colored tile should read as a cartridge sitting inside/on top of the existing mechanical slot housing, not replace the rail/housing itself.

No WAITING / ACTIVE words may return.

## Batch Supply integration

`BatchSupplyPanel` remains presentation-only except its existing front-row input surface.

Preserve:
- 3/4/5 columns;
- exactly 3 visible rows;
- row 0 front/selectable;
- rows 1/2 preview-only;
- hidden deeper queue remains hidden;
- one physical gesture -> one front activation;
- current hit geometry / >= owner-approved touch target behavior;
- exhausted columns;
- column-specific FIFO advance.

Use the same tile visual language.

Front tiles should be visually primary.
Preview tiles should be lower emphasis while retaining readable color/count.

## State visual behavior

### OCCUPIED / normal
- canonical face color;
- white outlined count centered in face;
- subtle depth/base/shadow.

### ACTIVE
- no text;
- restrained visual emphasis only, e.g. edge/glow/highlight and/or ~1.02–1.04 scale if it does not disturb layout/spawn geometry.

### WAITING
- no text;
- visually quieter than ACTIVE if needed;
- no semantic ambiguity introduced.

### EMPTY
- neutral empty slot/housing;
- no fake colored face;
- no count.

### SUPPLY PREVIEW
- lower emphasis/opacity or equivalent;
- still readable;
- must not look tappable.

## Palette fidelity

Use the current authoritative ScrubBots Palette v3 values.

Do not substitute approximate colors.

Highlight/shadow may modify small presentation bands, but the central face must preserve recognizable canonical color identity.

## Required focused tests

Add a focused M28-C002-C004 suite proving at minimum:

1. one shared/reusable tile styling/component path is used by slot and supply presentation;
2. five-slot occupied state renders live correct counts;
3. temporary sixth slot uses the same tile visual;
4. Batch Supply works for 3, 4 and 5 columns;
5. front vs preview presentation remains distinguishable;
6. preview rows remain non-interactive;
7. no visible WAITING/ACTIVE text;
8. EMPTY has no fake count;
9. displayed slot count remains `remaining_to_clear - committed`;
10. exact slot-count centering:
   - 1 digit;
   - 2 digits;
   - 3 digits;
   - ACTIVE;
   - WAITING;
   - five-slot and sixth-slot cases;
11. center proof must compare the label/control visual/layout center against the explicit COLORED FACE rect center, not the outer tile/base rect;
12. hidden compatibility spacer/state line cannot alter the face/count center;
13. responsive resize keeps center alignment;
14. Palette v3 face color identity remains correct;
15. no slot spawn-anchor drift;
16. no supply front hit-rect drift/overlap or gesture duplication;
17. no gameplay/solver/economy mutation from presentation refresh.

## Required fresh visual evidence

Under:

`coordination/sessions/M28-C002-C004/evidence/`

Provide at minimum:

- 5-slot occupied runtime shot;
- 6-slot runtime shot;
- 5x3 Batch Supply runtime shot;
- 3-column and 4-column examples;
- ACTIVE tile;
- WAITING tile;
- EMPTY tile;
- preview row state;
- light Palette v3 face;
- dark Palette v3 face;
- narrow phone;
- tablet;
- close-up evidence for 1-, 2- and 3-digit slot counts proving they are centered in the COLORED FACE.

If useful, include a debug/evidence overlay showing:
- colored-face rect center;
- count-label rect center;
- measured delta X/Y.

That overlay must be evidence/debug only, never shipping UI.

## Regression gate

Run at minimum:

- new M28-C002-C004 focused suite;
- M28 current/final presentation suites;
- M29 input/presentation identity;
- M39 +1 Slot integration;
- M43 popup/modal interactions that overlay gameplay;
- M52 slot/supply integration;
- routing/origin tests affected by slot geometry;
- responsive/touch suites;
- root suite;
- `git diff --check`.

Any pre-existing unrelated baseline/flakes must be identified exactly, not hidden.

## Scope locks

Do NOT change:

- root `TASKS.md`;
- gameplay route logic;
- railway-first rule;
- target/claim/reservation;
- board/grid/bevel;
- speed behavior;
- economy prices/durations;
- Heart/booster rules;
- M23/M24 supply/slot truth;
- current Home implementation;
- solver/difficulty;
- level data.

This task is presentation-only.

## Required outputs

Create:

- `coordination/sessions/M28-C002-C004/CLAUDE_LOG_V01.md`
- `coordination/sessions/M28-C002-C004/IMPLEMENTATION_MATRIX_V01.md`
- fresh evidence directory.

Commit/push all authorized work to `main`.

Return:
1. final SHA;
2. changed files;
3. focused/regression results;
4. evidence links;
5. any owner visual-review items still required.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M28-C002-C004 COLOR-BATCH TILE VISUAL POLISH V01`
