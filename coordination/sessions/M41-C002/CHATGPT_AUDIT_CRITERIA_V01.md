# M41-C002 V01 — SB-M41-005 Strict Audit Criteria

Date: 2026-09-25
Auditor: ChatGPT
Task: `SB-M41-005 Reduced Effects`

## PASS requires all of the following

### A. Canonical authority
- Reduced Effects has exactly one durable canonical setting authority in the M40 AppState/SaveService graph.
- Default is OFF for new state and old saves missing the field.
- No parallel sidecar save file or UI-owned truth exists.

### B. Strict save behavior
- Present value accepts exact bool only.
- Malformed present values follow existing whole-candidate rejection/recovery policy; no silent coercion.
- Future-schema/blocked AppState refuses mutation and the Settings control is read-only.
- ON and OFF both survive full relaunch exactly.

### C. Settings UI
- A single `REDUCED EFFECTS` control exists.
- It reads/writes canonical state only.
- It re-syncs correctly when the panel reopens.
- Touch target/readability remain consistent with M41-C001.
- Existing supported viewport matrix shows no clipping/overlap caused by the additional row.

### D. Real live gameplay binding
- The real production gameplay host consumes the canonical setting.
- Changing Reduced Effects after host build changes the existing CleaningEffectsController live; no gameplay rebuild is required.
- ON reaches the accepted M31 reduced behavior.
- OFF restores accepted M31 normal behavior.
- Existing FX enable/disable remains independent.

### E. Presentation-only invariant
- Reduced Effects changes only presentation density/cost.
- Equivalent ON/OFF gameplay reaches identical gameplay truth: same clear count/terminal result and no routing/reservation/supply/progression mutation.
- No new coupling from Settings/UI into BoardState or gameplay truth.

### F. Existing accepted behavior preserved
- M31 cleaning effects contract remains valid.
- M33 audio/settings isolation remains valid.
- M34 haptics behavior remains valid.
- M40 save/bootstrap behavior remains valid.
- M41-C001 Master/Music/SFX/Haptics controls remain valid.
- No M42 implementation appears in the diff.

### G. Tests/evidence
Claude log and task log must contain exact commands/results for:
- extended `m41_settings`;
- relevant M31 cleaning-effects focused tests;
- M33 audio runtime/settings;
- M34 haptics;
- M40 save/bootstrap safety;
- at least one real production-host gameplay invariant test;
- root suite;
- `git diff --check`.

All claimed runs must:
- exit 0;
- contain no `SCRIPT ERROR`;
- contain no hidden `FAIL:` line;
- complete all named ledger cases.

ChatGPT will independently inspect source and rerun/verify relevant evidence as available. Claude's PASS claim alone is not acceptance.

### H. Repository discipline
- root `TASKS.md` untouched by Claude;
- ChatGPT/owner audit artifacts untouched;
- focused implementation commit(s), no unrelated scope;
- published:
  - `coordination/sessions/M41-C002/CLAUDE_LOG_V01.md`
  - `coordination/sessions/M41-C002/task_logs/SB-M41-005.md`
- final Claude owner-facing response includes full GitHub links to both logs and implementation SHA.

## Verdicts

PASS:
`AUDITED_PASS / M41-C002 V01 / SB-M41-005 CODE CLOSED / OWNER_F6_REQUIRED`

If owner visual/manual evidence is not necessary because the implementation introduces no new visible/runtime behavior beyond already-owner-validated seams, ChatGPT may close directly only with explicit audit justification.

FAIL:
`CHANGES_REQUIRED / M41-C002 V01`

On failure, ChatGPT freezes concrete findings and authors a focused V02 remediation prompt. Unaffected accepted behavior must not be reopened.
