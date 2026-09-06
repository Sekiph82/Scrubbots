# M10-C001 — Owner Manual-QA Runtime Fix: OptionButton API (V07)

Status: **ISSUED — owner manual-QA regression found after V06 AUDITED_PASS**

## Owner-reported runtime error

Godot 4.7.1 throws:

```text
Invalid call. Nonexistent function 'get_item_disabled' in base 'OptionButton'.
```

The failing code is in:
`scripts/debug/board_renderer_debug.gd`

Current line:
```gdscript
if _size_option.selected < 0 or _size_option.get_item_disabled(_size_option.selected):
```

Godot 4.x `OptionButton` uses:
`is_item_disabled(idx)`

not:
`get_item_disabled(idx)`

## Required fix

Replace the invalid API call with the correct Godot 4.x API:

```gdscript
if _size_option.selected < 0 or _size_option.is_item_disabled(_size_option.selected):
```

Keep `set_item_disabled(idx, disabled)` unchanged.

## Regression prevention

Add a focused test/smoke check that actually executes the Real Artwork fixture-change path, not only scene parsing.

The test must prove:
- the scene/script instantiates successfully;
- selecting/changing a Real Artwork fixture executes `_on_fixture_changed()`;
- the Size dropdown validity logic runs without runtime errors;
- too-small sizes remain disabled;
- a valid size is selected/snapped correctly;
- the variable-canvas behavior from V05/V06 remains intact.

Specifically re-check Level 007:
- source 27×24
- 30×30 valid
- 59×59 valid
- no runtime error when the fixture is selected.

Also retain all existing V06 palette checks:
- palette v2 = C01..C16
- C16 Pure Black #000000
- BG01 #202533 outside the logical palette.

## Scope

This is a narrow M10 manual-QA runtime correction.

Do not:
- change artwork JSON grids/dimensions/counts;
- change palette values;
- change difficulty bands;
- change tasks.md checkboxes;
- touch M14+;
- update H!veAI tracker files;
- update PROJECT_DASHBOARD;
- update coordination/SESSION_INDEX;
- self-audit.

## Verification

Run:
- Godot 4.7.1 full headless test suite;
- a debug-scene runtime smoke that processes enough frames to execute the deferred fixture-change path;
- explicit Real Artwork selection/change smoke;
- git diff / git diff --check.

Write:
`coordination/sessions/M10-C001/CLAUDE_LOG_V07.md`

Commit/push safely, hand back `AWAITING_AUDIT`, and stop.
