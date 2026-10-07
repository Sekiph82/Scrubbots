# SB-M53-C002-R01-001 — STALE CALIBRATION CORPUS DETERMINISM — CLAUDE LOG V01

Prompt: `CHATGPT_STALE_CORPUS_REMEDIATION_PROMPT_R01.md` · Criteria: `CHATGPT_STALE_CORPUS_AUDIT_CRITERIA_R01.md`

Root `TASKS.md` was not edited. Status: investigation complete, **remediation STOPPED at a GPT_REQUIRED / OWNER_REQUIRED decision** (prompt step 6). No product code, test, assertion, corpus/holdout evidence, frozen config, anchor or score was changed.

## Sync truth

**Environment.** This ran in a Claude Code cloud container (Linux). The owner-local `C:/Users/sekip/Desktop/ScrubBots` (Windows) is not accessible; it was not touched or synced.

**Branch.** `claude/practical-darwin-ndbmxa` had `origin/main` `16c6c2b` merged in non-destructively (`3318174`). It carries CP05-R01 `19618f6e`, which is unrelated to M53. No reset, clean, force or stash.

## 1. Reproduction (exact, one assertion)

**Command:** `godot --headless --path . -s res://tests/m53_c002_difficulty_calibration.gd` (Godot `4.7.2.stable.official.ed1daf0bf`, Linux).

| Tree | Result |
|---|---|
| untouched `e36e023` (separate worktree) | `FAIL: fresh run == committed corpus raw (timing excluded)`, the only failure (`FAIL (1)`) |
| current branch tree | identical single failure; `V2 measurement deterministic across two fresh runs (timing excluded)` = **ok** |

