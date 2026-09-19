# ScrubBots M33 Canonical SFX

Owner-approved canonical audio assets for M33.

| Gameplay event | Canonical file | Approved source candidate | Runtime intent |
| --- | --- | --- | --- |
| Robot dispatch | `dispatch.wav` | ElevenLabs `dispatch_03` | One-shot when a robot is dispatched |
| Cleaning | `cleaning.wav` | ElevenLabs former `movement_loop_01`, explicitly repurposed by owner | Cleaning action SFX |
| Level completion | `completion.wav` | ElevenLabs `completion_02` | One-shot after terminal WIN settles |
| Robot movement | none | Owner decision | No movement audio in V1 |

## File format

The checked-in canonical exports are WAV, mono, 24 kHz, 16-bit PCM.

## Integration constraints

- Do not add a continuous movement sound in V1.
- Dispatch and completion are one-shot events.
- Cleaning may occur at high density, so M33 concurrency management must prevent audio spam/clipping without changing gameplay truth.
- Audio presentation must never drive or alter M23-M30 gameplay state.
