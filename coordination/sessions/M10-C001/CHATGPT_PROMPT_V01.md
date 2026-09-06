# M10-C001 — BoardRenderer Debug Real Artwork Fixtures (V01)

Status: **ISSUED**
Owner intent: add three owner-authorized real-artwork debug fixtures to the existing Godot 4.7.1 BoardRenderer manual-QA tool. This is a **debug/manual-QA tooling** cycle for the open M10 gates. It is not a production-content import cycle and must not open M14+.

## First action — safe local synchronization

Local working copy is expected at:

`C:\Users\sekip\Desktop\ScrubBots`

Before changing anything:

1. Inspect `git status --short --branch`, current branch, remotes, and any untracked/modified owner files.
2. Preserve all owner work. Never use `reset --hard`, `clean -fd`, force push, or destructive checkout/restore.
3. Safely synchronize local `main` with `origin/main`. If local owner changes prevent a clean fast-forward, preserve them and report the exact state rather than destroying them.
4. Record durable evidence only in the matching GitHub log:
   `coordination/sessions/M10-C001/CLAUDE_LOG_V01.md`.
   Do not create a Desktop phase log.

## Mandatory reading

Read current repository truth before implementation:

- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/05_TECH_DECISIONS.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
- https://github.com/Sekiph82/Scrubbots/blob/main/docs/08_PIXEL_ART_PALETTE_RULES.md
- https://github.com/Sekiph82/Scrubbots/blob/main/data/palettes/scrubbots_palette_v1.json
- https://github.com/Sekiph82/Scrubbots/blob/main/scenes/debug/board_renderer_debug.tscn
- https://github.com/Sekiph82/Scrubbots/blob/main/scripts/debug/board_renderer_debug.gd
- https://github.com/Sekiph82/Scrubbots/blob/main/scripts/debug/board_debug_fixtures.gd
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M10-C001/OWNER_FIXTURE_DATA_V01.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M10-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Current main at issuance was checked after the latest owner locks. The most recent commits were:
- `c0d767f5b385639170294f15b56d60fbc7a5fc66` — `docs: lock BG01 gameplay background color`
- `6d2447e00046ea0f192ce5a38ce795e3d00777ce` — `docs: lock global 15-color pixel-art palette`
- `92b0ae410bfdf13a36fc317c7b685d14ffe47171` — META-C004 V02 audited-pass handoff work

Do not assume those SHAs are still HEAD after this prompt issuance. Re-read `origin/main`.

## Current architecture you must preserve

The existing debug scene is deliberately tiny and script-driven:

- `scenes/debug/board_renderer_debug.tscn` is a Control with `scripts/debug/board_renderer_debug.gd`.
- `board_renderer_debug.gd` builds the debug UI procedurally.
- `BoardRenderer` remains one batched `Image/ImageTexture` per board. Never create one Node per cell.
- `BoardDebugFixtures` currently supplies synthetic in-memory fixtures.
- ACTIVE = exact source palette color, opaque.
- CLEARED = alpha 0 transparent, background shows through.
- No DIRTY/CLEAN transform and no A/B/C preset.
- M10-005..011 remain owner manual-QA gates. **Do not mark them complete on the owner's behalf.**
- M14/M15/M16/M17 remain unopened implementation gates. Do not touch them.

Also correct the stale comment in `scripts/debug/board_debug_fixtures.gd` that still says the project has no real palette. The canonical 15-color palette now exists and is owner-locked.

## Owner-locked palette/background contract

Logical production artwork colors are exactly C01..C15 from `scrubbots_palette_v1.json`.

For these three debug fixtures, use only the listed canonical subsets.

Production gameplay background:

`BG01 Midnight Slate = #202533 = RGB(32,37,51)`

Rules:
- BG01 is not C16.
- BG01 must never be inserted into a LevelData logical palette.
- CLEARED is transparent alpha 0, not a palette color.
- Visible square-cell boundaries are presentation only and do not add logical colors.

## Critical visual requirement — keep square cells, remove bead styling

The source images were plastic/bead-like. The owner explicitly does **not** want that material style.

For Real Artwork fixtures:
- every physical square remains visibly a square gameplay-cell unit;
- preserve visible square cell boundaries/separation;
- cell interiors are one flat solid canonical palette color;
- no gloss;
- no highlight;
- no bevel;
- no drop shadow;
- no 3D bulge/embossing;
- no interpolation.

Do **not** implement this by creating one Control/ColorRect/Sprite/Node per cell.

Because the owner is using this debug tool to approve the look, implement the cell-boundary treatment as a batched/presentation-only debug layer (for example one custom draw pass, one texture-generation pass, or another constant-node-count solution). Do not silently redesign the production BoardRenderer contract in this cycle. The debug visual can establish the candidate production look for owner review.

## Fixture selector required

Add a new `Fixture` OptionButton to the existing BoardRenderer Debug UI.

It must expose exactly:

