# M40-C001 V04 — ChatGPT Independent Full-Surface Audit

Date: 2026-09-25
Verdict: **AUDITED_PASS / M40 SAVE SYSTEM CLOSED**

Implementation: `21f8892`
Claude log: `coordination/sessions/M40-C001/CLAUDE_LOG_V04.md`
Criteria: `coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

## Executive result

The V04 implementation materially closes F-M40-V03-001..004.

All M40-owned task requirements are code/evidence-proven under current source
review. Final milestone `AUDITED_PASS` is withheld only because the mandatory
M38 strict regression is currently a false-positive suite: one required
sub-test aborts with SCRIPT ERROR while the process prints PASS.

M38 V03 now owns that evidence repair.

## Pass A — implementation/state sweep

### F-M40-V03-001 actual app bootstrap — ACCEPTED

The actual project main scene remains `res://scenes/app/main.tscn`, and its
root script now:
- constructs one AppState in `_enter_tree()`;
- owns the canonical save graph;
- exposes blocked state;
- creates gameplay only through `launch_gameplay()`;
- injects the same AppState into ProductionGameplayHost;
- flushes lifecycle state on pause/focus-out/close.

The old diagnostic labels remain presentation only.

### F-M40-V03-002 frontier -> content identity — ACCEPTED

`GameplayLaunchResolver` resolves the canonical progression frontier through
LevelCatalog by explicit order.

Accepted fail-closed behavior:
- frontier 1 -> actual catalog entry 1;
- missing frontier -> `CONTENT_MISSING`;
- stale exported `level_path/progression_level` are ignored on AppState path.

### F-M40-V03-003 durable action/save lifecycle — ACCEPTED

Accepted:
- AppState-level action facade bound to canonical save;
- host facade routes successful gameplay actions to AppState save;
- settings mutate through AppState and save;
- failed action does not signal/save;
- root lifecycle flush exists;
- no per-frame save behavior.

### F-M40-V03-004 local-day end-to-end persistence — ACCEPTED

Actual root tests use the M39 V04 local-calendar provider through AppState and
cover relaunch across same local day, next local day, year/month boundary and
clock rollback.

## Pass B — evidence/test/policy sweep

`tests/m40_v04_bootstrap.gd` actually instantiates the configured main scene
rather than merely AppState.

Directly observed test intents include:
- project main scene identity;
- same AppState graph in gameplay host;
- future schema block;
- catalog frontier resolution;
- CONTENT_MISSING;
- non-terminal durable action relaunch;
- failed action no-save;
- settings relaunch;
- lifecycle flush relaunch;
- local Daily boundary relaunch;
- no per-frame writes.

### Mandatory regression gap

V04 criteria require M38 regression. Claude disclosed that
`m38_v02_strict.gd` emits a typed-argument SCRIPT ERROR in one required case
and still prints PASS.

Therefore M40 final `AUDITED_PASS` waits for M38 V03 repaired evidence and a
rerun of `m40_v04_bootstrap.gd` plus root suite.

No M40-owned task row is reopened by this external evidence defect.

## Interaction sweep

Checked:
- AppState + future schema;
- AppState + LevelCatalog frontier;
- action commit + save boundary;
- settings + canonical save;
- local calendar + Daily + save/relaunch;
- lifecycle flush + blocked state;
- gameplay host + shared economy/progression graph.

No additional material M40 production defect found.

## Sprint task ledger

| Task | Status | Audit note |
|---|---|---|
| SB-M40-001 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-002 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-003 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-004 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-005 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-006 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-007 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-008 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-009 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-010 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-011 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-012 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |
| SB-M40-013 | PROVEN | V01-V04 source/evidence reconciled; V04 app-bootstrap interactions reviewed. |

Verdict string:
`CODE_AUDIT_PASS / M40-C001 V04 / M38 STRICT REGRESSION REQUIRED BEFORE FINAL AUDITED_PASS`


## Final mandatory-regression closure — 2026-09-25

The M38 strict false-PASS harness was repaired in M38 V03 with production M38
unchanged. The corrected suite now runs all 11 expected cases, contains no
SCRIPT ERROR, and fails if a sub-test aborts.

Claude reran the M40 V04 required dependency/regression set after that repair:
- repaired `m38_v02_strict.gd`: PASS 11/11
- `m39_v04_integration.gd`: PASS
- `m39_v04_tornado_inflight.gd`: PASS
- `m40_v04_bootstrap.gd`: PASS
- root: 5336 checks / 0 failures

The external regression gate is therefore closed.

All M40 task rows are now independently accepted.

Final verdict string:
`AUDITED_PASS / M40 SAVE SYSTEM CLOSED`
