# M34-C001 V01 — Haptics Implementation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M34-001..SB-M34-006`

Read first:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M34-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- accepted M20/M30/M31/M33 event wiring

## Batch-continuation rule
This milestone is part of the owner-authorized M34→M40 overnight implementation batch.
At M34 completion, commit + push M34 implementation/evidence/logs, then CONTINUE to M35 even if SB-M34-006 remains `DEVICE_REQUIRED`.
Do not self-close the milestone and do not edit root `TASKS.md`.

## Implement
1. Research the exact Godot 4.7.2 built-in handheld vibration/haptic API and record platform limitations.
2. Add a narrow presentation-only haptics controller/service.
3. Cleaning haptic observes only `authenticated_clear`.
4. Completion haptic observes WON only, once per attempt.
5. Add runtime enable/disable seam.
6. Add deterministic anti-spam policy for cleaning bursts with diagnostics.
7. Keep haptics presentation-only and fail-open: unsupported platform/no-op must never block gameplay.
8. Add Retry/reset hygiene.
9. Create a dedicated M34 haptics playtest/debug scene/checklist suitable for later real-device validation.
10. Do not implement M41 Settings UI.

## Mandatory per-task GitHub logs
Create six separate files:
`coordination/sessions/M34-C001/task_logs/SB-M34-001.md`
through
`coordination/sessions/M34-C001/task_logs/SB-M34-006.md`.

Each file must record:
- task ID and requirement
- status: IMPLEMENTED / TESTED / OWNER_REQUIRED / DEVICE_REQUIRED / BLOCKED
- production files touched
- exact tests/checks
- expected result + explicit failure condition
- actual result
- known limitation
- relevant commit SHA/URLs where available

Then create canonical:
`coordination/sessions/M34-C001/CLAUDE_LOG_V01.md`
indexing all six task logs and recording prompt/criteria URLs, implementation SHA(s), test results, and final handoff.

## Git discipline
Preserve owner work. No destructive reset/clean/force push.
Commit implementation/tests first, then evidence/log docs. Push all M34 commits before starting M35.

## Final M34 handoff line inside CLAUDE_LOG_V01.md
`AWAITING_AUDIT / M34-C001 V01 / DEVICE_OWNER_GATE_REMAINS`

Then continue immediately to the M35 prompt from the overnight master pipeline.