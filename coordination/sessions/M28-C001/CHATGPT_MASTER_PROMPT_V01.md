# M28-C001 V01 — MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M28 — Gameplay Screen Layout`
Execution mode: **ONE CONTINUOUS FULL-MILESTONE PASS**
Tasks: `SB-M28-001..028`

Read first:
1. root `TASKS.md` M28 section;
2. `docs/MASTER_UI_SYSTEM.md`;
3. `assets/art/references/inventory.json`;
4. `assets/art/references/README.md`;
5. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
6. `coordination/OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01.md`;
7. M22 final Railroad audit and M23–M27 final audits;
8. `coordination/sessions/M28-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
9. all linked M28 work packages.

## Objective

Build the first real production **responsive gameplay screen layout** around the now-closed M23–M27 gameplay engine.

M28 owns presentation composition and responsive geometry only. M29 owns player touch mechanics.

Canonical composition authority:
- `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png` is the canonical gameplay **layout reference**;
- `docs/MASTER_UI_SYSTEM.md` is the canonical implementation contract;
- production UI must be native/container-driven, not a flattened screenshot.

## Non-negotiable gameplay/input boundary

The old M21/M22 direct clickable slot demo is historical evidence only.

Production batch gameplay:
- player-visible supply has 3/4/5 FIFO columns;
- V1 shows exactly 3 rows per column;
- Row 1 is the future selectable front batch;
- Rows 2/3 are preview only;
- deeper batches are hidden;
- five gameplay batch slots are occupancy/status presentation, NOT player-selected destination controls;
- rightmost-empty placement remains M24 truth;
- M29 will wire actual touch/mouse activation of supply-front rows.

M28 must not revive `ColorSelectionPanel.slot_activated(slot_id)` as production gameplay input.

## Production scene

Create a dedicated production gameplay scene, preferably:
- `scenes/gameplay/gameplay_screen.tscn`
- controller under `scripts/ui/`.

Do not rename/overwrite historical M21/M22 demo scenes.

Recommended composition:

```
GameplayScreen (Control)
└── SafeAreaRoot
    └── ScreenContent
        ├── TopRegion
        ├── BoardRegion
        │   └── BoardPresentation
        │       ├── BoardRenderer
        │       ├── ScrubRailView
        │       └── AgentLayer
        ├── BatchRegion
        │   ├── ScrubbyDecorationAnchor
        │   │   └── ScrubbySpeechAnchor
        │   ├── FiveSlotStrip      # read-only presentation
        │   ├── BatchSupplyPanel   # 3/4/5 columns, V1 3 visible rows
        │   └── CleaningPropsAnchor
        ├── BoosterRow             # 4 compact controls
        └── BottomActionRow        # pause | ad placeholder | speed-up
