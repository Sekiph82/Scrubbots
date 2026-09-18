# OWNER GAMEPLAY BOTTOM ROW SPEED CONTROL DECISION V01

Date: 2026-09-18
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: M28 production gameplay-screen composition

## Decision

The production gameplay bottom row is:

`Pause | Ad placeholder | Speed-up control`

The previously documented Settings control on the bottom-right is superseded.

Required composition:
- Pause remains on the left.
- The center remains an ad-region placeholder only; monetization is still design-gated.
- The bottom-right control is a **speed-up button**, not Settings.
- Settings remains a separate future UI/navigation concern and must not occupy this gameplay-screen position.

## M28 boundary

M28 owns placement, sizing, responsive behavior, safe-area containment and presentation of the speed-up control.

M28 does **not** invent the speed multiplier, timing law, economy, cooldown or other gameplay behavior. Functional speed-control semantics require a later explicit implementation/design contract.

## Precedence

This owner decision supersedes:
- `docs/MASTER_UI_SYSTEM.md` wording that says Settings is on the gameplay bottom-right;
- `SB-M28-024` historical wording;
- M28 V01 prompt/criteria/work-package wording that says Settings is on the right;
- canonical gameplay-reference inventory notes that summarize the older pause/settings composition.

The canonical gameplay reference image remains the layout reference. This decision is an intentional owner override for the missing bottom-right speed-up control.
