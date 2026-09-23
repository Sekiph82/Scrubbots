# M34-C001 V02 — Remediation Audit Criteria

Purpose: close F-M34-001 without redesigning haptics.

PASS requires:
1. One production-owned HapticsController instance is created in the real gameplay composition.
2. `authenticated_clear` is connected exactly once to cleaning haptic.
3. `terminal_reached` is connected exactly once; only WON requests completion haptic.
4. successful Retry/new attempt resets the completion latch/throttle state.
5. persisted/current haptics enabled setting drives the live controller.
6. no haptic listener affects gameplay success/failure.
7. duplicate host setup/rebind does not duplicate signal connections.
8. production-stack tests prove event wiring rather than calling controller methods directly.
9. M33 audio/M31 FX/M30 retry regressions remain green.
10. SB-M34-006 remains DEVICE_REQUIRED until real handset evidence exists.

Handoff target:
`CODE_AUDIT_READY / M34-C001 V02 / DEVICE_OWNER_GATE_REMAINS`