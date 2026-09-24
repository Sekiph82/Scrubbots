# M34-C001 V02 — Claude Remediation Log

V01 audit: `coordination/sessions/M34-C001/CHATGPT_AUDIT_V01.md`
(verdict `CHANGES_REQUIRED / PRODUCTION_WIRING_REQUIRED`, F-M34-001)
V02 prompt: `coordination/sessions/M34-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M34-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Master batch: `coordination/sessions/M34-M40-BATCH/CHATGPT_MASTER_PROMPT_V02.md`

## F-M34-001 fix — production event wiring
`scripts/gameplay/runtime/production_gameplay_host.gd`:
- owns one live `HapticsController` + `HapticsSettingsService` (parallel to the
  M33 audio wiring);
- loads the persisted enabled bit and calls `set_enabled(...)` on the live
  controller;
- `_bind_haptics_signals()` connects `authenticated_clear -> _on_authenticated_clear`
  and `terminal_reached -> _on_terminal_reached` exactly once, guarded by
  `is_connected` so a host rebuild/rebind never stacks duplicate connections;
- `_on_retry_restored()` calls `_haptics.reset_for_new_attempt()` alongside the
  audio/FX resets;
- accessors `get_haptics_controller()` / `get_haptics_settings()`.
- fail-open preserved: unsupported platform / disabled / throttled never blocks
  the clear or terminal transaction.

## Test
`tests/m34_haptics_production.gd` — builds the real `ProductionGameplayHost`,
drives it to WON through the full stack, and asserts the injected platform sink
saw cleaning vibrations from real committed clears and exactly one completion
vibration on WON; verifies exactly-once connection + idempotent rebind. **PASS**.

Regression: `m33_audio_runtime` PASS, `m34_haptics_runtime` PASS,
`m30_transaction_safe_retry` PASS, `m30_completion_authority` PASS.

## Task logs
`coordination/sessions/M34-C001/task_logs_v02/SB-M34-002..006`.

## Gate
SB-M34-006 remains OWNER_REQUIRED / DEVICE_REQUIRED (no device evidence faked).

## Handoff
`AWAITING_AUDIT / M34-C001 V02 / DEVICE_OWNER_GATE_REMAINS`

Root `TASKS.md` not edited. Continuing to M36 V02.
