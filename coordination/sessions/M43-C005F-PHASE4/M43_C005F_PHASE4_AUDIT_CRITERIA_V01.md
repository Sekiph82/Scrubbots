# M43-C005F-PHASE4 — Gameplay→Results + Home State-Change Micro Feel — STRICT AUDIT CRITERIA V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`

## Verdict

PASS requires F010 and F012 to remain presentation-only, non-blocking, idempotent and isolated from Remote Content/R2 semantics.

## G0 — Desktop safety

- Desktop exact origin/main before implementation.
- owner-local files preserved.
- no destructive checkout/restore/reset/clean on Desktop.
- TEMP uses explicit absolute paths only.
- final Desktop exact origin/main, 0/0.
- owner project.godot hash unchanged.

Any Desktop mutation = FAIL.

## A — adapter boundary

- FeedbackAdapter only plugin gateway.
- no forbidden GFF/Spark direct calls.
- no camera/flash/freeze/time-scale/physics/global clear.
- Reduced = zero plugin work.
- no durable feel state.
- no reward/save/navigation/progression authority in feel code.

## B — F010 terminal bridge

PASS only if:

- terminal authority remains ProductionGameplayHost completion;
- nav.on_gameplay_terminal remains immediate and is never awaited behind decoration;
- at most one SMALL bridge event per terminal attempt;
- no duplicate WIN/confetti competing with F003;
- duplicate terminal/stale signal cannot duplicate bridge;
- plugin absent/throwing still reaches Results exactly once;
- same receipt/save/economy truth as baseline;
- Reduced reaches Results with zero plugin work.

Any delay inserted before terminal navigation = FAIL.

## C — F012 Home micro feel

PASS only if:

- first render = baseline only, zero effect;
- unchanged refresh x10 = zero;
- Heart timer ticks = zero;
- resize/safe-area/modal/hide-show/identical remote refresh = zero;
- real meaningful authoritative delta = one bounded MICRO/SMALL response;
- no generic whole-screen pulse;
- no duplicate celebration of F003-F009 owned events;
- same post-change state re-render = zero;
- Reduced updates static state with zero plugin work;
- snapshot is ephemeral/presentation-only and never saved.

Home effect budget:
- max two serialized MICRO/SMALL events for one state reconciliation;
- ordinary Home update uses no Spark unless strict audit finds a specific justified exception;
- no idle loop/permanent feedback node.

## D — regression / fault safety

Required PASS:

- focused Phase 4
- Phase1
- Phase2
- Phase3
- QA-R01 Standard/Premium
- M30
- M40
- M41
- M42 Home/navigation/safe-area
- M43 Results
- M55
- CP04/CP05
- root ALL PASS
- headless import/boot
- git diff --check

Any first-run failure must be disclosed.

## E — scope isolation

FAIL if implementation changes:

- Remote Content/R2 semantics/config
- LevelData/supply/VOID
- Family APK/export
- Level Factory
- owner-accepted pack/Collection/Gift/Daily/acquisition reward authority
- root TASKS.md by Claude

## F — runtime evidence

Mandatory:
- real WON terminal transition FULL/REDUCED
- real LOST terminal transition
- Home before/after a meaningful progression delta
- repeated same-state Home refresh showing no replay

Final verdict:
- `PASS`
- `PASS / AWAITING OWNER VISUAL ACCEPTANCE` if F012 materially alters approved Home hierarchy
- or `CHANGES_REQUIRED`.