```text
Fixture
├─ Synthetic Stripes
├─ Real Artwork - Level 007
├─ Real Artwork - Level 010
└─ Real Artwork - Level 013
```

Expected behavior:
- `Synthetic Stripes` preserves the existing synthetic size dropdown behavior and current ACTIVE/CLEARED pattern QA.
- Real Artwork fixtures use their own fixed true source-grid dimensions and palette subset; the size dropdown must not silently resize/resample them. Disable/ignore the size selector when a real-artwork fixture is selected, or otherwise make the fixed size unmistakable.
- The existing state-pattern dropdown remains useful. Apply patterns only to actual artwork cells. Debug-only VOID/background positions must stay visually absent/background and must not become colored artwork when switching patterns.
- Real Artwork fixtures use BG01 behind the board so the owner sees the intended production background. Synthetic Stripes may keep the conspicuous magenta transparency-proof background.
- Changing fixture/pattern must refresh cleanly without accumulating nodes/resources/signals.

## Debug-only VOID handling — do not mutate production semantics

Levels 007 and 013 have an irregular artwork silhouette inside a rectangular bounding matrix. The owner distinguishes:

- `VOID` = no artwork/gameplay square at that source position.
- `CLEARED` = a real artwork cell that was present and has been cleared.
- `BG01` = surface behind transparent/absent artwork.

Current production `LevelData/BoardState` does not have a canonical VOID CellState. **Do not invent a new production BoardState state in this M10 debug cycle.**

Implement a narrow debug-fixture mask/adapter so:
- VOID positions never become visible logical artwork cells;
- pattern changes operate only on real artwork cells;
- VOID is excluded from palette/color counts;
- this remains dev/debug tooling and does not leak into production level catalog semantics.

If the cleanest implementation needs a dedicated debug fixture data class/record or a debug-only mask beside LevelData, do that. Keep the boundary explicit.

## Data placement

Do not dump the large arrays directly into `board_renderer_debug.tscn`.

Repository rule 7 still applies: data stays separate from scene/script presentation. The scene is the entrypoint through which the fixtures are selectable.

Use a clearly dev-only data location such as:

`data/debug/board_renderer_fixtures/`

or another equally clear repository-consistent location discovered during inspection.

The canonical source arrays/mappings for this cycle are in:
`coordination/sessions/M10-C001/OWNER_FIXTURE_DATA_V01.md`

Convert them deterministically into the debug fixture format you implement. Do not re-OCR, approximate, regenerate, or artistically reinterpret them.

## Exact fixture contracts

### Real Artwork - Level 007
- source matrix: 27 columns × 24 rows
- actual artwork cells: 542
- VOID positions: 106
- palette subset:
  - C04 Leaf Green `#55B85A`
  - C10 Candy Pink `#E66FA5`
  - C14 Charcoal `#3D4652`
  - C15 Pure White `#FFFFFF`
- counts:
  - C04 = 217
  - C10 = 24
  - C14 = 165
  - C15 = 136

### Real Artwork - Level 010
Owner requested all source greens be recolored into the canonical blue family.
- source matrix: 49 columns × 50 rows
- no VOID positions in the supplied conversion
- palette subset:
  - C01 Coral Red `#E94B4B`
  - C02 Tangerine Orange `#F28C3C`
  - C03 Sunny Yellow `#F2C94C`
  - C06 Cyan `#42C7D9`
  - C07 Ocean Blue `#3E7EDB`
  - C08 Deep Blue `#3451A3`
  - C14 Charcoal `#3D4652`
  - C15 Pure White `#FFFFFF`
- source green remap:
  - bright green -> C06 Cyan
  - mid green -> C07 Ocean Blue
  - dark green -> C08 Deep Blue
- counts:
  - C01 = 16
  - C02 = 638
  - C03 = 560
  - C06 = 151
  - C07 = 603
  - C08 = 211
  - C14 = 229
  - C15 = 42

### Real Artwork - Level 013
- source matrix: 28 columns × 31 rows
- actual artwork cells: 375
- VOID positions: 493
- palette subset:
  - C02 Tangerine Orange `#F28C3C`
  - C03 Sunny Yellow `#F2C94C`
  - C09 Purple `#845EC2`
  - C14 Charcoal `#3D4652`
  - C15 Pure White `#FFFFFF`
- counts:
  - C02 = 68
  - C03 = 112
  - C09 = 26
  - C14 = 156
  - C15 = 13

## Important: these are debug/manual-QA fixtures, not production catalog levels

Do not claim all three are production-valid levels merely because their used-color counts resemble Easy/Hard bands.

In particular:
- Level 010 is 49×50, which crosses the production dimension band boundary.
- Level 013 is 28×31, which also crosses a production dimension band boundary.

Therefore:
- keep these fixtures in TEST/debug context;
- do not add them to the production LevelCatalog;
- do not mark M47/M48 content-import tasks complete;
- do not alter difficulty rules to make them pass production validation.

