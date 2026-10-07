# SB-M53-C002-R01-001 — PLATFORM-INDEPENDENT SERIALIZATION RE-FREEZE — CLAUDE LOG V02

Prompt: `CHATGPT_PLATFORM_INDEPENDENT_REFREEZE_PROMPT_R02.md` · Criteria: `CHATGPT_PLATFORM_INDEPENDENT_REFREEZE_AUDIT_CRITERIA_R02.md`
Authority: `CHATGPT_SERIALIZATION_AUTHORITY_DECISION_V01.md` (Option A) · Diagnosis: `SB-M53-C002-R01-001_CLAUDE_LOG_V01.md`

Event label: **`SERIALIZATION_ONLY_PLATFORM_INDEPENDENT_REFREEZE`**. This is not a difficulty retune. V2 stays `CANDIDATE_NOT_PRODUCTION_AUTHORITY`.

Root `TASKS.md` was **not** edited by Claude.

## Sync truth

**Environment.** This ran in a Claude Code cloud container (Linux). The owner-local `C:/Users/sekip/Desktop/ScrubBots` is **not accessible** from this session; it was not touched or synced, and no claim is made about it.

**Sync.**
- Branch `claude/practical-darwin-ndbmxa` was 0 ahead / 6 behind `origin/main` `596d2aab`. `main` had merged the CP05-R01 work (`09f32004`) plus the ChatGPT re-audit, decision, R02 prompt/criteria and `TASKS.md`.
- `git merge --ff-only origin/main` was a plain fast-forward. No reset, clean, force or stash.

**Remote Content Runtime + CP05-R01 intact.** No `scripts/content_runtime/` file and no CP04/CP05 test is touched. The CP04/CP05/CP05-R01/family suites pass (section 8).

## 1. Canonical serialization authority

**New file:** `tools/m53_canonical_json.gd` (QA-only; under `tools/`, never shipped):

```gdscript
static func stringify(value, indent: String = "\t") -> String:
	return JSON.stringify(value, indent, true, true)   # sort_keys = true, full_precision = true
static func file_text(value) -> String:
	return stringify(value, "\t") + "\n"
```

**Why this is platform-independent (verified in the Godot 4.7.2-stable source):**
- `core/io/json.cpp`, FLOAT branch:
  - `full_precision` → `String::num_scientific(num)` (exact `0` → `"0.0"`, and `".0"` is appended to integral values);
  - otherwise → `String::num(num, 14 - floor(log10|num|))`.
- `core/string/ustring.cpp`:
  - `String::num` → **`snprintf("%.<p>lf")`**, the C runtime. That was the old, platform-dependent path.
  - `String::num_scientific(double)` → **`grisu2::to_chars`** (`thirdparty/grisu2/grisu2.h`). This is Loitsch's Grisu2: integer `diyfp`/`uint64` arithmetic producing the shortest round-trip digits, with no `printf`/`strtod` call.
- Integers, strings, bools and null go through their own non-float branches (unchanged). Keys are sorted at every depth, with tab indent, `\n` newlines and exactly one trailing LF in files.

**Not changed:** generic game JSON behavior, `--build-corpus` (fixtures / manifest: integer-valued floats only, and not regenerated, so fixture hashes are untouched), and every non-M53 writer.

**Wiring.**
- **`tools/calibrate_difficulty_v2.gd`:** all five evidence writers now use `Canon.file_text`: corpus raw, frozen config, corpus evidence, holdout raw and holdout evidence.
- **`tests/m53_c002_difficulty_calibration.gd` `_norm`:**

```gdscript
var d: Dictionary = JSON.parse_string(Canon.stringify(raw, ""))
d.erase("timing")
return Canon.stringify(d, "")
```

  The assertion is the same exact string equality. Only the platform-dependent writer was replaced. There is no epsilon, skip, platform branch or field deletion.

**Godot parser note (disclosed, not hidden).** Godot's JSON number parser (`String::to_float`) is Godot's own C++ code, not the C runtime, but it is not correctly rounded for every input. On 400,000 random doubles, about 28 % of shortest-digit texts parse back 1 ULP off. Of the 189,092 floats in the M53 evidence, **1** does. Two consequences:
- **The determinism check stays exact.** It passes both sides through the identical serialize → parse → serialize path, so the comparison is a deterministic function of the measured double.
- **Read-back can be 1 ULP off.** Values the pipeline reads back from evidence (anchors and scores computed from committed raw) can differ from the in-memory double by at most 1 ULP. That is below every printed or decision precision; section 4 proves all decisions are identical.

**Golden suite:** `tests/m53_c002_canonical_json.gd`, **PASS 30/30**:
- **Goldens:**
  - the three boundary values `1.286916935992815` / `124.9313038031345`, as shortest digits and never the 15-digit printf text;
  - `0.1`, `-2.5`, `1/3`, `123456789.125`, `-0.000123`, `1e-07`, `1e+21`, `0.0`, `29.0`;
  - ints `29` / `-3` / `0`, plus `true` / `null` / string.
