# M52-C001 OWNER PLAYTEST FINDINGS V01

Date: 2026-09-26
Authority: OWNER
Status: OWNER PLAYTEST PAUSED / REMEDIATION REQUIRED
Repository: Sekiph82/Scrubbots

## Confirmed

- Level 1 remains playable.
- Progression reached Level 2 Apple correctly.
- Level 2 launches and is playable.

## Owner-observed blockers

1. Intermittent short gameplay freezes/stutters during Level 2.
2. Pressing the gameplay 2x control does not visibly accelerate play.
3. Same-color occupied batches are effectively serialized. Example: when five separate BLUE batches of 30 are placed into the five slots, Scrubbots from later BLUE batches do not begin working while the earliest BLUE batch still has dispatch capacity. The owner requires all five occupied batches to be able to contribute simultaneously.
4. Batch visible count must reduce when a Scrubby successfully leaves/commits from that slot onto the gameplay route, not only after the target pixel has been cleared.

## Playtest decision

The First 10 owner gate is **NOT PASS / PAUSED** at Level 2 until the runtime feel is corrected.

Do not continue M53/M54 and do not require the owner to test Levels 3–10 yet.

After remediation + independent audit, restart the owner test from Level 2 and then continue through Level 10 / frontier 11.

## Important distinction

Final Gameplay V02 art/layout polish remains a later presentation task. These findings concern core runtime behavior, speed interaction and frame smoothness.
