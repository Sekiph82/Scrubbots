# M28-C002-C002 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-28
Auditor: ChatGPT controller
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `004434930ae63b68e98978605796af9814f18511`

## Verdict

**AUDITED_PASS / M28-C002-C002 / STATIC MASTER SHELL / OWNER VISUAL REVIEW REQUIRED**

The six owner-locked gameplay master shells are correctly bound to the real production gameplay screen.

This closes the technical static-shell conversion. Final visual choices and popup/modal dependency rows remain open.

## 1. Exact asset lock

PASS.

Independent source/test inspection confirms:
- six shell ids only;
- each shell has the owner-locked SHA-256;
- focused test calls `FileAccess.get_sha256()` on the committed repo file;
- all six dimensions are asserted as 887×1774;
- historical `scrubbots_gameplay_master.png` remains present.

No substitution/regeneration path was introduced.

## 2. Authoritative shell selection

PASS.

Selection is derived from exactly two runtime facts:
- supply column count 3/4/5;
- active slot capacity 5/6.

`GameplayShellGeometry.shell_id(columns, capacity)` fails closed outside those values.

Focused test proves:
- 3/4/5 × 5 selects the corresponding normal shell;
- 3/4/5 × 6 selects the corresponding +1 Slot shell;
- returning to 5 restores the matching five-slot shell;
- unsupported column count exposes no shell.

## 3. +1 Slot semantics

PASS.

Owner superseding decision is respected: there is no separately drawn sixth slot or connector.

When capacity becomes six:
- shell changes to the matching six-slot master;
- all six live slot overlays bind to the six baked frames;
- baked six connector graphics remain the visual shell;
- runtime sixth-slot authority remains the existing booster/capacity system.

The 5→6→5 focused test runs three cycles for 3/4/5 columns and verifies:
- shell id;
- slot count;
- six overlay rectangles;
- six connector geometry entries;
- supply snapshot unchanged by the visual switch;
- existing first-five slot snapshot unchanged by the shell switch;
- ACTIVE board-cell count unchanged;
- node count stable;
- Retry restores capacity/shell five.

## 4. No duplicate chrome

PASS.

The static shell owns:
- environment;
- visible Railroad;
- board frame;
- five/six slot frames/connectors;
- supply frames;
- profile frame;
- Pause/2x boxes;
- Scrubby/bubble/props.

Runtime overlays suppress duplicate visible chrome:
- `ScrubRailView` remains hidden and is retained only for geometry;
- slot views in shell mode render no empty frame chrome;
- supply rows render live colour/count/state only;
- profile and Pause/2x use flat/live overlay content.

## 5. Board / Railroad / movement alignment

PASS.

Runtime board/routing truth remains independent.

The implementation measures each owner master and keeps a shell-specific geometry table.

BoardPresentation is fitted/scaled so runtime rail/movement geometry lands on the baked visible rail.

Builder measurements accepted:
- rail centreline error <= about 4.9 px;
- agent bottom-rail samples <= about 4.9 px;
- connector samples <= about 6.1 px;
- slot overlays <= about 1.5 px;
- supply overlays <= about 2.1 px.

No routing system was changed.

`BoardRenderer.get_cell_center_global()` was made transform-aware, which is required because the board presentation now has a fractional visual scale. Its no-scale behavior remains equivalent.

## 6. Supply truth

PASS.

Production supply view supports exactly:
- 3 columns;
- 4 columns;
- 5 columns;
- 3 visible rows.

Only front row is interactive.
Preview rows are input-ignored and visually subordinate.

Deeper queue remains hidden.

The owner shell supplies the cell frames; runtime supplies colour/count/front-state and input hitboxes.

## 7. Profile / Pause / 2x / boosters

PASS for current dependency boundary.

Profile overlays only current authoritative presentation data:
- robot portrait;
- Level;
- Bot Parts.

No unsupported XP/title system was invented.

Pause/2x occupy baked top-right boxes.
Timed 2x remains driven by existing entitlement truth and anti-rollback.

Exactly four boosters remain bound.
Ad band is layout-only and does not integrate a real ad provider.

Final Pause / BoosterAcquire / 2x Acquire popup families remain correctly deferred.

## 8. Speech bubble

PASS.

The owner bubble art remains baked in the master.

The obsolete board-tapping instruction is covered by a mask matching the bubble fill.

No replacement tutorial copy was invented.

M44 remains responsible for live/localized tutorial wording.

## 9. Responsive transform

PASS technically.

The shell uses one uniform 887×1774 reference transform.

Focused test measures the actual `GameplayShell` node rect rather than merely trusting a calculated scale.

Required phone/tablet matrix and synthetic notch/gesture insets are covered.

Every tested overlay is compared through the same reference transform.

The current short-phone case exposes one owner UX decision: painted slot/supply cells are about 83 px at 1080×1920, below the project's nominal 88 px touch token. The implementation currently keeps hitboxes exactly on the painted cells. This is an OWNER choice, not silently enlarged.

## 10. Regression

PASS with documented historical baseline.

Builder reports:
- focused C002: 16/16 cases, 79 ok;
- C001 migrated/safety checks PASS;
- M28 smoke: 253 checks / 0 fail;
- M29 migrated origin evidence PASS;
- First 10 owner plans still WON;
- root `tests/run_tests.gd`: 5323 checks, ALL PASS.

The two M21 corridor-model failures are the same previously documented pre-Railroad-V1 baseline and this cycle changes no routing authority.

No new unexplained production SCRIPT ERROR class is evidenced.

## 11. Open owner visual choices

Technical implementation is complete, but these remain visual/UX decisions:

- surround fill on non-1:2 devices;
- exact painted-cell hitbox policy on short phones;
- visibility of reserved AD band before M57;
- native Pause/2x glyph treatment;
- live front/preview/active colour treatment;
- future non-square-board policy.

These are captured in:
`coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md`.

## 12. M28-C002 status

Already complete from C001 + preserved under C002:
- 001..011
- 017

Still open:
- 012 canonical Booster Acquire popup
- 013 canonical 2x Acquire popup
- 014 canonical Pause popup
- 015 modal-stack input suppression
- 016 final owner visual acceptance of static shell presentation
- 018 final popup-open input-suppression portion
- 019 final popup-inclusive owner review pack
- 020 final independent audit + owner playtest acceptance

## Final

`AUDITED_PASS / M28-C002-C002 / STATIC MASTER SHELL / OWNER VISUAL REVIEW REQUIRED`