- **Structure:** nested dict/array with sorted keys at every depth; insertion order never changes the text; exact tab/LF layout; one trailing LF, no CR.
- **Repeatability:** 200 repeated runs are byte-identical.
- **Round trip:** the boundary values parse back to identical bits, and `canonical(parse(canonical))` is stable.
- **Wiring assertions:** five canonical writers in the tool, and the test `_norm` uses the authority.

## 2. Regeneration sequence (existing tool only; no manual value edits)

Old artifacts were byte-copied to a scratch snapshot first, for the report.

| Step | Command (`godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- …`) | Result |
|---|---|---|
| 1 | `--measure=<fixture>` × 27 (4 parallel workers, one process per fixture) | 27/27 `solver=SOLVED ok=true`, all 7 policies complete |
| 2 | `rm -r …/evidence/holdout_raw` (the tool's own chronology guard refuses `--refreeze` while holdout raw exists) | — |
| 3 | `--calibrate --refreeze` | 14/14 ordinal pairs PASS; family checks flowSizeSpread / flowBelowMedium / colourCountAlone PASS; `CALIBRATED config_sha=7dc96a0d… pairs_ok=true robust_ok=true` |
| 4 | `--holdout=<level>` × 10, against the newly frozen config | 10/10 `ok=true` |
| 5 | `--holdout-merge` | `HOLDOUT_MERGED inWindow=2 missing=[8 levels] robustAll=false`, identical to the previous holdout |

Chronology is preserved: corpus raw → anchors/freeze → corpus evidence → First 10 holdout raw → holdout evidence + matrix. Fixtures, manifest and production files were not regenerated.

## 3. Old/new SHA-256

| Artifact | Old | New |
|---|---|---|
| frozenConfigSha256 (`data/config/level_difficulty_analysis_v2_candidate.json`) | `4cd879c5aa8e6ee141169f29b5f6a758e20a1d88987bbff5c5de091051da14f8` | `7dc96a0de14d385cdda1f4c13caad9c34abd82629413552ec5d197b28f530fc5` |
| corpusManifestSha256 | `13885bcf2f0fc483b4a5aa6d00f73ff38cccf33db4b82671bdb8b068b66b227f` | **unchanged** |
| `evidence/calibration_corpus_v1.json` | `d7554ea0669e5a7f…` | `3da09bbacca4131f…` |
| `evidence/difficulty_v2_candidate_first10.json` | `b4f1b1f71c1de53f…` | `0eaa253d08085e22…` |
| `DIFFICULTY_CALIBRATION_MATRIX_V01.md` | `2979eba694cf0632…` | `91c96e8426f61fd1…` |
| 27 × `corpus_raw/*.json`, 10 × `holdout_raw/*.json` | full old/new SHA-256 for every file in `evidence/r01_refreeze/refreeze_report_v1.json` → `artifacts` | |

**Bindings.**
- Every corpus fixture `levelSha256` / `supplySha256` and every holdout `levelSha256` is **identical**.
- All 22 `frozenConfigSha256` fields (config/evidence/holdout raw) now carry `7dc96a0d…`, and the test's freeze-discipline checks pass.
- The matrix differs from the old one in **one line only**: the frozen-config SHA line.

## 4. Semantic invariants

All of these come from `evidence/r01_refreeze/refreeze_report_v1.json` (`allInvariantsHold: true`):

| Invariant | Result |
|---|---|
| Fixture level + supply SHA identical (27) | ✅ |
| Holdout level SHA identical (10) | ✅ |
| Corpus manifest SHA identical | ✅ |
| No structural change (keys / array lengths) in any artifact | ✅ |
| Only non-numeric change = `frozenConfigSha256` | ✅ |
| Corpus decisions identical: 14 ordinal pairs (axisPass / dPass / pass), 3 family checks, 27 robustness PASS/FAIL, `allFixturesWithinTolerance`, `calibrationPass`, `firstTenRead=false`, 27 × SOLVED, dominant/runner-up profiles | ✅ |
| Holdout decisions identical: 10 verdicts, acceptance windows, class/role, robustness, profiles, summary (`inDefaultWindow 2`, same 8 missing, `robustnessPassAll false`), recovery guards L3→L4 / L5→L6 / L8→L9 (all FAIL as before, `lowerThanPeak` unchanged), L10 boss (level 10, cycle maximum, rank 1, same descending order) | ✅ |
| Rounded owner-facing scores identical (challengeScore 2 dp, signedDelta 2 dp, sessionLoad 1 dp; 27 + 10 rows) | ✅ |
| Matrix text identical except the frozen-SHA line | ✅ |
| Every raw delta is exactly the old lossy print of the new double | ✅ (12,506 / 12,506) |
| Every derived delta is attributable to raw precision only | ✅ (343 / 343, see below) |

**V2 model unchanged.** There is no V2 formula, coefficient, policy, tolerance, fixture or rule change: `git diff` touches no `scripts/difficulty/*`, no `level_progression_v1.json` / `difficulty_score_model_v1.json`, and no production level/supply/catalog/palette. The config diff is limited to the anchor values at full precision plus the key order (sorted).

## 5. Numeric deltas (old 15-digit text → new full precision; `timing` excluded)

| Scope | Changed leaves | Max abs Δ | Max rel Δ |
|---|---|---|---|
| corpus raw (27 files; 103,606 numeric leaves) | 8,331 | 4.37e-10 | 4.53e-15 |
| holdout raw (10 files) | 4,175 | 5.09e-11 | 4.48e-15 |
| calibration_corpus_v1.json | 2,606 | 1.06e-10 | see note |
| difficulty_v2_candidate_first10.json | 1,510 | 7.28e-12 | 1.66e-12 |
| frozen config (anchors) | 9 | 5.33e-15 | 3.22e-15 |

**Raw: proven to be serialization recovery.** For every one of the 12,506 changed raw leaves, the old committed number equals what the old writer printed for the new double (Godot `%.<p>lf` with p = max(1, 14 − ⌊log10|x|⌋), under the glibc or the msvcrt rounding model).

**Derived: proven attributable.** `tests/tools/m53_c002_refreeze_rescore.gd` re-scored with the **current** analyzer:
- (a) old raw + old frozen config → reproduces **all 343** old committed derived values at their printed precision: challengeScore, sessionLoad and the W/C/A/U/B/R/S vector for 27 fixtures, plus signedDelta for 10 holdout levels.
- (b) new raw + new frozen config → reproduces **all 343** new values **exactly**.

So the analyzer is unchanged, and derived deltas come only from the recovered raw precision.

**Note on the max relative delta.** The single derived leaf with a relative Δ above 1e-12 is `flow_stripes3_32` `vector.A`: an exact `0.0` became `1.24e-17`, a floating cancellation residue that is now visible at full precision. Both directions of the rescore reproduce it, and it affects no score or decision.

**Anchors.** For example R_detour_lo `1.28781617200653 → 1.287816172006527`; U_p95_hi `4.0` unchanged; all |Δ| ≤ 5.3e-15.

## 6. Files

**New:**
- `tools/m53_canonical_json.gd`
- `tests/m53_c002_canonical_json.gd`
- `tests/tools/m53_c002_refreeze_rescore.gd`
- `coordination/sessions/M53-C002/evidence/r01_refreeze/`: `build_refreeze_report.py` and `refreeze_report_v1.json`
- this log

**Modified:**
- **Code / test:** `tools/calibrate_difficulty_v2.gd` (5 writers + the Canon preload); `tests/m53_c002_difficulty_calibration.gd` (`_norm` + the Canon preload).
- **Regenerated by the tool:**
  - `data/config/level_difficulty_analysis_v2_candidate.json`;
  - `evidence/calibration_corpus_v1.json`;
  - `evidence/corpus_raw/*` (27);
  - `evidence/holdout_raw/*` (10);
  - `evidence/difficulty_v2_candidate_first10.json`;
  - `DIFFICULTY_CALIBRATION_MATRIX_V01.md`.

**Untouched:** production LevelData / supply plans / catalog / palette / Difficulty V1 / progression, all `scripts/`, and the corpus fixtures + manifest.

**Reproduce the report:** `python3 -I evidence/r01_refreeze/build_refreeze_report.py <old_snapshot> . out.json rescore_old.json rescore_new.json`. The old snapshot is the parent commit's copy of the same paths.

## 7. Owner status

No owner-facing score, category, verdict or conclusion changed (section 4), so per the decision record **no new owner rating session is required**.

## 8. Tests (Godot 4.7.2 headless, final tree)

Each suite exited 0 with 0 `SCRIPT ERROR`.

| Suite | Before (R01, untouched tree) | After |
|---|---|---|
| `m53_c002_difficulty_calibration` | FAIL (1): `fresh run == committed corpus raw` | **PASS**, 214 ok (same check count), exact assertion intact |
| `m53_c002_canonical_json` (new golden suite) | — | **PASS 30/30** |
| `m53_first10_difficulty` (M53-C001) | PASS | PASS |
| M52: owner_supply_plans · r01_parallel_runtime · r02_early_slot_release | PASS | PASS ×3 |
| M54: collection_set_master_exactly_once (the only M54 suite in the repo) | PASS | PASS |
| M36: difficulty_v1 · v02_migration | PASS | PASS ×2 |
| CP04 28/28 · CP05 15/15 · CP05-R01 6/6 · remote family fixture | PASS | PASS |
| M35 ×2 · M37 ×3 · M40 ×4 · M43 c009 daily 12/12 · M39d daily/collection | PASS | PASS |
| root `tests/run_tests.gd` | ALL PASS 5329 | **ALL PASS — 5329 checks** |

**Diff and errors.** `git diff --check` is clean. There are no new ERROR or WARNING lines beyond Godot's usual exit-time leak lines.

## 9. Handoff

Branch `claude/practical-darwin-ndbmxa`. The final SHA and ahead/behind are in the handoff message.

AWAITING_GPT_M53_C002_R01_REFREEZE_AUDIT
