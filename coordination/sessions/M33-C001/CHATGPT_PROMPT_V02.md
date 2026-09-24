# M33-C001 V02 — Audio Clutter / Cleaning Tail / Music Remediation

Read:
- `coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md`
- `coordination/sessions/M33-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
- current M33 implementation + V01 audit/log.

Implement exactly:
1. Remove production dispatch SFX completely. Keep the asset file preserved.
2. Reuse `assets/audio/sfx/dispatch.wav` as the cleaning sound source.
3. Cleaning sound must be short-bounded and must not audibly continue after the cleaned pixel disappears.
   - Do not use the old long cleaning.wav playback path.
   - Prefer a short transient/cutoff strategy.
   - Do not delay gameplay clear to wait for sound.
4. Keep completion.wav for WON only.
5. Keep movement audio NONE.
6. Reduce/retune cleaning voice concurrency for a cleaner mix.
7. Add a reusable looping background-music controller on the Music bus.
8. Background music should autoplay continuously in normal gameplay and not restart on every dispatch/clear.
9. Do not invent or download a final music asset without owner approval. If no approved track exists, wire the controller/test seam and leave OWNER_MUSIC_SELECTION_REQUIRED in the log.
10. Integrate with the M41 audio/haptics settings slice so Master/Music/SFX/Haptics user settings apply live and persist.

Important technical note:
`authenticated_clear` is emitted after the clear transaction commits. Do not create a long sound that starts post-clear and trails visibly. If a pre-clear presentation seam is added, it must remain observer-only and must not alter clear authority. A short transient at clear is acceptable if it satisfies the owner listening goal.

Tests:
- no sound on assignment_dispatched;
- committed clear uses dispatch.wav source;
- cleaning playback cutoff/tail bound;
- no movement audio;
- completion once per WON attempt;
- Retry cleanup;
- background music loop controller lifecycle;
- Music/SFX bus routing;
- 1x/2x clutter stress;
- root/M31/M30/M33 regressions.

Create `task_logs_v02/` for affected M33 tasks and `CLAUDE_LOG_V02.md`.
Do not edit TASKS.md.

Handoff:
`AWAITING_AUDIT / M33-C001 V02 / OWNER_F6_AND_MUSIC_SELECTION_REQUIRED`