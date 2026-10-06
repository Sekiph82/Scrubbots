# M43 — MASTER REMEDIATION V04 AUDIT CRITERIA

## Integration
- [ ] V03 commits are preserved and integrated without rewriting unrelated history.
- [ ] Owner-local files/addons remain untouched.
- [ ] Root TASKS.md untouched by Claude.

## M41 pack RNG
- [ ] Production CardPackService remains OS-seeded.
- [ ] No fixed production RNG introduced.
- [ ] M41 removes/normalizes only the irrelevant pack RNG field for cross-AppState invariance.
- [ ] All other progression/economy truth remains compared.
- [ ] Sensitivity mutation of a real economy field is caught.
- [ ] tests/m41_settings.gd PASS.

## LevelImporter portability
- [ ] Contract follows existing _resolve_path()/simplify_path intent.
- [ ] No fake test-only subdir creation used to mask the bug.
- [ ] output JSON actual I/O uses resolved/simplified path.
- [ ] preview actual I/O uses resolved/simplified path.
- [ ] metadata actual I/O uses resolved/simplified path.
- [ ] source/destination alias rejection remains intact.
- [ ] overwrite/unchanged semantics remain intact.
- [ ] missing-parent behavior remains explicit/fail-safe.
- [ ] distinct dot-segment output succeeds at simplified location on Linux.
- [ ] dot-segment alias cases still reject.
- [ ] preview/metadata dot-segment coverage exists.

## V03 preservation
- [ ] cloud conflict remediation still passes.
- [ ] notification rollback cap still passes.
- [ ] meta audio/haptic + fatigue remediation still passes.
- [ ] status corrections remain 92 READY / 33 BLOCKED / 21 DEFERRED unless a documented audit-authorized reason changes them.

## Final regression
- [ ] Godot 4.7.2 headless.
- [ ] M41 PASS.
- [ ] V03 focused suites PASS.
- [ ] root tests/run_tests.gd = ALL PASS 5,323 / 5,323 on Linux.
- [ ] git diff --check clean.
- [ ] no unexplained runtime/script errors.

## Handoff
- [ ] M43_MASTER_REMEDIATION_CLAUDE_LOG_V04.md exists.
- [ ] final SHA and branch/main state reported.
- [ ] ends AWAITING_GPT_M43_MASTER_REMEDIATION_V04_AUDIT.
