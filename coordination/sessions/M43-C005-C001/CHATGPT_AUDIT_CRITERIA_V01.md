# M43-C005-C001 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-02
Primary roadmap row: SB-M43-076
Purpose: ceremony visual-master candidate gate before production implementation

## Governance
- [ ] root TASKS.md untouched by Claude.
- [ ] no production route/action added.
- [ ] preview harness is isolated and non-shipping.
- [ ] no authoritative grant/open/unlock/claim action is called by the visual harness.
- [ ] no economy/progression/save mutation from visual preview.

## Asset inventory
- [ ] CEREMONY_ASSET_INVENTORY_V01.md exists.
- [ ] every required ceremony lists exact existing asset paths.
- [ ] missing art is explicitly recorded rather than fabricated.
- [ ] existing final/owner-approved art is reused.
- [ ] no existing final art regenerated/overwritten.

## Standard Pack
- [ ] exactly 3 card slots.
- [ ] real Standard Pack art.
- [ ] rarity visible.
- [ ] NEW/DUPLICATE visible.
- [ ] no reroll/jackpot/near-miss language.

## Premium Pack
- [ ] exactly 5 card slots.
- [ ] real Premium Pack art.
- [ ] at least one Rare-or-better sample fixture.
- [ ] rarity visible.
- [ ] NEW/DUPLICATE visible.
- [ ] no reroll CTA.

## Collection ceremonies
- [ ] Set Complete uses a real configured set fixture.
- [ ] exact set SB/Bot Part reward shown.
- [ ] Master Collection shows exactly +2500 SB +20 Bot Parts.
- [ ] completion presentation does not imply reward authority moved into UI.

## Robot Unlock
- [ ] canonical robot asset/identity used.
- [ ] canonical role/personality shown.
- [ ] canonical 20% perk truth shown.
- [ ] remaining Bot Parts shown.
- [ ] EQUIP + KEEP CURRENT/CONTINUE candidate actions shown.
- [ ] no unlock/equip mutation from preview.

## Gift Meter
- [ ] small milestone fixture uses exact config reward.
- [ ] 1000 milestone uses exact config reward.
- [ ] no invented threshold/reward.

## Feature unlock
- [ ] generic feature shell exists.
- [ ] no hardcoded campaign unlock level.
- [ ] no reward implied unless fixture explicitly includes one.

## World unlock shell
- [ ] generic reusable shell exists.
- [ ] no hardcoded world level range.
- [ ] no invented World 02 name/id.
- [ ] no fabricated future world artwork.
- [ ] any World 01 art use is clearly preview-harness/shell-test only.

## Generic reward
- [ ] compact reusable candidate exists.
- [ ] supports 1–4 live reward rows.
- [ ] suitable visual hierarchy for Daily/Tasks 3/3 later.
- [ ] no grant behavior implemented.

## Responsive / Reduced Effects / lifecycle
- [ ] shared visual family proven at 1080x1920, 1080x2160, 1170x2532, 1290x2796, 1536x2048.
- [ ] Standard/Premium/Robot/Set/Master/Gift1000 each have 1080x2160 evidence.
- [ ] Premium Reduced Effects evidence exists.
- [ ] Robot Reduced Effects evidence exists.
- [ ] no clipping/unsafe touch targets in the candidate layouts.
- [ ] repeated preview open/close has stable nodes/timers/signals.

## Tests / regression
- [ ] focused visual-master suite passes.
- [ ] authoritative M39 economy/collection/robot truth tests remain pass.
- [ ] M43 relevant regressions pass if shared helpers touched.
- [ ] root suite passes.
- [ ] git diff --check clean.

## Owner gate
- [ ] OWNER_VISUAL_REVIEW_V01.md asks concrete grouped decisions.
- [ ] candidates are not marked MASTER_OWNER_APPROVED by Claude.
- [ ] production implementation remains blocked until owner visual decision.

Technical PASS of this gate does not close SB-M43-076 until owner visually approves the candidate family.
