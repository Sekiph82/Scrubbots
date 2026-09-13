# M21-C001 V07 — Owner Manual Gate PASS

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Cycle: `M21-C001`
State under owner test: accepted V07 production candidate `d704e2c12d67da428a9a5bd28e645ea430eb1d34` plus later ChatGPT coordination/tracker commits only

## Owner result

**OWNER_MANUAL_PASS**

The owner manually ran:

`scenes/debug/m21_real_art_vertical_slice.tscn`

with **F6** in Godot after the V07 implementation-stage audit and explicitly reported that all requested runtime checks were correct.

The accepted owner observations are:

1. Visible color-slot click is the gameplay activation path.
2. SPACE no longer causes gameplay dispatch.
3. The Scrubbot starts from the clicked visible slot origin.
4. On a fresh Hazard Bot, clicking C08 reaches the intended bottom-left-first target behavior.
5. The Scrubbot visibly uses outside-board routing rather than tunnelling through ACTIVE artwork.
6. Clearing behavior is correct at arrival.
7. Subsequent C08 behavior advances correctly from the bottom-left ordering basis.
8. The owner reported: **“hepsi ok.”**

The owner also supplied a Godot runtime screenshot from the successful playtest in the ChatGPT conversation. That screenshot is conversation evidence, not a repository production asset, and is not copied into the repository.

## Closure consequence

This owner gate is now satisfied for the accepted V07 candidate.

V08 remains required only as the already-authored **production-immutable technical adversarial validation** stage because V07 changed production routing inside a critical gameplay sprint and ChatGPT cannot independently execute Godot.

Therefore:

- V08 must not change accepted production/source/scene/project files.
- If V08 passes independent audit with production immutable, ChatGPT may perform M21 final closure directly; the owner does **not** need to repeat the same manual playtest again.
- If V08 exposes a production defect, Claude must stop `BLOCKED`. Any later authorized production correction invalidates this gate for the changed behavior and requires a fresh owner playtest after the correction is independently audited.

No M21/M22/UI checkbox is closed by this gate alone; final task closure remains ChatGPT-owned after V08 technical audit.