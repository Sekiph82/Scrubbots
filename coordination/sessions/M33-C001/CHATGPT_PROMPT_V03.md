# M33-C001 V03 — Integrate Owner-Approved Gameplay Music Loop

Read:
- `coordination/OWNER_M33_MUSIC_SELECTION_DECISION_V03.md`
- `coordination/sessions/M33-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
- `coordination/sessions/M33-C001/CHATGPT_AUDIT_V02.md`
- current `scripts/audio/music_controller.gd`
- current M41 settings implementation

The owner selected:
**Pixel Polish Parade** for gameplay.

The final prepared OGG is supplied externally by ChatGPT/user and must be placed at:

`assets/audio/music/background_loop.ogg`

Expected SHA-256:
`8c94897ea022924bb32c1e8384fd0b73ea21863f522c4d1dd682ca773ef9ae2a`

Expected duration:
`137.153379 s`

## Required work

1. Before modifying code, verify the supplied OGG:
   - path;
   - SHA-256;
   - duration;
   - 44.1 kHz stereo;
   - Godot import/load.

If the hash does not match, STOP:
`BLOCKED / M33 APPROVED MUSIC ASSET HASH MISMATCH`

Do not transcode or regenerate it.

2. Integrate through the existing MusicController only.
Do not create a second music authority/player.

3. Ensure imported OGG loops and automatically plays on normal gameplay entry.

4. Add/extend tests to prove:
   - approved asset exists and loads;
   - exact hash/provenance is preserved;
   - MusicController has track and loop=true;
   - normal session start count == 1;
   - Retry/dispatch/clear/speed do not restart;
   - scene/lifecycle stop works;
   - M41 Music/SFX/Master isolation still works.

5. Preserve V02 audio decisions:
   - dispatch SFX NONE;
   - cleaning = bounded dispatch.wav;
   - completion WON-only;
   - movement NONE.

6. Run all criteria regressions on actual main with zero SCRIPT ERROR.

7. Create:
   `coordination/sessions/M33-C001/task_logs_v03/SB-M33-MUSIC-FINAL.md`
   `coordination/sessions/M33-C001/CLAUDE_LOG_V03.md`

The log must include exact SHA/duration and test outputs.

Do not edit TASKS.md.
Do not self-audit.
Do not implement Reduced Effects.
Do not integrate `ScrubBots Workshop` yet.

Handoff:
`AWAITING_AUDIT / M33-C001 V03 / APPROVED_GAMEPLAY_MUSIC_INTEGRATED / OWNER_F6_REQUIRED`
