# SB-CP05-R01-001 — FAILED MULTI-PACK CANDIDATE TRANSACTION CLEANUP — CLAUDE LOG V01

Prompt: `CHATGPT_REMEDIATION_PROMPT_R01.md` · Criteria: `CHATGPT_REMEDIATION_AUDIT_CRITERIA_R01.md` · Source audit: `CHATGPT_INDEPENDENT_AUDIT_V01.md` (RC-R01-F001)

Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit.

## Sync truth

**Environment.** This ran in a Claude Code cloud container. The owner-local `C:/Users/sekip/Desktop/ScrubBots` is **not accessible** from this session; it was not touched or synced, and no claim is made about it. The clean clone has no owner-local `project.godot` / `main.tscn` / `addons/` / `.mcp.json` edits. Editor `.import` / `.uid` sidecars from the headless import stay unstaged.

**Merge.**
- Branch `claude/practical-darwin-ndbmxa` was at `e866258` (the CP04/CP05 runtime), 1 ahead / 6 behind `origin/main` `16c6c2b` (ChatGPT audit, R01 prompt/criteria, M53 prompt, `TASKS.md`).
- `git merge --no-edit origin/main` produced merge `3318174` with no conflicts.
- Both `e866258` and every newer ChatGPT governance file are preserved. No reset, clean, force, rebase or stash.

## Root cause

**V1 flow.** `RemoteContentManager._download_and_stage()` renamed each verified pack from `staging/<tx>/pack` into its final `packs/<id>/<ver>-<sha>/` path **before** the next pack was downloaded and before the registry commit.

**Failure.** When pack C failed after B had been finalized, `refresh()` only removed `staging/<tx>/` and the `.part`. B stayed installed but unreferenced until the next boot's prune.

**Two further defects** in the same boundary, found by the new tests and fixed here:
1. `_activate()` copied the active registry to `registry_v1.prev.json` before the rename, so even a failed commit changed a file.
2. A post-activation verification failure with **no** previous registry left the failed candidate registry active, because there was no `.prev` to restore.

## Fix: staging-until-commit, with a transaction-owned rollback

All changes are in `scripts/content_runtime/remote_content_manager.gd`.

**1. Download and verify (no change under `packs/`).** Every new pack is downloaded, verified and materialized into its own `staging/<tx>/p<i>/`. The whole candidate set is then verified while still in staging: `_verify_set(candidate, dirs)`, where `dirs` maps the new pack IDs to their staged dirs. **Any failure up to here leaves `packs/` and the registry untouched.** `refresh()` then removes `staging/<tx>/` and the `.part`, plus the `staging/` and `downloads/` dirs themselves when they are empty.

**2. Commit, `_commit(tx, candidate, staged)`.** This is the only place `packs/` changes. The transaction owns exactly:
- **`placed`:** the final pack dirs it renames in from staging;
- **`displaced`:** any dir already at a target path, moved aside into `staging/<tx>/displaced<n>` (an orphan, or a broken pack of the same identity being repaired).

The registry step:
- the previous registry bytes are held **in memory**;
- the candidate is written to `.tmp`, re-read, compared, then renamed;
- the new active set is verified (`_load_active`);
- only after success is `registry_v1.prev.json` written, followed by the prune.

**3. Rollback.**
- **Trigger:** any failure inside `_commit`: the install rename, the registry write, the registry rename, or a post-activate verification failure.
- **What it does:** `_rollback(placed, displaced)` removes exactly the placed dirs, restores every displaced dir to its original path, and removes a `packs/<id>/` parent only when that left it empty. On a post-activate failure the previous registry bytes are restored, or the registry is removed if there was none.
- **Properties:** idempotent, and every path is under the content root (`_rm_tree` refuses anything else).

**Never deleted:** a reused exact-identity active pack is never transaction-owned, and nothing referenced by the previous active/LKG registry is ever deleted. There is no blanket `packs/` deletion.

**Test seam.** `_fault` injects `verify_candidate` / `registry_write` / `registry_rename` / `post_activate_verify` at the commit boundary. It is test-only and never set in production.

