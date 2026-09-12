# M21-C001 — ChatGPT Independent Audit V02

Date: 2026-09-12
Auditor: ChatGPT
Cycle: `M21-C001`
Implementation evidence: `CLAUDE_LOG_V02.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_V02.md`

## Decision

**CHANGES_REQUIRED / F-M21-STRICT-003 RESIDUAL / V03_FINAL_PATH-SAFETY_AND_DIRECT-EVIDENCE_RECONCILIATION_REQUIRED**

V02 closes F-M21-STRICT-001, F-M21-STRICT-002 and F-M21-STRICT-004 with strong source-level and direct-test evidence. The AL-035 real-art adversarial pass also materially strengthens M21 and I found **no new M19/M20 gameplay-state defect**.

Final M21 closure is blocked by one residual inside the already-frozen F-M21-STRICT-003 path-safety finding: the new builder still does not use one filesystem-resolution contract consistently across alias identity and destination preflight for bare relative paths. V03 is therefore deliberately small and final in scope: unify the builder's path resolution and close a few explicit direct-evidence cells that V02 criteria required but V02 did not directly exercise on the new builder/fresh adversarial arrangement.

No `SB-M21-*` or `SB-UI-014..016` checkbox is closed by this audit.

---

## 1. Exact audit basis

The V02 implementation/handoff commit audited is exactly:

`00efae2b00ccd7cbd9afebc3d85fdcdcf895de81`

Its direct parent is the authorized tracker-only V02 start commit:

`3326d0a012ebe22c96d763690457596852fbcb7b`

At audit time `origin/main` / GitHub `main` points to `00efae2b...`.

The V02 implementation commit changes only the authorized M21 surfaces:

- `TASKS.md` lifecycle handoff;
- `coordination/sessions/M21-C001/CLAUDE_LOG_V02.md`;
- `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png`;
- `scripts/tools/production_art_level_builder.gd`;
- `tests/m21_real_art_smoke.gd`;
- `tests/run_tests.gd`;
- `tools/build_m21_reference_composite.gd`.

Claude reports Godot `4.7.1.stable.official.a13da4feb`, root suite `4475/4475`, dedicated M21 400-cell smoke PASS, all required M20 lifecycle smokes PASS, clean parse/error scans, deterministic level/composite reruns, and `git diff --check` with only the documented owner/local line-ending advisories. These runtime executions remain implementer E1/E2 evidence; this audit independently inspects GitHub source, test design, commit scope and immutable identities.

---

## 2. Locked identities independently verified

At `00efae2b...`:

- owner-approved Hazard Bot source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`;
- `scripts/gameplay/clearing/complete_clearing_loop.gd` remains blob `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` remains blob `eee10149e4f116af6706beec832042352bf3a6dd`.

No M19/M20 production gameplay source was changed by V02.

---

## 3. Frozen finding disposition

### F-M21-STRICT-001 — CLOSED

V02 now establishes one coherent difficulty identity before normalization:

- unsupported/malformed raw input is rejected first;
- the explicit compatibility difficulty must equal `raw.difficulty`;
- TEST, unknown and empty production difficulty are rejected;
- the normalized LevelData carries the same difficulty that was validated;
- successful normalized production output runs `ProductionLevelValidator`;
- the valid owner M21 fixture still normalizes to the canonical ascending local C-ID order without pixel change.

The direct mismatch test is load-bearing rather than accidentally green: it uses otherwise-valid production data and asserts the specific identity-mismatch failure.

**Disposition: CLOSED.**

### F-M21-STRICT-002 — CLOSED

`normalize_from_level_data` now applies an exact LevelData-script identity guard before field dereference. V02 directly attacks null, scalar/string/vector and unrelated/partial object shapes and expects a normal failed `NormalizeResult`, rather than relying on an engine exception.

The owner source is not touched by those malformed-input checks.

**Disposition: CLOSED.**

### F-M21-STRICT-003 — PARTIALLY CLOSED, ONE RESIDUAL REMAINS

V02 correctly improved the builder in several important ways:

- it preflights every enabled final destination before the first final write;
- final destination directories and missing/non-directory parents are rejected;
- output/preview/metadata content plans are all computed before writing;
- source/destination and destination/destination aliases remain rejected;
- a later preview failure is directly shown not to leave the earlier output behind;
- identical text artifacts tolerate checkout line-ending normalization for `UNCHANGED` detection.

However the builder still has **two different path-resolution rules inside the same write path**.

`_canon()` explicitly gives a bare relative path the already-audited project-relative base:

```gdscript
elif not r.is_absolute_path():
    r = ProjectSettings.globalize_path("res://" + r)
```

But `_preflight_destination()` instead does:

```gdscript
var real := ProjectSettings.globalize_path(path.replace("\\", "/")).simplify_path()
```

with no equivalent bare-relative -> `res://` step.

