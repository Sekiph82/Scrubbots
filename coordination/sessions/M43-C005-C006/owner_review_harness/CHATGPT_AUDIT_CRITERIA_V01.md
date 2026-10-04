# M43-C005-C006 — OWNER REVIEW HARNESS AUDIT CRITERIA V01

Canonical task: **SB-M43-064**  
Scope: review-only Godot harness for live OWNER VISUAL PASS.

## Production immutability

- [ ] `standard_pack_ceremony.gd` unchanged from audited V02.
- [ ] `standard_pack_model.gd` unchanged.
- [ ] `reveal_sequencer.gd` unchanged.
- [ ] Standard Pack final opening frames unchanged.
- [ ] canonical Collection card art/catalog unchanged.
- [ ] `project.godot` unchanged by Claude.
- [ ] root `TASKS.md` unchanged by Claude.
- [ ] no SB-M43-065/Premium work.

Any production ceremony modification is an automatic FAIL for this harness pass.

## Review scene

- [ ] `tests/tools/owner_review/standard_pack_owner_review.tscn` exists.
- [ ] F6 can run the scene directly.
- [ ] scene instantiates the real shipping `StandardPackCeremony`.
- [ ] real `ModalStack` is used.
- [ ] no copied/reimplemented pack-opening state machine exists in harness.
- [ ] default fixture is mixed NEW / DUPLICATE / NEW.
- [ ] ceremony opens in IDLE with pack waiting.
- [ ] no automatic Tap 1.
- [ ] no automatic Tap 2.
- [ ] actual owner mouse/touch input reaches shipping ceremony.

## Review controls

- [ ] R restarts current FULL/Reduced fixture from IDLE.
- [ ] E toggles FULL/Reduced and restarts.
- [ ] 1 selects mixed fixture.
- [ ] 2 selects all-new fixture.
- [ ] 3 selects repeated-duplicate fixture.
- [ ] review controls live only in harness.
- [ ] no visible debug UI covers the ceremony while running.

## Authority safety

- [ ] no pack-open authority.
- [ ] no reward grant.
- [ ] no Collection mutation.
- [ ] no Cards Exchange mutation.
- [ ] no save.
- [ ] no campaign navigation/progression mutation.
- [ ] no project startup/main-scene change.

## Owner instructions

- [ ] `OWNER_REVIEW_INSTRUCTIONS_V01.md` exists.
- [ ] exact Windows project path is included.
- [ ] exact review scene path is included.
- [ ] F6 steps are explicit.
- [ ] two owner clicks are explained.
- [ ] R / E / 1 / 2 / 3 controls are explained.
- [ ] document states this is the exact shipping V02 ceremony wrapped in review-only tooling.
- [ ] document states no F5/gameplay wiring is required.

## Validation

- [ ] dedicated harness smoke test PASS.
- [ ] existing SB-M43-064 V02 focused suite PASS.
- [ ] SB-M43-063 RevealSequencer suite PASS.
- [ ] production-file hash guard PASS.
- [ ] static authority guard PASS.
- [ ] no-auto-input guard PASS.
- [ ] `git diff --check` clean.
- [ ] Claude manually confirms F6 / click 1 / click 2 / R / E / fixtures work.
- [ ] no runtime/script errors in manual review check.

## Handoff

- [ ] `CLAUDE_LOG_V01.md` exists.
- [ ] Desktop checkout sync happened before work.
- [ ] owner-local work preserved.
- [ ] Claude returns `AWAITING_GPT_M43_C005_C006_OWNER_REVIEW_HARNESS_AUDIT`.

Passing this harness audit does **not** close SB-M43-064. It only returns the task to the owner for live visual approval.
