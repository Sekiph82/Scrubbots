# M43-C005-C008 — CLAUDE LOG V02 — Import Hardening (absent vs present C008 sections)

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-066
Status: **AWAITING_AUDIT** (implementer evidence only; no verdict claimed)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C008/CHATGPT_PROMPT_V02.md
- `CHATGPT_AUDIT_CRITERIA_V02.md`, `CHATGPT_AUDIT_V01.md` (FAIL: absent vs present-empty collapsed to `{}`),
  `CHATGPT_PROMPT_V01.md`, `CHATGPT_AUDIT_CRITERIA_V01.md`, `CLAUDE_LOG_V01.md`
- `CLAUDE.md`, root `TASKS.md` (read only, not edited), `coordination/AUDIT_POLICY.md`
- C008 production files, `save_service.gd` (`validate_candidate`, load path), focused suite

## Sync

`git fetch origin main --prune` → 0 ahead / 4 behind (`72769bd`, `02b421c`, `76eb509`, `7920250`: audit V01, prompt V02,
criteria V02, TASKS.md). No local edits on those paths → `git merge --ff-only origin/main` to `7920250`. Owner/local
work preserved and not staged: `M project.godot`, `M scenes/app/main.tscn`, addons, `.mcp.json`, untracked owner files,
`tests/_m55_diag_tmp.gd` (not mine).

## 1. Production diff (exact)

`scripts/economy/economy_services.gd` (`_apply_sections`) — presence decided with `has()`:

```gdscript
	# M43-C005-C008: key ABSENT = pre-C008 save (keep the live OS-seeded RNG / empty ledger).
	# Key PRESENT = strict C008 schema; an empty or partial section fails closed.
	if s.has("packs") and not packs.import_snapshot(s["packs"]):
		return false
	var ledger = s["pack_receipts"] if s.has("pack_receipts") else PackReceiptLedger.empty_snapshot()
	if not pack_receipts.import_snapshot(ledger):
		return false
```

`scripts/collection/card_pack_service.gd` (`import_snapshot`) — the legacy `if not s.has("rng"): return true` branch is
removed; a section must be exactly `{rng}`:

```gdscript
	if typeof(s) != TYPE_DICTIONARY or s.size() != 1 or not s.has("rng"):
		return false
```
(the existing exact `{hi, lo}` / exact-int / u32 checks follow unchanged)

`scripts/collection/pack_receipt_ledger.gd` — the `s.is_empty() → empty ledger` branch is removed; a section must be
exactly `{version, receipts}`; new `static func empty_snapshot() -> {version: 1, receipts: []}` (used by E for an absent
key). Header comments updated in both services.

Unchanged: PackCommitTransaction, AppState, receipt schema/semantics, RNG split, rollback, replay, ceremonies, models,
sequencer, frames, SaveService, root `TASKS.md`. EconomyServices' full-backup re-import on any section failure is
unchanged, so a strict C008 rejection after earlier sections were applied restores everything.

## 2. Absent vs present contract

| Key | Absent (pre-C008) | Present |
|---|---|---|
| `packs` | not imported; live OS-seeded RNG kept | strict: exactly `{rng:{hi,lo}}`, exact ints 0..4294967295 |
| `pack_receipts` | `empty_snapshot()` imported → empty ledger | strict: exactly `{version:1, receipts:[valid, unique tx]}` |

New focused case **t27_absent_vs_present** (10 present-malformed sections: `packs_empty` `{}`, `packs_rng_empty`
`{rng:{}}`, `packs_no_rng`, `packs_extra_key`, `packs_null`, `ledger_empty` `{}`, `ledger_no_receipts` `{version:1}`,
`ledger_no_version` `{receipts:[]}`, `ledger_extra_key`, `ledger_null`):

1. EconomyServices import: each bad candidate ALSO changes the wallet (+777 SB via the reward section) and Collection
   (s1_c0 +4) before the bad C008 section → all 10 rejected and the whole live authority (economy snapshot, RNG, save
   bytes) is unchanged afterwards (prompt §5).
