# M21-C001 — Owner Gate Result After V06

Date: 2026-09-13
Auditor: ChatGPT
Owner playtester: Şekip

## Result

**OWNER_VISUAL_GATE_FAIL / ENGINEERING_V06_PASS_RETAINED / V07_REQUIRED**

`CHATGPT_AUDIT_V06.md` remains valid as an engineering/validation pass. It explicitly left M21 open for owner visual/game-feel acceptance.

The owner then ran `scenes/debug/m21_real_art_vertical_slice.tscn` in Godot and rejected final M21 closure for two directly observed runtime behaviors:

1. SPACE still dispatches gameplay from synthetic off-board origins rather than a visible slot. Owner decision: remove SPACE dispatch entirely; visible slot clicks become the only owner-facing activation path.
2. Clicking C08 on the fresh Hazard Bot does not choose the true bottom-left C08 cell. The selector's positional comparator is already correct, but production routing does not model a usable exterior walking ring, so the far-left bottom target is not initially targetable from the below-board slot origin. Owner decision: add a one-logical-cell-wide exterior routing corridor around all four board sides.

Canonical owner detail:

`coordination/sessions/M21-C001/OWNER_PLAYTEST_FINDINGS_V07.md`

M21 remains open. No M21/M22/UI checkbox closes from V06 alone. V07 must be implemented, independently audited, and manually replayed by the owner.
