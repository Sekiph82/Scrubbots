# M34-C001 V01 — ChatGPT Audit Criteria

Milestone: `M34 — Haptics`
Tasks: `SB-M34-001..SB-M34-006`

Authority:
- root `TASKS.md`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- accepted M20/M30/M31/M33 event-authority contracts

## Governance
Claude implements/tests only. Claude must not edit root `TASKS.md`, create ChatGPT audit files, or self-assign `AUDITED_PASS`.
Every task must have a separate durable GitHub task log under:
`coordination/sessions/M34-C001/task_logs/<TASK_ID>.md`
and the canonical cycle log:
`coordination/sessions/M34-C001/CLAUDE_LOG_V01.md`
must index all six task logs.

## SB-M34-001 Platform API research
PASS requires repository-backed research notes for Godot 4.7.2 haptic APIs and Android/iOS support boundaries. Use built-in Godot APIs only unless an owner-approved dependency already exists. State what is directly testable headless vs device-only. Do not claim device support from desktop/headless execution.

## SB-M34-002 Cleaning haptic
Implementation may proceed as a conservative V1 presentation feature, but it must be driven only by the authoritative committed-clear seam `CompleteClearingLoop.authenticated_clear`. Failed/rolled-back clears emit no haptic request. Gameplay clear must never wait on haptics.

## SB-M34-003 Completion haptic
Completion haptic must observe the accepted M30 terminal latch and fire only for WON, at most once per attempt. LOST/ERROR must not reuse the win pattern unless separately owner-approved.

## SB-M34-004 Toggle
Provide a runtime haptics enabled/disabled setting seam, defaulting to a documented value. OFF must suppress new haptic requests without mutating gameplay. Persistence UI belongs to M41; do not build M41 settings UI here.

## SB-M34-005 Prevent vibration spam
Require deterministic throttling/debouncing/coalescing or an equivalently bounded policy. Cleaning bursts must not produce unbounded vibration requests. Expose request/played/suppressed diagnostics for tests. 1x/2x must not change gameplay truth.

## SB-M34-006 Real-device test
This task is DEVICE/OWNER-GATED. Claude cannot mark it independently complete without real Android/iOS evidence. Claude must create a dedicated debug/playtest scene or checklist and log `OWNER_REQUIRED / DEVICE_REQUIRED` if no authorized real device is available. This gate must NOT stop the overnight batch from continuing to M35.

## Required tests
- cleaning committed event -> one request subject to throttle
- rollback/rejected clear -> zero request
- WON -> one completion request
- repeated terminal evaluation -> no duplicate
- LOST/ERROR -> no completion request
- haptics OFF -> zero platform calls/requests while gameplay continues
- burst above throttle limit -> bounded/suppressed
- Retry/new attempt re-arms completion
- 1x/2x event-density smoke
- root suite + M30/M31 regressions + `git diff --check`

## Closure
Code-level success target:
`CODE_AUDIT_READY / M34-C001 V01 / DEVICE_OWNER_GATE_REMAINS`
Claude still hands back as `AWAITING_AUDIT`.