# M49 Responsive UI — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`** (fresh-context Claude subagent, read-only, 2026-10-15). Not a ChatGPT independent audit.

- Reviewed: `tests/m49_responsive_matrix.gd` @ `b530f8ba`, plan + builder log, CI runs 38744551437 / 38746625415 (artifacts read in memory).
- Findings are condensed; builder dispositions are marked **[builder]**.

## Verdict (reviewer)
- Passing scope (m01–m05, m07, m08): **PASS_WITH_CONCERNS**. The assertions are real and reproduce from both artifacts.
- m06 / row 009: **CHANGES_REQUIRED** (weakened assertions).

| # | Check | Result |
|---|---|---|
| 1a | Logical mapping (canvas_items / expand, 1080×2160) | PASS. The 8 devices give 6 distinct canvases. |
| 1b | Notch insets applied to Home / gameplay / modal stack | PASS |
| 1c | m04 touch mapping (emulated-mouse + touch order, one activation per correct column) | PASS for logical coordinates. The window stretch transform is not exercised. |
| 2 | m06 diagnosis (standalone screen 0×0) | Correct; the fix is likely to pass. |
| 2b | m06 assertions | FAIL (weakened), see D1 / D2 |
| 3 | Production defects | None near limits (m08 CTA 816×112) |
| 4 | Workflow guards | PASS (stale comment noted) |

## Defects → builder disposition
- **D1 MEDIUM.**
  - Finding: the m06 aspect is tautological (`get_board_rect` = w×h × cell).
  - **[builder]** Fixed: m06 now measures the DRAWN rect (renderer size × presentation scale at the presentation origin).
- **D2 MEDIUM.**
  - Finding: rail / region containment was demoted to print-only.
  - **[builder]** Fixed: hard assertions again (inside rail AND BoardRegion AND viewport, plus clear of slots / supply).
  - Run [38748970964](https://github.com/Sekiph82/Scrubbots/actions/runs/38748970964) (the M50 planned run, which executed the fixture fix `b530f8ba`) already printed `in_rail=true in_region=true` for all 6 boards.
- **D3 LOW.**
  - Finding: the m08 journey check can pass while hidden.
  - **[builder]** Visibility is now printed as a diagnostic; rows 031 / 032 stay PARTIAL until asserted.
- **D4 LOW.**
  - Finding: nav buttons are not held to 88 px; shortcut width, Pause / 2x size and the deep-link return value are not checked.
  - **[builder]** The deep-link return value is now asserted. Nav-button / Pause-2x sizes are not asserted (unverified values); row 020 is narrowed accordingly in the log.
- **D5 LOW.**
  - Finding: production `gameplay_screen.gd` `_build_tree` uses `set_anchors_preset` (fragile for hosts that add it to an already-sized parent).
  - **[builder]** Not changed: no production host is affected (`ProductionGameplayHost._fit_screen` uses `set_anchors_and_offsets_preset`). Recorded.

## NOT_RUN (reviewer)
- The m06 changes before run 38748970964.
- The window-stretch tap path.
- Real-device safe-area conversion.
- 022 / 027, 029, and cloud-conflict 030.
- Device visual sign-off.
