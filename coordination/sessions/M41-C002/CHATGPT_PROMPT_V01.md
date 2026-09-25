# M41-C002 V01 — SB-M41-005 Reduced Effects Settings Integration

Date: 2026-09-25
Repository: `Sekiph82/Scrubbots`
Implementation actor: Claude
Task: `SB-M41-005 — Reduced effects`

## Authority and scope

Read first:
- root `TASKS.md`
- `CLAUDE.md`
- `coordination/sessions/M41-C001/CHATGPT_AUDIT_V01.md`
- `coordination/OWNER_M41_SETTINGS_ACCEPTANCE_V01.md`
- `coordination/sessions/M31-C001/CHATGPT_AUDIT_V01.md`
- `scripts/gameplay/presentation/cleaning_effects_controller.gd`
- current M40 AppState/SaveService/settings graph

This cycle exists only to close the one remaining M41 row:
`SB-M41-005 Reduced Effects`.

Do not start M42.
Do not edit root `TASKS.md`.
Do not reopen or redesign accepted M31 cleaning effects.
Do not change gameplay truth, economy, progression, routing, completion, clearing, target selection, audio or haptics semantics.

## Existing accepted contract

M31 already owns the presentation behavior:
- `CleaningEffectsController.set_reduced_effects(bool)`
- normal default is reduced-effects OFF;
- reduced mode changes presentation density/cost only;
- reduced mode uses one shorter cue and the lower concurrency cap;
- it must never change clear count, clear timing, WON/LOST truth, routing, reservation, supply or progression.

M41-C001 already owns the Settings architecture:
- one canonical AppState / SaveService authority;
- live settings changes;
- strict save validation;
- persistence and relaunch restoration;
- responsive/mobile-readable Settings UI;
- blocked/future-schema state is read-only;
- no competing legacy side-file writer.

Extend those accepted contracts. Do not create a parallel settings authority.

## Required implementation

1. Add one canonical durable boolean setting for Reduced Effects.
   - Default for new users and old saves that lack the field: `false`.
   - Preserve M31 normal-mode behavior by default.
   - Use the existing M40 canonical save graph.
   - No new user:// sidecar settings file.

2. Strict persistence validation.
   - Exact bool values only.
   - A malformed present value must not be silently normalized.
   - Follow the existing M40/M41 whole-candidate validation/recovery policy.

3. Add a canonical AppState action/read seam for Reduced Effects.
   - Refuse mutation while AppState is blocked.
   - Persist through the canonical save path.
   - No UI-owned state.

4. Bind production gameplay live to the canonical setting.
   - The real `ProductionGameplayHost` / cleaning-effects path must consume the canonical setting.
   - Toggling Reduced Effects while gameplay is already running must update the existing cleaning-effects controller without rebuilding gameplay.
   - Re-enabling normal mode must restore normal presentation behavior live.
   - The accepted M31 FX ON/OFF behavior must remain independent.

5. Extend the Settings panel.
   - Add one touch-safe, readable toggle labelled `REDUCED EFFECTS`.
   - It must reflect canonical state when opened/reopened.
   - It must be disabled/read-only when AppState is blocked.
   - It must fit the existing supported viewport matrix without clipping/overlap.
   - Do not add unrelated settings.

6. Persistence/relaunch.
   - Toggle ON, relaunch, remains ON.
   - Toggle OFF, relaunch, remains OFF.
   - Pre-M41-C002 saves with no reduced-effects field load successfully with OFF.

7. Gameplay invariance.
   - Run equivalent production-host gameplay with Reduced Effects OFF and ON.
   - Both runs must reach the same terminal truth and clear the same cells.
   - Only presentation density/cost may differ.

8. Test the actual live presentation seam.
   - Prove OFF uses the accepted normal M31 behavior.
   - Prove ON reaches reduced M31 behavior.
   - Prove switching live in both directions works on the already-built real host.
   - Do not satisfy this only with a fake isolated boolean.

9. Regression protection.
   At minimum run and record:
   - `tests/m41_settings.gd` (extend it rather than weakening existing cases)
   - relevant M31 cleaning-effects focused suites
   - M33 audio runtime/settings regressions
   - M34 haptics regressions
   - M40 save/bootstrap safety suites
   - relevant production-host gameplay regression
   - root test suite
   - `git diff --check`
   Reject any run with `SCRIPT ERROR`, incomplete named cases, hidden FAIL lines or non-zero exit.

10. Preserve accepted scope.
   - Do not alter M33 owner-approved music/audio behavior.
   - Do not alter M34 haptics behavior.
   - Do not alter the owner-accepted M41-C001 controls except as necessary to lay out the one new toggle.
   - Do not implement M42.
   - Do not edit ChatGPT audit artifacts or owner evidence.

## Evidence/logging requirements

Create/update:
- `coordination/sessions/M41-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M41-C002/task_logs/SB-M41-005.md`

The task log must map every requirement above to concrete files/tests/results.

The final Claude message shown to the owner must include:
- implementation commit SHA;
- test summary;
- handoff verdict exactly:
  `AWAITING_AUDIT / M41-C002 V01 / SB-M41-005`;
- the full clickable GitHub URL to the published log:
  `https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C002/CLAUDE_LOG_V01.md`
- the full clickable GitHub URL to the task log:
  `https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M41-C002/task_logs/SB-M41-005.md`

Commit and push all authorized implementation + logs to `main`.
Never force-push.

## Stop condition

After publishing the code and logs, STOP.
Do not self-audit.
Do not edit `TASKS.md`.
Do not start M42.
ChatGPT performs the independent audit and decides PASS vs remediation.
