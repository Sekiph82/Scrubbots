# M43-C005-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-03
Canonical task: SB-M43-076

## References
- [ ] Exact owner Standard reference located by SHA-256 and copied.
- [ ] Exact owner Premium reference located by SHA-256 and copied.
- [ ] Originals were not modified.
- [ ] Old production pack art was not silently substituted.

## Tool/cost governance
- [ ] No paid OpenAI API or third-party paid image generation was used.
- [ ] No unapproved external upload of owner art.
- [ ] If no approved image-edit tool existed, task stopped rather than fabricating poor art.

## Standard
- [ ] Exactly 9 separate 1024×1536 RGBA transparent PNGs.
- [ ] Owner Standard identity is preserved.
- [ ] SCRUBBOTS remains the only pack text.
- [ ] Frames 01–03 remain sealed.
- [ ] Frame 04 first tear ~20–25%.
- [ ] Frame 05 tear ~55–60%.
- [ ] Frame 06 exactly one card edge.
- [ ] Frame 07 exactly one rising card.
- [ ] Frame 08 exactly three emerging card backs.
- [ ] Frame 09 exactly three fully revealed card backs.
- [ ] No card face/rarity/new/duplicate/UI appears.

## Premium
- [ ] Exactly 9 separate 1024×1536 RGBA transparent PNGs.
- [ ] Owner Premium identity is preserved.
- [ ] SCRUBBOTS + PREMIUM remain; no extra text.
- [ ] Frames 01–03 remain sealed.
- [ ] Frame 04 first tear ~20–25%.
- [ ] Frame 05 tear ~55–60%.
- [ ] Frame 06 exactly one card edge.
- [ ] Frame 07 exactly one rising card.
- [ ] Frame 08 exactly five emerging card backs.
- [ ] Frame 09 exactly five fully revealed card backs.
- [ ] No card face/rarity/new/duplicate/UI appears.

## Registration / technical
- [ ] All 18 files are 1024×1536 RGBA.
- [ ] Transparent background is real alpha, not black/white matte.
- [ ] No visible pixel is within 48 px of any edge.
- [ ] Pack center remains registered around x=512.
- [ ] Bottom anchor remains stable around y=1260.
- [ ] No visible camera zoom/jump between consecutive frames.
- [ ] Lower pack identity remains stable across edits.
- [ ] Tear progression is monotonic.
- [ ] Effects/fragments are unclipped.
- [ ] Card backs use one consistent Collection card-back family.
- [ ] Standard and Premium pack identities are visually distinct.

## Files / review
- [ ] Manifest records SHA/dimensions/mode/bounds/margins/registration/card-count role.
- [ ] Standard contact sheet exists.
- [ ] Premium contact sheet exists.
- [ ] Owner review markdown exists.
- [ ] Contact sheets are review-only; runtime candidates remain separate PNGs.
- [ ] CODEX_LOG_V01.md exists.

## Scope
- [ ] root TASKS.md untouched by Codex.
- [ ] final production pack PNGs untouched.
- [ ] no runtime pack animation/UI/service wiring.
- [ ] no Collection-card cleanup in this cycle.
- [ ] no Booster-of-choice work in this cycle.
- [ ] no Legendary Pack.
- [ ] no economy/rarity/purchase changes.
- [ ] no shipping scripts/scenes changed.
- [ ] git diff --check clean.

Technical PASS still requires owner visual acceptance before candidate frames can be promoted/wired.
