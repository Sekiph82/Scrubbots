# OWNER M33 AUDIO SELECTION DECISION V01

Status: OWNER LOCKED  
Date: 2026-09-19  
Scope: M33 Audio canonical SFX selection

## Locked selections

1. Dispatch SFX
   - Canonical file: `assets/audio/sfx/dispatch.wav`
   - Approved source candidate: ElevenLabs Sound Effects v2 `dispatch_03`.

2. Cleaning SFX
   - Canonical file: `assets/audio/sfx/cleaning.wav`
   - Approved source candidate: the previously generated ElevenLabs Sound Effects v2 `movement_loop_01`.
   - Owner explicitly repurposed this sound as the cleaning sound.

3. Completion SFX
   - Canonical file: `assets/audio/sfx/completion.wav`
   - Approved source candidate: ElevenLabs Sound Effects v2 `completion_02`.

4. Movement audio
   - V1 decision: NONE.
   - Do not play a continuous movement loop.

## Canonical export format

- WAV
- mono
- 24 kHz
- 16-bit PCM

## Runtime authority

These are presentation assets only. Audio must not become gameplay authority and must not modify TargetSelector, ReservationState, M23-M30 transaction truth, scheduling, completion, retry, or solver behavior.

M33 still owns bus setup, user volume controls, SFX concurrency management, and persisted settings.
