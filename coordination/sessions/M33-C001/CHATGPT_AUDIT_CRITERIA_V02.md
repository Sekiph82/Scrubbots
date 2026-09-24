# M33-C001 V02 — Owner Feedback Remediation Audit Criteria

Authority: OWNER_M33_AUDIO_SELECTION_DECISION_V02.md

PASS requires:
1. no production dispatch sound is played;
2. `dispatch.wav` is used as the cleaning source;
3. cleaning playback is short-bounded so no audible tail persists after the pixel disappears;
4. no movement loop exists;
5. completion remains WON-only, once per attempt;
6. concurrency is re-tuned for lower clutter;
7. Retry leaves no stale cleaning/completion tail;
8. real production-stack tests prove the changed wiring;
9. a continuously looping Music-bus background track is supported;
10. if the actual music asset is not yet owner-approved, code may land but final audio closure remains OWNER_MUSIC_SELECTION_REQUIRED;
11. M41 settings slice exposes/persists Master/Music/SFX/Haptics controls;
12. owner F6 re-listening is required before M33 final closure.

Successful code handoff:
`AWAITING_AUDIT / M33-C001 V02 / OWNER_F6_AND_MUSIC_SELECTION_REQUIRED`