```

Exact container nesting may vary if evidence proves the same contract.

## Board dominance / Railroad

Board is the largest gameplay element.

Preserve:
- BoardRenderer single-image architecture;
- board aspect ratio exactly;
- rectangular boards remain rectangular;
- ScrubRailView consumes canonical ScrubRailGeometry;
- exactly 2 logical-cell art-to-rail clearance;
- 1 logical-cell rail width;
- slot-to-bottom-rail geometry remains representable;
- no per-cell Control/Node architecture.

Responsive scaling may change physical pixels, never logical routing geometry.

## Responsive modes

Reference viewport remains 1080×2160.

Required matrix:
- 1080×2160;
- 1170×2532;
- 1290×2796;
- 1080×2400;
- 1440×3200;
- one shorter 16:9 portrait fixture;
- one tablet portrait fixture.

Use existing `ResponsiveLayout` COMPACT/NORMAL/TALL contract.

Validate representative board envelopes:
- small/easy-layout fixture;
- medium-layout fixture;
- hard-layout fixture;
- very-large/59×59 fixture;
- at least two non-square rectangular boards.

These are layout fixtures only. Do not make board dimension a new Difficulty V1 authority.

## Safe area

Every production screen must use `SafeAreaRoot`.

If existing `safe_area_root.gd` needs a narrow test seam for synthetic safe rectangles, add it without making safe-area data gameplay truth.

Essential controls must remain within safe bounds.

## Five-slot strip

Create a production **read-only batch-slot view**. Do not use Button semantics for destination slot selection.

It must show exactly five positions and be able to render scalar snapshots:
- EMPTY;
- batch color;
- remaining;
- committed/in-flight;
- ACTIVE/WAITING.

UI stores detached scalar snapshots only. No mutable M24 references.

## Batch supply panel

Create presentation components for:
- 3/4/5 columns;
- exactly 3 visible rows in V1;
- front row visually distinct;
- preview rows visibly secondary;
- hidden queue depth never rendered;
- empty/end-of-column state clean;
- scalar/detached M23 snapshot input only.

Do not wire activation to M23 in M28. That is M29.

## HUD / composition

Owner-approved M28 composition:
- remove Goal/Moves panel;
- no Level/lock rail;
- board dominant;
- protected supply/slot region;
- Scrubby anchor low-left;
- speech bubble above Scrubby, not full-width;
- cleaning props at right, lower priority;
- 4 boosters in one compact horizontal row;
- bottom row: pause left, ad placeholder center, speed-up control right.

Ad area is presentation placeholder only. M57 monetization remains design-gated.

## Illustration/asset rule

Canonical gameplay screenshot is a reference, not production art.

Do NOT:
- use the full screenshot as a production background;
- crop Scrubby/props/icons from the reference and promote them;
- generate replacement art automatically;
- label owner references as approved production assets.

Bind only assets explicitly marked production `APPROVED` / owner-original for that role.

Current inventory contains no explicitly APPROVED gameplay illustration. Therefore M28 may use native neutral presentation anchors/placeholders for Scrubby/cleaning decoration. Closure for SB-M28-026 means:
- every illustration actually bound is explicitly approved;
- zero unapproved reference art is promoted;
- optional illustration anchors are production-ready for later approved assets.

Do not spend image-generation credits in M28.

## Board coordinate mapping

After responsive layout, prove independent round-trip mapping:
- logical board cell center -> screen/global -> board local;
- visible board rectangle -> logical cells;
- slot/supply geometry does not alter BoardRenderer mapping.

Test at required viewport matrix and rectangular boards.

M28 does not activate gameplay through these coordinates; it only proves layout/mapping correctness.

## Evidence

Create deterministic viewport evidence under:
`coordination/sessions/M28-C001/evidence/`

At minimum:
- JSON/Markdown metrics for every required viewport;
- rendered PNG viewport captures generated by Godot/SubViewport when technically possible;
- board rect/aspect metrics;
- safe-area rect;
- supply/slot min sizes;
- booster/bottom-row rects;
- coordinate round-trip error;
- reference-audit record explaining what was adopted conceptually and what was intentionally not copied/bound.

Generated screenshots are test artifacts, not AI-generated art.

## Continuous execution

Execute all five work packages without approval stops:
1. `M28_WORK_PACKAGE_01_REFERENCE_AUDIT_AND_LAYOUT_CONTRACT.md`
2. `M28_WORK_PACKAGE_02_PRODUCTION_SCREEN_AND_RESPONSIVE_BOARD.md`
3. `M28_WORK_PACKAGE_03_BATCH_SLOTS_AND_SUPPLY_PRESENTATION.md`
4. `M28_WORK_PACKAGE_04_LOWER_HUD_DECORATION_AND_ASSET_GATE.md`
5. `M28_WORK_PACKAGE_05_VIEWPORT_MAPPING_EVIDENCE_AND_CLOSURE.md`

Fix implementation/test failures and continue automatically.

## Scope prohibitions

- Do not modify root `TASKS.md`.
- Do not implement M29 touch activation.
- Do not make five slots clickable destination controls.
- Do not implement booster mechanics.
- Do not enable ads/monetization.
- Do not implement M30+ progression/win/economy.
- Do not change M23–M27 gameplay truth.
- Do not generate AI images.
- Do not overwrite owner reference images.

## Final handoff

After all M28 implementation/evidence passes:
1. push implementation commit(s);
2. create `coordination/sessions/M28-C001/CLAUDE_LOG_V01.md` as a separate final commit;
3. map every `SB-M28-001..028` to code + direct evidence;
4. report start SHA, implementation SHAs, changed files, viewport evidence paths and test totals;
5. explicitly confirm no reference screenshot was used as flattened production UI and no unapproved illustration was promoted;
6. confirm root TASKS changed = NO, M29 input = NO, image credits = 0;
7. return only `AWAITING_AUDIT`, final implementation SHA and direct log URL.
