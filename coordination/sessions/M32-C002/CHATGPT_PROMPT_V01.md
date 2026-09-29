# M32-C002 — BOARD-RESOLUTION-INDEPENDENT SCRUBBOT APPARENT SIZE — IMPLEMENTATION PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M32-UI-012`
Status: READY FOR CLAUDE

Owner authority:
`coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md`

M29 tempo is CLOSED / OWNER PASS.

Do not edit root `TASKS.md`.

## Mission

Make live gameplay Scrubbots keep approximately the SAME apparent screen size when the logical board resolution changes.

Current behavior:

`ScrubbotVisual.BODY_SPAN_CELLS = 2.4`

Because the AgentLayer maps one board-local unit to the renderer's actual cell size, a constant 2.4-cell body becomes:

- too large on low-resolution boards;
- owner-reference size around 32x32;
- progressively too small on 38x38 / 59x59 / future denser boards.

The owner-approved reference is the CURRENT 32x32 / 2.4-cell appearance.

This is PRESENTATION ONLY.

## Owner-locked scaling rule

Use the actual rendered presentation geometry, not a hardcoded board-size lookup.

Conceptually, on the same viewport/presentation:

`target_display_span = 2.4 * reference_32_cell_display_size`

`local_body_span_cells = target_display_span / current_rendered_cell_display_size`

Therefore, ignoring integer renderer rounding, the expected examples are approximately:

- 20x20 -> 1.50 cells;
- 32x32 -> 2.40 cells;
- 38x38 -> 2.85 cells;
- 59x59 -> 4.425 cells;
- synthetic 100x100 -> 7.50 cells.

But implementation MUST derive from the real rendered cell scale and reference presentation geometry, so exact local spans may differ slightly because BoardRenderer intentionally floors cell size.

Do not implement a table such as `if size == 20: 1.5`.

## Recommended geometry seam

`BoardPresentation.configure(board, palette, available_size)` already owns the real display geometry.

A clean implementation is to expose/store enough read-only presentation data to compute:

- current rendered cell display size;
- the cell display size a 32x32 reference board would have inside the SAME available presentation rect.

For example, semantically:

`reference_cell_size_32 = max(floor(min(available_size.x / 32.0, available_size.y / 32.0)), 1.0)`

`compensation = reference_cell_size_32 / current_cell_size`

`body_span_cells = 2.4 * compensation`

Equivalent geometry-derived implementations are acceptable.

Do not push screen-pixel math into:
- RoutingSystem;
- ScrubbotAgent movement;
- BoardState;
- target selection.

## Dynamic relayout requirement — BLOCKING

The apparent size must stay correct when a live gameplay screen is resized/relaid out.

Existing live ScrubbotAgent nodes survive BoardPresentation relayout.

Therefore, sizing only once in `ScrubbotVisual._ready()` is insufficient if the AgentLayer cell scale/reference geometry later changes.

Required:

- newly spawned visuals use the current compensation;
- already-live visuals update after responsive relayout;
- no agent recreation;
- no route reset;
- no position jump;
- no gameplay timing change.

Use an efficient presentation seam. Do not rebuild/decode textures on relayout.

## Rectangular boards

Use actual rendered cell scale / available presentation geometry.

Prove at least two rectangular examples, including one width-limited and one height-limited case if practical.

The Scrubbot target display footprint should remain consistent even though board width/height differ.

Never assume `width == height`.

## Synthetic 100x100 proof

Do NOT expand production board validation/catalog legality.

Use only a TEST/synthetic geometry fixture or direct presentation calculation to prove that the formula remains sensible at a future 100x100 logical board.

The synthetic fixture must not enter production catalog/data.

## Retire echo consistency

The current Scrubbot retire echo uses:

`ECHO_SPAN_CELLS = 2.1`

and was tuned to remain approximately the same ratio to the 2.4-cell live body.

Do not leave the echo resolution-dependent while the live body becomes resolution-independent.

Apply the SAME presentation compensation to the echo footprint so the accepted live/echo ratio remains:

`2.1 / 2.4`

This is still presentation-only.

Do not change:
- echo lifetime;
- fade;
- shrink ratio;
- concurrency cap;
- authenticated-clear event source.

## Preserve exactly

Do not alter:

- ScrubbotAgent authoritative position;
- route points;
- route progress;
- speed;
- M29 9/18 cells/s tempo;
- target selection;
- claims/reservations;
- clear timing/identity;
- BoardState;
- BoardRenderer cell geometry;
- board hit testing;
- railway;
- solver;
- economy;
- current production board validity envelope.

The visual can change local Sprite2D scale only.