**Unchanged:**
- Manifest/scrubpack V1 contracts, SHA/ZIP/payload validation and HTTPS-only transport;
- builtin 1–10, the append-only order, the gameplay catalog bridge, save/progression/economy;
- cache reuse/dedup (exact 5-field identity), single activation and the post-commit prune.

## New permanent suite: `tests/cp05_r01_transaction_cleanup.gd` — PASS 6/6, 0 `SCRIPT ERROR`

"Tree" means every file and directory under the content root, with SHA-256s, compared exactly.

| Case | Asserts |
|---|---|
| **t1** active N = A; candidate N+1 = A + B + C; B verifies, C fails (both **hash** and **malformed-ZIP** variants) | B was fetched and verified before C failed. **Without reboot**: the whole tree is byte-identical to before; no final B/C, no staging, no `.part`, no `.tmp`; LKG N still active and playable |
| **t2** no active registry; B + C new; C fails (through a real `AppState`) | nothing remains (no pack, registry, staging or `.part`); builtin 1 and 10 still resolve |
| **t3** reused active pack A survives | A never re-downloaded; every A file hash unchanged; level + supply bytes identical |
| **t4** valid retry | activates exactly once (`content_changed` ×1); only B and C fetched; `packs/` = exactly the three active dirs; no staging residue; a further refresh is a no-op |
| **t5** faults: `verify_candidate`, `registry_write`, `registry_rename`, `post_activate_verify` | each refused; previous registry byte-identical and active; **whole tree byte-identical** (B/C final paths removed at once, `.prev` untouched). **Repair variant:** a broken active pack of the same identity is displaced and then restored exactly; the unfaulted repair succeeds |
| **t6** cold boot after an interrupted commit (a placed-but-unregistered pack, a staged pack, a displaced dir, a half-written `.tmp`, a `.part`) | LKG registry byte-identical and active; A unchanged; orphan pack removed and never exposed; no residue |

**Existing suites.** One existing assertion was updated, not loosened. CP05 k09 checked the source-order claim against the removed `func _activate`. It now checks the same property against the new boundary, and more strictly: `_verify_set(candidate, dirs)` runs before `return _commit(...)`, `func _commit` follows, and the commit still contains the single `rename_absolute(tmp, active)`. No other test was changed.

## Regression (Godot 4.7.2 headless, final tree; each exit 0, 0 `SCRIPT ERROR` unless noted)

| Suite | Result |
|---|---|
| `cp05_r01_transaction_cleanup` (new) | **PASS 6/6** |
| `cp04_remote_content_runtime` · `cp05_remote_content_cache` · `remote_content_family_fixture` | PASS 28/28 · PASS 15/15 · PASS |
| m35_level_catalog · m35_v02_hardening | PASS · PASS |
| m37_level_progression · m37_v02_strict · m37_v03_forward_only | PASS ×3 |
| m40_save_system · m40_v02_safety · m40_v03_canonical · m40_v04_bootstrap | PASS ×4 |
| m52_owner_supply_plans · m52_r01_parallel_runtime · m52_r02_early_slot_release | PASS ×3 |
| m43_master_c009_daily 12/12 · m39d_daily_collection · m43_c004_c001_fail_need_a_hand 40/40 | PASS |
| m53_first10_difficulty | PASS |
| **m53_c002_difficulty_calibration** | **FAIL (1), the known pre-existing baseline exception.** It fails identically on untouched `e36e023`; it is not touched by R01 and **not claimed to pass**. Its separate remediation is SB-M53-C002-R01-001 (separate log). |
| root `tests/run_tests.gd` | **RESULT: ALL PASS — Total checks 5329**, 0 script errors |

**Diff and warnings.** `git diff --check` is clean. The only engine warning is CP04 c05's intentional `1e999` ("Exponent too high").

## Handoff

The final SHA and ahead/behind are in the handoff message. Branch: `claude/practical-darwin-ndbmxa`.

AWAITING_GPT_CP05_R01_TRANSACTION_CLEANUP_AUDIT