Level 007 happens to fit an Easy dimension/color band, but this cycle still treats it only as a manual-QA debug fixture unless/until a later production-content cycle promotes it deliberately.

## Implementation expectations

Prefer extending the existing system rather than replacing it:

1. Add a fixture model/loader in debug scope.
2. Load/construct the selected real artwork with exact dimensions, palette subset, row-major IDs and VOID mask from the owner data.
3. Map global C-IDs to the local LevelData palette indices in ascending C-ID order.
4. Construct BoardState from the fixed fixture level.
5. Keep real artwork cells ACTIVE initially.
6. Keep VOID positions out of artwork/pattern mutation through the debug mask/adapter.
7. Let the existing pattern dropdown demonstrate ACTIVE/CLEARED behavior on real artwork cells.
8. Use BG01 for Real Artwork backgrounds.
9. Preserve one-batched-board rendering and constant-node-count intent.
10. Present visible cell boundaries without bead/3D effects and without per-cell nodes.
11. Update debug info text to show fixture name, true dimensions, actual artwork-cell count, VOID count, used canonical color count, cell size and state pattern.
12. Keep Synthetic Stripes behavior/regressions intact.

## Tests and validation required

Run baseline before meaningful modification when possible, then final validation.

Minimum:
- `godot --version` must report installed Godot 4.7.1 stable or current repository-approved equivalent.
- headless full suite:
  `godot --headless --path . -s res://tests/run_tests.gd`
- headless boot or equivalent parse/startup proof for:
  `res://scenes/debug/board_renderer_debug.tscn`
- verify Fixture OptionButton has the exact four labels and deterministic ordering.
- verify all three fixture dimensions.
- verify every real-artwork logical color is canonical and subset ordering is ascending C-ID.
- verify exact per-color counts and VOID counts listed above.
- verify row-major array length = columns × rows for each fixture.
- verify pattern changes do not turn VOID into artwork.
- verify ALL CLEARED on a real artwork fixture makes every real artwork cell transparent while VOID remains background.
- verify ALL ACTIVE reconstructs the mapped artwork layout.
- verify real-artwork background is exactly BG01 `#202533`.
- verify synthetic fixture retains its existing behavior.
- verify no per-cell Node explosion. Compare renderer/debug child-count behavior before/after and include evidence.
- verify no interpolation/material styling was added. Cell fill must be flat canonical color; boundary treatment must be presentation-only.
- inspect Godot output for parse/runtime errors.
- inspect `git diff` before commit.

Add focused automated regression tests where practical. Do not make a visual claim from tests alone: owner manual QA remains open.

## Files likely in scope

Expected, but inspect before deciding:
- `scripts/debug/board_renderer_debug.gd`
- `scripts/debug/board_debug_fixtures.gd`
- dev-only fixture data files under an appropriate `data/debug/` path
- targeted tests in `tests/`
- `CHANGELOG.md` only if current project convention calls for this debug tooling change
- coordination/H!veAI files required by protocol

Avoid production gameplay-system edits unless absolutely necessary for a narrow non-behavioral seam. If you discover that exact owner requirements require a production semantic change, stop and report the conflict rather than widening scope.

## Task ledger rules

- Do not create new SB task IDs.
- Do not mark SB-M10-005..011 complete. Those are owner manual-review tasks.
- SB-M10-012 is already complete; this work extends its tooling but does not change canonical progress by itself.
- Do not alter M14+ state.

## Coordination/evidence

Create and maintain:
`coordination/sessions/M10-C001/CLAUDE_LOG_V01.md`

Record:
- starting branch/HEAD/origin state and owner-change preservation;
- files inspected;
- baseline tests;
- implementation decisions, especially VOID-mask handling and cell-boundary rendering;
- exact fixture validation/count checks;
- failures and fixes;
- final tests;
- final diff review;
- commit/push evidence;
- any deviation from this prompt.

Before ending:
- update `coordination/SESSION_INDEX.md`;
- update `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md` if needed;
- materialize the latest state into `.hiveai/PROJECT_DASHBOARD.md`;
- push safely;
- hand back as `AWAITING_AUDIT`;
- stop. Do not self-audit and do not create `CHATGPT_AUDIT_V01.md`.

## Definition of success

The owner can open `scenes/debug/board_renderer_debug.tscn` in Godot 4.7.1 and choose:

```text
Synthetic Stripes
Real Artwork - Level 007
Real Artwork - Level 010
Real Artwork - Level 013
```

The three real artworks render from the exact owner-supplied logical grids using only their canonical C01..C15 subset, 010's greens appear as C06/C07/C08 blues, BG01 is visible through absent/CLEARED areas, square cell boundaries remain readable, and the plastic/gloss/bevel/shadow/3D-bead look is gone.

No production gameplay semantics are widened, no production difficulty rule is weakened, no per-cell Node architecture is introduced, and M10 owner-QA tasks remain open for the owner's actual review.
