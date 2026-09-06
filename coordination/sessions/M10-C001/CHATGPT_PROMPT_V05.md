# M10-C001 — Variable Real-Artwork Canvas + Coordination Ownership Normalization (V05)

Status: **ISSUED — supersedes V03 and V04 before implementation**

This single prompt combines:
1. the owner's corrected BoardRenderer Real Artwork canvas behavior; and
2. the owner's new coordination ownership rule that ChatGPT, not Claude, owns H!veAI tracker/dashboard updates after audit.

META-C005 V01 has already been independently audited **AUDITED_PASS**. Do not redo it.

## First action

Work in:
`C:\Users\sekip\Desktop\ScrubBots`

Safely sync local `main` with `origin/main` while preserving all owner changes.

Never use:
- `reset --hard`
- `clean -fd`
- destructive restore/checkout
- force push

Read:
- `CLAUDE.md`
- `tasks.md`
- `coordination/README.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M10-C001/CHATGPT_AUDIT_V02.md`
- `coordination/sessions/M10-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
- `docs/08_PIXEL_ART_PALETTE_RULES.md`
- `data/palettes/scrubbots_palette_v1.json`
- `scripts/debug/board_renderer_debug.gd`
- `scripts/debug/board_debug_fixtures.gd`
- `scripts/debug/board_grid_overlay.gd`
- the three JSON fixtures under `data/debug/board_renderer_fixtures/`
- `level_factory/CLAUDE.md`
- `content_pipeline/CLAUDE.md`

---

# PART A — Correct Real Artwork canvas behavior

## Owner clarification

The Real Artwork JSON dimensions are the immutable **source artwork bounding matrices**.

They are NOT the final BoardRenderer canvas size.

The currently selected Size option in the BoardRenderer Debug UI is the **debug canvas**.

The same source artwork must render completely at every selected canvas size that is large enough to contain the source matrix.

### Core rule

For source size `source_w × source_h` and selected debug canvas `canvas_w × canvas_h`:

The selection is valid only if:

```text
canvas_w >= source_w
canvas_h >= source_h
```

Place the unchanged source matrix centered inside the selected canvas:

```text
offset_x = floor((canvas_w - source_w) / 2)
offset_y = floor((canvas_h - source_h) / 2)
```

Everything outside the source matrix is debug-only VOID.

Source VOID remains VOID.

Do NOT:
- scale
- resample
- stretch
- crop
- repaint
- regenerate
- change source JSON arrays

Every source square remains exactly one logical cell.

## Source fixture invariants

### Level 007
- source matrix = 27×24 = 648 source slots
- artwork cells = 542
- source VOID = 106
- palette subset = C04/C10/C14/C15

Examples:
- 30×30 canvas -> offset (1,3)
- 59×59 canvas -> offset (16,17)

At BOTH sizes:
- artwork cells must remain exactly 542
- all 542 must be visible

Debug VOID:
- 30×30 -> 900 - 542 = 358
- 59×59 -> 3481 - 542 = 2939

### Level 010
- source matrix = 49×50
- artwork cells = 2450
- source VOID = 0
- palette subset = C01/C02/C03/C06/C07/C08/C14/C15

Examples:
- 50×50 canvas -> offset (0,0)
- 59×59 canvas -> offset (5,4)

Artwork count always remains 2450.

### Level 013
- source matrix = 28×31
- artwork cells = 375
- source VOID = 493
- palette subset = C02/C03/C09/C14/C15

Examples:
- 39×39 canvas -> offset (5,4)
- 59×59 canvas -> offset (15,14)

Artwork count always remains 375.

## Size dropdown behavior

For Real Artwork:
- keep the Size dropdown enabled;
- dynamically determine which size options can fully contain the selected fixture;
- invalid options must never crop the source;
- prefer disabling invalid options;
- if per-item disabling is impractical, reject invalid selections cleanly and move to the smallest valid option;
- switching fixtures must recompute valid choices;
- switching valid canvas sizes must rebuild the padded debug board while preserving the source matrix exactly.

Synthetic Stripes behavior must remain unchanged.

## Debug adapter architecture

Refactor the debug fixture path so there is a clean separation between:

1. immutable source fixture data loaded from JSON; and
2. a debug-only embedding step that places the source matrix into a selected canvas using VOID padding.

A helper concept such as:

```text
embed_real_fixture_in_canvas(source_fixture, canvas_w, canvas_h)
```

is preferred, but naming is implementation choice.

Do not add a production `BoardState.VOID` state.

## Rendering rules

Preserve the owner-locked visual contract:

- BG01 Midnight Slate = `#202533`
- logical artwork colors = canonical C01..C15 only
- ACTIVE = opaque canonical source color
- CLEARED = alpha 0
- VOID = debug-only absence
- source VOID + padding VOID never become ACTIVE
- square-cell separation remains visible
- flat solid cell fills
- no gloss
- no highlight
- no bevel
- no drop shadow
- no 3D/plastic bead appearance
- no interpolation
- no per-cell Nodes

