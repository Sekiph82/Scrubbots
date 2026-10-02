# M43-C005-C001 — OWNER VISUAL DECISION V02

Date: 2026-10-02
Authority: OWNER
Status: PARTIAL PASS / PACK-ASSET REMEDIATION REQUIRED

Technical audit:
`coordination/sessions/M43-C005-C001/CHATGPT_AUDIT_V01.md`

## Owner accepted without further visual changes

The following ceremony candidates are accepted as shown in V01:
- Collection Set Complete
- Master Collection Complete
- Robot Unlock
- Gift Meter milestone
- Generic Feature Unlock
- Generic World Transition shell
- Generic small reward ceremony

These remain subject to later production wiring/audit, but their current visual-master direction is owner-approved.

## Standard / Premium Pack direction is NOT accepted

The current pack-opening composition is replaced by this owner direction:

1. Standard and Premium each need a **real closed pack asset**.
2. The pack is shown closed first.
3. The pack then visibly opens through a short dedicated opening animation.
4. Only after the opening completes are the committed card results revealed.
5. The final reveal shows all cards together:
   - Standard: exactly 3 cards.
   - Premium: exactly 5 cards.
6. Card contents remain pre-committed and never reroll during animation.
7. Standard and Premium must have visually distinct pack identities but remain in the same SCRUBBOTS product family.

## Required new art

ChatGPT visual production will create owner-review candidates for:
- Standard Pack closed asset.
- Standard Pack opening animation asset set.
- Premium Pack closed asset.
- Premium Pack opening animation asset set.
- Booster-of-your-choice icon.

Opening sets must be frame-coherent and registration-safe for Godot animation. No runtime image-generation dependency.

## Collection card cleanup

The 135 production Collection card crops must be cleaned/re-exported from the original owner source sheets under:
`assets/art/references/_owner_inbox/Collection Cards/`

Requirements:
- preserve original artwork/text/rarity;
- remove neighbouring-card slivers / sheet-edge contamination;
- uniform crop dimensions/aspect across all 135 cards;
- no generative redraw of card contents;
- verify 15 sets × 9 cards and canonical set/card mapping.

## Booster-of-your-choice

The temporary native question-mark chip is not the desired production asset.

Create a dedicated SCRUBBOTS-family icon meaning “choose one booster”, with no baked text and no implication that a random booster is being granted.

## Gate

SB-M43-076 remains open.

Production ceremony implementation remains blocked until:
- new pack/animation assets are owner-approved;
- collection cards are cleaned and audited;
- booster-of-choice icon is owner-approved;
- pack preview masters are rebuilt with the approved assets.
