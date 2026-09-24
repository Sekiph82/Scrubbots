# OWNER M33 AUDIO SELECTION DECISION V02

Status: OWNER LOCKED
Date: 2026-09-24
Supersedes: `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V01.md` where conflicting.

## Owner listening feedback

The M33 V01 owner F6 listening gate did NOT pass as final mix approval.

Owner observations:
- continuous dispatch + cleaning one-shots create excessive audio clutter;
- dispatch SFX should be removed from gameplay;
- cleaning should use the currently approved `dispatch.wav` sonic identity instead;
- cleaning sound must not continue audibly after the cleaned pixel has disappeared;
- the game needs a continuously active background music loop;
- Settings must expose user control for sound/music/vibration.

## Locked V02 decisions

1. Dispatch SFX runtime behavior: **NONE**.
   - Do not play any sound on `assignment_dispatched`.
   - `assets/audio/sfx/dispatch.wav` remains preserved as an approved source asset and is repurposed for cleaning.

2. Cleaning SFX:
   - Source sound: `assets/audio/sfx/dispatch.wav`.
   - Runtime cleaning sound must be short and bounded.
   - It must not audibly trail the visual disappearance of the cleaned pixel.
   - Prefer a short transient/cutoff policy over a long one-shot tail.
   - Do not reintroduce a continuous movement/cleaning loop.

3. Completion SFX:
   - Keep `assets/audio/sfx/completion.wav` unless later owner feedback changes it.

4. Movement audio:
   - NONE in V1.

5. Background music:
   - one continuously active looping background track is required during normal gameplay;
   - music uses the `Music` bus;
   - music must not restart on every minor gameplay event;
   - music must survive normal gameplay state changes cleanly and stop/transition only at explicit scene/app lifecycle boundaries;
   - the exact music asset still requires owner-approved source selection before final audio closure.

6. Settings:
   - user can independently control Master, Music, SFX and Haptics;
   - each can be effectively disabled via zero volume / toggle;
   - values persist across relaunch;
   - settings UI is now owner-authorized earlier than the original M41 schedule for this narrow audio/haptics slice.

## Runtime authority

Audio/haptics remain presentation-only and never become gameplay authority.