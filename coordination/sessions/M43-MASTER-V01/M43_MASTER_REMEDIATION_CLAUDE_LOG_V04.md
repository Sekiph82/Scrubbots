# M43 — MASTER REMEDIATION V04 CROSS-PLATFORM CLOSURE — CLAUDE LOG V04

Prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_V04_CROSS_PLATFORM_CLOSURE.md`
Criteria: `M43_MASTER_REMEDIATION_AUDIT_CRITERIA_V04.md`

Root `TASKS.md` was read only and never edited. Every status below is Claude's implementation claim awaiting ChatGPT's independent V04 audit.

## 1. Sync / integration proof

- **Environment:** a Claude Code cloud container holding a clean clone, not the owner's `C:\Users\sekip\Desktop\ScrubBots`. `git status --short` showed no tracked modification and no owner-local file, so no `project.godot`, `scenes/app/main.tscn`, `addons/` or owner metadata was present or touched.
- **Fetch:** `git fetch origin main claude/practical-darwin-ndbmxa`. Before integration:
  - local HEAD = `origin/claude/practical-darwin-ndbmxa` = `956aecb` (V03 head);
  - `origin/main` = `0204a44`.
- **Main advanced** by 3 coordination commits since the V03 merge base `0a7ff02`:
  - `6e8613e` V04 prompt;
  - `e84c229` V04 criteria;
  - `0204a44` `TASKS.md` hold.

  They touch only those three files, so there was no overlap with V03.
- **Integration:** non-destructive merge of `origin/main` into the branch, giving merge commit `856811a`. No rebase, reset or force push; the V03 commits `1cbe37f`, `c7faa43` and `956aecb` are preserved unchanged.
- **After integration:** `origin/main...HEAD` = 0 behind / 4 ahead.
- **Integrated V03 SHA:** `956aecb`.
- **Generated artefacts:** the `.import` / `.uid` files from the headless `--import` were never staged.

## 2. M41 pack-RNG normalization (`tests/m41_settings.gd`)

**Exact change:**
- In `_reduced_effects_gameplay_invariance()`, each run now stores `"econ": _economy_without_pack_rng(app.economy.snapshot())`.
- The new static helper `_economy_without_pack_rng(snapshot)`:
  1. deep-duplicates the snapshot;
  2. erases only `packs.rng`;
  3. returns the result.
- Every other section is still compared exactly: reward + wallet, gift, streak, robots, hearts, speed / entitlement, boosters, daily, collection, `pack_receipts`, `meta_ui`, `pack_pity`, `daily_orders`, records, events, return, notifications.
- `economy.packs` holds only `{rng}` today, so `packs` is compared as `{}`.
- The progression, terminal, cell, supply and live comparisons are unchanged.
- An inline comment documents why the field is excluded.

**In-test sensitivity:** a copy of the OFF economy with wallet +1 SB must compare unequal after normalization. Result: `ok`.

**Manual sensitivity:** I injected `app.economy.wallet.credit("scrub_bucks", 1)` into the `on` run only, after the drain. Result: `FAIL: on: identical progression/economy result to OFF`, M41 FAIL (1). The file was then restored byte-exactly (`cmp` identical; sha256 `1a1fb8c4…`).

**Production RNG unchanged:**
- `scripts/collection/` has no diff; `card_pack_service.gd:38` still calls `_rng.randomize()`.
- Two fresh `AppState`s on the final tree still get different RNG state: `{hi:2919906289, lo:385230084}` and `{hi:1095446888, lo:3756269119}`.

**Result:** `tests/m41_settings.gd` → **M41 V01 settings evidence: PASS** (17/17 cases; the 2 former invariance FAILs are now `ok`), exit 0, 0 script errors.

## 3. LevelImporter resolved-path I/O (`scripts/tools/level_importer.gd`)

This follows the existing `_resolve_path()` / `simplify_path()` contract: a resolved path is the real filesystem path for actual I/O. After the alias preflight, `run_import()` now derives:

`source_fs`, `output_fs`, `preview_fs`, `metadata_fs` = `_resolve_path(request.*_path)`

and uses them for **every** actual I/O call:
- source `Image.load`;
- output / preview / metadata `FileAccess.file_exists`;
- existing output / metadata `get_file_as_string`;
- existing preview `Image.load`;
- output / metadata `_write_text`;
- preview `save_png`.

What did not change:
- Alias rejection still uses `_canonical_path()` exactly as before.
- Error messages and metadata provenance (`sourcePath`, `outputPath`) keep the request strings.
- Overwrite / unchanged / dry-run logic is unchanged.
- No directory is created implicitly.
- `LevelBatchImporter` already preflights parents via `_resolve_path`; it now writes where it preflighted. Its catalog-ownership checks are untouched.

**New root checks** (`tests/run_tests.gd`, F-M09-005 block, case 7; the case deletes its own three test files first because `user://` persists):
1. `subdir/../legit_prev.png` + `subdir/../legit_meta.json` destinations succeed (preview + metadata written);
2. both files exist at their simplified locations;
3. metadata provenance keeps the request path;
4. an identical rerun through the dot-segment paths reports output / preview / metadata **unchanged**, so preflight reads the simplified files;
5. output into `no_such_dir/x/../` still fails;
6. no parent directory was created.