This is exactly the identity-normalization class governed by AL-013. The accepted M09 resolver deliberately established one explicit base for bare relative paths before filesystem checks; the new M21 builder's alias comparison follows that rule, while its destination-parent/object preflight does not.

Consequences:

- a syntactically bare-relative destination can be judged under a different path identity during preflight than during alias comparison / normal FileAccess semantics;
- behavior can become dependent on how the underlying API treats a non-`res://` relative string rather than on the canonical project-relative contract;
- V02 has no direct new-builder test proving a legitimate bare-relative destination resolves to the same physical destination as its `res://...` equivalent.

This is not a newly expanded finding. It is an incomplete closure of F-M21-STRICT-003 criteria 46/51/57.

**Disposition: OPEN RESIDUAL.**

### F-M21-STRICT-004 — CLOSED

`tools/build_m21_reference_composite.gd` is now a durable regeneration path. It derives initial / deterministic partial / fully-cleared panels from committed M21 LevelData and BoardRenderer truth over BG01 rather than reading the existing composite as source truth. Claude records two consecutive deterministic runs with the second `UNCHANGED` and correctly labels this as headless evidence rather than mobile FPS/device evidence.

**Disposition: CLOSED.**

---

## 4. AL-035 gameplay validation result

The V02 blocked-activation arrangement is strong and load-bearing. On a fresh real production bundle it snapshots:

- all 400 BoardState states;
- all five candidate buckets;
- reservation truth/count;
- dispatcher state;
- M20 cleared count;
- renderer truth;

then requires a blocked non-C08 activation to return exactly `NO_REACHABLE_TARGET` with exact state preservation.

The same fresh real production path then dispatches a C08 Scrubbot, proves reservation + MOVING before arrival, drives authenticated arrival, and continues real clears until an initially-blocked non-C08 color becomes genuinely reachable and clears. The separate full-level smoke still drives all 400 cells through production collaborators and reports the exact zero-final-state invariants.

I found no evidence that M21 exposed a new M19/M20 production defect.

### Small direct-evidence reconciliation still required in V03

These are evidence gaps, not new gameplay defects:

1. V02 criteria 72 requires the **fresh V02 adversarial arrangement itself** to assert exact candidate counts `30/5/298/11/56`; V01 has those assertions, but the new V02 arrangement does not directly restate them.
2. V02 criteria 78 requires the first fresh successful authenticated arrival to directly prove candidate removal + reservation cleanup + dispatcher cleanup as well as exactly one clear. Those cleanup truths are proven in V01 and at final full-smoke state, but not all are directly asserted at that exact V02 first-arrival boundary.

V03 will add only those exact assertions while the path fix is already being validated.

---

## 5. Additional F-M21-STRICT-003 direct-evidence cells to close in V03

The production code is generic enough that these cases appear intended to work, but V02 criteria explicitly required direct evidence against the **new builder**, and the V02 test matrix/log does not directly demonstrate all of them:

- existing-different **preview** with `overwrite=false` blocks output mutation;
- existing-different **metadata** with `overwrite=false` blocks output/preview mutation;
- existing **directory at metadata path**, including `overwrite=true`, blocks earlier mutations.

Because V03 already must touch the path/preflight test surface, these will be reconciled there rather than creating another serial audit version later.

---

## 6. V03 frozen final scope

V03 must do only the following:

1. Introduce/reuse one canonical path resolver for the M21 builder, equivalent to accepted M09 semantics:
   - `res://` / `user://` globalized;
   - bare relative explicitly based at `res://`;
   - absolute kept absolute;
   - `.` / `..` simplified;
   - Windows case folding only for comparison identity, not for physical I/O paths.
2. Make alias comparison and deterministic destination preflight use that same resolver contract. Planning/writing must be demonstrably consistent with that resolved destination identity.
3. Add direct new-builder tests for legitimate bare-relative resolution and bare-relative/res:// / absolute-equivalent alias cases.
4. Add the missing preview/metadata conflict + metadata-directory direct tests.
5. Add the exact fresh candidate-count and first-arrival cleanup assertions noted above.
6. Rerun the entire M21 + M20 regression/evidence matrix.

No M19/M20 gameplay production change, Difficulty V1 implementation, Level Factory/PixelLab implementation, M22 UI/touch work, or task closure is authorized.

---

## 7. Closure state

M21 remains open.

- `SB-M21-001..012`: remain unchecked pending final independent closure.
- `SB-UI-014..016`: remain unchecked pending final independent closure.
- progress remains `304/719` main+ui and `304/943` overall.
- `lastCompletedTaskId` remains `M20-C001-V11`.

If V03 closes the one residual path-resolution issue and the frozen direct-evidence matrix without exposing another material defect, the next independent audit is intended to be the **M21 strict-v2 final closure**, not another broad implementation pass.