Changing 30×30 -> 59×59 changes display cell size only. It must never change the logical artwork.

## Debug info

For Real Artwork show:
- fixture name
- source matrix dimensions
- selected canvas dimensions
- centered offset
- artwork cell count
- total debug VOID count
- palette subset
- BG01
- cell size
- state pattern

Example:

```text
Real Artwork - Level 007 — source=27x24 — canvas=30x30 — offset=(1,3) — artwork=542 — void=358
```

---

# PART B — Normalize Claude / ChatGPT coordination ownership

The owner has changed the workflow.

## New locked ownership rule

Claude's responsibility ends with:

1. implementation;
2. tests/verification;
3. the matching `CLAUDE_LOG_VNN.md`;
4. safe commit/push;
5. handoff as `AWAITING_AUDIT`;
6. stop.

Claude must NOT update:
- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/SESSION_INDEX.md`

ChatGPT owns those files after independent audit.

Claude must never create or modify:
- `CHATGPT_AUDIT_VNN.md`
- audit verdicts
- post-audit tracker closure

## Governance files to normalize

Update only the coordination-ownership wording in:

- `CLAUDE.md`
- `coordination/README.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `level_factory/CLAUDE.md`
- `content_pipeline/CLAUDE.md`

Remove/supersede instructions that tell Claude to update H!veAI trackers, PROJECT_DASHBOARD, or SESSION_INDEX.

Make the new ownership explicit:

```text
Claude: implement + test + CLAUDE_LOG + push + AWAITING_AUDIT + stop.
ChatGPT: independent audit + audit file + SESSION_INDEX/H!veAI tracker/dashboard updates.
```

Do not alter unrelated governance rules.

## tasks.md rule

For this V05:
- do not change `tasks.md`;
- do not mark SB-M10-005..011 complete;
- do not open M14+;
- no new SB task IDs.

---

# Tests / verification

At minimum verify:

1. source JSON matrices remain unchanged:
   - 007 = 27×24
   - 010 = 49×50
   - 013 = 28×31
2. Real Artwork Size dropdown remains usable.
3. Invalid too-small canvases cannot crop.
4. 007 fully renders at 30×30 and 59×59.
5. 007 offsets exactly (1,3) and (16,17).
6. 007 artwork count remains 542 at both sizes.
7. 007 debug VOID = 358 at 30×30 and 2939 at 59×59.
8. 010 fully renders at 50×50 and 59×59.
9. 010 offsets exactly (0,0) and (5,4).
10. 010 artwork count remains 2450.
11. 013 fully renders at 39×39 and 59×59.
12. 013 offsets exactly (5,4) and (15,14).
13. 013 artwork count remains 375.
14. source VOID remains VOID.
15. padding VOID remains VOID.
16. ALL_ACTIVE activates only artwork cells.
17. ALL_CLEARED activates none.
18. CHECKER never activates source/padding VOID.
19. color counts remain invariant across valid canvas sizes.
20. BG01 stays exactly #202533.
21. no per-cell Node architecture.
22. flat-cell/no-bead/no-interpolation contract remains intact.
23. Synthetic Stripes remains unchanged.
24. full Godot 4.7.1 headless suite passes.
25. debug scene headless boot succeeds.
26. governance scan proves Claude is no longer instructed to update H!veAI trackers/dashboard/SESSION_INDEX in the normalized files.
27. `tasks.md` unchanged.
28. inspect `git diff` and `git diff --check`.

## Coordination output

Write only:

`coordination/sessions/M10-C001/CLAUDE_LOG_V05.md`

Do NOT update any H!veAI files.
Do NOT update PROJECT_DASHBOARD.
Do NOT update SESSION_INDEX.
Do NOT create an audit file.

Commit and push safely.

End with:
`AWAITING_AUDIT`

Then stop.