Bob/lean/squash may continue, but their body-scale baseline must be derived from the compensated base size.

## Texture / asset rules

Keep the same canonical owner-approved texture:

`res://assets/ui/final/characters/scrubby/scrubby_gameplay.png`

Do not regenerate or replace it.

Keep shared texture caching.

No per-board-size image assets.

No per-agent texture decode.

## Required focused test suite

Create a dedicated M32-C002 focused suite.

### 1. Geometry-derived formula

For the same presentation rect, prove the computed local span follows the actual rendered cell scale rather than a size lookup.

Cover:
- 20x20;
- 32x32;
- 38x38;
- 59x59;
- rectangular boards;
- synthetic 100x100 calculation/TEST fixture.

### 2. 32x32 reference lock

At the reference presentation:

- 32x32 local body span remains the accepted 2.4-cell equivalent;
- apparent display span is the reference baseline.

Do not silently resize the owner reference.

### 3. Apparent-size consistency

Measure actual rendered/global body footprint, not only constants.

For a fixed viewport/presentation rect, compare longest displayed body dimension.

Required target:

- 20/32/38/59 and rectangular examples remain within **±3%** of the 32x32 reference apparent span;
- synthetic 100 calculation also predicts within ±3% subject to integer cell-size floor behavior.

If renderer integer flooring makes a specific synthetic edge case exceed 3%, document it and prove the implementation is mathematically exact to the geometry-derived target; do not hand-tune by board size.

### 4. Live relayout

With a real production host:

- spawn at least one live Scrubbot;
- record route/progress/agent position;
- resize viewport and relayout;
- prove body apparent size recomputes;
- prove same agent instance survives;
- prove route/progress/position truth is unchanged by relayout itself;
- continue movement successfully afterward.

### 5. Presentation-only differential

Run equivalent agent movement with:
- compensated visual attached;
- bare visual/control agent.

Prove byte/epsilon-identical:
- authoritative agent position;
- progress;
- arrival;
- completion count;
- endpoint.

### 6. Echo

Across 20/32/38/59:
- echo apparent span remains the same screen-size family as live body;
- echo/live ratio remains ~2.1/2.4;
- echo placement stays exact cleared-cell center;
- lifetime/shrink/cap unchanged.

### 7. Performance

At dense live-bot presentation:
- no per-frame texture decode;
- no unbounded allocations;
- relayout update cost bounded;
- 59x59 with representative concurrent live bots remains stable.

Do not introduce a per-frame traversal of the whole scene tree if a cached presentation generation/revision seam can avoid it.

## Fresh visual evidence — REQUIRED

Create fresh screenshots under:

`coordination/sessions/M32-C002/evidence/`

At minimum:

- 20x20;
- 32x32 reference;
- 38x38;
- 59x59;
- one rectangular board;
- synthetic 100x100 debug/geometry proof if renderable without changing production legality;
- one before/after responsive relayout pair.

Use the SAME viewport size for the main 20/32/38/59 comparison.

Evidence should make the Scrubbot apparent-size consistency visually obvious.

Also provide a machine-readable/text measurement report containing:

- board dimensions;
- available presentation rect;
- current cell size;
- reference 32-cell size;
- compensation factor;
- local body span in cells;
- measured displayed body span in pixels;
- delta from 32x32 reference;
- echo span where applicable.

## Owner visual gate

Technical PASS will still require owner visual review.

Owner will inspect the evidence for:

1. 20/32/38/59 Scrubbots looking approximately the same physical size;
2. 32x32 still matching the accepted current appearance;
3. rectangular board not looking anomalous;
4. live/echo proportion still looking correct.

## Regression gate

Run at minimum:

- new M32-C002 focused suite;
- existing M32 visual/echo evidence;
- M29 presentation + tempo;
- M28 gameplay responsive/static-shell;
- M31 cleaning effects;
- M30 retry;
- M39;
- M52;
- M55 long session;
- root suite;
- `git diff --check`.

Known historical m21_v08/v09 baseline may remain only with exact known signatures.

## Governance

Do not edit root `TASKS.md`.

Preserve owner/local files.

No destructive reset/clean/force push.

## Required outputs

Create:

- `coordination/sessions/M32-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M32-C002/IMPLEMENTATION_MATRIX_V01.md`
- `coordination/sessions/M32-C002/evidence/`

Commit/push to `main`.

Return:
1. final SHA;
2. geometry formula/seam used;
3. 20/32/38/59/rectangular/100 measurements;
4. live-relayout proof;
5. echo consistency result;
6. regression summary;
7. owner visual evidence links.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M32-C002 BOARD-INDEPENDENT SCRUBBOT SIZE V01`
