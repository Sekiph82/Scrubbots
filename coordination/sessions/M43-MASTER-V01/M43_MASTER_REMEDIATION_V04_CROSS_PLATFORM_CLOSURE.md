# M43 — MASTER REMEDIATION V04 CROSS-PLATFORM CLOSURE

Status: **READY FOR CLAUDE**
Date: 2026-10-06
Repository: `Sekiph82/Scrubbots`
Local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Canonical tracker: root `TASKS.md` — READ ONLY for Claude

This is NOT a new per-task cycle. It is the final continuation of the milestone-wide M43 remediation.

## Current branch authority

ChatGPT verified on GitHub:

- `main` = `0a7ff024f7a6473acfd51378a026748c09cb4018`
- remediation branch = `claude/practical-darwin-ndbmxa`
- branch is **3 commits ahead, 0 behind** `main`
- merge base = current `main`
- remediation commits:
  - `1cbe37f` — V03 code/tests
  - `c7faa43` — V03 child/master log amendments
  - `956aecb` — V03 remediation handoff log

The V03 branch reproduced two failures on untouched baseline `0a7ff02`:
1. closed M41 Reduced Effects gameplay-invariance test compares fresh whole economy snapshots even though `packs.rng` is OS-seeded per AppState;
2. root LevelImporter dot-segment write test is Linux-nonportable because the importer canonicalizes/simplifies paths for identity checks but writes using the unsimplified request path.

Both must be fixed in this same milestone closure pass. Do not create separate owner handoffs.

# 0. FIRST ACTION — PRESERVE OWNER WORK + INTEGRATE V03

1. Work only from `C:\Users\sekip\Desktop\ScrubBots`.
2. `git fetch origin main claude/practical-darwin-ndbmxa --prune`.
3. Inspect:
   - `git status --short`
   - local HEAD vs `origin/main`
   - `origin/claude/practical-darwin-ndbmxa`
4. Preserve owner-local:
   - `project.godot`
   - `scenes/app/main.tscn`
   - `addons/`
   - owner-review scene metadata
   - unrelated untracked files/candidates
5. Never reset/clean/overwrite owner work.
6. Integrate the V03 remediation branch non-destructively before doing V04 work:
   - if `origin/main` is still the exact merge base, fast-forward the execution branch to the V03 head;
   - if main advanced, replay/cherry-pick the three V03 commits safely and prove no unrelated changes were lost.
7. Root `TASKS.md` remains READ ONLY.

If integration cannot be done without risking owner work, STOP and report exact paths.

# 1. CLOSED M41 TEST CORRECTION — PACK RNG SNAPSHOT

File:
`tests/m41_settings.gd`

Function:
`_reduced_effects_gameplay_invariance()`

## Defect

The test creates three fresh `AppState` instances and asserts complete `app.economy.snapshot()` equality across:
- Reduced Effects OFF
- Reduced Effects ON
- live toggle

Since M43-C005-C008, every fresh `CardPackService` gets an OS-randomized RNG and persists:

`economy.packs.rng = {hi, lo}`

The pack RNG is unrelated to Reduced Effects or gameplay terminal truth, so three fresh apps are expected to have different RNG state.

Production RNG behavior must NOT change.

## Required fix

**Preferred correction for this repository:** keep production RNG OS-seeded and normalize only the M41 comparison fixture.

Create a small test-only helper such as:

`_economy_without_pack_rng(snapshot: Dictionary) -> Dictionary`

that:
1. deep-duplicates the snapshot;
2. removes only `packs.rng` or the entire `packs` section if that section contains no other gameplay-equality field;
3. returns the normalized snapshot.

Use it only for the Reduced Effects gameplay-invariance comparison.

Do NOT:
- set a fixed production seed;
- alter `CardPackService.randomize()`;
- weaken progression/terminal/cell/supply/economy comparisons beyond the OS-seeded RNG field;
- ignore Collection/wallet/boosters/Daily/robot/entitlement/etc.

Document inline why the RNG field is excluded.

## Mandatory proof

Run:

`godot --headless --path . -s res://tests/m41_settings.gd`

Expected:
- all M41 cases PASS;
- specifically the two former invariance failures are gone.

