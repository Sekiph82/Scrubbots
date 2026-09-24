# M41-C001 V01 — Early Settings Slice Audit Criteria

Owner-authorized scope: SB-M41-001,002,003,004,006,007,008.
SB-M41-005 Reduced Effects is not required by this early slice.

PASS requires:
- Master, Music, SFX controls;
- Haptics on/off control;
- each value applies live;
- each value persists;
- relaunch restores exact values;
- 0 Music silences only music;
- 0 SFX silences gameplay SFX but not music;
- Master 0 silences all audio;
- Haptics OFF suppresses vibration without gameplay mutation;
- settings UI uses canonical services, no duplicate settings authority;
- mobile-readable controls and no direct gameplay mutation.

Handoff:
`AWAITING_AUDIT / M41-C001 V01 / SETTINGS_OWNER_F6_REQUIRED`