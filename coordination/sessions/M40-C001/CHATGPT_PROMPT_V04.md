# M40-C001 V04 — Actual App Bootstrap & Persistence Lifecycle Remediation

Read:
- CHATGPT_AUDIT_V03.md
- CHATGPT_AUDIT_CRITERIA_V04.md
- post-M39 V04 CLAUDE_LOG
- M35 catalog implementation
- project.godot / scenes/app/main.tscn / scripts/app/main.gd

Start after M39 V04 is pushed.

Close F-M40-V03-001..004 only.

## Phase A — real bootstrap
Make the actual project main scene/script own one AppState.
Expose one canonical state instance to later Home/navigation and gameplay creation.
Future-schema blocked state must be handled by this actual root.

Do not build M42 Home UI here.

## Phase B — frontier -> content resolver
Add a narrow production gameplay-launch resolver:
- read current frontier from AppState;
- lookup LevelCatalog;
- configure gameplay host with that entry/path;
- explicit CONTENT_MISSING when absent.

Remove shipping dependence on stale exported level_path/progression_level pairing.
Keep debug override explicitly separate.

## Phase C — persistence binding
Consume the M39 V04 canonical action facade.
On successful committed durable action, request canonical AppState save/dirty.
Settings setters must go through AppState/application actions and persist canonically.

## Phase D — lifecycle
Add a root-level flush method and wire supported app background/quit notifications to it.
No per-frame save.

## Phase E — true integration tests
Boot the actual root/composition with injected test save path/provider.
Do not write a test that merely says the host "would read" a value.
Drive the actual resolver and action/save/relaunch seams.

Create task_logs_v04 for SB-M40-002,003,005,010,013 and any directly touched row.
Create CLAUDE_LOG_V04.md with F-M40-V03-001..004 closure table.

Do not edit TASKS.md.
Do not self-audit.
Do not start M41+.

Handoff:
`AWAITING_AUDIT / M40-C001 V04 / ACTUAL_BOOTSTRAP_REAUDIT_REQUIRED`
