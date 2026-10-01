# M42-C003 V03 Reduced Effects capture

AppState.effects.set_reduced(true) on a live Home, then 12 attempts to start each gesture in turn with 0.5 s of runtime between renders (6 s total).

- Distinct rendered frames: 1 (1 = completely static)
- Gesture start counts before ON { "bow": 1 } -> after 12 attempts { "bow": 1 } (start_gesture refused while reduced)
- Idle squash: (1.0, 1.0) (identity)
- Capture: `reduced_effects_static_1080x2160.jpg`
