# OWNER M33 MUSIC SELECTION DECISION V03

Status: OWNER LOCKED
Date: 2026-09-25
Supersedes: the unresolved music-asset portion of `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md`.

## Owner-selected music

### Gameplay background

Selected source:
`Pixel Polish Parade(1).mp3`

Owner decision:
**APPROVED FOR SCRUBBOTS GAMEPLAY BACKGROUND MUSIC**

Intended use:
- normal gameplay;
- continuous Music-bus playback;
- presentation-only;
- no restart on dispatch, cleaning, Retry or speed changes.

Production preparation still required:
- derive a genuinely seamless loop from the approved source;
- export the final runtime asset as:
  `assets/audio/music/background_loop.ogg`;
- preserve the original selected source/provenance separately;
- do not simply transcode an audible outro/silence into a looping OGG.

Final gameplay music remains subject to owner F6 listening after the seamless runtime asset is integrated.

### Workshop music

Selected source:
`ScrubBots Workshop(1).mp3`

Owner decision:
**APPROVED / RESERVED FOR THE FUTURE SCRUBBOTS WORKSHOP SCREEN**

This track is NOT the M33 gameplay loop and must not replace `Pixel Polish Parade` in gameplay.

Workshop integration is deferred until a Workshop UI/screen milestone explicitly exists. Preserve this selection as owner-approved future content; do not silently repurpose it elsewhere.

## Rejected ambiguity

The two selected tracks have distinct roles:
- Gameplay = `Pixel Polish Parade`
- Workshop = `ScrubBots Workshop`

Do not swap the roles without a later owner decision.

## Remaining M33 owner gate

After `background_loop.ogg` is prepared and integrated:
1. run `res://scenes/debug/m33_audio_playtest.tscn`;
2. owner verifies music level, cleaning-SFX coexistence, loop seam and Settings behavior;
3. owner gives final F6 acceptance.

Until then:
`OWNER_MUSIC_SOURCE_SELECTED / SEAMLESS_LOOP_PREPARATION_REQUIRED / OWNER_F6_REQUIRED`
