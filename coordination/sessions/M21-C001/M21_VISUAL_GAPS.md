# M21-C001 — Real-Art Visual Gaps (V01)

Cycle `M21-C001` V01. This records only REAL remaining visual gaps observed
after the first real-art vertical slice. It pre-authorizes no asset generation
and starts no M22/M27 work.

## Present in V01 (real)

- Real owner-approved 20×20 "Hazard Bot" artwork renders through the real
  single-`Image`/`ImageTexture` `BoardRenderer` over owner-locked BG01
  (`#202533`).
- ACTIVE cells show their exact source palette color; CLEARED cells become
  alpha 0 so BG01 shows through. This is directly visible in the headless
  evidence composite `M21_REFERENCE_COMPOSITE.png` (initial → mid → final).

## Gaps (NOT addressed here, by scope)

1. **Scrubbot character art.** The moving Scrubbot uses the existing M18 debug
   agent marker (`ScrubbotAgent._draw`), not final owner-approved character
   art. Final Scrubbot visuals are future work (owner asset + a later
   milestone), not authorized in this cycle.
2. **Production slot / HUD UI.** The debug scene is a developer harness. It has
   no production slot panel, color-selection UI, boosters, counters, or
   speech-bubble composition (that is M22+ Master UI work, out of scope here).
3. **Touch controls / input.** No production touch input; the debug scene uses
   a manual keyboard/step trigger only (M24, out of scope).
4. **Win/lose, rewards, economy, progression, save.** None present; explicitly
   out of scope (M25+).
5. **Movement/clear VFX & animation polish.** No final clearing VFX, particles,
   or juice; the clear is the exact ACTIVE→CLEARED transparency transition only.
6. **Device/mobile rendering proof.** Only a headless evidence composite exists.
   It is NOT a real-device screenshot or a mobile FPS/GPU claim (AL-003). Real
   on-device visual/perf review remains future owner/manual QA.

## Explicitly NOT done (guardrails)

- No Magnific / AI artwork generation occurred or is pre-authorized here.
- No manual owner visual approval is claimed for this cycle. The debug scene
  `scenes/debug/m21_real_art_vertical_slice.tscn` remains available for later
  owner/manual visual review after this handoff.