Sensitivity:
- mutate a real economy field in one comparison fixture and prove the test still fails;
- restore byte-exactly.

# 2. LEVELIMPORTER DOT-SEGMENT OS PORTABILITY — FIX PRODUCTION CONTRACT

Files:
- `scripts/tools/level_importer.gd`
- `tests/run_tests.gd`

## Contract decision

Do **NOT** “fix” this by creating the missing `subdir` in the test.

The existing production source already states in `_resolve_path()` that:
- dot segments are simplified via `String.simplify_path()`;
- the resolved path is the real filesystem path intended for actual `FileAccess/DirAccess` calls.

The neighbouring root test explicitly requires:

> distinct dot-segment output written at its simplified location

Therefore the intended contract is already clear: **LevelImporter must perform actual filesystem preflight/writes against the resolved/simplified destination path.**

Current code is inconsistent because alias identity uses `_canonical_path/_resolve_path`, while write/preflight uses the raw request path.

## Required production fix

In `LevelImporter.run_import()`:

1. Keep original request strings for user-facing provenance/error context where useful.
2. Derive filesystem paths through `_resolve_path()` for actual I/O:
   - source load where safe/appropriate;
   - output JSON;
   - preview PNG;
   - metadata sidecar.
3. Use those resolved/simplified paths consistently for:
   - `FileAccess.file_exists`;
   - reading existing output/metadata;
   - loading existing preview;
   - `_write_text`;
   - `Image.save_png`.
4. Preserve alias rejection through canonical paths exactly as before.
5. Do not create missing parent directories implicitly.
6. Do not weaken overwrite/unchanged behavior.
7. Preserve batch import preflight semantics and catalog ownership checks.
8. Keep metadata provenance fields deliberate:
   - it is acceptable for metadata to record the original request path;
   - physical write location must use the resolved path.

## Mandatory root cases

The existing neighbouring tests must all remain true:

- source vs `subdir/../` equivalent destination -> rejected;
- absolute-vs-scheme source alias -> rejected;
- output vs preview dot-segment-equivalent destination -> rejected;
- overwrite=true never bypasses source alias rejection;
- a genuinely distinct `subdir/../legit_distinct.json` succeeds;
- actual file exists at the simplified path.

Add/extend tests for preview and metadata dot-segment outputs if not already covered, proving they also write at simplified destinations.

Sensitivity:
- temporarily revert the actual write to the raw path on Linux and prove the dot-segment case fails;
- restore.

# 3. V03 REMEDIATION REGRESSION MUST STAY INTACT

The V04 fixes are test/platform closure only. Do not regress the V03 work:

- SB-M43-155 cloud conflict lineage / whole-save safety;
- R12 rollback-safe notification cap;
- 161/162 complete meta audio/haptic mapping;
- 167 real fatigue coverage;
- corrected master statuses.

Run the V03 focused suite after V04.

# 4. VALIDATION MATRIX

Run with Godot 4.7.2 headless:

1. `tests/m41_settings.gd`
2. the V03 M43 C011-C014 focused suite
3. relevant LevelImporter / LevelBatchImporter focused suites if separate
4. `tests/run_tests.gd`

Final required condition:

**ROOT = ALL PASS 5,323 / 5,323 on Linux headless.**

Also:
- `git diff --check` clean;
- no unexplained `SCRIPT ERROR` / runtime errors;
- no production RNG behavior change;
- no owner-local files staged.

# 5. LOGGING

Do not edit root `TASKS.md`.

Append a clearly marked V04 closure note to:
- `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`

Also create:

`coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_CLAUDE_LOG_V04.md`

Record:
- sync/integration proof;
- exact integrated V03 SHA;
- final SHA;
- exact M41 normalization;
- proof production pack RNG remains OS-seeded;
- LevelImporter resolved-path implementation;
- Linux before/after failure proof;
- M41 result;
- V03 focused regression result;
- root 5,323/5,323;
- diff/runtime cleanliness.

Push the completed work to `main` if the session has permission.

If the session cannot push `main`, push one branch and report:
- exact branch;
- exact final SHA;
- ahead/behind relative to main;
- one clean merge/cherry-pick instruction.

Finish exactly:

`AWAITING_GPT_M43_MASTER_REMEDIATION_V04_AUDIT`