2. Direct imports: `CardPackService.import_snapshot` rejects `{}`, `{rng:{}}`, `{rng:{hi}}`, `{seed}`, extra key, `[]`,
   `null` with the RNG untouched and accepts canonical `{rng:{hi,lo}}`; `PackReceiptLedger.import_snapshot` rejects `{}`,
   `{version:1}`, `{receipts:[]}`, extra key, `version:2`, `[]`, `null` with the ledger untouched.
3. Both keys absent: accepted, live RNG kept, ledger empty.
4. SaveService: the real pre-C008 candidate (both keys absent) passes `validate_candidate`; all 10 malformed candidates
   fail; writing each as the primary file and constructing a real `AppState` never loads it as primary (no receipt
   survives); a legacy primary loads from primary, commits a Premium pack, and the receipt reloads exactly.

V01 cases retained: t20 (old save loads + commit + reload), t21 (25 corruptions incl. RNG shape/type/domain, wrong
version/root, receipt corruption), t22 (economy + direct ledger all-or-nothing).

## 3. Mutation sensitivity

Runner: temporary single-occurrence replace in production source, focused suite run, restore from copy; `cmp` confirmed
all five source files RESTORED byte-identical afterwards.

| # | Mutation | Result | Detected by |
|---|---|---|---|
| M16 | E `packs.import_snapshot(s.get("packs", {}))` (V01 collapse) | FAIL, 4 | t20, t27 (3)(4) — legacy save no longer loads |
| M17 | E present-empty `packs` treated as absent (`get(...,{}).is_empty()` skip) | FAIL, 3 | t27 (1)(4) `packs_empty` |
| M18 | E `pack_receipts.import_snapshot(s.get("pack_receipts", {}))` (V01 collapse) | FAIL, 4 | t20, t27 (3)(4) |
| M19 | E present-empty `pack_receipts` treated as absent | FAIL, 3 | t27 (1)(4) `ledger_empty` |
| M20 | P lenient again (missing `rng` → ok) | FAIL, 4 | t27 (1)(2)(4) |
| M21 | L lenient again (`{}` → empty ledger) | FAIL, 4 | t27 (1)(2)(4) |
| M01–M15 | V01 mutations re-run against the V02 suite | all FAIL | as V01 |

**21/21 detected.** (M17/M19 print a `SCRIPT ERROR` from the mutant's own `as Dictionary` cast of `null`; not from
production code.)

## 4. Validation

All `godot --headless --path . -s res://tests/<suite>.gd`; exit 0 and 0 `SCRIPT ERROR` lines in every final run.

| # | Suite | Result |
|---|---|---|
| V1 | `m43_c005_c008_pack_commit_transaction` | **PASS 27/27 cases, 0 fail** (t27 new; t01–t26 unchanged and PASS) |
| V2 | mutation sensitivity (§3) | **21/21 detected**, sources restored |
| V3 | `m43_c005_c006_standard_pack_presentation` / `owner_review_harness` | PASS 21/21 / 14/14 |
| V4 | `m43_c005_c007_premium_pack_presentation` / `premium_owner_review_harness` | PASS 19/19 / 11/11 |
| V5 | `m43_c005_c005_reward_reveal_sequencer`, `m43_c003_c001_acquisition`, `m43_c004_c001_fail_need_a_hand` | PASS 12/12, 34/34, 40/40 |
| V6 | M39 `m39a`–`m39e`, `m39_v02_atomicity/capacity/integration`, `m39_v03_full_surface/integration`, `m39_v04_integration/tornado_inflight` | all PASS |
| V7 | M40 `m40_save_system`, `m40_v02_safety`, `m40_v03_canonical`, `m40_v04_bootstrap` | all PASS |
| V8 | `m54_collection_set_master_exactly_once` | PASS |
| V9 | root `run_tests.gd` | **5,323 checks, ALL PASS** |
| V10 | `git diff --check` | clean |

Exit-time "ObjectDB leaked / resources still in use" lines are the AppState economy graphs of AppState-based suites, as
in V01.

## 5. Scope / blockers

- SB-M43-067 not started. Root `TASKS.md` untouched. No tracker created. No visual change.
- Blockers: none.

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C008_V02_IMPORT_HARDENING_AUDIT`