The neighbouring cases are unchanged and PASS:
- source vs `subdir/../` destination rejected;
- absolute-vs-scheme alias rejected;
- output vs preview dot-segment alias rejected;
- `overwrite=true` alias still rejected;
- distinct dot-segment output succeeds at its simplified location.

No test-only `subdir` was created to mask the bug.

## 4. Linux before / after proof

| State | Root `tests/run_tests.gd` (Linux, Godot 4.7.2 headless) |
|---|---|
| baseline `0a7ff02` (V03 log) | 5,323 checks, **2 FAIL** (distinct dot-segment output succeeds / written at its simplified location) |
| V04, with the three writes temporarily reverted to the raw request path (sensitivity) | 5,329 checks, **5 FAIL**: both original checks plus new checks 1, 2 and 4. File restored byte-exactly afterwards (`cmp` identical). |
| **V04 final** (`fa89fb6`) | **5,329 checks, 0 failures, RESULT: ALL PASS**, 0 script errors, run twice (rerun-stable) |

Note on the count: the criteria name 5,323 / 5,323. The total is now 5,329 because the prompt asked for the 6 new preview / metadata / missing-parent checks above. All 5,323 original checks pass, including the 2 former Linux failures.

## 5. V03 preservation

- `tests/m43_master_c011_c014.gd` (cloud conflict lineage, notification rollback cap, meta audio / haptic family + fatigue): **PASS 28/28**, exit 0, 0 script errors, on the final V04 tree.
- Master status table is unchanged: **92 READY · 33 BLOCKED · 21 DEFERRED** (row counts re-verified).
- No V03 production file was changed in V04.

## 6. Diff / runtime cleanliness

- V04 code commit `fa89fb6` changes exactly `scripts/tools/level_importer.gd`, `tests/m41_settings.gd` and `tests/run_tests.gd`. This log and the V03 log note follow in the docs commit.
- `git diff --check`: clean.
- No `SCRIPT ERROR` in M41, C011–C014 or either root run. Only Godot's usual exit-time leak warnings appear, and they are present at baseline too.
- No production RNG change. No owner-local file staged.

## 7. Branch / main state

- **Branch:** `claude/practical-darwin-ndbmxa`. This session may push only its designated branch, so `main` was not pushed.
- **Commits ahead of `main`:**
  - `1cbe37f`, `c7faa43`, `956aecb` (V03);
  - `856811a` (merge of `origin/main` `0204a44`);
  - `fa89fb6` (V04 code / tests);
  - this log's docs commit.
- Final SHA, ahead / behind and the merge instruction are reported in the handoff message.

AWAITING_GPT_M43_MASTER_REMEDIATION_V04_AUDIT