**Two fresh runs.** They agree within one process (the test's own assertion) and across separate processes: three independent processes printed the same `RR=1.286916935992815 … STRESS=1.2869169359928154` for `flow_stripes3_20`.

## 2. Field-level diff, whole corpus (machine-readable)

**Tool:** `tests/tools/m53_c002_corpus_drift_diagnostic.gd` (new, QA-only, read-only). It normalizes **exactly** like the test `_norm`: a JSON round trip with only `timing` removed. For every differing leaf it records the committed text, the fresh text and the fresh value's exact double.

**Evidence:** `coordination/sessions/M53-C002/evidence/r01_drift/corpus_drift_linux_v1.json` covers all **27** committed corpus fixtures.

**Result: 25 fixtures identical. Exactly 3 fields differ in 2 fixtures:**

| Fixture | Path | Committed text | Fresh text (Linux) | Fresh exact double |
|---|---|---|---|---|
| flow_stripes3_20 | `raw/runs/RR/routes/meanDetour` | `1.28691693599282` | `1.28691693599281` | `1.286916935992815` = 1.28691693599281498094910602958… |
| flow_stripes3_20 | `raw/runs/RR_REV/routes/meanDetour` | `1.28691693599282` | `1.28691693599281` | same |
| slot_high_24 | `raw/runs/RR/routes/lengthVariance` | `124.931303803135` | `124.931303803134` | `124.9313038031345` = 124.93130380313449734330788487568… |

There are no key, array-length, schema, policy-run, completion or vector differences. Every other value in all 27 raw records (thousands of floats and all integers) is text-identical.

## 3. Bisect / dependency history

**Corpus raw files.** They are unchanged since the freeze commit `4bea41e` (`git log -- coordination/sessions/M53-C002/evidence/corpus_raw/` lists only `4bea41e`).

**Probe.** The probe is the exact test normalization on `flow_stripes3_20`. It was run at each historical commit in a separate worktree on this machine:

| Commit | fresh == committed |
|---|---|
| `4bea41e` freeze (corpus written in this commit) | **false** |
| `e7865b4` First 10 holdout | **false** |
| `e36e023` | **false** |
| current | **false** |

Since the very commit that wrote the corpus already fails here with identical code and data, **there is no first behavior-changing commit**: `git bisect` has no good endpoint, and nothing in `scripts/difficulty/`, `tools/calibrate_difficulty_v2.gd`, supply/solver/routing/targeting, palette or fixtures drifted. The M53-C002 log of that commit records the original run as Godot 4.7.2 with the suite passing. That run was on the owner-local Windows checkout.

## 4. Source of drift: platform C runtime float formatting, not computation

**Dependency path.**
1. `_norm` → `JSON.stringify(raw)`.
2. Godot 4.7.2 `core/io/json.cpp` takes the FLOAT branch (`full_precision = false`) → `String::num(num, max(1, 14 - floor(log10|num|)))`.
3. `core/string/ustring.cpp String::num` → **`snprintf(buf, 325, "%.<p>lf", num)`**, i.e. the platform C runtime.

The tool wrote the corpus through the same path (`JSON.stringify(out, "\t")`).

**The three doubles are the same on both sides.** Each fresh double lies about 2e-17 relative *below* a decimal rounding midpoint at the printed precision (…281**498** / …134**497**):
- **glibc (Linux)** rounds exactly → `…281` / `…134` (the fresh text).
- **The committed text** equals a "17 significant digits first, then round half-up to `<p>` decimals" conversion of the **same** double. That is the classic msvcrt.dll-style `printf` (MinGW-w64 Windows) double rounding: `1.2869169359928150` → `…282`, `124.93130380313450` → `…135`.

**Check:** `evidence/r01_drift/verify_printf_models.py` (Python, stdlib only), applied to every diff in the JSON:

```text
fixtures 27 fixtures_with_diffs 2 diffs 3 explained_by_platform_printf 3 unexplained 0
per_fixture {'flow_stripes3_20': 2, 'slot_high_24': 1}
```

(Output saved in `verify_printf_models_output.txt`.) Every committed value is reproduced bit-for-text from the fresh double by the msvcrt model, and every fresh text by the glibc model. Together with the thousands of identical values, this shows the V2 computations are bit-identical across platforms; only the `float → text` step differs, and only for values sitting on a printing midpoint.

**Limit of this proof.** The Windows toolchain is inferred from the arithmetic, not observed: this session cannot run the owner's Windows build. **Owner confirmation step:** run the same test on the owner-local Windows checkout. The prediction is PASS with the exact-equality check intact.

## 5. Classification

- **Not a regression:** no code, data or behavior changed after the freeze.
- **Not an intentional audited behavior change.**
- **What it is:** a **latent platform-dependence defect in the evidence format and the equality check**. The committed QA evidence and the test both serialize floats through the C runtime `printf`, whose rounding is platform-specific. Exact text equality therefore holds only on the platform that wrote the evidence. The analyzer itself is deterministic.

## 6. Why remediation stops here (prompt step 6)

Every fix that makes the check pass on both platforms changes either the committed QA evidence bytes or the frozen-calibration artifacts, or what the assertion compares:

| Option | What it would do | Effect on authority |
|---|---|---|
| **A** (recommended) | Make the QA evidence platform-independent. Switch the calibration tool's raw/evidence writer AND the test `_norm` to Godot's own platform-independent shortest round-trip formatter (`JSON.stringify(v, indent, sort, full_precision = true)`, which uses `String::num_scientific` → grisu2, not `printf`). Regenerate corpus raw + corpus evidence + holdout raw/evidence through the existing tool. Exact equality stays (stricter: full precision) and becomes cross-platform. | Rewrites every `corpus_raw/*.json`, `calibration_corpus_v1.json`, holdout raw/evidence and probably the frozen config text and its `frozenConfigSha256` binding (anchors are written by the same `printf` path). This is a **re-freeze of the V2 candidate calibration artifacts.** Numeric values change only at ≤1e-15 and the scores/anchors are mathematically the same, but chronology/provenance bindings must be re-issued under explicit GPT/owner authority. |
| **B** | Declare the owner-local Windows build the canonical evidence platform. `m53_c002` runs as a Windows gate; Linux/cloud runs carry this proven, documented exception. | No code/evidence change. Leaves Linux/CI permanently red on this one assertion. |
| **C** | Emulate the evidence platform's formatting in the test `_norm`. | Changes what the assertion compares, so it counts as weakening/relabeling under the R01 rules. **Not recommended.** |

Option A is the actual root-cause fix (removing the C-runtime dependence from QA evidence). It requires a decision because it re-freezes the deferred owner's V2 candidate artifacts. Per the prompt I did **not** quietly regenerate, re-freeze, round, relax or alter anything.

**Decision requested (GPT_REQUIRED, owner-informed):**
1. Choose A or B.
2. If A: authorize a re-freeze of the V2-candidate calibration artifacts with exactly these properties:
   - the formatter change only;
   - no model, coefficient, fixture, supply or First 10 change;
   - provenance noting "re-serialized, numerically identical within 1e-15";
   - the holdout re-measured under the same frozen config.
3. Optionally, the owner runs the test once on Windows first, to confirm section 4's prediction.

## 7. Files added (no product/test/evidence change)

- `tests/tools/m53_c002_corpus_drift_diagnostic.gd`: read-only diagnostic.
- `coordination/sessions/M53-C002/evidence/r01_drift/corpus_drift_linux_v1.json`: field-level diff, all 27 fixtures.
- `coordination/sessions/M53-C002/evidence/r01_drift/verify_printf_models.py` and `verify_printf_models_output.txt`.
- This log.

**Unchanged:** `tests/m53_c002_difficulty_calibration.gd`, the analyzer, the tool, the corpus, the holdout, frozen config/anchors, production levels/supply/catalog/palette, Difficulty V1 and progression.

## 8. Tests

| Suite | Result |
|---|---|
| `m53_c002_difficulty_calibration` | **still FAIL (1)** on Linux, the same single assertion as `e36e023`; deliberately unchanged pending the decision |
| `m53_first10_difficulty` | PASS |
| M52 (owner plans, R01, R02) · M35 · M37 · M40 · M43 order context · CP04 · CP05 · CP05-R01 · family fixture | PASS (run on this branch tree; the CP05-R01 log has the table) |
| root `tests/run_tests.gd` | ALL PASS — 5329 checks |

**`git diff --check`:** clean.

The final SHA is in the handoff message.

AWAITING_GPT_M53_C002_R01_STALE_CORPUS_AUDIT
