# M33 + M41 EARLY SETTINGS BATCH — Audio Revision & Settings Integration

Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Execution order

1. M33-C001 V02
2. M41-C001 V01

Proceed without waiting between the two cycles.

Do not edit root `TASKS.md`.
Do not self-audit.
Do not start unrelated M41+ scope.

## M33-C001 V02

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M33-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M33-C001/CHATGPT_AUDIT_CRITERIA_V02.md

Owner decision:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/OWNER_M33_AUDIO_SELECTION_DECISION_V02.md

Required owner-locked behavior:
- no dispatch SFX;
- `dispatch.wav` becomes the cleaning sonic source;
- cleaning sound is short-bounded with no audible tail after the pixel disappears;
- completion.wav remains WON-only;
- no movement audio;
- lower cleaning concurrency/clutter;
- looping Music-bus background controller;
- do not invent/download a final music track without owner approval.

If no approved music asset exists, implement the controller/seam and record:
`OWNER_MUSIC_SELECTION_REQUIRED`.

Create M33 `task_logs_v02/` and `CLAUDE_LOG_V02.md`, push, verify remote, then continue immediately.

## M41-C001 V01 — owner-authorized early slice

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C001/CHATGPT_PROMPT_V01.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C001/CHATGPT_AUDIT_CRITERIA_V01.md

Scope only:
- SB-M41-001 Master
- SB-M41-002 Music
- SB-M41-003 SFX
- SB-M41-004 Haptics
- SB-M41-006 Persistence
- SB-M41-007 Settings UI
- SB-M41-008 Relaunch tests

Do NOT implement SB-M41-005 Reduced Effects.

Use the canonical post-M40 AppState/SaveService settings graph.
Do not revive independent audio_settings.cfg / haptics_settings.cfg as competing production authorities.

Settings requirements:
- Master slider/toggle
- Music slider/toggle
- SFX slider/toggle
- Haptics toggle
- live apply
- exact persistence/relaunch
- Music 0 affects music only
- SFX 0 affects gameplay SFX only
- Master 0 silences all audio
- Haptics OFF suppresses vibration only
- mobile-safe readable UI

Create M41 task logs + `CLAUDE_LOG_V01.md`, push and verify remote.

## Required regression

At minimum rerun:
- M30 / M31 / M33 relevant audio/playback tests
- M34 haptics tests
- M40 canonical bootstrap/save tests
- repaired M38 strict regression
- root test suite
- `git diff --check`

No SCRIPT ERROR may be ignored even if a suite footer prints PASS.

## Owner gates that remain after code handoff

- M33 final background music asset selection
- M33 owner F6 re-listening
- M41 Settings owner visual/manual F6
- M34 real-device haptics remains separate
- M36 human difficulty playtest remains separate
- M39 sixth-slot real-device safe-area/touch/readability remains separate

## Final handoff

Return:
- M33 V02 implementation/log SHAs + CLAUDE_LOG URL
- M41 V01 implementation/log SHAs + CLAUDE_LOG URL
- exact test results
- explicit remaining owner/device gates
- confirmation TASKS.md untouched
- confirmation SB-M41-005 untouched

Final line:
`AWAITING_AUDIT / M33-M41 EARLY SETTINGS BATCH COMPLETE`
